-- SBA_Simple_OverrideGUI_Core_Parens.lua
-- Shared parenthesis/group visualization helpers for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.GROUP_BOX_COLORS = {
    { 0.78, 0.66, 0.14, 0.08, 0.92, 0.76, 0.18, 0.95 },
    { 0.18, 0.42, 0.72, 0.08, 0.28, 0.58, 0.90, 0.95 },
    { 0.18, 0.58, 0.34, 0.08, 0.24, 0.82, 0.46, 0.95 },
}

function M.ParenColorCode(depth)
    local c = M.GROUP_BOX_COLORS[((depth - 1) % #M.GROUP_BOX_COLORS) + 1]
    return ("|cff%02x%02x%02x"):format(c[5] * 255, c[6] * 255, c[7] * 255)
end

function M.HasParenMismatch(conds)
    local depth = 0
    for _, cond in ipairs(conds or {}) do
        depth = depth + (cond.lparen or 0)
        depth = depth - (cond.rparen or 0)
        if depth < 0 then return true end
    end
    return depth ~= 0
end

function M.AnalyzeParenGroups(conds)
    local spans, unmatchedOpens, unmatchedCloses, stack = {}, {}, {}, {}

    for i, cond in ipairs(conds) do
        for _ = 1, (cond.lparen or 0) do
            stack[#stack + 1] = { startIdx = i, depth = #stack + 1 }
        end
        for _ = 1, (cond.rparen or 0) do
            local open = table.remove(stack)
            if open then
                spans[#spans + 1] = { startIdx = open.startIdx, endIdx = i, depth = open.depth }
            else
                unmatchedCloses[i] = (unmatchedCloses[i] or 0) + 1
            end
        end
    end

    for _, open in ipairs(stack) do
        unmatchedOpens[open.startIdx] = (unmatchedOpens[open.startIdx] or 0) + 1
    end

    table.sort(spans, function(a, b)
        local aLen, bLen = a.endIdx - a.startIdx, b.endIdx - b.startIdx
        if aLen ~= bLen then return aLen > bLen end
        return a.depth < b.depth
    end)

    return spans, unmatchedOpens, unmatchedCloses
end

function M.GetCondParenDepths(conds)
    local lpDepths, rpDepths, stack = {}, {}, {}
    for i, cond in ipairs(conds) do
        lpDepths[i] = {}
        for _ = 1, (cond.lparen or 0) do
            local d = #stack + 1
            stack[#stack + 1] = d
            lpDepths[i][#lpDepths[i] + 1] = d
        end
        rpDepths[i] = {}
        for _ = 1, (cond.rparen or 0) do
            local d = table.remove(stack) or 1
            rpDepths[i][#rpDepths[i] + 1] = d
        end
    end
    return lpDepths, rpDepths
end

function M.DrawConditionGroupBoxes(spans, rowYTops, deps)
    local condGroupBoxPool = deps.condGroupBoxPool
    local rightPanel = deps.rightPanel
    local setBD = deps.setBD

    for _, box in ipairs(condGroupBoxPool) do box:Hide() end
    if not rightPanel then return end

    local panelLevel = rightPanel:GetFrameLevel()
    for i, span in ipairs(spans) do
        if not condGroupBoxPool[i] then
            local box = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
            box:SetFrameStrata(rightPanel:GetFrameStrata())
            condGroupBoxPool[i] = box
        end

        local topY = rowYTops[span.startIdx]
        local endY = rowYTops[span.endIdx]
        if topY and endY then
            local inset = 2 + (span.depth - 1) * 4
            local color = M.GROUP_BOX_COLORS[((span.depth - 1) % #M.GROUP_BOX_COLORS) + 1]
            local box = condGroupBoxPool[i]
            local height = (topY - (endY - 22)) + 4

            box:ClearAllPoints()
            box:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4 + inset, topY + 2)
            box:SetSize(rightPanel:GetWidth() - 8 - inset * 2, height)
            box:SetFrameLevel(panelLevel + math.min(i - 1, 8))
            setBD(box, color[1], color[2], color[3], color[4], color[5], color[6], color[7])
            box:Show()
        end
    end
end
