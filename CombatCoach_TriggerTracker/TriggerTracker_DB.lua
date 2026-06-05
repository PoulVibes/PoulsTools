-- TriggerTracker_DB.lua
-- Helpers for reading and writing trigger entries in SavedVariables.

local TT = TriggerTracker

-- Returns the next available trigger index for a spec (1-based, fills gaps).
local function NextTriggerIndex(triggers)
    local maxIdx = 0
    for k in pairs(triggers) do
        local n = tonumber(k)
        if n and n > maxIdx then maxIdx = n end
    end
    return maxIdx + 1
end

-- Creates a new trigger entry and returns its index.
-- entry = { name, iconID, generators={[spellID]=true}, spenders={[spellID]=true},
--           buffSpellID, maxStacks, timer, x, y, point, size, enabled }
function TriggerTracker_AddTrigger(specID, entry)
    local triggers = TriggerTracker_GetSpecDB(specID)
    local idx      = NextTriggerIndex(triggers)
    entry.enabled  = entry.enabled ~= false
    entry.size     = entry.size or TT.DEFAULT_SIZE
    entry.maxStacks = entry.maxStacks or 5
    triggers[idx]  = entry
    return idx
end

-- Replaces an existing trigger entry (by 1-based index).
function TriggerTracker_SetTrigger(specID, idx, entry)
    local triggers = TriggerTracker_GetSpecDB(specID)
    triggers[idx]  = entry
end

-- Removes a trigger entry (and its shmIcon) by index.
function TriggerTracker_RemoveTrigger(specID, idx)
    local triggers = TriggerTracker_GetSpecDB(specID)
    if not triggers[idx] then return end
    local key = TriggerTracker_MakeKey(specID, idx)
    pcall(function()
        shmIcons:Unregister(TT.ADDON_NAME, key)
    end)
    if shmIcons and shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end
    triggers[idx] = nil
    TT.activeStacks[key] = nil
    if TT.timerHandles[key] then
        pcall(function() TT.timerHandles[key]:Cancel() end)
        TT.timerHandles[key] = nil
    end
    TT.timerEnd[key] = nil
end

-- Iterates triggers for a spec, calling fn(idx, entry) for each.
function TriggerTracker_ForEachTrigger(specID, fn)
    local triggers = TriggerTracker_GetSpecDB(specID)
    for idx, entry in pairs(triggers) do
        fn(idx, entry)
    end
end

-- Returns true if the player currently has all spells in entry.requiredTalents.
-- An entry with no requiredTalents always returns true.
function TriggerTracker_HasRequiredTalents(entry)
    local req = entry and entry.requiredTalents
    if not req then return true end
    for spellID in pairs(req) do
        if not IsSpellKnown(spellID) then return false end
    end
    return true
end

-- Returns a deep copy of a trigger entry suitable for editing.
function TriggerTracker_CopyEntry(entry)
    if not entry then return {} end
    local copy = {}
    for k, v in pairs(entry) do
        if type(v) == "table" then
            local sub = {}
            for sk, sv in pairs(v) do sub[sk] = sv end
            copy[k] = sub
        else
            copy[k] = v
        end
    end
    return copy
end

-- Builds a fast lookup: spellID -> { mode="generate"|"spend", key, maxStacks }
-- Used by the event handler to avoid iterating every frame.
function TriggerTracker_BuildSpellMap(specID)
    local map = {}
    local triggers = TriggerTracker_GetSpecDB(specID)
    for idx, entry in pairs(triggers) do
        if TriggerTracker_HasRequiredTalents(entry) then
            local key = TriggerTracker_MakeKey(specID, idx)
            if entry.generators then
                for spellID, amt in pairs(entry.generators) do
                    local perCast = (amt == true) and 1 or (tonumber(amt) or 1)
                    map[spellID] = map[spellID] or {}
                    table.insert(map[spellID], {
                        mode      = "generate",
                        key       = key,
                        maxStacks = tonumber(entry.maxStacks) or 5,
                        timer     = tonumber(entry.timer) or 0,
                        perCast   = perCast,
                    })
                end
            end
            if entry.spenders then
                for spellID in pairs(entry.spenders) do
                    map[spellID] = map[spellID] or {}
                    table.insert(map[spellID], {
                        mode    = "spend",
                        key     = key,
                        perCast = entry.spendPerCast or 1,
                    })
                end
            end
            if entry.extenders then
                for spellID, amt in pairs(entry.extenders) do
                    local extAmt = (amt == true) and 5 or (tonumber(amt) or 5)
                    map[spellID] = map[spellID] or {}
                    table.insert(map[spellID], {
                        mode         = "extend",
                        key          = key,
                        extendAmount = extAmt,
                        maxDuration  = tonumber(entry.maxDuration) or 0,
                    })
                end
            end
        end
    end
    return map
end
