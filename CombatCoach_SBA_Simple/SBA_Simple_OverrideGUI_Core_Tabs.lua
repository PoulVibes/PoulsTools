-- SBA_Simple_OverrideGUI_Core_Tabs.lua
-- Tab switching and tab bar management for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.SwitchTabState(state, deps, newTabIdx)
    if newTabIdx == state.activeTabIdx then return end
    state.allTabRules[state.activeTabIdx] = state.workingRules
    state.activeTabIdx = newTabIdx
    state.workingRules = state.allTabRules[state.activeTabIdx] or {}
    state.allTabRules[state.activeTabIdx] = state.workingRules

    if state.editSpecID and state.editSpecID ~= 0 then
        state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
        state.sessionAllTabs[state.editSpecID][state.activeTabIdx] = state.workingRules
    end

    state.selectedIdx = (#state.workingRules > 0) and 1 or 0
    state.isAddingCond = false
    state.selectedCondIdx = nil

    deps.refreshTabBar()
    deps.refreshRuleList()
    deps.refreshRightPanel()
end

function M.RefreshTabBarState(state, deps)
    local tabBar = deps.getTabBar()
    if not tabBar then return end

    local tabBarBtns = deps.getTabBarButtons()
    local BTN_SIZE, BTN_H, BTN_GAP = 16, 22, 1
    local TAB_LPAD, TAB_RPAD = 5, 2
    local GAP, xOff = 4, 0

    for t = 1, state.tabCount do
        if not tabBarBtns[t] then
            local btn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
            deps.setBD(btn, 0.05, 0.08, 0.14, 0.92, 0.20, 0.38, 0.58)
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn._lbl = lbl

            local xb = CreateFrame("Button", nil, btn, "UIPanelCloseButton")
            xb:SetSize(BTN_SIZE, BTN_SIZE)
            btn._delBtn = xb

            local rb = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            rb:SetSize(BTN_SIZE, BTN_SIZE)
            rb:SetText("R")
            rb:GetFontString():SetFont(GameFontNormalSmall:GetFont(), 9, "OUTLINE")
            rb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText("Rename tab", 1, 1, 1)
                GameTooltip:Show()
            end)
            rb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            btn._renameBtn = rb

            tabBarBtns[t] = btn
        end

        local btn = tabBarBtns[t]
        local captT = t
        local name = deps.getTabName(state.editSpecID, t)
        btn._lbl:SetText(name)
        local textW = btn._lbl:GetStringWidth()

        local tabW
        if t == 1 then
            tabW = math.max(60, math.ceil(textW) + TAB_LPAD * 2)
        else
            tabW = math.max(80, math.ceil(textW) + TAB_LPAD + 4 + BTN_SIZE + BTN_GAP + BTN_SIZE + TAB_RPAD)
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 2)
        btn:SetSize(tabW, BTN_H)

        if t == state.activeTabIdx then
            btn:SetBackdropColor(0.12, 0.24, 0.42, 0.97)
            btn:SetBackdropBorderColor(0.38, 0.68, 1, 1)
            btn._lbl:SetTextColor(1, 1, 1, 1)
        else
            btn:SetBackdropColor(0.05, 0.08, 0.14, 0.92)
            btn:SetBackdropBorderColor(0.20, 0.38, 0.58, 1)
            btn._lbl:SetTextColor(0.70, 0.80, 0.90, 1)
        end

        btn:SetScript("OnClick", function() deps.switchTab(captT) end)
        btn:SetScript("OnEnter", function(self)
            if captT ~= state.activeTabIdx then self:SetBackdropColor(0.09, 0.16, 0.30, 0.95) end
        end)
        btn:SetScript("OnLeave", function(self)
            if captT ~= state.activeTabIdx then self:SetBackdropColor(0.05, 0.08, 0.14, 0.92) end
        end)

        if t == 1 then
            btn._delBtn:Hide()
            btn._renameBtn:Hide()
            btn._lbl:ClearAllPoints()
            btn._lbl:SetJustifyH("CENTER")
            btn._lbl:SetPoint("CENTER", btn, "CENTER")
        else
            btn._delBtn:ClearAllPoints()
            btn._delBtn:SetPoint("RIGHT", btn, "RIGHT", TAB_RPAD, 0)
            btn._renameBtn:ClearAllPoints()
            btn._renameBtn:SetPoint("RIGHT", btn._delBtn, "LEFT", -BTN_GAP, 0)
            btn._delBtn:Show()
            btn._renameBtn:Show()

            btn._lbl:ClearAllPoints()
            btn._lbl:SetJustifyH("LEFT")
            btn._lbl:SetPoint("LEFT", btn, "LEFT", TAB_LPAD, 0)

            local captRename = t
            btn._renameBtn:SetScript("OnClick", function()
                if tabBar._renameBox and tabBar._renameBox:IsShown() then tabBar._renameBox:Hide() end
                if not tabBar._renameBox then
                    local eb = CreateFrame("EditBox", nil, tabBar, "BackdropTemplate")
                    eb:SetSize(100, 22)
                    eb:SetFontObject("GameFontHighlightSmall")
                    eb:SetAutoFocus(true)
                    eb:SetMaxLetters(24)
                    eb:SetTextInsets(4, 4, 2, 2)
                    deps.setBD(eb, 0.05, 0.08, 0.14, 0.97, 0.45, 0.70, 1)
                    eb:SetScript("OnEscapePressed", function(self) self:Hide() end)
                    eb:SetScript("OnEnterPressed", function(self)
                        local newName = self:GetText():match("^%s*(.-)%s*$")
                        if newName ~= "" then
                            deps.setTabName(state.editSpecID, self._tabIdx, newName)
                            state.tabNames[self._tabIdx] = newName
                            if type(_G.SBA_Simple_SetTabName) == "function" then
                                _G.SBA_Simple_SetTabName(self._tabIdx, newName)
                            end
                        end
                        self:Hide()
                        deps.refreshTabBar()
                    end)
                    tabBar._renameBox = eb
                end
                local eb = tabBar._renameBox
                eb._tabIdx = captRename
                eb:ClearAllPoints()
                eb:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
                eb:SetText(deps.getTabName(state.editSpecID, captRename))
                eb:SetCursorPosition(#eb:GetText())
                eb:HighlightText()
                eb:Show()
                eb:SetFocus()
            end)

            local captDel = t
            btn._delBtn:SetScript("OnClick", function() deps.deleteTab(captDel) end)
        end

        btn:Show()
        xOff = xOff + tabW + GAP
    end

    for t = state.tabCount + 1, #tabBarBtns do
        if tabBarBtns[t] then tabBarBtns[t]:Hide() end
    end

    if tabBar._addBtn then
        if state.tabCount >= deps.maxTabs then
            tabBar._addBtn:Hide()
        else
            tabBar._addBtn:ClearAllPoints()
            tabBar._addBtn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 2)
            tabBar._addBtn:Show()
        end
    end
