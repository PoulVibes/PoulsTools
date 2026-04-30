-- SBA_Simple_OverrideGUI.lua
-- Graphical priority-list override builder for SBA_Simple.
--
-- Usage:   /sbas override_gui     → open for the current spec
--
-- Rules are stored in SBA_SimpleDB.gui[specID] and compiled to
-- SBA_SimpleDB.specs[specID].overrideCode when saved.
-- The text-editor (/sbas override) still works independently.

-------------------------------------------------------------------------------
-- 1.  Condition type registry
--     Each entry defines one kind of condition that can be added to a rule.
--     Fields:
--       id            key stored in saved data
--       label         displayed in the picker
--       needsValue    (opt) true → show a numeric input field
--       valueLabel    (opt) label for the value field
--       default       (opt) default numeric value
--       needsSpell    (opt) true → show This Spell / Other Spell toggle
--       needsResource (opt) true → show resource type + operator selectors + value input
--       needsCompareValue (opt) true → show operator selector + value input
--       needsLua      (opt) true → show a free-text Lua expression input
--       generate(cond, ruleSpellID) → Lua fragment string
-------------------------------------------------------------------------------
-- Resolves which spell ID to use: "this"/nil → rule's spell; number → that ID.
-- Also handles old saved data that used the targetID field.
local function ResolveSpell(c, s)
    if not c.spell or c.spell == "this" then return s end
    if type(c.spell) == "number"        then return c.spell end
    return c.targetID or s
end

-- Forward declaration: allows closures defined below (COND_TYPES, CondSummaryText, etc.)
-- to read the currently-edited spec without a circular dependency on section 11.
local editSpecID = 0

-- Per-spec secondary (non-energy) resource. The "resource" condition type uses this
-- to emit the correct Lua variable in both generated code and the summary display.
-- Specs not listed have no secondary resource queryable in the Secret Value System
-- (e.g. Warriors, Balance Druid, Brewmaster) and fall through to the default, which
-- emits chi for backwards-compatibility with Windwalker data from before specID was known.
local SPEC_SECONDARY_DEFAULT = { varName = "chi",         powerType = "Chi",         label = "Chi"        }
local SPEC_SECONDARY = {
    -- Monk: only Windwalker uses Chi as a secondary resource.
    -- Brewmaster uses Energy (primary — not SVS-queryable); no secondary.
    [269] = { varName = "chi",         powerType = "Chi",         label = "Chi"        },  -- Windwalker
    -- Rogue (all specs: Combo Points are secondary)
    [259] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts"  },  -- Assassination
    [260] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts"  },  -- Outlaw
    [261] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts"  },  -- Subtlety
    -- Druid: Feral uses Combo Points as secondary (Energy is primary)
    [103] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts"  },  -- Feral
    -- Death Knight: Runic Power is secondary (Runes are the primary builder)
    [250] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr"  },  -- Blood
    [251] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr"  },  -- Frost
    [252] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr"  },  -- Unholy
    -- Paladin: Holy Power is secondary (Mana is primary)
    [65]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr"   },  -- Holy
    [66]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr"   },  -- Protection
    [70]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr"   },  -- Retribution
    -- Warlock: Soul Shards are secondary (Mana is primary)
    [265] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" }, -- Affliction
    [266] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" }, -- Demonology
    [267] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" }, -- Destruction
    -- Shadow Priest: Insanity is secondary (Mana is primary)
    [258] = { varName = "insanity",    powerType = "Insanity",    label = "Insanity"   },
    -- Enhancement Shaman: Maelstrom is the PRIMARY resource — not SVS-queryable; omitted.
    -- Demon Hunter: Fury (Havoc) and Pain (Vengeance) are PRIMARY resources — not SVS-queryable; omitted.
    -- Evoker: Essence is PRIMARY (mana equivalent) — not SVS-queryable; omitted.
    -- BM Hunter: Focus is the primary resource.  It is a secret value in combat;
    --   FocusGuesstimator exposes the estimate as the global currentFocus instead.
    --   inlineExpr marks that no UnitPower() local is emitted in generated code.
    [253] = { varName = "currentFocus", inlineExpr = "(_G.currentFocus or 0)", label = "Focus" },
}

-- Forward declarations used by condition generators defined before helper bodies.
local BuildPluginConditionExpr
local BuildPluginSummary

local COND_TYPES = {
    -- Spell-based checks (needsSpell = true → picker shows This Spell / Other Spell toggle)
    { id = "on_cd",        label = "Ready (Off-Cooldown)",        shortLabel = "Ready",   needsSpell = true,
      generate = function(c, s) local id = ResolveSpell(c,s) return ("(not C_Spell.GetSpellCooldown(%d).isActive or C_Spell.GetSpellCooldown(%d).isOnGCD)"):format(id, id) end },
    { id = "reactive_enabled", label = "Reactive Spell Enabled",  shortLabel = "Enabled", needsSpell = true,
      generate = function(c, s) return ("C_Spell.GetSpellCooldown(%d).isEnabled"):format(ResolveSpell(c,s)) end },
    { id = "usable",       label = "Is Usable",                  shortLabel = "Usable",  needsSpell = true,
      generate = function(c, s) return ("C_Spell.IsSpellUsable(%d)"):format(ResolveSpell(c,s)) end },
    { id = "talented",     label = "Talented",                  needsSpell = true,
      generate = function(c, s) return ("IsPlayerSpell(%d)"):format(ResolveSpell(c,s)) end },
    -- SBA
    { id = "sba_suggests", label = "SBA Suggests", needsSpell = true,
      generate = function(c, s)
          local id = (not c.spell or c.spell == "this") and s
                     or (type(c.spell) == "number" and c.spell or c.targetID or s)
          return ("spellID == %d"):format(id)
      end },
    -- Resource (Chi / Energy with operator)
        { id = "resource",     label = "Resource Check", needsResource = true,
      generate = function(c, s)
          local sec = SPEC_SECONDARY[editSpecID] or SPEC_SECONDARY_DEFAULT
          local var = (c.resource == "energy") and "(_G.currentEnergy or 0)"
                      or sec.inlineExpr or sec.varName
          local op  = c.operator or ">="
          return ("%s %s %d"):format(var, op, c.value or 0)
      end },
        { id = "target_count", label = "Target Count", shortLabel = "Targets", needsCompareValue = true, valueLabel = "Count", default = 1,
            generate = function(c, s)
                    local op = c.operator or ">="
                    return ("(_G.ECT_TargetCount or 0) %s %d"):format(op, c.value or 0)
            end },
        { id = "custom_lua",   label = "Custom Lua Expression", needsLua = true,
            generate = function(c, s)
                    local expr = (c.luaCode and c.luaCode:match("^%s*(.-)%s*$")) or ""
                    if expr == "" then return "false" end
                    return "(" .. expr .. ")"
            end },
        -- Plugin / Proc (Zenith, BOK, RWK, DOCJ — pick via dropdown)
        { id = "plugin",       label = "Plugin / Proc", needsPlugin = true,
      generate = function(c, s)
                                        return BuildPluginConditionExpr(c, s)
      end },
        { id = "last_combo_eq",label = "Last Combo Strike = Spell", shortLabel = "Combo", needsSpell = true,
            generate = function(c, s) return ("LastComboStrikeSpellID == %d"):format(ResolveSpell(c,s)) end },
    { id = "last_ability_eq", label = "Last Ability Used = Spell", shortLabel = "LastAbility", needsSpell = true,
        generate = function(c, s) return ("LastAbilityUsedSpellID == %d"):format(ResolveSpell(c,s)) end },
}
local COND_BY_ID = {}
for _, ct in ipairs(COND_TYPES) do COND_BY_ID[ct.id] = ct end

-- Plugin options shown inside the Plugin / Proc condition picker
local PLUGIN_OPTS_WW = {
    { id = "zenith",    label = "Zenith"            },
    { id = "last_combo_eq", label = "Combo"         },
    { id = "bok_proc",  label = "Blackout Kick!",    supportsProcMode = true, default = 4 },
    { id = "rwk_proc",  label = "Rushing Wind Kick", supportsProcMode = true, default = 4 },
    { id = "docj_proc", label = "Dance of Chi-Ji",   supportsProcMode = true, default = 4 },
    { id = "tod_proc",  label = "Touch of Death" },
}

local PLUGIN_OPTS_BM = {
    { id = "bestial_wrath_active",    label = "Bestial Wrath Active" },
    { id = "bestial_wrath_cooldown",  label = "Bestial Wrath Cooldown", supportsProcMode = true, default = 90 },
    { id = "barbed_shot_debuff",      label = "Barbed Shot Debuff",     supportsProcMode = true, default = 12 },
    { id = "withering_fire_active",   label = "Withering Fire Active" },
    { id = "withering_fire",          label = "Withering Fire",         supportsProcMode = true, default = 10 },
    { id = "howl_proc",               label = "Howl of the Pack Leader",supportsProcMode = true, default = 29 },
    { id = "black_arrow_proc",        label = "Black Arrow" },
    { id = "wailing_arrow_proc",      label = "Wailing Arrow",          supportsProcMode = true, default = 15 },
    { id = "hogstrider_proc",         label = "Hogstrider (Cobra Shot)", supportsProcMode = true, default = 19 },
    { id = "natures_ally",            label = "Nature's Ally Active" },
    { id = "beast_cleave",            label = "Beast Cleave",            supportsProcMode = true, default = 8 },
}

local WINDWALKER_SPEC_ID = 269
local BM_HUNTER_SPEC_ID = 253

local function IsWindwalkerGUI()
    return editSpecID == WINDWALKER_SPEC_ID
end

local function IsBeastMasteryHunterGUI()
    return editSpecID == BM_HUNTER_SPEC_ID
end

local function SupportsPluginGUI()
    return IsWindwalkerGUI() or IsBeastMasteryHunterGUI()
end

local function GetVisibleCondTypes()
    local out = {}
    for _, ct in ipairs(COND_TYPES) do
        -- Last Combo Strike is selected through Plugin / Proc -> Select plugin...
        if ct.id ~= "last_combo_eq" then
            if SupportsPluginGUI() then
                out[#out + 1] = ct
            elseif ct.id ~= "plugin" then
                out[#out + 1] = ct
            end
        end
    end
    return out
end

local function GetVisiblePluginOptions()
    if IsWindwalkerGUI() then return PLUGIN_OPTS_WW end
    if IsBeastMasteryHunterGUI() then return PLUGIN_OPTS_BM end
    return {}
end

local PROC_PLUGIN_BY_ID = {
    bok_proc = {
        label = "Blackout Kick!",
        activeFlag = "bok_proc_active",
        timerVar = "bok_proc_timer",
    },
    rwk_proc = {
        label = "Rushing Wind Kick",
        activeFlag = "rwk_proc_active",
        timerVar = "rwk_proc_timer",
    },
    docj_proc = {
        label = "Dance of Chi-Ji",
        activeFlag = "docj_proc_active",
        timerVar = "docj_proc_timer",
    },
    tod_proc = {
        label = "Touch of Death",
        activeFlag = "tod_proc_active",
    },
    withering_fire = {
        label = "Withering Fire",
        activeFlag = "WitheringFireActiveTracker",
        timerVar = "WitheringFireRemaining",
    },
    bestial_wrath_cooldown = {
        label = "Bestial Wrath Cooldown",
        activeFlag = "BestialWrathCooldownActiveTracker",
        timerVar = "BestialWrathCooldownRemaining",
    },
    barbed_shot_debuff = {
        label = "Barbed Shot Debuff",
        activeFlag = "BarbedShotDebuffActiveTracker",
        timerVar = "BarbedShotDebuffRemaining",
    },
    howl_proc = {
        label = "Howl of the Pack Leader",
        activeFlag = "howl_proc_active",
        timerVar = "howl_proc_timer",
    },
    black_arrow_proc = {
        label = "Black Arrow",
        activeFlag = "black_arrow_proc_active",
    },
    wailing_arrow_proc = {
        label = "Wailing Arrow",
        activeFlag = "wailing_arrow_proc_active",
        timerVar = "wailing_arrow_proc_timer",
    },
    hogstrider_proc = {
        label = "Hogstrider",
        activeFlag = "hogstrider_proc_active",
        timerVar = "hogstrider_proc_timer",
    },
    natures_ally = {
        label = "Nature's Ally",
        activeFlag = "NaturesAllyActiveTracker",
    },
    beast_cleave = {
        label = "Beast Cleave",
        activeFlag = "BeastCleaveActiveTracker",
        timerVar = "BeastCleaveRemaining",
    },
}

local VALID_COMP_OPS = {
    [">="] = true,
    ["<="] = true,
    ["=="] = true,
    [">"] = true,
    ["<"] = true,
}

local function IsCompOp(op)
    return op and VALID_COMP_OPS[op] or false
end

local function NormalizePluginState(cond)
    local plugin = cond and cond.plugin or nil
    local op = cond and cond.operator or nil
    local value = cond and cond.value or nil

    -- Backward compatibility: old saves used a separate docj_timer plugin id.
    if plugin == "docj_timer" then
        plugin = "docj_proc"
        op = IsCompOp(op) and op or "<"
        value = value or 4
    end

    return plugin, op, value
end

BuildPluginConditionExpr = function(cond, ruleSpellID)
    local plugin, op, value = NormalizePluginState(cond)
    if plugin == "zenith" then return "ZenithActiveTracker" end
    if plugin == "bestial_wrath_active" then return "BestialWrathActiveTracker" end
    if plugin == "withering_fire_active" then return "WitheringFireActiveTracker" end
    if plugin == "last_combo_eq" then
        return ("LastComboStrikeSpellID == %d"):format(ruleSpellID or 0)
    end

    local meta = PROC_PLUGIN_BY_ID[plugin]
    if not meta then return "false" end
    if IsCompOp(op) then
        if plugin == "withering_fire" then
            return ("(WitheringFireActiveTracker == true) and ((tonumber(%s) or 0) %s %d)"):format(meta.timerVar, op, value or 10)
        end
        if plugin == "bestial_wrath_cooldown" then
            return ("(((%s == true) and (tonumber(%s) or 0)) or 0) %s %d")
                :format(meta.activeFlag, meta.timerVar, op, value or 90)
        end
        if plugin == "barbed_shot_debuff" then
            return ("(((%s == true) and (tonumber(%s) or 0)) or 0) %s %d")
                :format(meta.activeFlag, meta.timerVar, op, value or 12)
        end
        if plugin == "beast_cleave" then
            return ("(((%s == true) and (tonumber(%s) or 0)) or 0) %s %d")
                :format(meta.activeFlag, meta.timerVar, op, value or 8)
        end
        return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 4)
    end
    return ("(%s == true)"):format(meta.activeFlag)
end

BuildPluginSummary = function(cond)
    local plugin, op, value = NormalizePluginState(cond)
    if plugin == "zenith" then return "Zenith" end
    if plugin == "bestial_wrath_active" then return "Bestial Wrath Active" end
    if plugin == "withering_fire_active" then return "Withering Fire Active" end
    if plugin == "last_combo_eq" then return "Combo" end

    local meta = PROC_PLUGIN_BY_ID[plugin]
    if not meta then return plugin or "?" end
    if IsCompOp(op) then
        return meta.label .. " " .. op .. " " .. tostring(value or 4)
    end
    return meta.label .. " Active"
end

-------------------------------------------------------------------------------
-- 2.  Data helpers
-------------------------------------------------------------------------------

-- The SBA "Single-Button Assistant" virtual button spell ID.
-- When a player tries to add this spell to the priority list we substitute
-- the spell that the Assisted Combat system is currently recommending.
local SBA_BUTTON_SPELL_ID = 1229376

-- Resolves a spell ID / name pair before inserting into the priority list.
-- Returns: resolvedID, resolvedName  (both nil if resolution fails)
local function ResolveSpellForAdd(id, name)
    return id, name
end

local function GuiDB()
    SBA_SimpleDB       = SBA_SimpleDB or {}
    SBA_SimpleDB.gui   = SBA_SimpleDB.gui or {}
    return SBA_SimpleDB.gui
end

local function GetGuiRules(specID)
    local db = GuiDB()
    db[specID] = db[specID] or {}
    return db[specID]
end

local function DeepCopyRules(src)
    local out = {}
    for i, r in ipairs(src) do
        local conds = {}
        for j, c in ipairs(r.conditions or {}) do
            conds[j] = {
                type     = c.type,
                value    = c.value,
                luaCode  = c.luaCode,
                negate   = c.negate,
                spell    = c.spell,
                targetID = c.targetID,
                resource = c.resource,
                operator = c.operator,
                plugin   = c.plugin,
                junction = c.junction,
                lparen   = c.lparen,
                rparen   = c.rparen,
            }
        end
        out[i] = { spellID = r.spellID, name = r.name, conditions = conds }
    end
    return out
end

local function EncodeField(v)
    if v == nil then return "" end
    local s = tostring(v)
    s = s:gsub("%%", "%%25")
    s = s:gsub("\r", "%%0D")
    s = s:gsub("\n", "%%0A")
    s = s:gsub("|", "%%7C")
    s = s:gsub(",", "%%2C")
    s = s:gsub(";", "%%3B")
    s = s:gsub("~", "%%7E")
    s = s:gsub("%(", "%%28")
    s = s:gsub("%)", "%%29")
    return s
end

local function DecodeField(v)
    if not v or v == "" then return "" end
    return (v:gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end))
end

