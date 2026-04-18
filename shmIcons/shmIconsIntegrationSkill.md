# shmIcons Integration Guide (WoW Midnight 12.0.1)

## Overview
shmIcons is a shared UI library managing icon frames with cooldown sweeps, stack counts, range/usability tints, glow effects, and cross-addon snapping. Consumers register icons, push data updates via API calls, and never touch frames directly.

## Setup

### TOC
```
## Dependencies: shmIcons
## SavedVariablesPerCharacter: YourAddonDB
```

### DB Schema (per icon entry)
```lua
{
    x=0, y=0, point="CENTER",  -- position (written back by library)
    size=64,                    -- square size in px (written back by library)
    enabled=true,
    glow_enabled=false,
    spellID=nil,               -- optional, needed by SetStacks issecretvalue fallback
}
```

### Registration
```lua
local icon = shmIcons:Register(ADDON_NAME, id, db, {
    onResize = function(sq) db.size = sq end,
    onMove   = function(db) end,  -- db already updated in-place
})
-- id: any string or number unique within your addon
-- globalID internally = "AddonName:id"
```




## Full Public API

```lua
-- Registration
shmIcons:Register(addonName, id, db, callbacks)   -- returns icon obj
shmIcons:Unregister(addonName, id)

-- Icon content
shmIcons:SetIcon(addonName, id, textureID)         -- number or path; 134400=question mark

-- Cooldowns
shmIcons:SetCooldown(addonName, id, durationObject)         -- DurationObject from C_Spell.GetSpellCooldownDuration
shmIcons:SetCooldownRaw(addonName, id, start, duration)     -- raw values; filters duration<=1.5 (GCD)
shmIcons:SetChargeCooldown(addonName, id, durationObject)   -- cd2 frame: edge only, no swipe (recharging state)

-- Overlays
shmIcons:SetGlow(addonName, id, show)              -- show=bool; respects glowEnabled flag
shmIcons:SetStacks(addonName, id, count)           -- pink bottom-right label; handles issecretvalue
shmIcons:SetRange(addonName, id, inRange)          -- secret bool or nil; nil=white (no target/no range)
shmIcons:SetUsable(addonName, id, usable)          -- secret bool; false=gray overlay

-- Management
shmIcons:ToggleGlowEnabled(addonName, id)          -- returns new state
shmIcons:SetVisible(addonName, id, visible)
shmIcons:ResetIcon(addonName, id, defaultSize)     -- unlinks snap, resets to center
shmIcons:ToggleLock()                              -- global; affects ALL registered icons; returns locked state
shmIcons:IsLocked()
shmIcons:GetAll()                                  -- returns list of all icon info tables
```

---

## Cooldown Patterns

### Item cooldown (TrinketTracker / ItemTracker pattern)
```lua
local start, duration = GetInventoryItemCooldown("player", slotID)
-- or for inventory items:
local start, duration = GetItemCooldown(itemID)

shmIcons:SetCooldownRaw(ADDON_NAME, id, start, duration)
shmIcons:SetGlow(ADDON_NAME, id, not (start and duration and duration > 1.5))
```

### Spell cooldown non-charge (CooldownTracker pattern)
```lua
local cdInfo         = C_Spell.GetSpellCooldown(spellID)
local durationObject = C_Spell.GetSpellCooldownDuration(spellID)

if durationObject and cdInfo and cdInfo.isActive then
    shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
    shmIcons:SetGlow(ADDON_NAME, key, false)
else
    shmIcons:SetCooldown(ADDON_NAME, key, nil)
    shmIcons:SetGlow(ADDON_NAME, key, true)
end
```

### Spell cooldown WITH charges (two-frame technique)
```lua
local cdInfo         = C_Spell.GetSpellCooldown(spellID)
local durationObject = C_Spell.GetSpellCooldownDuration(spellID)
local chargeInfo     = C_Spell.GetSpellCharges(spellID)

if durationObject and cdInfo and cdInfo.isActive then
    -- All charges gone: full sweep
    shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
    shmIcons:SetChargeCooldown(ADDON_NAME, key, nil)
    shmIcons:SetGlow(ADDON_NAME, key, false)
elseif durationObject then
    -- Has charges, one recharging: edge only (no dark overlay)
    shmIcons:SetCooldown(ADDON_NAME, key, nil)
    shmIcons:SetChargeCooldown(ADDON_NAME, key, durationObject)
    shmIcons:SetGlow(ADDON_NAME, key, true)
else
    shmIcons:SetCooldown(ADDON_NAME, key, nil)
    shmIcons:SetChargeCooldown(ADDON_NAME, key, nil)
    shmIcons:SetGlow(ADDON_NAME, key, true)
end

shmIcons:SetStacks(ADDON_NAME, key, chargeInfo.currentCharges)
```

