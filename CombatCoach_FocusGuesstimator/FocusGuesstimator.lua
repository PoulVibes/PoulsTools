local frame = CreateFrame("Frame", "FocusGuesstimatorLogicFrame")

local REQUIRED_CLASS   = "HUNTER"
local REQUIRED_SPEC_ID = 253   -- Beast Mastery
local SV_SPEC_ID       = 255   -- Survival

-- Focus is Power Type 2 (Enum.PowerType.Focus).
local FOCUS_POWER_TYPE = 2

-- Baseline passive focus regen: 5 focus/sec before haste; shared by all Hunter specs.
local BASE_REGEN = 5

local BARBED_SHOT_ID          = 217200
local BARBED_SHOT_REGEN_TOTAL = 20     -- focus restored per cast
local BARBED_SHOT_DURATION    = 8      -- seconds per stack
local BARBED_SHOT_REGEN_RATE  = BARBED_SHOT_REGEN_TOTAL / BARBED_SHOT_DURATION  -- 2.5/sec

-- Cobra Senses talent: reduces Cobra Shot focus cost by 5 (35 → 30).
local COBRA_SENSES_SPELL_ID = 378244
local COBRA_SHOT_ID         = 193455
local COBRA_SHOT_BASE_COST  = 35

local LETHAL_BARBS_SPELL_ID = 1264781

-- Focus costs for BM Hunter abilities (positive = focus spent on cast).
local ABILITY_COSTS = {
    [34026]          = 30,  -- Kill Command
    [COBRA_SHOT_ID]  = COBRA_SHOT_BASE_COST, -- Cobra Shot (modified by Cobra Senses)
    [BARBED_SHOT_ID] = 217200,  -- Barbed Shot (also triggers focus regen buff; see above)
    [1264359]        = 35, -- Wild Thrash
    [466930] = 0,    -- Black Arrow proc
    [392060] = 0,    -- Wailing Arrow proc
    [19574]  = 0,    -- Bestial Wrath
}

local SV_KILL_COMMAND_GAIN = 15

-- Flanker's Advantage (SV talent): Kill Command generates +5 additional focus.
local FLANKERS_ADVANTAGE_SPELL_ID = 459964 

-- Invigorating Pulse (SV talent): Kill Command generates +5 focus; raises max focus to 125.
local INVIGORATING_PULSE_SPELL_ID = 450379

-- Takedown (SV): generates 50 focus on cast.
local SV_TAKEDOWN_ID   = 1250646 
local SV_TAKEDOWN_GAIN = 50

-- Muzzle (SV): generates 30 focus on cast.
local SV_MUZZLE_ID   = 187707
local SV_MUZZLE_GAIN = 30

local SV_ABILITY_COSTS = {
    [259495] = 10,  -- Wildfire Bomb
    [1261193] = 50,  -- Boomstick        (unverified)
    [193265] = 30,  -- Hatchet Toss     (unverified)
    [186270] = 30,  -- Raptor Strike
    [1262343] = 30,  -- Raptor Swipe
    [195645] = 20,  -- Wing Clip
    [1251592] = 20,  -- Flamefang Pitch  (unverified)
}

-- Shrapnel Bomb (SV talent): Wildfire Bomb generates 15 focus over 3 seconds.
local SHRAPNEL_BOMB_SPELL_ID    = 1253172
local SHRAPNEL_BOMB_DURATION    = 3
local SHRAPNEL_BOMB_REGEN_TOTAL = 15
local SHRAPNEL_BOMB_REGEN_RATE  = SHRAPNEL_BOMB_REGEN_TOTAL / SHRAPNEL_BOMB_DURATION  -- 5/sec

local SV_MELEE_WEAPON_BASE_INTERVAL = 1 / 1.8   -- seconds per auto attack per weapon

-- Haste multiplier shared with GuesstimatorHaste; falls back to 21% if that addon is absent.
_G.GuesstimatedHaste = _G.GuesstimatedHaste or 0.21

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
local currentSpec               = 0          -- active spec ID (253 = BM, 255 = SV); 0 = neither
local flankersAdvantageActive   = false      -- SV: Kill Command +5 focus (set by RefreshTalents)
local invPulseActive            = false      -- SV: Kill Command +5 focus + 125 max (set by RefreshTalents)
local shrapnelBombActive        = false      -- SV: Wildfire Bomb triggers 15 focus regen over 3s
local shrapnelBombExpiry        = {}         -- expiry timestamps for active Shrapnel Bomb regen windows
local ui                                     -- forward declaration; assigned after CreateFrame

