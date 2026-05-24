-- SBA_Simple_OverrideGUI_Core_GUIFrame.lua
-- Main GUI frame scaffold and widget construction.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateGUIFrame(deps)
    local f = CreateFrame("Frame", "SBAS_OverrideGUI_Frame", UIParent, "BackdropTemplate")
    f:SetSize(deps.GUI_W, deps.GUI_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:SetFrameStrata("HIGH")
    if f.SetResizeBounds then
        f:SetResizeBounds(deps.GUI_MIN_W, deps.GUI_MIN_H)
    elseif f.SetMinResize then
        f:SetMinResize(deps.GUI_MIN_W, deps.GUI_MIN_H)
    end
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    deps.setBD(f, 0.03, 0.05, 0.09, 0.97, 0.24, 0.44, 0.64)

    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            if not InCombatLockdown() then self:SetPropagateKeyboardInput(false) end
        else
            if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end
        end
    end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetTextColor(0.38, 0.74, 1, 1)

    local subNote = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subNote:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
    subNote:SetText("Top = highest priority · Saving overwrites override code for this spec")
    subNote:SetTextColor(0.44, 0.55, 0.68, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f:HookScript("OnHide", function() deps.onHide() end)

    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:RegisterEvent("PLAYER_QUITING")
    logoutFrame:SetScript("OnEvent", function() deps.onLogout() end)

    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
        f.isSizing = true
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        if f.isSizing then
            f:StopMovingOrSizing()
            f.isSizing = false
        end
    end)

    local tabBarFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    tabBarFrame:SetPoint("TOPLEFT", f, "TOPLEFT", deps.PAD, -54)
    tabBarFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -deps.PAD, -54)
    tabBarFrame:SetHeight(26)
    deps.setBD(tabBarFrame, 0.03, 0.05, 0.10, 0.92, 0.18, 0.33, 0.52)

    local addTabBtn = CreateFrame("Button", nil, tabBarFrame, "UIPanelButtonTemplate")
    addTabBtn:SetSize(26, 22)
    addTabBtn:SetText("+")
    addTabBtn:SetScript("OnClick", function() deps.onAddTab() end)
    tabBarFrame._addBtn = addTabBtn

    local leftHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftHdr:SetPoint("TOPLEFT", f, "TOPLEFT", deps.PAD + 2, -80)
    leftHdr:SetText("Priority List")
    leftHdr:SetTextColor(0.50, 0.72, 0.90, 1)

    local leftSF = CreateFrame("ScrollFrame", nil, f)
    leftSF:SetPoint("TOPLEFT", f, "TOPLEFT", deps.PAD, -96)
    leftSF:SetSize(deps.LEFT_W, deps.GUI_H - 168)
    leftSF:EnableMouseWheel(true)
    leftSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * deps.ROW_H, 0), m))
    end)
    f._leftSF = leftSF

    local lc = CreateFrame("Frame", nil, leftSF)
    lc:SetSize(deps.LEFT_W, 100)
    leftSF:SetScrollChild(lc)

    local addSpellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addSpellBtn:SetSize(deps.LEFT_W, 26)
    addSpellBtn:SetPoint("TOPLEFT", leftSF, "BOTTOMLEFT", 0, -4)
    addSpellBtn:SetText("+ Add Spell")
    addSpellBtn:SetScript("OnClick", function() deps.onAddSpell(addSpellBtn) end)

    local rp = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rp:SetPoint("TOPRIGHT", f, "TOPRIGHT", -deps.PAD, -96)
    rp:SetSize(deps.RIGHT_W, deps.GUI_H - 142)
    deps.setBD(rp, 0.04, 0.07, 0.13, 0.90, 0.18, 0.33, 0.53)

    local rpHdr = rp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rpHdr:SetPoint("TOPLEFT", rp, "TOPLEFT", 8, -8)
    rpHdr:SetSize(deps.RIGHT_W - 16, 18)
    rpHdr:SetJustifyH("LEFT")
    rpHdr:SetText("Conditions")
    rpHdr:SetTextColor(0.50, 0.72, 0.90, 1)
    rp.header = rpHdr

    local addCondBtn = CreateFrame("Button", nil, rp, "UIPanelButtonTemplate")
    addCondBtn:SetSize(deps.RIGHT_W - 12, 24)
    addCondBtn:SetText("+ Add Condition")
    addCondBtn:SetScript("OnClick", function() deps.onAddCondition() end)
    addCondBtn:Hide()
    rp.addCondBtn = addCondBtn

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(128, 28)
    saveBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", deps.PAD, deps.PAD + 4)
    saveBtn:SetText("Save & Apply")
    saveBtn:SetScript("OnClick", function() deps.onSave(f) end)

    local previewBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    previewBtn:SetSize(106, 28)
    previewBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    previewBtn:SetText("Preview Code")
    previewBtn:SetScript("OnClick", function() deps.onPreview() end)

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(82, 28)
    exportBtn:SetPoint("LEFT", previewBtn, "RIGHT", 6, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function() deps.onExport(exportBtn) end)

    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(82, 28)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function() deps.onImport(importBtn) end)

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(104, 28)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 6, 0)
    clearBtn:SetText("Clear All Rules")
    clearBtn:SetScript("OnClick", function() deps.onClear() end)

    local function LayoutGUI()
        local leftW, rightW = deps.getPanelWidths(f:GetWidth())
        leftSF:SetSize(leftW, f:GetHeight() - 168)
        lc:SetWidth(leftW)
        addSpellBtn:SetWidth(leftW)
        rp:SetSize(rightW, f:GetHeight() - 142)
        rpHdr:SetWidth(rightW - 16)
        addCondBtn:SetWidth(rightW - 12)
        deps.onLayout()
    end

    f:SetScript("OnSizeChanged", function() LayoutGUI() end)
    LayoutGUI()

    deps.createSpellbookPanel(f, leftSF)
    deps.createBagPanel(f, leftSF)

    return {
        frame = f,
        leftChild = lc,
        rightPanel = rp,
        tabBar = tabBarFrame,
    }
end
