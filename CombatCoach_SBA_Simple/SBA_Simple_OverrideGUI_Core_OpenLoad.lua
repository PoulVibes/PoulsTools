-- SBA_Simple_OverrideGUI_Core_OpenLoad.lua
-- Shared open/load/import state transitions for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.PrepareOpenState(state, deps, targetSpec)
	local newSpec = targetSpec or deps.currentSpecID()
	if newSpec == 0 then newSpec = state.editSpecID end

	if newSpec ~= state.editSpecID then
		state.editSpecID = newSpec
		if deps.refreshCondInputSpec then deps.refreshCondInputSpec() end

		state.tabCount = deps.getTabCount(state.editSpecID)
		state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
		state.allTabRules = {}
		state.tabNames = {}

		for t = 1, state.tabCount do
			if state.sessionAllTabs[state.editSpecID][t] then
				state.allTabRules[t] = state.sessionAllTabs[state.editSpecID][t]
			else
				state.allTabRules[t] = deps.deepCopyRules(deps.getGuiTabRules(state.editSpecID, t))
				state.sessionAllTabs[state.editSpecID][t] = state.allTabRules[t]
			end
			state.tabNames[t] = deps.getTabName(state.editSpecID, t)
		end

		state.activeTabIdx = 1
		state.workingRules = state.allTabRules[1] or {}
		state.allTabRules[1] = state.workingRules
		state.selectedIdx = (#state.workingRules > 0) and 1 or 0
		state.isAddingCond = false
		state.selectedCondIdx = nil
	else
		state.allTabRules[state.activeTabIdx] = state.workingRules
	end

	state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
	for t = 1, state.tabCount do
		if not state.sessionAllTabs[state.editSpecID][t] then
			state.sessionAllTabs[state.editSpecID][t] = state.allTabRules[t]
		end
	end

	return state.editSpecID
end

function M.ApplyImportedTabs(state, deps, tabs)
	local newCount = #tabs

	for t = newCount + 1, state.tabCount do
		deps.setGuiTabRules(state.editSpecID, t, {})
		deps.setTabName(state.editSpecID, t, nil)
		if SBA_SimpleDB.guiTabs and SBA_SimpleDB.guiTabs[state.editSpecID] then
			SBA_SimpleDB.guiTabs[state.editSpecID][t] = nil
		end
	end

	for t = 1, newCount do
		local rules = deps.deepCopyRules(tabs[t].rules)
		state.allTabRules[t] = rules
		state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
		state.sessionAllTabs[state.editSpecID][t] = rules
		deps.setGuiTabRules(state.editSpecID, t, deps.deepCopyRules(rules))

		if t > 1 then
			state.tabNames[t] = tabs[t].name
			deps.setTabName(state.editSpecID, t, tabs[t].name)
			if type(_G.SBA_Simple_SetTabName) == "function" then
				_G.SBA_Simple_SetTabName(t, tabs[t].name)
			end
		end
	end

	for t = newCount + 1, state.tabCount do
		state.allTabRules[t] = nil
		state.tabNames[t] = nil
	end

	state.tabCount = newCount
	deps.setTabCount(state.editSpecID, state.tabCount)
	if type(_G.SBA_Simple_UpdateTabCount) == "function" then
		_G.SBA_Simple_UpdateTabCount(state.editSpecID, state.tabCount)
	end

	state.activeTabIdx = 1
	state.workingRules = state.allTabRules[1] or {}
	state.allTabRules[1] = state.workingRules
	state.selectedIdx = (#state.workingRules > 0) and 1 or 0
	state.selectedCondIdx = nil
	state.isAddingCond = false

	deps.refreshTabBar()
	deps.refreshRuleList()
	deps.refreshRightPanel()

	return newCount
end

function M.ApplyImportedSingleTab(state, deps, imported)
	state.workingRules = deps.deepCopyRules(imported)
	state.allTabRules[state.activeTabIdx] = state.workingRules
	state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
	state.sessionAllTabs[state.editSpecID][state.activeTabIdx] = state.workingRules
	state.selectedIdx = (#state.workingRules > 0) and 1 or 0
	state.selectedCondIdx = nil
	state.isAddingCond = false

	deps.refreshRuleList()
	deps.refreshRightPanel()

	return #state.workingRules
end

function M.ApplyImportPayload(state, deps, payload)
	local tabs = deps.deserializeAllTabsFromExport(payload, state.editSpecID)
	if tabs then
		local count = M.ApplyImportedTabs(state, deps, tabs)
		return true, "multi", count
	end

	local imported, err = deps.deserializeRulesFromExport(payload, state.editSpecID)
	if not imported then
		return false, tostring(err or "invalid text")
	end

	local count = M.ApplyImportedSingleTab(state, deps, imported)
	return true, "single", count
end

function M.ApplyRulesTable(state, deps, rules)
	state.workingRules = deps.deepCopyRules(rules)
	state.allTabRules[state.activeTabIdx] = state.workingRules
	state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
	state.sessionAllTabs[state.editSpecID][state.activeTabIdx] = state.workingRules
	state.selectedIdx = (#state.workingRules > 0) and 1 or 0
	state.selectedCondIdx = nil
	state.isAddingCond = false

	deps.refreshRuleList()
	deps.refreshRightPanel()
end

function M.GetDefaultOverrideCodeForSpec(state, deps, specID)
	local rec = _G.SBAS_GetRecommendedImportForSpec and _G.SBAS_GetRecommendedImportForSpec(specID)
	if not (rec and rec.importText) then return nil end

	local rules = deps.deserializeRulesFromExport(rec.importText, specID)
	if not rules or #rules == 0 then return nil end

	local prevSpec = state.editSpecID
	state.editSpecID = specID
	local code = deps.generateCode(rules)
	state.editSpecID = prevSpec
	return code
end