---

## Secret Value Pitfalls

Midnight 12.0.1 protects combat data as "secret values". Comparing or doing arithmetic on them causes errors.

| API Return | Secret? | Safe approach |
|---|---|---|
| `cdInfo.isActive` | Yes | Pass to `if` directly — Lua if/then accepts secrets |
| `cdInfo.startTime`, `cdInfo.duration` | Yes | Never compare; use DurationObject instead |
| `GetSpellCooldownDuration()` | — | Returns DurationObject (opaque); pass to `SetCooldownFromDurationObject` |
| `chargeInfo.currentCharges` | Yes in combat | Use `issecretvalue(count)` guard in `SetStacks`; library handles this |
| `chargeInfo.maxCharges` | No | Safe to compare — structural data |
| `IsSpellInRange()` | Yes | Pass directly to `SetRange`; library passes to `SetVertexColorFromBoolean` |
| `IsSpellUsable()` | Yes | Pass directly to `SetUsable`; library passes to `SetVertexColorFromBoolean` |
| `GetItemCount()` | No | Plain integer — safe to compare |
| `UnitExists("target")` | No | Safe boolean gate before range check |

### Key rules
- **Never** compare `cdInfo.isActive` with `==` or `~=` — use it only as an `if` condition
- **Never** do math on startTime/duration — use DurationObjects
- `durationObject ~= nil` is a **safe** nil check (not a secret comparison)
- `chargeInfo.maxCharges > 1` is **safe** — use to detect charge spells
- Always call `issecretvalue(x)` before comparing any charge/cooldown count
- `SetVertexColorFromBoolean`, `SetAlphaFromBoolean` accept secret booleans safely
- `UnitExists("target")` must gate `IsSpellInRange` calls — returns nil without a target, which crashes `SetVertexColorFromBoolean`

---

## Events to Register

| Addon type | Events |
|---|---|
| Spell tracker | `SPELL_UPDATE_COOLDOWN`, `PLAYER_TARGET_CHANGED`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED` |
| Equipment slot | `ACTIONBAR_UPDATE_COOLDOWN`, `PLAYER_EQUIPMENT_CHANGED`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED` |
| Inventory item | `BAG_UPDATE_COOLDOWN`, `BAG_UPDATE`, `ITEM_COUNT_CHANGED`, `GET_ITEM_INFO_RECEIVED`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED` |

---

## Per-Spec Pattern

```lua
local function GetCurrentSpecID()
    local idx = GetSpecialization()
    if not idx then return 0 end
    return select(1, GetSpecializationInfo(idx)) or 0
end

-- DB structure: YourAddonDB.specs[specID].items[key] = { x,y,point,size,enabled,glow_enabled,... }

local function LoadSpec(specID)
    -- 1. Unregister all current icons
    for key in pairs(tracked) do shmIcons:Unregister(ADDON_NAME, key) end
    tracked = {}
    currentSpecID = specID
    -- 2. Register new spec's icons
    for key, db in pairs(GetSpecData(specID)) do
        if db.enabled then AddItem(key, db, specID) end
    end
    UpdateAll()
end
```

---

## Lock/Unlock
`shmIcons:ToggleLock()` affects ALL icons across ALL addons. Print a shared message:
```lua
local locked = shmIcons:ToggleLock()
print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
```
Slash command `/shm lock` also available from shmIcons itself.

---

## Snap Groups
- Snap data stored in `shmIconsDB` (account-wide SavedVariables in shmIcons.toc)
- Default drag: move icon; snaps edge-to-edge with nearest **same-size** icon; never overlaps other icons
- Shift+drag: live resizes the dragged icon to match the nearest icon's size; after resize, normal edge-snap with same-size icons applies; size is committed on drop
- Ctrl+drag: corner-attach mode — icon resized to 30% of target, raised strata; only snaps to same-size icons; overlap at corners is intentional
- If an icon is dropped without a snap and without ctrl held, it is automatically pushed out of any bounding-box overlap
