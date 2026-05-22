-- DynamicBuffTracker_State.lua
-- Module table and shared state for DynamicBuffTracker.
-- Loads first; all other DBT files reference DynamicBuffTracker (aliased as DBT).

DynamicBuffTracker = DynamicBuffTracker or {}
local DBT = DynamicBuffTracker

DBT.ADDON_FOLDER  = "CombatCoach_DynamicBuffTracker"
DBT.ADDON_NAME    = "Dynamic Buff Tracker"
DBT.DEFAULT_SIZE  = 64
DBT.SCAN_INTERVAL = 5.0
DBT.MAX_RETRIES   = 6

-- Mutable runtime state
DBT.currentSpecID   = 0
DBT.trackedSpells   = {}
DBT.hookedChildren  = {}
DBT.retryCount      = 0
DBT.retryPending    = false
DBT.cdmFrames       = {}
DBT.cdmSpellToFrame = {}
DBT.cdmFrameToSpell = {}
DBT.buffTimerStart  = {}  -- [spellIDStr] -> GetTime() recorded when buff became active
DBT.buffTimerHandles = {} -- [spellIDStr] -> { ticker=..., endTime=..., timerVar=..., specID=... }
DBT.iconShown = {}        -- [spellIDStr] -> true when shmIcon is currently shown

-- Forward reference: assigned by the CombatCoach panel file.
DBT.rebuildCombatCoachList = nil
