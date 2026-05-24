-- SBA_Simple_OverrideGUI_Core_CondInputArea_Widgets.lua
-- UI widget construction for condition input area.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.BuildCondInputAreaWidgets(state)
    local deps = state.deps
    local f = state.frame
    local width = deps.getRightPanelWidth

    local function panelW()
        return width() - 18
    end

    state.notCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    state.notCheck:SetSize(20, 20)
    state.notCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)

    state.notLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.notLbl:SetPoint("LEFT", state.notCheck, "RIGHT", 2, 0)
    state.notLbl:SetText("NOT (negate)")
    state.notLbl:SetTextColor(0.90, 0.55, 0.38, 1)

    state.typeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    state.typeBtn:SetSize(panelW(), 22)
    state.typeBtn:SetPoint("TOPLEFT", state.notCheck, "BOTTOMLEFT", 0, -4)
    state.typeBtn:SetText("Select condition type...")

    state.spellToggleFrame = CreateFrame("Frame", nil, f)
    state.spellToggleFrame:SetSize(panelW(), 22)
    state.spellToggleFrame:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -4)
    state.spellToggleFrame:Hide()

    local halfW = math.floor((panelW() - 4) / 2)
    state.thisBtn = CreateFrame("Button", nil, state.spellToggleFrame, "UIPanelButtonTemplate")
    state.thisBtn:SetSize(halfW, 22)
    state.thisBtn:SetPoint("TOPLEFT", state.spellToggleFrame, "TOPLEFT")
    state.thisBtn:SetText("This Spell")

    state.otherBtn = CreateFrame("Button", nil, state.spellToggleFrame, "UIPanelButtonTemplate")
    state.otherBtn:SetSize(halfW, 22)
    state.otherBtn:SetPoint("LEFT", state.thisBtn, "RIGHT", 2, 0)
    state.otherBtn:SetText("Other Spell")

    state.otherFrame = CreateFrame("Frame", nil, f)
    state.otherFrame:SetSize(panelW(), 38)
    state.otherFrame:SetPoint("TOPLEFT", state.spellToggleFrame, "BOTTOMLEFT", 0, -2)
    state.otherFrame:Hide()

    state.otherNameBox = CreateFrame("EditBox", nil, state.otherFrame, "InputBoxTemplate")
    state.otherNameBox:SetSize(panelW() - 34, 20)
    state.otherNameBox:SetPoint("TOPLEFT", state.otherFrame, "TOPLEFT")
    state.otherNameBox:SetAutoFocus(false)
    state.otherNameBox:SetMaxLetters(80)

    state.otherIcon = state.otherFrame:CreateTexture(nil, "ARTWORK")
    state.otherIcon:SetSize(18, 18)
    state.otherIcon:SetPoint("LEFT", state.otherNameBox, "RIGHT", 4, 0)
    state.otherIcon:Hide()

    state.otherResultLbl = state.otherFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    state.otherResultLbl:SetPoint("TOPLEFT", state.otherNameBox, "BOTTOMLEFT", 0, -2)
    state.otherResultLbl:SetSize(panelW() - 4, 14)
    state.otherResultLbl:SetJustifyH("LEFT")

    state.resourceFrame = CreateFrame("Frame", nil, f)
    state.resourceFrame:SetSize(panelW(), 22)
    state.resourceFrame:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -4)
    state.resourceFrame:Hide()

    state.resLabel = state.resourceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.resLabel:SetPoint("LEFT", state.resourceFrame, "LEFT", 0, 0)
    state.resLabel:SetWidth(60)
    state.resLabel:SetText("Resource:")
    state.resLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    state.chiBtn = CreateFrame("Button", nil, state.resourceFrame, "UIPanelButtonTemplate")
    state.chiBtn:SetSize(88, 22)
    state.chiBtn:SetPoint("LEFT", state.resLabel, "RIGHT", 4, 0)

    state.energyBtn = CreateFrame("Button", nil, state.resourceFrame, "UIPanelButtonTemplate")
    state.energyBtn:SetSize(88, 22)
    state.energyBtn:SetPoint("LEFT", state.chiBtn, "RIGHT", 2, 0)
    state.energyBtn:SetText("Energy")

    state.operatorFrame = CreateFrame("Frame", nil, f)
    state.operatorFrame:SetSize(panelW(), 22)
    state.operatorFrame:SetPoint("TOPLEFT", state.resourceFrame, "BOTTOMLEFT", 0, -4)
    state.operatorFrame:Hide()

    state.opLabel = state.operatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.opLabel:SetPoint("LEFT", state.operatorFrame, "LEFT", 0, 0)
    state.opLabel:SetWidth(60)
    state.opLabel:SetText("Operator:")
    state.opLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    state.pluginFrame = CreateFrame("Frame", nil, f)
    state.pluginFrame:SetSize(panelW(), 22)
    state.pluginFrame:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -4)
    state.pluginFrame:Hide()

    state.pluginBtn = CreateFrame("Button", nil, state.pluginFrame, "UIPanelButtonTemplate")
    state.pluginBtn:SetSize(panelW(), 22)
    state.pluginBtn:SetPoint("TOPLEFT", state.pluginFrame, "TOPLEFT")
    state.pluginBtn:SetText("Select plugin...")

    state.procModeFrame = CreateFrame("Frame", nil, f)
    state.procModeFrame:SetSize(panelW(), 22)
    state.procModeFrame:SetPoint("TOPLEFT", state.pluginFrame, "BOTTOMLEFT", 0, -4)
    state.procModeFrame:Hide()

    state.procModeLabel = state.procModeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.procModeLabel:SetPoint("LEFT", state.procModeFrame, "LEFT", 0, 0)
    state.procModeLabel:SetWidth(60)
    state.procModeLabel:SetText("Mode:")
    state.procModeLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    state.luaFrame = CreateFrame("Frame", nil, f)
    state.luaFrame:SetSize(panelW(), 38)
    state.luaFrame:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -4)
    state.luaFrame:Hide()

    state.luaLabel = state.luaFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.luaLabel:SetPoint("TOPLEFT", state.luaFrame, "TOPLEFT", 0, 0)
    state.luaLabel:SetText("Lua expression:")
    state.luaLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    state.luaBox = CreateFrame("EditBox", nil, state.luaFrame, "InputBoxTemplate")
    state.luaBox:SetSize(panelW() - 6, 20)
    state.luaBox:SetPoint("TOPLEFT", state.luaLabel, "BOTTOMLEFT", 0, -2)
    state.luaBox:SetAutoFocus(false)
    state.luaBox:SetMaxLetters(512)

    state.valLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    state.valLbl:SetPoint("TOPLEFT", state.typeBtn, "BOTTOMLEFT", 0, -6)
    state.valLbl:SetTextColor(0.55, 0.72, 0.88, 1)
    state.valLbl:Hide()

    state.valBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    state.valBox:SetSize(72, 22)
    state.valBox:SetPoint("LEFT", state.valLbl, "RIGHT", 6, 0)
    state.valBox:SetAutoFocus(false)
    state.valBox:SetNumeric(true)
    state.valBox:SetMaxLetters(6)
    state.valBox:Hide()

    state.confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    state.confirmBtn:SetSize(88, 24)
    state.confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
    state.confirmBtn:SetText("Add")

    state.cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    state.cancelBtn:SetSize(76, 24)
    state.cancelBtn:SetPoint("LEFT", state.confirmBtn, "RIGHT", 6, 0)
    state.cancelBtn:SetText("Cancel")
end

return M