local function SplitPipe(line)
    local out = {}
    local start = 1
    while true do
        local idx = line:find("|", start, true)
        if not idx then
            out[#out + 1] = line:sub(start)
            break
        end
        out[#out + 1] = line:sub(start, idx - 1)
        start = idx + 1
    end
    return out
end

local function SerializeRulesForExport(specID, rules)
    local lines = {}
    lines[#lines + 1] = ("SBASGUI|1|%d"):format(specID or 0)
    for _, rule in ipairs(rules or {}) do
        lines[#lines + 1] = table.concat({
            "R",
            EncodeField(rule.spellID or 0),
            EncodeField(rule.name or ""),
        }, "|")

        for _, cond in ipairs(rule.conditions or {}) do
            local spellMode = ""
            local spellID = ""
            if cond.spell == "this" or cond.spell == nil then
                spellMode = "this"
            elseif type(cond.spell) == "number" then
                spellMode = "num"
                spellID = cond.spell
            elseif cond.targetID then
                spellMode = "num"
                spellID = cond.targetID
            end

            lines[#lines + 1] = table.concat({
                "C",
                EncodeField(cond.type or ""),
                EncodeField(cond.negate and "1" or "0"),
                EncodeField(spellMode),
                EncodeField(spellID),
                EncodeField(cond.resource),
                EncodeField(cond.operator),
                EncodeField(cond.plugin),
                EncodeField(cond.value),
                EncodeField(cond.junction),
                EncodeField(cond.lparen),
                EncodeField(cond.rparen),
                EncodeField(cond.luaCode),
            }, "|")
        end

        lines[#lines + 1] = "E"
    end
    return table.concat(lines, "\n")
end

local function SplitByChar(s, sep)
    local out = {}
    local start = 1
    while true do
        local idx = s:find(sep, start, true)
        if not idx then
            out[#out + 1] = s:sub(start)
            break
        end
        out[#out + 1] = s:sub(start, idx - 1)
        start = idx + 1
    end
    return out
end

-- Ensure export headers always carry a real specialization ID (e.g. 269), not
-- a specialization index (1-4). Some call paths can accidentally pass indices.
local function NormalizeExportSpecID(specID)
    local sid = tonumber(specID) or 0
    if sid > 4 then return sid end

    if editSpecID and editSpecID > 4 then
        return editSpecID
    end

    if sid > 0 and sid <= 4 and type(GetSpecializationInfo) == "function" then
        local byIndex = select(1, GetSpecializationInfo(sid))
        if byIndex and byIndex > 0 then
            return byIndex
        end
    end

    if type(CurrentSpecID) == "function" then
        local cur = CurrentSpecID()
        if cur and cur > 0 then
            return cur
        end
    end

    return sid
end

local NormalizeRuleParens

-- v2 compact format (single line):
-- SBASGUI2|1|<spec>;R,<spellID>,<name>,<cond>,<cond>;R,...
-- Condition token: <j><(><body><)>
-- j is "&&" or "||" for non-first conditions; first has no junction prefix.
-- body fields are ~-separated and percent-encoded:
-- type~neg~spellMode~spellID~resource~operator~plugin~value~lua
local function SerializeRulesForExportV2(specID, rules)
    local chunks = {}
    local exportSpecID = NormalizeExportSpecID(specID)
    chunks[#chunks + 1] = ("SBASGUI2|1|%d"):format(exportSpecID or 0)

    for _, rule in ipairs(rules or {}) do
        local ruleParts = {
            "R",
            EncodeField(rule.spellID or 0),
            EncodeField(rule.name or ""),
        }

        for idx, cond in ipairs(rule.conditions or {}) do
            local spellMode = ""
            local spellID = ""
            if cond.spell == "this" or cond.spell == nil then
                spellMode = "this"
            elseif type(cond.spell) == "number" then
                spellMode = "num"
                spellID = cond.spell
            elseif cond.targetID then
                spellMode = "num"
                spellID = cond.targetID
            end

            local body = table.concat({
                EncodeField(cond.type or ""),
                EncodeField(cond.negate and "1" or "0"),
                EncodeField(spellMode),
                EncodeField(spellID),
                EncodeField(cond.resource),
                EncodeField(cond.operator),
                EncodeField(cond.plugin),
                EncodeField(cond.value),
                EncodeField(cond.luaCode),
            }, "~")

            local j = ""
            if idx > 1 then
                j = (cond.junction == "or") and "||" or "&&"
            end
            local lp = (cond.lparen and cond.lparen > 0) and string.rep("(", cond.lparen) or ""
            local rp = (cond.rparen and cond.rparen > 0) and string.rep(")", cond.rparen) or ""

            ruleParts[#ruleParts + 1] = j .. lp .. body .. rp
        end

        chunks[#chunks + 1] = table.concat(ruleParts, ",")
    end

    return table.concat(chunks, ";")
end

local function DeserializeRulesFromExportV2(text, expectedSpecID)
    local payload = (text or ""):match("^%s*(.-)%s*$") or ""
    local chunks = SplitByChar(payload, ";")
    if #chunks == 0 or not chunks[1] or chunks[1] == "" then
        return nil, "Import text is empty."
    end

    local header = SplitPipe(chunks[1])
    if header[1] ~= "SBASGUI2" then
        return nil, "Missing v2 export header (expected SBASGUI2)."
    end
    local rawVersion = tostring(header[2] or "")
    rawVersion = rawVersion:match("^%s*(.-)%s*$") or ""
    local version = tonumber(rawVersion) or tonumber(rawVersion:match("(%d+)"))
    local rawSpec = tostring(header[3] or "")
    local sourceSpecID = tonumber(rawSpec:match("^(%d+)$")) or 0

    -- Compatibility recovery for malformed v2 headers where version/spec fields
    -- can be blank or shifted when copied through some text paths.
    if not version and rawVersion == "" then
        version = 1
    end
    -- Handle shifted header variant: SBASGUI2||1|269
    -- In this case header[3] carries version and header[4] carries spec.
    if rawVersion == "" and sourceSpecID > 0 and (sourceSpecID == 1 or sourceSpecID == 2) and #header >= 4 then
        local shiftedSpec = tonumber(tostring(header[4] or ""):match("^(%d+)")) or 0
        if shiftedSpec > 0 then
            version = sourceSpecID
            sourceSpecID = shiftedSpec
        end
    end
    -- If the spec token has trailing non-digits (e.g. malformed header that bled into
    -- the next record), recover by taking the leading numeric prefix only.
    if sourceSpecID == 0 then
        sourceSpecID = tonumber(rawSpec:match("^(%d+)")) or 0
    end
    if not version and #header >= 3 then
        for i = 2, #header do
            local token = tostring(header[i] or "")
            local n = tonumber(token) or tonumber(token:match("(%d+)"))
            if not version and (n == 1 or n == 2) then
                version = n
            end
        end
    end
    if version ~= 1 and version ~= 2 then
        return nil, "Unsupported v2 export version: " .. rawVersion
    end

    -- Spec IDs are values like 62, 269, 577... If parsing yields 1-4, that's a
    -- specialization index from malformed/copied headers, not a real spec ID.
    -- Treat it as unknown to avoid false mismatch failures on self-export/import.
    if sourceSpecID > 0 and sourceSpecID <= 4 then
        sourceSpecID = 0
    end

    if expectedSpecID and expectedSpecID ~= 0 and sourceSpecID ~= 0 and sourceSpecID ~= expectedSpecID then
        return nil, ("Spec mismatch: import is for spec %d, current GUI is spec %d."):format(sourceSpecID, expectedSpecID)
    end

    local out = {}
    for i = 2, #chunks do
        local line = chunks[i]
        if line and line ~= "" then
            local parts = SplitByChar(line, ",")
            if parts[1] ~= "R" then
                return nil, "Invalid v2 record tag: " .. tostring(parts[1])
            end

            local spellID = tonumber(DecodeField(parts[2] or "")) or 0
            local name = DecodeField(parts[3] or "")
            if name == "" then name = tostring(spellID) end

            local rule = { spellID = spellID, name = name, conditions = {} }
            for ci = 4, #parts do
                local tok = parts[ci] or ""
                if tok ~= "" then
                    local junction
                    if tok:sub(1, 2) == "&&" then
                        junction = "and"
                        tok = tok:sub(3)
                    elseif tok:sub(1, 2) == "||" then
                        junction = "or"
                        tok = tok:sub(3)
                    elseif tok:sub(1, 1) == "&" then
                        junction = "and"
                        tok = tok:sub(2)
                    elseif tok:sub(1, 1) == "|" then
                        junction = "or"
                        tok = tok:sub(2)
                    end

                    local lp = 0
                    while tok:sub(1, 1) == "(" do
                        lp = lp + 1
                        tok = tok:sub(2)
                    end

                    local rp = 0
                    while tok:sub(-1) == ")" do
                        rp = rp + 1
                        tok = tok:sub(1, -2)
                    end

                    local cols = SplitByChar(tok, "~")
                    local function col(idx)
                        return DecodeField(cols[idx] or "")
                    end

                    local cond = {
                        type = col(1),
                        negate = col(2) == "1",
                    }

                    local spellMode = col(3)
                    local cSpellID = tonumber(col(4))
                    if spellMode == "this" then
                        cond.spell = "this"
                    elseif spellMode == "num" and cSpellID then
                        cond.spell = cSpellID
                        cond.targetID = cSpellID
                    end

                    local resource = col(5)
                    local operator = col(6)
                    local plugin = col(7)
                    local value = tonumber(col(8))
                    local luaCode = col(9)

                    if resource ~= "" then cond.resource = resource end
                    if operator ~= "" then cond.operator = operator end
                    if plugin ~= "" then cond.plugin = plugin end
                    if value ~= nil then cond.value = value end
                    if luaCode ~= "" then cond.luaCode = luaCode end
                    if junction ~= nil then cond.junction = junction end
                    if lp > 0 then cond.lparen = lp end
                    if rp > 0 then cond.rparen = rp end

                    rule.conditions[#rule.conditions + 1] = cond
                end
            end

            NormalizeRuleParens(rule.conditions)
            out[#out + 1] = rule
        end
    end

    return out
end

local SPELL_MODE_SET = {
    ["this"] = true,
    ["num"] = true,
}

local RESOURCE_SET = {
    ["chi"] = true,
    ["energy"] = true,
}

local PLUGIN_SET = {
    ["zenith"] = true,
    ["last_combo_eq"] = true,
    ["bok_proc"] = true,
    ["rwk_proc"] = true,
    ["docj_proc"] = true,
    ["docj_timer"] = true,
    ["barbed_shot_debuff"] = true,
}

local function InferMissingPrefix(raw, validSet)
    if not raw or raw == "" then return raw end
    if validSet[raw] then return raw end
    for k in pairs(validSet) do
        if #k == (#raw + 1) and k:sub(2) == raw then
            return k
        end
    end
    return raw
end

local function InferCondType(raw)
    if not raw or raw == "" then return "" end
    if COND_BY_ID[raw] then return raw end
    for id in pairs(COND_BY_ID) do
        if #id == (#raw + 1) and id:sub(2) == raw then
            return id
        end
    end
    return raw
end

local function NormalizeImportLines(lines)
    local out = {}
    for _, ln in ipairs(lines) do
        local startsNew = (ln == "E") or ln:match("^R|") or ln:match("^C")
        if #out > 0 and not startsNew and out[#out]:sub(1, 1) == "C" then
            -- Some payloads split one condition record over multiple lines.
            out[#out] = out[#out] .. "|" .. ln
        else
            out[#out + 1] = ln
        end
    end
    return out
end

local function ParseConditionRelaxed(parts)
    local mergedTag = parts[1] or ""
    local typeRaw, negateRaw, startIdx

    if mergedTag == "C" then
        typeRaw   = DecodeField(parts[2] or "")
        negateRaw = DecodeField(parts[3] or "0")
        startIdx  = 4
    else
        -- Legacy malformed line where first field is like "Calented".
        typeRaw   = DecodeField(mergedTag:sub(2))
        negateRaw = DecodeField(parts[2] or "0")
        startIdx  = 3
    end

    local impliedSpellMode = ""
    local nDigit, tail = negateRaw:match("^([01])(.*)$")
    if nDigit then
        negateRaw = nDigit
        impliedSpellMode = tail or ""
    end

    local condType = InferCondType(typeRaw)
    local cond = {
        type = condType,
        negate = negateRaw == "1",
    }

    local def = COND_BY_ID[condType]
    if not def then
        cond.type = "custom_lua"
        cond.luaCode = table.concat(parts, "|")
        return cond
    end

    local tokens = {}
    for i = startIdx, #parts do
        tokens[#tokens + 1] = DecodeField(parts[i] or "")
    end

    local spellMode = InferMissingPrefix(tokens[1] ~= "" and tokens[1] or impliedSpellMode, SPELL_MODE_SET)
    local spellID = tonumber(tokens[2] or "")

    if def.needsSpell then
        if spellMode == "num" and spellID then
            cond.spell = spellID
            cond.targetID = spellID
        else
            cond.spell = "this"
        end
    end

    if def.needsResource then
        for _, tok in ipairs(tokens) do
            local res = InferMissingPrefix(tok, RESOURCE_SET)
            if RESOURCE_SET[res] then cond.resource = res end
            if VALID_COMP_OPS[tok] then cond.operator = tok end
            local n = tonumber(tok)
            if n ~= nil then cond.value = n end
        end
        cond.resource = cond.resource or "chi"
        cond.operator = cond.operator or ">="
        cond.value = cond.value or 0
    end

    if def.needsCompareValue then
        for _, tok in ipairs(tokens) do
            if VALID_COMP_OPS[tok] then cond.operator = tok end
            local n = tonumber(tok)
            if n ~= nil then cond.value = n end
        end
        cond.operator = cond.operator or ">="
        cond.value = cond.value or 0
    end

    if def.needsPlugin then
        for _, tok in ipairs(tokens) do
            local plugin = InferMissingPrefix(tok, PLUGIN_SET)
            if PLUGIN_SET[plugin] then cond.plugin = plugin end
            if VALID_COMP_OPS[tok] then cond.operator = tok end
            local n = tonumber(tok)
            if n ~= nil then cond.value = n end
        end
    end

    if def.needsLua then
        cond.luaCode = tokens[#tokens] or ""
    end

    for _, tok in ipairs(tokens) do
        if tok == "and" or tok == "or" then
            cond.junction = tok
            break
        end
    end

    return cond
end

NormalizeRuleParens = function(conds)
    local depth = 0
    for i, cond in ipairs(conds or {}) do
        local lp = tonumber(cond.lparen) or 0
        local rp = tonumber(cond.rparen) or 0
        if lp < 0 then lp = 0 end
        if rp < 0 then rp = 0 end

        -- Clamp closes so we never close more groups than are currently open.
        local maxClosable = depth + lp
        if rp > maxClosable then rp = maxClosable end

        cond.lparen = (lp > 0) and lp or nil
        cond.rparen = (rp > 0) and rp or nil
        depth = maxClosable - rp
    end

    -- Auto-close any trailing opens on the last condition to keep expressions valid.
    if depth > 0 and conds and #conds > 0 then
        local last = conds[#conds]
        last.rparen = (tonumber(last.rparen) or 0) + depth
    end
end

local function DeserializeRulesFromExport(text, expectedSpecID)
    local trimmedPayload = (text or ""):match("^%s*(.-)%s*$") or ""
    return DeserializeRulesFromExportV2(trimmedPayload, expectedSpecID)
end

-------------------------------------------------------------------------------
-- 3.  Code generator
-------------------------------------------------------------------------------
local function CondSummaryText(cond, ruleSpellID)
    local def = COND_BY_ID[cond.type]
    if not def then return "[obsolete: " .. (cond.type or "?") .. "]" end
    local prefix = cond.negate and "NOT " or ""
    local t
    if def.needsResource then
        local resName = (cond.resource == "energy") and "Energy"
                        or (SPEC_SECONDARY[editSpecID] or SPEC_SECONDARY_DEFAULT).label
        local op      = cond.operator or ">="
        t = resName .. " " .. op .. " " .. tostring(cond.value or 0)
    elseif def.needsCompareValue then
        local op = cond.operator or ">="
        t = (def.shortLabel or def.label) .. " " .. op .. " " .. tostring(cond.value or 0)
    elseif def.needsLua then
        local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
        if expr == "" then expr = "(empty)" end
        if #expr > 52 then expr = expr:sub(1, 49) .. "..." end
        t = "Lua: " .. expr
    elseif def.needsPlugin then
        t = BuildPluginSummary(cond)
    else
        if def.needsSpell then
            if cond.type == "sba_suggests" then
                if not cond.spell or cond.spell == "this" then
                    t = "SBA = [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
                    t = "SBA = [" .. (n or "?") .. "]"
                end
            else
                t = def.label
                if not cond.spell or cond.spell == "this" then
                    t = t .. " [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
                    t = t .. " [" .. (n or "?") .. "]"
                end
            end
        else
            t = def.label
        end
        if cond.value then t = t .. " " .. tostring(cond.value) end
    end
    return prefix .. t
end

local function GenerateCode(rules)
    if not rules or #rules == 0 then return nil end
    local L = {}

    -- Energy is referenced inline as (_G.currentEnergy or 0) in each expression,
    -- so no top-level local is needed (assigning a secret value to a local taints it).
    local _sec = SPEC_SECONDARY[editSpecID]   -- nil for specs with no queryable secondary

    L[#L+1] = "local spellID = C_AssistedCombat.GetNextCastSpell()"
    if _sec and not _sec.inlineExpr then
        -- Declare a local for the secondary resource only when it is read via
        -- UnitPower.  Specs using inlineExpr (e.g. BM Hunter / currentFocus)
        -- reference the global directly, so no local is needed or emitted.
        L[#L+1] = ('local %s = UnitPower("player", Enum.PowerType.%s)'):format(_sec.varName, _sec.powerType)
    end
    L[#L+1] = ""

    -- Pre-pass: build all condition fragments for every rule so we can count
    -- how many times each C_Spell.GetSpellCooldown(N) call appears across the
    -- entire output.  IDs that appear more than once across ANY rule will be
    -- hoisted into a single top-level local so no duplicate declarations are
    -- emitted when multiple rules reference the same spell's cooldown.
    local allRuleParts = {}   -- allRuleParts[i] = {parts=..., junctions=...}
    for i, rule in ipairs(rules) do
        if (rule.spellID or 0) > 0 then
            local parts        = {}
            local junctions    = {}
            for ci, cond in ipairs(rule.conditions or {}) do
                local def = COND_BY_ID[cond.type]
                if def then
                    local frag = def.generate(cond, rule.spellID)
                    if cond.negate then frag = "not (" .. frag .. ")" end
                    local lp = (cond.lparen or 0) > 0 and string.rep("(", cond.lparen) or ""
                    local rp = (cond.rparen or 0) > 0 and string.rep(")", cond.rparen) or ""
                    local partIdx = #parts + 1
                    parts[partIdx] = lp .. frag .. rp
                    if partIdx == 1 then
                        junctions[partIdx] = nil
                    else
                        local j = cond.junction
                        junctions[partIdx] = (j == "and" or j == "or") and j or "and"
                    end
                end
            end
            allRuleParts[i] = { parts = parts, junctions = junctions }
        else
            allRuleParts[i] = false
        end
    end

    -- Count total occurrences of each spell-ID across all rules.
    local cdTotalCount = {}
    local cdFirstSeenOrder = {}
    local cdSeen = {}
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for _, part in ipairs(rp.parts) do
                for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                    cdTotalCount[id] = (cdTotalCount[id] or 0) + 1
                    if not cdSeen[id] then
                        cdSeen[id] = true
                        cdFirstSeenOrder[#cdFirstSeenOrder + 1] = id
                    end
                end
            end
        end
    end

    -- Emit one top-level local for each spell ID that appears more than once,
    -- then substitute the variable name into every part that references it.
    local hoisted = {}   -- set of IDs already emitted as top-level locals
    for _, id in ipairs(cdFirstSeenOrder) do
        local count = cdTotalCount[id] or 0
        if count > 1 then
            local varName = "cd_" .. id
            L[#L+1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
            hoisted[id] = varName
        end
    end
    if next(hoisted) then L[#L+1] = "" end

    -- Substitute hoisted variable names into all pre-built parts.
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for id, varName in pairs(hoisted) do
                local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                for pi, part in ipairs(rp.parts) do
                    rp.parts[pi] = part:gsub(pattern, varName)
                end
            end
        end
    end

    local hasUnconditional = false
    for i, rule in ipairs(rules) do
        local rp = allRuleParts[i]
        if rp then
            local parts     = rp.parts
            local junctions = rp.junctions

            -- Within a single rule, hoist any cooldown calls that repeat
            -- more than once inside that rule alone (not already hoisted globally).
            if #parts > 1 then
                local cdCount = {}
                for _, part in ipairs(parts) do
                    for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                        if not hoisted[id] then
                            cdCount[id] = (cdCount[id] or 0) + 1
                        end
                    end
                end
                for id, count in pairs(cdCount) do
                    if count > 1 then
                        local varName = "cd_" .. id
                        L[#L+1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
                        local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                        for pi, part in ipairs(parts) do
                            parts[pi] = part:gsub(pattern, varName)
                        end
                        hoisted[id] = varName  -- prevent re-hoisting in later rules
                    end
                end
            end

            L[#L+1] = ("-- Priority %d: %s (%d)"):format(i, rule.name or "?", rule.spellID)
            if #parts > 0 then
                local expr = parts[1]
                for pi = 2, #parts do
                    expr = expr .. " " .. (junctions[pi] or "and") .. " " .. parts[pi]
                end
                if rule.spellID == SBA_BUTTON_SPELL_ID then
                    L[#L+1] = ("if %s then return spellID end"):format(expr)
                else
                    L[#L+1] = ("if %s then return %d end"):format(expr, rule.spellID)
                end
            else
                -- No conditions: unconditional (this blocks everything below it)
                if rule.spellID == SBA_BUTTON_SPELL_ID then
                    L[#L+1] = "return spellID  -- unconditional"
                else
                    L[#L+1] = ("return %d  -- unconditional"):format(rule.spellID)
                end
                hasUnconditional = true
            end
            L[#L+1] = ""
            if hasUnconditional then break end
        end
    end
    if not hasUnconditional then
        L[#L+1] = "-- Fallback: SBA assisted-combat suggestion"
        L[#L+1] = "return spellID"
    end
    return table.concat(L, "\n")
end

-------------------------------------------------------------------------------
-- 4.  Backdrop helper
-------------------------------------------------------------------------------
local function SetBD(f, r, g, b, a, er, eg, eb)
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(r or 0.05, g or 0.08, b or 0.12, a or 0.95)
    f:SetBackdropBorderColor(er or 0.2, eg or 0.35, eb or 0.5, 1)
end

-------------------------------------------------------------------------------
-- 5.  Spec name helper
-------------------------------------------------------------------------------
local function GetSpecName(specID)
    if specID and specID > 0 and GetSpecializationInfoByID then
        local specName = select(2, GetSpecializationInfoByID(specID))
        if specName then return specName end
    end
    return "Spec " .. tostring(specID)
end

local function CurrentSpecID()
    local si = GetSpecialization()
    if not si then return 0 end
    return select(1, GetSpecializationInfo(si)) or 0
end

-------------------------------------------------------------------------------
-- 6.  Condition-type picker popup
--     A floating popup listing all condition types as clickable buttons.
-------------------------------------------------------------------------------
local condPicker    = nil
local pluginPicker  = nil   -- forward-declared so CloseAllPopups can reference it
local addSpellPopup = nil   -- forward-declared so CloseAllPopups can reference it
local exportPopup   = nil
local importPopup   = nil
local opDropdownPopups = {} -- all MakeOpDropdown popup frames, closed by CloseAllPopups

local function CloseAllPopups()
    if condPicker   and condPicker:IsShown()   then condPicker:Hide()   end
    if pluginPicker and pluginPicker:IsShown() then pluginPicker:Hide() end
    if addSpellPopup and addSpellPopup:IsShown() then addSpellPopup:Hide() end
    if exportPopup and exportPopup:IsShown() then exportPopup:Hide() end
    if importPopup and importPopup:IsShown() then importPopup:Hide() end
    for _, p in ipairs(opDropdownPopups) do if p:IsShown() then p:Hide() end end
end

local function CreateCondPicker()
    local f = CreateFrame("Frame", "SBAS_GUI_CondPicker", UIParent, "BackdropTemplate")
    f:SetSize(272, 336)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Condition Type")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",  3, -20)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 22, 0), m))
    end)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(266, 4)
    sf:SetScrollChild(sc)

    f.callback = nil

    f.rows = {}
    f.scrollChild = sc
    f.UpdateRows = function(self)
        local visible = GetVisibleCondTypes()
        sc:SetHeight(math.max(4, #visible * 22 + 4))

        for i, ct in ipairs(visible) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Button", nil, sc)
                row:SetSize(262, 20)
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()
                row.bg:SetColorTexture(0, 0, 0, 0)
                row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.lbl:SetAllPoints()
                row.lbl:SetJustifyH("LEFT")
                row.lbl:SetTextColor(0.82, 0.9, 1, 1)
                self.rows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", sc, "TOPLEFT", 2, -2 - (i - 1) * 22)
            row.lbl:SetText("  " .. ct.label)
            row.ctRef = ct
            row:SetScript("OnClick", function(btn)
                self:Hide()
                if self.callback then self.callback(btn.ctRef) end
            end)
            row:SetScript("OnEnter", function(btn)
                btn.bg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
                btn.lbl:SetTextColor(1, 1, 1, 1)
            end)
            row:SetScript("OnLeave", function(btn)
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.lbl:SetTextColor(0.82, 0.9, 1, 1)
            end)
            row:Show()
        end

        for i = #visible + 1, #self.rows do
            self.rows[i]:Hide()
        end
    end

    return f
end

local function ShowCondPicker(anchor, callback)
    if not condPicker then condPicker = CreateCondPicker() end
    condPicker:UpdateRows()
    condPicker.callback = callback
    condPicker:ClearAllPoints()
    condPicker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    condPicker:Show()
    -- Keep on-screen: if it clips the bottom, flip above
    local bot = condPicker:GetBottom()
    if bot and bot < 0 then
        condPicker:ClearAllPoints()
        condPicker:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
end

-------------------------------------------------------------------------------
-- 7.  "Add Spell" popup
--     Enter a spell ID, see name/icon, confirm to add to the priority list.
-------------------------------------------------------------------------------
local function CreateAddSpellPopup()
    local f = CreateFrame("Frame", "SBAS_GUI_AddSpell", UIParent, "BackdropTemplate")
    f:SetSize(320, 130)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Add Spell by Name or ID")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local namInLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    namInLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    namInLbl:SetText("Name or ID:")
    namInLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(196, 22)
    nameBox:SetPoint("LEFT", namInLbl, "RIGHT", 6, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(80)

    local iconTex = f:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(28, 28)
    iconTex:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)
    iconTex:Hide()

    -- Result row: resolved ID + status
    local resultLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultLbl:SetPoint("TOPLEFT", namInLbl, "BOTTOMLEFT", 0, -8)
    resultLbl:SetSize(296, 16)
    resultLbl:SetJustifyH("LEFT")

    -- Stores the last successfully resolved spell
    local resolvedID   = nil
    local resolvedName = nil

    local function DoLookup()
        local input = nameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            resultLbl:SetText("")
            iconTex:Hide()
            resolvedID = nil
            return
        end

        local id = nil
        -- Numeric input: treat as a direct spell ID
        local numericID = tonumber(input)
        if numericID then
            id = numericID
        elseif C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            -- Name lookup
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end

        if id and id > 0 then
            local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id)
            if isPassive then
                resolvedID = nil
                resolvedName = nil
                resultLbl:SetText("|cffff5555That spell is passive and cannot be added|r")
                iconTex:Hide()
                return
            end
            local n   = C_Spell.GetSpellName   and C_Spell.GetSpellName(id)
            local tex = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
            resolvedID   = id
            resolvedName = n or input
            resultLbl:SetText("|cff55ee55" .. (n or input) .. "|r  |cff8899bbID: " .. id .. "|r")
            if tex then iconTex:SetTexture(tex) iconTex:Show() else iconTex:Hide() end
        else
            resolvedID = nil
            resolvedName = nil
            resultLbl:SetText("|cffff5555Spell not found|r")
            iconTex:Hide()
        end
    end

    nameBox:SetScript("OnTextChanged", DoLookup)
    nameBox:SetScript("OnEnterPressed", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        end
    end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(88, 24)
    addBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 10)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        else
            resultLbl:SetText("|cffff5555Enter a valid spell name or ID first|r")
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(88, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f.nameBox  = nameBox
    f.iconTex  = iconTex
    f.onAdd    = nil   -- set before showing

    return f
end

local function CreateTransferPopup(titleText, confirmText)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(520, 390)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText(titleText)
    title:SetTextColor(0.55, 0.82, 1, 1)

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    note:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -30)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.68, 0.78, 0.9, 1)
    f.note = note

    local boxFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    boxFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -52)
    boxFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 44)
    SetBD(boxFrame, 0.03, 0.05, 0.09, 0.95, 0.17, 0.28, 0.42)

    local sf = CreateFrame("ScrollFrame", nil, boxFrame)
    sf:SetPoint("TOPLEFT", boxFrame, "TOPLEFT", 4, -4)
    sf:SetPoint("BOTTOMRIGHT", boxFrame, "BOTTOMRIGHT", -4, 4)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 24, 0), m))
    end)

    local edit = CreateFrame("EditBox", nil, sf)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(486)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        local h = math.max(320, self:GetStringHeight() + 16)
        self:SetHeight(h)
    end)
    sf:SetScrollChild(edit)

    local confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    confirmBtn:SetSize(110, 24)
    confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
    confirmBtn:SetText(confirmText)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(110, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f.editBox = edit
    f.confirmBtn = confirmBtn

    return f
end

local function ShowExportPopup(anchor, specID, rules)
    if not exportPopup then
        exportPopup = CreateTransferPopup("Export SBA Rules", "Select All")
    end
    exportPopup.note:SetText("Copy this text and keep it as your backup for the currently open spec.")
    exportPopup.editBox:SetText(SerializeRulesForExportV2(specID, rules))
    exportPopup.confirmBtn:SetScript("OnClick", function()
        exportPopup.editBox:SetFocus()
        exportPopup.editBox:HighlightText()
    end)
    exportPopup:ClearAllPoints()
    exportPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    exportPopup:Show()
    exportPopup.editBox:SetFocus()
    exportPopup.editBox:HighlightText()
end

local function ShowImportPopup(anchor, onImport)
    if not importPopup then
        importPopup = CreateTransferPopup("Import SBA Rules", "Import")
    end
    importPopup.note:SetText("Paste exported text for this spec, then click Import.")
    importPopup.editBox:SetText("")
    importPopup.confirmBtn:SetScript("OnClick", function()
        if onImport and onImport(importPopup.editBox:GetText() or "") then
            importPopup:Hide()
        end
    end)
    importPopup:ClearAllPoints()
    importPopup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    importPopup:Show()
    importPopup.editBox:SetFocus()
end

-------------------------------------------------------------------------------
-- 8.  Main GUI state
-------------------------------------------------------------------------------
local GUI_W    = 680
local GUI_H    = 560
local LEFT_W   = 388
local RIGHT_W  = 268
local PAD      = 6
local ROW_H    = 72
local GUI_MIN_W = 680
local GUI_MIN_H = 560
local MIN_LEFT_W = 320
local MIN_RIGHT_W = 240

local guiFrame     = nil   -- main frame (created once)
local leftChild    = nil   -- scroll child for rule rows
local rightPanel   = nil   -- condition editor panel
local condInputArea= nil   -- "add condition" sub-frame inside rightPanel

local workingRules = {}    -- deep-copy being edited
-- editSpecID declared at top of file (forward declaration) so COND_TYPES closures can see it
local sessionRules = {}    -- in-session cache: specID -> workingRules table (survives close/reopen)
local selectedIdx  = 0     -- 1-based; 0 = none
local isAddingCond = false
local selectedCondIdx = nil  -- nil = adding new; number = editing existing cond at that index

local rowFrames        = {}    -- pool of rule-row frames
local condRowPool      = {}    -- pool of condition-row frames in right panel
local condJunctionPool = {}    -- pool of AND/OR junction toggles between condition rows
local condGroupBoxPool = {}    -- pool of backdrop boxes for matched parenthesis groups
local condRowYList     = {}    -- panel-relative Y of each cond row top (for drag hit-testing)

-- Forward declarations
local RefreshRuleList, RefreshRightPanel
-- Drag-infrastructure forward declarations (defined in section 11)
local ruleDrag      -- assigned in section 11 initialiser block
local dragIconFrame, dragCatcher
local EnsureDragIcon, EnsureDragCatcher
-- Condition-drag forward declarations
local condDrag, condCatcher, condDropLine
local EnsureCondCatcher

local function GetPanelWidths(totalWidth)
    totalWidth = totalWidth or (guiFrame and guiFrame:GetWidth()) or GUI_W
    local leftW = math.floor(totalWidth * (LEFT_W / GUI_W))
    leftW = math.max(MIN_LEFT_W, math.min(leftW, totalWidth - MIN_RIGHT_W - PAD * 4))
    local rightW = totalWidth - leftW - PAD * 4
    return leftW, rightW
end

local function GetLeftPanelWidth()
    return GetPanelWidths()
end

local function GetRightPanelWidth()
    local _, rightW = GetPanelWidths()
    return rightW
end

-------------------------------------------------------------------------------
-- 9.  Rule-row frames
-------------------------------------------------------------------------------
local function CreateRowFrame(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(GetLeftPanelWidth() - PAD * 2, ROW_H - 4)
    SetBD(f, 0.06, 0.10, 0.16, 0.88, 0.14, 0.24, 0.40)
    f:EnableMouse(true)

    -- Priority badge (GameFontNormal keeps 2-digit numbers inside the 26px width)
    f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.badge:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -4)
    f.badge:SetSize(26, 20)
    f.badge:SetJustifyH("CENTER")
    f.badge:SetTextColor(0.4, 0.62, 0.90, 1)

    -- Spell icon
    local iconBg = f:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(36, 36)
    iconBg:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -4)
    iconBg:SetColorTexture(0, 0, 0, 0.5)

    f.iconTex = f:CreateTexture(nil, "ARTWORK")
    f.iconTex:SetSize(34, 34)
    f.iconTex:SetPoint("CENTER", iconBg, "CENTER")
    f.iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- Spell name
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.nameLabel:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 6, 0)
    f.nameLabel:SetSize(LEFT_W - 186, 18)
    f.nameLabel:SetJustifyH("LEFT")
    f.nameLabel:SetTextColor(0.9, 0.95, 1, 1)

    -- Spell ID  
    f.idLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.idLabel:SetPoint("TOPLEFT", f.nameLabel, "BOTTOMLEFT", 0, -1)
    f.idLabel:SetTextColor(0.48, 0.60, 0.75, 1)

    -- Condition summary (anchored below ID label, grows downward)
    f.condLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.condLabel:SetPoint("TOPLEFT", f.idLabel, "BOTTOMLEFT", 0, -4)
    f.condLabel:SetWidth(LEFT_W - 130)
    f.condLabel:SetJustifyH("LEFT")
    f.condLabel:SetWordWrap(true)
    f.condLabel:SetTextColor(0.50, 0.72, 0.55, 1)

    -- Buttons (top-right)
    f.removeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.removeBtn:SetSize(20, 20)
    f.removeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    f:SetScript("OnMouseDown", function(self, mouseBtn)
        if mouseBtn ~= "LeftButton" then return end
        if not self._idx then return end
        -- Select the rule
        selectedIdx  = self._idx
        isAddingCond = false
        RefreshRuleList()
        RefreshRightPanel()
        -- Begin a *pending* drag — the visual only activates once the cursor
        -- moves more than 8 px, so normal clicks produce no floating icon.
        EnsureDragIcon()
        EnsureDragCatcher()
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        ruleDrag.pending  = true
        ruleDrag.fromIdx  = self._idx
        ruleDrag.pendingX = cx / s
        ruleDrag.pendingY = cy / s
        -- Pre-load the icon texture so it's ready the moment drag activates
        local rule = workingRules[self._idx]
        if rule and dragIconFrame then
            local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                         and C_Spell.GetSpellInfo(rule.spellID)
            local iconID = info and info.originalIconID
            dragIconFrame._tex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        -- Show catcher with mouse DISABLED so it doesn't block clicks;
        -- EnableMouse is turned on once the threshold is crossed.
        dragCatcher:EnableMouse(false)
        dragCatcher:Show()
    end)
    f:SetScript("OnMouseUp", function(self, mouseBtn)
        -- Cancel a pending drag that never crossed the movement threshold
        if mouseBtn == "LeftButton" and ruleDrag.pending then
            ruleDrag.pending = false
            ruleDrag.fromIdx = nil
            if dragCatcher then dragCatcher:Hide() end
        end
    end)
    f:SetScript("OnEnter", function(self)
        if self._idx ~= selectedIdx then
            f:SetBackdropColor(0.10, 0.16, 0.26, 0.88)
        end
    end)
    f:SetScript("OnLeave", function(self)
        if self._idx ~= selectedIdx then
            f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        end
    end)

    return f
end

local GROUP_BOX_COLORS = {
    { 0.78, 0.66, 0.14, 0.08, 0.92, 0.76, 0.18, 0.95 },
    { 0.18, 0.42, 0.72, 0.08, 0.28, 0.58, 0.90, 0.95 },
    { 0.18, 0.58, 0.34, 0.08, 0.24, 0.82, 0.46, 0.95 },
}

-- Returns a WoW color-code hex string for parenthesis at the given stack depth (1-based).
local function ParenColorCode(depth)
    local c = GROUP_BOX_COLORS[((depth - 1) % #GROUP_BOX_COLORS) + 1]
    return ("|cff%02x%02x%02x"):format(c[5]*255, c[6]*255, c[7]*255)
end

-- Returns true if the conditions for a rule have mismatched parentheses.
local function HasParenMismatch(conds)
    local depth = 0
    for _, cond in ipairs(conds or {}) do
        depth = depth + (cond.lparen or 0)
        depth = depth - (cond.rparen or 0)
        if depth < 0 then return true end   -- unmatched close
    end
    return depth ~= 0                       -- unclosed open(s)
end

local function UpdateRowFrame(f, idx, rule)
    local leftW = GetLeftPanelWidth()
    f._idx = idx
    -- Positioning (ClearAllPoints + SetPoint) is handled by RefreshRuleList
    -- after _rowH is computed here.

    f.badge:SetText(tostring(idx))

    local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                 and C_Spell.GetSpellInfo(rule.spellID)
    local iconID  = info and info.originalIconID
    local dispName = (info and info.name) or rule.name or "Unknown"
    f.iconTex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    f.nameLabel:SetText(dispName)
    f.nameLabel:SetWidth(math.max(120, leftW - 186))
    f.idLabel:SetText("ID: " .. tostring(rule.spellID or 0))

    local condCount = #(rule.conditions or {})
    if condCount == 0 then
        local labelW = math.max(120, leftW - 130)
        f.condLabel:SetWidth(labelW)
        f.condLabel:SetText("|cffff9944No conditions — unconditional return|r")
    else
        -- Build one display-string per condition, then group by paren depth.
        local tokens = {}
        local depth  = 0  -- running paren depth for color selection
        for i = 1, condCount do
            local cond = rule.conditions[i] or {}
            local def  = COND_BY_ID[cond.type]
            if def then
                local junction = ""
                if i > 1 then
                    local j = cond.junction or "and"
                    junction = "|cff8899cc" .. j:upper() .. "|r "
                end
                local lp = ""
                local rp = ""
                do
                    local depthBefore = depth
                    for k = 1, (cond.lparen or 0) do
                        local d = depthBefore + k
                        lp = lp .. ParenColorCode(d) .. "(" .. "|r"
                    end
                    depth = depth + (cond.lparen or 0)
                    for k = 1, (cond.rparen or 0) do
                        local d = depth - (k - 1)
                        rp = rp .. ParenColorCode(d) .. ")" .. "|r"
                    end
                    depth = depth - (cond.rparen or 0)
                end
                local label = def.shortLabel or def.label
                if def.needsSpell then
                    if cond.type == "sba_suggests" then
                        -- Show as "SBA = icon" using the chosen spell's icon
                        local op = "="
                        if not cond.spell or cond.spell == "this" then
                            label = "SBA " .. op .. (iconID and (" |T" .. iconID .. ":14:14|t") or " [this]")
                        else
                            local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                            if sid then
                                local sInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                                local sIcon = sInfo and sInfo.iconID
                                if sIcon then
                                    label = "SBA " .. op .. " |T" .. sIcon .. ":14:14|t"
                                else
                                    label = "SBA " .. op .. " [" .. tostring(sid) .. "]"
                                end
                            else
                                label = "SBA " .. op
                            end
                        end
                    elseif not cond.spell or cond.spell == "this" then
                        -- Show the rule's own spell icon
                        if iconID then
                            label = label .. " |T" .. iconID .. ":14:14|t"
                        end
                    else
                        local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                        if sid then
                            local sInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                            local sIcon = sInfo and sInfo.iconID
                            if sIcon then
                                label = label .. " |T" .. sIcon .. ":14:14|t"
                            else
                                label = label .. " [" .. tostring(sid) .. "]"
                            end
                        end
                    end
                elseif def.needsPlugin then
                    label = BuildPluginSummary(cond)
                elseif def.needsLua then
                    local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
                    if expr == "" then expr = "(empty)" end
                    if #expr > 30 then expr = expr:sub(1, 27) .. "..." end
                    label = "Lua: " .. expr
                elseif def.needsResource then
                    -- Show as e.g. "chi >= 2" or "energy <= 60"
                    local res = cond.resource or "chi"
                    local op  = cond.operator or ">="
                    local val = tostring(cond.value or 0)
                    label = res .. " " .. op .. " " .. val
                elseif def.needsCompareValue then
                    local op  = cond.operator or ">="
                    local val = tostring(cond.value or 0)
                    label = (def.shortLabel or def.label) .. " " .. op .. " " .. val
                end

                local labelText = cond.negate and ("|cffff4444NOT " .. label .. "|r") or label
                tokens[#tokens+1] = {
                    str = junction .. lp .. labelText .. rp,
                    lp  = cond.lparen or 0,
                    rp  = cond.rparen or 0,
                }
            end
        end

        -- Join all tokens into one continuous string; word-wrap handles line breaking.
        local parts = {}
        for _, tok in ipairs(tokens) do
            parts[#parts+1] = tok.str
        end
        local condText = table.concat(parts, " ")
        local labelW = math.max(120, leftW - 130)
        f.condLabel:SetWidth(labelW)
        f.condLabel:SetText(condText)
    end

    -- Use GetStringHeight() for accurate height now that width and text are set.
    -- Base header block ~44px + actual text height + 10px bottom pad.
    local textH = f.condLabel:GetStringHeight()
    local rowFrameH = math.max(ROW_H - 4, 44 + textH + 10)
    f._rowH = rowFrameH + 4   -- +4 gap between rows (used by RefreshRuleList)
    f:SetSize(leftW - PAD * 2, rowFrameH)
    f:Show()

    local hasMismatch = HasParenMismatch(rule.conditions)
    if hasMismatch then
        -- Red tint for paren mismatch regardless of selection state
        f:SetBackdropColor(0.30, 0.04, 0.04, 0.95)
        f:SetBackdropBorderColor(0.90, 0.18, 0.18, 1)
    elseif idx == selectedIdx then
        f:SetBackdropColor(0.08, 0.20, 0.36, 0.95)
        f:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
    else
        f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        f:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
    end

    f.removeBtn:SetScript("OnClick", function()
        table.remove(workingRules, idx)
        if selectedIdx == idx then
            selectedIdx = math.min(idx, #workingRules)
        elseif selectedIdx > idx then
            selectedIdx = selectedIdx - 1
        end
        isAddingCond = false
        RefreshRuleList(); RefreshRightPanel()
    end)
end

RefreshRuleList = function()
    local count = #workingRules
    leftChild:SetWidth(GetLeftPanelWidth())
    local yOff = -PAD

    -- Find the first unconditional rule (no conditions = always returns, shadows everything below)
    local firstUnconditionalIdx = math.huge
    for i = 1, count do
        if #(workingRules[i].conditions or {}) == 0 then
            firstUnconditionalIdx = i
            break
        end
    end

    for i = 1, count do
        if not rowFrames[i] then
            rowFrames[i] = CreateRowFrame(leftChild)
        end
        UpdateRowFrame(rowFrames[i], i, workingRules[i])
        -- Position after UpdateRowFrame has set _rowH
        local rf = rowFrames[i]
        -- Dim rules that can never be reached (shadowed by a prior unconditional return)
        rf:SetAlpha(i > firstUnconditionalIdx and 0.40 or 1.0)
        rf:ClearAllPoints()
        rf:SetPoint("TOPLEFT", leftChild, "TOPLEFT", PAD, yOff)
        yOff = yOff - (rf._rowH or ROW_H)
    end
    for i = count + 1, #rowFrames do
        if rowFrames[i] then rowFrames[i]:Hide() end
    end
    leftChild:SetHeight(math.max(-yOff + PAD, 100))
end

-------------------------------------------------------------------------------
-- 6b. Plugin / Proc picker popup
-------------------------------------------------------------------------------
local function CreatePluginPicker()
    local f = CreateFrame("Frame", "SBAS_GUI_PluginPicker", UIParent, "BackdropTemplate")
    f:SetSize(200, 28)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Plugin / Proc")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    f.rows = {}
    f.UpdateRows = function(self)
        local visible = GetVisiblePluginOptions()
        self:SetHeight(#visible * 22 + 28)

        for i, opt in ipairs(visible) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Button", nil, self)
                row:SetSize(192, 20)
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()
                row.bg:SetColorTexture(0, 0, 0, 0)
                row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.lbl:SetAllPoints()
                row.lbl:SetJustifyH("LEFT")
                row.lbl:SetTextColor(0.82, 0.9, 1, 1)
                self.rows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -22 - (i - 1) * 22)
            row.lbl:SetText("  " .. opt.label)
            row.optRef = opt
            row:SetScript("OnClick", function(btn)
                self:Hide()
                if self.callback then self.callback(btn.optRef) end
            end)
            row:SetScript("OnEnter", function(btn)
                btn.bg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
                btn.lbl:SetTextColor(1, 1, 1, 1)
            end)
            row:SetScript("OnLeave", function(btn)
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.lbl:SetTextColor(0.82, 0.9, 1, 1)
            end)
            row:Show()
        end

        for i = #visible + 1, #self.rows do
            self.rows[i]:Hide()
        end
    end

    return f
end

local function ShowPluginPicker(anchor, callback)
    if not pluginPicker then pluginPicker = CreatePluginPicker() end
    pluginPicker:UpdateRows()
    if #GetVisiblePluginOptions() == 0 then return end
    pluginPicker.callback = callback
    pluginPicker:ClearAllPoints()
    pluginPicker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    pluginPicker:Show()
    local bot = pluginPicker:GetBottom()
    if bot and bot < 0 then
        pluginPicker:ClearAllPoints()
        pluginPicker:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
end

-------------------------------------------------------------------------------
-- 10. Condition input area (inside right panel)
--     Shown when isAddingCond = true; lets the user pick a type + optional
--     numeric value and/or secondary spell-ID target.
-------------------------------------------------------------------------------

-- Scan every spellbook slot (all tabs, including passives) for a case-insensitive
-- name match.  Used as a fallback when GetSpellIDForSpellIdentifier fails, which
-- happens for many talent-granted spells.
local function SearchSpellBookByName(input)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return nil end
    local lower = input:lower()
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if info then
            local offset = info.itemIndexOffset
            local count  = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name, _ =
                    C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local _, spellID =
                    C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if spellID and spellID ~= 0 then
                    -- Check the base spellbook entry name
                    if name and name:lower() == lower then
                        return spellID
                    end
                    -- Also check the GetSpellInfo name (may differ from spellbook display name)
                    if C_Spell and C_Spell.GetSpellInfo then
                        local si = C_Spell.GetSpellInfo(spellID)
                        if si and si.name and si.name:lower() == lower then
                            return spellID
                        end
                    end
                    -- Check the active override of this spell
                    if C_SpellBook.FindSpellOverrideByID then
                        local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                        if oid and oid ~= spellID then
                            local oi = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                            if oi and oi.name and oi.name:lower() == lower then
                                return oid
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Scan the active talent tree for a case-insensitive name match.
-- Catches passive talents (like Obsidian Spiral) that never appear in the spellbook.
-- Uses: C_ClassTalents.GetActiveConfigID → C_Traits.GetConfigInfo (treeIDs) →
--       GetTreeNodes → GetNodeInfo (entryIDs) → GetEntryInfo (definitionID) →
--       GetDefinitionInfo (spellID).
local function SearchTalentTreeByName(input)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
            and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo
            and C_Traits.GetDefinitionInfo) then return nil end

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not (configInfo and configInfo.treeIDs) then return nil end

    local lower = input:lower()
    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes(treeID)
        if nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.entryIDs then
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if defInfo and defInfo.spellID and defInfo.spellID ~= 0 then
                                local si = C_Spell.GetSpellInfo
                                           and C_Spell.GetSpellInfo(defInfo.spellID)
                                if si and si.name and si.name:lower() == lower then
                                    return defInfo.spellID
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Comparison operator options (shared by resource and proc timer comparisons)
-------------------------------------------------------------------------------
local OP_LIST = {
    { id = ">=", label = ">=" },
    { id = "<=", label = "<=" },
    { id = "==", label = "==" },
    { id = ">",  label = ">"  },
    { id = "<",  label = "<"  },
}

local PROC_MODE_LIST = {
    { id = "active", label = "Active" },
    { id = ">=",     label = ">="     },
    { id = "<=",     label = "<="     },
    { id = "==",     label = "=="     },
    { id = ">",      label = ">"      },
    { id = "<",      label = "<"      },
}

-- Creates a compact dropdown button that opens a popup list of options.
-- ops:   array of { id, label }
-- Returns a Frame container with methods:
--   :SetSelected(id)    – select an option by id and update button text
--   :GetSelected()      – return the currently selected id
--   :UpdateWidth(w)     – resize the button, popup, and all rows to w
--   :SetOnChange(fn)    – register a callback fn(id) fired on selection
local function MakeOpDropdown(parent, ops)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(80, 22)

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:SetToplevel(true)
    popup:SetSize(80, #ops * 22 + 6)
    popup:Hide()
    SetBD(popup, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    -- Register so CloseAllPopups() can reach it.
    opDropdownPopups[#opDropdownPopups + 1] = popup

    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetAllPoints()

    local rows = {}
    local selected = ops[1].id
    local onChange = nil

    for i, op in ipairs(ops) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(80, 22)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -3 - (i - 1) * 22)
        rows[i] = row

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0, 0, 0, 0)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowLbl:SetAllPoints()
        rowLbl:SetJustifyH("CENTER")
        rowLbl:SetText(op.label)
        rowLbl:SetTextColor(0.82, 0.9, 1, 1)

        local opRef = op
        row:SetScript("OnClick", function()
            popup:Hide()
            selected = opRef.id
            btn:SetText(opRef.label)
            if onChange then onChange(opRef.id) end
        end)
        row:SetScript("OnEnter", function()
            rowBg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
            rowLbl:SetTextColor(1, 1, 1, 1)
        end)
        row:SetScript("OnLeave", function()
            rowBg:SetColorTexture(0, 0, 0, 0)
            rowLbl:SetTextColor(0.82, 0.9, 1, 1)
        end)
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            CloseAllPopups()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
            local bot = popup:GetBottom()
            if bot and bot < 0 then
                popup:ClearAllPoints()
                popup:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
            end
        end
    end)

    -- Initialize button text to first option.
    btn:SetText(ops[1].label)

    container.SetSelected = function(self, id)
        for _, op in ipairs(ops) do
            if op.id == id then
                selected = id
                btn:SetText(op.label)
                return
            end
        end
    end
    container.GetSelected  = function(self) return selected end
    container.UpdateWidth  = function(self, w)
        container:SetWidth(w)
        btn:SetWidth(w)
        popup:SetWidth(w)
        for _, row in ipairs(rows) do row:SetWidth(w) end
    end
    container.SetOnChange  = function(self, fn) onChange = fn end

    return container
end

local function CreateCondInputArea(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(GetRightPanelWidth() - 10, 95)
    SetBD(f, 0.04, 0.07, 0.13, 0.97, 0.20, 0.40, 0.60)

    local selType           = nil
    local spellSel          = "this"   -- "this" or "other"
    local resolvedOtherID   = nil
    local resolvedOtherName = nil
    local resSel            = "chi"    -- "chi" or "energy"
    local opSel             = ">="     -- resource operator (>=, <=, ==, >, <)
    local procModeSel       = "active" -- "active" or comparison operator
    local opDropdown        = nil      -- assigned after operatorFrame is built
    local procModeDropdown  = nil      -- assigned after procModeFrame is built
    -- Forward-declare so closures defined before their creation can capture them.
    local procModeFrame
    local valLbl
    local valBox
    local luaFrame
    local luaLabel
    local luaBox
    local selPlugin = nil
    local UpdateLayout  -- assigned below; forward-declared so all closures share it

    -- ── NOT checkbox ──────────────────────────────────────────────────────
    local notCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    notCheck:SetSize(20, 20)
    notCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    local notLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notLbl:SetPoint("LEFT", notCheck, "RIGHT", 2, 0)
    notLbl:SetText("NOT (negate)")
    notLbl:SetTextColor(0.90, 0.55, 0.38, 1)

    -- ── Type selector ─────────────────────────────────────────────────────
    local typeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    typeBtn:SetSize(GetRightPanelWidth() - 18, 22)
    typeBtn:SetPoint("TOPLEFT", notCheck, "BOTTOMLEFT", 0, -4)
    typeBtn:SetText("Select condition type...")

    -- ── Spell toggle: This Spell / Other Spell ────────────────────────────
    local spellToggleFrame = CreateFrame("Frame", nil, f)
    spellToggleFrame:SetSize(GetRightPanelWidth() - 18, 22)
    spellToggleFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    spellToggleFrame:Hide()

    local halfW = math.floor((GetRightPanelWidth() - 22) / 2)
    local thisBtn = CreateFrame("Button", nil, spellToggleFrame, "UIPanelButtonTemplate")
    thisBtn:SetSize(halfW, 22)
    thisBtn:SetPoint("TOPLEFT", spellToggleFrame, "TOPLEFT")
    thisBtn:SetText("This Spell")

    local otherBtn = CreateFrame("Button", nil, spellToggleFrame, "UIPanelButtonTemplate")
    otherBtn:SetSize(halfW, 22)
    otherBtn:SetPoint("LEFT", thisBtn, "RIGHT", 2, 0)
    otherBtn:SetText("Other Spell")

    -- ── Other spell name input ────────────────────────────────────────────
    local otherFrame = CreateFrame("Frame", nil, f)
    otherFrame:SetSize(GetRightPanelWidth() - 18, 38)
    otherFrame:SetPoint("TOPLEFT", spellToggleFrame, "BOTTOMLEFT", 0, -2)
    otherFrame:Hide()

    local otherNameBox = CreateFrame("EditBox", nil, otherFrame, "InputBoxTemplate")
    otherNameBox:SetSize(GetRightPanelWidth() - 52, 20)
    otherNameBox:SetPoint("TOPLEFT", otherFrame, "TOPLEFT")
    otherNameBox:SetAutoFocus(false)
    otherNameBox:SetMaxLetters(80)

    local otherIcon = otherFrame:CreateTexture(nil, "ARTWORK")
    otherIcon:SetSize(18, 18)
    otherIcon:SetPoint("LEFT", otherNameBox, "RIGHT", 4, 0)
    otherIcon:Hide()

    local otherResultLbl = otherFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    otherResultLbl:SetPoint("TOPLEFT", otherNameBox, "BOTTOMLEFT", 0, -2)
    otherResultLbl:SetSize(GetRightPanelWidth() - 22, 14)
    otherResultLbl:SetJustifyH("LEFT")

    otherNameBox:SetScript("OnTextChanged", function()
        local input = otherNameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            otherResultLbl:SetText("") otherIcon:Hide() resolvedOtherID = nil; return
        end
        local id
        -- Numeric input: treat as a direct spell ID
        local numericID = tonumber(input)
        if numericID then
            id = numericID
        elseif C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end
        -- Fallback: scan spellbook by name (catches talent-granted spells)
        if not (id and id > 0) then
            id = SearchSpellBookByName(input)
        end
        -- Final fallback: scan talent tree (catches passive talents like Obsidian Spiral
        -- that never appear in the spellbook)
        if not (id and id > 0) then
            id = SearchTalentTreeByName(input)
        end
        if id and id > 0 then
            local n   = C_Spell.GetSpellName   and C_Spell.GetSpellName(id)
            local tex = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
            resolvedOtherID = id; resolvedOtherName = n or input
            otherResultLbl:SetText("|cff55ee55" .. (n or input) .. "|r  ID:" .. id)
            if tex then otherIcon:SetTexture(tex) otherIcon:Show() else otherIcon:Hide() end
        else
            resolvedOtherID = nil
            otherResultLbl:SetText("|cffff5555Not found|r") otherIcon:Hide()
        end
    end)

    -- ── Resource type selector: Chi / Energy ──────────────────────────────
    local resourceFrame = CreateFrame("Frame", nil, f)
    resourceFrame:SetSize(GetRightPanelWidth() - 18, 22)
    resourceFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    resourceFrame:Hide()

    local resLabel = resourceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resLabel:SetPoint("LEFT", resourceFrame, "LEFT", 0, 0)
    resLabel:SetWidth(60)
    resLabel:SetText("Resource:")
    resLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    local chiBtn = CreateFrame("Button", nil, resourceFrame, "UIPanelButtonTemplate")
    chiBtn:SetSize(88, 22)
    chiBtn:SetPoint("LEFT", resLabel, "RIGHT", 4, 0)
    chiBtn:SetText("Chi")

    local energyBtn = CreateFrame("Button", nil, resourceFrame, "UIPanelButtonTemplate")
    energyBtn:SetSize(88, 22)
    energyBtn:SetPoint("LEFT", chiBtn, "RIGHT", 2, 0)
    energyBtn:SetText("Energy")

    -- ── Operator selector: dropdown (>=, <=, ==, >, <) ──────────────────
    local operatorFrame = CreateFrame("Frame", nil, f)
    operatorFrame:SetSize(GetRightPanelWidth() - 18, 22)
    operatorFrame:SetPoint("TOPLEFT", resourceFrame, "BOTTOMLEFT", 0, -4)
    operatorFrame:Hide()

    local opLabel = operatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opLabel:SetPoint("LEFT", operatorFrame, "LEFT", 0, 0)
    opLabel:SetWidth(60)
    opLabel:SetText("Operator:")
    opLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    opDropdown = MakeOpDropdown(operatorFrame, OP_LIST)
    opDropdown:SetPoint("LEFT", opLabel, "RIGHT", 4, 0)
    opDropdown:SetSelected(">=")
    opDropdown:SetOnChange(function(id) opSel = id end)

    -- ── Plugin / Proc selector ────────────────────────────────────────────
    local pluginFrame = CreateFrame("Frame", nil, f)
    pluginFrame:SetSize(GetRightPanelWidth() - 18, 22)
    pluginFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    pluginFrame:Hide()

    local pluginBtn = CreateFrame("Button", nil, pluginFrame, "UIPanelButtonTemplate")
    pluginBtn:SetSize(GetRightPanelWidth() - 18, 22)
    pluginBtn:SetPoint("TOPLEFT", pluginFrame, "TOPLEFT")
    pluginBtn:SetText("Select plugin...")
    pluginBtn:SetScript("OnClick", function()
        if pluginPicker and pluginPicker:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        ShowPluginPicker(pluginBtn, function(opt)
            selPlugin = opt
            pluginBtn:SetText(opt.label)
            if opt.supportsProcMode then
                procModeFrame:Show()
                procModeSel = "active"
                if procModeDropdown then procModeDropdown:SetSelected("active") end
                valLbl:Hide(); valBox:Hide()
            else
                procModeFrame:Hide()
                valLbl:Hide(); valBox:Hide()
            end
            UpdateLayout()
        end)
    end)

    -- ── Proc mode selector (Active or timer comparison) ───────────────────
    procModeFrame = CreateFrame("Frame", nil, f)
    procModeFrame:SetSize(GetRightPanelWidth() - 18, 22)
    procModeFrame:SetPoint("TOPLEFT", pluginFrame, "BOTTOMLEFT", 0, -4)
    procModeFrame:Hide()

    local procModeLabel = procModeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    procModeLabel:SetPoint("LEFT", procModeFrame, "LEFT", 0, 0)
    procModeLabel:SetWidth(60)
    procModeLabel:SetText("Mode:")
    procModeLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    procModeDropdown = MakeOpDropdown(procModeFrame, PROC_MODE_LIST)
    procModeDropdown:SetPoint("LEFT", procModeLabel, "RIGHT", 4, 0)
    procModeDropdown:SetSelected("active")
    procModeDropdown:SetOnChange(function(id)
        procModeSel = id
        if id == "active" then
            valLbl:Hide(); valBox:Hide()
        else
            valLbl:SetText("Seconds:")
            valLbl:Show()
            if valBox:GetText() == "" then valBox:SetText("4") end
            valBox:Show()
        end
        UpdateLayout()
    end)

    -- ── Custom Lua expression row ─────────────────────────────────────────
    luaFrame = CreateFrame("Frame", nil, f)
    luaFrame:SetSize(GetRightPanelWidth() - 18, 38)
    luaFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    luaFrame:Hide()

    luaLabel = luaFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    luaLabel:SetPoint("TOPLEFT", luaFrame, "TOPLEFT", 0, 0)
    luaLabel:SetText("Lua expression:")
    luaLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    luaBox = CreateFrame("EditBox", nil, luaFrame, "InputBoxTemplate")
    luaBox:SetSize(GetRightPanelWidth() - 24, 20)
    luaBox:SetPoint("TOPLEFT", luaLabel, "BOTTOMLEFT", 0, -2)
    luaBox:SetAutoFocus(false)
    luaBox:SetMaxLetters(512)
    luaBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    valLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valLbl:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -6)
    valLbl:SetTextColor(0.55, 0.72, 0.88, 1)
    valLbl:Hide()

    valBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    valBox:SetSize(72, 22)
    valBox:SetPoint("LEFT", valLbl, "RIGHT", 6, 0)
    valBox:SetAutoFocus(false)
    valBox:SetNumeric(true)
    valBox:SetMaxLetters(6)
    valBox:Hide()

    -- ── Confirm / Cancel ──────────────────────────────────────────────────
    local confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    confirmBtn:SetSize(88, 24)
    confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
    confirmBtn:SetText("Add")

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(76, 24)
    cancelBtn:SetPoint("LEFT", confirmBtn, "RIGHT", 6, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        selectedCondIdx = nil
        isAddingCond = false
        RefreshRightPanel()
    end)

    -- ── Resource / operator highlight helpers ─────────────────────────────
    local function HlBtn(btn, selected)
        btn:GetFontString():SetTextColor(
            selected and 1.0 or 0.65,
            selected and 1.0 or 0.65,
            selected and 0.5 or 0.65, 1)
    end

    local function SetResSel(mode)
        resSel = mode
        HlBtn(chiBtn,    mode == "chi")
        HlBtn(energyBtn, mode == "energy")
    end

    local function SetOpSel(mode)
        opSel = mode
        if opDropdown then opDropdown:SetSelected(mode) end
    end

    chiBtn:SetScript("OnClick",    function() SetResSel("chi")    end)
    energyBtn:SetScript("OnClick", function() SetResSel("energy") end)

    local function RefreshSize()
        local rightW = GetRightPanelWidth()
        local contentW = rightW - 18
        local spellHalfW = math.floor((contentW - 4) / 2)
        local otherBoxW = math.max(120, contentW - 34)
        local resBtnW = math.max(68, math.floor((contentW - 66) / 2))
        local opDropdownW = math.max(60, contentW - 64)   -- 64 = label 60 + gap 4

        f:SetWidth(rightW - 10)
        typeBtn:SetWidth(contentW)
        spellToggleFrame:SetWidth(contentW)
        thisBtn:SetWidth(spellHalfW)
        otherBtn:SetWidth(spellHalfW)
        otherFrame:SetWidth(contentW)
        otherNameBox:SetWidth(otherBoxW)
        otherResultLbl:SetWidth(contentW - 4)
        resourceFrame:SetWidth(contentW)
        operatorFrame:SetWidth(contentW)
        pluginFrame:SetWidth(contentW)
        procModeFrame:SetWidth(contentW)
        luaFrame:SetWidth(contentW)
        pluginBtn:SetWidth(contentW)
        luaBox:SetWidth(math.max(120, contentW - 6))
        chiBtn:SetWidth(resBtnW)
        energyBtn:SetWidth(resBtnW)
        if opDropdown      then opDropdown:UpdateWidth(opDropdownW)      end
        if procModeDropdown then procModeDropdown:UpdateWidth(opDropdownW) end
        UpdateLayout()
    end

    -- ── Layout ────────────────────────────────────────────────────────────
    UpdateLayout = function()
        -- Operator row is reused by two condition families:
        -- 1) needsResource      -> shown below resource row
        -- 2) needsCompareValue  -> shown directly below type selector
        operatorFrame:ClearAllPoints()
        if selType and selType.needsResource then
            operatorFrame:SetPoint("TOPLEFT", resourceFrame, "BOTTOMLEFT", 0, -4)
        else
            operatorFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
        end

        local above = typeBtn
        if selType and selType.needsSpell then
            above = (spellSel == "other") and otherFrame or spellToggleFrame
        elseif selType and selType.needsResource then
            above = operatorFrame
        elseif selType and selType.needsCompareValue then
            above = operatorFrame
        elseif selType and selType.needsLua then
            above = luaFrame
        elseif selType and selType.needsPlugin then
            above = (selPlugin and selPlugin.supportsProcMode) and procModeFrame or pluginFrame
        end
        local showVal = selType and (
            selType.needsValue or selType.needsResource or selType.needsCompareValue or
            (selType.needsPlugin and selPlugin and selPlugin.supportsProcMode and procModeSel ~= "active"))
        if showVal then
            valLbl:ClearAllPoints()
            valLbl:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -6)
        end
        local h = 6 + 20 + 4 + 22 + 4  -- pad + notCheck + gap + typeBtn + gap
        if selType and selType.needsSpell then
            h = h + 22 + 4
            if spellSel == "other" then h = h + 38 + 4 end
        end
        if selType and selType.needsResource then
            h = h + 22 + 4   -- resource row
            h = h + 22 + 4   -- operator row
        end
        if selType and selType.needsCompareValue then
            h = h + 22 + 4   -- operator row
        end
        if selType and selType.needsLua then
            h = h + 38 + 4   -- custom Lua row
        end
        if selType and selType.needsPlugin then
            h = h + 22 + 4   -- plugin selector row
            if selPlugin and selPlugin.supportsProcMode then
                h = h + 22 + 4  -- mode row
            end
        end
        if showVal then h = h + 22 + 4 end
        h = h + 24 + 8                  -- buttons + bottom pad
        f:SetHeight(h)
    end

    local function SetSpellSel(mode)
        spellSel = mode
        if mode == "this" then
            otherFrame:Hide()
            thisBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            otherBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        else
            otherFrame:Show()
            otherBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            thisBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        end
        UpdateLayout()
    end

    thisBtn:SetScript("OnClick",  function() SetSpellSel("this")  end)
    otherBtn:SetScript("OnClick", function() SetSpellSel("other") end)

    typeBtn:SetScript("OnClick", function()
        if condPicker and condPicker:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        ShowCondPicker(typeBtn, function(ct)
            selType = ct
            typeBtn:SetText(ct.label)
            -- Hide all optional sections first
            spellToggleFrame:Hide(); otherFrame:Hide()
            resourceFrame:Hide(); operatorFrame:Hide()
            luaFrame:Hide()
            pluginFrame:Hide(); procModeFrame:Hide()
            valLbl:Hide(); valBox:Hide()
            selPlugin = nil
            if ct.needsSpell then
                spellToggleFrame:Show()
                if ct.id == "sba_suggests" then
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell")
                elseif ct.id == "talented" then
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell / Talent")
                else
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell")
                end
                SetSpellSel("this")
            end
            if ct.needsResource then
                resourceFrame:Show()
                operatorFrame:Show()
                local sec = SPEC_SECONDARY[editSpecID] or SPEC_SECONDARY_DEFAULT
                chiBtn:SetText(sec.label)
                if sec.inlineExpr then
                    energyBtn:Hide()
                else
                    energyBtn:Show()
                end
                SetResSel("chi")
                SetOpSel(">=")
                valLbl:SetText("Value:")
                valLbl:Show()
                valBox:SetText("0")
                valBox:Show()
            end
            if ct.needsCompareValue then
                operatorFrame:Show()
                SetOpSel(">=")
                valLbl:SetText((ct.valueLabel or "Value") .. ":")
                valLbl:Show()
                valBox:SetText(tostring(ct.default or 0))
                valBox:Show()
            end
            if ct.needsLua then
                luaFrame:Show()
                luaLabel:SetText((ct.luaLabel or "Lua expression") .. ":")
                luaBox:SetText("")
            end
            if ct.needsPlugin then
                pluginFrame:Show()
                pluginBtn:SetText("Select plugin...")
                procModeSel = "active"
                if procModeDropdown then procModeDropdown:SetSelected("active") end
            end
            if ct.needsValue then
                valLbl:SetText((ct.valueLabel or "Value") .. ":")
                valLbl:Show()
                valBox:SetText(tostring(ct.default or ""))
                valBox:Show()
            end
            UpdateLayout()
        end)
    end)

    -- ── Public interface ──────────────────────────────────────────────────
    f.confirmBtn = confirmBtn
    f.typeBtn    = typeBtn

    f.GetSelectedType = function() return selType end
    f.GetValue        = function() return tonumber(valBox:GetText()) end
    f.GetNegate       = function() return notCheck:GetChecked() and true or false end
    f.GetResource     = function() return resSel end
    f.GetOperator     = function() return opSel end
    f.GetProcMode     = function() return procModeSel end
    f.GetPlugin       = function() return selPlugin and selPlugin.id or nil end
    f.GetLuaCode      = function()
        local expr = luaBox:GetText() and luaBox:GetText():match("^%s*(.-)%s*$") or ""
        if expr == "" then return nil end
        return expr
    end
    f.GetSpell        = function()
        if not selType or not selType.needsSpell then return nil end
        if spellSel == "this" then return "this" end
        return resolvedOtherID  -- number or nil if not yet resolved
    end
    f.RefreshSize     = RefreshSize

    -- Update the secondary-resource button label to match the spec now being edited.
    -- Call whenever editSpecID changes (e.g. from OpenGUI).
    f.RefreshSpec = function()
        local sec = SPEC_SECONDARY[editSpecID] or SPEC_SECONDARY_DEFAULT
        chiBtn:SetText(sec.label)
        -- Specs that use an inline expression (e.g. BM Hunter tracks Focus via
        -- the FocusGuesstimator global) have no meaningful Energy alternative;
        -- hide the Energy button so only the single resource option is shown.
        if sec.inlineExpr then
            energyBtn:Hide()
        else
            energyBtn:Show()
        end
    end

    f.Reset = function()
        selType = nil; spellSel = "this"; resSel = "chi"; opSel = ">="
        procModeSel = "active"
        selPlugin = nil
        resolvedOtherID = nil; resolvedOtherName = nil
        notCheck:SetChecked(false)
        typeBtn:SetText("Select condition type...")
        spellToggleFrame:Hide(); otherFrame:Hide()
        resourceFrame:Hide(); operatorFrame:Hide()
        luaFrame:Hide(); luaBox:SetText("")
        pluginFrame:Hide(); procModeFrame:Hide(); pluginBtn:SetText("Select plugin...")
        otherNameBox:SetText(""); otherResultLbl:SetText(""); otherIcon:Hide()
        valLbl:Hide(); valBox:SetText(""); valBox:Hide()
        if opDropdown      then opDropdown:SetSelected(">=") end
        if procModeDropdown then procModeDropdown:SetSelected("active") end
        f:SetHeight(95)
    end

    f.Populate = function(cond)
        f.Reset()
        local ct = COND_BY_ID[cond.type]
        if not ct then return end
        selType = ct
        typeBtn:SetText(ct.label)
        notCheck:SetChecked(cond.negate and true or false)
        if ct.needsSpell then
            spellToggleFrame:Show()
            if ct.id == "sba_suggests" then
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell")
            elseif ct.id == "talented" then
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell / Talent")
            else
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell")
            end
            if not cond.spell or cond.spell == "this" then
                SetSpellSel("this")
            else
                local spellID = type(cond.spell) == "number" and cond.spell or cond.targetID
                if spellID then
                    local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
                    otherNameBox:SetText(n or tostring(spellID))
                    resolvedOtherID = spellID  -- ensure ID is set even if name lookup fires first
                end
                SetSpellSel("other")
            end
        end
        if ct.needsResource then
            resourceFrame:Show()
            operatorFrame:Show()
            local sec = SPEC_SECONDARY[editSpecID] or SPEC_SECONDARY_DEFAULT
            chiBtn:SetText(sec.label)
            if sec.inlineExpr then
                energyBtn:Hide()
            else
                energyBtn:Show()
            end
            SetResSel(cond.resource or "chi")
            SetOpSel(cond.operator or ">=")
            valLbl:SetText("Value:")
            valLbl:Show()
            valBox:SetText(tostring(cond.value or 0))
            valBox:Show()
        end
        if ct.needsCompareValue then
            operatorFrame:Show()
            SetOpSel(cond.operator or ">=")
            valLbl:SetText((ct.valueLabel or "Value") .. ":")
            valLbl:Show()
            valBox:SetText(tostring(cond.value or ct.default or 0))
            valBox:Show()
        end
        if ct.needsLua then
            luaFrame:Show()
            luaLabel:SetText((ct.luaLabel or "Lua expression") .. ":")
            luaBox:SetText(cond.luaCode or "")
        end
        if ct.needsPlugin then
            pluginFrame:Show()
            local pluginID, savedOp, savedValue = NormalizePluginState(cond)
            local visiblePlugins = GetVisiblePluginOptions() or {}
            for _, opt in ipairs(visiblePlugins) do
                if opt.id == pluginID then
                    selPlugin = opt
                    pluginBtn:SetText(opt.label)
                    if opt.supportsProcMode then
                        procModeFrame:Show()
                        local mode = IsCompOp(savedOp) and savedOp or "active"
                        procModeSel = mode
                        if procModeDropdown then procModeDropdown:SetSelected(mode) end
                        if mode ~= "active" then
                            valLbl:SetText("Seconds:")
                            valLbl:Show()
                            valBox:SetText(tostring(savedValue or opt.default or 4))
                            valBox:Show()
                        end
                    end
                    break
                end
            end
        end
        if ct.needsValue then
            valLbl:SetText((ct.valueLabel or "Value") .. ":")
            valLbl:Show()
            valBox:SetText(tostring(cond.value or ct.default or ""))
            valBox:Show()
        end
        UpdateLayout()
    end

    RefreshSize()

    return f
end

local function AnalyzeParenGroups(conds)
    local spans = {}
    local unmatchedOpens  = {}
    local unmatchedCloses = {}
    local stack = {}

    for i, cond in ipairs(conds) do
        for _ = 1, (cond.lparen or 0) do
            stack[#stack + 1] = { startIdx = i, depth = #stack + 1 }
        end
        for _ = 1, (cond.rparen or 0) do
            local open = table.remove(stack)
            if open then
                spans[#spans + 1] = {
                    startIdx = open.startIdx,
                    endIdx   = i,
                    depth    = open.depth,
                }
            else
                unmatchedCloses[i] = (unmatchedCloses[i] or 0) + 1
            end
        end
    end

    for _, open in ipairs(stack) do
        unmatchedOpens[open.startIdx] = (unmatchedOpens[open.startIdx] or 0) + 1
    end

    table.sort(spans, function(a, b)
        local aLen = a.endIdx - a.startIdx
        local bLen = b.endIdx - b.startIdx
        if aLen ~= bLen then return aLen > bLen end
        return a.depth < b.depth
    end)

    return spans, unmatchedOpens, unmatchedCloses
end

-- Returns two tables: lpDepths[i] and rpDepths[i], each a list of depths for
-- the opening/closing parens of condition i (innermost depth last).
local function GetCondParenDepths(conds)
    local lpDepths = {}
    local rpDepths = {}
    local stack    = {}   -- each entry = depth at which that ( was opened
    for i, cond in ipairs(conds) do
        lpDepths[i] = {}
        for _ = 1, (cond.lparen or 0) do
            local d = #stack + 1
            stack[#stack + 1] = d
            lpDepths[i][#lpDepths[i] + 1] = d
        end
        rpDepths[i] = {}
        for _ = 1, (cond.rparen or 0) do
            local d = table.remove(stack) or 1
            rpDepths[i][#rpDepths[i] + 1] = d
        end
    end
    return lpDepths, rpDepths
end

local function DrawConditionGroupBoxes(spans, rowYTops)
    for _, box in ipairs(condGroupBoxPool) do
        box:Hide()
    end
    if not rightPanel then return end

    local panelLevel = rightPanel:GetFrameLevel()
    for i, span in ipairs(spans) do
        if not condGroupBoxPool[i] then
            local box = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
            box:SetFrameStrata(rightPanel:GetFrameStrata())
            condGroupBoxPool[i] = box
        end

        local topY = rowYTops[span.startIdx]
        local endY = rowYTops[span.endIdx]
        if topY and endY then
            local inset = 2 + (span.depth - 1) * 4
            local color = GROUP_BOX_COLORS[((span.depth - 1) % #GROUP_BOX_COLORS) + 1]
            local box = condGroupBoxPool[i]
            local height = (topY - (endY - 22)) + 4

            box:ClearAllPoints()
            box:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4 + inset, topY + 2)
            box:SetSize(rightPanel:GetWidth() - 8 - inset * 2, height)
            box:SetFrameLevel(panelLevel + math.min(i - 1, 8))
            SetBD(box, color[1], color[2], color[3], color[4], color[5], color[6], color[7])
            box:Show()
        end
    end
end

-------------------------------------------------------------------------------
-- 11. Right panel refresh
--     Rebuilds the condition list for the currently selected rule.
-------------------------------------------------------------------------------
RefreshRightPanel = function()
    if not rightPanel then return end

    -- Hide all pooled condition rows and junction toggles
    for _, row in ipairs(condRowPool)      do row:Hide() end
    for _, jf  in ipairs(condJunctionPool) do jf:Hide()  end
    for _, box in ipairs(condGroupBoxPool) do box:Hide() end
    condRowYList = {}

    local rule = workingRules[selectedIdx]

    if not rule then
        rightPanel.header:SetText("Select a spell to edit conditions")
        rightPanel.addCondBtn:Hide()
        if condInputArea then condInputArea:Hide() end
        return
    end

    rightPanel.header:SetText((rule.name or tostring(rule.spellID or "?"))
                               .. " — Conditions")
    rightPanel.header:SetWidth(GetRightPanelWidth() - 16)

    local conds  = rule.conditions or {}
    local spans, unmatchedOpens, unmatchedCloses = AnalyzeParenGroups(conds)
    local lpDepths, rpDepths = GetCondParenDepths(conds)
    local yBase  = -28  -- below the header
    local rowIdx = 0
    local rowYTops = {}

    for i, cond in ipairs(conds) do
        -- AND / OR junction toggle (shown between consecutive conditions)
        if i > 1 then
            local jIdx = i - 1
            if not condJunctionPool[jIdx] then
                local jf = CreateFrame("Button", nil, rightPanel)
                jf:SetSize(44, 14)
                jf:SetFrameLevel(rightPanel:GetFrameLevel() + 20)
                local jbg = jf:CreateTexture(nil, "BACKGROUND")
                jbg:SetAllPoints() jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
                jf._bg = jbg
                local jLbl = jf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                jLbl:SetAllPoints() jLbl:SetJustifyH("CENTER")
                jf._lbl = jLbl
                jf:SetScript("OnEnter", function() jbg:SetColorTexture(0.18, 0.28, 0.48, 0.9) end)
                jf:SetScript("OnLeave", function() jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)
                condJunctionPool[jIdx] = jf
            end
            local jf           = condJunctionPool[jIdx]
            local capturedCond = cond
            jf:ClearAllPoints()
            jf:SetPoint("TOP", rightPanel, "TOP", 0, yBase)
            local function RefreshJunction()
                local j = capturedCond.junction or "and"
                jf._lbl:SetText(j:upper())
                jf._lbl:SetTextColor(
                    j == "or" and 1.0 or 0.55,
                    j == "or" and 0.72 or 0.80,
                    j == "or" and 0.28 or 1.0, 1)
            end
            RefreshJunction()
            jf:SetScript("OnClick", function()
                local j = capturedCond.junction or "and"
                capturedCond.junction = (j == "and") and "or" or "and"
                RefreshJunction()
                RefreshRuleList()
            end)
            jf:Show()
            yBase = yBase - 16
        end

        rowIdx = rowIdx + 1
        -- Get or create a pooled row frame
        if not condRowPool[rowIdx] then
            local row = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
            row:SetSize(RIGHT_W - 12, 22)
            row:SetFrameLevel(rightPanel:GetFrameLevel() + 20)
            SetBD(row, 0.07, 0.11, 0.18, 0.85, 0.12, 0.22, 0.36)

            -- Left paren column button
            local lpBtn = CreateFrame("Button", nil, row)
            lpBtn:SetSize(20, 20)
            lpBtn:SetPoint("LEFT", row, "LEFT", 2, 0)
            local lpBg = lpBtn:CreateTexture(nil, "BACKGROUND")
            lpBg:SetAllPoints() lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            lpBtn._bg = lpBg
            local lpLbl = lpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lpLbl:SetAllPoints() lpLbl:SetJustifyH("CENTER")
            row._lpBtn = lpBtn
            row._lpLbl = lpLbl
            lpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            lpBtn:SetScript("OnEnter", function() lpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            lpBtn:SetScript("OnLeave", function() lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            -- Right paren column button
            local rpBtn = CreateFrame("Button", nil, row)
            rpBtn:SetSize(20, 20)
            rpBtn:SetPoint("RIGHT", row, "RIGHT", -22, 0)
            local rpBg = rpBtn:CreateTexture(nil, "BACKGROUND")
            rpBg:SetAllPoints() rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            rpBtn._bg = rpBg
            local rpLbl = rpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rpLbl:SetAllPoints() rpLbl:SetJustifyH("CENTER")
            row._rpBtn = rpBtn
            row._rpLbl = rpLbl
            rpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            rpBtn:SetScript("OnEnter", function() rpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            rpBtn:SetScript("OnLeave", function() rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT",  row, "LEFT",  24, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT", -44, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetTextColor(0.78, 0.90, 1, 1)
            row._lbl = lbl

            local xb = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            xb:SetSize(18, 18)
            xb:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row._xb = xb

            condRowPool[rowIdx] = row
        end

        local row = condRowPool[rowIdx]
        row:ClearAllPoints()
        row:SetSize(GetRightPanelWidth() - 12, 22)
        row:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase)
        rowYTops[i] = yBase
        condRowYList[i] = yBase   -- record for drag drop-slot detection
        row._lbl:SetText(CondSummaryText(cond, rule.spellID))
        row._lbl:SetTextColor(cond.negate and 1 or 0.78, cond.negate and 0.38 or 0.90, cond.negate and 0.38 or 1, 1)
        local capturedI    = i
        local capturedCond = cond
        -- Snapshot depth lists so closures don't capture by-reference after loop mutation.
        local capturedLpD  = lpDepths[i] or {}
        local capturedRpD  = rpDepths[i] or {}

        local function UpdateLPBtn()
            local n = capturedCond.lparen or 0
            local hasError = (unmatchedOpens[capturedI] or 0) > 0
            if n == 0 then
                row._lpLbl:SetText("(")
                row._lpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                -- Build a colored string per paren, each at its own depth.
                local parts = {}
                for k = 1, n do
                    local d = capturedLpD[k] or k
                    local c = GROUP_BOX_COLORS[((d - 1) % #GROUP_BOX_COLORS) + 1]
                    parts[k] = ("|cff%02x%02x%02x(|r"):format(c[5]*255, c[6]*255, c[7]*255)
                end
                row._lpLbl:SetText(table.concat(parts))
                if hasError then
                    row._lpLbl:SetTextColor(1.0, 0.30, 0.30, 1)
                end
            end
            row._lpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end
        local function UpdateRPBtn()
            local n = capturedCond.rparen or 0
            local hasError = (unmatchedCloses[capturedI] or 0) > 0
            if n == 0 then
                row._rpLbl:SetText(")")
                row._rpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                local parts = {}
                for k = 1, n do
                    local d = capturedRpD[k] or (n - k + 1)
                    local c = GROUP_BOX_COLORS[((d - 1) % #GROUP_BOX_COLORS) + 1]
                    parts[k] = ("|cff%02x%02x%02x)|r"):format(c[5]*255, c[6]*255, c[7]*255)
                end
                row._rpLbl:SetText(table.concat(parts))
                if hasError then
                    row._rpLbl:SetTextColor(1.0, 0.30, 0.30, 1)
                end
            end
            row._rpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end
        UpdateLPBtn()
        UpdateRPBtn()
        row._lpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.lparen = math.max(0, (capturedCond.lparen or 0) - 1)
            else
                capturedCond.lparen = ((capturedCond.lparen or 0) + 1) % 4
            end
            RefreshRightPanel()
            RefreshRuleList()
        end)
        row._rpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.rparen = math.max(0, (capturedCond.rparen or 0) - 1)
            else
                capturedCond.rparen = ((capturedCond.rparen or 0) + 1) % 4
            end
            RefreshRightPanel()
            RefreshRuleList()
        end)
        row._xb:SetScript("OnClick", function()
            if workingRules[selectedIdx] then
                table.remove(workingRules[selectedIdx].conditions, capturedI)
                selectedCondIdx = nil
                RefreshRightPanel()
                RefreshRuleList()
            end
        end)
        row:EnableMouse(true)
        row:SetScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" then
                -- Start pending drag; click vs drag resolved in OnMouseUp
                EnsureCondCatcher()
                local cx, cy = GetCursorPosition()
                local sc = UIParent:GetEffectiveScale()
                condDrag.pending  = true
                condDrag.active   = false
                condDrag.fromIdx  = capturedI
                condDrag.toSlot   = nil
                condDrag.pendingX = cx / sc
                condDrag.pendingY = cy / sc
            end
        end)
        row:SetScript("OnMouseUp", function(self, btn)
            -- WoW always sends OnMouseUp to the frame that received OnMouseDown,
            -- so this handler fires on release regardless of cursor position.
            if btn ~= "LeftButton" then return end
            if condDropLine then condDropLine:Hide() end
            if condDrag.pending then
                -- No significant movement: treat as a click to open editor
                condDrag.pending = false
                condDrag.fromIdx = nil
                selectedCondIdx = capturedI
                isAddingCond = true
                RefreshRightPanel()
            elseif condDrag.active then
                -- Drop: move condition; strip parens to avoid breaking paren groups
                condDrag.active = false
                local fromIdx = condDrag.fromIdx
                local toSlot  = condDrag.toSlot
                condDrag.fromIdx = nil
                condDrag.toSlot  = nil
                local rule = selectedIdx > 0 and workingRules[selectedIdx]
                if rule and fromIdx and toSlot
                   and fromIdx ~= toSlot and fromIdx ~= toSlot - 1 then
                    local conds    = rule.conditions
                    local moved    = table.remove(conds, fromIdx)
                    moved.lparen   = 0   -- don't drag paren-grouping structure
                    moved.rparen   = 0
                    local insertAt = (toSlot > fromIdx) and (toSlot - 1) or toSlot
                    table.insert(conds, insertAt, moved)
                    selectedCondIdx = nil
                    isAddingCond = false
                    RefreshRightPanel()
                    RefreshRuleList()
                end
            end
        end)
        row:SetScript("OnEnter", function()
            row:SetBackdropColor(0.14, 0.22, 0.35, 0.95)
        end)
        row:SetScript("OnLeave", function()
            row:SetBackdropColor(0.07, 0.11, 0.18, 0.85)
        end)
        row:Show()
        yBase = yBase - 26
    end

    DrawConditionGroupBoxes(spans, rowYTops)

    -- Add Condition button
    rightPanel.addCondBtn:SetWidth(GetRightPanelWidth() - 12)
    rightPanel.addCondBtn:ClearAllPoints()
    rightPanel.addCondBtn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase - 4)
    rightPanel.addCondBtn:Show()
    yBase = yBase - 32

    -- Condition input area
    if isAddingCond then
        if not condInputArea then
            condInputArea = CreateCondInputArea(rightPanel)
        end
        condInputArea.confirmBtn:SetText(selectedCondIdx and "Update" or "Add")
        condInputArea.confirmBtn:SetScript("OnClick", function()
            local ct = condInputArea.GetSelectedType()
            if not ct then
                print("|cffff4444SBAS GUI:|r Select a condition type first.")
                return
            end
            local newCond = { type = ct.id, negate = condInputArea.GetNegate() }
            if ct.needsValue then newCond.value = condInputArea.GetValue() or ct.default end
            if ct.needsResource then
                newCond.resource = condInputArea.GetResource()
                newCond.operator = condInputArea.GetOperator()
                newCond.value    = condInputArea.GetValue() or 0
            end
            if ct.needsCompareValue then
                newCond.operator = condInputArea.GetOperator()
                newCond.value    = condInputArea.GetValue() or ct.default or 0
            end
            if ct.needsLua then
                newCond.luaCode = condInputArea.GetLuaCode()
                if not newCond.luaCode then
                    print("|cffff4444SBAS GUI:|r Enter a Lua expression first.")
                    return
                end
            end
            if ct.needsPlugin then
                local pid = condInputArea.GetPlugin()
                if not pid then
                    print("|cffff4444SBAS GUI:|r Select a plugin/proc first.")
                    return
                end
                newCond.plugin = pid
                if PROC_PLUGIN_BY_ID[pid] then
                    local mode = condInputArea.GetProcMode()
                    if IsCompOp(mode) then
                        newCond.operator = mode
                        newCond.value = condInputArea.GetValue() or 4
                    end
                end
            end
            if ct.needsSpell then
                local sp = condInputArea.GetSpell()
                if sp == nil then
                    print("|cffff4444SBAS GUI:|r Enter a valid spell name for 'Other Spell'.")
                    return
                end
                newCond.spell = sp
            end
            local r = workingRules[selectedIdx]
            if r then
                r.conditions = r.conditions or {}
                if selectedCondIdx then
                    local existing = r.conditions[selectedCondIdx]
                    if existing then
                        for k in pairs(existing) do existing[k] = nil end
                        for k, v in pairs(newCond) do existing[k] = v end
                    end
                else
                    r.conditions[#r.conditions + 1] = newCond
                end
            end
            selectedCondIdx = nil
            isAddingCond = false
            RefreshRightPanel()
            RefreshRuleList()
        end)
        condInputArea:ClearAllPoints()
        if condInputArea.RefreshSize then condInputArea.RefreshSize() end
        condInputArea:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase - 4)
        if selectedCondIdx then
            local r = workingRules[selectedIdx]
            local existingCond = r and r.conditions and r.conditions[selectedCondIdx]
            if existingCond then
                condInputArea.Populate(existingCond)
            else
                condInputArea.Reset()
            end
        else
            condInputArea.Reset()
        end
        condInputArea:Show()
    else
        if condInputArea then condInputArea:Hide() end
    end
end

-------------------------------------------------------------------------------
-- 11b. Spellbook slide-out panel + drag-to-priority system
--
--  A tab button (spellbook icon) is attached to the left edge of the main
--  GUI frame.  Clicking it opens a 224-px-wide panel showing all active-spec
--  and general class spells pulled from the player's spellbook.
--
--  Interaction:
--    Left-click  a spell row → appends the spell to the bottom of the list.
--    Left-drag   a spell row → shows a floating icon; releasing over a rule
--                              row inserts the spell BEFORE that rule;
--                              releasing over the empty list area appends it.
-------------------------------------------------------------------------------
local sbasDrag = { active = false, spellID = nil, spellName = nil }
-- Assign into the forward-declared upvalues so CreateRowFrame closures can see them
ruleDrag      = { active = false, fromIdx = nil, pending = false, pendingX = 0, pendingY = 0 }
condDrag      = { active = false, pending = false, fromIdx = nil, pendingX = 0, pendingY = 0, toSlot = nil }
dragIconFrame = nil
dragCatcher   = nil
local dropIndicator = nil   -- horizontal line shown between rows while reordering

-- Forward declaration so CreateSpellbookPanel can call it for the reset button.
local ResetSeenCastsForCurrentSpec

-- Spells seen via successful player casts, persisted per spec in SavedVariables.
-- Only records spells that are overrides of a class ability (e.g. Rushing Wind Kick).
local seenCastSpells = {}
do
    local function CastsDB()
        SBA_SimpleDB           = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        return SBA_SimpleDB.castsSeen
    end

    local function LoadCastsForSpec()
        local specID = CurrentSpecID()
        wipe(seenCastSpells)
        if specID == 0 then return end
        local saved = CastsDB()[specID]
        if saved then
            for spellID, entry in pairs(saved) do
                seenCastSpells[spellID] = entry
            end
        end
    end

    ResetSeenCastsForCurrentSpec = function()
        local specID = CurrentSpecID()
        wipe(seenCastSpells)
        if specID ~= 0 then
            CastsDB()[specID] = {}
        end
    end

    local castTrackFrame = CreateFrame("Frame")
    castTrackFrame:RegisterEvent("PLAYER_LOGIN")
    castTrackFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    castTrackFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    castTrackFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            LoadCastsForSpec()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit ~= "player" or not spellID or seenCastSpells[spellID] then return end
            -- FindBaseSpellByID returns the spell this one overrides.
            -- If it returns a different ID, spellID is an override spell.
            local baseID = C_SpellBook.FindBaseSpellByID and C_SpellBook.FindBaseSpellByID(spellID)
            if not baseID or baseID == spellID then
                return
            end
            -- Confirm the base spell is actually a class/player ability
            if not IsPlayerSpell(baseID) then
                return
            end
            local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)
            if isPassive then return end
            local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            if not info or not info.name then return end
            local entry = {
                name    = info.name,
                spellID = spellID,
                texture = info.originalIconID or "Interface\\Icons\\INV_Misc_QuestionMark",
            }
            seenCastSpells[spellID] = entry
            local curSpec = CurrentSpecID()
            if curSpec ~= 0 then
                local db = CastsDB()
                db[curSpec]          = db[curSpec] or {}
                db[curSpec][spellID] = entry
            end
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            LoadCastsForSpec()
        end
    end)
end

-- Returns a sorted list of {name, spellID, texture} for the spec being edited.
-- When editing the player's current spec: scans the live spellbook, persists it
-- to SavedVariables, then merges any runtime-captured cast spells.
-- When editing a different spec: returns only the stored spells for that spec
-- (seeded on a prior session when you played that spec).
-- Excludes: off-spec lines, guild, flyouts, FutureSpell slots, and passives.
local function GetClassSpells()
    local curSpec    = CurrentSpecID()
    local targetSpec = (editSpecID ~= 0) and editSpecID or curSpec

    -- ── Cross-spec: skip live scan, just return stored spells for that spec ──
    if targetSpec ~= curSpec then
        local result, seenIDs = {}, {}
        local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
        if srcDB then
            for _, entry in pairs(srcDB) do
                if entry.spellID and not seenIDs[entry.spellID] then
                    seenIDs[entry.spellID] = true
                    result[#result + 1] = entry
                end
            end
        end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    end

    -- ── Own spec (or no API): live spellbook scan ─────────────────────────
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
        -- No spellbook API: fall back to stored data for the target spec.
        local result, seenIDs = {}, {}
        local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
        if srcDB then
            for _, entry in pairs(srcDB) do
                if entry.spellID and not seenIDs[entry.spellID] then
                    seenIDs[entry.spellID] = true
                    result[#result + 1] = entry
                end
            end
        end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    end
    local spells, seen = {}, {}
    local isFlyoutType = Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
    local isFutureType = Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell
    -- Primary tabs: class, active spec, racial — spells included freely (minus passives without icons)
    local primaryTabs = {}
    primaryTabs[UnitClass("player")] = true                        -- e.g. "Monk"
    primaryTabs[UnitRace("player")]  = true                        -- e.g. "Pandaren"
    local specIdx = GetSpecialization and GetSpecialization()
    if specIdx then
        local specName = select(2, GetSpecializationInfo(specIdx)) -- e.g. "Windwalker"
        if specName then primaryTabs[specName] = true end
    end
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        -- Visit all non-guild, non-offSpec tabs (includes General tab)
        if info and not info.isGuild and not info.offSpecID then
            local isPrimaryTab = primaryTabs[info.name]
            local offset = info.itemIndexOffset
            local count  = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name, subName =
                    C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local itemType, spellID =
                    C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if name and spellID and spellID ~= 0 then
                    local isPassive = C_Spell.IsSpellPassive  and C_Spell.IsSpellPassive(spellID)
                    -- Non-primary tabs (e.g. General): only include if subtext contains "Racial"
                    local subtext   = (not isPrimaryTab) and C_Spell.GetSpellSubtext
                                      and C_Spell.GetSpellSubtext(spellID) or nil
                    local skip = (isFlyoutType and itemType == isFlyoutType)
                              or (isFutureType and itemType == isFutureType)
                              or (not isPrimaryTab and not (subtext and subtext:find("Racial")))
                              or (isPassive)   -- passives without an icon are excluded
                              or seen[spellID]
                    if not skip then
                        local baseInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
                        local baseName = (baseInfo and baseInfo.name) or name
                        seen[spellID] = true

                        local overID, overInfo, overName
                        if C_SpellBook.FindSpellOverrideByID then
                            local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                            if oid and oid ~= spellID and not seen[oid] then
                                local isOverPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(oid)
                                if not isOverPassive then
                                    overID   = oid
                                    overInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                                    overName = overInfo and overInfo.name
                                end
                            end
                        end

                        if overID then
                            seen[overID] = true
                            -- Names differ: both are distinct spells, add both
                            if overName and overName ~= baseName then
                                spells[#spells + 1] = {
                                    name    = baseName,
                                    spellID = spellID,
                                    texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                }
                            end
                            -- Always add the override (only entry when names match)
                            spells[#spells + 1] = {
                                name    = overName or baseName,
                                spellID = overID,
                                texture = (overInfo and overInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        else
                            -- No active override — add the base spell
                            spells[#spells + 1] = {
                                name    = baseName,
                                spellID = spellID,
                                texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        end
                    end
                end
            end
        end
    end
    -- Persist the freshly scanned spellbook spells into the current spec's store
    -- so they are available for cross-spec editing in future sessions.
    if curSpec ~= 0 then
        SBA_SimpleDB           = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        SBA_SimpleDB.castsSeen[curSpec] = SBA_SimpleDB.castsSeen[curSpec] or {}
        local curDB = SBA_SimpleDB.castsSeen[curSpec]
        for _, sp in ipairs(spells) do
            if not curDB[sp.spellID] then
                curDB[sp.spellID] = { name = sp.name, spellID = sp.spellID, texture = sp.texture }
            end
        end
    end

    -- Build name-index to avoid duplicates when merging stored data.
    local seenNames = {}
    for _, sp in ipairs(spells) do seenNames[sp.name] = true end

    -- Merge stored spells and any in-memory runtime captures for the current spec.
    local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
    if srcDB then
        for castID, entry in pairs(srcDB) do
            if not seen[castID] and entry.name and not seenNames[entry.name] then
                seen[castID]           = true
                seenNames[entry.name]  = true
                spells[#spells + 1]    = entry
            end
        end
    end
    for castID, entry in pairs(seenCastSpells) do
        if not seen[castID] and entry.name and not seenNames[entry.name] then
            seen[castID] = true
            spells[#spells + 1] = entry
        end
    end
    table.sort(spells, function(a, b) return a.name < b.name end)
    return spells
end

EnsureDragIcon = function()
    if dragIconFrame then return end
    dragIconFrame = CreateFrame("Frame", "SBAS_SpellDragIcon", UIParent)
    dragIconFrame:SetSize(38, 38)
    dragIconFrame:SetFrameStrata("TOOLTIP")
    dragIconFrame:Hide()
    local tex = dragIconFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dragIconFrame._tex = tex
    local glow = dragIconFrame:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    glow:SetBlendMode("ADD")
    dragIconFrame:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
end

EnsureDragCatcher = function()
    if dragCatcher then return end
    dragCatcher = CreateFrame("Frame", "SBAS_SpellDragCatcher", UIParent)
    dragCatcher:SetAllPoints(UIParent)
    dragCatcher:SetFrameStrata("DIALOG")
    dragCatcher:EnableMouse(true)
    dragCatcher:Hide()

    -- Drop indicator: a bright horizontal line shown between rows during reorder
    dropIndicator = CreateFrame("Frame", "SBAS_DropIndicator", UIParent)
    dropIndicator:SetSize(1, 3)
    dropIndicator:SetFrameStrata("TOOLTIP")
    dropIndicator:Hide()
    local diTex = dropIndicator:CreateTexture(nil, "ARTWORK")
    diTex:SetAllPoints()
    diTex:SetColorTexture(0.3, 0.85, 1, 1)

    -- Helper: find which "slot" (1 = before row1, 2 = before row2, ..., n+1 = after last)
    -- the cursor is closest to, for the drop indicator.
    local function GetRuleDropSlot(mx, my)
        local best, bestDist = 1, math.huge
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rt = rf:GetTop()
                if rt then
                    local d = math.abs(my - rt)
                    if d < bestDist then bestDist = d; best = i end
                end
            end
        end
        -- Also check below the last visible row
        local lastVisible = 0
        for i, rf in ipairs(rowFrames) do if rf:IsShown() then lastVisible = i end end
        if lastVisible > 0 then
            local rb = rowFrames[lastVisible]:GetBottom()
            if rb and math.abs(my - rb) < bestDist then best = lastVisible + 1 end
        end
        return best
    end

    -- Shared drop-logic extracted so both OnUpdate (release-to-drop) and
    -- OnMouseUp (fallback) can call it without duplication.
    local function FinishRuleDrop()
        local fromIdx = ruleDrag.fromIdx
        ruleDrag.active  = false
        ruleDrag.fromIdx = nil
        if dragIconFrame then dragIconFrame:Hide() end
        if dropIndicator then dropIndicator:Hide() end
        dragCatcher:Hide()

        -- Restore borders
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                if rf._idx and rf._idx == selectedIdx then
                    rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else
                    rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                end
            end
        end

        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s
        local slot = GetRuleDropSlot(mx, my)
        slot = math.max(1, math.min(slot, #workingRules + 1))
        if slot ~= fromIdx and slot ~= fromIdx + 1 then
            local rule = table.remove(workingRules, fromIdx)
            local toIdx = (slot > fromIdx) and (slot - 1) or slot
            table.insert(workingRules, toIdx, rule)
            selectedIdx = toIdx
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end
    end

    local function FinishSpellDrop()
        sbasDrag.active = false
        if dragIconFrame then dragIconFrame:Hide() end
        dragCatcher:Hide()

        -- Restore row border colours
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                if rf._idx and rf._idx == selectedIdx then
                    rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else
                    rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                end
            end
        end

        if not sbasDrag.spellID then return end

        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s

        local insertIdx = nil
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr = rf:GetLeft(),  rf:GetRight()
                local rt, rb = rf:GetTop(),   rf:GetBottom()
                if rl and rr and rt and rb
                   and mx >= rl and mx <= rr and my >= rb and my <= rt then
                    insertIdx = i
                    break
                end
            end
        end
        if not insertIdx and guiFrame and guiFrame._leftSF then
            local sf = guiFrame._leftSF
            local ll, lr = sf:GetLeft(),  sf:GetRight()
            local lt, lb = sf:GetTop(),   sf:GetBottom()
            if ll and lr and lt and lb
               and mx >= ll and mx <= lr and my >= lb and my <= lt then
                insertIdx = #workingRules + 1
            end
        end

        if insertIdx then
            local id   = sbasDrag.spellID
            local name = sbasDrag.spellName
            if insertIdx > #workingRules then
                workingRules[#workingRules + 1] = { spellID = id, name = name, conditions = {} }
                selectedIdx = #workingRules
            else
                table.insert(workingRules, insertIdx, { spellID = id, name = name, conditions = {} })
                selectedIdx = insertIdx
            end
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end

        sbasDrag.spellID   = nil
        sbasDrag.spellName = nil
    end

    -- Highlight row under cursor while dragging
    dragCatcher:SetScript("OnUpdate", function()
        -- ── Pending drag: wait for 8-px movement before activating ─────────
        if ruleDrag.pending then
            if not IsMouseButtonDown("LeftButton") then
                -- Mouse released before threshold — cancel cleanly
                ruleDrag.pending = false
                ruleDrag.fromIdx = nil
                dragCatcher:Hide()
                return
            end
            local cx, cy = GetCursorPosition()
            local s = UIParent:GetEffectiveScale()
            cx, cy = cx / s, cy / s
            local dx = cx - ruleDrag.pendingX
            local dy = cy - ruleDrag.pendingY
            if dx * dx + dy * dy > 64 then   -- 8-pixel threshold
                ruleDrag.pending = false
                ruleDrag.active  = true
                dragCatcher:EnableMouse(true)
                if dragIconFrame then dragIconFrame:Show() end
            end
            return
        end
        if not sbasDrag.active and not ruleDrag.active then return end
        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s
        if ruleDrag.active then
            -- ── Drop as soon as the mouse button is released ─────────────
            if not IsMouseButtonDown("LeftButton") then
                FinishRuleDrop()
                return
            end
            -- Show drop indicator line between rows
            local slot = GetRuleDropSlot(mx, my)
            local indY = nil
            if slot <= #rowFrames and rowFrames[slot] and rowFrames[slot]:IsShown() then
                indY = rowFrames[slot]:GetTop()
            elseif slot > 1 and rowFrames[slot-1] and rowFrames[slot-1]:IsShown() then
                indY = rowFrames[slot-1]:GetBottom()
            end
            if indY and rowFrames[1] and rowFrames[1]:IsShown() then
                local rowW = rowFrames[1]:GetWidth()
                local rowL = rowFrames[1]:GetLeft()
                dropIndicator:ClearAllPoints()
                dropIndicator:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", rowL, indY)
                dropIndicator:SetWidth(rowW)
                dropIndicator:Show()
            end
            -- Dim the row being dragged
            for i, rf in ipairs(rowFrames) do
                if rf:IsShown() then
                    if i == ruleDrag.fromIdx then
                        rf:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
                    else
                        rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                    end
                end
            end
            return
        end
        -- sbasDrag: drop on release, otherwise highlight drop target row
        if not IsMouseButtonDown("LeftButton") then
            FinishSpellDrop()
            return
        end
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr = rf:GetLeft(),  rf:GetRight()
                local rt, rb = rf:GetTop(),   rf:GetBottom()
                if rl and rr and rt and rb
                   and mx >= rl and mx <= rr and my >= rb and my <= rt then
                    rf:SetBackdropBorderColor(0.50, 0.88, 0.25, 1)
                else
                    if rf._idx and rf._idx == selectedIdx then
                        rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                    else
                        rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                    end
                end
            end
        end
    end)

    -- Finalise the drag on mouse-up (fallback; OnUpdate handles rule reorder
    -- via release detection, but spell-drop still needs this path)
    dragCatcher:SetScript("OnMouseUp", function(self, btn)
        -- Cancel a pending drag that never crossed the movement threshold
        if ruleDrag.pending then
            ruleDrag.pending = false
            ruleDrag.fromIdx = nil
            self:Hide()
            return
        end
        if btn ~= "LeftButton" then return end

        -- Rule reorder is handled by OnUpdate polling; call shared finish
        -- only if OnUpdate somehow missed it (e.g. very fast release)
        if ruleDrag.active then
            FinishRuleDrop()
            return
        end

        if not sbasDrag.active then self:Hide(); return end
        -- OnUpdate handles release-to-drop; this is just a fallback
        FinishSpellDrop()
    end)
end

-------------------------------------------------------------------------------
-- Condition drag-drop (reorder conditions inside the right panel)
-- NOTE: In WoW, OnMouseUp ALWAYS fires on the frame that received OnMouseDown,
-- even if the cursor has moved far away.  There is no need for a full-screen
-- mouse-catcher here; the condition row's own OnMouseUp handles the drop.
-------------------------------------------------------------------------------
EnsureCondCatcher = function()
    if condCatcher then return end

    -- Drop-line indicator (cyan horizontal bar between rows)
    condDropLine = CreateFrame("Frame", nil, UIParent)
    condDropLine:SetHeight(2)
    condDropLine:SetFrameStrata("TOOLTIP")
    condDropLine:Hide()
    local diTex = condDropLine:CreateTexture(nil, "ARTWORK")
    diTex:SetAllPoints()
    diTex:SetColorTexture(0.3, 0.85, 1, 0.95)

    -- Lightweight ticker: handles threshold detection, drop-slot calculation,
    -- and drop-line positioning only.  The actual reorder happens in the
    -- condition row's OnMouseUp (which WoW reliably sends to the row that
    -- received OnMouseDown, regardless of cursor position at release time).
    condCatcher = CreateFrame("Frame", "SBAS_CondDragTicker", UIParent)
    condCatcher:SetScript("OnUpdate", function()
        if not condDrag.pending and not condDrag.active then
            if condDropLine then condDropLine:Hide() end
            return
        end

        local cx, cy = GetCursorPosition()
        local sc = UIParent:GetEffectiveScale()
        cx, cy = cx / sc, cy / sc

        if condDrag.pending then
            if not IsMouseButtonDown("LeftButton") then
                -- Released before threshold; row's OnMouseUp will handle it
                return
            end
            local dx = cx - condDrag.pendingX
            local dy = cy - condDrag.pendingY
            if dx * dx + dy * dy > 64 then
                condDrag.pending = false
                condDrag.active  = true
            end
            return
        end

        if not condDrag.active then return end

        -- Safety net: mouse released outside all condition row frames
        if not IsMouseButtonDown("LeftButton") then
            condDrag.active  = false
            condDrag.fromIdx = nil
            condDrag.toSlot  = nil
            if condDropLine then condDropLine:Hide() end
            return
        end

        -- Update drop slot from cursor position
        local rule     = selectedIdx > 0 and workingRules[selectedIdx]
        local numConds = rule and #(rule.conditions or {}) or 0
        local panelTop = rightPanel and rightPanel:GetTop()
        if not panelTop or numConds == 0 then return end

        local relY = cy - panelTop
        local slot = numConds + 1
        for j = 1, numConds do
            if relY > (condRowYList[j] or 0) - 11 then
                slot = j
                break
            end
        end
        condDrag.toSlot = slot

        -- Position drop-line indicator
        local lineY
        if slot <= numConds then
            lineY = condRowYList[slot] or 0
        else
            lineY = (condRowYList[numConds] or 0) - 22
        end
        local panelLeft = rightPanel:GetLeft() or 0
        condDropLine:ClearAllPoints()
        condDropLine:SetWidth(GetRightPanelWidth() - 12)
        condDropLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", panelLeft + 6, panelTop + lineY)
        condDropLine:Show()
    end)
end

local function CreateSpellbookPanel(f, leftSF)
    EnsureDragIcon()
    EnsureDragCatcher()
    f._leftSF = leftSF

    -- ── Slide-out spellbook panel ─────────────────────────────────────────
    -- The panel is parented to the main frame and positioned to its left.
    local PANEL_W = 264
    local panel   = CreateFrame("Frame", "SBAS_SpellbookPanel", f, "BackdropTemplate")
    panel:SetSize(PANEL_W, f:GetHeight())
    panel:SetPoint("TOPRIGHT", f, "TOPLEFT", -1, 0)
    panel:SetFrameLevel(f:GetFrameLevel() + 1)
    panel:Hide()
    SetBD(panel, 0.04, 0.06, 0.12, 0.97, 0.24, 0.44, 0.64)

    -- ── Tab button ────────────────────────────────────────────────────────
    -- Parented to the PANEL so it flies out with it when the panel shows.
    -- Positioned on the panel's RIGHT edge near the top so it peeks out
    -- against the main frame's left border.
    local TAB_W, TAB_H = 54, 56   -- taller to fit icon + label
    local tabBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    tabBtn:SetSize(TAB_W, TAB_H)
    tabBtn:SetFrameLevel(panel:GetFrameLevel() + 2)
    -- RIGHT edge of tab = LEFT edge of panel (tab peeks out to the far left)
    tabBtn:SetPoint("TOPRIGHT", panel, "TOPLEFT", 0, -14)
    SetBD(tabBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    -- Book icon above the label
    local tabIcon = tabBtn:CreateTexture(nil, "ARTWORK")
    tabIcon:SetSize(28, 28)
    tabIcon:SetPoint("TOP", tabBtn, "TOP", 0, -5)
    tabIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    tabIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- "Spells" label below the icon
    local tabLbl = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLbl:SetPoint("BOTTOM", tabBtn, "BOTTOM", 0, 6)
    tabLbl:SetJustifyH("CENTER")
    tabLbl:SetText("Spells")
    tabLbl:SetTextColor(0.65, 0.85, 1, 1)

    tabBtn:SetScript("OnEnter", function()
        tabIcon:SetVertexColor(0.5, 0.85, 1, 1)
        tabLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(tabBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    tabBtn:SetScript("OnLeave", function()
        tabIcon:SetVertexColor(1, 1, 1, 1)
        tabLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    -- When the panel is hidden the tab still needs to be clickable to reopen.
    -- We achieve this by keeping the panel's tab visible at all times and
    -- hooking the panel OnHide to show just the tab stub on the main frame.
    -- Simpler: keep a separate stub button parented to the main frame that
    -- is shown only when the panel is hidden.
    local stubBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    stubBtn:SetSize(TAB_W, TAB_H)
    stubBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -14)
    SetBD(stubBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    local stubIcon = stubBtn:CreateTexture(nil, "ARTWORK")
    stubIcon:SetSize(28, 28)
    stubIcon:SetPoint("TOP", stubBtn, "TOP", 0, -5)
    stubIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    stubIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local stubLbl = stubBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stubLbl:SetPoint("BOTTOM", stubBtn, "BOTTOM", 0, 6)
    stubLbl:SetJustifyH("CENTER")
    stubLbl:SetText("Spells")
    stubLbl:SetTextColor(0.65, 0.85, 1, 1)

    stubBtn:SetScript("OnEnter", function()
        stubIcon:SetVertexColor(0.5, 0.85, 1, 1)
        stubLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(stubBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    stubBtn:SetScript("OnLeave", function()
        stubIcon:SetVertexColor(1, 1, 1, 1)
        stubLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    local phdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -12)
    phdr:SetText("Spells")
    phdr:SetTextColor(0.38, 0.74, 1, 1)

    -- Reset button: clears the persisted seen-spells list for the current spec
    local resetBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    resetBtn:SetSize(52, 16)
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -10)
    SetBD(resetBtn, 0.28, 0.05, 0.05, 0.90, 0.65, 0.18, 0.18)
    local resetLbl = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetLbl:SetAllPoints()
    resetLbl:SetJustifyH("CENTER")
    resetLbl:SetText("Reset")
    resetLbl:SetTextColor(1, 0.55, 0.55, 1)
    resetBtn:SetScript("OnEnter", function(self)
        resetLbl:SetTextColor(1, 0.8, 0.8, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Reset Spell Cache", 1, 0.6, 0.6)
        GameTooltip:AddLine("Clears the cached spell list for this spec.\nReopening the GUI will rebuild it from your spellbook.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        resetLbl:SetTextColor(1, 0.55, 0.55, 1)
        GameTooltip:Hide()
    end)
    -- OnClick wired up below, after RefreshSpellbookPanel is defined.

    local searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetSize(PANEL_W - 16, 22)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(64)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local divLine = panel:CreateTexture(nil, "ARTWORK")
    divLine:SetSize(PANEL_W - 8, 1)
    divLine:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -4)
    divLine:SetColorTexture(0.25, 0.40, 0.60, 0.6)

    local hintLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintLbl:SetPoint("TOPLEFT", divLine, "BOTTOMLEFT", 4, -3)
    hintLbl:SetSize(PANEL_W - 16, 24)
    hintLbl:SetJustifyH("LEFT")
    hintLbl:SetText("Click to add  ·  Drag to insert at position")
    hintLbl:SetTextColor(0.48, 0.62, 0.72, 1)

    local panelSF = CreateFrame("ScrollFrame", nil, panel)
    panelSF:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4, -92)
    panelSF:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4,  4)
    panelSF:EnableMouseWheel(true)
    panelSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 28, 0), m))
    end)

    local panelContent = CreateFrame("Frame", nil, panelSF)
    panelContent:SetSize(PANEL_W - 8, 100)
    panelSF:SetScrollChild(panelContent)

    local spellRowPool  = {}
    local currentSpells = {}
    local SPELL_ROW_H   = 30

    local function CreateSpellEntry(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(PANEL_W - 8, SPELL_ROW_H - 2)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:RegisterForClicks("LeftButtonUp")

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        row._bg = bg

        local iconBg = row:CreateTexture(nil, "BACKGROUND")
        iconBg:SetSize(24, 24)
        iconBg:SetPoint("LEFT", row, "LEFT", 4, 0)
        iconBg:SetColorTexture(0, 0, 0, 0.45)

        local iconTex = row:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(22, 22)
        iconTex:SetPoint("CENTER", iconBg, "CENTER")
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = iconTex

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameLbl:SetPoint("LEFT",  iconBg, "RIGHT", 6, 0)
        nameLbl:SetPoint("RIGHT", row,    "RIGHT", -4, 0)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetTextColor(0.88, 0.92, 1, 1)
        row._nameLbl = nameLbl

        row:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.16, 0.28, 0.48, 0.70)
            if self._spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self._spellID)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)

        -- Left-click: append to end of priority list
        row:SetScript("OnClick", function(self)
            if not self._spellID then return end
            local addID, addName = ResolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            workingRules[#workingRules + 1] = {
                spellID    = addID,
                name       = addName,
                conditions = {},
            }
            selectedIdx  = #workingRules
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end)

        -- Left-drag: drag to a specific position in the priority list
        row:SetScript("OnDragStart", function(self)
            if not self._spellID then return end
            local addID, addName = ResolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            sbasDrag.active    = true
            sbasDrag.spellID   = addID
            sbasDrag.spellName = addName
            dragIconFrame._tex:SetTexture(self._icon:GetTexture())
            dragIconFrame:Show()
            dragCatcher:Show()
        end)

        return row
    end

    local function PopulatePanel(filterText)
        local filter = (filterText or ""):lower()
        local shown  = 0
        for _, spell in ipairs(currentSpells) do
            if filter == "" or spell.name:lower():find(filter, 1, true) then
                shown = shown + 1
                if not spellRowPool[shown] then
                    spellRowPool[shown] = CreateSpellEntry(panelContent)
                end
                local row = spellRowPool[shown]
                row._spellID   = spell.spellID
                row._spellName = spell.name
                row._icon:SetTexture(spell.texture)
                row._nameLbl:SetText(spell.name)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", panelContent, "TOPLEFT", 0, -(shown - 1) * SPELL_ROW_H)
                row:Show()
            end
        end
        for i = shown + 1, #spellRowPool do
            if spellRowPool[i] then spellRowPool[i]:Hide() end
        end
        panelContent:SetHeight(math.max(shown * SPELL_ROW_H + 4, 100))
    end

    local function RefreshSpellbookPanel()
        currentSpells = GetClassSpells()
        PopulatePanel(searchBox:GetText())
    end
    -- Expose so OpenGUI can force a refresh on every open.
    f._refreshSpellPanel = RefreshSpellbookPanel

    -- Wire up the reset button now that RefreshSpellbookPanel is in scope.
    resetBtn:SetScript("OnClick", function()
        ResetSeenCastsForCurrentSpec()
        RefreshSpellbookPanel()
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        PopulatePanel(self:GetText())
    end)

    local function OpenPanel()
        RefreshSpellbookPanel()
        stubBtn:Hide()
        panel:Show()
    end

    local function ClosePanel()
        panel:Hide()
        stubBtn:Show()
    end

    tabBtn:SetScript("OnClick",  function() ClosePanel() end)
    stubBtn:SetScript("OnClick", function() OpenPanel()  end)

    -- Start with the stub visible (panel closed)
    stubBtn:Show()

    -- Keep panel height in sync with the main frame
    f:HookScript("OnSizeChanged", function(self)
        panel:SetHeight(self:GetHeight())
    end)

    -- ── Rebuild spell list on talent/spec change ──────────────────────────
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshSpellbookPanel()
        else
            -- Mark stale so the next open rebuilds automatically
            currentSpells = nil
        end
    end)

    -- Rebuild when panel opens if the list was marked stale
    panel:HookScript("OnShow", function()
        if currentSpells == nil then
            RefreshSpellbookPanel()
        end
    end)
end

-------------------------------------------------------------------------------
-- 12. Main GUI frame
-------------------------------------------------------------------------------
local function CreateGUI()
    local f = CreateFrame("Frame", "SBAS_OverrideGUI_Frame", UIParent, "BackdropTemplate")
    f:SetSize(GUI_W, GUI_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:SetFrameStrata("HIGH")
    if f.SetResizeBounds then
        f:SetResizeBounds(GUI_MIN_W, GUI_MIN_H)
    elseif f.SetMinResize then
        f:SetMinResize(GUI_MIN_W, GUI_MIN_H)
    end
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    SetBD(f, 0.03, 0.05, 0.09, 0.97, 0.24, 0.44, 0.64)

    -- Do NOT add to UISpecialFrames — that table is iterated by CloseAllWindows()
    -- which WoW calls when the Settings window closes via Escape, causing the GUI
    -- to be hidden as an unintended side-effect.  Instead, handle Escape directly.
    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetTextColor(0.38, 0.74, 1, 1)

    local subNote = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subNote:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
    subNote:SetText("Top = highest priority · Saving overwrites override code for this spec")
    subNote:SetTextColor(0.44, 0.55, 0.68, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f:HookScript("OnHide", function()
        CloseAllPopups()
        -- Auto-save rule structure to the same store as the explicit Save button so
        -- rules survive close/reopen within a session and across /reload.  The compiled
        -- override code is NOT regenerated here — that still requires "Save & Apply".
        if editSpecID and editSpecID ~= 0 then
            sessionRules[editSpecID]    = workingRules          -- in-session reference
            GuiDB()[editSpecID]         = DeepCopyRules(workingRules) -- persisted storage
        end
    end)

    -- Belt-and-suspenders: also save on PLAYER_LOGOUT/PLAYER_QUITING so that
    -- a /reload where OnHide may not fire still persists the working rules.
    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:RegisterEvent("PLAYER_QUITING")
    logoutFrame:SetScript("OnEvent", function()
        if editSpecID and editSpecID ~= 0 then
            GuiDB()[editSpecID] = DeepCopyRules(workingRules)
        end
    end)

    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
        f.isSizing = true
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        if f.isSizing then
            f:StopMovingOrSizing()
            f.isSizing = false
        end
    end)

    -- ── Left panel: priority list ──────────────────────────────────────────
    local leftHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftHdr:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -48)
    leftHdr:SetText("Priority List")
    leftHdr:SetTextColor(0.50, 0.72, 0.90, 1)

    local leftSF = CreateFrame("ScrollFrame", nil, f)
    leftSF:SetPoint("TOPLEFT",     f, "TOPLEFT", PAD, -64)
    -- Reserve 64px top (header) + 38px footer buttons + 34px Add Spell btn + gap = 136px
    leftSF:SetSize(LEFT_W, GUI_H - 136)
    leftSF:EnableMouseWheel(true)
    leftSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * ROW_H, 0), m))
    end)
    f._leftSF = leftSF   -- stored for drag-drop drop-zone detection

    local lc = CreateFrame("Frame", nil, leftSF)
    lc:SetSize(LEFT_W, 100)
    leftSF:SetScrollChild(lc)
    leftChild = lc

    -- Add Spell button
    local addSpellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addSpellBtn:SetSize(LEFT_W, 26)
    addSpellBtn:SetPoint("TOPLEFT", leftSF, "BOTTOMLEFT", 0, -4)
    addSpellBtn:SetText("+ Add Spell")
    addSpellBtn:SetScript("OnClick", function()
        if addSpellPopup and addSpellPopup:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        if not addSpellPopup then
            addSpellPopup = CreateAddSpellPopup()
        end
        addSpellPopup.onAdd = function(id, name)
            local addID, addName = ResolveSpellForAdd(id, name)
            if not addID then return end
            workingRules[#workingRules + 1] = { spellID = addID, name = addName, conditions = {} }
            selectedIdx  = #workingRules
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end
        addSpellPopup.nameBox:SetText("")
        addSpellPopup.iconTex:Hide()
        addSpellPopup:ClearAllPoints()
        addSpellPopup:SetPoint("TOPLEFT", addSpellBtn, "BOTTOMLEFT", 0, -2)
        addSpellPopup:Show()
        addSpellPopup.nameBox:SetFocus()
    end)

    -- ── Right panel: condition editor ──────────────────────────────────────
    local rp = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rp:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    -PAD, -64)
    rp:SetSize(RIGHT_W, GUI_H - 110)
    SetBD(rp, 0.04, 0.07, 0.13, 0.90, 0.18, 0.33, 0.53)

    local rpHdr = rp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rpHdr:SetPoint("TOPLEFT", rp, "TOPLEFT", 8, -8)
    rpHdr:SetSize(RIGHT_W - 16, 18)
    rpHdr:SetJustifyH("LEFT")
    rpHdr:SetText("Conditions")
    rpHdr:SetTextColor(0.50, 0.72, 0.90, 1)
    rp.header = rpHdr

    local addCondBtn = CreateFrame("Button", nil, rp, "UIPanelButtonTemplate")
    addCondBtn:SetSize(RIGHT_W - 12, 24)
    addCondBtn:SetText("+ Add Condition")
    addCondBtn:SetScript("OnClick", function()
        if selectedIdx > 0 and workingRules[selectedIdx] then
            selectedCondIdx = nil
            isAddingCond = true
            RefreshRightPanel()
        end
    end)
    addCondBtn:Hide()
    rp.addCondBtn = addCondBtn

    rightPanel = rp

    -- ── Footer buttons ─────────────────────────────────────────────────────
    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(128, 28)
    saveBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD + 4)
    saveBtn:SetText("Save & Apply")
    saveBtn:SetScript("OnClick", function()
        -- Validate parentheses before saving
        local mismatchedPriorities = {}
        for i, rule in ipairs(workingRules) do
            if HasParenMismatch(rule.conditions) then
                mismatchedPriorities[#mismatchedPriorities + 1] = i
            end
        end
        if #mismatchedPriorities > 0 then
            local nums = table.concat(mismatchedPriorities, ", ")
            print("|cffFF4444SBAS Override GUI:|r Save blocked — mismatched parentheses in "
                  .. "priorit" .. (#mismatchedPriorities == 1 and "y " or "ies ")
                  .. nums .. ". Fix the red rows first.")
            return
        end
        -- Persist GUI rules
        GuiDB()[editSpecID] = DeepCopyRules(workingRules)
        -- Keep the session cache in sync
        sessionRules[editSpecID] = workingRules

        -- Generate and save override code
        local code = GenerateCode(workingRules) or ""
        SBA_SimpleDB.specs                         = SBA_SimpleDB.specs or {}
        SBA_SimpleDB.specs[editSpecID]             = SBA_SimpleDB.specs[editSpecID] or {}
        SBA_SimpleDB.specs[editSpecID].overrideCode   = code
        SBA_SimpleDB.specs[editSpecID].overrideSource = "gui"
        SBA_SimpleDB.overrideCode                  = code

        -- Compile if editing current spec
        if editSpecID == CurrentSpecID() and type(SBA_Simple_SetOverrideCode) == "function" then
            SBA_Simple_SetOverrideCode(code)
        end

        print("|cff00ff99SBAS Override GUI:|r Priority list saved for "
              .. GetSpecName(editSpecID))
        -- Notify PoulsTools integration so it can determine the override mode
        -- (optimized vs custom) based on whether the saved rules match the baseline.
        if type(_G.SBAS_OnGuiSaveAndApply) == "function" then
            local savedExport = SerializeRulesForExportV2(editSpecID, workingRules)
            _G.SBAS_OnGuiSaveAndApply(editSpecID, savedExport)
        end
        f:Hide()
        -- Refresh the analyzer if it is currently visible (GUI save keeps it relevant)
        local af = _G["SBAS_OverrideAnalyzerFrame"]
        if af and af:IsShown() and type(_G.SBAS_OpenOrRefreshAnalyzer) == "function" then
            _G.SBAS_OpenOrRefreshAnalyzer(editSpecID, GetSpecName(editSpecID))
        end
    end)

    local previewBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    previewBtn:SetSize(106, 28)
    previewBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    previewBtn:SetText("Preview Code")
    previewBtn:SetScript("OnClick", function()
        local of = _G["SBAS_OverrideFrame"]
        if of and of:IsShown() then
            of:Hide()
            return
        end
        local code = GenerateCode(workingRules) or "-- (no rules defined)"
        -- Open raw override editor in temporary preview mode (non-persistent).
        if type(SBA_Simple_ShowOverridePreview) == "function" then
            SBA_Simple_ShowOverridePreview(code, editSpecID, GetSpecName(editSpecID))
        else
            -- Fallback for older SBA_Simple versions where preview API isn't available.
            local eb = _G["SBAS_OverrideEditBox"]
            if eb and of then
                eb:SetText(code)
                of:Show()
            else
                print("|cff00ccffSBAS Preview:|r\n" .. code)
            end
        end
    end)

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(82, 28)
    exportBtn:SetPoint("LEFT", previewBtn, "RIGHT", 6, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        ShowExportPopup(exportBtn, editSpecID, workingRules)
    end)

    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(82, 28)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        ShowImportPopup(importBtn, function(payload)
            local imported, err = DeserializeRulesFromExport(payload, editSpecID)
            if not imported then
                print("|cffff4444SBAS Override GUI:|r Import failed - " .. tostring(err or "invalid text"))
                return false
            end

            workingRules = DeepCopyRules(imported)
            sessionRules[editSpecID] = workingRules
            selectedIdx = (#workingRules > 0) and 1 or 0
            selectedCondIdx = nil
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()

            print("|cff00ff99SBAS Override GUI:|r Imported " .. tostring(#workingRules)
                  .. " priorit" .. ((#workingRules == 1) and "y" or "ies")
                  .. " for " .. GetSpecName(editSpecID)
                  .. ". Click Save & Apply to compile.")
            return true
        end)
    end)

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(104, 28)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 6, 0)
    clearBtn:SetText("Clear All Rules")
    clearBtn:SetScript("OnClick", function()
        workingRules = {}
        selectedIdx  = 0
        isAddingCond = false
        RefreshRuleList()
        RefreshRightPanel()
    end)

    local function LayoutGUI()
        local leftW, rightW = GetPanelWidths(f:GetWidth())
        leftSF:SetSize(leftW, f:GetHeight() - 136)
        lc:SetWidth(leftW)
        addSpellBtn:SetWidth(leftW)
        rp:SetSize(rightW, f:GetHeight() - 110)
        rpHdr:SetWidth(rightW - 16)
        addCondBtn:SetWidth(rightW - 12)
        if condInputArea and condInputArea.RefreshSize then
            condInputArea.RefreshSize()
        end
        if f:IsShown() then
            RefreshRuleList()
            RefreshRightPanel()
        end
    end

    f:SetScript("OnSizeChanged", function()
        LayoutGUI()
    end)

    LayoutGUI()

    CreateSpellbookPanel(f, leftSF)

    guiFrame = f
end

-------------------------------------------------------------------------------
-- 13. Open the GUI
-------------------------------------------------------------------------------
local function OpenGUI(specID, displayName)
    if not guiFrame then CreateGUI() end

    local targetSpec = specID or CurrentSpecID()
    -- If the API can't determine the spec yet, keep whatever is loaded
    if targetSpec == 0 then targetSpec = editSpecID end

    if targetSpec ~= editSpecID then
        editSpecID = targetSpec
        -- Refresh the condition editor's secondary-resource button label for the new spec
        if condInputArea and condInputArea.RefreshSpec then condInputArea.RefreshSpec() end
        if sessionRules[editSpecID] then
            -- Already seen this spec this session — reuse the live in-memory table
            workingRules = sessionRules[editSpecID]
        else
            -- First time opening this spec this session: load from persistent storage
            workingRules = DeepCopyRules(GetGuiRules(editSpecID))
        end
        selectedIdx  = (#workingRules > 0) and 1 or 0
        isAddingCond = false
    end
    -- Same spec: workingRules unchanged — all unsaved edits are still in memory.
    -- Seed the session cache if this is the very first open.
    if not sessionRules[editSpecID] then
        sessionRules[editSpecID] = workingRules
    end

    guiFrame.title:SetText("SBA Override Builder — " .. (displayName or GetSpecName(editSpecID)))
    guiFrame:Show()
    -- Refresh the flyout spell list on every open so it reflects the current
    -- spec, any newly cast override spells, and talent changes.
    if guiFrame._refreshSpellPanel then
        guiFrame._refreshSpellPanel()
    end
    RefreshRuleList()
    RefreshRightPanel()
end

_G.SBAS_OpenOverrideGUI    = OpenGUI

-- Public: open GUI for a spec and load rules from an import/export payload.
-- This uses the exact same parser as the Import button in the GUI.
_G.SBAS_LoadImportTextIntoOverrideGUI = function(specID, displayName, payload)
    if type(payload) ~= "string" or payload:match("^%s*$") then
        return false, "import payload is empty"
    end

    OpenGUI(specID, displayName)

    local imported, err = DeserializeRulesFromExport(payload, editSpecID)
    if not imported then
        return false, err or "invalid import payload"
    end

    workingRules = DeepCopyRules(imported)
    sessionRules[editSpecID] = workingRules
    selectedIdx = (#workingRules > 0) and 1 or 0
    selectedCondIdx = nil
    isAddingCond = false

    RefreshRuleList()
    RefreshRightPanel()

    return true
end

-- Public: normalize an import text string through the same deserialize→re-serialize pipeline
-- used by Save & Apply. Callers can store this normalized form as a baseline and compare it
-- directly against the savedExport passed to SBAS_OnGuiSaveAndApply.
_G.SBAS_NormalizeImportText = function(importText, specID)
    if type(importText) ~= "string" or importText:match("^%s*$") then
        return nil, "empty import text"
    end
    local rules, err = DeserializeRulesFromExport(importText, specID)
    if not rules then return nil, err or "parse error" end
    return SerializeRulesForExportV2(specID, rules)
end

-- Public: open GUI for a spec and replace current working rules with a provided table.
-- Used by submenu "Recommended" buttons to preload curated priority lists.
_G.SBAS_LoadRulesIntoOverrideGUI = function(specID, displayName, rules)
    if type(rules) ~= "table" then
        return false, "rules must be a table"
    end

    OpenGUI(specID, displayName)

    workingRules = DeepCopyRules(rules)
    sessionRules[editSpecID] = workingRules
    selectedIdx = (#workingRules > 0) and 1 or 0
    selectedCondIdx = nil
    isAddingCond = false

    RefreshRuleList()
    RefreshRightPanel()

    return true
end

-- Expose condition-summary renderer for the Priority Analyzer.
-- Returns a human-readable short string for one condition.
_G.SBAS_CondSummaryText    = CondSummaryText

-- Builds the full decorated display token for one condition, matching the right
-- panel's exact format: [AND/OR] [(s] [NOT] label [)s]
-- parenDepth: running parenthesis depth coming INTO this condition (updated in-place
-- via the returned second value).  Pass 0 for the first call.
-- isFirst: pass true for condition index 1 (suppresses the junction prefix).
_G.SBAS_BuildCondRowText = function(cond, ruleSpellID, isFirst, parenDepthIn)
    local depth = parenDepthIn or 0
    local def   = COND_BY_ID[cond.type]
    if not def then
        return ("[" .. (cond.type or "?") .. "]"), depth
    end

    -- Junction prefix
    local junction = ""
    if not isFirst then
        local j = cond.junction or "and"
        junction = "|cff8899cc" .. j:upper() .. "|r "
    end

    -- Parentheses
    local lp = ""
    local rp = ""
    local depthBefore = depth
    for k = 1, (cond.lparen or 0) do
        local d = depthBefore + k
        lp = lp .. ParenColorCode(d) .. "(" .. "|r"
    end
    depth = depth + (cond.lparen or 0)
    for k = 1, (cond.rparen or 0) do
        local d = depth - (k - 1)
        rp = rp .. ParenColorCode(d) .. ")" .. "|r"
    end
    depth = depth - (cond.rparen or 0)

    -- Label — mirrors the UpdateRowFrame token-building logic exactly
    local label = def.shortLabel or def.label
    if def.needsSpell then
        if cond.type == "sba_suggests" then
            local op = "="
            if not cond.spell or cond.spell == "this" then
                label = "SBA " .. op .. " [this]"
            else
                local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                local sInfo = sid and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                local sIcon = sInfo and sInfo.iconID
                if sIcon then
                    label = "SBA " .. op .. " |T" .. sIcon .. ":14:14|t"
                else
                    label = "SBA " .. op .. " [" .. tostring(sid or "?") .. "]"
                end
            end
        elseif not cond.spell or cond.spell == "this" then
            local rInfo = ruleSpellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(ruleSpellID)
            local rIcon = rInfo and rInfo.iconID
            if rIcon then
                label = label .. " |T" .. rIcon .. ":14:14|t"
            end
        else
            local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
            local sInfo = sid and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
            local sIcon = sInfo and sInfo.iconID
            if sIcon then
                label = label .. " |T" .. sIcon .. ":14:14|t"
            elseif sid then
                label = label .. " [" .. tostring(sid) .. "]"
            end
        end
    elseif def.needsPlugin then
        label = BuildPluginSummary(cond)
    elseif def.needsLua then
        local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
        if expr == "" then expr = "(empty)" end
        if #expr > 30 then expr = expr:sub(1, 27) .. "..." end
        label = "Lua: " .. expr
    elseif def.needsResource then
        local res = cond.resource or "chi"
        local op  = cond.operator or ">="
        local val = tostring(cond.value or 0)
        label = res .. " " .. op .. " " .. val
    elseif def.needsCompareValue then
        local op  = cond.operator or ">="
        local val = tostring(cond.value or 0)
        label = (def.shortLabel or def.label) .. " " .. op .. " " .. val
    end

    local labelText = cond.negate and ("|cffff4444NOT " .. label .. "|r") or label
    return junction .. lp .. labelText .. rp, depth
end

-------------------------------------------------------------------------------
-- 14. Hook the existing slash command to add "override_gui"
--     This file loads after SBA_Simple.lua, so we wrap the existing handler.
--     OpenGUI is local to this file, so no global indirection is needed.
-------------------------------------------------------------------------------
local _origSBAS = SlashCmdList["SBASIMPLE"]
SlashCmdList["SBASIMPLE"] = function(msg)
    local cmd = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "override_gui" then
        OpenGUI()
    else
        if _origSBAS then _origSBAS(msg) end
    end
end
