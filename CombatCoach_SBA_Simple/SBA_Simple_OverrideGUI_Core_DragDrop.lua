-- SBA_Simple_OverrideGUI_Core_DragDrop.lua
-- Spell/rule drag infrastructure for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.EnsureDragIcon(deps)
    local dragIconFrame = deps.getDragIconFrame()
    if dragIconFrame then return end
    dragIconFrame = CreateFrame("Frame", "SBAS_SpellDragIcon", UIParent)
    dragIconFrame:SetSize(38, 38)
    dragIconFrame:SetFrameStrata("TOOLTIP")
    dragIconFrame:Hide()
    local tex = dragIconFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dragIconFrame._tex = tex
    local glow = dragIconFrame:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    glow:SetBlendMode("ADD")
    dragIconFrame:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
    deps.setDragIconFrame(dragIconFrame)
end

function M.EnsureDragCatcher(deps)
    if deps.getDragCatcher() then return end

    local dragCatcher = CreateFrame("Frame", "SBAS_SpellDragCatcher", UIParent)
    dragCatcher:SetAllPoints(UIParent)
    dragCatcher:SetFrameStrata("DIALOG")
    dragCatcher:EnableMouse(true)
    dragCatcher:Hide()
    deps.setDragCatcher(dragCatcher)

    local dropIndicator = CreateFrame("Frame", "SBAS_DropIndicator", UIParent)
    dropIndicator:SetSize(1, 3)
    dropIndicator:SetFrameStrata("TOOLTIP")
    dropIndicator:Hide()
    local diTex = dropIndicator:CreateTexture(nil, "ARTWORK")
    diTex:SetAllPoints()
    diTex:SetColorTexture(0.3, 0.85, 1, 1)
    deps.setDropIndicator(dropIndicator)

    local function GetRuleDropSlot(mx, my)
        local best, bestDist = 1, math.huge
        local rowFrames = deps.getRowFrames()
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rt = rf:GetTop()
                if rt then
                    local d = math.abs(my - rt)
                    if d < bestDist then bestDist = d; best = i end
                end
            end
        end
        local lastVisible = 0
        for i, rf in ipairs(rowFrames) do if rf:IsShown() then lastVisible = i end end
        if lastVisible > 0 then
            local rb = rowFrames[lastVisible]:GetBottom()
            if rb and math.abs(my - rb) < bestDist then best = lastVisible + 1 end
        end
        return best
    end

    local function ResetRowBorders()
        local rowFrames, selectedIdx = deps.getRowFrames(), deps.getSelectedIdx()
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                if rf._idx and rf._idx == selectedIdx then rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1) end
            end
        end
    end

    local function FinishRuleDrop()
        local ruleDrag, fromIdx = deps.getRuleDrag(), deps.getRuleDrag().fromIdx
        ruleDrag.active, ruleDrag.fromIdx = false, nil
        local icon = deps.getDragIconFrame(); if icon then icon:Hide() end
        local di = deps.getDropIndicator(); if di then di:Hide() end
        dragCatcher:Hide()
        ResetRowBorders()

        local mx, my = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); mx, my = mx / s, my / s
        local workingRules = deps.getWorkingRules()
        local slot = math.max(1, math.min(GetRuleDropSlot(mx, my), #workingRules + 1))
        if slot ~= fromIdx and slot ~= fromIdx + 1 then
            local rule = table.remove(workingRules, fromIdx)
            local toIdx = (slot > fromIdx) and (slot - 1) or slot
            table.insert(workingRules, toIdx, rule)
            deps.setSelectedIdx(toIdx)
            deps.setIsAddingCond(false)
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end
    end

    local function FinishSpellDrop()
        local sbasDrag = deps.getSbasDrag()
        sbasDrag.active = false
        local icon = deps.getDragIconFrame(); if icon then icon:Hide() end
        dragCatcher:Hide(); ResetRowBorders()
        if not sbasDrag.spellID then return end

        local mx, my = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); mx, my = mx / s, my / s
        local insertIdx = nil
        local rowFrames = deps.getRowFrames()
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr, rt, rb = rf:GetLeft(), rf:GetRight(), rf:GetTop(), rf:GetBottom()
                if rl and rr and rt and rb and mx >= rl and mx <= rr and my >= rb and my <= rt then insertIdx = i; break end
            end
        end

        local guiFrame = deps.getGuiFrame()
        if not insertIdx and guiFrame and guiFrame._leftSF then
            local sf = guiFrame._leftSF
            local ll, lr, lt, lb = sf:GetLeft(), sf:GetRight(), sf:GetTop(), sf:GetBottom()
            if ll and lr and lt and lb and mx >= ll and mx <= lr and my >= lb and my <= lt then insertIdx = #deps.getWorkingRules() + 1 end
        end

        if insertIdx then
            local rules, entry = deps.getWorkingRules(), { spellID = sbasDrag.spellID, name = sbasDrag.spellName, conditions = {}, itemID = sbasDrag.itemID }
            if insertIdx > #rules then rules[#rules + 1] = entry; deps.setSelectedIdx(#rules)
            else table.insert(rules, insertIdx, entry); deps.setSelectedIdx(insertIdx) end
            deps.setIsAddingCond(false)
            deps.refreshRuleList()
            deps.refreshRightPanel()
        end

        sbasDrag.spellID, sbasDrag.spellName, sbasDrag.itemID = nil, nil, nil
    end

    dragCatcher:SetScript("OnUpdate", function()
        local ruleDrag, sbasDrag = deps.getRuleDrag(), deps.getSbasDrag()
        if ruleDrag.pending then
            if not IsMouseButtonDown("LeftButton") then ruleDrag.pending, ruleDrag.fromIdx = false, nil; dragCatcher:Hide(); return end
            local cx, cy = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); cx, cy = cx / s, cy / s
            local dx, dy = cx - ruleDrag.pendingX, cy - ruleDrag.pendingY
            if dx * dx + dy * dy > 64 then
                ruleDrag.pending, ruleDrag.active = false, true
                dragCatcher:EnableMouse(true)
                local icon = deps.getDragIconFrame(); if icon then icon:Show() end
            end
            return
        end

        if not sbasDrag.active and not ruleDrag.active then return end
        local mx, my = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); mx, my = mx / s, my / s

        if ruleDrag.active then
            if not IsMouseButtonDown("LeftButton") then FinishRuleDrop(); return end
            local slot, rowFrames = GetRuleDropSlot(mx, my), deps.getRowFrames()
            local indY = nil
            if slot <= #rowFrames and rowFrames[slot] and rowFrames[slot]:IsShown() then indY = rowFrames[slot]:GetTop()
            elseif slot > 1 and rowFrames[slot - 1] and rowFrames[slot - 1]:IsShown() then indY = rowFrames[slot - 1]:GetBottom() end
            local di = deps.getDropIndicator()
            if indY and rowFrames[1] and rowFrames[1]:IsShown() and di then
                di:ClearAllPoints(); di:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", rowFrames[1]:GetLeft(), indY); di:SetWidth(rowFrames[1]:GetWidth()); di:Show()
            end
            for i, rf in ipairs(rowFrames) do
                if rf:IsShown() then
                    if i == ruleDrag.fromIdx then rf:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
                    else rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1) end
                end
            end
            return
        end

        if not IsMouseButtonDown("LeftButton") then FinishSpellDrop(); return end
        local rowFrames, selectedIdx = deps.getRowFrames(), deps.getSelectedIdx()
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr, rt, rb = rf:GetLeft(), rf:GetRight(), rf:GetTop(), rf:GetBottom()
                if rl and rr and rt and rb and mx >= rl and mx <= rr and my >= rb and my <= rt then rf:SetBackdropBorderColor(0.50, 0.88, 0.25, 1)
                elseif rf._idx and rf._idx == selectedIdx then rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1) end
            end
        end
    end)

    dragCatcher:SetScript("OnMouseUp", function(self, btn)
        local ruleDrag, sbasDrag = deps.getRuleDrag(), deps.getSbasDrag()
        if ruleDrag.pending then ruleDrag.pending, ruleDrag.fromIdx = false, nil; self:Hide(); return end
        if btn ~= "LeftButton" then return end
        if ruleDrag.active then FinishRuleDrop(); return end
        if not sbasDrag.active then self:Hide(); return end
        FinishSpellDrop()
    end)
end

return M
