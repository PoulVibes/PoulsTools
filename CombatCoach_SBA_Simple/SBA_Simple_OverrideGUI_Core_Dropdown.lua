-- SBA_Simple_OverrideGUI_Core_Dropdown.lua
-- Shared operator dropdown UI for override GUI condition editor.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.OP_LIST = {
    { id = ">=", label = ">=" },
    { id = "<=", label = "<=" },
    { id = "==", label = "==" },
    { id = ">", label = ">" },
    { id = "<", label = "<" },
}

M.PROC_MODE_LIST = {
    { id = "active", label = "Active" },
    { id = ">=", label = ">=" },
    { id = "<=", label = "<=" },
    { id = "==", label = "==" },
    { id = ">", label = ">" },
    { id = "<", label = "<" },
}

M.STACKS_VALUE_LIST = {
    { id = "0", label = "0 (None)" },
    { id = "1", label = "1" },
    { id = "max", label = "Max" },
}

function M.MakeOpDropdown(parent, ops, deps)
    local setBD = deps.setBD
    local closeAllPopups = deps.closeAllPopups
    local opDropdownPopups = deps.opDropdownPopups

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(80, 22)

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:SetToplevel(true)
    popup:SetSize(80, #ops * 22 + 6)
    popup:Hide()
    setBD(popup, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    opDropdownPopups[#opDropdownPopups + 1] = popup

    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetAllPoints()

    local rows = {}
    local selected = ops[1].id
    local onChange = nil

    for i, op in ipairs(ops) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(80, 22)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -3 - (i - 1) * 22)
        rows[i] = row

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0, 0, 0, 0)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowLbl:SetAllPoints()
        rowLbl:SetJustifyH("CENTER")
        rowLbl:SetText(op.label)
        rowLbl:SetTextColor(0.82, 0.9, 1, 1)

        local opRef = op
        row:SetScript("OnClick", function()
            popup:Hide()
            selected = opRef.id
            btn:SetText(opRef.label)
            if onChange then onChange(opRef.id) end
        end)
        row:SetScript("OnEnter", function()
            rowBg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
            rowLbl:SetTextColor(1, 1, 1, 1)
        end)
        row:SetScript("OnLeave", function()
            rowBg:SetColorTexture(0, 0, 0, 0)
            rowLbl:SetTextColor(0.82, 0.9, 1, 1)
        end)
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            closeAllPopups()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
            local bot = popup:GetBottom()
            if bot and bot < 0 then
                popup:ClearAllPoints()
                popup:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
            end
        end
    end)

    btn:SetText(ops[1].label)

    container.SetSelected = function(self, id)
        for _, op in ipairs(ops) do
            if op.id == id then
                selected = id
                btn:SetText(op.label)
                return
            end
        end
    end

    container.GetSelected = function(self) return selected end

    container.UpdateWidth = function(self, w)
        container:SetWidth(w)
        btn:SetWidth(w)
        popup:SetWidth(w)
        for _, row in ipairs(rows) do row:SetWidth(w) end
    end

    container.SetOnChange = function(self, fn)
        onChange = fn
    end

    return container
end
