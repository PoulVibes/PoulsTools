# CombatCoach

**A central Settings hub for managing your WoW addons.**  
WoW Interface Version: **12.0.1** (The War Within)

---

## Installation

1. Copy the `CombatCoach` folder into:  
   `World of Warcraft/_retail_/Interface/AddOns/CombatCoach/`
2. Enable **CombatCoach** in the AddOns list at character select.
3. Log in — a new **CombatCoach** entry will appear in your game's Settings (Escape → Options → AddOns section).

---

## Usage

- Press **Escape → Options** and scroll to the **AddOns** section in the left panel.
- Click **CombatCoach** to see the hub and all registered sub-addons.
- Click a sub-addon entry to jump to its settings page.
- Type `/pt` or `/CombatCoach` in chat to open the panel directly.

---

## Files

| File | Purpose |
|---|---|
| `CombatCoach.toc` | AddOn manifest (required by WoW) |
| `CombatCoach.lua` | Core: events, slash commands, saved variables |
| `CombatCoach_Menu.lua` | Settings panel & subcategory (submenu) system |
| `CombatCoach_Widgets.lua` | Reusable UI helpers for sub-addons |
| `ExampleAddon_CombatCoach.lua` | Full working example — shows how to integrate |

---

## Integrating Your Addon

In your addon (which must load **after** CombatCoach), call:

