-- SBA_Simple_OverrideGUI_Core_RightPanelFooter.lua
-- Add-condition button and editor area wiring for the right panel.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.RenderRightPanelFooter(rule, yBase, deps)
    deps.rightPanel.addCondBtn:SetWidth(deps.getRightPanelWidth() - 12)
    deps.rightPanel.addCondBtn:ClearAllPoints()
    deps.rightPanel.addCondBtn:SetPoint("TOPLEFT", deps.rightPanel, "TOPLEFT", 6, yBase - 4)
    deps.rightPanel.addCondBtn:Show()
    yBase = yBase - 32

    if deps.getIsAddingCond() then
        local condInputArea = deps.getCondInputArea()
        if not condInputArea then
            condInputArea = deps.createCondInputArea(deps.rightPanel)
            deps.setCondInputArea(condInputArea)
        end

        condInputArea.confirmBtn:SetText(deps.getSelectedCondIdx() and "Update" or "Add")
        condInputArea.confirmBtn:SetScript("OnClick", function()
            local ct = condInputArea.GetSelectedType()
            if not ct then
                print("|cffff4444SBAS GUI:|r Select a condition type first.")
                return
            end

            local newCond = { type = ct.id, negate = condInputArea.GetNegate() }
            if ct.needsValue then newCond.value = condInputArea.GetValue() or ct.default end
            if ct.needsStacksValue then newCond.value = condInputArea.GetStacksValue() end
            if ct.needsResource then
                newCond.resource = condInputArea.GetResource()
                newCond.operator = condInputArea.GetOperator()
                newCond.value = condInputArea.GetValue() or 0
            end
            if ct.needsCompareValue then
                newCond.operator = condInputArea.GetOperator()
                newCond.value = condInputArea.GetValue() or ct.default or 0
            end
            if ct.needsLua then
                newCond.luaCode = condInputArea.GetLuaCode()
                if not newCond.luaCode then
                    print("|cffff4444SBAS GUI:|r Enter a Lua expression first.")
                    return
                end
            end
            if ct.needsPlugin then
                local pid = condInputArea.GetPlugin()
                if not pid then
                    print("|cffff4444SBAS GUI:|r Select a plugin/proc first.")
                    return
                end
                newCond.plugin = pid
                local mode = condInputArea.GetProcMode()
                local reg = (_G.SBAS_DynBuffRegistry and _G.SBAS_DynBuffRegistry[pid])
                    or (_G.SBAS_DynActivationRegistry and _G.SBAS_DynActivationRegistry[pid])
                if reg and reg.timerVar and deps.isCompOp(mode) then
                    newCond.operator = mode
                    newCond.value = condInputArea.GetValue() or 4
                elseif _G.SBAS_TriggerTrackerRegistry and _G.SBAS_TriggerTrackerRegistry[pid] then
                    if deps.isCompOp(mode) then
                        newCond.operator = mode
                        newCond.value = condInputArea.GetValue() or 1
                    end
                end
            end
            if ct.needsSpell then
                local sp = condInputArea.GetSpell()
                if sp == nil then
                    print("|cffff4444SBAS GUI:|r Enter a valid spell name for 'Other Spell'.")
                    return
                end
                newCond.spell = sp
            end

            local selectedIdx = deps.getSelectedIdx()
            local r = deps.workingRules[selectedIdx]
            if r then
                r.conditions = r.conditions or {}
                local selectedCondIdx = deps.getSelectedCondIdx()
                if selectedCondIdx then
                    local existing = r.conditions[selectedCondIdx]
                    if existing then
                        -- Preserve structural fields (parens, junction) that the editor doesn't touch.
                        if existing.lparen   then newCond.lparen   = existing.lparen   end
                        if existing.rparen   then newCond.rparen   = existing.rparen   end
                        if existing.junction then newCond.junction = existing.junction end
                        for k in pairs(existing) do existing[k] = nil end
                        for k, v in pairs(newCond) do existing[k] = v end
                    end
                else
                    r.conditions[#r.conditions + 1] = newCond
                end
            end

            deps.setSelectedCondIdx(nil)
            deps.setIsAddingCond(false)
            deps.refreshRightPanel()
            deps.refreshRuleList()
        end)

        condInputArea:ClearAllPoints()
        if condInputArea.RefreshSize then condInputArea.RefreshSize() end
        condInputArea:SetPoint("TOPLEFT", deps.rightPanel, "TOPLEFT", 6, yBase - 4)

        local selectedCondIdx = deps.getSelectedCondIdx()
        local selectedIdx = deps.getSelectedIdx()
        if selectedCondIdx then
            local r = deps.workingRules[selectedIdx]
            local existingCond = r and r.conditions and r.conditions[selectedCondIdx]
            if existingCond then
                condInputArea.Populate(existingCond)
            else
                condInputArea.Reset()
            end
        else
            condInputArea.Reset()
        end

        local activeRule = deps.workingRules[selectedIdx]
        condInputArea.SetItemMode(activeRule and activeRule.itemID ~= nil)
        condInputArea:Show()
    else
        local condInputArea = deps.getCondInputArea()
        if condInputArea then condInputArea:Hide() end
    end
end
