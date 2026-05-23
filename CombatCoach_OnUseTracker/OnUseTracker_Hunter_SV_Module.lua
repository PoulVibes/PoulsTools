-- OnUseTracker_Hunter_SV_Module.lua
-- Survival Hunter (spec 255) module definition, icon registration, and events.
-- State, constants, and helpers -> OnUseTracker_Hunter_SV.lua

local ADDON_NAME = "On Use Tracker"
local ICON_SIZE_DEFAULT = 64

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

    if not OnUseTrackerDB[KEY_SV_TOTS] then
        local d = {}
        for k, v in pairs(SV_TOTS_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_TOTS] = d
    end
    local totsDB = OnUseTrackerDB[KEY_SV_TOTS]
    sv_iconTots = shmIcons:Register(ADDON_NAME, KEY_SV_TOTS, totsDB, {
        onResize = function(sq) totsDB.size = sq end,
        onMove = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_TOTS, C_Spell.GetSpellTexture(SV_TOTS_TALENT_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)

    if not OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE] then
        local d = {}
        for k, v in pairs(SV_RAPTOR_SWIPE_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE] = d
    end
    local raptorSwipeDB = OnUseTrackerDB[KEY_SV_RAPTOR_SWIPE]
    sv_iconRaptorSwipe = shmIcons:Register(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, raptorSwipeDB, {
        onResize = function(sq) raptorSwipeDB.size = sq end,
        onMove = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, C_Spell.GetSpellTexture(SV_RAPTOR_SWIPE_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)

    if not OnUseTrackerDB[KEY_SV_TAKEDOWN] then
        local d = {}
        for k, v in pairs(SV_TAKEDOWN_ICON_DEFAULTS) do d[k] = v end
        OnUseTrackerDB[KEY_SV_TAKEDOWN] = d
    end
    local takedownDB = OnUseTrackerDB[KEY_SV_TAKEDOWN]
    shmIcons:Register(ADDON_NAME, KEY_SV_TAKEDOWN, takedownDB, {
        onResize = function(sq) takedownDB.size = sq end,
        onMove = function() end,
    })
    shmIcons:SetIcon(ADDON_NAME, KEY_SV_TAKEDOWN, C_Spell.GetSpellTexture(SV_TAKEDOWN_ID))
    shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)

    if not sv_lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
        sv_lockCallbackRegistered = true
        shmIcons:RegisterLockCallback(function(locked)
            if locked and sv_iconsRegistered then
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_TOTS, false)
                shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TOTS, 0, 0)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_TOTS, false)
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_RAPTOR_SWIPE, false)
                shmIcons:SetVisible(ADDON_NAME, KEY_SV_TAKEDOWN, false)
                shmIcons:SetCooldownRaw(ADDON_NAME, KEY_SV_TAKEDOWN, 0, 0)
                shmIcons:SetGlow(ADDON_NAME, KEY_SV_TAKEDOWN, false)
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
    shmIcons:Unregister(ADDON_NAME, KEY_SV_RAPTOR_SWIPE)
    shmIcons:Unregister(ADDON_NAME, KEY_SV_TAKEDOWN)
    sv_iconTots = nil
    sv_iconRaptorSwipe = nil
    sv_iconsRegistered = false
end

local svModule = {}
svModule.specID = SV_SPEC_ID

function svModule.GetIconTextureSpellID()
    return SV_KILL_COMMAND_ID
end

function svModule.GetTimerDuration()
    return SV_TOTS_DURATION
end

function svModule.Enable(_iconFrame)
    if not sv_iconsRegistered then SV_RegisterIcons() end
    sv_totsStacks = 0
    SV_UpdateIconState()

    if sv_raptorSwipeTicker then sv_raptorSwipeTicker:Cancel() end
    sv_raptorSwipeTicker = C_Timer.NewTicker(0.2, SV_CheckRaptorSwipeOverride)
    SV_CheckRaptorSwipeOverride()
end

function svModule.Disable()
    SV_ClearTotsTracking()
    SV_ClearTakedownTracking()
    if sv_raptorSwipeTicker then sv_raptorSwipeTicker:Cancel() sv_raptorSwipeTicker = nil end
    sv_raptorSwipeActive = false
    SV_UnregisterIcons()

    _G["TipOfTheSpearStacks"] = 0
    _G["TipOfTheSpearTimerActive"] = false
    _G["TipOfTheSpearRemaining"] = 0
    _G["RaptorSwipeOverrideActive"] = false
    _G["TakedownBuffActive"] = false
    _G["TakedownBuffRemaining"] = 0
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
                sv_totsStacks = SV_TOTS_MAX_STACKS - 1
                SV_StartTotsTimer()
            else
                sv_totsStacks = math.max(sv_totsStacks - 1, 0)
            end
            SV_UpdateIconState()
        end
    end

    if spellID == SV_TAKEDOWN_ID then
        SV_StartTakedownTracking()
    end
end

OnUseTracker_RegisterModule(svModule)

SLASH_ONUSETRACKERSV1 = "/st"
SlashCmdList["ONUSETRACKERSV"] = function(msg)
    msg = msg:lower():match("^%s*(.-)%s*$")
    if msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    elseif msg == "reset" then
        if OnUseTrackerDB then
            local totsSize = OnUseTrackerDB[KEY_SV_TOTS] and OnUseTrackerDB[KEY_SV_TOTS].size or ICON_SIZE_DEFAULT
            shmIcons:ResetIcon(ADDON_NAME, KEY_SV_TOTS, totsSize)
            print("OnUseTracker (SV): Tip of the Spear icon reset to center.")
        end
    elseif msg == "status" then
        print(string.format(
            "OnUseTracker (SV): tots=%d raptorSwipe=%s",
            sv_totsStacks,
            tostring(sv_raptorSwipeActive)
        ))
    else
        print("OnUseTracker (SV): /st lock | reset | status")
    end
end