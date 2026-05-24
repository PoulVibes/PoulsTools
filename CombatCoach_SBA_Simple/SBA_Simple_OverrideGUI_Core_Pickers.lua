-- SBA_Simple_OverrideGUI_Core_Pickers.lua
-- Shared picker popup builders for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateCondPicker(setBD, getVisibleCondTypes)
    local f = CreateFrame("Frame", "SBAS_GUI_CondPicker", UIParent, "BackdropTemplate")
    f:SetSize(272, 336)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    setBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Condition Type")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -20)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 22, 0), m))
    end)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(266, 4)
    sf:SetScrollChild(sc)

    f.callback = nil
    f.rows = {}
    f.UpdateRows = function(self)
        local visible = getVisibleCondTypes()
        sc:SetHeight(math.max(4, #visible * 22 + 4))

        for i, ct in ipairs(visible) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Button", nil, sc)
                row:SetSize(262, 20)
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()
                row.bg:SetColorTexture(0, 0, 0, 0)
                row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.lbl:SetAllPoints()
                row.lbl:SetJustifyH("LEFT")
                row.lbl:SetTextColor(0.82, 0.9, 1, 1)
                self.rows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", sc, "TOPLEFT", 2, -2 - (i - 1) * 22)
            row.lbl:SetText("  " .. ct.label)
            row.ctRef = ct
            row:SetScript("OnClick", function(btn)
                self:Hide()
                if self.callback then self.callback(btn.ctRef) end
            end)
            row:SetScript("OnEnter", function(btn)
                btn.bg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
                btn.lbl:SetTextColor(1, 1, 1, 1)
            end)
            row:SetScript("OnLeave", function(btn)
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.lbl:SetTextColor(0.82, 0.9, 1, 1)
            end)
            row:Show()
        end

        for i = #visible + 1, #self.rows do self.rows[i]:Hide() end
    end

    return f
end

function M.ShowPickerBelowOrAbove(picker, anchor, callback)
    picker.callback = callback
    picker:ClearAllPoints()
    picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    picker:Show()
    local bot = picker:GetBottom()
    if bot and bot < 0 then
        picker:ClearAllPoints()
        picker:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
end

function M.CreatePluginPicker(setBD, getVisiblePluginOptions)
    local f = CreateFrame("Frame", "SBAS_GUI_PluginPicker", UIParent, "BackdropTemplate")
    f:SetSize(200, 28)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    setBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Plugin / Proc")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    f.rows = {}
    f.UpdateRows = function(self)
        local visible = getVisiblePluginOptions()
        self:SetHeight(#visible * 22 + 28)

        for i, opt in ipairs(visible) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Button", nil, self)
                row:SetSize(192, 20)
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()
                row.bg:SetColorTexture(0, 0, 0, 0)
                row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.lbl:SetAllPoints()
                row.lbl:SetJustifyH("LEFT")
                row.lbl:SetTextColor(0.82, 0.9, 1, 1)
                self.rows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -22 - (i - 1) * 22)
            row.lbl:SetText("  " .. opt.label)
            row.optRef = opt
            row:SetScript("OnClick", function(btn)
                self:Hide()
                if self.callback then self.callback(btn.optRef) end
            end)
            row:SetScript("OnEnter", function(btn)
                btn.bg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
                btn.lbl:SetTextColor(1, 1, 1, 1)
            end)
            row:SetScript("OnLeave", function(btn)
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.lbl:SetTextColor(0.82, 0.9, 1, 1)
            end)
            row:Show()
        end

        for i = #visible + 1, #self.rows do self.rows[i]:Hide() end
    end

    return f
end