local function IsPlayerClass(token)
    local _, classToken = UnitClass("player")
    return classToken == token
end

local function IsPlayerSpec(specID)
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    return select(1, GetSpecializationInfo(specIndex)) == specID
end

-- Refreshes talent-driven modifiers; called on login and whenever the loadout changes.
local function RefreshTalents()
    regenMultiplier = 1.0

    local apiMax = UnitPowerMax("player", FOCUS_POWER_TYPE)
    if apiMax and not issecretvalue(apiMax) then
        maxFocus = apiMax
    else
        maxFocus = 100   -- safe fallback
    end

    cobraSensesActive = IsPlayerSpell(COBRA_SENSES_SPELL_ID)

    if not InCombatLockdown() then
        local crit = GetRangedCritChance()
        if crit and not issecretvalue(crit) then
            lastKnownRangedCritChance = crit
            cobraCritExpectedRefund   = (lastKnownRangedCritChance / 100) * 10
        end
    end

    if currentSpec == SV_SPEC_ID then
        flankersAdvantageActive = IsPlayerSpell(FLANKERS_ADVANTAGE_SPELL_ID)
        invPulseActive          = IsPlayerSpell(INVIGORATING_PULSE_SPELL_ID)
        shrapnelBombActive      = IsPlayerSpell(SHRAPNEL_BOMB_SPELL_ID)
    else
        flankersAdvantageActive = false
        invPulseActive          = false
        shrapnelBombActive      = false
    end
    lethalBarbsActive = IsPlayerSpell(LETHAL_BARBS_SPELL_ID)

    if currentFocus > maxFocus then currentFocus = maxFocus end
end

-- Caches base (un-hasted) ranged weapon speed for auto-shot interval calculation.
local function RefreshWeaponSpeed()
    if InCombatLockdown() then return end
    local hastedSpeed = UnitAttackSpeed("player")
    if hastedSpeed and not issecretvalue(hastedSpeed) and hastedSpeed > 0 then
        local haste = _G.GuesstimatedHaste or 0
        baseRangedWeaponSpeed = hastedSpeed * (1 + haste)
    end
end

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
    addonEnabled            = false
    autoShotTimer           = 0
    playerInCombat          = false
    currentSpec             = 0
    flankersAdvantageActive = false
    invPulseActive          = false
    shrapnelBombActive      = false
    wipe(bardedShotRegenExpiry)
    wipe(shrapnelBombExpiry)
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
        frame:UnregisterAllEvents()
        ui:Hide()
        return
    end
    if IsPlayerSpec(REQUIRED_SPEC_ID) then
        currentSpec = REQUIRED_SPEC_ID
        RefreshTalents()
        RefreshWeaponSpeed()
        EnableAddon()
    elseif IsPlayerSpec(SV_SPEC_ID) then
        currentSpec = SV_SPEC_ID
        RefreshTalents()
        RefreshWeaponSpeed()
        EnableAddon()
    else
        currentSpec = 0
        DisableAddon()
    end
