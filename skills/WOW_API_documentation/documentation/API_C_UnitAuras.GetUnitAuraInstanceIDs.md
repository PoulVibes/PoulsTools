| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

| [SecretArguments](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |
| --- |
| AllowedWhenUntainted |
| Game Types |
| * [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_UnitAuras.GetUnitAuraInstanceIDs&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_UnitAuras.GetUnitAuraInstanceIDs&type=code) |
| Links |
| * [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)C_UnitAuras.GetUnitAuraInstanceIDs/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_UnitAuras.GetUnitAuraInstanceIDs/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore) * [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:C_UnitAuras.GetUnitAuraInstanceIDs)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_UnitAuras.GetUnitAuraInstanceIDs) * [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_UnitAuras.GetUnitAuraInstanceIDs)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_UnitAuras.GetUnitAuraInstanceIDs) * [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetUnitAuraInstanceIDs\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetUnitAuraInstanceIDs\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code) * [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:GetUnitAuraInstanceIDs:UnitAuras)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetUnitAuraInstanceIDs:UnitAuras) |
| Patch |
| Added in [12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |

| Filter | Description |
| --- | --- |
| HELPFUL | Buffs |
| HARMFUL | Debuffs |
| PLAYER | Buffs/debuffs applied by the player  * *Requires the HELPFUL or HARMFUL filter if using UnitAura / .GetAuraDataByIndex* |
| RAID | HELPFUL: Buffs filtered by the player's class, e.g. for Priests it will only return  [[Power Word: Fortitude]](Power_Word:_Fortitude.md "Power Word: Fortitude") or  [[Renew]](Renew.md "Renew"). HARMFUL: Certain debuffs that only show up on raid frames, e.g. most debuffs that are relevant in a raid context.   * *Requires the HELPFUL or HARMFUL filter if using UnitAura / .GetAuraDataByIndex* * *This does not require you to be in a raid* |
| CANCELABLE | Buffs that can be cancelled with [/cancelaura](MACRO_cancelaura.md "MACRO cancelaura") or [CancelUnitBuff](API_CancelUnitBuff.md "API CancelUnitBuff")() |
| NOT\_CANCELABLE | Buffs that cannot be cancelled |
| INCLUDE\_NAME\_PLATE\_ONLY | Auras that should be shown on nameplates.  * *Unlike other filters that restrict the results, this filter expands results to include some auras that would otherwise not be returned, like [**Crusading Strikes**](https://www.wowhead.com/spell=1226662)* |
| MAW | Torghast [Anima Powers](Torghast,_Tower_of_the_Damned.md "Torghast, Tower of the Damned") |
| EXTERNAL\_DEFENSIVE | 12.0.0 - External defensive buffs |
| CROWD\_CONTROL | 12.0.1 - Crowd control effects |
| RAID\_IN\_COMBAT | 12.0.1 - Auras flagged to show on raid frames in combat. Combine with PLAYER & HELPFUL to return self-cast HoTs |
| RAID\_PLAYER\_DISPELLABLE | 12.0.1 - Auras with a dispel type the player can dispel |
| BIG\_DEFENSIVE | 12.0.1 - Big defensive buffs |
| IMPORTANT | 12.0.1 - Spells that pass [C\_Spell.IsSpellImportant](API_C_Spell.IsSpellImportant.md "API C Spell.IsSpellImportant")() |

| Value | Field | Description |
| --- | --- | --- |
| 0 | Unsorted | Applies no sorting to auras. |
| 1 | Default | Sorts auras according first by whether or not the aura was applied by the player, else whether or not the player can apply the aura, and finally by aura instance ID. |
| 2 | BigDefensive | Sorts auras according first by whether or not the aura was applied by another player, else by expiration time (longest to shortest), and finally by aura instance ID. |
| 3 | Expiration | Sorts auras according first by whether or not the aura was applied by the player, else whether or not the player can apply the aura, then by expiration time (soonest to longest, followed by permanent auras), and finally by aura instance ID. |
| 4 | ExpirationOnly | Sorts auras according only to expiration time. |
| 5 | Name | Sorts auras according first by whether or not the aura was applied by the player, else whether or not the player can apply the aura, then by spell name, and finally by aura instance ID. |
| 6 | NameOnly | Sorts auras according only their spell name. |

| Value | Field | Description |
| --- | --- | --- |
| 0 | Normal |  |
| 1 | Reverse |  |

```
auraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter [, maxCount [, sortRule [, sortDirection]]])
```

`= Unsorted`
`= Normal`

* [WoW API](World_of_Warcraft_API.md "World of Warcraft API")
* [Lua API](Lua_functions.md "Lua functions")
* [FrameXML API](FrameXML_functions.md "FrameXML functions")

* [Widget API](Widget_API.md "Widget API")
* [Widget scripts](Widget_script_handlers.md "Widget script handlers")
* [XML schema](XML_schema.md "XML schema")
* [Events](Events.md "Events")
* [CVars](Console_variables.md "Console variables")

* [Macro commands](Macro_commands.md "Macro commands")
* [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT")
* [Escape sequences](UI_escape_sequences.md "UI escape sequences")
* [Hyperlinks](Hyperlinks.md "Hyperlinks")
* [API changes](API_change_summaries.md "API change summaries")
* [HOWTOs](HOWTOs.md "HOWTOs")
* [![Discord logo.png](/images/thumb/Discord_logo.png/12px-Discord_logo.png?4d7bc2)](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6)

* [![12.0.1 (65617)](/images/thumb/Midnight-inline.png/36px-Midnight-inline.png?801468)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_UnitAuras.GetUnitAuraInstanceIDs&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_UnitAuras.GetUnitAuraInstanceIDs&type=code)

* [![GitHub Octocat.png](/images/thumb/GitHub_Octocat.png/16px-GitHub_Octocat.png?e90c6c)](https://github.com/search?type=code&q=/(?-i)C_UnitAuras.GetUnitAuraInstanceIDs/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_UnitAuras.GetUnitAuraInstanceIDs/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)
* [![Townlong-Yak Globe.png](/images/thumb/Townlong-Yak_Globe.png/16px-Townlong-Yak_Globe.png?680b35)](https://www.townlong-yak.com/globe/wut/#q:C_UnitAuras.GetUnitAuraInstanceIDs)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_UnitAuras.GetUnitAuraInstanceIDs)
* [![Townlong-Yak BAD.png](/images/thumb/Townlong-Yak_BAD.png/16px-Townlong-Yak_BAD.png?ca02cf)](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_UnitAuras.GetUnitAuraInstanceIDs)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_UnitAuras.GetUnitAuraInstanceIDs)
* [![Blizz.gif](/images/Blizz.gif?984542)](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetUnitAuraInstanceIDs\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetUnitAuraInstanceIDs\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)
* [![ProfIcons engineering.png](/images/thumb/ProfIcons_engineering.png/16px-ProfIcons_engineering.png?4717ae)](https://mrbuds.github.io/wow-api-web/?search=api:function:GetUnitAuraInstanceIDs:UnitAuras)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetUnitAuraInstanceIDs:UnitAuras)

:   unit
    :   [UnitTokenRestrictedForAddOns](UnitId.md "UnitId") : string

    filter
    :   AuraFilters : string

unit
:   [UnitTokenRestrictedForAddOns](UnitId.md "UnitId") : string

filter
:   AuraFilters : string

* *Requires the HELPFUL or HARMFUL filter if using UnitAura / .GetAuraDataByIndex*

* *Requires the HELPFUL or HARMFUL filter if using UnitAura / .GetAuraDataByIndex*
* *This does not require you to be in a raid*

* *Unlike other filters that restrict the results, this filter expands results to include some auras that would otherwise not be returned, like [**Crusading Strikes**](https://www.wowhead.com/spell=1226662)*

:   maxCount
    :   number?

    sortRule
    :   Enum.UnitAuraSortRule? `= Unsorted`

maxCount
:   number?

sortRule
:   Enum.UnitAuraSortRule? `= Unsorted`

:   sortDirection
    :   Enum.UnitAuraSortDirection? `= Normal`

sortDirection
:   Enum.UnitAuraSortDirection? `= Normal`

:   auraInstanceIDs
    :   number[]

auraInstanceIDs
:   number[]