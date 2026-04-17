-- PoulsTools_Widgets.lua
-- Reusable UI widget helpers for sub-addons to use in their OnBuildUI callbacks
-- WoW API: 12.0.1 (The War Within)

PoulsTools = PoulsTools or {}
PoulsTools.Widgets = PoulsTools.Widgets or {}
local W = PoulsTools.Widgets

-- ============================================================
-- Color constants
-- ============================================================
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

-- ============================================================
-- Section header
-- Creates a styled section label with a divider line.
-- Returns: fontString, yBottom (relative offset after the element)
-- ============================================================
function W:SectionHeader(parent, anchor, yOffset, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- If the anchor is the parent (first element), anchor to the parent's TOPLEFT;
    -- otherwise anchor below the previous element's bottom-left.
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

-- ============================================================
-- Checkbox row
-- Creates a labeled checkbox with optional tooltip.
-- Parameters:
--   parent   - parent frame
--   anchor   - anchor region (previous element)
--   yOffset  - vertical offset from anchor
--   label    - display label text
--   tooltip  - (optional) tooltip text
--   getValue - function() returning current boolean value
--   setValue - function(bool) called when toggled
-- Returns: checkFrame
-- ============================================================
function W:Checkbox(parent, anchor, yOffset, label, tooltip, getValue, setValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(540, 26)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 6)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetPoint("LEFT", row, "LEFT", 0, 0)
    check:SetSize(22, 22)
    check:SetChecked(getValue())

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", check, "RIGHT", 6, 0)
    text:SetText(label)
    text:SetTextColor(unpack(W.colors.text))

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    check:SetScript("OnClick", function(self)
        setValue(self:GetChecked())
    end)

    return row
end

-- ============================================================
-- Slider row
-- Creates a labeled slider.
-- Parameters:
--   parent   - parent frame
--   anchor   - anchor region
--   yOffset  - vertical offset
--   label    - display label
--   min, max - range
--   step     - step size
--   getValue - function() returning current number
--   setValue - function(num) called on change
--   fmt      - (optional) format string e.g. "%.1f"
-- Returns: sliderFrame
-- ============================================================
function W:Slider(parent, anchor, yOffset, label, min, max, step, getValue, setValue, fmt)
    fmt = fmt or "%d"

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(540, 50)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 6)

    local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(W.colors.textLabel))

    local valText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valText:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
    valText:SetText(string.format(fmt, getValue()))
    valText:SetTextColor(unpack(W.colors.text))

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
    slider:SetSize(540, 16)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(getValue())

    -- Hide default slider labels
    slider.Low:SetText("")
    slider.High:SetText("")
    if slider.Text then slider.Text:SetText("") end

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        setValue(value)
        valText:SetText(string.format(fmt, value))
    end)

    -- expose inner elements so callers can update them later if needed
    row.slider = slider
    row.valText = valText

    return row
end

-- ============================================================
-- Dropdown row
-- Creates a simple dropdown (uses UIDropDownMenu).
-- Parameters:
--   parent    - parent frame
--   anchor    - anchor region
--   yOffset   - vertical offset
--   label     - display label
--   items     - array of {text=string, value=any}
--   getValue  - function() returning current value
--   setValue  - function(value) called on selection
-- Returns: dropdownFrame
-- ============================================================
function W:Dropdown(parent, anchor, yOffset, label, items, getValue, setValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(540, 46)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 6)

    local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(W.colors.textLabel))

    local dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropdown, 200)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.checked = (getValue() == item.value)
            info.func = function(btn)
                setValue(btn.value)
                UIDropDownMenu_SetSelectedValue(dropdown, btn.value)
                -- Update displayed text
                for _, it in ipairs(items) do
                    if it.value == btn.value then
                        UIDropDownMenu_SetText(dropdown, it.text)
                        break
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Set initial display text
    local currentVal = getValue()
    for _, item in ipairs(items) do
        if item.value == currentVal then
            UIDropDownMenu_SetText(dropdown, item.text)
            UIDropDownMenu_SetSelectedValue(dropdown, item.value)
            break
        end
    end

    return row
end

-- ============================================================
-- Text input row
-- Creates a labeled single-line edit box.
-- Parameters:
--   parent    - parent frame
--   anchor    - anchor region
--   yOffset   - vertical offset
--   label     - display label
--   placeholder - placeholder text
--   getValue  - function() returning current string
--   setValue  - function(str) called on change
-- Returns: editFrame
-- ============================================================
function W:EditBox(parent, anchor, yOffset, label, placeholder, getValue, setValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(540, 46)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 6)

    local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    labelText:SetText(label)
    labelText:SetTextColor(unpack(W.colors.textLabel))

    local box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -6)
    box:SetSize(300, 22)
    box:SetAutoFocus(false)
    box:SetText(getValue() or "")
    box:SetMaxLetters(255)

    if placeholder and box:GetText() == "" then
        box:SetTextColor(0.4, 0.5, 0.6, 1.0)
        box:SetText(placeholder)
        box:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == placeholder then
                self:SetText("")
                self:SetTextColor(unpack(W.colors.text))
            end
        end)
        box:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                self:SetText(placeholder)
                self:SetTextColor(0.4, 0.5, 0.6, 1.0)
            end
        end)
    end

    box:SetScript("OnEnterPressed", function(self)
        local val = self:GetText()
        if val ~= placeholder then
            setValue(val)
        end
        self:ClearFocus()
    end)

    return row
end

-- ============================================================
-- Status indicator
-- Creates a colored dot + text status label.
-- ============================================================
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

-- ============================================================
-- Button row
-- Creates a styled action button.
-- ============================================================
function W:Button(parent, anchor, yOffset, label, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 8)
    btn:SetSize(160, 26)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end
