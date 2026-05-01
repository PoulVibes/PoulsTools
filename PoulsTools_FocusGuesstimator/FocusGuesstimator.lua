local frame = CreateFrame("Frame", "FocusGuesstimatorLogicFrame")

-- ── 1. Configuration & Constants ──────────────────────────────────────────────

-- BM Hunter: class token and spec ID 253
local REQUIRED_CLASS   = "HUNTER"
local REQUIRED_SPEC_ID = 253

-- Focus is Power Type 2 (Enum.PowerType.Focus).
local FOCUS_POWER_TYPE = 2

-- Passive focus regeneration rate (focus per second) before haste.
-- BM Hunter baseline: 5 focus/sec.  All hunter specs share this rate.
local BASE_REGEN = 5

-- Barbed Shot focus regeneration mechanic.
-- Each cast of Barbed Shot starts a buff that restores 20 focus over 8 seconds
-- (2.5 focus/sec per stack).  Stacks are additive; multiple casts within the
-- 8-second window each contribute their own regen tick.
local BARBED_SHOT_ID          = 217200
local BARBED_SHOT_REGEN_TOTAL = 20     -- focus restored per cast
local BARBED_SHOT_DURATION    = 8      -- seconds per stack
local BARBED_SHOT_REGEN_RATE  = BARBED_SHOT_REGEN_TOTAL / BARBED_SHOT_DURATION  -- 2.5/sec

-- Cobra Senses talent: reduces Cobra Shot focus cost by 5 (35 → 30).
-- TODO: replace 0 with the verified passive spell ID granted by the talent node.
--       In-game: /script print(C_Spell.GetSpellName(XXXXXX)) until you find it.
local COBRA_SENSES_SPELL_ID = 378244
local COBRA_SHOT_ID         = 193455
local COBRA_SHOT_BASE_COST  = 35

-- Lethal Barbs talent: each ranged Auto Shot generates 1 focus.
-- The auto-shot interval = base weapon speed / (1 + haste).
local LETHAL_BARBS_SPELL_ID = 1264781

-- Focus costs for BM Hunter abilities (positive = focus spent on cast).
local ABILITY_COSTS = {
    -- ── Core rotation ──────────────────────────────────────────────────────
    [34026]          = 30,  -- Kill Command
    [COBRA_SHOT_ID]  = COBRA_SHOT_BASE_COST, -- Cobra Shot (modified by Cobra Senses)
    [BARBED_SHOT_ID] = 0,  -- Barbed Shot (also triggers focus regen buff; see above)
    [1264359]        = 35, -- Wild Thrash
    -- ── Proc / free abilities (no focus cost; listed for completeness) ─────
    [466930] = 0,    -- Black Arrow proc   – verify if a hidden cost exists
    [392060] = 0,    -- Wailing Arrow proc – verify if a hidden cost exists
    [19574]  = 0,    -- Bestial Wrath      – cooldown, no direct focus cost
    -- ── Possible future entry: Dire Beast hits may restore 10 focus each ──
    -- [120679] = -10,  -- Dire Beast (negative = focus gained; uncomment if confirmed)
}

-- Haste multiplier shared with CombatCoach_GuesstimatorHaste.
-- Falls back to 21 % until that addon updates the global.
_G.GuesstimatedHaste = _G.GuesstimatedHaste or 0.21

-- ── 2. Runtime State ──────────────────────────────────────────────────────────

local maxFocus                = 100
currentFocus                  = maxFocus   -- intentional global; readable by SBA / other addons
local addonEnabled              = false
local regenMultiplier           = 1.0        -- adjusted by talent scan
local cobraSensesActive         = false      -- set by RefreshTalents
local lethalBarbsActive         = false      -- set by RefreshTalents; enables auto-shot focus gain
local lastKnownRangedCritChance = 0          -- saved outside combat; reused while in combat
local cobraCritExpectedRefund   = 0          -- (lastKnownRangedCritChance/100)*10
local baseRangedWeaponSpeed     = 0          -- base (un-hasted) weapon speed in seconds
local autoShotTimer             = 0          -- accumulates elapsed time toward next auto-shot
local playerInCombat            = false      -- true between PLAYER_REGEN_DISABLED/ENABLED
local bardedShotRegenExpiry     = {}         -- expiry timestamps for each active Barbed Shot stack
local ui                                     -- forward declaration; assigned after CreateFrame

