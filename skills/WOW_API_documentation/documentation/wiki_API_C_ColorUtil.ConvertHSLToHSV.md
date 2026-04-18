| [Main Menu](wiki_Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](wiki_World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](wiki_Lua_functions.md "Lua functions") * [FrameXML API](wiki_FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](wiki_Widget_API.md "Widget API") * [Widget scripts](wiki_Widget_script_handlers.md "Widget script handlers") * [XML schema](wiki_XML_schema.md "XML schema") * [Events](wiki_Events.md "Events") * [CVars](wiki_Console_variables.md "Console variables")  ---  * [Macro commands](wiki_Macro_commands.md "Macro commands") * [Combat Log](wiki_COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](wiki_UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](wiki_Hyperlinks.md "Hyperlinks") * [API changes](wiki_API_change_summaries.md "API change summaries") * [HOWTOs](wiki_HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

| [SecretArguments](wiki_Patch_12.0.0_API_changes.md "Patch 12.0.0/API changes") |
| --- |
| AllowedWhenUntainted |
| Game Types |
| * [12.0.1 (65617)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_ColorUtil.ConvertHSLToHSV&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_ColorUtil.ConvertHSLToHSV&type=code) |
| Links |
| * [GitHub Octocat.png](https://github.com/search?type=code&q=/(?-i)C_ColorUtil.ConvertHSLToHSV/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_ColorUtil.ConvertHSLToHSV/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore) * [Townlong-Yak Globe.png](https://www.townlong-yak.com/globe/wut/#q:C_ColorUtil.ConvertHSLToHSV)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_ColorUtil.ConvertHSLToHSV) * [Townlong-Yak BAD.png](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_ColorUtil.ConvertHSLToHSV)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_ColorUtil.ConvertHSLToHSV) * [Blizz.gif](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22ConvertHSLToHSV\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22ConvertHSLToHSV\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code) * [ProfIcons engineering.png](https://mrbuds.github.io/wow-api-web/?search=api:function:ConvertHSLToHSV:ColorUtil)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:ConvertHSLToHSV:ColorUtil) |
| Patch |
| Added in [12.0.0](wiki_Patch_12.0.0_API_changes.md "Patch 12.0.0/API changes") |

```
hsvH, hsvS, hsvV = C_ColorUtil.ConvertHSLToHSV(hslH, hslS, hslL)
```

* [Create account](wiki_Special:CreateAccount.md "You are encouraged to create an account and log in; however, it is not mandatory")
* [Log in](wiki_Special:UserLogin.md "You are encouraged to log in; however, it is not mandatory [o]")

* [Create account](wiki_Special:CreateAccount.md "You are encouraged to create an account and log in; however, it is not mandatory")
* [Log in](wiki_Special:UserLogin.md "You are encouraged to log in; however, it is not mandatory [o]")

* [WoW API](wiki_World_of_Warcraft_API.md "World of Warcraft API")
* [Lua API](wiki_Lua_functions.md "Lua functions")
* [FrameXML API](wiki_FrameXML_functions.md "FrameXML functions")

* [Widget API](wiki_Widget_API.md "Widget API")
* [Widget scripts](wiki_Widget_script_handlers.md "Widget script handlers")
* [XML schema](wiki_XML_schema.md "XML schema")
* [Events](wiki_Events.md "Events")
* [CVars](wiki_Console_variables.md "Console variables")

* [Macro commands](wiki_Macro_commands.md "Macro commands")
* [Combat Log](wiki_COMBAT_LOG_EVENT.md "COMBAT LOG EVENT")
* [Escape sequences](wiki_UI_escape_sequences.md "UI escape sequences")
* [Hyperlinks](wiki_Hyperlinks.md "Hyperlinks")
* [API changes](wiki_API_change_summaries.md "API change summaries")
* [HOWTOs](wiki_HOWTOs.md "HOWTOs")
* [![Discord logo.png](/images/thumb/Discord_logo.png/12px-Discord_logo.png?4d7bc2)](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6)

* [![12.0.1 (65617)](/images/thumb/Midnight-inline.png/36px-Midnight-inline.png?801468)](https://github.com/search?q=repo:Gethe/wow-ui-source+C_ColorUtil.ConvertHSLToHSV&type=code "12.0.1 (65617)")  [mainline](https://github.com/search?q=repo:Gethe/wow-ui-source+C_ColorUtil.ConvertHSLToHSV&type=code)

* [![GitHub Octocat.png](/images/thumb/GitHub_Octocat.png/16px-GitHub_Octocat.png?e90c6c)](https://github.com/search?type=code&q=/(?-i)C_ColorUtil.ConvertHSLToHSV/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)  [GitHub search](https://github.com/search?type=code&q=/(?-i)C_ColorUtil.ConvertHSLToHSV/+language:Lua+NOT+is:fork+NOT+path:Interface+NOT+path:FrameXML+NOT+path:GlueXML+NOT+path:SharedXML+NOT+path:AddOns+NOT+repo:BigWigsMods/WoWUI+NOT+owner:Ketho+NOT+path:.luacheckrc+NOT+repo:Resike/BlizzardInterfaceResources+NOT+repo:mrbuds/wow-api-web+NOT+owner:arkanoid1+NOT+owner:refaim+NOT+owner:clicketz+NOT+owner:Zetaprime82+NOT+owner:biroistv+NOT+owner:liquidbase+NOT+owner:Falkicon+NOT+repo:Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API+NOT+repo:ChrisKader/wowapi+NOT+repo:nebularg/wow-selene-parser+NOT+repo:Resike/LuaLSP+NOT+owner:MrMartin92+NOT+repo:ketho-wow/KethoDoc+NOT+path:data/impl+NOT+path:wow-api.lua+NOT+path:wow-widget-api.lua+NOT+path:textentry.lua+NOT+owner:papa-smurf+NOT+owner:Bhahlou+NOT+owner:nwpark+NOT+owner:turulix+NOT+path:luaserver.lua+NOT+repo:QartemisT/WoW.luadoc+NOT+owner:92Garfield+NOT+owner:BreakBB+NOT+owner:Logonz+NOT+owner:Subwaytime+NOT+owner:ZenonWow+NOT+path:WeakAuras+NOT+path:ElvUI+NOT+path:DataStore)
* [![Townlong-Yak Globe.png](/images/thumb/Townlong-Yak_Globe.png/16px-Townlong-Yak_Globe.png?680b35)](https://www.townlong-yak.com/globe/wut/#q:C_ColorUtil.ConvertHSLToHSV)  [Globe](https://www.townlong-yak.com/globe/wut/#q:C_ColorUtil.ConvertHSLToHSV)
* [![Townlong-Yak BAD.png](/images/thumb/Townlong-Yak_BAD.png/16px-Townlong-Yak_BAD.png?ca02cf)](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_ColorUtil.ConvertHSLToHSV)  [Townlong Yak](https://www.townlong-yak.com/framexml/beta/Blizzard_APIDocumentation#C_ColorUtil.ConvertHSLToHSV)
* [![Blizz.gif](/images/Blizz.gif?984542)](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22ConvertHSLToHSV\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)  [Blizzard Docs](https://github.com/search?q=repo:Gethe/wow-ui-source+\%22ConvertHSLToHSV\%22+path:/^Interface\/AddOns\/Blizzard_APIDocumentationGenerated\//&type=code)
* [![ProfIcons engineering.png](/images/thumb/ProfIcons_engineering.png/16px-ProfIcons_engineering.png?4717ae)](https://mrbuds.github.io/wow-api-web/?search=api:function:ConvertHSLToHSV:ColorUtil)  [/api addon](https://mrbuds.github.io/wow-api-web/?search=api:function:ConvertHSLToHSV:ColorUtil)

:   hslH
    :   number

    hslS
    :   number

    hslL
    :   number

hslH
:   number

hslS
:   number

hslL
:   number

:   hsvH
    :   number

    hsvS
    :   number

    hsvV
    :   number

hsvH
:   number

hsvS
:   number

hsvV
:   number

* This page was last edited on 3 January 2026, at 00:26.
* Pages that were created prior to October 2023 are adapted from the Fandom Wowpedia Wiki.  
  Page content is under [Creative Commons Attribution-ShareAlike 4.0 License](https://creativecommons.org/licenses/by-sa/4.0) unless otherwise noted.

* [Terms of Service](https://www.indie.io/terms-of-service)
* [Privacy policy](https://www.indie.io/privacy-policy)
* [Support Wiki](https://support.wiki.gg)
* [Send a ticket to wiki.gg](https://wiki.gg/go/servicedesk)
* [Status page](https://wikiggstatus.com)
* [Manage cookie settings](#)

* [![Creative Commons Attribution-ShareAlike 4.0 License](https://commons.wiki.gg/images/CC-BY-SA_footer_badge.svg?d931d3)![Creative Commons Attribution-ShareAlike 4.0 License](https://commons.wiki.gg/images/CC-BY-SA_footer_badge_dark.svg?55845c)](https://creativecommons.org/licenses/by-sa/4.0)
* [![Powered by MediaWiki](https://commons.wiki.gg/images/MediaWiki_footer_badge.svg?8c3a36)![Powered by MediaWiki](https://commons.wiki.gg/images/MediaWiki_footer_badge_dark.svg?12ec0a)](https://www.mediawiki.org/)
* [![Part of wiki.gg](https://commons.wiki.gg/images/d/d1/Network_footer_badge.svg?9d5a96)![Part of wiki.gg](https://commons.wiki.gg/images/2/23/Network_footer_badge_dark.svg?9cf3e8)](https://wiki.gg)