```lua
-- Guard in case CombatCoach isn't installed
if not CombatCoach then return end

CombatCoach.Menu:RegisterAddon({
    name      = "MyAddon",          -- Display name in the menu
    id        = "MyAddon",          -- Unique ID (use your addon's folder name)
    desc      = "What it does",     -- Short description (optional)
    version   = "1.0.0",            -- Version string (optional)
    icon      = "Interface\\Icons\\INV_Misc_Gear_01",  -- Icon texture (optional)
    accentColor = {1.0, 0.5, 0.0, 1.0},  -- Header accent bar color RGBA (optional)

    OnBuildUI = function(parent)
        -- `parent` is a Frame — add your widgets here.
        -- Use CombatCoach.Widgets helpers (see below) or raw WoW API frames.
        local W = CombatCoach.Widgets
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

In your `.toc` file, declare CombatCoach as a dependency so it loads first:

```
## Dependencies: CombatCoach
```

Or as optional (gracefully skips if not present):

```
## OptionalDeps: CombatCoach
```

---

## Widget Helpers (`CombatCoach.Widgets`)

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

CombatCoach stores its own data in `CombatCoachDB` (defined in the `.toc`).  
Each sub-addon manages its own `SavedVariables` independently in its own `.toc`.

---

## Slash Commands

| Command | Action |
|---|---|
| `/pt` | Open CombatCoach settings |
| `/pt options` | Open CombatCoach settings |
| `/pt help` | Print command list |

---

## Detailed Integration Guide

This section collects best practices, examples, and troubleshooting tips to make integrating a new addon into the CombatCoach Menu system quick and predictable.

### Quick Checklist
- **Guard:** In your addon, check `if not CombatCoach then return end` to skip when CombatCoach isn't installed.
- **Declare Load Order:** Add `## Dependencies: CombatCoach` to your `.toc` (or `RequiredDeps`).
- **Register:** Call `CombatCoach.Menu:RegisterAddon({...})` and implement `OnBuildUI(parent)`.
- **SavedVariables:** Keep your own saved variables (do not rely on CombatCoach' DB).

### OnBuildUI pattern (recommended)
`OnBuildUI` receives a single `parent` frame you should use as the anchor for your UI. Use the `CombatCoach.Widgets` helpers to ensure a consistent look:

```lua
local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
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

CombatCoach.Menu:RegisterAddon({
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
- If a helper is missing, verify CombatCoach loaded before your addon (dependencies in `.toc`) and that `CombatCoach_Widgets.lua` is present.
- Use `ExampleAddon_CombatCoach.lua` as a minimal working reference.

---

## Integration Lessons — CooldownTracker Case Study

This repository's recent work integrating `CooldownTracker` into CombatCoach surfaced several practical patterns and APIs you can reuse when integrating other addons. Below are the key lessons, code patterns, and pitfalls discovered while copying the style of `SBA_Simple` and wiring a live, dynamic UI.

### Key Patterns

- **Guard & Load Order:** Always check `if not CombatCoach then return end` at the top of your CombatCoach integration file and declare `## Dependencies: CombatCoach` in your `.toc` so load order is predictable.

- **Central Command Handler / Public API:** Put slash parsing and behavior in a function (for example `CooldownTracker_HandleCommand(msg)`) and expose small public helpers (`CooldownTracker_Add`, `CooldownTracker_Remove`, `CooldownTracker_ToggleLock`, `CooldownTracker_Reset`, etc.). This lets the settings UI call your logic directly instead of invoking `SlashCmdList`. Don't forget to always make your buttons have actions.

- **Dynamic UI via Change Listeners:** If your runtime state can change outside the settings panel, expose a small listener API so the CombatCoach UI can refresh dynamically. In the CooldownTracker example we added:

    - `CooldownTracker_RegisterChangeListener(fn)` — register a callback called when trackers change (add/remove).
    - `CooldownTracker_GetTrackedSpells(specID)` — return an array of tracked entries for the current spec.

    Usage pattern in `OnBuildUI`:

    ```lua
    CooldownTracker_RegisterChangeListener(BuildTrackedList)
    -- BuildTrackedList reads CooldownTracker_GetTrackedSpells() and rebuilds rows
    ```

- **CombatCoach Widget Anchor Chaining:** `CombatCoach.Widgets` helpers follow the (parent, anchor, yOffset, ...) pattern and return a frame (or row) you should assign to `anchor` for the next widget. If you don't reassign and update `y`, multiple rows will overlap.

    Example:

    ```lua
    local anchor = parent
    local div, dy = W:SectionHeader(parent, anchor, y, "Header")
    anchor = div; y = dy
    anchor = W:Checkbox(parent, anchor, y, "Label", nil, getValue, setValue)
    y = -6
    ```

- **EditBox internals:** `W:EditBox` exposes `row.box` and `row.placeholder`. Use `edit.box:GetText()` when a button is clicked (don't rely solely on the `setValue` callback). Clear focus and reset text after use (e.g., `edit.box:ClearFocus(); edit.box:SetText("")`).

- **Let `shmIcons` be authoritative for icon movement:** If you use `shmIcons` for icons, call `shmIcons:Register` to create icons, `shmIcons:RestoreSnapGroups()` after registering, and `shmIcons:ToggleLock()` to toggle lock state. Do not override icon frame drag handlers, reparent icon frames, or disable mouse handling — doing so breaks snap/move behavior.

### SBA_Simple Lessons Observed

- `SBA_Simple` demonstrates persisting per-spec DB tables and seeding per-spec entries from global values when needed. Follow the `db.specs[specID]` pattern for per-specialization settings.
- Preferred `shmIcons` usage: register icons once and use `shmIcons:SetVisible`/`SetIcon`/`SetCooldown`/`SetGlow` to update visuals.
- Use `parent:HookScript("OnShow", ...)` to synchronize controls that may change outside the settings UI (slider values, lock button label, etc.).

### Practical Tips & Pitfalls

- **Anchor chaining mistakes cause overlapping rows.** Always reassign `anchor` to the return value of widget helpers.
- **Don't call `SlashCmdList` from UI.** Instead call a central handler function or a small public API so behavior is consistent between slash and UI.
- **When building dynamic lists:** create a `trackedContainer` frame, create/hide per-row frames, update the container's height, and reanchor subsequent sections (Actions header) to the container's bottom.


### Files touched in this case study

- `CooldownTracker/CooldownTracker.lua` — added change-listener registration, public wrappers, and notifications on add/remove.
- `CooldownTracker/CooldownTracker_CombatCoach.lua` — implemented a dynamic tracked-abilities list that shows icon + name and registers for runtime updates.
- `CombatCoach/CombatCoach_Widgets.lua` — `EditBox` exposes `row.box`/`row.placeholder` and propagates `setValue` on focus-lost (pattern already present; follow it as a best-practice).

### How to test (in-game)

1. Reload UI and open CombatCoach → CooldownTracker.
2. Add a tracker via the Add Tracker button or `/cdt Fireball` and confirm the tracked list updates with an icon and name.
3. Unlock icons with the Lock button and drag an icon; it should snap to nearby icons within threshold.
4. Toggle the glow checkbox in the list to enable/disable ready glow for that ability.
5. Reset a single icon and `reset all` to verify positions and sizes restore.

---

