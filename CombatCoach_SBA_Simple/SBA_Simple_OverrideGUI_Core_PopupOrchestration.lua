-- SBA_Simple_OverrideGUI_Core_PopupOrchestration.lua
-- Popup lifecycle helpers for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.NewPopupController(deps)
    local state = {
        condPicker = nil,
        pluginPicker = nil,
        addSpellPopup = nil,
        exportPopup = nil,
        importPopup = nil,
        transferPopupState = nil,
        opDropdownPopups = {},
    }

    local function CloseAllPopups()
        if state.condPicker and state.condPicker:IsShown() then state.condPicker:Hide() end
        if state.pluginPicker and state.pluginPicker:IsShown() then state.pluginPicker:Hide() end
        if state.addSpellPopup and state.addSpellPopup:IsShown() then state.addSpellPopup:Hide() end
        if state.exportPopup and state.exportPopup:IsShown() then state.exportPopup:Hide() end
        if state.importPopup and state.importPopup:IsShown() then state.importPopup:Hide() end
        for _, p in ipairs(state.opDropdownPopups) do
            if p:IsShown() then p:Hide() end
        end
    end

    local function ShowCondPicker(anchor, callback)
        if not state.condPicker then
            state.condPicker = M.CreateCondPicker(deps.setBD, deps.getVisibleCondTypes)
        end
        state.condPicker:UpdateRows()
        M.ShowPickerBelowOrAbove(state.condPicker, anchor, callback)
    end

    local function ShowPluginPicker(anchor, callback)
        if not state.pluginPicker then
            state.pluginPicker = M.CreatePluginPicker(deps.setBD, deps.getVisiblePluginOptions)
        end
        state.pluginPicker:UpdateRows()
        if #deps.getVisiblePluginOptions() == 0 then return end
        M.ShowPickerBelowOrAbove(state.pluginPicker, anchor, callback)
    end

    local function GetAddSpellPopup()
        if not state.addSpellPopup then
            state.addSpellPopup = M.CreateAddSpellPopup(deps.setBD)
        end
        return state.addSpellPopup
    end

    local function MakeOpDropdown(parent, ops)
        return M.MakeOpDropdown(parent, ops, {
            setBD = deps.setBD,
            closeAllPopups = CloseAllPopups,
            opDropdownPopups = state.opDropdownPopups,
        })
    end

    local function ShowExportPopup(anchor, specID, tabsRules, count)
        state.transferPopupState = state.transferPopupState or {
            setBD = deps.setBD,
            serializeAllTabsForExport = deps.serializeAllTabsForExport,
            exportPopup = nil,
            importPopup = nil,
        }
        M.ShowExportPopup(state.transferPopupState, anchor, specID, tabsRules, count)
        state.exportPopup = state.transferPopupState.exportPopup
    end

    local function ShowImportPopup(anchor, onImport)
        state.transferPopupState = state.transferPopupState or {
            setBD = deps.setBD,
            serializeAllTabsForExport = deps.serializeAllTabsForExport,
            exportPopup = nil,
            importPopup = nil,
        }
        M.ShowImportPopup(state.transferPopupState, anchor, onImport)
        state.importPopup = state.transferPopupState.importPopup
    end

    return {
        CloseAllPopups = CloseAllPopups,
        ShowCondPicker = ShowCondPicker,
        ShowPluginPicker = ShowPluginPicker,
        GetAddSpellPopup = GetAddSpellPopup,
        MakeOpDropdown = MakeOpDropdown,
        ShowExportPopup = ShowExportPopup,
        ShowImportPopup = ShowImportPopup,
        IsCondPickerShown = function() return state.condPicker and state.condPicker:IsShown() end,
        IsPluginPickerShown = function() return state.pluginPicker and state.pluginPicker:IsShown() end,
        GetOpDropdownPopups = function() return state.opDropdownPopups end,
    }
end

return M
