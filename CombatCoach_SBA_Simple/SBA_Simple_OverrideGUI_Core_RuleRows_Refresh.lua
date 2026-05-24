-- SBA_Simple_OverrideGUI_Core_RuleRows_Refresh.lua
-- Refresh logic for rule rows.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.RefreshRuleList(deps)
    local workingRules = deps.getWorkingRules()
    local count = #workingRules
    deps.leftChild:SetWidth(deps.getLeftPanelWidth())
    local yOff = -deps.PAD

    local firstUnconditionalIdx = math.huge
    for i = 1, count do
        if #(workingRules[i].conditions or {}) == 0 then
            firstUnconditionalIdx = i
            break
        end
    end

    for i = 1, count do
        if not deps.rowFrames[i] then
            deps.rowFrames[i] = M.CreateRowFrame(deps.leftChild, deps)
        end
        M.UpdateRowFrame(deps.rowFrames[i], i, workingRules[i], deps)
        local rf = deps.rowFrames[i]
        rf:SetAlpha(i > firstUnconditionalIdx and 0.40 or 1.0)
        rf:ClearAllPoints()
        rf:SetPoint("TOPLEFT", deps.leftChild, "TOPLEFT", deps.PAD, yOff)
        yOff = yOff - (rf._rowH or deps.ROW_H)
    end

    for i = count + 1, #deps.rowFrames do
        if deps.rowFrames[i] then deps.rowFrames[i]:Hide() end
    end

    deps.leftChild:SetHeight(math.max(-yOff + deps.PAD, 100))
end
