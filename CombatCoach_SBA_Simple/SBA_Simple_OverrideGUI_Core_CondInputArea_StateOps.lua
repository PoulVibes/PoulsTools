-- SBA_Simple_OverrideGUI_Core_CondInputArea_StateOps.lua
-- Shared state operations for condition input area.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CondInputArea_ResetVisibility(state)
    state.spellToggleFrame:Hide()
    state.otherFrame:Hide()
    state.resourceFrame:Hide()
    state.operatorFrame:Hide()
    state.luaFrame:Hide()
    state.pluginFrame:Hide()
    state.procModeFrame:Hide()
    state.stacksValueFrame:Hide()
    state.valLbl:Hide()
    state.valBox:Hide()
end

function M.CondInputArea_UpdateLayout(state)
    local selType = state.selType
    state.operatorFrame:ClearAllPoints()
    if selType and selType.needsResource then
        state.operatorFrame:SetPoint("TOPLEFT", state.resourceFrame, "BOTTOMLEFT", 0, -4)
    else
        state.operatorFrame:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -4)
    end

    local above = state.typeBtn
    if selType and selType.needsSpell then
        above = (state.spellSel == "other") and state.otherFrame or state.spellToggleFrame
    elseif selType and (selType.needsResource or selType.needsCompareValue) then
        above = state.operatorFrame
    elseif selType and selType.needsLua then
        above = state.luaFrame
    elseif selType and selType.needsPlugin then
        above = (state.selPlugin and state.selPlugin.supportsProcMode) and state.procModeFrame or state.pluginFrame
    end

    if selType and selType.needsStacksValue then
        state.stacksValueFrame:ClearAllPoints()
        if state.spellSel == "other" then
            state.stacksValueFrame:SetPoint("TOPLEFT", state.otherFrame, "BOTTOMLEFT", 0, -4)
        else
            state.stacksValueFrame:SetPoint("TOPLEFT", state.spellToggleFrame, "BOTTOMLEFT", 0, -4)
        end
        above = state.stacksValueFrame
    end

    local showVal = selType and (selType.needsValue or selType.needsResource or selType.needsCompareValue or
        (selType.needsPlugin and state.selPlugin and state.selPlugin.supportsProcMode and state.procModeSel ~= "active"))

    if showVal then
        state.valLbl:ClearAllPoints()
        state.valLbl:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -6)
    end

    local h = 6 + 20 + 4 + 22 + 4
    if selType and selType.needsSpell then
        h = h + 22 + 4
        if state.spellSel == "other" then h = h + 38 + 4 end
    end
    if selType and selType.needsStacksValue then h = h + 22 + 4 end
    if selType and selType.needsResource then h = h + 22 + 4 + 22 + 4 end
    if selType and selType.needsCompareValue then h = h + 22 + 4 end
    if selType and selType.needsLua then h = h + 38 + 4 end
    if selType and selType.needsPlugin then
        h = h + 22 + 4
        if state.selPlugin and state.selPlugin.supportsProcMode then h = h + 22 + 4 end
    end
    if showVal then h = h + 22 + 4 end
    state.frame:SetHeight(h + 24 + 8)
end

function M.CondInputArea_RefreshSize(state)
    local rightW = state.deps.getRightPanelWidth()
    local contentW = rightW - 18
    local spellHalfW = math.floor((contentW - 4) / 2)
    local otherBoxW = math.max(120, contentW - 34)
    local resBtnW = math.max(68, math.floor((contentW - 66) / 2))
    local opDropdownW = math.max(60, contentW - 64)

    state.frame:SetWidth(rightW - 10)
    state.typeBtn:SetWidth(contentW)
    state.spellToggleFrame:SetWidth(contentW)
    state.thisBtn:SetWidth(spellHalfW)
    state.otherBtn:SetWidth(spellHalfW)
    state.otherFrame:SetWidth(contentW)
    state.otherNameBox:SetWidth(otherBoxW)
    state.otherResultLbl:SetWidth(contentW - 4)
    state.resourceFrame:SetWidth(contentW)
    state.operatorFrame:SetWidth(contentW)
    state.pluginFrame:SetWidth(contentW)
    state.procModeFrame:SetWidth(contentW)
    state.stacksValueFrame:SetWidth(contentW)
    state.luaFrame:SetWidth(contentW)
    state.pluginBtn:SetWidth(contentW)
    state.luaBox:SetWidth(math.max(120, contentW - 6))
    state.chiBtn:SetWidth(resBtnW)
    state.energyBtn:SetWidth(resBtnW)
    if state.opDropdown then state.opDropdown:UpdateWidth(opDropdownW) end
    if state.procModeDropdown then state.procModeDropdown:UpdateWidth(opDropdownW) end
    if state.stacksValueDropdown then state.stacksValueDropdown:UpdateWidth(opDropdownW) end
    M.CondInputArea_UpdateLayout(state)
