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

-- ===========================================================================
-- Survival Hunter (spec 255) — Sentinel's Mark + Tip of the Spear tracking
-- ===========================================================================

local SV_SPEC_ID = 255

-- Spell IDs
local SV_KILL_COMMAND_ID  = 259489   -- Kill Command (SV)    !! VERIFY
local SV_RAPTOR_STRIKE_ID = 186270   -- Raptor Strike
local SV_RAPTOR_SWIPE_ID  = 1262293  -- Raptor Swipe
local SV_BOOMSTICK_ID     = 1261193  -- Boomstick             !! VERIFY
local SV_WILDFIRE_BOMB_ID = 259495   -- Wildfire Bomb
local SV_HATCHET_TOSS_ID  = 193265   -- Hatchet Toss
local SV_TAKEDOWN_ID      = 1250646  -- Takedown
local SV_TOTS_TALENT_ID    = 260286   -- Tip of the Spear (talent node)
local SV_PRIMAL_SURGE_TALENT_ID = 141452  -- Primal Surge: KC grants +1 extra TotS stack
local SV_TWIN_FANGS_TALENT_ID   = 140445  -- Twin Fangs: Takedown sets TotS to max stacks
local SV_SENTINEL_MARK_ID    = 1253601  -- Sentinel's Mark        !! VERIFY
local SV_SENTINEL_TALENT_ID  = 1253599  -- Sentinel (talent node; gates mark tracking)

local SV_SENTINEL_TEXTURE          = 5927647  -- Sentinel Storm texture (viewer child detection)
local SV_RAPTOR_SWIPE_OVERRIDE_TEX = 7514183  -- texture[1] of spell 186270 when Raptor Swipe overrides Raptor Strike
local SV_VIEWER_NAME      = "BuffIconCooldownViewer"
local SV_MARK_DURATION    = 12
local SV_TOTS_DURATION    = 10
local SV_TOTS_MAX_STACKS  = 3
local SV_TAKEDOWN_BUFF_DURATION = 10

local SV_ALL_CONSUMERS = {
    [SV_RAPTOR_STRIKE_ID] = true,
    [SV_RAPTOR_SWIPE_ID]  = true,
    [SV_BOOMSTICK_ID]     = true,
    [SV_WILDFIRE_BOMB_ID] = true,
    [SV_HATCHET_TOSS_ID]  = true,
    [SV_TAKEDOWN_ID]      = true,
}

local KEY_SV_TOTS         = "Tip of the Spear"
local KEY_SV_MARK         = "Sentinel's Mark"
local KEY_SV_RAPTOR_SWIPE = "Raptor Swipe Override"
local KEY_SV_TAKEDOWN     = "Takedown Buff"

local SV_TOTS_ICON_DEFAULTS         = { x =  0, y =  36, point = "CENTER", size = 64, enabled = true, glow_enabled = false }
local SV_MARK_ICON_DEFAULTS         = { x =  0, y = -36, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }
local SV_RAPTOR_SWIPE_ICON_DEFAULTS = { x = 72, y =   0, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }
local SV_TAKEDOWN_ICON_DEFAULTS     = { x =-72, y =   0, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }

-- State
local sv_iconsRegistered        = false
local sv_lockCallbackRegistered = false
local sv_iconTots               = nil
local sv_iconMark               = nil
local sv_markTimerText          = nil
local sv_totsStacks             = 0
local sv_markExpiry             = 0
local sv_markChild              = nil

local sv_totsTimer     = nil
local sv_totsTicker    = nil
local sv_totsExpiresAt = 0

local sv_wildfireBombPending      = false
local sv_wildfireBombPendingTimer = nil

local sv_iconRaptorSwipe   = nil
local sv_raptorSwipeActive = false
local sv_raptorSwipeTicker = nil

local sv_takedownTimer     = nil
local sv_takedownTicker    = nil
local sv_takedownExpiresAt = 0

-- Timer helpers
local SV_UpdateIconState  -- forward declaration (defined below)
local function SV_MarkActive()    return sv_markExpiry > 0 and GetTime() < sv_markExpiry end
local function SV_SetMarkActive() sv_markExpiry = GetTime() + SV_MARK_DURATION end
local function SV_ClearMark()     sv_markExpiry = 0 end

