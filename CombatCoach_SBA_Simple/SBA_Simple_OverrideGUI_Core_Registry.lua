-- SBA_Simple_OverrideGUI_Core_Registry.lua
-- Shared condition registry and condition-type visibility lists.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.COND_TYPES = {
    { id = "on_cd", label = "Ready (Off-Cooldown)", shortLabel = "Ready", needsSpell = true,
      generate = function(c, s, rule)
          if (not c.spell or c.spell == "this") and rule and rule.itemID then
              return ("(select(2, C_Item.GetItemCooldown(%d)) == 0)"):format(rule.itemID)
          end
          local id = M.ResolveSpell(c, s)
          return ("(not C_Spell.GetSpellCooldown(%d).isActive or C_Spell.GetSpellCooldown(%d).isOnGCD)"):format(id, id)
      end },
    { id = "reactive_enabled", label = "Reactive Spell Enabled", shortLabel = "Enabled", needsSpell = true,
      generate = function(c, s) return ("C_Spell.GetSpellCooldown(%d).isEnabled"):format(M.ResolveSpell(c, s)) end },
    { id = "usable", label = "Is Usable", shortLabel = "Usable", needsSpell = true,
      generate = function(c, s) return ("C_Spell.IsSpellUsable(%d)"):format(M.ResolveSpell(c, s)) end },
    { id = "talented", label = "Talented", needsSpell = true,
      generate = function(c, s) return ("IsPlayerSpell(%d)"):format(M.ResolveSpell(c, s)) end },
    { id = "sba_suggests", label = "SBA Suggests", needsSpell = true,
      generate = function(c, s)
          local id = (not c.spell or c.spell == "this") and s or (type(c.spell) == "number" and c.spell or c.targetID or s)
          return ("C_AssistedCombat.GetNextCastSpell() == %d"):format(id)
      end },
    { id = "resource", label = "Resource Check", needsResource = true,
      generate = function(c)
          local sec = M.SPEC_SECONDARY[M.GetEditSpecID()] or M.SPEC_SECONDARY_DEFAULT
          local var = (c.resource == "energy") and "(_G.currentEnergy or 0)" or sec.inlineExpr or sec.varName
          return ("%s %s %d"):format(var, c.operator or ">=", c.value or 0)
      end },
    { id = "target_count", label = "Target Count", shortLabel = "Targets", needsCompareValue = true, valueLabel = "Count", default = 1,
      generate = function(c)
          return ("(_G.ECT_TargetCount or 0) %s %d"):format(c.operator or ">=", c.value or 0)
      end },
    { id = "custom_lua", label = "Custom Lua Expression", needsLua = true,
      generate = function(c)
          local expr = (c.luaCode and c.luaCode:match("^%s*(.-)%s*$")) or ""
          if expr == "" then return "false" end
          return "(" .. expr .. ")"
      end },
    { id = "plugin", label = "Plugin / Proc", needsPlugin = true,
      generate = function(c, s)
          return M.BuildPluginConditionExpr(c, s)
      end },
    { id = "last_combo_eq", label = "Last Combo Strike = Spell", shortLabel = "Combo", needsSpell = true,
      generate = function(c, s) return ("LastComboStrikeSpellID == %d"):format(M.ResolveSpell(c, s)) end },
    { id = "last_ability_eq", label = "Last Ability Used = Spell", shortLabel = "LastAbility", needsSpell = true,
      generate = function(c, s) return ("LastAbilityUsedSpellID == %d"):format(M.ResolveSpell(c, s)) end },
    { id = "has_pet", label = "Pet Summoned", shortLabel = "Has Pet",
      generate = function() return 'UnitExists("pet")' end },
    { id = "pet_alive", label = "Pet Alive", shortLabel = "Pet Alive",
      generate = function() return 'not UnitIsDead("pet")' end },
    { id = "has_stacks", label = "Has Stacks", shortLabel = "Stacks", needsSpell = true, needsStacksValue = true,
      generate = function(c, s)
          local id = M.ResolveSpell(c, s)
          local v = c.value
          if v == "max" then
              return ("(C_Spell.GetSpellCharges(%d) ~= nil and not C_Spell.GetSpellCharges(%d).isActive)"):format(id, id)
          elseif v == "1" or v == 1 then
              return ("(C_Spell.GetSpellCharges(%d) ~= nil and C_Spell.GetSpellCharges(%d).isActive and (not C_Spell.GetSpellCooldown(%d).isActive or C_Spell.GetSpellCooldown(%d).isOnGCD))"):format(id, id, id, id)
          elseif v == ">1" then
              return ("((C_Spell.GetSpellCooldown(%d) ~= nil and not C_Spell.GetSpellCooldown(%d).isActive) or C_Spell.GetSpellCooldown(%d).isOnGCD) or (C_Spell.GetSpellCharges(%d) ~= nil and not C_Spell.GetSpellCharges(%d).isActive)"):format(id, id, id, id, id)
          else
              return ("(C_Spell.GetSpellCooldown(%d) ~= nil and C_Spell.GetSpellCooldown(%d).isActive and not C_Spell.GetSpellCooldown(%d).isOnGCD)"):format(id, id, id)
          end
      end },
}

M.COND_BY_ID = {}
for _, ct in ipairs(M.COND_TYPES) do
    M.COND_BY_ID[ct.id] = ct
end

function M.GetVisibleCondTypes()
    local out = {}
    for _, ct in ipairs(M.COND_TYPES) do
        if ct.id ~= "last_combo_eq" then
            if M.SupportsPluginGUI() then
                out[#out + 1] = ct
            elseif ct.id ~= "plugin" then
                out[#out + 1] = ct
            end
        end
    end
    return out
end