end

function M.CondInputArea_Reset(state)
    state.selType = nil
    state.spellSel = "this"
    state.resSel = "chi"
    state.opSel = ">="
    state.procModeSel = "active"
    state.selPlugin = nil
    state.resolvedOtherID = nil
    state.resolvedOtherName = nil

    state.notCheck:SetChecked(false)
    state.typeBtn:SetText("Select condition type...")
    state.pluginBtn:SetText("Select plugin...")
    state.luaBox:SetText("")
    state.otherNameBox:SetText("")
    state.otherResultLbl:SetText("")
    state.otherIcon:Hide()
    state.valBox:SetText("")
    state.stacksValueSel = "max"
    if state.opDropdown then state.opDropdown:SetSelected(">=") end
    if state.procModeDropdown then state.procModeDropdown:SetSelected("active") end
    if state.stacksValueDropdown then state.stacksValueDropdown:SetSelected("max") end

    M.CondInputArea_ResetVisibility(state)
    state.frame:SetHeight(95)
end

function M.CondInputArea_Populate(state, cond, condById)
    M.CondInputArea_Reset(state)
    local ct = condById[cond.type]
    if not ct then return end

    state.selType = ct
    state.typeBtn:SetText(ct.label)
    state.notCheck:SetChecked(cond.negate and true or false)

    if ct.needsSpell then
        state.spellToggleFrame:Show()
        state.thisBtn:SetText("This Spell")
        state.otherBtn:SetText(ct.id == "talented" and "Other Spell / Talent" or "Other Spell")
        if not cond.spell or cond.spell == "this" then
            state.spellSel = "this"
            state.thisBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            state.otherBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
            state.otherFrame:Hide()
        else
            local spellID = type(cond.spell) == "number" and cond.spell or cond.targetID
            if spellID then
                local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
                state.otherNameBox:SetText(n or tostring(spellID))
                state.resolvedOtherID = spellID
            end
            state.spellSel = "other"
            state.otherFrame:Show()
            state.otherBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            state.thisBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        end
    end

    if ct.needsResource then
        state.resourceFrame:Show(); state.operatorFrame:Show()
        local sec = state.deps.specSecondary[state.deps.getEditSpecID()] or state.deps.specSecondaryDefault
        state.chiBtn:SetText(sec.label)
        if sec.inlineExpr then state.energyBtn:Hide() else state.energyBtn:Show() end
        state.resSel = cond.resource or "chi"
        state.opSel = cond.operator or ">="
        state.opDropdown:SetSelected(state.opSel)
        state.valLbl:SetText("Value:"); state.valLbl:Show()
        state.valBox:SetText(tostring(cond.value or 0)); state.valBox:Show()
    end

    if ct.needsCompareValue then
        state.operatorFrame:Show()
        state.opSel = cond.operator or ">="
        state.opDropdown:SetSelected(state.opSel)
        state.valLbl:SetText((ct.valueLabel or "Value") .. ":"); state.valLbl:Show()
        state.valBox:SetText(tostring(cond.value or ct.default or 0)); state.valBox:Show()
    end

    if ct.needsLua then
        state.luaFrame:Show()
        state.luaLabel:SetText((ct.luaLabel or "Lua expression") .. ":")
        state.luaBox:SetText(cond.luaCode or "")
    end

    if ct.needsPlugin then
        state.pluginFrame:Show()
        local pluginID, savedOp, savedValue = state.deps.normalizePluginState(cond)
        for _, opt in ipairs(state.deps.getVisiblePluginOptions() or {}) do
            if opt.id == pluginID then
                state.selPlugin = opt
                state.pluginBtn:SetText(opt.label)
                if opt.supportsProcMode then
                    state.procModeFrame:Show()
                    local mode = state.deps.isCompOp(savedOp) and savedOp or "active"
                    state.procModeSel = mode
                    state.procModeDropdown:SetSelected(mode)
                    if mode ~= "active" then
                        state.valLbl:SetText("Seconds:")
                        state.valLbl:Show()
                        state.valBox:SetText(tostring(savedValue or opt.default or 4))
                        state.valBox:Show()
                    end
                end
                break
            end
        end
    end

    if ct.needsValue then
        state.valLbl:SetText((ct.valueLabel or "Value") .. ":")
        state.valLbl:Show()
        state.valBox:SetText(tostring(cond.value or ct.default or ""))
        state.valBox:Show()
    end

    if ct.needsStacksValue then
        state.stacksValueFrame:Show()
        local v = tostring(cond.value or "max")
        if v ~= "0" and v ~= "1" and v ~= "max" then v = "max" end
        state.stacksValueSel = v
        if state.stacksValueDropdown then state.stacksValueDropdown:SetSelected(v) end
    end

    M.CondInputArea_UpdateLayout(state)
end

return M
