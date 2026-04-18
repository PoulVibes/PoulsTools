| [Main Menu](Warcraft_Wiki:Interface_customization.md "Warcraft Wiki:Interface customization") |
| --- |
| * [WoW API](World_of_Warcraft_API.md "World of Warcraft API") * [Lua API](Lua_functions.md "Lua functions") * [FrameXML API](FrameXML_functions.md "FrameXML functions")  ---  * [Widget API](Widget_API.md "Widget API") * [Widget scripts](Widget_script_handlers.md "Widget script handlers") * [XML schema](XML_schema.md "XML schema") * [Events](Events.md "Events") * [CVars](Console_variables.md "Console variables")  ---  * [Macro commands](Macro_commands.md "Macro commands") * [Combat Log](COMBAT_LOG_EVENT.md "COMBAT LOG EVENT") * [Escape sequences](UI_escape_sequences.md "UI escape sequences") * [Hyperlinks](Hyperlinks.md "Hyperlinks") * [API changes](API_change_summaries.md "API change summaries") * [HOWTOs](HOWTOs.md "HOWTOs") * [Discord logo.png](https://discord.gg/txUg39Vhc6) [wowuidev](https://discord.gg/txUg39Vhc6) |

```
str = string.concat(...)
    = strconcat
```

```
/dump strconcat("hello", "world", 123) -- helloworld123
```

`string.concat`
`strconcat`

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

:   ...
    :   string - Strings to concatenate.

...
:   string - Strings to concatenate.

:   str
    :   string - Returns a string with all arguments concatenated.

str
:   string - Returns a string with all arguments concatenated.

* [![Midnight](/images/thumb/Midnight-inline.png/40px-Midnight-inline.png?801468)](World_of_Warcraft:_Midnight.md "Midnight") **[Patch 12.0.0](Patch_12.0.0/API_changes.md "Patch 12.0.0/API changes") (2026-01-20):** Added `string.concat`
* [![Burning Crusade](/images/Bc_icon.gif?6fe702)](World_of_Warcraft:_The_Burning_Crusade.md "Burning Crusade") **[Patch 2.0.1](Patch_2.0.1/API_changes.md "Patch 2.0.1/API changes") (2006-12-05):** Added `strconcat`

* [table.concat](API_table.concat.md "API table.concat")