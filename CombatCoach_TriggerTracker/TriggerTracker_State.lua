-- TriggerTracker_State.lua
-- Module table and shared runtime state. Loads first.

TriggerTracker = TriggerTracker or {}
local TT = TriggerTracker

TT.ADDON_FOLDER = "CombatCoach_TriggerTracker"
TT.ADDON_NAME   = "Trigger Tracker"
TT.DEFAULT_SIZE = 64

-- Runtime state
TT.currentSpecID = 0
TT.activeStacks  = {}   -- [triggerKey] -> current stack count (integer)
TT.timerHandles  = {}   -- [triggerKey] -> C_Timer ticker handle
TT.timerEnd      = {}   -- [triggerKey] -> end time (GetTime())

-- Forward ref: set by CombatCoach panel file to trigger list rebuild.
TT.rebuildCombatCoachList = nil

-- Returns a stable string key for a trigger entry.
function TriggerTracker_MakeKey(specID, triggerIdx)
    return tostring(specID) .. "_" .. tostring(triggerIdx)
end

-- Returns the DB table for the current spec, creating it if needed.
function TriggerTracker_GetSpecDB(specID)
    TriggerTrackerDB          = TriggerTrackerDB or {}
    TriggerTrackerDB.specs    = TriggerTrackerDB.specs or {}
    TriggerTrackerDB.specs[specID] = TriggerTrackerDB.specs[specID] or {}
    TriggerTrackerDB.specs[specID].triggers = TriggerTrackerDB.specs[specID].triggers or {}
    return TriggerTrackerDB.specs[specID].triggers
end

-- Returns the current spec ID (0 if none active).
function TriggerTracker_GetCurrentSpecID()
    local index = GetSpecialization and GetSpecialization()
    if not index then return 0 end
    local id = GetSpecializationInfo and select(1, GetSpecializationInfo(index))
    return id or 0
end
