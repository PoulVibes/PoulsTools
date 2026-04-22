# SBAS Override GUI — Agent Reference

## Files Involved

| File | Purpose |
|---|---|
| `SBA_Simple_OverrideGUI.lua` | Graphical priority-list builder (the GUI) |
| `SBA_Simple.lua` | Runtime override execution + raw text override editor |
| `PoulsTools_SBA_Simple.toc` | Addon manifest — `SBA_Simple.lua` must load before `SBA_Simple_OverrideGUI.lua` |

---

## Entry Points

- `/sbas override_gui` → calls `OpenGUI()` in `SBA_Simple_OverrideGUI.lua`
- `/sbas override` → opens raw text editor (`SBAS_OverrideFrame`) in `SBA_Simple.lua`
- `_G.SBAS_OpenOverrideGUI` — public alias to `OpenGUI(specID?)`

---

## Data Model

```
SBA_SimpleDB
├── gui[specID][]            -- GUI rules (source of truth for GUI builder)
│   └── { spellID, name, conditions[] }
│       └── condition: { type, negate, value, spell, targetID, resource, operator, plugin, junction, lparen, rparen }
├── specs[specID].overrideCode  -- generated/saved Lua code per spec
└── overrideCode             -- legacy top-level mirror
```

- `workingRules` is a deep copy of `SBA_SimpleDB.gui[editSpecID]` edited in memory.
- On **Save & Apply**: `workingRules` is written back to DB and Lua code is compiled live.
- On **Preview Code**: code is generated but only shown in the text editor — NOT saved unless user clicks "Override Logic" in that editor.

---

## Condition Type Registry (`COND_TYPES`)

Defined at top of `SBA_Simple_OverrideGUI.lua`. Each entry:

```lua
{ id, label,
  needsSpell    = true,   -- shows This Spell / Other Spell toggle
  needsValue    = true,   -- shows numeric input; use valueLabel/default
  needsResource = true,   -- shows Chi/Energy selector + operator + value
  needsPlugin   = true,   -- shows plugin/proc dropdown
  generate = function(cond, ruleSpellID) → "Lua fragment string" end
}
```

`COND_BY_ID[id]` is the lookup table. `ResolveSpell(cond, spellID)` resolves `"this"` vs explicit spell ID.

### Current Condition Types
| id | Label | Output fragment |
|---|---|---|
| `on_cd` | On Cooldown | `C_Spell.GetSpellCooldown(id).isActive` |
| `reactive_enabled` | Reactive Spell Enabled | `C_Spell.GetSpellCooldown(id).isEnabled` |
| `usable` | Is Usable | `C_Spell.IsSpellUsable(id)` |
| `talented` | Talented | `IsPlayerSpell(id)` |
| `last_combo_eq` | Last Combo Strike = Spell | `LastComboStrikeSpellID == id` |
| `sba_suggests` | SBA Suggests This Spell | `spellID == id` |
| `resource` | Resource Check | `chi/currentEnergy >= value` |
| `plugin` | Plugin / Proc | Zenith/BOK/RWK/DOCJ booleans |

**To add a condition type:** append a new entry to the `COND_TYPES` table. If it needs a custom input, add the appropriate `needs*` flag and handle it in `CreateCondInputArea`.

---

## GUI Architecture

```
guiFrame  (SBAS_OverrideGUI_Frame)   680×560 min, resizable
├── Left Panel (leftSF ScrollFrame)
│   └── leftChild (scroll content)
│       └── rowFrames[] — CreateRowFrame() pool, one per rule
├── Right Panel (rightPanel / rp)
│   ├── header FontString
│   ├── condRowPool[] — condition rows (pooled)
│   ├── condJunctionPool[] — AND/OR toggles between rows (pooled)
│   ├── condGroupBoxPool[] — backdrop boxes for paren groups (pooled)
│   ├── addCondBtn
│   └── condInputArea — CreateCondInputArea() (created once, reused)
└── Footer buttons: Save & Apply | Preview Code | Clear All Rules
```

### Size constants (top of file)
```lua
GUI_W, GUI_H     = 680, 560   -- default size
LEFT_W, RIGHT_W  = 388, 268   -- default panel widths
PAD              = 6
ROW_H            = 72          -- height of each rule row
GUI_MIN_W/H      = 680, 560
MIN_LEFT_W/RIGHT_W = 320, 240
```

`GetPanelWidths(totalWidth)` recalculates left/right widths proportionally on resize. `LayoutGUI()` (inside `CreateGUI`) is called from `OnSizeChanged` to refit all child frames.

---

## Key State Variables (file-local in OverrideGUI.lua)

| Variable | Meaning |
|---|---|
| `workingRules` | In-memory copy of rules being edited |
| `editSpecID` | Spec being edited |
| `selectedIdx` | 1-based index of selected rule row (0 = none) |
| `isAddingCond` | Whether condition input area is visible |
| `selectedCondIdx` | nil = new condition, number = editing existing index |
| `rowFrames[]` | Pooled rule-row frames |
| `condRowPool[]` | Pooled condition-row frames in right panel |
| `condJunctionPool[]` | Pooled AND/OR junction toggle buttons |
| `condGroupBoxPool[]` | Pooled backdrop frames for paren group visualization |

---

## Key Functions