local function SV_ClearTakedownTracking()
    if sv_takedownTimer  then sv_takedownTimer:Cancel()  end
    if sv_takedownTicker then sv_takedownTicker:Cancel() end
    sv_takedownTimer     = nil
    sv_takedownTicker    = nil
    sv_takedownExpiresAt = 0
    _G["TakedownBuffActive"]    = false
    _G["TakedownBuffRemaining"] = 0
    if sv_iconsRegistered then
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TAKEDOWN, 0, 0)
        shmIcons:SetGlow(ADDON_NAME, KEY_SV_TAKEDOWN, false)
    end
end

local function SV_StartTakedownTracking()
    SV_ClearTakedownTracking()
    sv_takedownExpiresAt = GetTime() + SV_TAKEDOWN_BUFF_DURATION
    _G["TakedownBuffActive"]    = true
    _G["TakedownBuffRemaining"] = SV_TAKEDOWN_BUFF_DURATION
    if sv_iconsRegistered then
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, true)
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TAKEDOWN, GetTime(), SV_TAKEDOWN_BUFF_DURATION)
        shmIcons:SetGlow(ADDON_NAME, KEY_SV_TAKEDOWN, true)
    end
    sv_takedownTicker = C_Timer.NewTicker(0.1, function()
        local remains = sv_takedownExpiresAt - GetTime()
        if remains > 0 then
            _G["TakedownBuffRemaining"] = remains
        else
            SV_ClearTakedownTracking()
        end
    end)
    sv_takedownTimer = C_Timer.NewTimer(SV_TAKEDOWN_BUFF_DURATION, function()
        SV_ClearTakedownTracking()
    end)
end

local function SV_ClearTotsTracking()
    if sv_totsTimer  then sv_totsTimer:Cancel()  end
    if sv_totsTicker then sv_totsTicker:Cancel() end
    sv_totsTimer     = nil
    sv_totsTicker    = nil
    sv_totsExpiresAt = 0
    sv_totsStacks    = 0
    _G["TipOfTheSpearTimerActive"] = false
    _G["TipOfTheSpearRemaining"]   = 0
    _G["TipOfTheSpearStacks"]      = 0
    if sv_iconsRegistered then
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
        shmIcons:SetStacks(ADDON_NAME, KEY_SV_TOTS, 0)
    end
end

local function SV_StartTotsTimer()
    if sv_totsTimer  then sv_totsTimer:Cancel()  end
    if sv_totsTicker then sv_totsTicker:Cancel() end
    sv_totsTimer     = nil
    sv_totsTicker    = nil
    sv_totsExpiresAt = GetTime() + SV_TOTS_DURATION
    if sv_iconsRegistered then
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, GetTime(), SV_TOTS_DURATION)
    end
    sv_totsTicker = C_Timer.NewTicker(0.1, function()
        local remains = sv_totsExpiresAt - GetTime()
        _G["TipOfTheSpearTimerActive"] = remains > 0
        _G["TipOfTheSpearRemaining"]   = math.max(0, remains)
    end)
    sv_totsTimer = C_Timer.NewTimer(SV_TOTS_DURATION, function()
        sv_totsTimer = nil
        SV_ClearTotsTracking()
        SV_UpdateIconState()
    end)
end

local function SV_SetWildfireBombPending()
    sv_wildfireBombPending = true
    if sv_wildfireBombPendingTimer then sv_wildfireBombPendingTimer:Cancel() end
    sv_wildfireBombPendingTimer = C_Timer.NewTimer(0.5, function()
        sv_wildfireBombPending      = false
        sv_wildfireBombPendingTimer = nil
    end)
end

local function SV_ConsumeWildfireBombPending()
    sv_wildfireBombPending = false
    if sv_wildfireBombPendingTimer then
        sv_wildfireBombPendingTimer:Cancel()
        sv_wildfireBombPendingTimer = nil
    end
end

-- Ticker frame for Sentinel's Mark countdown text
local sv_tickerFrame = CreateFrame("Frame")
sv_tickerFrame:Hide()
sv_tickerFrame:SetScript("OnUpdate", function()
    if not sv_markTimerText then sv_tickerFrame:Hide() return end
    local remaining = sv_markExpiry > 0 and (sv_markExpiry - GetTime()) or 0
    if remaining > 0 then
        sv_markTimerText:SetText(string.format("%d", math.ceil(remaining)))
    else
        sv_markTimerText:SetText("")
        sv_tickerFrame:Hide()
    end
end)