-- ── 3. Class / Spec Helpers ───────────────────────────────────────────────────

local function IsPlayerClass(token)
    local _, classToken = UnitClass("player")
    return classToken == token
end

local function IsPlayerSpec(specID)
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    return select(1, GetSpecializationInfo(specIndex)) == specID
end

-- ── 4. Talent Scan ────────────────────────────────────────────────────────────
-- Run on login and whenever the talent loadout changes.
-- Add IsSpellKnown() checks here as focus-affecting talents are confirmed.
--
-- Focus-affecting BM Hunter talent notes (Interface 120005):
--   • UnitPowerMax("player", 2) is read to pick up any max-focus bonuses from
--     talents like an upgraded Kindred Beasts node (if present in current tree).
--   • Regen-boosting talents (if any) should multiply regenMultiplier below.
--   • A talent that reduces ability costs (e.g. via Bestial Wrath window) should
--     be handled by temporarily patching ABILITY_COSTS values in your own code,
--     or by adding a separate cost-modifier table checked inside UNIT_SPELLCAST_SUCCEEDED.

local function RefreshTalents()
    regenMultiplier = 1.0

    -- Read actual max focus from the API.
    -- For focus, UnitPowerMax is typically NOT a secret value.
    local apiMax = UnitPowerMax("player", FOCUS_POWER_TYPE)
    if apiMax and not issecretvalue(apiMax) then
        maxFocus = apiMax
    else
        maxFocus = 100   -- safe fallback
    end

    -- ── Cobra Senses: reduces Cobra Shot cost by 5 ────────────────────────
    cobraSensesActive = (COBRA_SENSES_SPELL_ID > 0) and IsSpellKnown(COBRA_SENSES_SPELL_ID) or false

    -- ── Lethal Barbs: Auto Shot generates 1 focus per shot ────────────────
    lethalBarbsActive = IsSpellKnown(LETHAL_BARBS_SPELL_ID)

    -- ── Cobra Shot crit refund: expected +10 focus per crit ──────────────
    -- GetRangedCritChance() is a secret value in combat.  Save the raw value
    -- while outside combat so it can be reused for the duration of each fight.
    if not InCombatLockdown() then
        local crit = GetRangedCritChance()
        if crit and not issecretvalue(crit) then
            lastKnownRangedCritChance = crit
            cobraCritExpectedRefund   = (lastKnownRangedCritChance / 100) * 10
        end
    end

    -- ── Add further talent checks below as spell IDs are confirmed ─────────
    --
    -- BM Hunter candidates to research (TWW / Interface 120005):
    --   • Any "One with the Pack" node that grants extra focus per barbed shot tick
    --   • Any "Pack Leader" node that modifies passive regen during Bestial Wrath
    --   • Aspect of the Wild (if it still grants focus regen in current tree)
    --
    -- Example pattern:
    --   if IsSpellKnown(XXXXXX) then regenMultiplier = regenMultiplier * 1.10 end

    if currentFocus > maxFocus then currentFocus = maxFocus end
end

-- Reads the ranged weapon speed and stores the BASE (un-hasted) value.
-- UnitAttackSpeed returns the currently-hasted mainhand speed; we reverse
-- the haste scaling so OnUpdate can re-apply GuesstimatedHaste each frame.
-- For hunters, their bow/gun/crossbow is INVSLOT_MAINHAND (slot 13).
-- Only called outside combat; weapon swaps cannot occur in combat anyway.
local function RefreshWeaponSpeed()
    if InCombatLockdown() then return end
    local hastedSpeed = UnitAttackSpeed("player")
    if hastedSpeed and not issecretvalue(hastedSpeed) and hastedSpeed > 0 then
        local haste = _G.GuesstimatedHaste or 0
        baseRangedWeaponSpeed = hastedSpeed * (1 + haste)
    end
