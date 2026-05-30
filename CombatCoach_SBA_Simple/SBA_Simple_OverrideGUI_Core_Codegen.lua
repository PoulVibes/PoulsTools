-- SBA_Simple_OverrideGUI_Core_Codegen.lua
-- Shared override code generator.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

-- API call patterns to cache; each entry: Lua capture pattern, call format string, var-name factory.
local API_PATS = {
    { pat = "C_Spell%.GetSpellCooldown%((%d+)%)", fmt = "C_Spell.GetSpellCooldown(%s)", fn = function(id) return "cd_"..id end },
    { pat = "C_Spell%.GetSpellCharges%((%d+)%)",  fmt = "C_Spell.GetSpellCharges(%s)",  fn = function(id) return "charges_"..id end },
    { pat = "C_Spell%.IsSpellUsable%((%d+)%)",    fmt = "C_Spell.IsSpellUsable(%s)",    fn = function(id) return "usable_"..id end },
}
local SBANEXT_CALL = "C_AssistedCombat.GetNextCastSpell()"
local SBANEXT_LPAT = "C_AssistedCombat" .. "%." .. "GetNextCastSpell" .. "%(%" .. ")"

-- Scan s; register any first-seen API calls into cache and append to newList.
local function scanStr(s, cache, newList)
    for _, p in ipairs(API_PATS) do
        for arg in s:gmatch(p.pat) do
            local callStr = p.fmt:format(arg)
            if not cache[callStr] then
                local var = p.fn(arg)
                cache[callStr] = var
                newList[#newList+1] = { var = var, call = callStr }
            end
        end
    end
    if s:find(SBANEXT_LPAT) and not cache[SBANEXT_CALL] then
        cache[SBANEXT_CALL] = "sba_next"
        newList[#newList+1] = { var = "sba_next", call = SBANEXT_CALL }
    end
end

-- Replace all cached call strings in s with their local var names.
local function applyCache(s, cache)
    for callStr, var in pairs(cache) do
        s = s:gsub(callStr:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), var)
    end
    return s
end

function M.GenerateCode(rules)
    if not rules or #rules == 0 then return nil end
    local L = {}
    local editSpecID = M.GetEditSpecID and M.GetEditSpecID() or 0
    local sec = M.SPEC_SECONDARY[editSpecID]
    if sec and not sec.inlineExpr then
        L[#L+1] = ('local %s = UnitPower("player", Enum.PowerType.%s)'):format(sec.varName, sec.powerType)
    end
    L[#L+1] = ""

    local cache = {}
    local hasUnconditional = false

    for i, rule in ipairs(rules) do
        if (rule.spellID or 0) > 0 then
            -- Build raw condition fragments.
            local parts, junctions = {}, {}
            for _, cond in ipairs(rule.conditions or {}) do
                local def = M.COND_BY_ID[cond.type]
                if def then
                    local frag = def.generate(cond, rule.spellID, rule)
                    if cond.negate then frag = "not (" .. frag .. ")" end
                    local idx = #parts + 1
                    parts[idx] = string.rep("(", cond.lparen or 0) .. frag .. string.rep(")", cond.rparen or 0)
                    if idx > 1 then
                        local j = cond.junction
                        junctions[idx] = (j == "and" or j == "or") and j or "and"
                    end
                end
            end

            local isSBA = (rule.spellID == M.SBA_BUTTON_SPELL_ID)

            -- Discover first-seen API calls across all fragments (and the SBA return expr).
            local newList = {}
            for _, p in ipairs(parts) do scanStr(p, cache, newList) end
            if isSBA then scanStr(SBANEXT_CALL, cache, newList) end

            -- Emit local declarations for newly-seen calls just before this rule.
            for _, e in ipairs(newList) do
                L[#L+1] = ("local %s = %s"):format(e.var, e.call)
            end
            if #newList > 0 then L[#L+1] = "" end

            -- Substitute all known cached vars into fragments.
            for pi = 1, #parts do parts[pi] = applyCache(parts[pi], cache) end

            local sbaRet = isSBA and (cache[SBANEXT_CALL] or SBANEXT_CALL) or nil

            L[#L+1] = ("-- Priority %d: %s (%d)"):format(i, rule.name or "?", rule.spellID)
            if #parts > 0 then
                local expr = parts[1]
                for pi = 2, #parts do expr = expr .. " " .. (junctions[pi] or "and") .. " " .. parts[pi] end
                if isSBA then
                    L[#L+1] = ("if %s then return %s, %d end"):format(expr, sbaRet, i)
                else
                    L[#L+1] = ("if %s then return %d, %d end"):format(expr, rule.spellID, i)
                end
            else
                if isSBA then
                    L[#L+1] = ("return %s, %d  -- unconditional"):format(sbaRet, i)
                else
                    L[#L+1] = ("return %d, %d  -- unconditional"):format(rule.spellID, i)
                end
                hasUnconditional = true
            end
            L[#L+1] = ""
            if hasUnconditional then break end
        end
    end

    if not hasUnconditional then L[#L+1] = "return nil" end
    return table.concat(L, "\n")
end
