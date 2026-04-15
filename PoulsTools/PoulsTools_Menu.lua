-- PoulsTools_Menu.lua
-- Handles the Settings panel registration and submenu system
-- WoW API: 12.0.1 (The War Within) - Uses Settings API

PoulsTools = PoulsTools or {}
PoulsTools.Menu = PoulsTools.Menu or {}
local PT = PoulsTools
local Menu = PoulsTools.Menu

-- Registry of all registered sub-addons
Menu.registry = {}

-- ============================================================
-- Public API: Register a sub-addon into PoulsTools
--
-- Usage (from your other addon):
--   PoulsTools.Menu:RegisterAddon({
--       name    = "MyAddon",          -- Display name
--       id      = "MyAddon",          -- Unique ID (usually addon folder name)
--       icon    = "Interface\\Icons\\INV_Misc_Gear_01",  -- optional
--       desc    = "Short description",
--       version = "1.0.0",            -- optional
--       OnBuildUI = function(parent)  -- Called to populate the submenu panel
--           -- Add your widgets to `parent` here
--       end,
--   })
-- ============================================================
function Menu:RegisterAddon(info)
    assert(type(info) == "table", "PoulsTools.Menu:RegisterAddon - info must be a table")
    assert(type(info.id) == "string" and info.id ~= "", "PoulsTools.Menu:RegisterAddon - info.id is required")
    assert(type(info.name) == "string" and info.name ~= "", "PoulsTools.Menu:RegisterAddon - info.name is required")
    assert(type(info.OnBuildUI) == "function", "PoulsTools.Menu:RegisterAddon - info.OnBuildUI must be a function")

    if self.registry[info.id] then
        print("|cFFFF4444PoulsTools:|r Addon '" .. info.id .. "' is already registered. Overwriting.")
    end

    self.registry[info.id] = info

    -- If the main panel is already built, add submenu dynamically
    if self.mainCategory then
        self:AddSubcategory(info)
    end
end

-- ============================================================
-- Build the main PoulsTools Settings panel
-- ============================================================
function Menu:BuildSettingsPanel()
    -- Create the main content frame (shown in the right pane)
    local mainPanel = self:CreateMainPanel()

    -- Register main category with the Settings API
    local category, layout = Settings.RegisterCanvasLayoutCategory(mainPanel, "PoulsTools")
    Settings.RegisterAddOnCategory(category)
    self.mainCategory = category

    -- Register any addons that registered before login
    for id, info in pairs(self.registry) do
        self:AddSubcategory(info)
    end
end

-- ============================================================
-- Create the main panel canvas
-- ============================================================
function Menu:CreateMainPanel()
    local frame = CreateFrame("Frame")
    frame.name = "PoulsTools"

    -- Header banner
    local banner = frame:CreateTexture(nil, "ARTWORK")
    banner:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -10)
    banner:SetSize(580, 80)
    banner:SetColorTexture(0.04, 0.08, 0.15, 0.85)

    -- Decorative accent line
    local accentLine = frame:CreateTexture(nil, "OVERLAY")
    accentLine:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 0, 0)
    accentLine:SetSize(580, 2)
    accentLine:SetColorTexture(0.0, 0.8, 1.0, 1.0)

    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", banner, "TOPLEFT", 16, -16)
    title:SetText("|cFF00CCFFPouls|r|cFFFFFFFFTools|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")

    -- Subtitle
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Addon Management Hub")
    subtitle:SetTextColor(0.6, 0.85, 1.0, 1.0)

    -- Version label (top right)
    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("TOPRIGHT", banner, "TOPRIGHT", -16, -16)
    version:SetText("v" .. (PT.version or "1.0.0"))
    version:SetTextColor(0.5, 0.6, 0.7, 1.0)

    -- Description area
    local descBg = frame:CreateTexture(nil, "BACKGROUND")
    descBg:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -12)
    descBg:SetSize(580, 55)
    descBg:SetColorTexture(0.06, 0.10, 0.18, 0.6)

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", descBg, "TOPLEFT", 16, -10)
    desc:SetWidth(548)
    desc:SetJustifyH("LEFT")
    desc:SetText(
        "Welcome to |cFF00CCFFPoulsTools|r — your central hub for managing addon settings.\n" ..
        "Select a sub-addon from the list on the left to configure it."
    )
    desc:SetTextColor(0.85, 0.90, 0.95, 1.0)

    -- Divider
    local divider = frame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT", descBg, "BOTTOMLEFT", 0, -12)
    divider:SetSize(580, 1)
    divider:SetColorTexture(0.15, 0.25, 0.35, 0.8)

    -- Registered addons section header
    local sectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sectionHeader:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
    sectionHeader:SetText("REGISTERED SUB-ADDONS")
    sectionHeader:SetTextColor(0.4, 0.6, 0.8, 1.0)
    sectionHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    -- Dynamic addon list (populated at runtime)
    self.addonListFrame = frame
    self.addonEntries = {}
    self.addonListAnchor = sectionHeader

    -- Footer
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    footer:SetText("Use |cFFFFFF00/pt|r to open this panel quickly.")
    footer:SetTextColor(0.4, 0.5, 0.6, 1.0)

    return frame
