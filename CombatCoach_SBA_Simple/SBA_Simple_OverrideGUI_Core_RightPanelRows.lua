-- SBA_Simple_OverrideGUI_Core_RightPanelRows.lua
-- Condition row rendering for the override right panel.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.RenderConditionRows(rule, deps)
    local groupBoxColors = deps.groupBoxColors
    if type(groupBoxColors) ~= "table" or #groupBoxColors == 0 then
        groupBoxColors = {
            { 0.10, 0.16, 0.28, 0.18, 0.35, 0.55, 0.95 },
        }
    end

    for _, row in ipairs(deps.condRowPool) do row:Hide() end
    for _, jf in ipairs(deps.condJunctionPool) do jf:Hide() end
    for _, box in ipairs(deps.condGroupBoxPool) do box:Hide() end
    for k in pairs(deps.condRowYList) do deps.condRowYList[k] = nil end

    local conds = rule.conditions or {}
    local spans, unmatchedOpens, unmatchedCloses = deps.analyzeParenGroups(conds)
    local lpDepths, rpDepths = deps.getCondParenDepths(conds)
    local yBase = -28
    local rowIdx = 0
    local rowYTops = {}

    for i, cond in ipairs(conds) do
        if i > 1 then
            local jIdx = i - 1
            if not deps.condJunctionPool[jIdx] then
                local jf = CreateFrame("Button", nil, deps.rightPanel)
                jf:SetSize(44, 14)
                jf:SetFrameLevel(deps.rightPanel:GetFrameLevel() + 20)
                local jbg = jf:CreateTexture(nil, "BACKGROUND")
                jbg:SetAllPoints()
                jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
                jf._bg = jbg
                local jLbl = jf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                jLbl:SetAllPoints()
                jLbl:SetJustifyH("CENTER")
                jf._lbl = jLbl
                jf:SetScript("OnEnter", function() jbg:SetColorTexture(0.18, 0.28, 0.48, 0.9) end)
                jf:SetScript("OnLeave", function() jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)
                deps.condJunctionPool[jIdx] = jf
            end
            local jf = deps.condJunctionPool[jIdx]
            local capturedCond = cond
            jf:ClearAllPoints()
            jf:SetPoint("TOP", deps.rightPanel, "TOP", 0, yBase)
            local function RefreshJunction()
                local j = capturedCond.junction or "and"
                jf._lbl:SetText(j:upper())
                jf._lbl:SetTextColor(j == "or" and 1.0 or 0.55, j == "or" and 0.72 or 0.80, j == "or" and 0.28 or 1.0, 1)
            end
            RefreshJunction()
            jf:SetScript("OnClick", function()
                local j = capturedCond.junction or "and"
                capturedCond.junction = (j == "and") and "or" or "and"
                RefreshJunction()
                deps.refreshRuleList()
            end)
            jf:Show()
            yBase = yBase - 16
        end

        rowIdx = rowIdx + 1
        if not deps.condRowPool[rowIdx] then
            local row = CreateFrame("Frame", nil, deps.rightPanel, "BackdropTemplate")
            row:SetSize(deps.RIGHT_W - 12, 22)
            row:SetFrameLevel(deps.rightPanel:GetFrameLevel() + 20)
            deps.setBD(row, 0.07, 0.11, 0.18, 0.85, 0.12, 0.22, 0.36)

            local lpBtn = CreateFrame("Button", nil, row)
            lpBtn:SetSize(20, 20)
            lpBtn:SetPoint("LEFT", row, "LEFT", 2, 0)
            local lpBg = lpBtn:CreateTexture(nil, "BACKGROUND")
            lpBg:SetAllPoints()
            lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            lpBtn._bg = lpBg
            local lpLbl = lpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lpLbl:SetAllPoints()
            lpLbl:SetJustifyH("CENTER")
            row._lpBtn = lpBtn
            row._lpLbl = lpLbl
            lpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            lpBtn:SetScript("OnEnter", function() lpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            lpBtn:SetScript("OnLeave", function() lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            local rpBtn = CreateFrame("Button", nil, row)
            rpBtn:SetSize(20, 20)
            rpBtn:SetPoint("RIGHT", row, "RIGHT", -22, 0)
            local rpBg = rpBtn:CreateTexture(nil, "BACKGROUND")
            rpBg:SetAllPoints()
            rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            rpBtn._bg = rpBg
            local rpLbl = rpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rpLbl:SetAllPoints()
            rpLbl:SetJustifyH("CENTER")
            row._rpBtn = rpBtn
            row._rpLbl = rpLbl
            rpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            rpBtn:SetScript("OnEnter", function() rpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            rpBtn:SetScript("OnLeave", function() rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT", row, "LEFT", 24, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT", -44, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetTextColor(0.78, 0.90, 1, 1)
            row._lbl = lbl

            local xb = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            xb:SetSize(18, 18)
            xb:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row._xb = xb

            deps.condRowPool[rowIdx] = row
        end

        local row = deps.condRowPool[rowIdx]
        row:ClearAllPoints()
        row:SetSize(deps.getRightPanelWidth() - 12, 22)
        row:SetPoint("TOPLEFT", deps.rightPanel, "TOPLEFT", 6, yBase)
        rowYTops[i] = yBase
        deps.condRowYList[i] = yBase
        row._lbl:SetText(deps.condSummaryText(cond, rule.spellID))
        row._lbl:SetTextColor(cond.negate and 1 or 0.78, cond.negate and 0.38 or 0.90, cond.negate and 0.38 or 1, 1)

        local capturedI = i
        local capturedCond = cond
        local capturedLpD = lpDepths[i] or {}
        local capturedRpD = rpDepths[i] or {}

        local function UpdateLPBtn()
            local n = capturedCond.lparen or 0
            local hasError = (unmatchedOpens[capturedI] or 0) > 0
            if n == 0 then
                row._lpLbl:SetText("(")
                row._lpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                local parts = {}
                for k = 1, n do
                    local d = capturedLpD[k] or k
                    local c = groupBoxColors[((d - 1) % #groupBoxColors) + 1]
                    parts[k] = ("|cff%02x%02x%02x(|r"):format(c[5] * 255, c[6] * 255, c[7] * 255)
                end
                row._lpLbl:SetText(table.concat(parts))
                if hasError then row._lpLbl:SetTextColor(1.0, 0.30, 0.30, 1) end
            end
            row._lpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end

        local function UpdateRPBtn()
            local n = capturedCond.rparen or 0
            local hasError = (unmatchedCloses[capturedI] or 0) > 0
            if n == 0 then
                row._rpLbl:SetText(")")
                row._rpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                local parts = {}
                for k = 1, n do
                    local d = capturedRpD[k] or (n - k + 1)
                    local c = groupBoxColors[((d - 1) % #groupBoxColors) + 1]
                    parts[k] = ("|cff%02x%02x%02x)|r"):format(c[5] * 255, c[6] * 255, c[7] * 255)
                end
                row._rpLbl:SetText(table.concat(parts))
                if hasError then row._rpLbl:SetTextColor(1.0, 0.30, 0.30, 1) end
            end
            row._rpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end

        UpdateLPBtn()
        UpdateRPBtn()

        row._lpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.lparen = math.max(0, (capturedCond.lparen or 0) - 1)
            else
                capturedCond.lparen = ((capturedCond.lparen or 0) + 1) % 4
            end
            deps.refreshRightPanel()
            deps.refreshRuleList()
        end)

        row._rpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.rparen = math.max(0, (capturedCond.rparen or 0) - 1)
            else
                capturedCond.rparen = ((capturedCond.rparen or 0) + 1) % 4
            end
            deps.refreshRightPanel()
            deps.refreshRuleList()
        end)

        row._xb:SetScript("OnClick", function()
            local sidx = deps.getSelectedIdx()
            if deps.workingRules[sidx] then
                table.remove(deps.workingRules[sidx].conditions, capturedI)
                deps.setSelectedCondIdx(nil)
                deps.refreshRightPanel()
                deps.refreshRuleList()
            end
        end)

        row:EnableMouse(true)
        row:SetScript("OnMouseDown", function(_, btn)
            if btn == "LeftButton" then
                deps.ensureCondCatcher()
                local cx, cy = GetCursorPosition()
                local sc = UIParent:GetEffectiveScale()
                deps.condDrag.pending = true
                deps.condDrag.active = false
                deps.condDrag.fromIdx = capturedI
                deps.condDrag.toSlot = nil
                deps.condDrag.pendingX = cx / sc
                deps.condDrag.pendingY = cy / sc
            end
        end)

        row:SetScript("OnMouseUp", function(_, btn)
            if btn ~= "LeftButton" then return end
            if deps.condDropLine then deps.condDropLine:Hide() end
            if deps.condDrag.pending then
                deps.condDrag.pending = false
                deps.condDrag.fromIdx = nil
                deps.setSelectedCondIdx(capturedI)
                deps.setIsAddingCond(true)
                deps.refreshRightPanel()
            elseif deps.condDrag.active then
                deps.condDrag.active = false
                local fromIdx = deps.condDrag.fromIdx
                local toSlot = deps.condDrag.toSlot
                deps.condDrag.fromIdx = nil
                deps.condDrag.toSlot = nil
                local sidx = deps.getSelectedIdx()
                local curRule = sidx > 0 and deps.workingRules[sidx]
                if curRule and fromIdx and toSlot and fromIdx ~= toSlot and fromIdx ~= toSlot - 1 then
                    local condsList = curRule.conditions
                    local moved = table.remove(condsList, fromIdx)
                    moved.lparen = 0
                    moved.rparen = 0
                    local insertAt = (toSlot > fromIdx) and (toSlot - 1) or toSlot
                    table.insert(condsList, insertAt, moved)
                    deps.setSelectedCondIdx(nil)
                    deps.setIsAddingCond(false)
                    deps.refreshRightPanel()
                    deps.refreshRuleList()
                end
            end
        end)

        row:SetScript("OnEnter", function() row:SetBackdropColor(0.14, 0.22, 0.35, 0.95) end)
        row:SetScript("OnLeave", function() row:SetBackdropColor(0.07, 0.11, 0.18, 0.85) end)
        row:Show()
        yBase = yBase - 26
    end

    deps.drawConditionGroupBoxes(spans, rowYTops)
    return yBase
end
