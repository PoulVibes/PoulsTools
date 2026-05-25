DynamicActivationTracker = DynamicActivationTracker or {}

local DAT = DynamicActivationTracker

DAT.ADDON_FOLDER = "CombatCoach_DynamicActivationTracker"
DAT.ADDON_NAME = "Dynamic Activation Tracker"
DAT.DEFAULT_SIZE = 64
DAT.currentSpecID = 0
DAT.runtimeIcons = DAT.runtimeIcons or {}
DAT.iconShown = DAT.iconShown or {}
DAT.conditionTimers = DAT.conditionTimers or {}
DAT.initialized = false
DAT.rebuildCombatCoachList = DAT.rebuildCombatCoachList or nil