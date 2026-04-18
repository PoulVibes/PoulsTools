# Addon Resources — Quick Reference

This file provides a short description of each addon in this repository. Use these notes as quick references when authoring or integrating addons.

- **ComboTracker** — Displays the last used ability that triggers Mastery: Combo Strikes; tracks combo-related state and exposes saved variables. See [../ComboTracker/ComboTracker.toc](../ComboTracker/ComboTracker.toc).

- **CooldownTracker** — Tracks ability cooldowns by name with an icon, cooldown sweep, and ready glow. Integrates with `shmIcons` and `PoulsTools`. See [../CooldownTracker/CooldownTracker.toc](../CooldownTracker/CooldownTracker.toc).

- **GuesstimatorEnergy** — Experimental energy estimator (Monk-focused). Uses AceEvent/Libs for event handling and aims to predict energy windows. See [../EnergyGuesstimator/EnergyGuesstimator.toc](../EnergyGuesstimator/EnergyGuesstimator.toc).

- **GuesstimatorHaste** — Compares `GetHaste()` against a whitelisted GCD dummy to evaluate haste effects on GCD timing. See [../GuesstimatorHaste/GuesstimatorHaste.toc](../GuesstimatorHaste/GuesstimatorHaste.toc).

- **ItemTracker** — Tracks inventory items by name; shows cooldown, stack count, and ready glow. Integrates with `shmIcons` and `PoulsTools`. See [../ItemTracker/ItemTracker.toc](../ItemTracker/ItemTracker.toc).

- **PoulsTools** — Central addon management hub and settings menu; register other addons into a unified settings UI. See [../PoulsTools/PoulsTools.toc](../PoulsTools/PoulsTools.toc).

- **ProcViewer** — Centered HUD proc icons with activation glow for tracked procs; depends on `shmIcons`. See [../ProcViewer/ProcViewer.toc](../ProcViewer/ProcViewer.toc).

- **SBA_Simple** — Simple suggestion display showing the next suggested cast from `C_AssistedCombat`, integrated with `shmIcons`. See [../SBA_Simple/SBA_Simple.toc](../SBA_Simple/SBA_Simple.toc).

- **shmIcons** — Shared icon/cooldown/glow/snap framework used by many addons in this repo; provide common UI primitives and saved variables. See [../shmIcons/shmIcons.toc](../shmIcons/shmIcons.toc).

- **TrinketTracker** — Tracks equipment slot/trinket cooldowns with icon, cooldown sweep, and ready glow; integrates with `shmIcons` and `PoulsTools`. See [../TrinketTracker/TrinketTracker.toc](../TrinketTracker/TrinketTracker.toc).

- **VivifyProcTracker** — Tracks Vivacious Vivification procs and broadcasts via AceMessage; bundles Ace libraries under `Libs`. See [../VivifyProcTracker/VivifyProcTracker.toc](../VivifyProcTracker/VivifyProcTracker.toc).

- **ZenithTracker** — Tracks Zenith uptime (15/20s durations) and provides an audio alert when active. See [../ZenithTracker/ZenithTracker.toc](../ZenithTracker/ZenithTracker.toc).

- **Libs/** — Bundled libraries (Ace3, LibStub, etc.) used by several addons; find per-addon `Libs` folders where present.

- **skills/** — Repository documentation, how-tos, and agent skill definitions (this folder). See [./SKILL.md](./SKILL.md).

---

If you want a shorter inline summary for use inside `skills/SKILL.md` or a markdown table instead, tell me which format you prefer and I will update this file accordingly.