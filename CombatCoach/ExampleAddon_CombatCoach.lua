-- MyAddon_CombatCoach.lua
-- Example: How to register MyAddon into CombatCoach
-- Drop this file into your own addon folder and add it to your .toc AFTER CombatCoach loads.
--
-- .toc load order tip:
--   ## Dependencies: CombatCoach
--   ## RequiredDeps: CombatCoach

-- ============================================================
-- Guard: only register if CombatCoach is loaded
-- ============================================================
if not CombatCoach then return end

-- ============================================================
-- Saved variables for this addon (defined in your own .toc)
-- MyAddonDB = MyAddonDB or {}
-- ============================================================

local function OnBuildUI(parent)
    -- Alias the widget library for convenience
    local W = CombatCoach.Widgets

    -- Anchor starts at parent's top-left
    local anchor = parent
    local y = 0

    -- ---- Section: General ----
    local divider, dy = W:SectionHeader(parent, anchor, y, "General")
    anchor = divider
    y = dy

    anchor = W:Checkbox(
        parent, anchor, y,
        "Enable MyAddon",
        "Turn MyAddon on or off.",
        function() return MyAddonDB and MyAddonDB.enabled ~= false end,
        function(val)
            MyAddonDB = MyAddonDB or {}
            MyAddonDB.enabled = val
        end
    )
    y = -6

    -- ---- Section: Display ----
    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Display")
    anchor = div2
    y = dy2

    anchor = W:Slider(
        parent, anchor, y,
        "Opacity", 0, 100, 5,
        function() return (MyAddonDB and MyAddonDB.opacity) or 100 end,
        function(val)
            MyAddonDB = MyAddonDB or {}
            MyAddonDB.opacity = val
        end,
        "%d%%"
    )
    y = -8

    anchor = W:Dropdown(
        parent, anchor, y,
        "Anchor Position",
        {
            {text = "Top Left",     value = "TOPLEFT"},
            {text = "Top Right",    value = "TOPRIGHT"},
            {text = "Bottom Left",  value = "BOTTOMLEFT"},
            {text = "Bottom Right", value = "BOTTOMRIGHT"},
            {text = "Center",       value = "CENTER"},
        },
        function() return (MyAddonDB and MyAddonDB.anchor) or "TOPLEFT" end,
        function(val)
            MyAddonDB = MyAddonDB or {}
            MyAddonDB.anchor = val
        end
    )
    y = -8

    -- ---- Section: Status ----
    local div3, dy3 = W:SectionHeader(parent, anchor, y, "Status")
    anchor = div3
    y = dy3

    W:StatusLabel(parent, anchor, y, "Plugin Status:", true, "Active")
    y = -6

    -- ---- Action Buttons ----
    local div4, dy4 = W:SectionHeader(parent, anchor, y, "Actions")
    anchor = div4
    y = dy4

    W:Button(parent, anchor, y, "Reset to Defaults", function()
        MyAddonDB = {}
        print("|cFF00CCFFMyAddon|r settings reset to defaults.")
    end)
end

-- ============================================================
-- Register with CombatCoach
-- ============================================================
CombatCoach.Menu:RegisterAddon({
    name       = "MyAddon",
    id         = "MyAddon",
    desc       = "Example sub-addon for CombatCoach",
    version    = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("MyAddon", "Version")) or "1.0.0",
    icon       = "Interface\\Icons\\INV_Misc_Gear_01",
    -- accentColor = {1.0, 0.5, 0.0, 1.0},  -- optional: override header accent color (R,G,B,A)
    OnBuildUI  = OnBuildUI,
})
