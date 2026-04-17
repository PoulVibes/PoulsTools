| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

| [SecretArguments](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |
| --- |
| AllowedWhenTainted |
| Game Types |
| * [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+AbbreviateNumbers&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+AbbreviateNumbers&type=code) |
| Links |
| * [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)AbbreviateNumbers/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)AbbreviateNumbers/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore) * [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:AbbreviateNumbers)  [Globe](https://www.townlong-yak.com/globe/wut/#q:AbbreviateNumbers) * [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#AbbreviateNumbers)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#AbbreviateNumbers) * [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22AbbreviateNumbers\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22AbbreviateNumbers\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code) * [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:AbbreviateNumbers:Localization)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:AbbreviateNumbers:Localization) |
| Patch |
| Added in [12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") |

| Field | Type | Description |
| --- | --- | --- |
| breakpointData | NumberAbbreviationBreakpoint[]? | Order these from largest to smallest. |
| locale | string? | Locale controls whether standard asian abbreviation data will be used along with a small change in behavior for large number abbreviation when fractionDivisor is greater than zero. |
| config | [AbbreviateConfig](ScriptObject_AbbreviateConfig.md "ScriptObject AbbreviateConfig")? | Provides a cached config object for optimal performance when calling abbreviation functions multiple times with the same options. |

NumberAbbreviationBreakpoint

| Field | Type | Description |
| --- | --- | --- |
| breakpoint | number | Breakpoints should generally be specified as pairs, with one at the named order (1,000) with fractionDivisor = 10, and one a single order higher (eg. 10,000) with fractionDivisor = 1., This ruleset means numbers like '1234' will be abbreviated to '1.2k' and numbers like '12345' to '12k'. |
| abbreviation | string | Abbreviation name to be looked up as a global string. |
| significandDivisor | number | significandDivisor and fractionDivisor should multiply such that they become equal to a named order of magnitude, such as thousands or millions. |
| fractionDivisor | number |  |
| abbreviationIsGlobal | boolean? `= true` | Defaults to true. Set to false to skip the global string lookup and use the raw abbreviation string when formatting results |

```
result = AbbreviateNumbers(number [, options])
```

`= true`

```
function AbbreviateNumbers(value)
	for i, data in ipairs(GetLocalizedNumberAbbreviationData()) do
		if value >= data.breakpoint then
			local finalValue = math.floor(value / data.significandDivisor) / data.fractionDivisor;
			return finalValue .. data.abbreviation;
		end
	end
	return tostring(value);
end
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

* [![12.0.1 (65617)](/images/thumb/Midnight-inline.png/36px-Midnight-inline.png?801468)](https://github.com/search?q=repo:Gethe/wow-ui-source+AbbreviateNumbers&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+AbbreviateNumbers&type=code)

* [![GitHub Octocat.png](/images/thumb/GitHub_Octocat.png/16px-GitHub_Octocat.png?e90c6c)](https://github.com/search?type=code&q=/(?-i)AbbreviateNumbers/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)AbbreviateNumbers/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)
* [![Townlong-Yak Globe.png](/images/thumb/Townlong-Yak_Globe.png/16px-Townlong-Yak_Globe.png?680b35)](https://www.townlong-yak.com/globe/wut/#q:AbbreviateNumbers)  [Globe](https://www.townlong-yak.com/globe/wut/#q:AbbreviateNumbers)
* [![Townlong-Yak BAD.png](/images/thumb/Townlong-Yak_BAD.png/16px-Townlong-Yak_BAD.png?ca02cf)](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#AbbreviateNumbers)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#AbbreviateNumbers)
* [![Blizz.gif](/images/Blizz.gif?984542)](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22AbbreviateNumbers\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22AbbreviateNumbers\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)
* [![ProfIcons engineering.png](/images/thumb/ProfIcons_engineering.png/16px-ProfIcons_engineering.png?4717ae)](https://mrbuds.github.io/wow-api-web/?search=api:function:AbbreviateNumbers:Localization)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:AbbreviateNumbers:Localization)

:   number
    :   number

    options
    :   NumberAbbrevOptions?

number
:   number

options
:   NumberAbbrevOptions?

:   result
    :   string

result
:   string

* [![Midnight](/images/thumb/Midnight-inline.png/40px-Midnight-inline.png?801468)](World_of_Warcraft:_Midnight.md "Midnight") **[Patch 12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") (2026-01-20):** Converted to an API function.
* [![Mists of Pandaria](/images/Mists-Logo-Small.png?f96b23)](World_of_Warcraft:_Mists_of_Pandaria.md "Mists of Pandaria") **[Patch 5.0.4](Patch_5.0.4/API_changes.md "Patch 5.0.4/API changes") (2012-08-28):** Added as a FrameXML function.

This function was previously defined in [FrameXML](https://github.com/Gethe/wow-ui-source/blob/11.2.7/Interface/AddOns/Blizzard_UIParent/Shared/UIParent.lua#L126).