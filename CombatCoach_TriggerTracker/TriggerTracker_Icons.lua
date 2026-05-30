-- TriggerTracker_Icons.lua
-- shmIcons registration and stack/timer management.

local TT = TriggerTracker

-- Forward declarations for SBAS condition helpers (defined later in this file).
local RegisterSBASConditions, UnregisterSBASConditions

-- Registers a shmIcon for one trigger entry.
function TriggerTracker_RegisterIcon(specID, idx, entry)
    local key  = TriggerTracker_MakeKey(specID, idx)
    local ADDON = TT.ADDON_NAME

    -- Ensure the entry has a DB-style position table that shmIcons can write into.
    entry.x     = entry.x     or 0
    entry.y     = entry.y     or 0
    entry.point = entry.point or "CENTER"
    entry.size  = entry.size  or TT.DEFAULT_SIZE

    shmIcons:Register(ADDON, key, entry, {
        onResize = function(sq) entry.size = sq end,
        onMove   = function(_db) end,
    })

    local iconID = entry.iconID or 134400
    if entry.buffSpellID then
        local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(entry.buffSpellID)
        if si and si.iconID then iconID = si.iconID end
    end
    shmIcons:SetIcon(ADDON, key, iconID)
    shmIcons:SetDisplayName(ADDON, key, entry.name or ("Trigger " .. tostring(key)))
    shmIcons:SetStacks(ADDON, key, 0)
    shmIcons:SetGlow(ADDON, key, false)
    shmIcons:SetVisible(ADDON, key, false)
    shmIcons:SetCooldownReverse(ADDON, key, true)  -- buff timers sweep fill-up, not drain

    if shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end
end

-- Unregisters the shmIcon for one trigger entry.
function TriggerTracker_UnregisterIcon(specID, idx)
    pcall(function()
        shmIcons:Unregister(TT.ADDON_NAME, TriggerTracker_MakeKey(specID, idx))
    end)
    if shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end
end

-- Loads all triggers for a spec: registers icons and resets runtime state.
function TriggerTracker_LoadSpec(specID)
    TT.currentSpecID = specID
    TT.activeStacks  = {}
    for k, h in pairs(TT.timerHandles) do
        pcall(function() h:Cancel() end)
    end
    TT.timerHandles = {}
    TT.timerEnd     = {}

    if specID == 0 then return end

    TriggerTracker_ForEachTrigger(specID, function(idx, entry)
        TriggerTracker_RegisterIcon(specID, idx, entry)
    end)

    TT.spellMap = TriggerTracker_BuildSpellMap(specID)
    RegisterSBASConditions(specID)
    if TT.rebuildCombatCoachList then TT.rebuildCombatCoachList() end
end

-- Unloads all icons for the current spec without touching SavedVariables.
function TriggerTracker_UnloadSpec()
    local specID = TT.currentSpecID
    if specID == 0 then return end
    TriggerTracker_ForEachTrigger(specID, function(idx, _entry)
        TriggerTracker_UnregisterIcon(specID, idx)
    end)
    TT.activeStacks = {}
    for k, h in pairs(TT.timerHandles) do
        pcall(function() h:Cancel() end)
    end
    TT.timerHandles = {}
    TT.timerEnd     = {}
    TT.spellMap     = {}
    UnregisterSBASConditions(TT.currentSpecID)
end

-- Adds one stack to a trigger icon, respecting maxStacks; starts/refreshes timer.
function TriggerTracker_AddStack(key, maxStacks, timerDuration, amount)
    local cur  = TT.activeStacks[key] or 0
    local maxS = tonumber(maxStacks) or 5
    cur = math.min(cur + (tonumber(amount) or 1), maxS)
    TT.activeStacks[key] = cur

    shmIcons:SetStacks(TT.ADDON_NAME, key, cur)
    shmIcons:SetGlow(TT.ADDON_NAME, key, true)
    shmIcons:SetVisible(TT.ADDON_NAME, key, true)

    if timerDuration and timerDuration > 0 then
        TriggerTracker_StartTimer(key, timerDuration)
    end
end