SV_UpdateIconState = function()
    if sv_iconTots then
        shmIcons:SetStacks(ADDON_NAME, KEY_SV_TOTS, sv_totsStacks)
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, sv_totsStacks > 0)
        if sv_totsStacks == 0 then
            shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
        end
    end
    local active = SV_MarkActive()
    if sv_iconMark then
        shmIcons:SetGlow(ADDON_NAME, KEY_SV_MARK, active)
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_MARK, active)
    end
    if active then
        sv_tickerFrame:Show()
    else
        if sv_markTimerText then sv_markTimerText:SetText("") end
        sv_tickerFrame:Hide()
    end
    _G["SentinelMarkActiveTracker"] = active
    _G["SentinelMarkRemaining"]     = active and math.max(0, sv_markExpiry - GetTime()) or 0
    _G["TipOfTheSpearStacks"]       = sv_totsStacks
    _G["TipOfTheSpearTimerActive"]  = sv_totsExpiresAt > 0 and GetTime() < sv_totsExpiresAt
    _G["TipOfTheSpearRemaining"]    = (_G["TipOfTheSpearTimerActive"] and math.max(0, sv_totsExpiresAt - GetTime())) or 0
end

-- Viewer child detection: scan BuffIconCooldownViewer for the child whose
-- icon texture matches the Sentinel Storm texture.
local function SV_FindMarkChild()
    -- If CooldownTracker is not loaded the viewer frame may still exist as a
    -- stale global, but its children will have secret/tainted texture IDs that
    -- cannot be compared without a Lua error.  Guard on the addon being loaded.
    if not BuffIconCooldownViewer:IsShown() then return nil end
    local viewer = _G[SV_VIEWER_NAME]
    if not viewer then return nil end
    local n = viewer:GetNumChildren()
    for i = 1, n do
        local child = select(i, viewer:GetChildren())
        for j = 1, select("#", child:GetRegions()) do
            local r = select(j, child:GetRegions())
            if r:GetObjectType() == "Texture" then
                local ok, tid = pcall(r.GetTexture, r)
                if ok and tid == SV_SENTINEL_TEXTURE then return child end
            end
        end
        for j = 1, child:GetNumChildren() do
            local gc = select(j, child:GetChildren())
            for k = 1, select("#", gc:GetRegions()) do
                local r = select(k, gc:GetRegions())
                if r:GetObjectType() == "Texture" then
                    local ok, tid = pcall(r.GetTextureID, r)
                    if ok and tid == SV_SENTINEL_TEXTURE then return child end
                end
            end
        end
    end
    return nil
end

local function SV_HookMarkChild(child)
    sv_markChild = child
    _G["SentinelMarkTrackerReady"] = true
    -- Notify the SBAS Override GUI so it can clear any tracker-missing warnings.
    if type(_G.SBAS_OnSentinelMarkTrackerReady) == "function" then
        _G.SBAS_OnSentinelMarkTrackerReady()
    end
    local hideTimer = nil
    child:HookScript("OnShow", function()
        -- Cancel any pending hide debounce (buff refresh: hide + immediate show)
        if hideTimer then hideTimer:Cancel() hideTimer = nil end
        -- Only reset the timer on a fresh application or a Wildfire Bomb refresh.
        -- Other consumers (Raptor Strike, etc.) trigger hide+show but must NOT reset.
        local freshApply = not SV_MarkActive()
        local wfbRefresh = sv_wildfireBombPending
        if wfbRefresh then SV_ConsumeWildfireBombPending() end
        if freshApply or wfbRefresh then SV_SetMarkActive() end
        SV_UpdateIconState()
    end)
    child:HookScript("OnHide", function()
        -- Defer clear so a same-frame OnShow (refresh) can cancel it
        hideTimer = C_Timer.NewTimer(0.05, function()
            hideTimer = nil
            SV_ClearMark()
            SV_UpdateIconState()
        end)
    end)
    if child:IsShown() then
        SV_SetMarkActive()
        SV_UpdateIconState()
    end
end

local sv_markRetryPending = false
local sv_markRetryCount   = 0
local SV_MARK_MAX_RETRIES = 10   -- 10 × 3 s = 30 s total per attempt cycle

