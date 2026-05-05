-- OnUseTracker_Monk.lua
-- Windwalker Monk module for OnUseTracker.
-- Registered with OnUseTracker_RegisterModule() so the main file can delegate to it.

local ADDON_NAME = "On Use Tracker"

local SPEC_ID           = 269  -- Windwalker Monk
local ICON_SIZE_DEFAULT = 64

local KEY_ZENITH = "Zenith Buff"
local KEY_VIVIFY = "Vivacious Vivification"

-- WW gets both icons; BM/MW get only the Vivify icon.
local WW_SLOT_DEFS = {
    { key = KEY_ZENITH, iconSpellID = 1249625 },
    { key = KEY_VIVIFY, iconSpellID = 116670  },
}

local MONK_VIVIFY_SLOT_DEFS = {
    { key = KEY_VIVIFY, iconSpellID = 116670 },
}

local ZENITH_SPELL_IDS = {
    [1249625] = true,  -- Zenith (Main Talent ID)
    [1249763] = true,  -- Zenith (Mastery Trigger ID)
    [1272696] = true,  -- Zenith Stomp
}

local DRINKING_HORN_COVER_TALENT_ID  = 391370
local ZENITH_TIMER_BASE              = 15
local ZENITH_TIMER_WITH_DHC          = 20

local VIVIFY_SPELL_ID                = 116670
local RSK_SPELL_ID                   = 107428
local RWK_SPELL_ID                   = 467307
local VIVACIOUS_VIVIFICATION_WW      = 388812  -- Windwalker / Brewmaster
local VIVACIOUS_VIVIFICATION_MW      = 137024  -- Mistweaver
local VIVIFY_PROC_DURATION           = 20

local iconsRegistered        = false
local lockCallbackRegistered = false
local currentSlotDefs        = nil  -- slot set currently registered, for lock callback
local onUseWindowTimer       = nil
local iconFrameRef           = nil

local vivifyProcActive = false
local vivifyProcTimer  = nil

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

-- Vivify proc icon: no glow (matches original VivifyProcTracker behaviour).
local function ShowVivifyProcIcon(duration)
    if not iconsRegistered then return end
    shmIcons:SetVisible(ADDON_NAME, KEY_VIVIFY, true)
    shmIcons:SetCooldownRaw(ADDON_NAME, KEY_VIVIFY, GetTime(), duration)
    shmIcons:SetGlow(ADDON_NAME, KEY_VIVIFY, false)
end

local function HideIcon(key)
    if not iconsRegistered then return end
    shmIcons:SetVisible(ADDON_NAME, key, false)
    shmIcons:SetCooldownRaw(ADDON_NAME, key, 0, 0)
    shmIcons:SetGlow(ADDON_NAME, key, false)
end

local function RegisterIcons(slotDefs)
    if iconsRegistered then return end
    OnUseTrackerDB = OnUseTrackerDB or {}
    currentSlotDefs = slotDefs
    local defaultPositions = {
        [KEY_ZENITH] = { x =  0,   y =  0    },
        [KEY_VIVIFY] = { x =  0,   y = -100  },
    }
    for _, def in ipairs(slotDefs) do
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
            if locked and iconsRegistered and currentSlotDefs then
                for _, def in ipairs(currentSlotDefs) do
                    shmIcons:SetVisible(ADDON_NAME, def.key, false)
                    shmIcons:SetCooldownRaw(ADDON_NAME, def.key, 0, 0)
                    shmIcons:SetGlow(ADDON_NAME, def.key, false)
                end
            end
        end)
    end
    iconsRegistered = true
end

local function UnregisterIcons(slotDefs)
    if not iconsRegistered then return end
    for _, def in ipairs(slotDefs) do
        shmIcons:Unregister(ADDON_NAME, def.key)
    end
    currentSlotDefs = nil
    iconsRegistered = false
end

local function GetTimerDuration()
    if IsPlayerSpell(DRINKING_HORN_COVER_TALENT_ID) then
        return ZENITH_TIMER_WITH_DHC
    end
    return ZENITH_TIMER_BASE
end

-- ---- Vivify proc helpers ----

local function FireVivifyEvent(event)
    if _G.VivifyProc_OnEvent then
        _G.VivifyProc_OnEvent(event)
    end
end

local function ClearVivifyProc()
    vivifyProcActive = false
    if vivifyProcTimer then vivifyProcTimer:Cancel() end
    vivifyProcTimer = nil
    HideIcon(KEY_VIVIFY)
end

local function HandleVivifyProcSpell(spellID)
    -- RSK or RWK with talent → start proc window
    if (spellID == RSK_SPELL_ID or spellID == RWK_SPELL_ID)
        and (IsPlayerSpell(VIVACIOUS_VIVIFICATION_WW) or IsPlayerSpell(VIVACIOUS_VIVIFICATION_MW)) then
        vivifyProcActive = true
        ShowVivifyProcIcon(VIVIFY_PROC_DURATION)
        if vivifyProcTimer then vivifyProcTimer:Cancel() end
        vivifyProcTimer = C_Timer.NewTimer(VIVIFY_PROC_DURATION, function()
            ClearVivifyProc()
        end)
    -- Vivify cast → consume proc or fire normal event
    elseif spellID == VIVIFY_SPELL_ID then
        if vivifyProcActive then
            ClearVivifyProc()
            FireVivifyEvent("VIVIFY_PROC_CONSUMED")
        else
            FireVivifyEvent("VIVIFY_NORMAL_CAST")
        end
    end
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
    if not iconsRegistered then RegisterIcons(WW_SLOT_DEFS) end
end

function module.Disable()
    onUseWindowTimer = CancelTimer(onUseWindowTimer)
    _G["ZenithActiveTracker"] = false
    HideIcon(KEY_ZENITH)
    ClearVivifyProc()
    UnregisterIcons(WW_SLOT_DEFS)
    if iconFrameRef then iconFrameRef:Hide() end
end

function module.OnSpellCast(spellID, outIconEnabled)
    -- Vivify proc tracking (always active for WW regardless of Zenith window)
    HandleVivifyProcSpell(spellID)

    -- Zenith window tracking
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

OnUseTracker_RegisterModule(module)  -- 269 Windwalker

-- ---- Brewmaster (268) and Mistweaver (270): Vivify proc only ----

local function MakeVivifyOnlyModule(specID)
    local m = {}
    m.specID = specID
    function m.GetIconTextureSpellID() return VIVIFY_SPELL_ID end
    function m.GetTimerDuration() return 0 end
    function m.Enable(iconFrame)
        iconFrameRef = iconFrame
        if not iconsRegistered then RegisterIcons(MONK_VIVIFY_SLOT_DEFS) end
    end
    function m.Disable()
        ClearVivifyProc()
        UnregisterIcons(MONK_VIVIFY_SLOT_DEFS)
        if iconFrameRef then iconFrameRef:Hide() end
    end
    function m.OnSpellCast(spellID, _)
        HandleVivifyProcSpell(spellID)
    end
    return m
end

OnUseTracker_RegisterModule(MakeVivifyOnlyModule(268))  -- Brewmaster
OnUseTracker_RegisterModule(MakeVivifyOnlyModule(270))  -- Mistweaver
