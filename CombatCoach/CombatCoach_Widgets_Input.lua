-- CombatCoach_Widgets_Input.lua
-- Input widget helpers: Checkbox, Slider, Dropdown, EditBox.

local W = CombatCoach.Widgets

-- Creates a labeled checkbox with optional tooltip.
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

    slider.Low:SetText("")
    slider.High:SetText("")
    if slider.Text then slider.Text:SetText("") end

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        setValue(value)
        valText:SetText(string.format(fmt, value))
    end)

    row.slider = slider
    row.valText = valText

    return row
end

-- Creates a simple dropdown (uses UIDropDownMenu).
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

    local currentVal = getValue()
    for _, item in ipairs(items) do
        if item.value == currentVal then
            UIDropDownMenu_SetText(dropdown, item.text)
            UIDropDownMenu_SetSelectedValue(dropdown, item.value)
            break
        end
    end

    row.dropdown = dropdown
    row.items = items
    return row
end

-- Creates a labeled single-line edit box.
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

    if placeholder then
        if box:GetText() == "" then
            box:SetTextColor(0.4, 0.5, 0.6, 1.0)
            box:SetText(placeholder)
        end
        box:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == placeholder then
                self:SetText("")
                self:SetTextColor(unpack(W.colors.text))
            end
        end)
        box:SetScript("OnEditFocusLost", function(self)
            local val = self:GetText()
            if val == "" or val == placeholder then
                self:SetText(placeholder)
                self:SetTextColor(0.4, 0.5, 0.6, 1.0)
                setValue("")
            else
                setValue(val)
            end
        end)
    else
        box:SetScript("OnEditFocusLost", function(self)
            setValue(self:GetText())
        end)
    end

    box:SetScript("OnEnterPressed", function(self)
        local val = self:GetText()
        if val ~= placeholder then
            setValue(val)
        end
        self:ClearFocus()
    end)

    row.box = box
    row.placeholder = placeholder
    return row
end