local function SV_InitMarkTracking()
    if sv_markChild then return end   -- already hooked
    -- Skip entirely if the talent is not learned; wait for TRAIT_CONFIG_UPDATED.
    if not IsPlayerSpell(SV_SENTINEL_TALENT_ID) then
        sv_markRetryPending = false
        sv_markRetryCount   = 0
        return
    end
    local child = SV_FindMarkChild()
    if child then
        sv_markRetryPending = false
        sv_markRetryCount   = 0
        SV_HookMarkChild(child)
    elseif not sv_markRetryPending then
        if sv_markRetryCount >= SV_MARK_MAX_RETRIES then
            -- Give up for this attempt cycle and emit a warning once.
            sv_markRetryCount = 0
            print("OnUseTracker (SV): Sentinel's Mark texture not found in " .. SV_VIEWER_NAME
                .. " — ensure it is added to the Tracked Buffs bar")
            return
        end
        sv_markRetryCount   = sv_markRetryCount + 1
        sv_markRetryPending = true
        C_Timer.After(3, function()
            sv_markRetryPending = false
            SV_InitMarkTracking()
        end)
    end
end

-- Polls C_Spell.GetSpellTexture(SV_RAPTOR_STRIKE_ID) to detect the Raptor Swipe override.
-- When texture[1] == SV_RAPTOR_SWIPE_OVERRIDE_TEX the spell button is showing Raptor Swipe.
local function SV_CheckRaptorSwipeOverride()
    local tex1 = C_Spell.GetSpellTexture(SV_RAPTOR_STRIKE_ID)
    local isOverride = (tex1 == SV_RAPTOR_SWIPE_OVERRIDE_TEX)
    if isOverride ~= sv_raptorSwipeActive then
        sv_raptorSwipeActive = isOverride
        _G["RaptorSwipeOverrideActive"] = isOverride
        if sv_iconsRegistered then
            shmIcons:SetVisible(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, isOverride)
            shmIcons:SetGlow(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, isOverride)
        end
    end
end

local function SV_RegisterIcons()
    if sv_iconsRegistered then return end
    OnUseTrackerDB = OnUseTrackerDB or {}
    -- Tip of the Spear icon
    if not OnUseTrackerDB[KEY_SV_TOTS] then
        local d = {}
        for k, v in pairs(SV_TOTS_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_TOTS] = d
    end
    local totsDB = OnUseTrackerDB[KEY_SV_TOTS]
    sv_iconTots = shmIcons:Register(ADDON_NAME, KEY_SV_TOTS, totsDB, {
        onResize = function(sq) totsDB.size = sq end,
        onMove   = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_TOTS, C_Spell.GetSpellTexture(SV_TOTS_SPELL_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)
    -- Sentinel's Mark icon
    if not OnUseTrackerDB[KEY_SV_MARK] then
        local d = {}
        for k, v in pairs(SV_MARK_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_MARK] = d
    end
    local markDB = OnUseTrackerDB[KEY_SV_MARK]
    sv_iconMark = shmIcons:Register(ADDON_NAME, KEY_SV_MARK, markDB, {
        onResize = function(sq)
            markDB.size = sq
            if sv_markTimerText then
                sv_markTimerText:SetFont(
                    "Fonts\\FRIZQT__.TTF",
                    math.max(8, math.floor(sq * 0.45)),
                    "OUTLINE")
            end
        end,
        onMove = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_MARK,
        C_Spell.GetSpellTexture(SV_SENTINEL_MARK_ID) or SV_SENTINEL_TEXTURE)
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_MARK, false)
    -- Countdown font string on mark icon frame
    if sv_iconMark and sv_iconMark.frame then
        sv_markTimerText = sv_iconMark.frame:CreateFontString(nil, "OVERLAY")
        sv_markTimerText:SetFont(
            "Fonts\\FRIZQT__.TTF",
            math.max(8, math.floor(markDB.size * 0.45)),
            "OUTLINE")
        sv_markTimerText:SetPoint("CENTER", sv_iconMark.frame, "CENTER", 0, 0)
        sv_markTimerText:SetTextColor(1, 1, 1, 1)
        sv_markTimerText:SetText("")
    end
    -- Raptor Swipe Override icon
    if not OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE] then
        local d = {}
        for k, v in pairs(SV_RAPTOR_SWIPE_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE] = d
    end
    local raptorSwipeDB = OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE]
    sv_iconRaptorSwipe = shmIcons:Register(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, raptorSwipeDB, {
        onResize = function(sq) raptorSwipeDB.size = sq end,
        onMove   = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, C_Spell.GetSpellTexture(SV_RAPTOR_SWIPE_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)
    -- Takedown Buff icon
    if not OnUseTrackerDB[KEY_SV_TAKEDOWN] then
        local d = {}
        for k, v in pairs(SV_TAKEDOWN_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_TAKEDOWN] = d
    end
    local takedownDB = OnUseTrackerDB[KEY_SV_TAKEDOWN]
    shmIcons:Register(ADDON_NAME, KEY_SV_TAKEDOWN, takedownDB, {
        onResize = function(sq) takedownDB.size = sq end,
        onMove   = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_TAKEDOWN, C_Spell.GetSpellTexture(SV_TAKEDOWN_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)
    -- Lock callback (SV-specific; BM already has its own separate callback)
    if not sv_lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
        sv_lockCallbackRegistered = true
        shmIcons:RegisterLockCallback(function(locked)
            if locked and sv_iconsRegistered then
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)
                shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_TOTS, false)
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_MARK, false)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_MARK, false)
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)
                shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TAKEDOWN, 0, 0)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_TAKEDOWN, false)
                if sv_markTimerText then sv_markTimerText:SetText("") end
                sv_tickerFrame:Hide()
            elseif not locked and sv_iconsRegistered then
                SV_UpdateIconState()
                SV_CheckRaptorSwipeOverride()
            end
        end)
    end
    sv_iconsRegistered = true
