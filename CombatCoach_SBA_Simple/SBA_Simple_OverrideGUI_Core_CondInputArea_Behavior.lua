-- SBA_Simple_OverrideGUI_Core_CondInputArea_Behavior.lua
-- Behavior wiring for condition input area.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

local ITEM_DISABLED_THIS = {
    reactive_enabled = true,
    usable = true,
    talented = true,
    sba_suggests = true,
    last_ability_eq = true,
}

function M.AttachCondInputAreaBehavior(state)
    local deps = state.deps
    local f = state.frame
    local ctById = deps.condById
    local specSecondary = deps.specSecondary
    local secDefault = deps.specSecondaryDefault

    local function HlBtn(btn, selected)
        btn:GetFontString():SetTextColor(selected and 1.0 or 0.65, selected and 1.0 or 0.65, selected and 0.5 or 0.65, 1)
    end

    local function SetResSel(mode)
        state.resSel = mode
        HlBtn(state.chiBtn, mode == "chi")
        HlBtn(state.energyBtn, mode == "energy")
    end

    local function SetOpSel(mode)
        state.opSel = mode
        if state.opDropdown then state.opDropdown:SetSelected(mode) end
    end

    local function SetSpellSel(mode)
        state.spellSel = mode
        if mode == "this" then
            state.otherFrame:Hide()
            state.thisBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            state.otherBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        else
            state.otherFrame:Show()
            state.otherBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            state.thisBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        end
        M.CondInputArea_UpdateLayout(state)
    end

    local function ApplyItemModeToSpellToggle()
        local selType = state.selType
        if not selType or not selType.needsSpell then return end
        if state.isItemRule then
            if selType.id == "on_cd" then
                state.thisBtn:SetText("This Item")
                state.thisBtn:Enable()
            elseif ITEM_DISABLED_THIS[selType.id] then
                state.thisBtn:SetText("This Spell")
                state.thisBtn:Disable()
                if state.spellSel == "this" then SetSpellSel("other") end
            else
                state.thisBtn:SetText("This Spell")
                state.thisBtn:Enable()
            end
        else
            state.thisBtn:Enable()
            state.thisBtn:SetText("This Spell")
            if selType.id == "talented" then
                state.otherBtn:SetText("Other Spell / Talent")
            else
                state.otherBtn:SetText("Other Spell")
            end
        end
    end

    state.thisBtn:SetScript("OnClick", function() SetSpellSel("this") end)
    state.otherBtn:SetScript("OnClick", function() SetSpellSel("other") end)
    state.chiBtn:SetScript("OnClick", function() SetResSel("chi") end)
    state.energyBtn:SetScript("OnClick", function() SetResSel("energy") end)

    state.cancelBtn:SetScript("OnClick", function()
        deps.setSelectedCondIdx(nil)
        deps.setIsAddingCond(false)
        deps.refreshRightPanel()
    end)

    state.otherNameBox:SetScript("OnTextChanged", function()
        local input = state.otherNameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            state.otherResultLbl:SetText("")
            state.otherIcon:Hide()
            state.resolvedOtherID = nil
            return
        end

        local id, name, tex, errText
        if M.ResolveCondInputOtherSpell then
            id, name, tex, errText = M.ResolveCondInputOtherSpell(input, {
                searchSpellBookByName = deps.searchSpellBookByName,
                searchTalentTreeByName = deps.searchTalentTreeByName,
            })
        end

        if id and id > 0 then
            state.resolvedOtherID = id
            state.resolvedOtherName = name or input
            state.otherResultLbl:SetText("|cff55ee55" .. (state.resolvedOtherName or input) .. "|r  ID:" .. id)
            if tex then
                state.otherIcon:SetTexture(tex)
                state.otherIcon:Show()
            else
                state.otherIcon:Hide()
            end
        else
            state.resolvedOtherID = nil
            state.otherResultLbl:SetText(errText or "|cffff5555Not found|r")
            state.otherIcon:Hide()
        end
    end)

    state.typeBtn:SetScript("OnClick", function()
        if deps.isCondPickerShown() then deps.closeAllPopups(); return end
        deps.closeAllPopups()
        deps.showCondPicker(state.typeBtn, function(ct)
            state.selType = ct
            state.selPlugin = nil
            state.typeBtn:SetText(ct.label)
            M.CondInputArea_ResetVisibility(state)

            if ct.needsSpell then
                state.spellToggleFrame:Show()
                state.thisBtn:SetText("This Spell")
                state.otherBtn:SetText(ct.id == "talented" and "Other Spell / Talent" or "Other Spell")
                SetSpellSel("this")
                ApplyItemModeToSpellToggle()
            end
            if ct.needsResource then
                state.resourceFrame:Show()
                state.operatorFrame:Show()
                local sec = specSecondary[deps.getEditSpecID()] or secDefault
                state.chiBtn:SetText(sec.label)
                if sec.inlineExpr then state.energyBtn:Hide() else state.energyBtn:Show() end
                SetResSel("chi")
                SetOpSel(">=")
                state.valLbl:SetText("Value:")
                state.valLbl:Show()
                state.valBox:SetText("0")
                state.valBox:Show()
            end
            if ct.needsCompareValue then
                state.operatorFrame:Show()
                SetOpSel(">=")
                state.valLbl:SetText((ct.valueLabel or "Value") .. ":")
                state.valLbl:Show()
                state.valBox:SetText(tostring(ct.default or 0))
                state.valBox:Show()
            end
            if ct.needsLua then
                state.luaFrame:Show()
                state.luaLabel:SetText((ct.luaLabel or "Lua expression") .. ":")
                state.luaBox:SetText("")
            end
            if ct.needsPlugin then
                state.pluginFrame:Show()
                state.pluginBtn:SetText("Select plugin...")
                state.procModeSel = "active"
                if state.procModeDropdown then state.procModeDropdown:SetSelected("active") end
            end
            if ct.needsValue then
                state.valLbl:SetText((ct.valueLabel or "Value") .. ":")
                state.valLbl:Show()
                state.valBox:SetText(tostring(ct.default or ""))
                state.valBox:Show()
            end
            M.CondInputArea_UpdateLayout(state)
        end)
    end)

    state.pluginBtn:SetScript("OnClick", function()
        if deps.isPluginPickerShown() then deps.closeAllPopups(); return end
        deps.closeAllPopups()
        deps.showPluginPicker(state.pluginBtn, function(opt)
            state.selPlugin = opt
            state.pluginBtn:SetText(opt.label)
            if opt.supportsProcMode then
                state.procModeFrame:Show()
                state.procModeSel = "active"
                if state.procModeDropdown then state.procModeDropdown:SetSelected("active") end
                state.valLbl:Hide(); state.valBox:Hide()
            else
                state.procModeFrame:Hide()
                state.valLbl:Hide(); state.valBox:Hide()
            end
            M.CondInputArea_UpdateLayout(state)
        end)
    end)

    state.procModeDropdown:SetOnChange(function(id)
        state.procModeSel = id
        if id == "active" then
            state.valLbl:Hide(); state.valBox:Hide()
        else
            state.valLbl:SetText("Seconds:")
            state.valLbl:Show()
            if state.valBox:GetText() == "" then state.valBox:SetText("4") end
            state.valBox:Show()
        end
        M.CondInputArea_UpdateLayout(state)
    end)

    state.luaBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    f.SetItemMode = function(isItem)
        state.isItemRule = isItem and true or false
        ApplyItemModeToSpellToggle()
    end

    f.GetSelectedType = function() return state.selType end
    f.GetValue = function() return tonumber(state.valBox:GetText()) end
    f.GetNegate = function() return state.notCheck:GetChecked() and true or false end
    f.GetResource = function() return state.resSel end
    f.GetOperator = function() return state.opSel end
    f.GetProcMode = function() return state.procModeSel end
    f.GetPlugin = function() return state.selPlugin and state.selPlugin.id or nil end
    f.GetLuaCode = function()
        local expr = state.luaBox:GetText() and state.luaBox:GetText():match("^%s*(.-)%s*$") or ""
        if expr == "" then return nil end
        return expr
    end
    f.GetSpell = function()
        if not state.selType or not state.selType.needsSpell then return nil end
        if state.spellSel == "this" then return "this" end
        return state.resolvedOtherID
    end

    f.RefreshSpec = function()
        local sec = specSecondary[deps.getEditSpecID()] or secDefault
        state.chiBtn:SetText(sec.label)
        if sec.inlineExpr then state.energyBtn:Hide() else state.energyBtn:Show() end
    end

    f.RefreshSize = function() M.CondInputArea_RefreshSize(state) end
    f.Reset = function() M.CondInputArea_Reset(state) end
    f.Populate = function(cond) M.CondInputArea_Populate(state, cond, ctById) end
end

return M
