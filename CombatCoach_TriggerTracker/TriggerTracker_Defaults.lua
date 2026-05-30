-- TriggerTracker_Defaults.lua
-- Preloaded triggers applied once per spec when no saved triggers exist yet.
-- To populate: run /tt export in-game, copy the output, and paste it below.

TriggerTracker_Defaults = TriggerTracker_Defaults or {}

-- ============================================================
-- PASTE EXPORTED TRIGGERS BELOW THIS LINE
-- ============================================================



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
