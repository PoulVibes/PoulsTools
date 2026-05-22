-- CombatCoach_Menu_MainPanel.lua
-- Main panel frame creation and addon list management.

local CC   = CombatCoach
local Menu = CombatCoach.Menu

-- Creates the main panel canvas frame.
function Menu:CreateMainPanel()
    local frame = CreateFrame("Frame")
    frame.name = "CombatCoach"

    -- Header banner
    local banner = frame:CreateTexture(nil, "ARTWORK")
    banner:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -10)
    banner:SetSize(580, 80)
    banner:SetColorTexture(0.04, 0.08, 0.15, 0.85)

    local accentLine = frame:CreateTexture(nil, "OVERLAY")
    accentLine:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 0, 0)
    accentLine:SetSize(580, 2)
    accentLine:SetColorTexture(0.0, 0.8, 1.0, 1.0)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", banner, "TOPLEFT", 16, -16)
    title:SetText("|cFF00CCFFCombat|r|cFFFFFFFFCoach|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Addon Management Hub")
    subtitle:SetTextColor(0.6, 0.85, 1.0, 1.0)

    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("TOPRIGHT", banner, "TOPRIGHT", -16, -16)
    version:SetText("v" .. (CC.version or "1.0.0"))
    version:SetTextColor(0.5, 0.6, 0.7, 1.0)

    local descBg = frame:CreateTexture(nil, "BACKGROUND")
    descBg:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -12)
    descBg:SetSize(580, 55)
    descBg:SetColorTexture(0.06, 0.10, 0.18, 0.6)

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", descBg, "TOPLEFT", 16, -10)
    desc:SetWidth(548)
    desc:SetJustifyH("LEFT")
    desc:SetText(
        "Welcome to |cFF00CCFFCombatCoach|r — your personal rotation prioritizer and info tracker.\n" ..
        "Select a sub-addon from the list on the left to configure it."
    )
    desc:SetTextColor(0.85, 0.90, 0.95, 1.0)

    local divider = frame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT", descBg, "BOTTOMLEFT", 0, -12)
    divider:SetSize(580, 1)
    divider:SetColorTexture(0.15, 0.25, 0.35, 0.8)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8)
    scroll:SetSize(580, 420)
    scroll:SetClipsChildren(true)

    local contentFrame = CreateFrame("Frame", nil, scroll)
    contentFrame:SetSize(560, 1000)
    contentFrame:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(contentFrame)

    local sectionHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sectionHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -8)
    sectionHeader:SetText("REGISTERED SUB-ADDONS")
    sectionHeader:SetTextColor(0.4, 0.6, 0.8, 1.0)
    sectionHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    self.addonListFrame = contentFrame
    self.addonEntries = {}
    self.addonListAnchor = sectionHeader

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -8)
    footer:SetText("Use |cFFFFFF00/coach|r to open this panel quickly.")
    footer:SetTextColor(0.4, 0.5, 0.6, 1.0)

    return frame
end