### `RefreshRuleList()`
Rebuilds left panel rows. Pools `rowFrames`, calls `UpdateRowFrame` for each rule.  
Left-click on row → sets `selectedIdx`, hides cond editor, calls both refresh functions.

### `RefreshRightPanel()`
Rebuilds right panel for `workingRules[selectedIdx]`.  
- Iterates `conds[]`; for each: places junction toggle (i>1), then a `condRowPool` row.
- Each row: `_lpBtn` / `_rpBtn` (left/right click: increment mod 4 / decrement to 0), `_lbl` (condition text), `_xb` (remove).
- Left-click on a condition row: sets `selectedCondIdx = i`, `isAddingCond = true`, re-enters `RefreshRightPanel` to show editor populated with that condition.
- After rows: calls `DrawConditionGroupBoxes(spans, rowYTops)`.
- Then places `addCondBtn` and (if `isAddingCond`) `condInputArea`.

### `AnalyzeParenGroups(conds)`
Returns `spans[]` (matched open/close pairs with depth), `unmatchedOpens{}`, `unmatchedCloses{}`.  
Unmatched entries cause red highlighting on the relevant paren buttons.

### `DrawConditionGroupBoxes(spans, rowYTops)`
Hides old boxes, draws a backdrop box per matched span. Outer groups draw first (lower frame level); depth cycling color from `GROUP_BOX_COLORS[3]`.

### `GenerateCode(rules)`
Compiles `workingRules` into a Lua string. Preamble declares `spellID`, `chi`.  
Each rule generates: `if lp .. fragment .. rp [and/or ...] then return spellID end`.  
No conditions → `return spellID  -- unconditional` (blocks everything below).

### `CreateCondInputArea(parent)`
Returns frame `f` with public interface:
- `f.Reset()` — clears all fields
- `f.Populate(cond)` — fills fields from an existing condition table
- `f.GetSelectedType/GetValue/GetNegate/GetResource/GetOperator/GetPlugin/GetSpell` — read current selections
- `f.RefreshSize()` — resizes widgets to current `GetRightPanelWidth()`
- `f.confirmBtn` — set text to "Add" or "Update"; `OnClick` is wired in `RefreshRightPanel`

---

## Preview vs Save Flow

**Preview Code button:**
1. Calls `GenerateCode(workingRules)`.
2. Calls `SBA_Simple_ShowOverridePreview(code, editSpecID, specName)` in `SBA_Simple.lua`.
3. Raw override editor opens showing the generated code with `(Preview)` suffix in title.
4. Closing without clicking "Override Logic" → `OnHide` clears `overrideEditorPreviewMode` (discards).
5. Clicking "Override Logic" → saves to DB and compiles.

**Save & Apply button:**
- Writes `workingRules` directly to `SBA_SimpleDB.gui[editSpecID]`.
- Calls `GenerateCode`, writes to `SBA_SimpleDB.specs[editSpecID].overrideCode`.
- Calls `SBA_Simple_SetOverrideCode(code)` if editing current spec (compiles live).

---

## Public API Between Files

| Symbol | Defined in | Used by |
|---|---|---|
| `SBA_Simple_SetOverrideCode(code)` | `SBA_Simple.lua` | GUI Save & Apply |
| `SBA_Simple_ShowOverrideForSpec(specID, name)` | `SBA_Simple.lua` | (slash command) |
| `SBA_Simple_ShowOverridePreview(code, specID, name)` | `SBA_Simple.lua` | GUI Preview Code button |
| `_G.SBAS_OpenOverrideGUI` | `SBA_Simple_OverrideGUI.lua` | External callers |

---

## How to Add / Modify Features

### Add a new condition type
1. Append to `COND_TYPES` in `SBA_Simple_OverrideGUI.lua`.
2. If it needs a new UI input kind, add a `needs*` flag and handle in `CreateCondInputArea`.
3. `COND_BY_ID` is auto-built from `COND_TYPES`.

### Change rule-row layout
Edit `CreateRowFrame` and `UpdateRowFrame`. Row height is `ROW_H = 72`.

### Change condition-row layout
Edit the pool creation block inside `RefreshRightPanel` (look for `condRowPool[rowIdx]`).

### Add a footer button
Add it in `CreateGUI()` after the existing footer buttons, anchored relative to `saveBtn` or `f`.

### Change paren group colors
Edit `GROUP_BOX_COLORS` at the top of `DrawConditionGroupBoxes`.

### Change how `GenerateCode` works
Edit the `GenerateCode(rules)` function. The preamble variables (`spellID`, `chi`) are always emitted; add others if new condition types need them (e.g., `currentEnergy`).

---

## WoW API Notes

- `C_Spell.GetSpellCooldown(id)` returns `{ isActive, isEnabled, startTime, duration }`
- `C_Spell.IsSpellUsable(id)` → boolean
- `C_Spell.GetSpellIDForSpellIdentifier(name)` → id (12.x+)
- `C_Spell.GetSpellName(id)`, `C_Spell.GetSpellTexture(id)`
- `IsPlayerSpell(id)` → talented check
- Frame backdrop: use `"BackdropTemplate"` + `SetBD()` helper (defined in this file)
- `SetResizeBounds` (12.x) / `SetMinResize` (older) — handled with fallback in `CreateGUI`
