-- OnUseTracker_Hunter.lua
-- Beast Mastery Hunter module for OnUseTracker.
-- Registered with OnUseTracker_RegisterModule() so the main file can delegate to it.

local ADDON_NAME = "On Use Tracker"

local SPEC_ID           = 253  -- Beast Mastery Hunter
local ICON_SIZE_DEFAULT = 64

local KEY_BW           = "Bestial Wrath Buff"
local KEY_BW_CD        = "Bestial Wrath Cooldown Timer"
local KEY_WFIRE        = "Withering Fire"
local KEY_BARBED       = "Barbed Shot Debuff"
local KEY_NATURES_ALLY = "Nature's Ally"
local KEY_BEAST_CLEAVE = "Beast Cleave"

local SLOT_DEFS = {
    { key = KEY_BW,           iconSpellID = 19574   },
    { key = KEY_BW_CD,        iconSpellID = 19574   },
    { key = KEY_WFIRE,        iconSpellID = 466990  },
    { key = KEY_BARBED,       iconSpellID = 217200  },
    { key = KEY_NATURES_ALLY, iconSpellID = 1273043,  },
    { key = KEY_BEAST_CLEAVE, iconSpellID = 115939 },
}

local BESTIAL_WRATH_SPELL_ID                   = 19574
local BESTIAL_WRATH_BASE_COOLDOWN              = 90
local BESTIAL_WRATH_WITH_BEAST_WITHIN_COOLDOWN = 30
local THE_BEAST_WITHIN_TALENT_ID               = 231548
local BW_TIMER_BASE                            = 15

local BARBED_SHOT_SPELL_ID             = 217200
local BARBED_SHOT_DEBUFF_BASE_DURATION = 12  -- 14 sec with Savagery
local SAVAGERY_TALENT_ID               = 131244  -- Barbed Shot lasts 2 sec longer (14 s total)

local NATURES_ALLY_RANK3_TALENT_ID = 1273126  -- Nature's Ally (Rank 3)
local COBRA_SHOT_SPELL_ID          = 193455
local BLACK_ARROW_SPELL_ID         = 466930
local KILL_COMMAND_SPELL_ID        = 34026

local WILD_THRASH_SPELL_ID     = 1264359
local UMBRAL_REACH_TALENT_ID   = 1235397  -- Beast Cleave on Dark Arrow when enemies > 1
local BEAST_CLEAVE_DURATION    = 8

local WITHERING_FIRE_TALENT_ID = 466990
local WITHERING_FIRE_DURATION  = 10

local iconsRegistered        = false
local lockCallbackRegistered = false
local iconFrameRef           = nil

local witheringFireExpiresAt        = 0
local barbedShotExpiresAt           = 0
local bestialWrathCooldownExpiresAt = 0
local beastCleaveExpiresAt          = 0

local onUseWindowTimer           = nil
local witheringFireTimer         = nil
local witheringFireTicker        = nil
local barbedShotTimer            = nil
local barbedShotTicker           = nil
local bestialWrathCooldownTimer  = nil
local bestialWrathCooldownTicker = nil
local beastCleaveTimer           = nil
local beastCleaveTicker          = nil

local function CancelTimer(timerObj)
    if timerObj and timerObj.Cancel then timerObj:Cancel() end
    return nil
end

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
        [KEY_BW]           = { x = -halfStep, y =  halfStep },
        [KEY_BW_CD]        = { x =  halfStep, y =  halfStep },
        [KEY_WFIRE]        = { x =  0,        y =  halfStep },
        [KEY_BARBED]       = { x = -halfStep, y = -halfStep },
        [KEY_NATURES_ALLY] = { x =  halfStep, y = -halfStep },
        [KEY_BEAST_CLEAVE] = { x =  0,        y = -halfStep },
    }
    for _, def in ipairs(SLOT_DEFS) do
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
        shmIcons:SetIcon(ADDON_NAME, k, def.iconTexture or C_Spell.GetSpellTexture(def.iconSpellID))
        shmIcons:SetVisible(ADDON_NAME, k, false)
    end
    if not lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
        lockCallbackRegistered = true
        shmIcons:RegisterLockCallback(function(locked)
            if locked and iconsRegistered then
                for _, def in ipairs(SLOT_DEFS) do
                    shmIcons:SetVisible(ADDON_NAME, def.key, false)
                    shmIcons:SetCooldownRaw(ADDON_NAME, def.key, 0, 0)
                    shmIcons:SetGlow(ADDON_NAME, def.key, false)
                end
            end
        end)
    end
    iconsRegistered = true
end

local function UnregisterIcons()
    if not iconsRegistered then return end
    for _, def in ipairs(SLOT_DEFS) do
        shmIcons:Unregister(ADDON_NAME, def.key)
    end
    iconsRegistered = false
end

-- ---- Withering Fire tracking ----

local function ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = false
    _G["WitheringFireRemaining"] = 0
    witheringFireExpiresAt = 0
    witheringFireTimer  = CancelTimer(witheringFireTimer)
    witheringFireTicker = CancelTimer(witheringFireTicker)
    HideIcon(KEY_WFIRE)
