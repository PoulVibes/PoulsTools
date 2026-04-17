-- SBA_Simple_PoulsTools.lua
-- PoulsTools integration for SBA_Simple

if not PoulsTools then return end

SBA_SimpleDB = SBA_SimpleDB or {}

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    local anchor = parent
    local y = 0

    local header, dy = W:SectionHeader(parent, anchor, y, "SBA Simple")
    anchor = header
    y = dy

    anchor = W:Checkbox(parent, anchor, y,
        "Enabled",
        "Enable the SBA Simple icon.",
        function() return (SBA_SimpleDB and SBA_SimpleDB.enabled) ~= false end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.enabled = val end
    )
    y = -6

    anchor = W:Slider(parent, anchor, y,
        "Icon Size", 16, 128, 1,
        function() return (SBA_SimpleDB and SBA_SimpleDB.size) or 64 end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.size = val end,
        "%d"
    )
    y = -8

    anchor = W:Dropdown(parent, anchor, y,
        "Anchor Point",
        {
            {text = "CENTER", value = "CENTER"},
            {text = "TOPLEFT", value = "TOPLEFT"},
            {text = "TOPRIGHT", value = "TOPRIGHT"},
            {text = "BOTTOMLEFT", value = "BOTTOMLEFT"},
            {text = "BOTTOMRIGHT", value = "BOTTOMRIGHT"},
            {text = "LEFT", value = "LEFT"},
            {text = "RIGHT", value = "RIGHT"},
            {text = "TOP", value = "TOP"},
            {text = "BOTTOM", value = "BOTTOM"},
        },
        function() return (SBA_SimpleDB and SBA_SimpleDB.point) or "CENTER" end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.point = val end
    )
    y = -8

    anchor = W:Checkbox(parent, anchor, y,
        "Glow Enabled",
        "Show glow around the icon.",
        function() return (SBA_SimpleDB and SBA_SimpleDB.glow_enabled) end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.glow_enabled = val end
    )
    y = -6

    W:Button(parent, anchor, y, "Edit Override Logic", function()
        if overrideFrame then
            overrideFrame:Show()
        else
            print("|cFFFF4444SBA_Simple:|r Override editor not available.")
        end
    end)
    y = -8

    W:Button(parent, anchor, y, "Reset Position", function()
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.x = 0
        SBA_SimpleDB.y = 0
        SBA_SimpleDB.point = "CENTER"
        print("|cFF00CCFFSBA_Simple|r position reset to defaults.")
    end)
end

PoulsTools.Menu:RegisterAddon({
    name    = "SBA Simple",
    id      = "SBA_Simple",
    desc    = "Displays the next suggested cast using shmIcons.",
    version = "1.0.0",
    icon    = "Interface\\Icons\\INV_Misc_Gear_01",
    OnBuildUI = OnBuildUI,
})
