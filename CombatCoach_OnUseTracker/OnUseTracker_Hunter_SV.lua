-- OnUseTracker_Hunter_SV.lua
-- Survival Hunter (spec 255) — state, constants, and helper functions.
-- Module definition and event wiring → OnUseTracker_Hunter_SV_Module.lua

local ADDON_NAME = "On Use Tracker"

-- ===========================================================================
-- Survival Hunter (spec 255) — Sentinel's Mark + Tip of the Spear tracking
-- ===========================================================================

SV_SPEC_ID = 255

-- Spell IDs
SV_KILL_COMMAND_ID  = 259489   -- Kill Command (SV)    !! VERIFY
SV_RAPTOR_STRIKE_ID = 186270   -- Raptor Strike
SV_RAPTOR_SWIPE_ID  = 1262293  -- Raptor Swipe
SV_BOOMSTICK_ID     = 1261193  -- Boomstick             !! VERIFY
SV_WILDFIRE_BOMB_ID = 259495   -- Wildfire Bomb
SV_HATCHET_TOSS_ID  = 193265   -- Hatchet Toss
SV_TAKEDOWN_ID      = 1250646  -- Takedown
SV_TOTS_TALENT_ID    = 260285   -- Tip of the Spear (talent node)
SV_PRIMAL_SURGE_TALENT_ID = 1272154  -- Primal Surge: KC grants +1 extra TotS stack
SV_TWIN_FANGS_TALENT_ID   = 1272139  -- Twin Fangs: Takedown sets TotS to max stacks
SV_SENTINEL_MARK_ID    = 1253601  -- Sentinel's Mark        !! VERIFY
SV_SENTINEL_TALENT_ID  = 1253599  -- Sentinel (talent node; gates mark tracking)

SV_SENTINEL_TEXTURE          = 5927647  -- Sentinel Storm texture (viewer child detection)
SV_RAPTOR_SWIPE_OVERRIDE_TEX = 7514183  -- texture[1] of spell 186270 when Raptor Swipe overrides Raptor Strike
SV_VIEWER_NAME      = "BuffIconCooldownViewer"
SV_MARK_DURATION    = 12
SV_TOTS_DURATION    = 10
SV_TOTS_MAX_STACKS  = 3
SV_TAKEDOWN_BUFF_DURATION = 10

SV_ALL_CONSUMERS = {
    [SV_RAPTOR_STRIKE_ID] = true,
    [SV_RAPTOR_SWIPE_ID]  = true,
    [SV_BOOMSTICK_ID]     = true,
    [SV_WILDFIRE_BOMB_ID] = true,
    [SV_HATCHET_TOSS_ID]  = true,
    [SV_TAKEDOWN_ID]      = true,
}

KEY_SV_TOTS         = "Tip of the Spear"
KEY_SV_MARK         = "Sentinel's Mark"
KEY_SV_RAPTOR_SWIPE = "Raptor Swipe Override"
KEY_SV_TAKEDOWN     = "Takedown Buff"

SV_TOTS_ICON_DEFAULTS         = { x =  0, y =  36, point = "CENTER", size = 64, enabled = true, glow_enabled = false }
SV_MARK_ICON_DEFAULTS         = { x =  0, y = -36, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }
SV_RAPTOR_SWIPE_ICON_DEFAULTS = { x = 72, y =   0, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }
SV_TAKEDOWN_ICON_DEFAULTS     = { x =-72, y =   0, point = "CENTER", size = 64, enabled = true, glow_enabled = true  }

-- State
sv_iconsRegistered        = false
sv_lockCallbackRegistered = false
sv_iconTots               = nil
sv_iconMark               = nil
sv_markTimerText          = nil
sv_totsStacks             = 0
sv_markExpiry             = 0
sv_markChild              = nil

sv_totsTimer     = nil
sv_totsTicker    = nil
sv_totsExpiresAt = 0

sv_wildfireBombPending      = false
sv_wildfireBombPendingTimer = nil

sv_iconRaptorSwipe   = nil
sv_raptorSwipeActive = false
sv_raptorSwipeTicker = nil

sv_takedownTimer     = nil
sv_takedownTicker    = nil
sv_takedownExpiresAt = 0

-- Timer helpers
SV_UpdateIconState = nil  -- forward declaration; assigned below

function SV_MarkActive()    return sv_markExpiry > 0 and GetTime() < sv_markExpiry end
function SV_SetMarkActive() sv_markExpiry = GetTime() + SV_MARK_DURATION end
function SV_ClearMark()     sv_markExpiry = 0 end

function SV_ClearTakedownTracking()
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

function SV_StartTakedownTracking()
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

function SV_ClearTotsTracking()
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

function SV_StartTotsTimer()
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

function SV_SetWildfireBombPending()
    sv_wildfireBombPending = true
    if sv_wildfireBombPendingTimer then sv_wildfireBombPendingTimer:Cancel() end
    sv_wildfireBombPendingTimer = C_Timer.NewTimer(0.5, function()
        sv_wildfireBombPending      = false
        sv_wildfireBombPendingTimer = nil
    end)
end

function SV_ConsumeWildfireBombPending()
    sv_wildfireBombPending = false
    if sv_wildfireBombPendingTimer then
        sv_wildfireBombPendingTimer:Cancel()
        sv_wildfireBombPendingTimer = nil
    end
end

-- Ticker frame for Sentinel's Mark countdown text
sv_tickerFrame = CreateFrame("Frame")
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
function SV_FindMarkChild()
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

function SV_HookMarkChild(child)
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

sv_markRetryPending = false
sv_markRetryCount   = 0
SV_MARK_MAX_RETRIES = 10   -- 10 × 3 s = 30 s total per attempt cycle