end

-- ── 5. Enable / Disable ───────────────────────────────────────────────────────

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled  = true
    currentFocus  = maxFocus   -- optimistic start; synced on first combat-exit
    autoShotTimer = 0
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled   = false
    autoShotTimer  = 0
    playerInCombat = false
    wipe(bardedShotRegenExpiry)
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:UnregisterEvent("UNIT_MAXPOWER")
    frame:UnregisterEvent("UNIT_POWER_UPDATE")
    frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    ui:Hide()
end

local function UpdateEnabledState()
    if not IsPlayerClass(REQUIRED_CLASS) then
        -- Wrong class entirely; stop listening for everything.
        frame:UnregisterAllEvents()
        ui:Hide()
        return
    end
    if IsPlayerSpec(REQUIRED_SPEC_ID) then
        RefreshTalents()      -- always re-scan on spec/talent changes
        RefreshWeaponSpeed()  -- cache weapon speed for auto-shot interval
        EnableAddon()
    else
        DisableAddon()
    end
end

-- ── 6. UI ─────────────────────────────────────────────────────────────────────

ui = CreateFrame("Frame", "FocusGuesstimatorUI", UIParent, "BackdropTemplate")
ui:SetSize(160, 40)
ui:SetPoint("CENTER", 0, -60)
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)

ui:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
ui:SetBackdropColor(0, 0, 0, 0.6)

ui.text = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ui.text:SetPoint("CENTER")
ui.text:SetTextColor(0.2, 0.6, 1)   -- blue tint matches the focus bar colour

-- ── 7. Event Handling ─────────────────────────────────────────────────────────

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if select(1, ...) == "CombatCoach_FocusGuesstimator" then
            ui:Hide()
            UpdateEnabledState()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        -- Spec is guaranteed valid here; perform the authoritative first check.
        UpdateEnabledState()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if select(1, ...) == "player" then UpdateEnabledState() end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Loadout swap within the same spec; refresh talent modifiers.
        if addonEnabled then RefreshTalents() end
        UpdateEnabledState()
        return
    end

    if not addonEnabled then return end

    -- ── Runtime events (registered only while addon is active) ────────────

    if event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: sync estimate and refresh out-of-combat stats.
        playerInCombat = false
        local real = UnitPower("player", FOCUS_POWER_TYPE)
        if not issecretvalue(real) then currentFocus = real end
        local crit = GetRangedCritChance()
        if crit and not issecretvalue(crit) then
            lastKnownRangedCritChance = crit
            cobraCritExpectedRefund   = (lastKnownRangedCritChance / 100) * 10
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: mark combat active and reset the auto-shot timer so
        -- the first simulated shot fires after one full weapon-speed interval.
        playerInCombat = true
        autoShotTimer  = 0
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Re-derive base weapon speed if the ranged weapon (main hand) changed.
        local slot = select(1, ...)
        if slot == INVSLOT_MAINHAND then
            RefreshWeaponSpeed()
        end
        return
    end

    -- All remaining runtime events carry unit as the first argument.
    local unit = select(1, ...)
    if unit ~= "player" then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = select(3, ...)
        local cost = ABILITY_COSTS[spellID]

        -- Cobra Senses talent: reduce Cobra Shot cost by 5
        -- Also subtract the expected focus refund from crits (updated outside combat).
        if spellID == COBRA_SHOT_ID then
            if cobraSensesActive then cost = cost - 5 end
            cost = cost - cobraCritExpectedRefund
        end

        if cost and cost > 0 then
            currentFocus = math.max(0, currentFocus - cost)
        elseif cost and cost < 0 then
            -- Negative cost = focus gained (e.g. Dire Beast hits if enabled above)
            currentFocus = math.min(maxFocus, currentFocus - cost)
        end

        -- Barbed Shot: register a new focus regen stack expiring in 8 seconds
        if spellID == BARBED_SHOT_ID then
            bardedShotRegenExpiry[#bardedShotRegenExpiry + 1] = GetTime() + BARBED_SHOT_DURATION
        end

    elseif event == "UNIT_POWER_UPDATE" then
        -- Floor the estimate using ability usability as a hint.
        -- If Kill Command (costs 30) is castable, we must have at least 30 focus.
        local powerType = select(2, ...)
        if powerType == "FOCUS" then
            local kcUsable = C_Spell.IsSpellUsable(34026)
            if not issecretvalue(kcUsable) and kcUsable then
                if currentFocus < 30 then currentFocus = 30 end
            end
        end

    elseif event == "UNIT_MAXPOWER" then
        local apiMax = UnitPowerMax("player", FOCUS_POWER_TYPE)
        if apiMax and not issecretvalue(apiMax) then
            maxFocus = apiMax
            if currentFocus > maxFocus then currentFocus = maxFocus end
        end
    end
end)