end

function M.AddNewTabState(state, deps)
    if state.tabCount >= deps.maxTabs then return end

    state.allTabRules[state.activeTabIdx] = state.workingRules
    state.tabCount = state.tabCount + 1
    deps.setTabCount(state.editSpecID, state.tabCount)
    state.tabNames[state.tabCount] = "Tab " .. state.tabCount
    deps.setTabName(state.editSpecID, state.tabCount, state.tabNames[state.tabCount])

    if type(_G.SBA_Simple_SetTabName) == "function" then
        _G.SBA_Simple_SetTabName(state.tabCount, state.tabNames[state.tabCount])
    end

    state.allTabRules[state.tabCount] = {}
    state.sessionAllTabs[state.editSpecID] = state.sessionAllTabs[state.editSpecID] or {}
    state.sessionAllTabs[state.editSpecID][state.tabCount] = state.allTabRules[state.tabCount]

    if type(_G.SBA_Simple_UpdateTabCount) == "function" then
        _G.SBA_Simple_UpdateTabCount(state.editSpecID, state.tabCount)
    end

    state.activeTabIdx = state.tabCount
    state.workingRules = state.allTabRules[state.activeTabIdx]
    state.selectedIdx = 0
    state.isAddingCond = false
    state.selectedCondIdx = nil

    deps.refreshTabBar()
    deps.refreshRuleList()
    deps.refreshRightPanel()
end

function M.DeleteTabState(state, deps, tabIdx)
    if tabIdx <= 1 or tabIdx > state.tabCount then return end

    state.allTabRules[state.activeTabIdx] = state.workingRules
    table.remove(state.allTabRules, tabIdx)

    if state.sessionAllTabs[state.editSpecID] then
        table.remove(state.sessionAllTabs[state.editSpecID], tabIdx)
    end

    if SBA_SimpleDB.guiTabs and SBA_SimpleDB.guiTabs[state.editSpecID] then
        local gt = SBA_SimpleDB.guiTabs[state.editSpecID]
        for t = tabIdx, state.tabCount - 1 do gt[t] = gt[t + 1] end
        gt[state.tabCount] = nil
    end

    if SBA_SimpleDB.extraIcons then
        for t = tabIdx, state.tabCount - 1 do
            SBA_SimpleDB.extraIcons["tab" .. t] = SBA_SimpleDB.extraIcons["tab" .. (t + 1)]
        end
        SBA_SimpleDB.extraIcons["tab" .. state.tabCount] = nil
    end

    if SBA_SimpleDB.tabNames and SBA_SimpleDB.tabNames[state.editSpecID] then
        local tn = SBA_SimpleDB.tabNames[state.editSpecID]
        for t = tabIdx, state.tabCount - 1 do tn[t] = tn[t + 1] end
        tn[state.tabCount] = nil
    end
    for t = tabIdx, state.tabCount - 1 do state.tabNames[t] = state.tabNames[t + 1] end
    state.tabNames[state.tabCount] = nil

    if SBA_SimpleDB.specs and SBA_SimpleDB.specs[state.editSpecID] then
        local sp = SBA_SimpleDB.specs[state.editSpecID]
        for t = tabIdx, state.tabCount - 1 do
            sp["overrideCode_" .. t] = sp["overrideCode_" .. (t + 1)]
        end
        sp["overrideCode_" .. state.tabCount] = nil
    end

    state.tabCount = state.tabCount - 1
    deps.setTabCount(state.editSpecID, state.tabCount)
    if state.activeTabIdx > state.tabCount then state.activeTabIdx = state.tabCount end

    state.workingRules = state.allTabRules[state.activeTabIdx] or {}
    state.allTabRules[state.activeTabIdx] = state.workingRules
    state.selectedIdx = (#state.workingRules > 0) and 1 or 0
    state.isAddingCond = false
    state.selectedCondIdx = nil

    if type(_G.SBA_Simple_UpdateTabCount) == "function" then
        _G.SBA_Simple_UpdateTabCount(state.editSpecID, state.tabCount)
    end

    deps.refreshTabBar()
    deps.refreshRuleList()
    deps.refreshRightPanel()
end