end

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
        UpdateEnabledState()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if select(1, ...) == "player" then UpdateEnabledState() end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if addonEnabled then RefreshTalents() end
        UpdateEnabledState()
        return
    end

    if not addonEnabled then return end

    if event == "PLAYER_REGEN_ENABLED" then
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
        playerInCombat = true
        autoShotTimer  = 0
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
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

        if currentSpec == SV_SPEC_ID then
            local gain = 0
            if spellID == 259489 then  -- Kill Command
                gain = SV_KILL_COMMAND_GAIN
                if flankersAdvantageActive then gain = gain + 5 end
                if invPulseActive          then gain = gain + 5 end
            elseif SV_TAKEDOWN_ID > 0 and spellID == SV_TAKEDOWN_ID then
                gain = SV_TAKEDOWN_GAIN
            elseif spellID == SV_MUZZLE_ID then
                gain = SV_MUZZLE_GAIN
            end
            if gain > 0 then
                currentFocus = math.min(maxFocus, currentFocus + gain)
            end

            if shrapnelBombActive and spellID == 259495 then  -- Wildfire Bomb
                shrapnelBombExpiry[#shrapnelBombExpiry + 1] = GetTime() + SHRAPNEL_BOMB_DURATION
            end

            local cost = SV_ABILITY_COSTS[spellID]
            if cost and cost > 0 then
                currentFocus = math.max(0, currentFocus - cost)
            end
            --print ("FG detected SV cast: " .. spellID .. " gaining focus: " .. gain)
            return  -- skip BM focus-cost logic below
        end

        local cost = ABILITY_COSTS[spellID]

        if spellID == COBRA_SHOT_ID then
            if cobraSensesActive then cost = cost - 5 end
            cost = cost - cobraCritExpectedRefund
        end

        if cost and cost > 0 then
            currentFocus = math.max(0, currentFocus - cost)
        elseif cost and cost < 0 then
            currentFocus = math.min(maxFocus, currentFocus - cost)
        end

        if spellID == BARBED_SHOT_ID then
            bardedShotRegenExpiry[#bardedShotRegenExpiry + 1] = GetTime() + BARBED_SHOT_DURATION
        end

    elseif event == "UNIT_POWER_UPDATE" then
        if currentSpec == REQUIRED_SPEC_ID then
            local powerType = select(2, ...)
            if powerType == "FOCUS" then
                local kcUsable = C_Spell.IsSpellUsable(34026)
                if not issecretvalue(kcUsable) and kcUsable then
                    if currentFocus < 30 then currentFocus = 30 end
                end
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

frame:SetScript("OnUpdate", function(self, elapsed)
    if not addonEnabled then return end

    local regenRate = BASE_REGEN * (1 + (_G.GuesstimatedHaste or 0)) * regenMultiplier

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
    for i = writeIdx + 1, #bardedShotRegenExpiry do
        bardedShotRegenExpiry[i] = nil
    end

    regenRate = regenRate + (activeStacks * BARBED_SHOT_REGEN_RATE)

    if currentFocus < maxFocus then
        currentFocus = math.min(maxFocus, currentFocus + (regenRate * elapsed))
    end

    if lethalBarbsActive and playerInCombat then
        local focusPerTick, interval
        if currentSpec == SV_SPEC_ID then
            focusPerTick = 2
            interval     = SV_MELEE_WEAPON_BASE_INTERVAL / (1 + (_G.GuesstimatedHaste or 0))
        elseif baseRangedWeaponSpeed > 0 then
            focusPerTick = 1
            interval     = baseRangedWeaponSpeed / (1 + (_G.GuesstimatedHaste or 0))
        end
        if interval then
            autoShotTimer = autoShotTimer + elapsed
            while autoShotTimer >= interval do
                autoShotTimer = autoShotTimer - interval
                currentFocus  = math.min(maxFocus, currentFocus + focusPerTick)
            end
        end
    end

    if currentSpec == SV_SPEC_ID and shrapnelBombActive then
        local activeBombs = 0
        local wIdx = 0
        for i = 1, #shrapnelBombExpiry do
            local expiry = shrapnelBombExpiry[i]
            if expiry > now then
                wIdx = wIdx + 1
                shrapnelBombExpiry[wIdx] = expiry
                activeBombs = activeBombs + 1
            end
        end
        for i = wIdx + 1, #shrapnelBombExpiry do shrapnelBombExpiry[i] = nil end
        if activeBombs > 0 then
            currentFocus = math.min(maxFocus, currentFocus + activeBombs * SHRAPNEL_BOMB_REGEN_RATE * elapsed)
        end
    end

    if ui:IsShown() then
        local actual = UnitPower("player", FOCUS_POWER_TYPE)
        ui.text:SetFormattedText("%d vs %s", math.floor(currentFocus), actual)
    end
end)

SLASH_FOCUSGUESSTIMATE1 = "/fg"
SlashCmdList["FOCUSGUESSTIMATE"] = function()
    if not IsPlayerClass(REQUIRED_CLASS) then return end
    if not IsPlayerSpec(REQUIRED_SPEC_ID) and not IsPlayerSpec(SV_SPEC_ID) then return end
    if ui:IsShown() then ui:Hide() else ui:Show() end
end
