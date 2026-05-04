-- OnUseTracker_Monk.lua
-- Windwalker Monk module for OnUseTracker.
-- Registered with OnUseTracker_RegisterModule() so the main file can delegate to it.

local ADDON_NAME = "On Use Tracker"

local SPEC_ID          = 269  -- Windwalker Monk
local ICON_SIZE_DEFAULT = 64

local KEY_ZENITH = "Zenith Buff"

local SLOT_DEFS = {
    { key = KEY_ZENITH, iconSpellID = 1249625 },
}

local ZENITH_SPELL_IDS = {
    [1249625] = true,  -- Zenith (Main Talent ID)
    [1249763] = true,  -- Zenith (Mastery Trigger ID)
    [1272696] = true,  -- Zenith Stomp
}

local DRINKING_HORN_COVER_TALENT_ID = 391370
local ZENITH_TIMER_BASE             = 15
local ZENITH_TIMER_WITH_DHC         = 20

local iconsRegistered        = false
local lockCallbackRegistered = false
local onUseWindowTimer       = nil
local iconFrameRef           = nil

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
    local defaultPositions = {
        [KEY_ZENITH] = { x = 0, y = 0 },
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
        shmIcons:SetIcon(ADDON_NAME, k, C_Spell.GetSpellTexture(def.iconSpellID))
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

local function GetTimerDuration()
    if IsPlayerSpell(DRINKING_HORN_COVER_TALENT_ID) then
        return ZENITH_TIMER_WITH_DHC
    end
    return ZENITH_TIMER_BASE
end

-- ---- Module interface ----

local module = {}
module.specID = SPEC_ID

function module.GetIconTextureSpellID()
    return 1249625
end

function module.GetTimerDuration()
    return GetTimerDuration()
end

function module.Enable(iconFrame)
    iconFrameRef = iconFrame
    if not iconsRegistered then RegisterIcons() end
end

function module.Disable()
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    _G["ZenithActiveTracker"] = false
    HideIcon(KEY_ZENITH)
    UnregisterIcons()
    if iconFrameRef then iconFrameRef:Hide() end
end

function module.OnSpellCast(spellID, outIconEnabled)
    if not ZENITH_SPELL_IDS[spellID] then return end
    if _G["ZenithActiveTracker"] then return end

    _G["ZenithActiveTracker"] = true
    if outIconEnabled and iconFrameRef then
        iconFrameRef:Show()
    end

    local duration = GetTimerDuration()
    ShowIcon(KEY_ZENITH, duration)
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    onUseWindowTimer = C_Timer.NewTimer(duration, function()
        onUseWindowTimer = nil
        _G["ZenithActiveTracker"] = false
        HideIcon(KEY_ZENITH)
        if iconFrameRef then iconFrameRef:Hide() end
    end)
end

OnUseTracker_RegisterModule(module)
