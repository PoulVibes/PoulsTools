local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- Multi-spec tracking: Windwalker Monk and Beast Mastery Hunter
local TRACKED_SPECS = {
    ["MONK"]   = 269,  -- Windwalker
    ["HUNTER"] = 253,  -- Beast Mastery
}

-- Spell ID registry per spec
local SPEC_SPELL_IDS = {
    [269] = {  -- Windwalker
        [1249625] = true, -- Zenith (Main Talent ID)
        [1249763] = true, -- Zenith (Mastery Trigger ID)
        [1272696] = true, -- Zenith Stomp
    },
    [253] = {  -- Beast Mastery
        [19574] = true,   -- Bestial Wrath
    },
}

-- Icon texture per spec
local SPEC_ICON_TEXTURES = {
    [269] = 1249625,  -- Zenith icon
    [253] = 19574,    -- Bestial Wrath icon
}

-- Timer duration per spec
local SPEC_TIMER_DURATIONS = {
    [269] = { base = 15, talentID = 391370, talentDuration = 20 },  -- Windwalker: Drinking Horn Cover
    [253] = { base = 15 },  -- Beast Mastery: always 15 seconds
}

local addonEnabled = false
local iconFrame
local currentSpecID = nil  -- Track current spec ID for spell/icon/timer logic
local BESTIAL_WRATH_SPELL_ID = 19574
local BESTIAL_WRATH_BASE_COOLDOWN = 90
local BESTIAL_WRATH_WITH_BEAST_WITHIN_COOLDOWN = 30
local THE_BEAST_WITHIN_TALENT_ID = 231548
local BARBED_SHOT_SPELL_ID = 217200
local BARBED_SHOT_DEBUFF_DURATION = 12
local BARBED_SHOT_MAX_CHARGES = 2
local BARBED_SHOT_BASE_RECHARGE = 18  -- seconds, affected by haste
local SCENT_OF_BLOOD_TALENT_ID = 193532
local BARBED_SCALES_TALENT_ID = 469880
local BARBED_SCALES_CDR = 2  -- seconds reduced per Cobra Shot cast
local COBRA_SHOT_SPELL_ID = 193455
local WITHERING_FIRE_TALENT_ID = 466990
local WITHERING_FIRE_DURATION = 10
-- Pack Mentality: summoning a pet reduces Barbed Shot CD by 4 seconds
local PACK_MENTALITY_TALENT_ID        = 472358
local PACK_MENTALITY_CDR              = 4
local SHELL_COVER_TALENT_ID           = 472707   -- makes Survival of the Fittest summon a pet
local SURVIVAL_OF_THE_FITTEST_SPELL_ID = 264735
local HOWL_OF_THE_PACK_LEADER_TALENT_ID = 471876 -- Kill Command glow removed = pet summoned
local DIRE_COMMAND_TALENT_ID          = 378743   -- 20% chance on Kill Command; use expected 0.8 s
local DIRE_COMMAND_EXPECTED_CDR       = 0.8
local KILL_COMMAND_SPELL_ID           = 34026
local CALL_PET_SPELL_ID               = 9
local witheringFireExpiresAt = 0
local barbedShotExpiresAt = 0
local onUseWindowTimer = nil
local witheringFireTimer = nil
local witheringFireTicker = nil
local barbedShotTimer = nil
local barbedShotTicker = nil
local bestialWrathCooldownExpiresAt = 0
local bestialWrathCooldownTimer = nil
local bestialWrathCooldownTicker = nil
-- Barbed Shot charge tracking
local barbedShotCharges = BARBED_SHOT_MAX_CHARGES
local barbedShotRechargeExpiries = {}  -- one entry per charge currently on cooldown
local barbedShotChargeTicker = nil
local howlProcWasActive = false  -- edge-detect howl_proc_active falling edge

local function CancelTimer(timerObj)
    if timerObj and timerObj.Cancel then
        timerObj:Cancel()
    end
    return nil
end

local function ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = false
    _G["WitheringFireRemaining"] = 0
    witheringFireExpiresAt = 0
    witheringFireTimer = CancelTimer(witheringFireTimer)
    witheringFireTicker = CancelTimer(witheringFireTicker)
end

local function StartWitheringFireTracking(duration)
    ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = true
    _G["WitheringFireRemaining"] = duration
    witheringFireExpiresAt = GetTime() + duration

    -- Low-frequency ticker keeps remaining time updated without per-frame OnUpdate work.
    witheringFireTicker = C_Timer.NewTicker(0.1, function()
        local remains = witheringFireExpiresAt - GetTime()
        if remains > 0 then
            _G["WitheringFireRemaining"] = remains
        else
            ClearWitheringFireTracking()
        end
    end)

    witheringFireTimer = C_Timer.NewTimer(duration, function()
        ClearWitheringFireTracking()
    end)
