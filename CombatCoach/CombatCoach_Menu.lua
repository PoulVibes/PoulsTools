-- CombatCoach_Menu.lua
-- Settings panel registration and submenu system.

CombatCoach = CombatCoach or {}
CombatCoach.Menu = CombatCoach.Menu or {}
local CC = CombatCoach
local Menu = CombatCoach.Menu

-- Registry of all registered sub-addons
Menu.registry = {}
Menu.mainPanelContentFns    = {}    -- fns injected inline onto the main panel
Menu.mainPanelExtraFrames   = {}    -- frames built by those fns (rebuilt on refresh)
Menu.mainPanelContentPending = false

-- Registers a sub-addon into CombatCoach.
function Menu:RegisterAddon(info)
    assert(type(info) == "table", "CombatCoach.Menu:RegisterAddon - info must be a table")
    assert(type(info.id) == "string" and info.id ~= "", "CombatCoach.Menu:RegisterAddon - info.id is required")
    assert(type(info.name) == "string" and info.name ~= "", "CombatCoach.Menu:RegisterAddon - info.name is required")
    assert(type(info.OnBuildUI) == "function", "CombatCoach.Menu:RegisterAddon - info.OnBuildUI must be a function")

    if self.registry[info.id] then
        print("|cFFFF4444CombatCoach:|r Addon '" .. info.id .. "' is already registered. Overwriting.")
    end

    self.registry[info.id] = info

    -- If the main panel is already built, add submenu dynamically
    if self.mainCategory then
        self:AddSubcategory(info)
    end
end

-- Registers content to appear inline on the main panel.
function Menu:RegisterMainPanelContent(fn)
    assert(type(fn) == "function", "CombatCoach.Menu:RegisterMainPanelContent - fn must be a function")
    table.insert(self.mainPanelContentFns, fn)
    if self.mainCategory then
        self:RefreshMainPanelContent()
    end
end

-- Builds the main CombatCoach Settings panel.
function Menu:BuildSettingsPanel()
    local mainPanel = self:CreateMainPanel()

    local category, layout = Settings.RegisterCanvasLayoutCategory(mainPanel, "CombatCoach")
    Settings.RegisterAddOnCategory(category)
    self.mainCategory = category

    for id, info in pairs(self.registry) do
        if not info.parentId then
            self:AddSubcategory(info)
        end
    end

    for id, info in pairs(self.registry) do
        if info.parentId then
            self:AddSubcategory(info)
        end
    end
end
