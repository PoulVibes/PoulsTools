-- CombatCoach_Widgets.lua
-- Reusable UI widget helpers for sub-addon OnBuildUI callbacks.

CombatCoach = CombatCoach or {}
CombatCoach.Widgets = CombatCoach.Widgets or {}
local W = CombatCoach.Widgets

W.colors = {
    accent      = {0.0, 0.8, 1.0, 1.0},
    headerBg    = {0.04, 0.08, 0.15, 0.85},
    rowEven     = {0.06, 0.10, 0.16, 0.5},
    rowOdd      = {0.04, 0.07, 0.12, 0.3},
    text        = {0.9, 0.95, 1.0, 1.0},
    textMuted   = {0.55, 0.65, 0.75, 1.0},
    textLabel   = {0.6, 0.75, 0.9, 1.0},
    enabled     = {0.2, 1.0, 0.4, 1.0},
    disabled    = {0.8, 0.3, 0.3, 1.0},
    warning     = {1.0, 0.75, 0.1, 1.0},
}

-- Creates a styled section label with a divider line; returns (fontString, yOffset).
function W:SectionHeader(parent, anchor, yOffset, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    local anchorPoint = (anchor == parent) and "TOPLEFT" or "BOTTOMLEFT"
    label:SetPoint("TOPLEFT", anchor, anchorPoint, 0, yOffset - 12)
    label:SetText(text:upper())
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetTextColor(0.4, 0.6, 0.8, 1.0)

    local line = parent:CreateTexture(nil, "OVERLAY")
    line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    line:SetSize(540, 1)
    line:SetColorTexture(0.15, 0.25, 0.35, 0.8)

    return line, -28
end

-- Creates a colored dot + text status label.
function W:StatusLabel(parent, anchor, yOffset, label, status, statusText)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(540, 20)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 4)

    local dot = row:CreateTexture(nil, "OVERLAY")
    dot:SetPoint("LEFT", row, "LEFT", 0, 0)
    dot:SetSize(10, 10)
    dot:SetTexture("Interface\\COMMON\\Indicator-Green")
    if status == false then
        dot:SetTexture("Interface\\COMMON\\Indicator-Red")
    elseif status == "warn" then
        dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    end

    local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", dot, "RIGHT", 6, 0)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(W.colors.textLabel))

    if statusText then
        local valText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valText:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
        valText:SetText(statusText)
        valText:SetTextColor(unpack(W.colors.text))
    end

    return row
end

-- Creates a styled action button.
function W:Button(parent, anchor, yOffset, label, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 8)
    btn:SetSize(160, 26)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end