-- ── 8. OnUpdate: passive regen tick ───────────────────────────────────────────

frame:SetScript("OnUpdate", function(self, elapsed)
    if not addonEnabled then return end

    -- Passive regen: baseline scaled by haste and talent multiplier.
    local regenRate = BASE_REGEN * (1 + (_G.GuesstimatedHaste or 0)) * regenMultiplier

    -- Barbed Shot regen stacks: each active stack adds 2.5 focus/sec.
    -- Expired stacks are removed here to keep the table clean.
    local now = GetTime()
    local activeStacks = 0
    local writeIdx = 0
    for i = 1, #bardedShotRegenExpiry do
        local expiry = bardedShotRegenExpiry[i]
        if expiry > now then
            writeIdx = writeIdx + 1
            bardedShotRegenExpiry[writeIdx] = expiry
            activeStacks = activeStacks + 1
        end
    end
    -- Trim removed entries from the end of the table
    for i = writeIdx + 1, #bardedShotRegenExpiry do
        bardedShotRegenExpiry[i] = nil
    end

    regenRate = regenRate + (activeStacks * BARBED_SHOT_REGEN_RATE)

    if currentFocus < maxFocus then
        currentFocus = math.min(maxFocus, currentFocus + (regenRate * elapsed))
    end

    -- Lethal Barbs: each Auto Shot generates 1 focus.
    -- Auto-shot interval = base weapon speed / (1 + haste); accumulate time
    -- and fire discrete +1 ticks.  Only active during combat.
    if lethalBarbsActive and playerInCombat and baseRangedWeaponSpeed > 0 then
        local currentInterval = baseRangedWeaponSpeed / (1 + (_G.GuesstimatedHaste or 0))
        autoShotTimer = autoShotTimer + elapsed
        while autoShotTimer >= currentInterval do
            autoShotTimer = autoShotTimer - currentInterval
            currentFocus  = math.min(maxFocus, currentFocus + 1)
        end
    end

    if ui:IsShown() then
        -- SetFormattedText keeps the actual value as a secret-wrapped display string.
        local actual = UnitPower("player", FOCUS_POWER_TYPE)
        ui.text:SetFormattedText("%d vs %s", math.floor(currentFocus), actual)
    end
end)

-- ── 9. Slash Command: /fg ─────────────────────────────────────────────────────

SLASH_FOCUSGUESSTIMATE1 = "/fg"
SlashCmdList["FOCUSGUESSTIMATE"] = function()
    if not IsPlayerClass(REQUIRED_CLASS) then return end
    if not IsPlayerSpec(REQUIRED_SPEC_ID) then return end
    if ui:IsShown() then ui:Hide() else ui:Show() end
end
