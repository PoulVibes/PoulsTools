-- SBA_Simple_OverrideGUI_Core_GUIFrameCallbacks.lua
-- Builds GUI frame callback set for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.BuildGUIFrameCallbacks(deps)
    return {
        onHide = function()
            deps.closeAllPopups()
            local editSpecID = deps.getEditSpecID()
            if editSpecID and editSpecID ~= 0 then
                local allTabRules = deps.getAllTabRules()
                local activeTabIdx = deps.getActiveTabIdx()
                local workingRules = deps.getWorkingRules()
                local tabCount = deps.getTabCountCurrent()
                allTabRules[activeTabIdx] = workingRules
                local sessionAllTabs = deps.getSessionAllTabs()
                sessionAllTabs[editSpecID] = sessionAllTabs[editSpecID] or {}
                for t = 1, tabCount do
                    local rules = allTabRules[t] or {}
                    sessionAllTabs[editSpecID][t] = rules
                    deps.setGuiTabRules(editSpecID, t, deps.deepCopyRules(rules))
                end
            end
        end,

        onLogout = function()
            local editSpecID = deps.getEditSpecID()
            if editSpecID and editSpecID ~= 0 then
                local allTabRules = deps.getAllTabRules()
                local activeTabIdx = deps.getActiveTabIdx()
                local workingRules = deps.getWorkingRules()
                local tabCount = deps.getTabCountCurrent()
                allTabRules[activeTabIdx] = workingRules
                for t = 1, tabCount do
                    deps.setGuiTabRules(editSpecID, t, deps.deepCopyRules(allTabRules[t] or {}))
                end
            end
        end,

        onAddTab = function()
            deps.addNewTab()
        end,

        onAddSpell = function(anchor)
            local addSpellPopup = deps.getAddSpellPopup()
            if addSpellPopup and addSpellPopup:IsShown() then
                deps.closeAllPopups()
                return
            end
            deps.closeAllPopups()
            addSpellPopup = deps.getAddSpellPopup()
            addSpellPopup.onAdd = function(id, name)
                local addID, addName = deps.resolveSpellForAdd(id, name)
                if not addID then return end
                local workingRules = deps.getWorkingRules()
                workingRules[#workingRules + 1] = { spellID = addID, name = addName, conditions = {} }
                deps.setSelectedIdx(#workingRules)
                deps.setIsAddingCond(false)
                deps.refreshRuleList()
                deps.refreshRightPanel()
            end
            addSpellPopup.nameBox:SetText("")
            addSpellPopup.iconTex:Hide()
            addSpellPopup:ClearAllPoints()
            addSpellPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
            addSpellPopup:Show()
            addSpellPopup.nameBox:SetFocus()
        end,

        onAddCondition = function()
            local selectedIdx = deps.getSelectedIdx()
            local workingRules = deps.getWorkingRules()
            if selectedIdx > 0 and workingRules[selectedIdx] then
                deps.setSelectedCondIdx(nil)
                deps.setIsAddingCond(true)
                deps.refreshRightPanel()
            end
        end,

        onSave = function(f)
            local state = deps.buildOpenLoadState()
            if M.HandleSaveAndApply then
                M.HandleSaveAndApply(state, {
                    hasParenMismatch = deps.hasParenMismatch,
                    setGuiTabRules = deps.setGuiTabRules,
                    deepCopyRules = deps.deepCopyRules,
                    generateCode = deps.generateCode,
                    currentSpecID = deps.currentSpecID,
                    getSpecName = deps.getSpecName,
                    serializeAllTabsForExport = deps.serializeAllTabsForExport,
                    serializeRulesForExportV2 = deps.serializeRulesForExportV2,
                    hideGUI = function() f:Hide() end,
                })
            end
            deps.applyOpenLoadState(state)
        end,

        onPreview = function()
            local of = _G["SBAS_OverrideFrame"]
            if of and of:IsShown() then
                of:Hide()
                return
            end
            local code = deps.generateCode(deps.getWorkingRules()) or "-- (no rules defined)"
            local editSpecID = deps.getEditSpecID()
            if type(SBA_Simple_ShowOverridePreview) == "function" then
                SBA_Simple_ShowOverridePreview(code, editSpecID, deps.getSpecName(editSpecID))
            else
                local eb = _G["SBAS_OverrideEditBox"]
                if eb and of then
                    eb:SetText(code)
                    of:Show()
                else
                    print("|cff00ccffSBAS Preview:|r\n" .. code)
                end
            end
        end,

        onExport = function(anchor)
            local allTabRules = deps.getAllTabRules()
            local activeTabIdx = deps.getActiveTabIdx()
            allTabRules[activeTabIdx] = deps.getWorkingRules()
            deps.showExportPopup(anchor, deps.getEditSpecID(), allTabRules, deps.getTabCountCurrent())
        end,

        onImport = function(anchor)
            deps.showImportPopup(anchor, function(payload)
                local state = deps.buildOpenLoadState()
                local importDeps = deps.buildOpenLoadDeps()
                if importDeps then
                    importDeps.refreshTabBar = function()
                        deps.applyOpenLoadState(state)
                        if deps.refreshTabBar then
                            deps.refreshTabBar()
                        else
                            deps.refreshRuleList()
                            deps.refreshRightPanel()
                        end
                    end
                    importDeps.refreshRuleList = function()
                        deps.applyOpenLoadState(state)
                        deps.refreshRuleList()
                    end
                    importDeps.refreshRightPanel = function()
                        deps.applyOpenLoadState(state)
                        deps.refreshRightPanel()
                    end
                end

                local ok, modeOrErr, count = M.ApplyImportPayload and M.ApplyImportPayload(state, importDeps, payload)
                if not ok then
                    print("|cffff4444SBAS Override GUI:|r Import failed - " .. tostring(modeOrErr or "invalid text"))
                    return false
                end
                deps.applyOpenLoadState(state)
                local editSpecID = deps.getEditSpecID()
                if modeOrErr == "multi" then
                    print("|cff00ff99SBAS Override GUI:|r Imported " .. tostring(count)
                          .. " tab" .. (count == 1 and "" or "s")
                          .. " for " .. deps.getSpecName(editSpecID)
                          .. ". Click Save & Apply to compile.")
                else
                    print("|cff00ff99SBAS Override GUI:|r Imported " .. tostring(count)
                          .. " priorit" .. ((count == 1) and "y" or "ies")
                          .. " for " .. deps.getSpecName(editSpecID)
                          .. ". Click Save & Apply to compile.")
                end
                return true
            end)
        end,

        onClear = function()
            local workingRules = {}
            deps.setWorkingRules(workingRules)
            local allTabRules = deps.getAllTabRules()
            local activeTabIdx = deps.getActiveTabIdx()
            allTabRules[activeTabIdx] = workingRules
            local editSpecID = deps.getEditSpecID()
            local sessionAllTabs = deps.getSessionAllTabs()
            sessionAllTabs[editSpecID] = sessionAllTabs[editSpecID] or {}
            sessionAllTabs[editSpecID][activeTabIdx] = workingRules
            deps.setSelectedIdx(0)
            deps.setIsAddingCond(false)
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end,

        onLayout = function()
            local condInputArea = deps.getCondInputArea()
            if condInputArea and condInputArea.RefreshSize then condInputArea.RefreshSize() end
            local guiFrame = deps.getGUIFrame()
            if guiFrame and guiFrame:IsShown() then
                deps.refreshRuleList()
                deps.refreshRightPanel()
            end
        end,
    }
end

return M
