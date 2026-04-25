---
name: skills
description: Use this for WoW Midnight Addon development, API lookups, and Lua scripting. Trigger when the user mentions WoW API, addon commands, or Midnight framework.
---
# WoW Midnight API Expert

You are a specialist in the WoW Midnight Addon API. You have direct access to the documentation located in the `./WOW_API_documentation/documentation/` folder.
All source code being worked on in this repository is lua code for WoW addons, specifically using the Midnight framework. When a user asks about WoW API functions, addon commands, or how to implement certain features, you will consult the documentation files to provide accurate and up-to-date information. The current WoW interface is version 12.0.5 (##Interface: 120005).
When I say "Roll toc versions", Every `LUA` file we have changed in this conversation should roll the minor version number in the `TOC` file of the relevant addon folder to make easily identify when issues were introduced. For example, if the current version is `1.0.0`, update it to `1.0.1`.
Be concise in your responses, providing only the necessary information and code snippets to address the user's query. Always ensure that the information you provide is based on the latest documentation available in the `./WOW_API_documentation/documentation/` folder.


## Core Reference
- **Main API Index**: [./WOW_API_documentation/documentation/API_changes.md](./WOW_API_documentation/documentation/API_changes.md)
  - Use this file as your primary starting point to find function signatures, command changes, and links to specific module documentation.

## Instructions for the Agent
1. **Lookup First**: Before suggesting any Lua code, consult `API_changes.md` to ensure you are using the most current API syntax.
2. **Follow Links**: Use the relative links within the documentation files to jump to specific API details as needed.
3. **Accuracy**: If the user asks about a specific command, search the documentation folder for that command's definition to provide the exact parameters and return values.

## Implementation Style
- Provide code snippets in **Lua**.
- Ensure examples follow the Midnight framework patterns found in the docs.

---

## Condensed Addon Summary
- **ComboTracker** — Displays the last used ability that triggers Mastery: Combo Strikes.
- **CooldownTracker** — Tracks ability cooldowns with icon, cooldown sweep, and ready glow.
- **EnergyGuesstimator** — Experimental energy estimator (Monk-focused); uses native WoW API events and listens for `_G.VivifyProc_OnEvent`.
- **GuesstimatorHaste** — Compares `GetHaste()` vs a GCD dummy to assess haste effects.
- **ItemTracker** — Tracks item cooldowns, stack counts, and ready glow.
- **PoulsTools** — Central settings hub and addon registration UI.
- **ProcViewer** — Centered HUD proc icons with activation glow.
- **SBA_Simple** — Displays the next suggested cast from `C_AssistedCombat`.
- **shmIcons** — Shared icon/cooldown/glow framework used by other addons.
- **TrinketTracker** — Tracks trinket/equipment cooldowns with UI integration.
- **VivifyProcTracker** — Tracks Vivacious Vivification procs and notifies listeners via `_G.VivifyProc_OnEvent` (no bundled external libraries).
- **ZenithTracker** — Tracks Zenith uptime (15/20s) and plays an audio alert.
- **Libs/** — Bundled libraries (LibStub, etc.) used by select addons.

## Other Repository Reference Files

### Skills & How-Tos
- **[./WoW_Core_Concepts_Skill.md](./WoW_Core_Concepts_Skill.md)** — Read when you need background on WoW fundamentals: classes, specs, combat roles, content types, and leveling systems.
- **[./WoW_Detailed_Reference_Skill.md](./WoW_Detailed_Reference_Skill.md)** — Read when you need spec IDs for `GetSpecializationInfo()`, role matrices, or content difficulty/Midnight systems reference.
- **[./HOWTO_Addon_Single_Spec.md](./HOWTO_Addon_Single_Spec.md)** — Read when building an addon that should only activate for a specific class or specialization; covers startup checks, spec gating, and event timing.

### Addon-Specific Guides
- **[../PoulsTools_shmIcons/shmIconsIntegrationSkill.md](../PoulsTools_shmIcons/shmIconsIntegrationSkill.md)** — Read when integrating with `shmIcons`: registering icon frames, pushing cooldown/stack/glow updates, TOC dependencies, and the full public API.
- **[../PoulsTools/README.md](../PoulsTools/README.md)** — Read when integrating a sub-addon into the PoulsTools settings hub; covers installation, slash commands, and the `PoulsTools.Menu:RegisterAddon()` API.

### SBAS Override GUI — Summary

Brief summary and pointer to the full agent notes: [SBAS_override_agent.md](PoulsTools_SBA_Simple/SBAS_override_agent.md)

- Purpose: graphical priority-list builder for SBA overrides.
- Primary files: `PoulsTools_SBA_Simple/SBA_Simple_OverrideGUI.lua`, `PoulsTools_SBA_Simple/SBA_Simple.lua`.
- Data model: rules stored in `SBA_SimpleDB.gui[specID]`; generated code in `SBA_SimpleDB.specs[specID].overrideCode`.
- UI: resizable frame with left rule list and right condition editor; condition registry in `COND_TYPES`; parenthesis grouping visualization; preview vs save flow.

Refer to the linked file for full details and step-by-step editing guidance.