end

local function ClearBarbedShotTracking()
    _G["BarbedShotDebuffActiveTracker"] = false
    _G["BarbedShotDebuffRemaining"] = 0
    barbedShotExpiresAt = 0
    barbedShotTimer = CancelTimer(barbedShotTimer)
    barbedShotTicker = CancelTimer(barbedShotTicker)
end

local function StartBarbedShotTracking(duration)
    ClearBarbedShotTracking()
    _G["BarbedShotDebuffActiveTracker"] = true
    _G["BarbedShotDebuffRemaining"] = duration
    barbedShotExpiresAt = GetTime() + duration

    barbedShotTicker = C_Timer.NewTicker(0.1, function()
        local remains = barbedShotExpiresAt - GetTime()
        if remains > 0 then
            _G["BarbedShotDebuffRemaining"] = remains
        else
            ClearBarbedShotTracking()
        end
    end)

    barbedShotTimer = C_Timer.NewTimer(duration, function()
        ClearBarbedShotTracking()
    end)
end

local function ClearBestialWrathCooldownTracking()
    _G["BestialWrathCooldownActiveTracker"] = false
    _G["BestialWrathCooldownRemaining"] = 0
    bestialWrathCooldownExpiresAt = 0
    bestialWrathCooldownTimer = CancelTimer(bestialWrathCooldownTimer)
    bestialWrathCooldownTicker = CancelTimer(bestialWrathCooldownTicker)
end

local function ResolveBestialWrathCooldownDuration()
    if IsPlayerSpell(THE_BEAST_WITHIN_TALENT_ID) then
        return BESTIAL_WRATH_WITH_BEAST_WITHIN_COOLDOWN
    end
    return BESTIAL_WRATH_BASE_COOLDOWN
end

local function StartBestialWrathCooldownTracking(duration)
    ClearBestialWrathCooldownTracking()
    _G["BestialWrathCooldownActiveTracker"] = true
    _G["BestialWrathCooldownRemaining"] = duration
    bestialWrathCooldownExpiresAt = GetTime() + duration

    bestialWrathCooldownTicker = C_Timer.NewTicker(0.1, function()
        local remains = bestialWrathCooldownExpiresAt - GetTime()
        if remains > 0 then
            _G["BestialWrathCooldownRemaining"] = remains
        else
            ClearBestialWrathCooldownTracking()
        end
    end)

    bestialWrathCooldownTimer = C_Timer.NewTimer(duration, function()
        ClearBestialWrathCooldownTracking()
    end)
end

local function GetBarbedShotRechargeTime()
    local haste = _G.GuesstimatedHaste or 0
    return BARBED_SHOT_BASE_RECHARGE / (1 + haste)
end

