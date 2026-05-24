-- SBA_Simple_OverrideGUI_Core_Reset.lua
-- Reset operations for override GUI state.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.ResetToBlizzardSBA(state, deps, specID)
    local rules = deps.getBlizzardSBADefaultRules()
    deps.setGuiTabRules(specID, 1, rules)

    SBA_SimpleDB.specs = SBA_SimpleDB.specs or {}
    SBA_SimpleDB.specs[specID] = SBA_SimpleDB.specs[specID] or {}
    SBA_SimpleDB.specs[specID].overrideMode = "blizzard"

    local code = deps.generateCode(rules)
    if type(_G.SBA_Simple_SetAllTabOverrideCodes) == "function" then
        _G.SBA_Simple_SetAllTabOverrideCodes(specID, { code })
    else
        SBA_SimpleDB.specs[specID].overrideCode = code
    end

    if deps.isGUIOpen() and state.editSpecID == specID then
        local fresh = deps.deepCopyRules(rules)
        state.allTabRules[1] = fresh
        state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
        state.sessionAllTabs[state.editSpecID][1] = fresh
        if state.activeTabIdx == 1 then
            state.workingRules = fresh
            state.selectedIdx = 1
            state.isAddingCond = false
            state.selectedCondIdx = nil
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end
    end
end
