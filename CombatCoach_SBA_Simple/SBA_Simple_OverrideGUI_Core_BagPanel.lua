-- SBA_Simple_OverrideGUI_Core_BagPanel.lua
-- Bag-items slide-out panel UI for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateBagPanel(f, deps)
    deps.ensureDragIcon()
    deps.ensureDragCatcher()

    local PANEL_W = 264
    local TAB_W, TAB_H = 54, 56

    local panel = CreateFrame("Frame", "SBAS_BagPanel", f, "BackdropTemplate")
    panel:SetSize(PANEL_W, f:GetHeight())
    panel:SetPoint("TOPRIGHT", f, "TOPLEFT", -1, 0)
    panel:SetFrameLevel(f:GetFrameLevel() + 1)
    panel:Hide()
    deps.setBD(panel, 0.04, 0.08, 0.06, 0.97, 0.20, 0.52, 0.34)

    local tabBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    tabBtn:SetSize(TAB_W, TAB_H)
    tabBtn:SetFrameLevel(panel:GetFrameLevel() + 2)
    tabBtn:SetPoint("TOPRIGHT", panel, "TOPLEFT", 0, -14)
    deps.setBD(tabBtn, 0.05, 0.10, 0.07, 0.95, 0.20, 0.52, 0.34)

    local tabIcon = tabBtn:CreateTexture(nil, "ARTWORK")
    tabIcon:SetSize(28, 28)
    tabIcon:SetPoint("TOP", tabBtn, "TOP", 0, -5)
    tabIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_07")
    tabIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local tabLbl = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLbl:SetPoint("BOTTOM", tabBtn, "BOTTOM", 0, 6)
    tabLbl:SetJustifyH("CENTER")
    tabLbl:SetText("Items")
    tabLbl:SetTextColor(0.55, 1, 0.70, 1)

    tabBtn:SetScript("OnEnter", function()
        tabIcon:SetVertexColor(0.4, 1, 0.6, 1)
        tabLbl:SetTextColor(0.4, 1, 0.6, 1)
        GameTooltip:SetOwner(tabBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("Bag Items")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 1, 0.8, true)
        GameTooltip:Show()
    end)
    tabBtn:SetScript("OnLeave", function()
        tabIcon:SetVertexColor(1, 1, 1, 1)
        tabLbl:SetTextColor(0.55, 1, 0.70, 1)
        GameTooltip:Hide()
    end)

    local stubBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    stubBtn:SetSize(TAB_W, TAB_H)
    stubBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -(14 + TAB_H + 4))
    deps.setBD(stubBtn, 0.05, 0.10, 0.07, 0.95, 0.20, 0.52, 0.34)

    local stubIcon = stubBtn:CreateTexture(nil, "ARTWORK")
    stubIcon:SetSize(28, 28)
    stubIcon:SetPoint("TOP", stubBtn, "TOP", 0, -5)
    stubIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_07")
    stubIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local stubLbl = stubBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stubLbl:SetPoint("BOTTOM", stubBtn, "BOTTOM", 0, 6)
    stubLbl:SetJustifyH("CENTER")
    stubLbl:SetText("Items")
    stubLbl:SetTextColor(0.55, 1, 0.70, 1)

    stubBtn:SetScript("OnEnter", function()
        stubIcon:SetVertexColor(0.4, 1, 0.6, 1)
        stubLbl:SetTextColor(0.4, 1, 0.6, 1)
        GameTooltip:SetOwner(stubBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Bag Items")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 1, 0.8, true)
        GameTooltip:Show()
    end)
    stubBtn:SetScript("OnLeave", function()
        stubIcon:SetVertexColor(1, 1, 1, 1)
        stubLbl:SetTextColor(0.55, 1, 0.70, 1)
        GameTooltip:Hide()
    end)

    local phdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -12)
    phdr:SetText("Bag Items")
    phdr:SetTextColor(0.38, 1, 0.60, 1)

    local hintLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -34)
    hintLbl:SetSize(PANEL_W - 16, 24)
    hintLbl:SetJustifyH("LEFT")
    hintLbl:SetText("Click to add  ·  Drag to insert at position")
    hintLbl:SetTextColor(0.40, 0.72, 0.52, 1)

    local panelSF = CreateFrame("ScrollFrame", nil, panel)
    panelSF:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -64)
    panelSF:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    panelSF:EnableMouseWheel(true)
    panelSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 28, 0), m))
    end)

    local panelContent = CreateFrame("Frame", nil, panelSF)
    panelContent:SetSize(PANEL_W - 8, 100)
    panelSF:SetScrollChild(panelContent)

    local itemRowPool, currentItems = {}, {}
    local ITEM_ROW_H = 30

    local function CreateItemEntry(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(PANEL_W - 8, ITEM_ROW_H - 2)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:RegisterForClicks("LeftButtonUp")

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        row._bg = bg

        local iconBg = row:CreateTexture(nil, "BACKGROUND")
        iconBg:SetSize(24, 24)
        iconBg:SetPoint("LEFT", row, "LEFT", 4, 0)
        iconBg:SetColorTexture(0, 0, 0, 0.45)

        local iconTex = row:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(22, 22)
        iconTex:SetPoint("CENTER", iconBg, "CENTER")
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = iconTex

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameLbl:SetPoint("LEFT", iconBg, "RIGHT", 6, 0)
        nameLbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetTextColor(0.75, 1, 0.82, 1)
        row._nameLbl = nameLbl

        row:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.10, 0.30, 0.18, 0.70)
            if self._itemID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(self._itemID)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(self)
            if not self._spellID then return end
            local wr = deps.getWorkingRules()
            wr[#wr + 1] = {
                spellID = self._spellID,
                name = self._itemName,
                conditions = {},
                itemID = self._itemID,
            }
            deps.setSelectedIdx(#wr)
            deps.setIsAddingCond(false)
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end)

        row:SetScript("OnDragStart", function(self)
            if not self._spellID then return end
            deps.sbasDrag.active = true
            deps.sbasDrag.spellID = self._spellID
            deps.sbasDrag.spellName = self._itemName
            deps.sbasDrag.itemID = self._itemID
            deps.getDragIconFrame()._tex:SetTexture(self._icon:GetTexture())
            deps.getDragIconFrame():Show()
            deps.getDragCatcher():Show()
        end)

        return row
    end

    local function PopulateBagPanel()
        local shown = 0
        for _, item in ipairs(currentItems) do
            shown = shown + 1
            if not itemRowPool[shown] then
                itemRowPool[shown] = CreateItemEntry(panelContent)
            end
            local row = itemRowPool[shown]
            row._spellID = item.spellID
            row._itemID = item.itemID
            row._itemName = item.name
            row._icon:SetTexture(item.texture)
            row._nameLbl:SetText(item.name)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", panelContent, "TOPLEFT", 0, -(shown - 1) * ITEM_ROW_H)
            row:Show()
        end
        for i = shown + 1, #itemRowPool do if itemRowPool[i] then itemRowPool[i]:Hide() end end
        panelContent:SetHeight(math.max(shown * ITEM_ROW_H + 4, 100))
    end

    local function RefreshBagPanel()
        currentItems = deps.getBagItems()
        PopulateBagPanel()
    end
    f._refreshBagPanel = RefreshBagPanel

    local function CloseBagPanel()
        panel:Hide()
        stubBtn:Show()
        if f._spellFlyout then
            f._spellFlyout.stubBtn:ClearAllPoints()
            f._spellFlyout.stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -14)
        end
    end

    local function OpenBagPanel()
        if f._spellFlyout and f._spellFlyout.panel:IsShown() then
            f._spellFlyout.ClosePanel()
        end
        RefreshBagPanel()
        stubBtn:Hide()
        panel:Show()
        if f._spellFlyout then
            f._spellFlyout.stubBtn:ClearAllPoints()
            f._spellFlyout.stubBtn:SetPoint("TOP", tabBtn, "BOTTOM", 0, -4)
        end
    end

    tabBtn:SetScript("OnClick", function() CloseBagPanel() end)
    stubBtn:SetScript("OnClick", function() OpenBagPanel() end)
    stubBtn:Show()
    f._bagFlyout = { panel = panel, tabBtn = tabBtn, stubBtn = stubBtn, ClosePanel = CloseBagPanel }

    f:HookScript("OnSizeChanged", function(self) panel:SetHeight(self:GetHeight()) end)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshBagPanel()
        else
            currentItems = nil
        end
    end)

    panel:HookScript("OnShow", function()
        if currentItems == nil then
            RefreshBagPanel()
        end
    end)
end