end

-- ============================================================
-- Refresh the addon list displayed on the main panel
-- ============================================================
function Menu:RefreshAddonList()
    if not self.addonListFrame then return end

    -- Clear old entries
    for _, entry in ipairs(self.addonEntries) do
        entry:Hide()
        entry:SetParent(nil)
    end
    self.addonEntries = {}

    local anchor = self.addonListAnchor
    local yOffset = -8
    local count = 0

    for id, info in pairs(self.registry) do
        count = count + 1
        local row = self:CreateAddonListRow(self.addonListFrame, info, count)
        row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - ((count - 1) * 32))
        table.insert(self.addonEntries, row)
    end

    if count == 0 then
        local empty = self.addonListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
        empty:SetText("|cFF888888No sub-addons registered yet.|r")
        table.insert(self.addonEntries, empty)
    end
end

-- ============================================================
-- Create a single row entry for the main panel addon list
-- ============================================================
function Menu:CreateAddonListRow(parent, info, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(560, 28)

    -- Alternating row background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if index % 2 == 0 then
        bg:SetColorTexture(0.06, 0.10, 0.16, 0.5)
    else
        bg:SetColorTexture(0.04, 0.07, 0.12, 0.3)
    end

    -- Highlight on hover
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.0, 0.6, 1.0, 0.15)

    -- Icon (if provided)
    local xOffset = 8
    if info.icon then
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", xOffset, 0)
        icon:SetSize(20, 20)
        icon:SetTexture(info.icon)
        xOffset = xOffset + 26
    end

    -- Name
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", row, "LEFT", xOffset, 0)
    nameLabel:SetText(info.name)
    nameLabel:SetTextColor(0.9, 0.95, 1.0, 1.0)

    -- Version (if provided)
    if info.version then
        local verLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        verLabel:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)
        verLabel:SetText("v" .. info.version)
        verLabel:SetTextColor(0.4, 0.55, 0.7, 1.0)
    end

    -- Description (if provided)
    if info.desc then
        local descLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descLabel:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        descLabel:SetText(info.desc)
        descLabel:SetTextColor(0.55, 0.65, 0.75, 1.0)
        descLabel:SetWidth(220)
        descLabel:SetJustifyH("RIGHT")
    end

    -- Click to open submenu
    row:SetScript("OnClick", function()
        local reg = Menu.registry[info.id]
        if reg and reg._category then
            Settings.OpenToCategory(reg._category:GetID())
        end
    end)

    return row
end

-- ============================================================
-- Add a subcategory (submenu) for a registered addon
-- ============================================================
function Menu:AddSubcategory(info)
    -- Create the sub-panel canvas
    local subPanel = self:CreateSubPanel(info)

    -- Register as a subcategory under the main PoulsTools category
    local subCategory, layout = Settings.RegisterCanvasLayoutSubcategory(
        self.mainCategory,
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

    -- Version
    if info.version then
        local ver = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
        ver:SetText("Version " .. info.version)
        ver:SetTextColor(0.5, 0.65, 0.8, 1.0)
    end

    -- Description below header
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

    -- Content area — let the addon draw its own UI
    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -120)
    contentFrame:SetSize(580, 460)

    -- Call the addon's UI builder
    if info.OnBuildUI then
        local ok, err = pcall(info.OnBuildUI, contentFrame)
        if not ok then
            local errText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 16, -16)
            errText:SetWidth(548)
            errText:SetText("|cFFFF4444Error building UI for " .. info.name .. ":|r\n" .. tostring(err))
        end
    end

    return frame
end
