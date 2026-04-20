> ⚠️ **Pre-Release Alpha** — This collection is actively being built out. Expect Updates

---

## PoulsTools — Rotation & Tracker Addon Suite

My goal is simple: bring back the quality-of-life rotation helpers and information trackers that many of us have relied on for the past two decades. They'll never be quite as pinpoint-accurate as they once were, but they're a significant step above what Blizzard currently provides.

---

### Rotation Helper

A single-spell suggestion display that improves on Blizzard's Assisted Combat system.

- Displays the Assisted Combat suggestion by default — zero configuration required
- Supports custom override logic written in Lua for per-spec fine-tuning
- Override code runs surprisingly well in practice

---

### Ability Cooldown Tracker

Track any ability in the game and place it exactly where you want it.

- Resizable, movable icons that can be positioned anywhere on screen
- Tracks cooldowns, stack counts, glow effects, and icon overrides on procs
- Per-spec configuration — different layouts for each specialization

---

### Item Cooldown Tracker

Track any item in the game and place it anywhere you want.

- Supports an unlimited number of tracked items (usable or not)
- Displays cooldown timers, inventory count, and charges
- Per-character configuration

---

### Gear / On-Use Tracker

Track your equipped on-use items and place them where you want them.

- Works with any gear slot — trinkets, Nitro Boost belts, on-use rings, and more
- Cooldown display identical to the item tracker

---

### Proc Tracking

> Currently focused on Windwalker Monk — a broader class library is coming next.

- **Hit Combo** — Tracks Mastery: Combo Strikes for rotation helper, Displays Hit Combo stacks and plays an audio alert when you break the chain
- **Proc Icons** — Movable HUD icons for: Touch of Death · Blackout Kick! · Dance of Chi-Ji · Rushing Wind Kick
- **Zenith Tracker** — Monitors Zenith uptime for use in custom rotations
- **Vivacious Vivification** — Tracks the free Vivify proc for talented Monks

---

### Plugin & Profile Support

- **Plugin API** — Integrate your own addons into the icon system, menus, and rotation helper with a few lines of Lua
- **Custom Lua Overrides** — write your own Lua code to override scripts or use the default
- **Example Scripts** — Comes with some example scripts for overrides
- **Profile Import / Export** — Share your entire UI layout with friends or move it between characters instantly

---

*Just getting started — feedback and requests welcome!*

---

### Slash Commands

List of slash commands available in this addon suite:

- `/pt`, `/poulstools` — Open PoulsTools settings; `/pt help` shows help.

Notes: Commands are case-insensitive. Use the addon's UI for more options.
