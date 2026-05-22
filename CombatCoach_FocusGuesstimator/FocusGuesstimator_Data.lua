-- FocusGuesstimator_Data.lua
-- Module table, constants, and mutable state for FocusGuesstimator.
-- Loads first; all other FG files read from this table.

FocusGuesstimator = FocusGuesstimator or {}
local FG = FocusGuesstimator

-- Named event frame (also accessible as global FocusGuesstimatorLogicFrame).
FocusGuesstimatorLogicFrame = CreateFrame("Frame", "FocusGuesstimatorLogicFrame")

------------------------------------------------------------------------
-- Class/spec constants
------------------------------------------------------------------------
FG.REQUIRED_CLASS   = "HUNTER"
FG.REQUIRED_SPEC_ID = 253   -- Beast Mastery
FG.SV_SPEC_ID       = 255   -- Survival

-- Focus is Power Type 2 (Enum.PowerType.Focus).
FG.FOCUS_POWER_TYPE = 2

-- Baseline passive focus regen: 5 focus/sec before haste.
FG.BASE_REGEN = 5

FG.BARBED_SHOT_ID          = 217200
FG.BARBED_SHOT_REGEN_TOTAL = 20
FG.BARBED_SHOT_DURATION    = 8
FG.BARBED_SHOT_REGEN_RATE  = FG.BARBED_SHOT_REGEN_TOTAL / FG.BARBED_SHOT_DURATION  -- 2.5/sec

FG.COBRA_SENSES_SPELL_ID = 378244
FG.COBRA_SHOT_ID         = 193455
FG.COBRA_SHOT_BASE_COST  = 35

FG.LETHAL_BARBS_SPELL_ID = 1264781

FG.ABILITY_COSTS = {
    [34026]          = 30,   -- Kill Command
    [193455]         = 35,   -- Cobra Shot (FG.COBRA_SHOT_BASE_COST; modified by Cobra Senses)
    [217200]         = 217200, -- Barbed Shot (existing value preserved from original)
    [1264359]        = 35,   -- Wild Thrash
    [466930]         = 0,    -- Black Arrow proc
    [392060]         = 0,    -- Wailing Arrow proc
    [19574]          = 0,    -- Bestial Wrath
}

FG.SV_KILL_COMMAND_GAIN = 15

FG.FLANKERS_ADVANTAGE_SPELL_ID = 459964
FG.INVIGORATING_PULSE_SPELL_ID = 450379

FG.SV_TAKEDOWN_ID   = 1250646
FG.SV_TAKEDOWN_GAIN = 50

FG.SV_MUZZLE_ID   = 187707
FG.SV_MUZZLE_GAIN = 30

FG.SV_ABILITY_COSTS = {
    [259495]  = 10,  -- Wildfire Bomb
    [1261193] = 50,  -- Boomstick        (unverified)
    [193265]  = 30,  -- Hatchet Toss     (unverified)
    [186270]  = 30,  -- Raptor Strike
    [1262343] = 30,  -- Raptor Swipe
    [195645]  = 20,  -- Wing Clip
    [1251592] = 20,  -- Flamefang Pitch  (unverified)
}

FG.SHRAPNEL_BOMB_SPELL_ID    = 1253172
FG.SHRAPNEL_BOMB_DURATION    = 3
FG.SHRAPNEL_BOMB_REGEN_TOTAL = 15
FG.SHRAPNEL_BOMB_REGEN_RATE  = FG.SHRAPNEL_BOMB_REGEN_TOTAL / FG.SHRAPNEL_BOMB_DURATION  -- 5/sec

FG.SV_MELEE_WEAPON_BASE_INTERVAL = 1 / 1.8

-- Haste multiplier shared with GuesstimatorHaste; falls back to 21% if absent.
_G.GuesstimatedHaste = _G.GuesstimatedHaste or 0.21

------------------------------------------------------------------------
-- Mutable state
------------------------------------------------------------------------
FG.maxFocus                = 100
FG.addonEnabled            = false
FG.regenMultiplier         = 1.0
FG.cobraSensesActive       = false
FG.lethalBarbsActive       = false
FG.lastKnownRangedCritChance = 0
FG.cobraCritExpectedRefund  = 0
FG.baseRangedWeaponSpeed    = 0
FG.autoShotTimer            = 0
FG.playerInCombat           = false
FG.bardedShotRegenExpiry    = {}
FG.currentSpec              = 0
FG.flankersAdvantageActive  = false
FG.invPulseActive           = false
FG.shrapnelBombActive       = false
FG.shrapnelBombExpiry       = {}

-- currentFocus is intentionally global: readable by SBA / other addons.
currentFocus = FG.maxFocus