-- Refreshes the addon list displayed on the main panel.
function Menu:RefreshAddonList()
    if not self.addonListFrame then return end

    for _, entry in ipairs(self.addonEntries) do
        entry:Hide()
        entry:SetParent(nil)
    end
    self.addonEntries = {}

    local topLevel = {}
    for id, info in pairs(self.registry) do
        if not info.parentId then
            topLevel[#topLevel + 1] = info
        end
    end
    table.sort(topLevel, function(a, b)
        local oa = a.order or math.huge
        local ob = b.order or math.huge
        if oa ~= ob then return oa < ob end
        return a.name < b.name
    end)

    local ordered = {}
    for _, info in ipairs(topLevel) do
        ordered[#ordered + 1] = { info = info, isChild = false }
        local children = {}
        for id2, child in pairs(self.registry) do
            if child.parentId == info.id then
                children[#children + 1] = child
            end
        end
        table.sort(children, function(a, b) return a.name < b.name end)
        for _, child in ipairs(children) do
            ordered[#ordered + 1] = { info = child, isChild = true }
        end
    end

    if #ordered == 0 then
        local empty = self.addonListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOPLEFT", self.addonListAnchor, "BOTTOMLEFT", 0, -12)
        empty:SetText("|cFF888888No sub-addons registered yet.|r")
        table.insert(self.addonEntries, empty)
    else
        local prevRow = nil
        for i, entry in ipairs(ordered) do
            local row = self:CreateAddonListRow(self.addonListFrame, entry.info, i, entry.isChild)
            if prevRow then
                row:SetPoint("TOPLEFT", prevRow, "BOTTOMLEFT", 0, -4)
            else
                row:SetPoint("TOPLEFT", self.addonListAnchor, "BOTTOMLEFT", 0, -8)
            end
            table.insert(self.addonEntries, row)
            prevRow = row
        end
    end

        if not self.mainPanelContentPending then
            self.mainPanelContentPending = true
            C_Timer.After(0, function()
                self.mainPanelContentPending = false
                self:RefreshMainPanelContent()
            end)
        end
end

-- Rebuilds inline content registered via RegisterMainPanelContent.
function Menu:RefreshMainPanelContent()
    if not self.addonListFrame then return end

    for _, ef in ipairs(self.mainPanelExtraFrames) do
        ef:Hide()
        ef:SetParent(nil)
    end
    self.mainPanelExtraFrames = {}

    if #self.mainPanelContentFns == 0 then return end

    local lastEntry = self.addonEntries[#self.addonEntries]
    local extraAnchor = lastEntry or self.addonListAnchor

    for _, fn in ipairs(self.mainPanelContentFns) do
        local extraFrame = CreateFrame("Frame", nil, self.addonListFrame)
        extraFrame:SetPoint("TOPLEFT", extraAnchor, "BOTTOMLEFT", 0, -16)
        extraFrame:SetSize(560, 800)
        local ok, err = pcall(fn, extraFrame)
        if not ok then
            local errText = extraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errText:SetPoint("TOPLEFT", extraFrame, "TOPLEFT", 16, -16)
            errText:SetWidth(528)
            errText:SetText("|cFFFF4444Error in main panel content:|r\n" .. tostring(err))
        end
        table.insert(self.mainPanelExtraFrames, extraFrame)
        extraAnchor = extraFrame
    end
end

-- Creates a single row entry for the main panel addon list.
function Menu:CreateAddonListRow(parent, info, index, isChild)
    local row = CreateFrame("Button", nil, parent)
    local indent = isChild and 20 or 0
    row:SetSize(560, 28)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if isChild then
        bg:SetColorTexture(0.03, 0.05, 0.10, 0.25)
    elseif index % 2 == 0 then
        bg:SetColorTexture(0.06, 0.10, 0.16, 0.5)
    else
        bg:SetColorTexture(0.04, 0.07, 0.12, 0.3)
    end

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.0, 0.6, 1.0, 0.15)

    if isChild then
        local connector = row:CreateTexture(nil, "OVERLAY")
        connector:SetPoint("LEFT", row, "LEFT", indent - 10, 0)
        connector:SetSize(2, 18)
        connector:SetColorTexture(0.2, 0.5, 0.8, 0.5)
    end

    local xOffset = 8 + indent
    if info.icon then
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", xOffset, 0)
        icon:SetSize(20, 20)
        icon:SetTexture(info.icon)
        xOffset = xOffset + 26
    end

    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", row, "LEFT", xOffset, 0)
    nameLabel:SetText(info.name)
    if isChild then
        nameLabel:SetTextColor(0.75, 0.88, 0.98, 1.0)
    else
        nameLabel:SetTextColor(0.9, 0.95, 1.0, 1.0)
    end

    if info.version then
        local verLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        verLabel:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)
        verLabel:SetText("v" .. info.version)
        verLabel:SetTextColor(0.4, 0.55, 0.7, 1.0)
    end

    if info.desc then
        local descLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descLabel:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        descLabel:SetText(info.desc)
        descLabel:SetTextColor(0.55, 0.65, 0.75, 1.0)
        descLabel:SetWidth(220 - indent)
        descLabel:SetJustifyH("RIGHT")
    end

    row:SetScript("OnClick", function()
        if InCombatLockdown() then
            print("|cFFFF4444CombatCoach:|r Cannot open settings during combat.")
            return
        end
        local reg = Menu.registry[info.id]
        if reg and reg._category then
            Settings.OpenToCategory(reg._category:GetID())
        end
    end)

    return row
end
