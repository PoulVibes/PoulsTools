# PoulsTools

**A central Settings hub for managing your WoW addons.**  
WoW Interface Version: **12.0.1** (The War Within)

---

## Installation

1. Copy the `PoulsTools` folder into:  
   `World of Warcraft/_retail_/Interface/AddOns/PoulsTools/`
2. Enable **PoulsTools** in the AddOns list at character select.
3. Log in — a new **PoulsTools** entry will appear in your game's Settings (Escape → Options → AddOns section).

---

## Usage

- Press **Escape → Options** and scroll to the **AddOns** section in the left panel.
- Click **PoulsTools** to see the hub and all registered sub-addons.
- Click a sub-addon entry to jump to its settings page.
- Type `/pt` or `/poulstools` in chat to open the panel directly.

---

## Files

| File | Purpose |
|---|---|
| `PoulsTools.toc` | AddOn manifest (required by WoW) |
| `PoulsTools.lua` | Core: events, slash commands, saved variables |
| `PoulsTools_Menu.lua` | Settings panel & subcategory (submenu) system |
| `PoulsTools_Widgets.lua` | Reusable UI helpers for sub-addons |
| `ExampleAddon_PoulsTools.lua` | Full working example — shows how to integrate |

---

## Integrating Your Addon

In your addon (which must load **after** PoulsTools), call:

```lua
-- Guard in case PoulsTools isn't installed
if not PoulsTools then return end

PoulsTools.Menu:RegisterAddon({
    name      = "MyAddon",          -- Display name in the menu
    id        = "MyAddon",          -- Unique ID (use your addon's folder name)
    desc      = "What it does",     -- Short description (optional)
    version   = "1.0.0",            -- Version string (optional)
    icon      = "Interface\\Icons\\INV_Misc_Gear_01",  -- Icon texture (optional)
    accentColor = {1.0, 0.5, 0.0, 1.0},  -- Header accent bar color RGBA (optional)

    OnBuildUI = function(parent)
        -- `parent` is a Frame — add your widgets here.
        -- Use PoulsTools.Widgets helpers (see below) or raw WoW API frames.
        local W = PoulsTools.Widgets
        local anchor = parent

        local div, dy = W:SectionHeader(parent, anchor, 0, "General")
        W:Checkbox(parent, div, dy, "Enable", nil,
            function() return MyAddonDB.enabled end,
            function(v) MyAddonDB.enabled = v end
        )
    end,
})
```

### Load Order

In your `.toc` file, declare PoulsTools as a dependency so it loads first:

```
## Dependencies: PoulsTools
```

Or as optional (gracefully skips if not present):

```
## OptionalDeps: PoulsTools
```

---

## Widget Helpers (`PoulsTools.Widgets`)

All helpers take `(parent, anchor, yOffset, ...)` and return the created frame to use as the next anchor.

| Helper | Description |
|---|---|
| `W:SectionHeader(parent, anchor, y, text)` | Labeled divider section. Returns `(line, yStep)` |
| `W:Checkbox(parent, anchor, y, label, tooltip, getValue, setValue)` | Toggle checkbox |
| `W:Slider(parent, anchor, y, label, min, max, step, getValue, setValue, fmt)` | Numeric slider |
| `W:Dropdown(parent, anchor, y, label, items, getValue, setValue)` | Dropdown selector |
| `W:EditBox(parent, anchor, y, label, placeholder, getValue, setValue)` | Text input |
| `W:StatusLabel(parent, anchor, y, label, status, statusText)` | Colored status dot |
| `W:Button(parent, anchor, y, label, onClick)` | Styled action button |

---

## Saved Variables

PoulsTools stores its own data in `PoulsToolsDB` (defined in the `.toc`).  
Each sub-addon manages its own `SavedVariables` independently in its own `.toc`.

---

## Slash Commands

| Command | Action |
|---|---|
| `/pt` | Open PoulsTools settings |
| `/pt options` | Open PoulsTools settings |
| `/pt help` | Print command list |

---

## Detailed Integration Guide

This section collects best practices, examples, and troubleshooting tips to make integrating a new addon into the PoulsTools Menu system quick and predictable.

