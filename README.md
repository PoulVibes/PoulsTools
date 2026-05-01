## CombatCoach — Rotation & Tracker Addon Suite

CombatCoach is a suite of tools designed to help improve your rotation and awareness. Blizzard has added their own combat assistant and cooldown manager, but often times they are incomplete, flat wrong, or just not customizable enough. That's where CombatCoach comes in. CombatCoach Augments the information available in Blizzards baked in tools to consider things they don't and allow you to track a lot of info blizz doesn't.
---

### Rotation Helper

A single-spell suggestion display that improves on Blizzard's Assisted Combat system.

- Displays the Assisted Combat suggestion by default for classes where it makes sense — zero configuration required
- For specs that experience issues it provides overrides to the reccomendation system
- Has a handy graphical tool for building your priorities.
- Includes baked in conditions for common checks, plugin support for class specific procs (growing list daily), and custom Lua expression condition support
- Override code lets you update your rotational priorities real time.

---

### Ability Cooldown Tracker

Track any ability in the game and place it exactly where you want it.

- Resizable, movable icons that can be positioned anywhere on screen.
- Tracks cooldowns, stack counts, resource checks, and icon overrides
- Per-spec configuration — different layouts for each specialization
- Supports Audio queues when ability usage is fully charged and ready.
- Supports glow effects when abilities are usable.

---

### Item Cooldown Tracker

Track any item in the game and place it anywhere you want.

- Supports an unlimited number of tracked items (usable or not)
- Displays cooldown timers, inventory count, and charges
- Per-character configuration
- Handy for tracking Combat potions, healthstones, or even just as a farming display

---

### Gear / On-Use Tracker

Track your equipped on-use gear and place them where you want them.

- Works with any gear slot — trinkets, Nitro Boost belts, on-use rings, and more
- Shows cooldown information
- Supports Highlight glow when usable


---

### Realtime Proc Tracking

> Built-in class plugins let you see information on key DPS procs.

- Supported Specs: WW-Monk, BM Hunter, more coming soon.

---

### Plugin & Profile Support

- **Plugin API** — Integrate your own addons into the icon system, menus, and rotation helper with a few lines of Lua
- **Custom Overrides** — Use the priority override gui to choose the priorities you want or add custom code to override
- **Reccomended Overrides** — Growing list of Pre-programmed overrides for ability helper
- **Override Sharing** — Full import and export support to share your priorities and layouts with your friends.

---

*Just getting started — feedback and requests encouraged!*

---

### Slash Commands

 - What's overriden and why?
    - Windwalker Monk - SBA = unplayable
        - Blizz reccomends Touch of death when someone around can be touch of deathed not when your current target can be.
        - During zenith blizz doesn't change the rotation to account for not generally needing to build chi with tiger palm
        - Blizz always recommends spending chi even when Fists of Fury is off cooldown
        - General flow improvements
    - Beast Mastery Hunter - SBA = generally not bad, but subtle improvements help.
        - Improved AoE Rotation
        - Blizz's SBA always wants to recommend something usable so it will recommend cobra shot even when using it will cost you dps
        - SBA doesn't delay Wailing Arrow to get the extra black arrow.


---

### Slash Commands

List of slash commands available in this addon suite:

- `/cc`, `/CombatCoach` — Open CombatCoach settings; `/cc help` shows help.

Notes: Commands are case-insensitive. Use the addon's UI for more options.