end

local function SV_UnregisterIcons()
    if not sv_iconsRegistered then return end
    shmIcons:Unregister(ADDON_NAME, KEY_SV_TOTS)
    shmIcons:Unregister(ADDON_NAME, KEY_SV_MARK)
    shmIcons:Unregister(ADDON_NAME, KEY_SV_RAPTOR_SWIPE)
    shmIcons:Unregister(ADDON_NAME, KEY_SV_TAKEDOWN)
    sv_iconTots        = nil
    sv_iconMark        = nil
    sv_iconRaptorSwipe = nil
    sv_markTimerText   = nil
    sv_tickerFrame:Hide()
    _G["SentinelMarkTrackerReady"] = false
    sv_iconsRegistered = false
end

-- ---- Module interface ----

local svModule = {}
svModule.specID = SV_SPEC_ID

function svModule.GetIconTextureSpellID()
    return SV_KILL_COMMAND_ID
end

function svModule.GetTimerDuration()
    return SV_MARK_DURATION
end

function svModule.Enable(_iconFrame)
    if not sv_iconsRegistered then SV_RegisterIcons() end
    sv_totsStacks = 0
    sv_markChild  = nil
    SV_ClearMark()
    SV_UpdateIconState()
    SV_InitMarkTracking()
    -- Poll Raptor Strike's texture every 0.2s to detect the Raptor Swipe override.
    if sv_raptorSwipeTicker then sv_raptorSwipeTicker:Cancel() end
    sv_raptorSwipeTicker = C_Timer.NewTicker(0.2, SV_CheckRaptorSwipeOverride)
    SV_CheckRaptorSwipeOverride()
    -- SV_InitMarkTracking may run before PLAYER_ENTERING_WORLD (e.g. on
    -- PLAYER_LOGIN) when BuffIconCooldownViewer children aren't set up yet.
    -- The sv_worldFrame below retries once the world is fully loaded, exactly
    -- mirroring what the original SentinelTracker did with its own event frame.
end

function svModule.Disable()
    SV_ClearTotsTracking()
    SV_ClearTakedownTracking()
    sv_markChild  = nil
    SV_ClearMark()
    if sv_raptorSwipeTicker then sv_raptorSwipeTicker:Cancel() sv_raptorSwipeTicker = nil end
    sv_raptorSwipeActive = false
    SV_UnregisterIcons()
    _G["SentinelMarkActiveTracker"] = false
    _G["SentinelMarkRemaining"]     = 0
    _G["TipOfTheSpearStacks"]       = 0
    _G["TipOfTheSpearTimerActive"]  = false
    _G["TipOfTheSpearRemaining"]    = 0
    _G["RaptorSwipeOverrideActive"] = false
    _G["TakedownBuffActive"]        = false
    _G["TakedownBuffRemaining"]     = 0
