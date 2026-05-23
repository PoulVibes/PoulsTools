-- OnUseTracker_Hunter_SV.lua
-- Survival Hunter (spec 255) state, constants, and helper functions.
-- Module definition and event wiring -> OnUseTracker_Hunter_SV_Module.lua

local ADDON_NAME = "On Use Tracker"

-- ===========================================================================
-- Survival Hunter (spec 255) - Tip of the Spear and utility proc tracking
-- ===========================================================================

SV_SPEC_ID = 255

-- Spell IDs
SV_KILL_COMMAND_ID  = 259489   -- Kill Command (SV)
SV_RAPTOR_STRIKE_ID = 186270   -- Raptor Strike
SV_RAPTOR_SWIPE_ID  = 1262293  -- Raptor Swipe
SV_BOOMSTICK_ID     = 1261193  -- Boomstick
SV_WILDFIRE_BOMB_ID = 259495   -- Wildfire Bomb
SV_HATCHET_TOSS_ID  = 193265   -- Hatchet Toss
SV_TAKEDOWN_ID      = 1250646  -- Takedown

SV_TOTS_TALENT_ID          = 260285   -- Tip of the Spear (talent node)
SV_PRIMAL_SURGE_TALENT_ID  = 1272154  -- KC grants +1 extra TotS stack
SV_TWIN_FANGS_TALENT_ID    = 1272139  -- Takedown sets TotS to max stacks

SV_RAPTOR_SWIPE_OVERRIDE_TEX = 7514183
SV_TOTS_DURATION             = 10
SV_TOTS_MAX_STACKS           = 3
SV_TAKEDOWN_BUFF_DURATION    = 10

SV_ALL_CONSUMERS = {
    [SV_RAPTOR_STRIKE_ID] = true,
    [SV_RAPTOR_SWIPE_ID]  = true,
    [SV_BOOMSTICK_ID]     = true,
    [SV_WILDFIRE_BOMB_ID] = true,
    [SV_HATCHET_TOSS_ID]  = true,
    [SV_TAKEDOWN_ID]      = true,
}

KEY_SV_TOTS         = "Tip of the Spear"
KEY_SV_RAPTOR_SWIPE = "Raptor Swipe Override"
KEY_SV_TAKEDOWN     = "Takedown Buff"

SV_TOTS_ICON_DEFAULTS         = { x = 0, y = 36, point = "CENTER", size = 64, enabled = true, glow_enabled = false }
SV_RAPTOR_SWIPE_ICON_DEFAULTS = { x = 72, y = 0, point = "CENTER", size = 64, enabled = true, glow_enabled = true }
SV_TAKEDOWN_ICON_DEFAULTS     = { x = -72, y = 0, point = "CENTER", size = 64, enabled = true, glow_enabled = true }

-- State
sv_iconsRegistered        = false
sv_lockCallbackRegistered = false
sv_iconTots               = nil
sv_totsStacks             = 0

sv_totsTimer     = nil
sv_totsTicker    = nil
sv_totsExpiresAt = 0

sv_iconRaptorSwipe   = nil
sv_raptorSwipeActive = false
sv_raptorSwipeTicker = nil

sv_takedownTimer     = nil
sv_takedownTicker    = nil
sv_takedownExpiresAt = 0

-- Timer helpers
SV_UpdateIconState = nil  -- forward declaration; assigned below

function SV_ClearTakedownTracking()
    if sv_takedownTimer then sv_takedownTimer:Cancel() end
    if sv_takedownTicker then sv_takedownTicker:Cancel() end
    sv_takedownTimer = nil
    sv_takedownTicker = nil
    sv_takedownExpiresAt = 0
    _G["TakedownBuffActive"] = false
    _G["TakedownBuffRemaining"] = 0
    if sv_iconsRegistered then
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TAKEDOWN, 0, 0)
        shmIcons:SetGlow(ADDON_NAME, KEY_SV_TAKEDOWN, false)
    end
end

function SV_StartTakedownTracking()
    SV_ClearTakedownTracking()
    sv_takedownExpiresAt = GetTime() + SV_TAKEDOWN_BUFF_DURATION
    _G["TakedownBuffActive"] = true
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

function SV_ClearTotsTracking()
    if sv_totsTimer then sv_totsTimer:Cancel() end
    if sv_totsTicker then sv_totsTicker:Cancel() end
    sv_totsTimer = nil
    sv_totsTicker = nil
    sv_totsExpiresAt = 0
    sv_totsStacks = 0
    _G["TipOfTheSpearTimerActive"] = false
    _G["TipOfTheSpearRemaining"] = 0
    _G["TipOfTheSpearStacks"] = 0
    if sv_iconsRegistered then
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
        shmIcons:SetStacks(ADDON_NAME, KEY_SV_TOTS, 0)
    end
end

function SV_StartTotsTimer()
    if sv_totsTimer then sv_totsTimer:Cancel() end
    if sv_totsTicker then sv_totsTicker:Cancel() end
    sv_totsTimer = nil
    sv_totsTicker = nil
    sv_totsExpiresAt = GetTime() + SV_TOTS_DURATION
    if sv_iconsRegistered then
        shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, GetTime(), SV_TOTS_DURATION)
    end
    sv_totsTicker = C_Timer.NewTicker(0.1, function()
        local remains = sv_totsExpiresAt - GetTime()
        _G["TipOfTheSpearTimerActive"] = remains > 0
        _G["TipOfTheSpearRemaining"] = math.max(0, remains)
    end)
    sv_totsTimer = C_Timer.NewTimer(SV_TOTS_DURATION, function()
        sv_totsTimer = nil
        SV_ClearTotsTracking()
        SV_UpdateIconState()
    end)
end

SV_UpdateIconState = function()
    if sv_iconTots then
        shmIcons:SetStacks(ADDON_NAME, KEY_SV_TOTS, sv_totsStacks)
        shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, sv_totsStacks > 0)
        if sv_totsStacks == 0 then
            shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
        end
    end
    _G["TipOfTheSpearStacks"] = sv_totsStacks
    _G["TipOfTheSpearTimerActive"] = sv_totsExpiresAt > 0 and GetTime() < sv_totsExpiresAt
    _G["TipOfTheSpearRemaining"] = (_G["TipOfTheSpearTimerActive"] and math.max(0, sv_totsExpiresAt - GetTime())) or 0
end