-- OnUseTracker_Monk.lua
-- Windwalker Monk module for OnUseTracker.
-- Registered with OnUseTracker_RegisterModule() so the main file can delegate to it.

local ADDON_NAME = "On Use Tracker"

local SPEC_ID           = 269  -- Windwalker Monk
local ICON_SIZE_DEFAULT = 64

local KEY_ZENITH = "Zenith Buff"
local KEY_VIVIFY = "Vivacious Vivification"

local KEY_HOJS = "Heart of the Jade Serpent"

-- WW gets both icons; BM/MW get only the Vivify icon.
local WW_SLOT_DEFS = {
    { key = KEY_ZENITH, iconSpellID = 1249625 },
    { key = KEY_VIVIFY, iconSpellID = 116670  },
    { key = KEY_HOJS,   iconSpellID = 443421  },
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

-- Heart of the Jade Serpent (talent) tracking
local HOJS_TALENT_ID                  = 443294  -- Heart of the Jade Serpent (talent/spell id)
local WDP_SPELL_ID                    = 152175  -- Whirling Dragon Punch
local SOTW_SPELL_ID                   = 392983  -- Strike of the Windlord
local HOJS_DURATION_ON_STRIKE         = 6
local HOJS_DURATION_ON_ZENITH         = 4

-- Track multiple concurrent HOJS windows. Each entry is { timer = <C_Timer>, expiresAt = <GetTime()+dur> }
local hojsTimers = {}

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
        [KEY_HOJS]   = { x =  0,   y = -200  },
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

-- ---- Heart of the Jade Serpent helpers ----
-- Update the HOJS icon cooldown and stack count based on active timers
local function UpdateHojsDisplay()
    if not iconsRegistered then return end
    local count = #hojsTimers
    if count == 0 then
        shmIcons:SetStacks(ADDON_NAME, KEY_HOJS, 0)
        HideIcon(KEY_HOJS)
        return
    end
    local now = GetTime()
    local maxRemaining = 0
    for _, e in ipairs(hojsTimers) do
        local rem = (e.expiresAt or 0) - now
        if rem > maxRemaining then maxRemaining = rem end
    end
    if maxRemaining > 0 then
        ShowIcon(KEY_HOJS, maxRemaining)
    else
        HideIcon(KEY_HOJS)
    end
    if count == 1 then
        shmIcons:SetStacks(ADDON_NAME, KEY_HOJS, 0)
    else
        shmIcons:SetStacks(ADDON_NAME, KEY_HOJS, count)
    end
end

local function ClearHojs()
    for _, e in ipairs(hojsTimers) do
        if e.timer and e.timer.Cancel then e.timer:Cancel() end
    end
    hojsTimers = {}
    shmIcons:SetStacks(ADDON_NAME, KEY_HOJS, 0)
    HideIcon(KEY_HOJS)
end

local function StartHojs(duration)
    if not IsPlayerSpell(HOJS_TALENT_ID) then return end
    if not duration or duration <= 0 then return end
    local entry = { expiresAt = GetTime() + duration }
    entry.timer = C_Timer.NewTimer(duration, function()
        for i, v in ipairs(hojsTimers) do
            if v == entry then
                table.remove(hojsTimers, i)
                break
            end
        end
        UpdateHojsDisplay()
    end)
    table.insert(hojsTimers, entry)
    UpdateHojsDisplay()
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
    ClearHojs()
    UnregisterIcons(WW_SLOT_DEFS)
    if iconFrameRef then iconFrameRef:Hide() end
end

function module.OnSpellCast(spellID, outIconEnabled)
    -- Vivify proc tracking (always active for WW regardless of Zenith window)
    HandleVivifyProcSpell(spellID)

    -- Heart of the Jade Serpent: triggered by Whirling Dragon Punch or Strike of the Windlord
    if (spellID == WDP_SPELL_ID or spellID == SOTW_SPELL_ID) and IsPlayerSpell(HOJS_TALENT_ID) then
        StartHojs(HOJS_DURATION_ON_STRIKE)
    end

    -- Zenith window tracking
    if not ZENITH_SPELL_IDS[spellID] then return end
    if _G["ZenithActiveTracker"] then return end

    _G["ZenithActiveTracker"] = true
    if outIconEnabled and iconFrameRef then
        iconFrameRef:Show()
    end

    local duration = GetTimerDuration()
    ShowIcon(KEY_ZENITH, duration)
    -- Zenith cast also grants a shorter Heart of the Jade Serpent window when talented
    if IsPlayerSpell(HOJS_TALENT_ID) then
        StartHojs(HOJS_DURATION_ON_ZENITH)
    end
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