end

function svModule.OnSpellCast(spellID, _outIconEnabled)
    local totsActive = IsPlayerSpell(SV_TOTS_TALENT_ID)
    if spellID == SV_KILL_COMMAND_ID then
        if totsActive then
            local kcGrant = IsPlayerSpell(SV_PRIMAL_SURGE_TALENT_ID) and 2 or 1
            sv_totsStacks = math.min(sv_totsStacks + kcGrant, SV_TOTS_MAX_STACKS)
            SV_StartTotsTimer()
            SV_UpdateIconState()
        end
    elseif SV_ALL_CONSUMERS[spellID] then
        if totsActive then
            if spellID == SV_TAKEDOWN_ID and IsPlayerSpell(SV_TWIN_FANGS_TALENT_ID) then
                -- Twin Fangs grants 3 stacks before the cast, then Takedown consumes 1 as a
                -- normal consumer — net result is max - 1 = 2 stacks.
                sv_totsStacks = SV_TOTS_MAX_STACKS - 1
                SV_StartTotsTimer()
            else
                sv_totsStacks = math.max(sv_totsStacks - 1, 0)
            end
            SV_UpdateIconState()
        end
        if spellID == SV_WILDFIRE_BOMB_ID then
            SV_SetWildfireBombPending()
        end
    end
    if spellID == SV_TAKEDOWN_ID then
        SV_StartTakedownTracking()
    end
end

OnUseTracker_RegisterModule(svModule)

-- Mirror the original SentinelTracker: re-run child detection on every
-- PLAYER_ENTERING_WORLD so the hook is attached even if Enable() ran
-- before BuffIconCooldownViewer children were populated (e.g. PLAYER_LOGIN).
local sv_worldFrame = CreateFrame("Frame")
sv_worldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
sv_worldFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
sv_worldFrame:SetScript("OnEvent", function(_, event)
    if sv_iconsRegistered and not sv_markChild then
        sv_markRetryPending = false   -- cancel any in-flight retry timer
        sv_markRetryCount   = 0
        if event == "TRAIT_CONFIG_UPDATED" then
            -- Defer slightly so CooldownTracker can process the talent change
            -- and populate BuffIconCooldownViewer before we scan it.
            C_Timer.After(0.5, function()
                if sv_iconsRegistered and not sv_markChild then
                    SV_InitMarkTracking()
                end
            end)
        else
            SV_InitMarkTracking()
        end
    end
end)

-- Slash commands for SV debug / management
SLASH_SENTINELTRACKER1 = "/st"
SlashCmdList["SENTINELTRACKER"] = function(msg)
    msg = msg:lower():match("^%s*(.-)%s*$")
    if msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    elseif msg == "reset" then
        if OnUseTrackerDB then
            local totsSize = OnUseTrackerDB[KEY_SV_TOTS] and OnUseTrackerDB[KEY_SV_TOTS].size or ICON_SIZE_DEFAULT
            local markSize = OnUseTrackerDB[KEY_SV_MARK] and OnUseTrackerDB[KEY_SV_MARK].size or ICON_SIZE_DEFAULT
            shmIcons:ResetIcon(ADDON_NAME, KEY_SV_TOTS, totsSize)
            shmIcons:ResetIcon(ADDON_NAME, KEY_SV_MARK, markSize)
            print("OnUseTracker (SV): Icons reset to center.")
        end
    elseif msg == "reinit" then
        sv_markChild        = nil
        sv_markRetryPending = false
        sv_markRetryCount   = 0
        SV_ClearMark()
        SV_InitMarkTracking()
        print("OnUseTracker (SV): Mark child detection re-run.")
    elseif msg == "status" then
        print(string.format(
            "OnUseTracker (SV): mark=%s(%.1fs) tots=%d markChild=%s",
            tostring(SV_MarkActive()),
            math.max(0, sv_markExpiry - GetTime()),
            sv_totsStacks,
            tostring(sv_markChild ~= nil)))
    else
        print("OnUseTracker (SV): /st lock | reset | reinit | status")
    end
end
