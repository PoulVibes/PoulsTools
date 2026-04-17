# World of Warcraft: API & Specialization Reference (v2.0)

## 1. Class Specialization ID & Role Matrix
Use these IDs to identify specializations via `GetSpecializationInfo()`. Roles are categorized as **Tank**, **Healer**, **Melee DPS**, or **Ranged DPS**.


| Class | Spec Name | API ID | Role (Specific) |
| :--- | :--- | :--- | :--- |
| **Death Knight** | Blood | 250 | Tank |
| | Frost | 251 | Melee DPS |
| | Unholy | 252 | Melee DPS |
| **Demon Hunter** | Havoc | 577 | Melee DPS |
| | Vengeance | 581 | Tank |
| | **Devourer** | 1480 | Ranged DPS (Midnight) |
| **Druid** | Balance | 102 | Ranged DPS |
| | Feral | 103 | Melee DPS |
| | Guardian | 104 | Tank |
| | Restoration | 105 | Healer |
| **Evoker** | Devastation | 1467 | Ranged DPS |
| | Preservation | 1468 | Healer |
| | Augmentation | 1473 | Ranged DPS (Support) |
| **Hunter** | Beast Mastery | 253 | Ranged DPS |
| | Marksmanship | 254 | Ranged DPS |
| | Survival | 255 | Melee DPS |
| **Mage** | Arcane | 62 | Ranged DPS |
| | Fire | 63 | Ranged DPS |
| | Frost | 64 | Ranged DPS |
| **Monk** | Brewmaster | 268 | Tank |
| | Mistweaver | 270 | Healer |
| | Windwalker | 269 | Melee DPS |
| **Paladin** | Holy | 65 | Healer |
| | Protection | 66 | Tank |
| | Retribution | 70 | Melee DPS |
| **Priest** | Discipline | 256 | Healer |
| | Holy | 257 | Healer |
| | Shadow | 258 | Ranged DPS |
| **Rogue** | Assassination | 259 | Melee DPS |
| | Outlaw | 260 | Melee DPS |
| | Subtlety | 261 | Melee DPS |
| **Shaman** | Elemental | 262 | Ranged DPS |
| | Enhancement | 263 | Melee DPS |
| | Restoration | 264 | Healer |
| **Warlock** | Affliction | 265 | Ranged DPS |
| | Demonology | 266 | Ranged DPS |
| | Destruction | 267 | Ranged DPS |
| **Warrior** | Arms | 71 | Melee DPS |
| | Fury | 72 | Melee DPS |
| | Protection | 73 | Tank |

## 2. Content Difficulty & Midnight Systems
*   **Dungeons**: Normal → Heroic → Mythic (M0) → Mythic+ (M+).
*   **Raids**: Story Mode → LFR → Normal → Heroic → Mythic.
*   **The Prey (Midnight)**: An outdoor challenge system with **Normal**, **Hard** (Torments), and **Nightmare** tiers.
*   **Delves (Season 1)**: 1-5 player content featuring **Valeera Sanguinar** as the seasonal companion.
*   **Apex Talents**: Progression for levels 81-90.
*   **Voidforging**: Endgame gear upgrades using **Voidcores**.

## 3. Core API Functionality
*   `GetSpecialization()`: Returns the current active spec index (1-4).
*   `GetSpecializationInfo(index)`: Returns `specializationID` (Table ID), name, description, and icon.
*   `GetSpecializationRole(index)`: Returns the generic string (e.g., "DAMAGER"), which the AI should then map to the **Role (Specific)** column in the table above.
