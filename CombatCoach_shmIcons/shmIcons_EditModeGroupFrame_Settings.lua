-- shmIcons_EditModeGroupFrame_Settings.lua
-- Settings window helper for edit mode group frames.

function shmIcons_OpenEditModeGroupSettings(ctx)
    CloseEditModeSettingsWindow()

    local currentSize = ctx.mySize

    local half0 = currentSize * 0.5
    local minCX0, minCY0 = math.huge, math.huge
    local maxCX0, maxCY0 = -math.huge, -math.huge
    for _, entry in ipairs(ctx.offsets) do
        local cx, cy = entry.icon.frame:GetCenter()
        minCX0 = math.min(minCX0, cx - half0)
        minCY0 = math.min(minCY0, cy - half0)
        maxCX0 = math.max(maxCX0, cx + half0)
        maxCY0 = math.max(maxCY0, cy + half0)
    end
    local fixedGCX = (minCX0 + maxCX0) * 0.5
    local fixedGCY = (minCY0 + maxCY0) * 0.5
    for _, entry in ipairs(ctx.offsets) do
        entry.nx = (currentSize > 0) and (entry.offsetX / currentSize) or 0
        entry.ny = (currentSize > 0) and (entry.offsetY / currentSize) or 0
    end

    local win = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    win:SetSize(300, 100)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    win:SetFrameStrata("TOOLTIP")
    win:SetFrameLevel(100)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) self:StartMoving() end)
    win:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    win:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    win:SetBackdropColor(0.05, 0.05, 0.12, 0.95)
    win:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)

    win:SetScript("OnHide", function()
        if editModeSettingsWindow == win then
            editModeSettingsWindow = nil
        end
    end)

    local title = win:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_PATH, 12, FONT_FLAGS)
    title:SetPoint("TOP", win, "TOP", 0, -12)
    title:SetText(#ctx.group == 1 and "Icon Settings" or (#ctx.group .. " Icon Group Settings"))
    title:SetTextColor(0.3, 0.8, 1.0, 1.0)

    local closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
    closeBtn:EnableMouse(true)
    local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY")
    closeLabel:SetFont(FONT_PATH, 16, FONT_FLAGS)
    closeLabel:SetText("x")
    closeLabel:SetTextColor(0.7, 0.2, 0.2, 1.0)
    closeLabel:SetAllPoints(closeBtn)
    closeBtn:SetScript("OnEnter", function() closeLabel:SetTextColor(1.0, 0.5, 0.5, 1.0) end)
    closeBtn:SetScript("OnLeave", function() closeLabel:SetTextColor(0.7, 0.2, 0.2, 1.0) end)
    closeBtn:SetScript("OnClick", function()
        CloseEditModeSettingsWindow()
        shmIcons:EnterEditMode()
    end)

    local sizeLabel = win:CreateFontString(nil, "OVERLAY")
    sizeLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
    sizeLabel:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -52)
    sizeLabel:SetText("Size:")
    sizeLabel:SetTextColor(1, 1, 1, 1)

    local slider = CreateFrame("Slider", nil, win, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("LEFT", sizeLabel, "RIGHT", 8, 0)
    slider:SetSize(190, 16)
    slider:SetMinMaxValues(MIN_SIZE, MAX_SIZE)
    slider:SetValueStep(1)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetSize(32, 18)
    slider:SetThumbTexture(thumb)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })

    local sizeValue = win:CreateFontString(nil, "OVERLAY")
    sizeValue:SetFont(FONT_PATH, 11, FONT_FLAGS)
    sizeValue:SetPoint("LEFT", slider, "RIGHT", 6, 0)
    sizeValue:SetText(tostring(currentSize))
    sizeValue:SetTextColor(1, 1, 1, 1)

    slider:SetScript("OnValueChanged", function(_, value)
        local newSize = math.max(MIN_SIZE, math.min(math.floor(value + 0.5), MAX_SIZE))
        if newSize == currentSize then return end

        local uiCX, uiCY = UIParent:GetCenter()
        currentSize = newSize
        sizeValue:SetText(tostring(newSize))

        for _, entry in ipairs(ctx.offsets) do
            entry.offsetX = entry.nx * newSize
            entry.offsetY = entry.ny * newSize
            entry.icon.frame:SetSize(newSize, newSize)
            entry.icon.frame:ClearAllPoints()
            entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", fixedGCX + entry.offsetX - uiCX, fixedGCY + entry.offsetY - uiCY)
            SaveIconPos(entry.icon)
            if entry.icon.onMove then entry.icon.onMove(entry.icon.db) end
        end

        for _, entry in ipairs(ctx.offsets) do
            RepositionCtrlChildren(entry.icon.globalID)
        end

        ctx.mySize = newSize

        local half2 = newSize * 0.5
        local minX2, minY2 = math.huge, math.huge
        local maxX2, maxY2 = -math.huge, -math.huge
        for _, entry in ipairs(ctx.offsets) do
            local icx = fixedGCX + entry.offsetX
            local icy = fixedGCY + entry.offsetY
            minX2 = math.min(minX2, icx - half2)
            minY2 = math.min(minY2, icy - half2)
            maxX2 = math.max(maxX2, icx + half2)
            maxY2 = math.max(maxY2, icy + half2)
        end
        local pad2 = 6
        ctx.frame:SetSize((maxX2 - minX2) + pad2 * 2, (maxY2 - minY2) + pad2 * 2)
        ctx.frame:ClearAllPoints()
        ctx.frame:SetPoint("CENTER", UIParent, "CENTER", (minX2 + maxX2) * 0.5 - uiCX, (minY2 + maxY2) * 0.5 - uiCY)
    end)

    slider:SetValue(currentSize)

    editModeSettingsWindow = win
    win:Show()
end
