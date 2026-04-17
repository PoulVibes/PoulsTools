| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

| [SecretArguments](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |
| --- |
| AllowedWhenUntainted |
| Game Types |
| * [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterWarnings.GetEditModeWarningInfo&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterWarnings.GetEditModeWarningInfo&type=code) |
| Links |
| * [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)C_EncounterWarnings.GetEditModeWarningInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_EncounterWarnings.GetEditModeWarningInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore) * [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:C_EncounterWarnings.GetEditModeWarningInfo)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_EncounterWarnings.GetEditModeWarningInfo) * [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterWarnings.GetEditModeWarningInfo)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterWarnings.GetEditModeWarningInfo) * [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEditModeWarningInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEditModeWarningInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code) * [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEditModeWarningInfo:EncounterWarnings)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEditModeWarningInfo:EncounterWarnings) |
| Patch |
| Added in [12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |

| Value | Field | Description |
| --- | --- | --- |
| 0 | Low |  |
| 1 | Medium |  |
| 2 | High |  |

| Field | Type | Description |
| --- | --- | --- |
| text | string |  |
| casterGUID | [WOWGUID](GUID.md "GUID") : string |  |
| casterName | string |  |
| targetGUID | [WOWGUID](GUID.md "GUID") : string |  |
| targetName | string |  |
| iconFileID | number |  |
| tooltipSpellID | number |  |
| isDeadly | boolean |  |
| color | [colorRGB](ColorMixin.md "ColorMixin") | 12.0.1 |
| duration | DurationSeconds : number |  |
| severity | Enum.EncounterEventSeverity |  |
| shouldPlaySound | boolean |  |
| shouldShowChatMessage | boolean |  |
| shouldShowWarning | boolean |  |

Enum.EncounterEventSeverity

| Value | Field | Description |
| --- | --- | --- |
| 0 | Low |  |
| 1 | Medium |  |
| 2 | High |  |

```
warningInfo = C_EncounterWarnings.GetEditModeWarningInfo(severity)
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

* [![12.0.1 (65617)](/images/thumb/Midnight-inline.png/36px-Midnight-inline.png?801468)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterWarnings.GetEditModeWarningInfo&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterWarnings.GetEditModeWarningInfo&type=code)

* [![GitHub Octocat.png](/images/thumb/GitHub_Octocat.png/16px-GitHub_Octocat.png?e90c6c)](https://github.com/search?type=code&q=/(?-i)C_EncounterWarnings.GetEditModeWarningInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_EncounterWarnings.GetEditModeWarningInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)
* [![Townlong-Yak Globe.png](/images/thumb/Townlong-Yak_Globe.png/16px-Townlong-Yak_Globe.png?680b35)](https://www.townlong-yak.com/globe/wut/#q:C_EncounterWarnings.GetEditModeWarningInfo)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_EncounterWarnings.GetEditModeWarningInfo)
* [![Townlong-Yak BAD.png](/images/thumb/Townlong-Yak_BAD.png/16px-Townlong-Yak_BAD.png?ca02cf)](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterWarnings.GetEditModeWarningInfo)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterWarnings.GetEditModeWarningInfo)
* [![Blizz.gif](/images/Blizz.gif?984542)](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEditModeWarningInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEditModeWarningInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)
* [![ProfIcons engineering.png](/images/thumb/ProfIcons_engineering.png/16px-ProfIcons_engineering.png?4717ae)](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEditModeWarningInfo:EncounterWarnings)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEditModeWarningInfo:EncounterWarnings)

:   severity
    :   Enum.EncounterEventSeverity

severity
:   Enum.EncounterEventSeverity

:   warningInfo
    :   EncounterWarningInfo

warningInfo
:   EncounterWarningInfo