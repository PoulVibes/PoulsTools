-- SBA_Simple_OverrideGUI_Core_CondInputArea.lua
-- Thin orchestrator for condition input area.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateCondInputArea(parent, deps)
    deps = deps or {}

    local state = {
        deps = {
            setBD = deps.setBD,
            getRightPanelWidth = deps.getRightPanelWidth,
            makeOpDropdown = deps.makeOpDropdown,
            closeAllPopups = deps.closeAllPopups or function() end,
            showCondPicker = deps.showCondPicker or function() end,
            showPluginPicker = deps.showPluginPicker or function() end,
            searchSpellBookByName = deps.searchSpellBookByName,
            searchTalentTreeByName = deps.searchTalentTreeByName,
            specSecondary = deps.specSecondary or M.SPEC_SECONDARY,
            specSecondaryDefault = deps.specSecondaryDefault or M.SPEC_SECONDARY_DEFAULT,
            condById = deps.condById or M.COND_BY_ID,
            getVisiblePluginOptions = deps.getVisiblePluginOptions or function() return {} end,
            normalizePluginState = deps.normalizePluginState or M.NormalizePluginState,
            isCompOp = deps.isCompOp or M.IsCompOp,
            setSelectedCondIdx = deps.setSelectedCondIdx or function() end,
            setIsAddingCond = deps.setIsAddingCond or function() end,
            refreshRightPanel = deps.refreshRightPanel or function() end,
            opList = deps.opList or M.OP_LIST,
            procModeList = deps.procModeList or M.PROC_MODE_LIST,
            isCondPickerShown = deps.isCondPickerShown or function() return false end,
            isPluginPickerShown = deps.isPluginPickerShown or function() return false end,
            getEditSpecID = deps.getEditSpecID or function() return 0 end,
            opDropdownPopups = deps.opDropdownPopups or {},
        },
    }

    state.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    state.frame:SetSize(state.deps.getRightPanelWidth() - 10, 95)
    state.deps.setBD(state.frame, 0.04, 0.07, 0.13, 0.97, 0.20, 0.40, 0.60)

    state.selType = nil
    state.spellSel = "this"
    state.resolvedOtherID = nil
    state.resolvedOtherName = nil
    state.resSel = "chi"
    state.opSel = ">="
    state.procModeSel = "active"
    state.selPlugin = nil
    state.isItemRule = false

    M.BuildCondInputAreaWidgets(state)

    state.opDropdown = state.deps.makeOpDropdown(state.operatorFrame, state.deps.opList)
    state.opDropdown:SetPoint("LEFT", state.opLabel, "RIGHT", 4, 0)
    state.opDropdown:SetSelected(">=")
    state.opDropdown:SetOnChange(function(id) state.opSel = id end)

    state.procModeDropdown = state.deps.makeOpDropdown(state.procModeFrame, state.deps.procModeList)
    state.procModeDropdown:SetPoint("LEFT", state.procModeLabel, "RIGHT", 4, 0)
    state.procModeDropdown:SetSelected("active")

    local sec = state.deps.specSecondary[state.deps.getEditSpecID()] or state.deps.specSecondaryDefault
    state.chiBtn:SetText(sec.label)

    M.AttachCondInputAreaBehavior(state)
    M.CondInputArea_RefreshSize(state)

    state.frame.confirmBtn = state.confirmBtn
    state.frame.typeBtn = state.typeBtn

    return state.frame
end

return M
