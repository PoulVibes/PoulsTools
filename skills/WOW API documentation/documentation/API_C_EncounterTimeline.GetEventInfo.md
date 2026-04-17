| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

| Predicates |
| --- |
| RequiresValidTimelineEvent |
| SecretWhenEncounterEvent |
| [SecretArguments](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |
| NotAllowed |
| Game Types |
| * [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterTimeline.GetEventInfo&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterTimeline.GetEventInfo&type=code) |
| Links |
| * [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)C_EncounterTimeline.GetEventInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_EncounterTimeline.GetEventInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore) * [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:C_EncounterTimeline.GetEventInfo)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_EncounterTimeline.GetEventInfo) * [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterTimeline.GetEventInfo)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterTimeline.GetEventInfo) * [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEventInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEventInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code) * [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEventInfo:EncounterTimeline)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEventInfo:EncounterTimeline) |
| Patch |
| Added in [12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |

| Field | Type | Description |
| --- | --- | --- |
| id | EncounterTimelineEventID : number  NeverSecret | Instance ID for this event. |
| source | Enum.EncounterTimelineEventSource  NeverSecret | Source that this event came from. |
| spellName | string | Spell name associated with this event. For script events, this may instead be the contents of the 'overrideName' field if it wasn't empty. |
| spellID | number | Spell ID associated with this event. |
| iconFileID | [fileID](FileDataID.md "FileDataID") : number | Icon file ID associated with this event. |
| duration | DurationSeconds : number  NeverSecret | Base duration of this event at the point that it was queued onto the timeline. |
| maxQueueDuration | DurationSeconds : number  NeverSecret | Hold duration for this event after it reaches the end of the timeline. During this period, the event will sit in the queued track of the timeline until manually finished or this added duration expires. |
| icons | Enum.EncounterEventIconmask | Bitmask of active icon states for this event. |
| severity | Enum.EncounterEventSeverity | Severity of this event. |
| color | [colorRGB](ColorMixin.md "ColorMixin") | 12.0.1 - Color to use for displaying this event. May be overridden by C\_EncounterEvents APIs, else will default to an appropriate color for the current view mode. |
| isApproximate | boolean | If true, this event is an approximation and may not occur exactly when the timeline suggests it will. |

Enum.EncounterTimelineEventSource

| Value | Field | Description |
| --- | --- | --- |
| 0 | Encounter | Source used for events added by an instance encounter. |
| 1 | Script | Source used for events added by Lua scripting APIs. This is used to apply API restrictions; the Pause/Cancel/ResumeScriptEvent functions only work on Script events. |
| 2 | EditMode | Source used for events added by the AddEditModeEvents script API. |

Enum.EncounterEventIconmask

| Value | Field | Description |
| --- | --- | --- |
| 0x1 | DeadlyEffect |  |
| 0x2 | EnrageEffect |  |
| 0x4 | BleedEffect |  |
| 0x8 | MagicEffect |  |
| 0x10 | DiseaseEffect |  |
| 0x20 | CurseEffect |  |
| 0x40 | PoisonEffect |  |
| 0x80 | TankRole |  |
| 0x100 | HealerRole |  |
| 0x200 | DpsRole |  |

Enum.EncounterEventSeverity

| Value | Field | Description |
| --- | --- | --- |
| 0 | Low |  |
| 1 | Medium |  |
| 2 | High |  |

```
info = C_EncounterTimeline.GetEventInfo(eventID)
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

* [![12.0.1 (65617)](/images/thumb/Midnight-inline.png/36px-Midnight-inline.png?801468)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterTimeline.GetEventInfo&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_EncounterTimeline.GetEventInfo&type=code)

* [![GitHub Octocat.png](/images/thumb/GitHub_Octocat.png/16px-GitHub_Octocat.png?e90c6c)](https://github.com/search?type=code&q=/(?-i)C_EncounterTimeline.GetEventInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_EncounterTimeline.GetEventInfo/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)
* [![Townlong-Yak Globe.png](/images/thumb/Townlong-Yak_Globe.png/16px-Townlong-Yak_Globe.png?680b35)](https://www.townlong-yak.com/globe/wut/#q:C_EncounterTimeline.GetEventInfo)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_EncounterTimeline.GetEventInfo)
* [![Townlong-Yak BAD.png](/images/thumb/Townlong-Yak_BAD.png/16px-Townlong-Yak_BAD.png?ca02cf)](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterTimeline.GetEventInfo)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_EncounterTimeline.GetEventInfo)
* [![Blizz.gif](/images/Blizz.gif?984542)](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEventInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22GetEventInfo\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)
* [![ProfIcons engineering.png](/images/thumb/ProfIcons_engineering.png/16px-ProfIcons_engineering.png?4717ae)](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEventInfo:EncounterTimeline)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:GetEventInfo:EncounterTimeline)

:   eventID
    :   EncounterTimelineEventID : number

eventID
:   EncounterTimelineEventID : number

:   info
    :   EncounterTimelineEventInfo

info
:   EncounterTimelineEventInfo