-- Sync globals from local state and prune any expired recharge entries.
local function UpdateBarbedShotChargeState()
    local now = GetTime()

    -- If the API says the spell has no real cooldown active it is fully recharged.
    -- NOTE: intentionally not checking OnGCD here — the GCD fires immediately
    -- after every cast and would falsely signal "full charges" for ~1.5 s.
    local cd = C_Spell.GetSpellCooldown(BARBED_SHOT_SPELL_ID)
    --if cd and not cd.isActive then
    --    barbedShotRechargeExpiries = {}
    --    barbedShotCharges = BARBED_SHOT_MAX_CHARGES
    --    _G["BarbedShotCharges"] = barbedShotCharges
    --    _G["BarbedShotRechargeRemaining"] = 0
    --    return
    --end

    -- Remove expiries that have already elapsed (those charges came back).
    local active = {}
    for _, expiry in ipairs(barbedShotRechargeExpiries) do
        if expiry > now then
            active[#active + 1] = expiry
        end
    end
    barbedShotRechargeExpiries = active
    barbedShotCharges = BARBED_SHOT_MAX_CHARGES - #active

    -- Expose the time until the next charge recharges (the earliest expiry).
    local earliest = math.huge
    for _, expiry in ipairs(active) do
        if expiry < earliest then earliest = expiry end
    end
    _G["BarbedShotCharges"] = barbedShotCharges
    _G["BarbedShotRechargeRemaining"] = (earliest < math.huge) and math.max(0, earliest - now) or 0
end

-- Forward declaration so On* functions below can call UpdateBarbedShotDebugIcon().
-- The actual definition lives in the debug block further down.
local UpdateBarbedShotDebugIcon

local function OnBarbedShotUsed()
    -- Deduct one charge and record when it will come back.
    -- Barbed Shot uses SEQUENTIAL recharging: the second charge doesn't start
    -- recharging until the first is fully recharged.  Pin the new expiry to the
    -- latest pending expiry + recharge time, not simply now + recharge time.
    if barbedShotCharges > 0 then
        barbedShotCharges = barbedShotCharges - 1
    end
    local T = GetBarbedShotRechargeTime()
    local startFrom = GetTime()
    for _, exp in ipairs(barbedShotRechargeExpiries) do
        if exp > startFrom then startFrom = exp end
    end
    barbedShotRechargeExpiries[#barbedShotRechargeExpiries + 1] = startFrom + T
    _G["BarbedShotCharges"] = barbedShotCharges
end

local function OnBestialWrathUsed_ScentOfBlood()
    -- Scent of Blood: Bestial Wrath instantly refunds 1 Barbed Shot charge.
    if not IsPlayerSpell(SCENT_OF_BLOOD_TALENT_ID) then return end
    if #barbedShotRechargeExpiries == 0 then return end
    -- Remove the earliest pending recharge (the one currently counting down).
    table.sort(barbedShotRechargeExpiries)
    table.remove(barbedShotRechargeExpiries, 1)
    barbedShotCharges = math.min(BARBED_SHOT_MAX_CHARGES, barbedShotCharges + 1)
    _G["BarbedShotCharges"] = barbedShotCharges
    -- The remaining charge was waiting for the removed one to finish (sequential
    -- model).  It now starts recharging from this moment.
    if #barbedShotRechargeExpiries > 0 then
        barbedShotRechargeExpiries[1] = GetTime() + GetBarbedShotRechargeTime()
    end
    UpdateBarbedShotChargeState()
    UpdateBarbedShotDebugIcon()
    print(string.format("|cffff9900[BS-CDR]|r ScentOfBlood (Bestial Wrath): +1 charge → charges=%d remaining=%.2fs",
        _G["BarbedShotCharges"], _G["BarbedShotRechargeRemaining"]))
end

-- Shared CDR helper: reduce only the currently-recharging (earliest) expiry,
-- then re-pin any subsequent expiries sequentially (they haven't started yet).
local function ApplyCDRToRechargeExpiries(amount)
    if #barbedShotRechargeExpiries == 0 then return end
    local now = GetTime()
    local T = GetBarbedShotRechargeTime()
    table.sort(barbedShotRechargeExpiries)
    barbedShotRechargeExpiries[1] = math.max(now, barbedShotRechargeExpiries[1] - amount)
    -- Re-pin subsequent charges: each one starts after the previous finishes.
    for i = 2, #barbedShotRechargeExpiries do
        barbedShotRechargeExpiries[i] = barbedShotRechargeExpiries[i-1] + T
    end
end

local function OnCobraShotUsed_BarbedScales()
    -- Barbed Scales: each Cobra Shot reduces Barbed Shot recharge by 2 seconds.
    if not IsPlayerSpell(BARBED_SCALES_TALENT_ID) then return end
    if #barbedShotRechargeExpiries == 0 then return end
    ApplyCDRToRechargeExpiries(BARBED_SCALES_CDR)
    UpdateBarbedShotChargeState()
end

-- Apply Pack Mentality CDR (pet summoned): reduce every active recharge by amount.
local function ApplyPackMentalityCDR(amount, reason)
    if not IsPlayerSpell(PACK_MENTALITY_TALENT_ID) then return end
    if #barbedShotRechargeExpiries == 0 then return end
    ApplyCDRToRechargeExpiries(amount)
    UpdateBarbedShotChargeState()
    print(string.format("|cffff9900[BS-CDR]|r %s: -%.1fs → charges=%d remaining=%.2fs",
        reason or "unknown", amount, _G["BarbedShotCharges"], _G["BarbedShotRechargeRemaining"]))
end

local function ClearBarbedShotChargeTracking()
    barbedShotCharges = BARBED_SHOT_MAX_CHARGES
    barbedShotRechargeExpiries = {}
    barbedShotChargeTicker = CancelTimer(barbedShotChargeTicker)
    howlProcWasActive = false
    _G["BarbedShotCharges"] = BARBED_SHOT_MAX_CHARGES
    _G["BarbedShotRechargeRemaining"] = 0
end

-- ── TEMPORARY DEBUG: shmIcon showing tracked Barbed Shot charges + recharge ──
-- Remove this block (and the TOC Dependencies line) once confirmed correct.
local ADDON_NAME_OUT = "PoulsTools_OnUseTracker"
local BS_DEBUG_KEY   = "barbed_shot_debug"
local bsDebugDB      = { x = 0, y = -160, point = "CENTER", size = 64, enabled = true, glow_enabled = false, spellID = BARBED_SHOT_SPELL_ID }
local bsDebugIcon    = nil

local function RegisterBarbedShotDebugIcon()
    if bsDebugIcon then return end
    if not shmIcons then return end
    bsDebugIcon = shmIcons:Register(ADDON_NAME_OUT, BS_DEBUG_KEY, bsDebugDB, {
        onResize = function(sq) bsDebugDB.size = sq end,
        onMove   = function(_)  end,
    })
    shmIcons:SetIcon(ADDON_NAME_OUT, BS_DEBUG_KEY, C_Spell.GetSpellTexture(BARBED_SHOT_SPELL_ID))
end

local function UnregisterBarbedShotDebugIcon()
    if not bsDebugIcon then return end
    shmIcons:SetVisible(ADDON_NAME_OUT, BS_DEBUG_KEY, false)
    shmIcons:Unregister(ADDON_NAME_OUT, BS_DEBUG_KEY)
    bsDebugIcon = nil
end

UpdateBarbedShotDebugIcon = function()
    if not bsDebugIcon then return end
    -- Drive from our own tracked expiries so CDR adjustments show immediately,
    -- and so the sweep is visible in both the 0-charge and 1-charge cases.
    -- (C_Spell.GetSpellCooldownDuration returns nil when the spell has >=1 charge,
    -- so the API-based approach misses the 1-charge recharge sweep entirely.)
    if #barbedShotRechargeExpiries > 0 then
        local earliest = math.huge
        for _, exp in ipairs(barbedShotRechargeExpiries) do
            if exp < earliest then earliest = exp end
        end
        local T = GetBarbedShotRechargeTime()
        shmIcons:SetCooldownRaw(ADDON_NAME_OUT, BS_DEBUG_KEY, earliest - T, T)
    else
        shmIcons:SetCooldownRaw(ADDON_NAME_OUT, BS_DEBUG_KEY, 0, 0)
    end
    shmIcons:SetChargeCooldown(ADDON_NAME_OUT, BS_DEBUG_KEY, nil)
    shmIcons:SetStacks(ADDON_NAME_OUT, BS_DEBUG_KEY, _G["BarbedShotCharges"])
end
-- ── END TEMPORARY DEBUG ───────────────────────────────────────────────────────

local function IsPlayerSpec(specID)
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local id = select(1, GetSpecializationInfo(specIndex))
    return id == specID
end

local function GetCurrentTrackedSpec()
    local _, classToken = UnitClass("player")
    local trackedSpecID = TRACKED_SPECS[classToken]
    if trackedSpecID and IsPlayerSpec(trackedSpecID) then
        return trackedSpecID
    end
    return nil
end

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    -- Poll Barbed Shot charge state at 0.1 s intervals.
    barbedShotChargeTicker = C_Timer.NewTicker(0.1, function()
        UpdateBarbedShotChargeState()
        UpdateBarbedShotDebugIcon()
        -- Howl of the Pack Leader: detect falling edge of Kill Command glow.
        -- When the glow is removed the hunter's pet is summoned (Pack Mentality CDR).
        if IsPlayerSpell(HOWL_OF_THE_PACK_LEADER_TALENT_ID) then
            local howlNow = _G["howl_proc_active"] and true or false
            if howlProcWasActive and not howlNow then
                ApplyPackMentalityCDR(PACK_MENTALITY_CDR, "HowlOfThePackLeader (glow removed)")
            end
            howlProcWasActive = howlNow
        end
    end)
    RegisterBarbedShotDebugIcon()
    shmIcons:SetVisible(ADDON_NAME_OUT, BS_DEBUG_KEY, true)
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    _G["BestialWrathActiveTracker"] = false
    _G["ZenithActiveTracker"] = false
    ClearWitheringFireTracking()
    ClearBarbedShotTracking()
    ClearBestialWrathCooldownTracking()
    ClearBarbedShotChargeTracking()
    UnregisterBarbedShotDebugIcon()
    iconFrame:Hide()
end

local function UpdateEnabledState()
    local specID = GetCurrentTrackedSpec()
    if specID then
        currentSpecID = specID
        EnableAddon()
    else
        currentSpecID = nil
        DisableAddon()
    end
end

-- Keep legacy globals for SBA plugin compatibility.
_G["ZenithActiveTracker"] = false
_G["BestialWrathActiveTracker"] = false
_G["BestialWrathCooldownActiveTracker"] = false
_G["BestialWrathCooldownRemaining"] = 0
_G["WitheringFireActiveTracker"] = false
_G["WitheringFireRemaining"] = 0
_G["BarbedShotDebuffActiveTracker"] = false
_G["BarbedShotDebuffRemaining"] = 0
_G["BarbedShotCharges"] = BARBED_SHOT_MAX_CHARGES
_G["BarbedShotRechargeRemaining"] = 0

local OUT_IconEnabled = false

-- Create the visual icon
iconFrame = CreateFrame("Frame", "OnUseTrackerIcon", UIParent)
iconFrame:SetSize(64, 64)
iconFrame:SetPoint("CENTER", 0, 0)
iconFrame:Hide()

local texture = iconFrame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(iconFrame)

local function UpdateIconTexture()
    if currentSpecID then
        local spellID = SPEC_ICON_TEXTURES[currentSpecID]
        if spellID then
            texture:SetTexture(C_Spell.GetSpellTexture(spellID))
        end
    end
end

-- Slash command
SLASH_OUT1 = "/out"
SlashCmdList["OUT"] = function(_)
    OUT_IconEnabled = not OUT_IconEnabled
    if not OUT_IconEnabled then iconFrame:Hide() end
end

local function UpdateTimerDuration()
    if not currentSpecID then return 15 end
    local specConfig = SPEC_TIMER_DURATIONS[currentSpecID]
    if not specConfig then return 15 end

    local baseDuration = specConfig.base or 15
    if specConfig.talentID and IsPlayerSpell(specConfig.talentID) then
        return specConfig.talentDuration or baseDuration
    end
    return baseDuration
end

frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "ADDON_LOADED" and unit == "PoulsTools_OnUseTracker" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_LOGIN" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit == "player" then
            UpdateEnabledState()
            UpdateIconTexture()
        end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if not addonEnabled then return end

    if unit == "player" and currentSpecID == TRACKED_SPECS["HUNTER"] and spellID == BARBED_SHOT_SPELL_ID then
        StartBarbedShotTracking(BARBED_SHOT_DEBUFF_DURATION)
        OnBarbedShotUsed()
    end

    if unit == "player" and currentSpecID == TRACKED_SPECS["HUNTER"] and spellID == COBRA_SHOT_SPELL_ID then
        OnCobraShotUsed_BarbedScales()
    end

    -- Pack Mentality: pet-summoning abilities reduce Barbed Shot cooldown.
    if unit == "player" and currentSpecID == TRACKED_SPECS["HUNTER"] then
        if spellID == CALL_PET_SPELL_ID then
            -- Call Pet always summons.
            ApplyPackMentalityCDR(PACK_MENTALITY_CDR, "CallPet")
        elseif spellID == SURVIVAL_OF_THE_FITTEST_SPELL_ID and IsPlayerSpell(SHELL_COVER_TALENT_ID) then
            -- Shell Cover: Survival of the Fittest summons a pet.
            ApplyPackMentalityCDR(PACK_MENTALITY_CDR, "SurvivalOfTheFittest+ShellCover")
        elseif spellID == KILL_COMMAND_SPELL_ID and IsPlayerSpell(DIRE_COMMAND_TALENT_ID) then
            -- Dire Command: 20% chance per Kill Command; apply expected value CDR.
            ApplyPackMentalityCDR(DIRE_COMMAND_EXPECTED_CDR, "KillCommand+DireCommand (expected)")
        end
    end
    -- (Howl of the Pack Leader is handled in the ticker via howl_proc_active falling edge.)

    if unit == "player" and currentSpecID and SPEC_SPELL_IDS[currentSpecID][spellID] and not _G["ZenithActiveTracker"] then
        _G["ZenithActiveTracker"] = true
        _G["BestialWrathActiveTracker"] = (spellID == BESTIAL_WRATH_SPELL_ID)
        if spellID == BESTIAL_WRATH_SPELL_ID then
            StartBestialWrathCooldownTracking(ResolveBestialWrathCooldownDuration())
            OnBestialWrathUsed_ScentOfBlood()
        end

        if spellID == BESTIAL_WRATH_SPELL_ID and IsPlayerSpell(WITHERING_FIRE_TALENT_ID) then
            StartWitheringFireTracking(WITHERING_FIRE_DURATION)
        else
            ClearWitheringFireTracking()
        end
        if OUT_IconEnabled then
            iconFrame:Show()
        end

        local duration = UpdateTimerDuration()
        onUseWindowTimer = CancelTimer(onUseWindowTimer)
        onUseWindowTimer = C_Timer.NewTimer(duration, function()
            onUseWindowTimer = nil
            _G["ZenithActiveTracker"] = false
            _G["BestialWrathActiveTracker"] = false
            iconFrame:Hide()
        end)
    end
end)
