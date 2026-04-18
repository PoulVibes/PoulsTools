| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)C_ActionBar.IsActionInRange/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:C_ActionBar.IsActionInRange)  [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_ActionBar.IsActionInRange)  [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22IsActionInRange\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:IsActionInRange:ActionBar) | `C_ActionBar.IsActionInRange` | [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_ActionBar.IsActionInRange&type=code "12.0.1 (65617)") | + [12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") | RequiresValidActionSlot | AllowedWhenUntainted |
| [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)IsActionInRange/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:IsActionInRange)  [Wowprogramming.png](https://wowprogramming.com/docs/api/IsActionInRange.html) | `IsActionInRange` | [5.5.3 (65302)](https://github.com/search?q=repo:Ketho/wow-ui-source-mists+IsActionInRange&type=code "5.5.3 (65302)")[2.5.5 (65463)](https://github.com/search?q=repo:Ketho/wow-ui-source-bcc+IsActionInRange&type=code "2.5.5 (65463)")[1.15.8 (63829)](https://github.com/search?q=repo:Ketho/wow-ui-source-vanilla+IsActionInRange&type=code "1.15.8 (63829)") | + [1.0.0](Patch_1.0.0/API_changes.md "Patch 1.0.0/API changes") / [1.13.2](Patch_1.13.2/API_changes.md "Patch 1.13.2/API changes") |

`C_ActionBar.IsActionInRange`
`IsActionInRange`

```
isInRange = C_ActionBar.IsActionInRange(actionID [, target])
```

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

:   actionID
    :   number

    target
    :   [UnitToken](UnitId.md "UnitId")? : string

actionID
:   number

target
:   [UnitToken](UnitId.md "UnitId")? : string

:   isInRange
    :   boolean? - If nil, range cannot be determined (eg. no target is available).

isInRange
:   boolean? - If nil, range cannot be determined (eg. no target is available).

↑ *[World of Warcraft API](World_of_Warcraft_API.md "World of Warcraft API")*