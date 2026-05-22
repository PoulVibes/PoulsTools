-- OnUseTracker_Hunter_SV_Module.lua
-- Survival Hunter (spec 255) — module definition, icon registration, and events.
-- State, constants, and helpers → OnUseTracker_Hunter_SV.lua

local ADDON_NAME       = "On Use Tracker"
local ICON_SIZE_DEFAULT = 64

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
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_TOTS, C_Spell.GetSpellTexture(SV_TOTS_TALENT_ID))
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