end

local function StartWitheringFireTracking(duration)
    ClearWitheringFireTracking()
    _G["WitheringFireActiveTracker"] = true
    _G["WitheringFireRemaining"] = duration
    witheringFireExpiresAt = GetTime() + duration
    ShowIcon(KEY_WFIRE, duration)

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

-- ---- Barbed Shot tracking ----

local function ClearBarbedShotTracking()
    _G["BarbedShotDebuffActiveTracker"] = false
    _G["BarbedShotDebuffRemaining"] = 0
    barbedShotExpiresAt = 0
    barbedShotTimer  = CancelTimer(barbedShotTimer)
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

-- ---- Bestial Wrath cooldown tracking ----

local function ClearBestialWrathCooldownTracking()
    _G["BestialWrathCooldownActiveTracker"] = false
    _G["BestialWrathCooldownRemaining"] = 0
    bestialWrathCooldownExpiresAt = 0
    bestialWrathCooldownTimer  = CancelTimer(bestialWrathCooldownTimer)
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

-- ---- Beast Cleave tracking ----

local function ClearBeastCleaveTracking()
    _G["BeastCleaveActiveTracker"] = false
    _G["BeastCleaveRemaining"] = 0
    beastCleaveExpiresAt = 0
    beastCleaveTimer  = CancelTimer(beastCleaveTimer)
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

-- ---- Module interface ----

local module = {}
module.specID = SPEC_ID

function module.GetIconTextureSpellID()
    return BESTIAL_WRATH_SPELL_ID
end

function module.GetTimerDuration()
    return BW_TIMER_BASE
end

function module.Enable(iconFrame)
    iconFrameRef = iconFrame
    if not iconsRegistered then RegisterIcons() end
end

function module.Disable()
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    _G["BestialWrathActiveTracker"] = false
    HideIcon(KEY_BW)
    ClearWitheringFireTracking()
    ClearBarbedShotTracking()
    ClearBestialWrathCooldownTracking()
    _G["NaturesAllyActiveTracker"] = false
    HideIcon(KEY_NATURES_ALLY)
    ClearBeastCleaveTracking()
    UnregisterIcons()
    if iconFrameRef then iconFrameRef:Hide() end
end

function module.OnSpellCast(spellID, outIconEnabled)
    -- Barbed Shot debuff + Nature's Ally (Rank 3) on BS
    if spellID == BARBED_SHOT_SPELL_ID then
        local debuffDuration = BARBED_SHOT_DEBUFF_BASE_DURATION + (IsPlayerSpell(SAVAGERY_TALENT_ID) and 2 or 0)
        StartBarbedShotTracking(debuffDuration)
        if IsPlayerSpell(NATURES_ALLY_RANK3_TALENT_ID) then
            _G["NaturesAllyActiveTracker"] = true
            ShowIcon(KEY_NATURES_ALLY, nil)
        end
    end

    -- Nature's Ally (Rank 3): applied on CS/Dark Arrow, consumed on KC
    if (spellID == COBRA_SHOT_SPELL_ID or spellID == BLACK_ARROW_SPELL_ID) and IsPlayerSpell(NATURES_ALLY_RANK3_TALENT_ID) then
        _G["NaturesAllyActiveTracker"] = true
        ShowIcon(KEY_NATURES_ALLY, nil)
    elseif spellID == KILL_COMMAND_SPELL_ID then
        _G["NaturesAllyActiveTracker"] = false
        HideIcon(KEY_NATURES_ALLY)
    end

    -- Beast Cleave: Wild Thrash always; Dark Arrow with Umbral Reach when multi-target
    if spellID == WILD_THRASH_SPELL_ID then
        StartBeastCleaveTracking()
    elseif spellID == BLACK_ARROW_SPELL_ID
        and IsPlayerSpell(UMBRAL_REACH_TALENT_ID)
        and (_G.ECT_TargetCount or 0) > 1 then
        StartBeastCleaveTracking()
    end

    -- Bestial Wrath main window
    if spellID == BESTIAL_WRATH_SPELL_ID and not _G["BestialWrathActiveTracker"] then
        _G["BestialWrathActiveTracker"] = true
        StartBestialWrathCooldownTracking(ResolveBestialWrathCooldownDuration())

        if IsPlayerSpell(WITHERING_FIRE_TALENT_ID) then
            StartWitheringFireTracking(WITHERING_FIRE_DURATION)
        else
            ClearWitheringFireTracking()
        end

        if outIconEnabled and iconFrameRef then
            iconFrameRef:Show()
        end

        ShowIcon(KEY_BW, BW_TIMER_BASE)
        onUseWindowTimer = CancelTimer(onUseWindowTimer)
        onUseWindowTimer = C_Timer.NewTimer(BW_TIMER_BASE, function()
            onUseWindowTimer = nil
            _G["BestialWrathActiveTracker"] = false
            HideIcon(KEY_BW)
            if iconFrameRef then iconFrameRef:Hide() end
        end)
    end
end

OnUseTracker_RegisterModule(module)
