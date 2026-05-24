-- SBA_Simple_OverrideGUI_Core_DragDrop_Cond.lua
-- Condition drag ticker setup.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.EnsureCondCatcher(deps)
    if deps.getCondCatcher() then return end

    local condDropLine = CreateFrame("Frame", nil, UIParent)
    condDropLine:SetHeight(2)
    condDropLine:SetFrameStrata("TOOLTIP")
    condDropLine:Hide()
    local diTex = condDropLine:CreateTexture(nil, "ARTWORK")
    diTex:SetAllPoints()
    diTex:SetColorTexture(0.3, 0.85, 1, 0.95)
    deps.setCondDropLine(condDropLine)

    local condCatcher = CreateFrame("Frame", "SBAS_CondDragTicker", UIParent)
    condCatcher:SetScript("OnUpdate", function()
        local condDrag = deps.getCondDrag()
        if not condDrag.pending and not condDrag.active then
            local line = deps.getCondDropLine()
            if line then line:Hide() end
            return
        end

        local cx, cy = GetCursorPosition()
        local sc = UIParent:GetEffectiveScale()
        cx, cy = cx / sc, cy / sc

        if condDrag.pending then
            if not IsMouseButtonDown("LeftButton") then
                return
            end
            local dx = cx - condDrag.pendingX
            local dy = cy - condDrag.pendingY
            if dx * dx + dy * dy > 64 then
                condDrag.pending = false
                condDrag.active = true
            end
            return
        end

        if not condDrag.active then return end

        if not IsMouseButtonDown("LeftButton") then
            condDrag.active = false
            condDrag.fromIdx = nil
            condDrag.toSlot = nil
            local line = deps.getCondDropLine()
            if line then line:Hide() end
            return
        end

        local selectedIdx = deps.getSelectedIdx()
        local workingRules = deps.getWorkingRules()
        local rule = selectedIdx > 0 and workingRules[selectedIdx]
        local numConds = rule and #(rule.conditions or {}) or 0
        local rightPanel = deps.getRightPanel()
        local panelTop = rightPanel and rightPanel:GetTop()
        if not panelTop or numConds == 0 then return end

        local relY = cy - panelTop
        local slot = numConds + 1
        local condRowYList = deps.getCondRowYList()
        for j = 1, numConds do
            if relY > (condRowYList[j] or 0) - 11 then
                slot = j
                break
            end
        end
        condDrag.toSlot = slot

        local lineY
        if slot <= numConds then
            lineY = condRowYList[slot] or 0
        else
            lineY = (condRowYList[numConds] or 0) - 22
        end
        local panelLeft = rightPanel:GetLeft() or 0
        local line = deps.getCondDropLine()
        line:ClearAllPoints()
        line:SetWidth(deps.getRightPanelWidth() - 12)
        line:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", panelLeft + 6, panelTop + lineY)
        line:Show()
    end)

    deps.setCondCatcher(condCatcher)
end

return M
