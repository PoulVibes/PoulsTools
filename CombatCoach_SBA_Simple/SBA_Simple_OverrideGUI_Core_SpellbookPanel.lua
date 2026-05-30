-- SBA_Simple_OverrideGUI_Core_SpellbookPanel.lua
-- Spellbook slide-out panel UI for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateSpellbookPanel(f, leftSF, deps)
    deps.ensureDragIcon()
    deps.ensureDragCatcher()
    f._leftSF = leftSF

    local PANEL_W = 264
    local panel = CreateFrame("Frame", "SBAS_SpellbookPanel", f, "BackdropTemplate")
    panel:SetSize(PANEL_W, f:GetHeight())
    panel:SetPoint("TOPRIGHT", f, "TOPLEFT", -1, 0)
    panel:SetFrameLevel(f:GetFrameLevel() + 1)
    panel:Hide()
    deps.setBD(panel, 0.04, 0.06, 0.12, 0.97, 0.24, 0.44, 0.64)

    local TAB_W, TAB_H = 54, 56
    local tabBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    tabBtn:SetSize(TAB_W, TAB_H)
    tabBtn:SetFrameLevel(panel:GetFrameLevel() + 2)
    tabBtn:SetPoint("TOPRIGHT", panel, "TOPLEFT", 0, -14)
    deps.setBD(tabBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    local tabIcon = tabBtn:CreateTexture(nil, "ARTWORK")
    tabIcon:SetSize(28, 28)
    tabIcon:SetPoint("TOP", tabBtn, "TOP", 0, -5)
    tabIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    tabIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local tabLbl = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLbl:SetPoint("BOTTOM", tabBtn, "BOTTOM", 0, 6)
    tabLbl:SetJustifyH("CENTER")
    tabLbl:SetText("Spells")
    tabLbl:SetTextColor(0.65, 0.85, 1, 1)

    tabBtn:SetScript("OnEnter", function()
        tabIcon:SetVertexColor(0.5, 0.85, 1, 1)
        tabLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(tabBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    tabBtn:SetScript("OnLeave", function()
        tabIcon:SetVertexColor(1, 1, 1, 1)
        tabLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    local stubBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    stubBtn:SetSize(TAB_W, TAB_H)
    stubBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -14)
    deps.setBD(stubBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    local stubIcon = stubBtn:CreateTexture(nil, "ARTWORK")
    stubIcon:SetSize(28, 28)
    stubIcon:SetPoint("TOP", stubBtn, "TOP", 0, -5)
    stubIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    stubIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local stubLbl = stubBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stubLbl:SetPoint("BOTTOM", stubBtn, "BOTTOM", 0, 6)
    stubLbl:SetJustifyH("CENTER")
    stubLbl:SetText("Spells")
    stubLbl:SetTextColor(0.65, 0.85, 1, 1)

    stubBtn:SetScript("OnEnter", function()
        stubIcon:SetVertexColor(0.5, 0.85, 1, 1)
        stubLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(stubBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    stubBtn:SetScript("OnLeave", function()
        stubIcon:SetVertexColor(1, 1, 1, 1)
        stubLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    local phdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -12)
    phdr:SetText("Spells")
    phdr:SetTextColor(0.38, 0.74, 1, 1)

    local resetBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    resetBtn:SetSize(52, 16)
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -10)
    deps.setBD(resetBtn, 0.28, 0.05, 0.05, 0.90, 0.65, 0.18, 0.18)
    local resetLbl = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetLbl:SetAllPoints()
    resetLbl:SetJustifyH("CENTER")
    resetLbl:SetText("Reset")
    resetLbl:SetTextColor(1, 0.55, 0.55, 1)
    resetBtn:SetScript("OnEnter", function(self)
        resetLbl:SetTextColor(1, 0.8, 0.8, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Reset Spell Cache", 1, 0.6, 0.6)
        GameTooltip:AddLine("Clears the cached spell list for this spec.\nReopening the GUI will rebuild it from your spellbook.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        resetLbl:SetTextColor(1, 0.55, 0.55, 1)
        GameTooltip:Hide()
    end)

    local searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetSize(PANEL_W - 16, 22)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(64)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local divLine = panel:CreateTexture(nil, "ARTWORK")
    divLine:SetSize(PANEL_W - 8, 1)
    divLine:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -4)
    divLine:SetColorTexture(0.25, 0.40, 0.60, 0.6)

    local hintLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintLbl:SetPoint("TOPLEFT", divLine, "BOTTOMLEFT", 4, -3)
    hintLbl:SetSize(PANEL_W - 16, 24)
    hintLbl:SetJustifyH("LEFT")
    hintLbl:SetText("Click to add  ·  Drag to insert at position")
    hintLbl:SetTextColor(0.48, 0.62, 0.72, 1)

    local panelSF = CreateFrame("ScrollFrame", nil, panel)
    panelSF:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -92)
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

    local spellRowPool, currentSpells = {}, {}
    local SPELL_ROW_H = 30

    local function CreateSpellEntry(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(PANEL_W - 8, SPELL_ROW_H - 2)
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
        nameLbl:SetTextColor(0.88, 0.92, 1, 1)
        row._nameLbl = nameLbl

        row:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.16, 0.28, 0.48, 0.70)
            if self._spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self._spellID)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(self)
            if not self._spellID then return end
            local addID, addName = deps.resolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            local wr = deps.getWorkingRules()
            wr[#wr + 1] = { spellID = addID, name = addName, conditions = {} }
            deps.setSelectedIdx(#wr)
            deps.setIsAddingCond(false)
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end)

        row:SetScript("OnDragStart", function(self)
            if not self._spellID then return end
            local addID, addName = deps.resolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            deps.sbasDrag.active = true
            deps.sbasDrag.spellID = addID
            deps.sbasDrag.spellName = addName
            deps.getDragIconFrame()._tex:SetTexture(self._icon:GetTexture())
            deps.getDragIconFrame():Show()
            deps.getDragCatcher():Show()
        end)

        return row
    end

    local function PopulatePanel(filterText)
        local filter = (filterText or ""):lower()
        local shown = 0
        for _, spell in ipairs(currentSpells) do
            if filter == "" or spell.name:lower():find(filter, 1, true) then
                shown = shown + 1
                if not spellRowPool[shown] then
                    spellRowPool[shown] = CreateSpellEntry(panelContent)
                end
                local row = spellRowPool[shown]
                row._spellID = spell.spellID
                row._spellName = spell.name
                row._icon:SetTexture(spell.texture)
                row._nameLbl:SetText(spell.name)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", panelContent, "TOPLEFT", 0, -(shown - 1) * SPELL_ROW_H)
                row:Show()
            end
        end
        for i = shown + 1, #spellRowPool do if spellRowPool[i] then spellRowPool[i]:Hide() end end
        panelContent:SetHeight(math.max(shown * SPELL_ROW_H + 4, 100))
    end

    local function RefreshSpellbookPanel()
        currentSpells = deps.getClassSpells()
        PopulatePanel(searchBox:GetText())
    end
    f._refreshSpellPanel = RefreshSpellbookPanel

    resetBtn:SetScript("OnClick", function()
        deps.resetSeenCastsForCurrentSpec()
        RefreshSpellbookPanel()
    end)

    searchBox:SetScript("OnTextChanged", function(self) PopulatePanel(self:GetText()) end)

    local function ClosePanel()
        panel:Hide()
        stubBtn:Show()
        if f._bagFlyout then
            f._bagFlyout.stubBtn:ClearAllPoints()
            f._bagFlyout.stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -(14 + TAB_H + 4))
        end
    end

    local function OpenPanel()
        if f._bagFlyout and f._bagFlyout.panel:IsShown() then
            f._bagFlyout.ClosePanel()
        end
        RefreshSpellbookPanel()
        stubBtn:Hide()
        panel:Show()
        if f._bagFlyout then
            f._bagFlyout.stubBtn:ClearAllPoints()
            f._bagFlyout.stubBtn:SetPoint("TOP", tabBtn, "BOTTOM", 0, -4)
        end
    end

    tabBtn:SetScript("OnClick", function() ClosePanel() end)
    stubBtn:SetScript("OnClick", function() OpenPanel() end)
    stubBtn:Show()
    f._spellFlyout = { panel = panel, tabBtn = tabBtn, stubBtn = stubBtn, ClosePanel = ClosePanel }

    f:HookScript("OnSizeChanged", function(self) panel:SetHeight(self:GetHeight()) end)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshSpellbookPanel()
        else
            currentSpells = nil
        end
    end)

    panel:HookScript("OnShow", function()
        if currentSpells == nil then
            RefreshSpellbookPanel()
        end
    end)
end
