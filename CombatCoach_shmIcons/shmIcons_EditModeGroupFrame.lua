-- shmIcons_EditModeGroupFrame.lua
-- BuildEditModeGroupFrame orchestration.

function BuildEditModeGroupFrame(group, recycledFrame)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, icon in ipairs(group) do
        local cx, cy = icon.frame:GetCenter()
        local half = icon.frame:GetWidth() * 0.5
        minX = math.min(minX, cx - half)
        minY = math.min(minY, cy - half)
        maxX = math.max(maxX, cx + half)
        maxY = math.max(maxY, cy + half)
    end

    local pad = 6
    local uiCX, uiCY = UIParent:GetCenter()
    local grpCX = (minX + maxX) * 0.5
    local grpCY = (minY + maxY) * 0.5

    local offsets = {}
    for _, icon in ipairs(group) do
        local cx, cy = icon.frame:GetCenter()
        offsets[#offsets + 1] = {
            icon = icon,
            offsetX = cx - grpCX,
            offsetY = cy - grpCY,
        }
    end

    local groupIDSet = {}
    for _, icon in ipairs(group) do
        groupIDSet[icon.globalID] = true
    end

    local f = recycledFrame
    if not f then
        f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:EnableMouse(true)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.1, 0.5, 1.0, 0.12)
        f:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)

        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("BOTTOM", f, "TOP", 0, 2)
        label:SetFont(FONT_PATH, 11, FONT_FLAGS)
        label:SetTextColor(0.3, 0.8, 1.0, 1.0)
        f._groupLabel = label
    end

    f:ClearAllPoints()
    f:SetSize((maxX - minX) + pad * 2, (maxY - minY) + pad * 2)
    f:SetPoint("CENTER", UIParent, "CENTER", grpCX - uiCX, grpCY - uiCY)

    local label = f._groupLabel
    if label then
        label:SetText(#group == 1 and "Icon" or (#group .. " Icons"))
    end

    f:Show()

    local ctx = {
        group = group,
        frame = f,
        offsets = offsets,
        groupIDSet = groupIDSet,
        mySize = math.floor(group[1].frame:GetWidth() + 0.5),
        isDragging = false,
        isSnapFrozen = false,
        cursorOffX = 0,
        cursorOffY = 0,
        soloEntry = nil,
        soloIconOffX = 0,
        soloIconOffY = 0,
        clickPending = false,
    }

    shmIcons_AttachEditModeGroupDragScripts(ctx)

    return f
end