-- Removes one stack from a trigger icon; hides icon when stacks reach 0.
function TriggerTracker_SpendStack(key, amount)
    local cur = TT.activeStacks[key] or 0
    if cur <= 0 then return end
    if amount == "all" then
        cur = 0
    else
        cur = math.max(cur - (tonumber(amount) or 1), 0)
    end
    TT.activeStacks[key] = cur

    if cur <= 0 then
        shmIcons:SetStacks(TT.ADDON_NAME, key, 0)
        shmIcons:SetGlow(TT.ADDON_NAME, key, false)
        shmIcons:SetVisible(TT.ADDON_NAME, key, false)
        TriggerTracker_CancelTimer(key)
    else
        shmIcons:SetStacks(TT.ADDON_NAME, key, cur)
    end
end

-- Starts a countdown timer; cancels any existing one for the same key.
function TriggerTracker_StartTimer(key, duration)
    TriggerTracker_CancelTimer(key)
    local endTime = GetTime() + duration
    TT.timerEnd[key] = endTime
    local start = GetTime()
    shmIcons:SetCooldownRaw(TT.ADDON_NAME, key, start, duration)

    TT.timerHandles[key] = C_Timer.NewTimer(duration, function()
        TT.timerHandles[key] = nil
        TT.timerEnd[key]     = nil
        TT.activeStacks[key] = 0
        shmIcons:SetStacks(TT.ADDON_NAME, key, 0)
        shmIcons:SetGlow(TT.ADDON_NAME, key, false)
        shmIcons:SetVisible(TT.ADDON_NAME, key, false)
        shmIcons:SetCooldownRaw(TT.ADDON_NAME, key, 0, 0)
    end)
end

-- Cancels a running timer without clearing stacks.
function TriggerTracker_CancelTimer(key)
    if TT.timerHandles[key] then
        pcall(function() TT.timerHandles[key]:Cancel() end)
        TT.timerHandles[key] = nil
    end
    TT.timerEnd[key] = nil
    shmIcons:SetCooldownRaw(TT.ADDON_NAME, key, 0, 0)
end

-- Public accessor: returns current stack count for a trigger key (safe to call from generated Lua).
function TriggerTracker_GetActiveStacks(key)
    return TT.activeStacks[key] or 0
end

-- Public accessor: returns remaining timer seconds for a trigger key (0 when inactive).
function TriggerTracker_GetTimerRemaining(key)
    local t = TT.timerEnd[key]
    if not t then return 0 end
    return math.max(t - GetTime(), 0)
end

-- ============================================================
-- SBAS plugin condition registry
-- ============================================================
-- Populated when a spec loads so that SBA_Simple's override GUI
-- can offer per-trigger conditions ("Active" and timer comparisons).

RegisterSBASConditions = function(specID)
    _G.SBAS_TriggerTrackerRegistry = _G.SBAS_TriggerTrackerRegistry or {}
    TriggerTracker_ForEachTrigger(specID, function(idx, entry)
        local key       = TriggerTracker_MakeKey(specID, idx)
        local pluginID  = "tt_" .. key
        local name      = entry.name or ("Trigger " .. idx)
        local maxStacks = tonumber(entry.maxStacks) or 0
        _G.SBAS_TriggerTrackerRegistry[pluginID] = {
            specID    = specID,
            label     = name,
            key       = key,
            hasTimer  = (tonumber(entry.timer) or 0) > 0,
            maxStacks = maxStacks,
        }
        if maxStacks > 0 then
            _G.SBAS_TriggerTrackerRegistry["tt_stacks_" .. key] = {
                specID        = specID,
                label         = name .. " (Stacks)",
                key           = key,
                isStacksEntry = true,
            }
        end
    end)
end

UnregisterSBASConditions = function(specID)
    if not _G.SBAS_TriggerTrackerRegistry then return end
    for pluginID, entry in pairs(_G.SBAS_TriggerTrackerRegistry) do
        if entry.specID == specID then
            _G.SBAS_TriggerTrackerRegistry[pluginID] = nil
        end
    end
end

-- Public: full rebuild for specID (call after creating, editing, or deleting a trigger).
function TriggerTracker_RefreshSBASConditions(specID)
    UnregisterSBASConditions(specID)
    RegisterSBASConditions(specID)
end
