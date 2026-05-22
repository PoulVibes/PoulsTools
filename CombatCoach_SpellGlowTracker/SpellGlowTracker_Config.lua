-- SpellGlowTracker_Config.lua
-- Static data: slot definitions, proc registry, class/spec eligibility helpers.
-- Loads before SpellGlowTracker_UI.lua and SpellGlowTracker.lua.

SpellGlowTracker = SpellGlowTracker or {}
local SGT = SpellGlowTracker

local ICON_SIZE_DEFAULT = 64
local GAP               = 8
local halfStep          = (ICON_SIZE_DEFAULT / 2) + (GAP / 2)

local WINDWALKER_SPEC_ID      = 269
local BM_HUNTER_SPEC_ID       = 253
local SURVIVAL_HUNTER_SPEC_ID = 255

------------------------------------------------------------------------
-- Slot definitions
------------------------------------------------------------------------
SGT.SLOT_DEFS = {
    { key = "Black Out Kick!",           x = -halfStep,      y =  halfStep,      iconSpellID = 100784, iconTexture = 572033,   timerKey = "bok_proc_timer",          buffDuration = 15, classSpec = "MONK_WW"    },
    { key = "Dance of Chi-JI",           x =  halfStep,      y =  halfStep,      iconSpellID = 101546, iconTexture = 607849,   timerKey = "docj_proc_timer",         buffDuration = 15, classSpec = "MONK_WW"    },
    { key = "Touch of Death",            x = -halfStep,      y = -halfStep,      iconSpellID = 322109, timerKey = nil,                                         classSpec = "MONK_ALL"   },
    { key = "Rushing Wind Kick",         x =  halfStep,      y = -halfStep,      iconSpellID = 468179, timerKey = "rwk_proc_timer",          buffDuration = 15, classSpec = "MONK_WW"    },
    -- Hunter entries (Beast Mastery spec only)
    { key = "Howl of the Pack Leader",   x =  3 * halfStep,  y =  halfStep,      iconSpellID = 34026,  iconTexture = 5927643, timerKey = "howl_proc_timer",         buffDuration = 29, classSpec = "HUNTER_BM"  },
    { key = "Black Arrow",               x =  3 * halfStep,  y = -halfStep,      iconSpellID = 466930, timerKey = nil,                                         classSpec = "HUNTER_BM"  },
    { key = "Wailing Arrow",             x =  0,             y = -3 * halfStep,  iconSpellID = 392060, timerKey = "wailing_arrow_proc_timer", buffDuration = 15, classSpec = "HUNTER_BM"  },
    { key = "Hogstrider",                x = -3 * halfStep,  y =  halfStep,      iconSpellID = 193455,  iconTexture = 463878,  timerKey = "hogstrider_proc_timer",         buffDuration = 19, classSpec = "HUNTER_BM"  },
    -- Survival Hunter entries
    { key = "Howl of the Pack Leader",   x =  3 * halfStep,  y =  halfStep,      iconSpellID = 259489,  iconTexture = 5927643, timerKey = "howl_proc_timer",               buffDuration = 29, classSpec = "HUNTER_SV"  },
    { key = "Hogstrider",                x = -3 * halfStep,  y =  halfStep,      iconSpellID = 1261193, iconTexture = 463878,  timerKey = "hogstrider_proc_timer",         buffDuration = 19, classSpec = "HUNTER_SV"  },
    { key = "Moonlight Chakram",         x = -3 * halfStep,  y = -halfStep,      iconSpellID = 1264949,                         timerKey = "moonlight_chakram_proc_timer",  buffDuration = 14, classSpec = "HUNTER_SV"  },
}

SGT.SLOT_DEF_BY_KEY = {}
for _, def in ipairs(SGT.SLOT_DEFS) do SGT.SLOT_DEF_BY_KEY[def.key] = def end

------------------------------------------------------------------------
-- Proc state registry
------------------------------------------------------------------------
SGT.PROC_REGISTRY = {
    [100784] = { globalKey = "bok_proc_active",  key = "Black Out Kick!",  timerKey = "bok_proc_timer",  buffDuration = 15, endTime = 0 },
    [101546] = { globalKey = "docj_proc_active", key = "Dance of Chi-JI",   timerKey = "docj_proc_timer", buffDuration = 15, endTime = 0 },
    [322109] = { globalKey = "tod_proc_active",  key = "Touch of Death" },
    [107428] = { globalKey = "rwk_proc_active",  key = "Rushing Wind Kick", timerKey = "rwk_proc_timer",  buffDuration = 15, endTime = 0 },
    -- Hunter procs
    [34026]  = { globalKey = "howl_proc_active",          key = "Howl of the Pack Leader", timerKey = "howl_proc_timer",         buffDuration = 29, endTime = 0 },
    [466930] = { globalKey = "black_arrow_proc_active",   key = "Black Arrow" },
    [392060] = { globalKey = "wailing_arrow_proc_active", key = "Wailing Arrow",            timerKey = "wailing_arrow_proc_timer", buffDuration = 15, endTime = 0 },
    [193455] = { globalKey = "hogstrider_proc_active",        key = "Hogstrider",               timerKey = "hogstrider_proc_timer",         buffDuration = 19, endTime = 0 },
    -- Survival Hunter procs (different trigger spell IDs than BM)
    [259489]  = { globalKey = "howl_proc_active",              key = "Howl of the Pack Leader",  timerKey = "howl_proc_timer",               buffDuration = 29, endTime = 0 },
    [1261193] = { globalKey = "hogstrider_proc_active",        key = "Hogstrider",               timerKey = "hogstrider_proc_timer",         buffDuration = 19, endTime = 0 },
    [1264949] = { globalKey = "moonlight_chakram_proc_active", key = "Moonlight Chakram",        timerKey = "moonlight_chakram_proc_timer",  buffDuration = 14, endTime = 0 },
}

SGT.TIMED_ENTRIES = {}
for _, entry in pairs(SGT.PROC_REGISTRY) do
    if entry.timerKey then
        table.insert(SGT.TIMED_ENTRIES, entry)
    end
end

------------------------------------------------------------------------
-- Class/spec eligibility helpers
------------------------------------------------------------------------
local function IsPlayerMonk()
    local _, classToken = UnitClass("player")
    return classToken == "MONK"
end

local function IsPlayerHunter()
    local _, classToken = UnitClass("player")
    return classToken == "HUNTER"
end

local function IsPlayerWindwalkerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == WINDWALKER_SPEC_ID
end

local function IsPlayerBMHunterSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == BM_HUNTER_SPEC_ID
end

local function IsPlayerSVHunterSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == SURVIVAL_HUNTER_SPEC_ID
end

function SpellGlowTracker_IsSlotEligible(def)
    local cs = def.classSpec
    if cs == "MONK_ALL"  then return IsPlayerMonk() end
    if cs == "MONK_WW"   then return IsPlayerMonk() and IsPlayerWindwalkerSpec() end
    if cs == "HUNTER_BM" then return IsPlayerHunter() and IsPlayerBMHunterSpec() end
    if cs == "HUNTER_SV" then return IsPlayerHunter() and IsPlayerSVHunterSpec() end
    return false
end

function SpellGlowTracker_HasEligibleSlot()
    for _, def in ipairs(SGT.SLOT_DEFS) do
        if SpellGlowTracker_IsSlotEligible(def) then return true end
    end
    return false
end
