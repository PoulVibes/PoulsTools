-- CooldownTracker_State.lua
-- Module table initialization for CooldownTracker.
-- Loaded first; all other CT files use CooldownTracker (aliased as CT).

CooldownTracker = CooldownTracker or {}
local CT = CooldownTracker

CT.FOLDER_NAME         = "CombatCoach_CooldownTracker"
CT.ADDON_NAME          = "Cooldown Tracker"
CT.DEFAULT_SIZE        = 64
CT.POLL_INTERVAL       = 0.10

-- Mutable state shared across files
CT.tracked             = {}          -- spellKey -> { spellName, spellID }
CT.changeListeners     = {}          -- registered callback functions
CT.warnedDormant       = {}          -- keys that have shown the dormant warning this session
CT.currentSpecID       = nil         -- spec ID that icons were last loaded for
