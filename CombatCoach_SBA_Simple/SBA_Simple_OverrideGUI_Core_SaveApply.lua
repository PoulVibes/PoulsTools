-- SBA_Simple_OverrideGUI_Core_SaveApply.lua
-- Save/apply handler for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.HandleSaveAndApply(state, deps)
    state.allTabRules[state.activeTabIdx] = state.workingRules

    local mismatched = {}
    for tIdx = 1, state.tabCount do
        local rules = state.allTabRules[tIdx] or {}
        for i, rule in ipairs(rules) do
            if deps.hasParenMismatch(rule.conditions) then
                mismatched[#mismatched + 1] = "Tab " .. tIdx .. " #" .. i
            end
        end
    end
    if #mismatched > 0 then
        print("|cffFF4444SBAS Override GUI:|r Save blocked - mismatched parentheses: "
              .. table.concat(mismatched, ", ") .. ". Fix the red rows first.")
        return false
    end

    local allCodes = {}
    for tIdx = 1, state.tabCount do
        local rules = state.allTabRules[tIdx] or {}
        deps.setGuiTabRules(state.editSpecID, tIdx, deps.deepCopyRules(rules))
        state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
        state.sessionAllTabs[state.editSpecID][tIdx] = state.allTabRules[tIdx]
        allCodes[tIdx] = deps.generateCode(rules) or ""
    end

    if type(_G.SBA_Simple_SetAllTabOverrideCodes) == "function" then
        _G.SBA_Simple_SetAllTabOverrideCodes(state.editSpecID, allCodes)
    else
        local specEntry = SBA_SimpleDB.specs[state.editSpecID] or {}
        specEntry.overrideCode = allCodes[1] or ""
        specEntry.overrideSource = "gui"
        SBA_SimpleDB.overrideCode = specEntry.overrideCode
        if state.editSpecID == deps.currentSpecID() and type(SBA_Simple_SetOverrideCode) == "function" then
            SBA_Simple_SetOverrideCode(allCodes[1] or "")
        end
    end

    print("|cff00ff99SBAS Override GUI:|r " .. state.tabCount .. " tab"
          .. (state.tabCount == 1 and "" or "s") .. " saved for "
          .. deps.getSpecName(state.editSpecID))

    if type(_G.SBAS_OnGuiSaveAndApply) == "function" then
        local tabsRules = {}
        for t = 1, state.tabCount do tabsRules[t] = state.allTabRules[t] or {} end
        local savedExport = deps.serializeAllTabsForExport(state.editSpecID, tabsRules, state.tabCount)
        _G.SBAS_OnGuiSaveAndApply(state.editSpecID, savedExport)
    end

    deps.hideGUI()

    local af = _G["SBAS_OverrideAnalyzerFrame"]
    if af and af:IsShown() and type(_G.SBAS_OpenOrRefreshAnalyzer) == "function" then
        _G.SBAS_OpenOrRefreshAnalyzer(state.editSpecID, deps.getSpecName(state.editSpecID))
    end

    return true
end
