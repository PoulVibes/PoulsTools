local FOLDER_NAME = "CombatCoach_OnUseTracker"
local ADDON_NAME  = "On Use Tracker"

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

-- ---- shmIcons icon slot definitions ----
local ICON_SIZE_DEFAULT = 64

local KEY_ZENITH       = "Zenith Buff"
local KEY_BW           = "Bestial Wrath Buff"
local KEY_BW_CD        = "Bestial Wrath Cooldown Timer"
local KEY_WFIRE        = "Withering Fire"
local KEY_BARBED       = "Barbed Shot Debuff"
local KEY_NATURES_ALLY = "Nature's Ally"
local KEY_BEAST_CLEAVE = "Beast Cleave"

local function DefaultSlotDB(x, y, spellID)
    return {
        x            = x,
        y            = y,
        point        = "CENTER",
        size         = ICON_SIZE_DEFAULT,
        enabled      = false,
        glow_enabled = false,
        spellID      = spellID,
    }
end

-- One entry per icon; specID gates registration to the right spec.
local SLOT_DEFS = {
    { key = KEY_ZENITH,       specID = 269, iconSpellID = 1249625 },
    { key = KEY_BW,           specID = 253, iconSpellID = 19574   },
    { key = KEY_BW_CD,        specID = 253, iconSpellID = 19574   },
    { key = KEY_WFIRE,        specID = 253, iconSpellID = 466990  },
    { key = KEY_BARBED,       specID = 253, iconSpellID = 217200  },
    { key = KEY_NATURES_ALLY, specID = 253, iconSpellID = 1273126 },
    { key = KEY_BEAST_CLEAVE, specID = 253, iconSpellID = 131251  },
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
local BARBED_SHOT_DEBUFF_BASE_DURATION = 12  -- 14 sec with Savagery
local SAVAGERY_TALENT_ID              = 131244  -- Barbed Shot lasts 2 sec longer (14 s total)
local NATURES_ALLY_RANK3_TALENT_ID    = 1273126 -- Nature's Ally (Rank 3): buff applied on BS/CS/BA, consumed on KC
local COBRA_SHOT_SPELL_ID             = 193455
local BLACK_ARROW_SPELL_ID            = 141219
local KILL_COMMAND_SPELL_ID           = 34026
local WILD_THRASH_SPELL_ID            = 131251
local UMBRAL_REACH_TALENT_ID          = 1235397 -- Beast Cleave on Dark Arrow when enemies > 1
local BEAST_CLEAVE_DURATION           = 8
local WITHERING_FIRE_TALENT_ID = 466990
local WITHERING_FIRE_DURATION = 10
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
local beastCleaveExpiresAt = 0
local beastCleaveTimer = nil
local beastCleaveTicker = nil

local function CancelTimer(timerObj)
    if timerObj and timerObj.Cancel then
        timerObj:Cancel()
    end
    return nil
end

-- ---- shmIcons icon state ----
local iconsRegistered        = false
local lockCallbackRegistered = false

local function ShowIcon(key, duration)
    if not iconsRegistered then return end
    shmIcons:SetVisible(ADDON_NAME, key, true)
    if duration and duration > 0 then
        shmIcons:SetCooldownRaw(ADDON_NAME, key, GetTime(), duration)
    end
    shmIcons:SetGlow(ADDON_NAME, key, true)
end

local function HideIcon(key)
    if not iconsRegistered then return end
    shmIcons:SetVisible(ADDON_NAME, key, false)
    shmIcons:SetCooldownRaw(ADDON_NAME, key, 0, 0)
    shmIcons:SetGlow(ADDON_NAME, key, false)
end

local function RegisterIcons()
    if iconsRegistered then return end
    OnUseTrackerDB = OnUseTrackerDB or {}
    local halfStep = ICON_SIZE_DEFAULT / 2 + 4
    local defaultPositions = {
        [KEY_ZENITH]       = { x =  0,         y =  0        },
        [KEY_BW]           = { x = -halfStep,   y =  halfStep },
        [KEY_BW_CD]        = { x =  halfStep,   y =  halfStep },
        [KEY_WFIRE]        = { x =  0,          y =  halfStep },
        [KEY_BARBED]       = { x = -halfStep,   y = -halfStep },
        [KEY_NATURES_ALLY] = { x =  halfStep,   y = -halfStep },
        [KEY_BEAST_CLEAVE] = { x =  0,          y = -halfStep },
    }
    for _, def in ipairs(SLOT_DEFS) do
        if def.specID == currentSpecID then
            local k = def.key
            local pos = defaultPositions[k] or { x = 0, y = 0 }
            if not OnUseTrackerDB[k] then
                OnUseTrackerDB[k] = DefaultSlotDB(pos.x, pos.y, def.iconSpellID)
            end
            local db = OnUseTrackerDB[k]
            shmIcons:Register(ADDON_NAME, k, db, {
                onResize = function(sq) db.size = sq end,
                onMove   = function() end,
            })
            shmIcons:SetIcon(ADDON_NAME, k, C_Spell.GetSpellTexture(def.iconSpellID))
            shmIcons:SetVisible(ADDON_NAME, k, false)
        end
    end
    if not lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
        lockCallbackRegistered = true
        shmIcons:RegisterLockCallback(function(locked)
            if locked and iconsRegistered then
                for _, def in ipairs(SLOT_DEFS) do
                    if def.specID == currentSpecID then
                        shmIcons:SetVisible(ADDON_NAME, def.key, false)
                        shmIcons:SetCooldownRaw(ADDON_NAME, def.key, 0, 0)
                        shmIcons:SetGlow(ADDON_NAME, def.key, false)
                    end
                end
            end
        end)
    end
    iconsRegistered = true
end

local function UnregisterIcons()
    if not iconsRegistered then return end
    for _, def in ipairs(SLOT_DEFS) do
        if def.specID == currentSpecID then
            shmIcons:Unregister(ADDON_NAME, def.key)
        end
    end
    iconsRegistered = false
end

local function ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = false
    _G["WitheringFireRemaining"] = 0
    witheringFireExpiresAt = 0
    witheringFireTimer = CancelTimer(witheringFireTimer)
    witheringFireTicker = CancelTimer(witheringFireTicker)
    HideIcon(KEY_WFIRE)
end

local function StartWitheringFireTracking(duration)
    ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = true
    _G["WitheringFireRemaining"] = duration
    witheringFireExpiresAt = GetTime() + duration
    ShowIcon(KEY_WFIRE, duration)

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
    HideIcon(KEY_BARBED)
end

local function StartBarbedShotTracking(duration)
    ClearBarbedShotTracking()
    _G["BarbedShotDebuffActiveTracker"] = true
    _G["BarbedShotDebuffRemaining"] = duration
    barbedShotExpiresAt = GetTime() + duration
    ShowIcon(KEY_BARBED, duration)

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
    HideIcon(KEY_BW_CD)
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
    ShowIcon(KEY_BW_CD, duration)

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

local function ClearBeastCleaveTracking()
    _G["BeastCleaveActiveTracker"] = false
    _G["BeastCleaveRemaining"] = 0
    beastCleaveExpiresAt = 0
    beastCleaveTimer = CancelTimer(beastCleaveTimer)
    beastCleaveTicker = CancelTimer(beastCleaveTicker)
    HideIcon(KEY_BEAST_CLEAVE)
end

local function StartBeastCleaveTracking()
    ClearBeastCleaveTracking()
    _G["BeastCleaveActiveTracker"] = true
    _G["BeastCleaveRemaining"] = BEAST_CLEAVE_DURATION
    beastCleaveExpiresAt = GetTime() + BEAST_CLEAVE_DURATION
    ShowIcon(KEY_BEAST_CLEAVE, BEAST_CLEAVE_DURATION)

    beastCleaveTicker = C_Timer.NewTicker(0.1, function()
        local remains = beastCleaveExpiresAt - GetTime()
        if remains > 0 then
            _G["BeastCleaveRemaining"] = remains
        else
            ClearBeastCleaveTracking()
        end
    end)

    beastCleaveTimer = C_Timer.NewTimer(BEAST_CLEAVE_DURATION, function()
        ClearBeastCleaveTracking()
    end)
end

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
    if not iconsRegistered then RegisterIcons() end
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    _G["BestialWrathActiveTracker"] = false
    _G["ZenithActiveTracker"] = false
    HideIcon(KEY_ZENITH)
    HideIcon(KEY_BW)
    ClearWitheringFireTracking()
    ClearBarbedShotTracking()
    ClearBestialWrathCooldownTracking()
    _G["NaturesAllyActiveTracker"] = false
    HideIcon(KEY_NATURES_ALLY)
    ClearBeastCleaveTracking()
    UnregisterIcons()
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
_G["NaturesAllyActiveTracker"] = false
_G["BeastCleaveActiveTracker"] = false
_G["BeastCleaveRemaining"] = 0

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
    if event == "ADDON_LOADED" and unit == FOLDER_NAME then
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
        local debuffDuration = BARBED_SHOT_DEBUFF_BASE_DURATION + (IsPlayerSpell(SAVAGERY_TALENT_ID) and 2 or 0)
        StartBarbedShotTracking(debuffDuration)
        if IsPlayerSpell(NATURES_ALLY_RANK3_TALENT_ID) then
            _G["NaturesAllyActiveTracker"] = true
            ShowIcon(KEY_NATURES_ALLY, nil)
        end
    end

    if unit == "player" and currentSpecID == TRACKED_SPECS["HUNTER"] then
        if (spellID == COBRA_SHOT_SPELL_ID or spellID == BLACK_ARROW_SPELL_ID) and IsPlayerSpell(NATURES_ALLY_RANK3_TALENT_ID) then
            _G["NaturesAllyActiveTracker"] = true
            ShowIcon(KEY_NATURES_ALLY, nil)
        elseif spellID == KILL_COMMAND_SPELL_ID then
            _G["NaturesAllyActiveTracker"] = false
            HideIcon(KEY_NATURES_ALLY)
        end
        if spellID == WILD_THRASH_SPELL_ID then
            StartBeastCleaveTracking()
        elseif spellID == BLACK_ARROW_SPELL_ID
            and IsPlayerSpell(UMBRAL_REACH_TALENT_ID)
            and (_G.ECT_TargetCount or 0) > 1 then
            StartBeastCleaveTracking()
        end
    end

    if unit == "player" and currentSpecID and SPEC_SPELL_IDS[currentSpecID][spellID] and not _G["ZenithActiveTracker"] then
        _G["ZenithActiveTracker"] = true
        _G["BestialWrathActiveTracker"] = (spellID == BESTIAL_WRATH_SPELL_ID)
        if spellID == BESTIAL_WRATH_SPELL_ID then
            StartBestialWrathCooldownTracking(ResolveBestialWrathCooldownDuration())
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
        if currentSpecID == TRACKED_SPECS["MONK"] then
            ShowIcon(KEY_ZENITH, duration)
        elseif currentSpecID == TRACKED_SPECS["HUNTER"] then
            ShowIcon(KEY_BW, duration)
        end
        onUseWindowTimer = CancelTimer(onUseWindowTimer)
        onUseWindowTimer = C_Timer.NewTimer(duration, function()
            onUseWindowTimer = nil
            _G["ZenithActiveTracker"] = false
            _G["BestialWrathActiveTracker"] = false
            HideIcon(KEY_ZENITH)
            HideIcon(KEY_BW)
            iconFrame:Hide()
        end)
    end
end)
