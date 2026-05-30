-- TriggerTracker_Defaults.lua
-- Preloaded triggers applied once per spec when no saved triggers exist yet.
-- To populate: run /tt export in-game, copy the output, and paste it below.

TriggerTracker_Defaults = TriggerTracker_Defaults or {}

-- ============================================================
-- PASTE EXPORTED TRIGGERS BELOW THIS LINE
-- ============================================================
TriggerTracker_Defaults = TriggerTracker_Defaults or {}

TriggerTracker_Defaults[253] = {
    [1] = {
        buffSpellID = 19574,
        enabled = false,
        generators = {
            [19574] = 1,
        },
        glow_enabled = false,
        iconID = 132127,
        maxStacks = 0,
        name = "Bestial Wrath",
        spellName = "Bestial Wrath",
        spendPerCast = 1,
        spenders = {

        },
        timer = 15,
    },
    [2] = {
        buffSpellID = 19574,
        enabled = false,
        generators = {
            [19574] = 1,
        },
        glow_enabled = false,
        iconID = 132127,
        maxStacks = 0,
        name = "Bestial Wrath - CD",
        spellName = "Bestial Wrath - CD",
        spendPerCast = 1,
        spenders = {

        },
        timer = 30,
    },
    [3] = {
        buffSpellID = 1273043,
        enabled = false,
        generators = {
            [19574] = 1,
        },
        glow_enabled = false,
        iconID = 7636556,
        maxStacks = 0,
        name = "Nature's Ally",
        spellName = "Nature's Ally",
        spendPerCast = 1,
        spenders = {

        },
        timer = 15,
    },
    [4] = {
        buffSpellID = 466990,
        enabled = false,
        generators = {
            [19574] = 1,
        },
        glow_enabled = false,
        iconID = 136181,
        maxStacks = 0,
        name = "Withering Fire",
        spellName = "Withering Fire",
        spendPerCast = 1,
        spenders = {

        },
        timer = 10,
    },
}

TriggerTracker_Defaults[255] = {
    [1] = {
        buffSpellID = 260285,
        enabled = false,
        generators = {
            [259489] = 2,
            [1250646] = 3,
        },
        glow_enabled = false,
        iconID = 1117879,
        maxStacks = 3,
        name = "Tip of the Spear",
        spellName = "Tip of the Spear",
        spendPerCast = 1,
        spenders = {
            [186270] = true,
            [193265] = true,
            [259495] = true,
            [1250646] = true,
            [1259003] = true,
            [1261193] = true,
            [1264902] = true,
        },
        strata = "MEDIUM",
        timer = 10,
    },
    [2] = {
        buffSpellID = 1250646,
        enabled = false,
        generators = {
            [1250646] = 1,
        },
        glow_enabled = false,
        iconID = 7439201,
        maxStacks = 0,
        name = "Takedown",
        spellName = "Takedown",
        spendPerCast = 1,
        spenders = {

        },
        strata = "MEDIUM",
        timer = 10,
    },
}

TriggerTracker_Defaults[269] = {
    [1] = {
        buffSpellID = 443294,
        enabled = false,
        generators = {
            [152175] = 1,
            [392983] = 1,
        },
        glow_enabled = false,
        iconID = 574571,
        maxStacks = 0,
        name = "Heart of the Jade Serpent",
        requiredTalents = {
            [443294] = true,
        },
        spellName = "Heart of the Jade Serpent",
        spendPerCast = 1,
        spenders = {

        },
        timer = 6,
    },
    [2] = {
        buffSpellID = 1249625,
        enabled = false,
        generators = {
            [1249625] = 1,
        },
        glow_enabled = false,
        iconID = 6035314,
        maxStacks = 0,
        name = "Zenith",
        spellName = "Zenith",
        spendPerCast = 1,
        spenders = {

        },
        strata = "MEDIUM",
        timer = 15,
    },
}



-- ============================================================
-- END OF DEFAULTS
-- ============================================================

-- Applies defaults for specID only if the spec currently has no saved triggers.
function TriggerTracker_ApplyDefaults(specID)
    local defaults = TriggerTracker_Defaults[specID]
    if not defaults then return end
    local existing = TriggerTracker_GetSpecDB(specID)
    if next(existing) then return end

    local idxList = {}
    for idx in pairs(defaults) do idxList[#idxList + 1] = idx end
    table.sort(idxList)

    for _, idx in ipairs(idxList) do
        local src = defaults[idx]
        if type(src) == "table" then
            TriggerTracker_AddTrigger(specID, TriggerTracker_CopyEntry(src))
        end
    end
end
