---
name: wow-addon-single-spec
description: Guide for making a World of Warcraft addon that only runs for a single specialization.
---

# How to make an addon specific to a single specialization (spec)

This short how-to explains the common pattern to ensure an addon only runs while the player is a specific class/spec (for example: Monk — Windwalker). It covers safe startup checks, runtime gating, and recommended best practices.

## Key ideas
- Abort early on load if the player's class is different (avoid runtime errors).
- Gate runtime behavior on the active specialization (enable/disable features when respeccing).
- Create your event frame early so helper functions can register/unregister events without nil errors.
- Register only the events needed while the addon is active (reduce overhead and avoid spurious handling for other classes).

Note about timing: do not rely on `GetSpecialization()` during `ADDON_LOADED` — the player's specialization may not be initialized by the UI yet. Perform the first specialization check at `PLAYER_LOGIN` (or later), and use `PLAYER_SPECIALIZATION_CHANGED` / `ACTIVE_TALENT_GROUP_CHANGED` to handle runtime changes.

## Useful APIs
- `UnitClass("player")` → returns (localizedName, classToken) where `classToken` is e.g. `"MONK"`.
- `GetSpecialization()` → returns the active specialization index (or nil).
- `GetSpecializationInfo(index)` → returns `(specID, name, description, icon, ...)` — use `specID` to compare against a known specialization.
- Events: `PLAYER_LOGIN`, `PLAYER_SPECIALIZATION_CHANGED`, `ACTIVE_TALENT_GROUP_CHANGED`, and register/unregister runtime events like `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW` only when active.

See the repository's specialization table (WoW_Detailed_Reference_Skill.md) for spec IDs.

## Minimal template (Lua)

```lua
-- Replace these constants for your addon / spec
local ADDON = "MyAddon"
local REQUIRED_CLASS = "MONK"       -- class token
local REQUIRED_SPEC_ID = 269        -- specID (e.g. Windwalker)

-- Create event frame early so Enable/Disable helpers can reference it
local eventFrame = CreateFrame("Frame")
-- Listen for saved-vars initialization and the player login (spec is valid at LOGIN)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

local addonEnabled = false
local resourcesInitialized = false

local function IsPlayerClass(token)
  local _, classToken = UnitClass("player")
  return classToken == token
end

local function IsPlayerSpec(specID)
  local specIndex = GetSpecialization()
  if not specIndex then return false end
  local id = select(1, GetSpecializationInfo(specIndex))
  return id == specID
end

local function InitResources()
  if resourcesInitialized then return end
  resourcesInitialized = true
  -- create frames, register saved-vars defaults, create icons, FontStrings, etc.
end

local function EnableAddon()
  if addonEnabled then return end
  addonEnabled = true
  InitResources()
  -- Register runtime events only when active
  eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
  eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
  -- Show UI, restore positions, start tickers as needed
  print("[" .. ADDON .. "] enabled for required spec")
end

local function DisableAddon()
  if not addonEnabled then return end
  addonEnabled = false
  -- Unregister runtime events and hide UI
  eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
  eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
  -- Hide frames, reset timers, stop tickers
  print("[" .. ADDON .. "] disabled (not required spec)")
end

local function UpdateEnabledState()
  -- If wrong class, abort entirely (no further events needed)
  if not IsPlayerClass(REQUIRED_CLASS) then
    print("[" .. ADDON .. "] abort: wrong class")
    eventFrame:UnregisterAllEvents()
    return
  end
  if IsPlayerSpec(REQUIRED_SPEC_ID) then
    EnableAddon()
  else
    DisableAddon()
  end
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    -- Initialise saved-variables and register any icons/UI here.
    -- Do NOT rely on `GetSpecialization()` here; the player's spec may not be ready.
    if arg1 == ADDON then
      -- init saved-vars, register icons, etc.
    end

  elseif event == "PLAYER_LOGIN" then
    -- PLAYER_LOGIN is the first reliable point to query the player's specialization.
    UpdateEnabledState()

  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    if arg1 == "player" then UpdateEnabledState() end

  elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
    UpdateEnabledState()

  elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
    if not addonEnabled then return end
    -- handle proc glow show

  elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
    if not addonEnabled then return end
    -- handle proc glow hide
  end
end)
```

## Best practices
- Create the `eventFrame` before any helper that references it (avoid nil frame errors when registering/unregistering events).
- Prefer lazy resource creation: create UI once when enabling rather than on every login, and keep it idempotent.
- Register runtime events only while the addon is active; `UnregisterEvent` when disabling.
- Reset timers and hide UI when disabling so the addon leaves no visible artifacts.
- Use `PLAYER_SPECIALIZATION_CHANGED` and `ACTIVE_TALENT_GROUP_CHANGED` to detect respeccing and talent-set swaps.

## Testing
- Test by logging in on the target class/spec and verifying the addon enables.
- Respec to another spec and verify the addon disables (icons hidden, timers stopped).
- Test on a different class to ensure the addon exits cleanly without errors.

Replace `REQUIRED_CLASS` and `REQUIRED_SPEC_ID` with the class token and spec ID your addon targets. See `WoW_Detailed_Reference_Skill.md` for spec IDs used in this repository.