### Quick Checklist
- **Guard:** In your addon, check `if not PoulsTools then return end` to skip when PoulsTools isn't installed.
- **Declare Load Order:** Add `## Dependencies: PoulsTools` to your `.toc` (or `OptionalDeps`).
- **Register:** Call `PoulsTools.Menu:RegisterAddon({...})` and implement `OnBuildUI(parent)`.
- **SavedVariables:** Keep your own saved variables (do not rely on PoulsTools' DB).

### OnBuildUI pattern (recommended)
`OnBuildUI` receives a single `parent` frame you should use as the anchor for your UI. Use the `PoulsTools.Widgets` helpers to ensure a consistent look:

```lua
local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    local anchor = parent
    local y = 0

    -- Section header returns a divider "line" texture and a y-offset:
    local div, dy = W:SectionHeader(parent, anchor, y, "General")
    anchor = div
    y = dy

    -- Checkbox: get/set from your saved DB
    anchor = W:Checkbox(parent, anchor, y, "Enable", nil,
        function() return MyAddonDB.enabled end,
        function(v) MyAddonDB.enabled = v; if MyAddon_SetEnabled then MyAddon_SetEnabled(v) end
    )
    y = -6

    -- Slider: returns the row (it exposes row.slider and row.valText so you can refresh them)
    local sizeRow = W:Slider(parent, anchor, y, "Icon Size", 16, 128, 1,
        function() return MyAddonDB.size end,
        function(v) MyAddonDB.size = v; if MyAddon_SetSize then MyAddon_SetSize(v) end
    )
    anchor = sizeRow
    y = -8

    -- Keep UI controls in sync when the panel is shown (e.g., user manually resized an icon)
    parent:HookScript("OnShow", function()
        local sz = MyAddonDB.size or 64
        if sizeRow and sizeRow.slider then
            sizeRow.slider:SetValue(sz)
            if sizeRow.valText then sizeRow.valText:SetText(string.format("%d", sz)) end
        end
    end)
end

PoulsTools.Menu:RegisterAddon({
    name = "MyAddon",
    id   = "MyAddon",
    desc = "Does useful things",
    version = "1.0.0",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    OnBuildUI = OnBuildUI,
})
```

### Dynamic controls and live updates
- If your addon exposes runtime helpers (for example `MyAddon_SetEnabled(enabled)` or `MyAddon_SetSize(size)`), call them from the widget `setValue` callbacks so changes apply immediately.
- `W:Slider` now exposes `row.slider` and `row.valText` so you can update the displayed value from `OnShow` or other hooks.
- When your UI needs to reflect state that can change outside the settings panel (e.g., icon resized by dragging), update the saved DB and call any public helper to re-create or adjust visuals (for example, `shmIcons:SetVisible` / `shmIcons:Register`).

### Per-specialization data
- If your addon keeps per-spec settings, follow the pattern `MyAddonDB.specs[specID] = { ... }`. Create entries on demand and seed from any legacy global override if needed.
- Provide a small public opener function (for example `MyAddon_ShowOverrideForSpec(specID, displayName)`) so other UI code can open a per-spec editor programmatically.

### Class / Spec Reference
For an authoritative, localization-independent list of class specializations and their API IDs, see the repository's detailed reference:

[World of Warcraft: API & Specialization Reference](../skills/WOW%20API%20documentation/WoW_Detailed_Reference_Skill.md)

The referenced markdown includes a table mapping class, spec name, and `API ID` — use the numeric ID first when building per-spec mappings to avoid localization issues.


### shmIcons tips (if your addon uses shared icons)
- Register icons with `shmIcons:Register(addonName, id, db, { onResize = func, onMove = func })`.
- Toggle visibility with `shmIcons:SetVisible(addonName, id, visible)`.
- Use `shmIcons:IsLocked()` to set initial lock/unlock button text, and `shmIcons:ToggleLock()` to toggle.
- When resizing or moving, persist `db.size`, `db.x`, `db.y`, and `db.point` in your saved variables so OnBuildUI can reflect them.

### Troubleshooting
- If a helper is missing, verify PoulsTools loaded before your addon (dependencies in `.toc`) and that `PoulsTools_Widgets.lua` is present.
- Use `ExampleAddon_PoulsTools.lua` as a minimal working reference.


