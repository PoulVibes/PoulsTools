-- SBA_Simple_OverrideGUI_Core_TransferPopup.lua
-- Shared transfer popup helpers (export/import text UI).

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateTransferPopup(setBD, titleText, confirmText)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(520, 390)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    setBD(f, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText(titleText)
    title:SetTextColor(0.55, 0.82, 1, 1)

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    note:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -30)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.68, 0.78, 0.9, 1)
    f.note = note

    local boxFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    boxFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -52)
    boxFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 44)
    setBD(boxFrame, 0.03, 0.05, 0.09, 0.95, 0.17, 0.28, 0.42)

    local sf = CreateFrame("ScrollFrame", nil, boxFrame)
    sf:SetPoint("TOPLEFT", boxFrame, "TOPLEFT", 4, -4)
    sf:SetPoint("BOTTOMRIGHT", boxFrame, "BOTTOMRIGHT", -4, 4)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 24, 0), m))
    end)

    local edit = CreateFrame("EditBox", nil, sf)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(486)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        local lines = (self.GetNumLines and self:GetNumLines() or 1)
        self:SetHeight(math.max(320, lines * 14 + 16))
    end)
    sf:SetScrollChild(edit)

    local confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    confirmBtn:SetSize(110, 24)
    confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
    confirmBtn:SetText(confirmText)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(110, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f.editBox = edit
    f.confirmBtn = confirmBtn

    return f
end

function M.ShowExportPopup(state, anchor, specID, tabsRules, count)
    if not state.exportPopup then
        state.exportPopup = M.CreateTransferPopup(state.setBD, "Export SBA Rules", "Select All")
    end
    local exportPopup = state.exportPopup
    local noteText = (count and count > 1)
        and ("Copy this text — includes all %d tabs for this spec."):format(count)
        or "Copy this text and keep it as your backup for the currently open spec."
    exportPopup.note:SetText(noteText)
    exportPopup.editBox:SetText(state.serializeAllTabsForExport(specID, tabsRules, count or 1))
    exportPopup.confirmBtn:SetScript("OnClick", function()
        exportPopup.editBox:SetFocus()
        exportPopup.editBox:HighlightText()
    end)
    exportPopup:ClearAllPoints()
    exportPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    exportPopup:Show()
    exportPopup.editBox:SetFocus()
    exportPopup.editBox:HighlightText()
end

function M.ShowImportPopup(state, anchor, onImport)
    if not state.importPopup then
        state.importPopup = M.CreateTransferPopup(state.setBD, "Import SBA Rules", "Import")
    end
    local importPopup = state.importPopup
    importPopup.note:SetText("Paste exported text for this spec, then click Import.")
    importPopup.editBox:SetText("")
    importPopup.confirmBtn:SetScript("OnClick", function()
        if onImport and onImport(importPopup.editBox:GetText() or "") then
            importPopup:Hide()
        end
    end)
    importPopup:ClearAllPoints()
    importPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    importPopup:Show()
    importPopup.editBox:SetFocus()
end
