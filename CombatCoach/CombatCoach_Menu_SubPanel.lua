-- CombatCoach_Menu_SubPanel.lua
-- Subcategory registration and sub-panel creation.

local CC   = CombatCoach
local Menu = CombatCoach.Menu

-- Adds a subcategory (submenu) for a registered addon.
function Menu:AddSubcategory(info)
    -- Create the sub-panel canvas
    local subPanel = self:CreateSubPanel(info)

    -- Determine parent: nest under another addon's category if parentId is set
    local parentCategory = self.mainCategory
    if info.parentId then
        local parentInfo = self.registry[info.parentId]
        if parentInfo and parentInfo._category then
            parentCategory = parentInfo._category
        end
    end

    -- Register as a subcategory under the resolved parent
    local subCategory, layout = Settings.RegisterCanvasLayoutSubcategory(
        parentCategory,
        subPanel,
        info.name
    )
    Settings.RegisterAddOnCategory(subCategory)

    info._category = subCategory

    -- Refresh the main panel list
    self:RefreshAddonList()
end

-- ============================================================
-- Create the canvas panel for a sub-addon
-- ============================================================
function Menu:CreateSubPanel(info)
    local frame = CreateFrame("Frame")
    frame.name = info.name

    -- Header bar
    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -10)
    header:SetSize(580, 60)
    header:SetColorTexture(0.04, 0.08, 0.15, 0.85)

    -- Accent line (colored by addon, or default)
    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetSize(580, 2)
    if info.accentColor then
        accent:SetColorTexture(unpack(info.accentColor))
    else
        accent:SetColorTexture(0.0, 0.8, 1.0, 1.0)
    end

    -- Icon
    local xOffset = 16
    if info.icon then
        local iconTex = frame:CreateTexture(nil, "OVERLAY")
        iconTex:SetPoint("LEFT", header, "LEFT", xOffset, 0)
        iconTex:SetSize(36, 36)
        iconTex:SetTexture(info.icon)
        xOffset = xOffset + 46
    end

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", xOffset, -12)
    title:SetText("|cFF00CCFF" .. info.name .. "|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    if info.version then
        local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
        ver:SetText("Version " .. info.version)
        ver:SetTextColor(0.5, 0.65, 0.8, 1.0)
    end

    if info.desc then
        local descBg = frame:CreateTexture(nil, "BACKGROUND")
        descBg:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
        descBg:SetSize(580, 36)
        descBg:SetColorTexture(0.06, 0.10, 0.18, 0.5)

        local descText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descText:SetPoint("LEFT", descBg, "LEFT", 16, 0)
        descText:SetWidth(548)
        descText:SetJustifyH("LEFT")
        descText:SetText(info.desc)
        descText:SetTextColor(0.75, 0.85, 0.95, 1.0)
    end

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -120)
    scroll:SetSize(580, 460)
    scroll:SetClipsChildren(true)

    local contentFrame = CreateFrame("Frame", nil, scroll)
    contentFrame:SetSize(560, 1000)
    contentFrame:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(contentFrame)

    local children = {}
    for id, reg in pairs(self.registry) do
        if reg.parentId == info.id then
            children[#children + 1] = reg
        end
    end
    table.sort(children, function(a, b) return a.name < b.name end)

    local onBuildUIParent = contentFrame
    if #children > 0 then
        local childLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        childLabel:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -12)
        childLabel:SetText("SUB-ADDONS")
        childLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        childLabel:SetTextColor(0.4, 0.6, 0.8, 1.0)

        local childLine = contentFrame:CreateTexture(nil, "OVERLAY")
        childLine:SetPoint("TOPLEFT", childLabel, "BOTTOMLEFT", 0, -4)
        childLine:SetSize(540, 1)
        childLine:SetColorTexture(0.15, 0.25, 0.35, 0.8)

        local prevAnchor = childLine
        for i, child in ipairs(children) do
            local row = self:CreateAddonListRow(contentFrame, child, i, false)
            row:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -4)
            prevAnchor = row
        end

        local dividerLine = contentFrame:CreateTexture(nil, "OVERLAY")
        dividerLine:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -12)
        dividerLine:SetSize(540, 1)
        dividerLine:SetColorTexture(0.1, 0.2, 0.3, 0.5)

        local innerFrame = CreateFrame("Frame", nil, contentFrame)
        innerFrame:SetPoint("TOPLEFT", dividerLine, "BOTTOMLEFT", 0, -8)
        innerFrame:SetSize(560, 900)
        onBuildUIParent = innerFrame
    end

    if info.OnBuildUI then
        local ok, err = pcall(info.OnBuildUI, onBuildUIParent)
        if not ok then
            local errText = onBuildUIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errText:SetPoint("TOPLEFT", onBuildUIParent, "TOPLEFT", 16, -16)
            errText:SetWidth(548)
            errText:SetText("|cFFFF4444Error building UI for " .. info.name .. ":|r\n" .. tostring(err))
        end
    end

    return frame
end
