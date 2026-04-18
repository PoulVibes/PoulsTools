---
name: skills
description: Use this for WoW Midnight Addon development, API lookups, and Lua scripting. Trigger when the user mentions WoW API, addon commands, or Midnight framework.
---
# WoW Midnight API Expert

You are a specialist in the WoW Midnight Addon API. You have direct access to the documentation located in the `./WOW API documentation/documentation/` folder.
All source code being worked on in this repository is lua code for WoW addons, specifically using the Midnight framework. When a user asks about WoW API functions, addon commands, or how to implement certain features, you will consult the documentation files to provide accurate and up-to-date information.


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

## Other Repository Reference Files

### Skills & How-Tos
- **[./WoW_Core_Concepts_Skill.md](./WoW_Core_Concepts_Skill.md)** — Read when you need background on WoW fundamentals: classes, specs, combat roles, content types, and leveling systems.
- **[./WoW_Detailed_Reference_Skill.md](./WoW_Detailed_Reference_Skill.md)** — Read when you need spec IDs for `GetSpecializationInfo()`, role matrices, or content difficulty/Midnight systems reference.
- **[./HOWTO_Addon_Single_Spec.md](./HOWTO_Addon_Single_Spec.md)** — Read when building an addon that should only activate for a specific class or specialization; covers startup checks, spec gating, and event timing.

### Addon-Specific Guides
- **[../shmIcons/shmIconsIntegrationSkill.md](../shmIcons/shmIconsIntegrationSkill.md)** — Read when integrating with `shmIcons`: registering icon frames, pushing cooldown/stack/glow updates, TOC dependencies, and the full public API.
- **[../PoulsTools/README.md](../PoulsTools/README.md)** — Read when integrating a sub-addon into the PoulsTools settings hub; covers installation, slash commands, and the `PoulsTools.Menu:RegisterAddon()` API.

### Third-Party Library Docs
- **[../VivifyProcTracker/Libs/README.md](../VivifyProcTracker/Libs/README.md)** — Read when working with the Ace3 framework (lifecycle, saved variables, events, config); points to official Ace3 documentation and repository links.
