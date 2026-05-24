-- SBA_Simple_OverrideGUI_Core_Codegen.lua
-- Shared override code generator.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.GenerateCode(rules)
    if not rules or #rules == 0 then return nil end
    local L = {}

    local editSpecID = M.GetEditSpecID and M.GetEditSpecID() or 0
    local sec = M.SPEC_SECONDARY[editSpecID]

    if sec and not sec.inlineExpr then
        L[#L + 1] = ('local %s = UnitPower("player", Enum.PowerType.%s)'):format(sec.varName, sec.powerType)
    end
    L[#L + 1] = ""

    local allRuleParts = {}
    for i, rule in ipairs(rules) do
        if (rule.spellID or 0) > 0 then
            local parts, junctions = {}, {}
            for _, cond in ipairs(rule.conditions or {}) do
                local def = M.COND_BY_ID[cond.type]
                if def then
                    local frag = def.generate(cond, rule.spellID, rule)
                    if cond.negate then frag = "not (" .. frag .. ")" end
                    local lp = (cond.lparen or 0) > 0 and string.rep("(", cond.lparen) or ""
                    local rp = (cond.rparen or 0) > 0 and string.rep(")", cond.rparen) or ""
                    local idx = #parts + 1
                    parts[idx] = lp .. frag .. rp
                    if idx > 1 then
                        local j = cond.junction
                        junctions[idx] = (j == "and" or j == "or") and j or "and"
                    end
                end
            end
            allRuleParts[i] = { parts = parts, junctions = junctions }
        else
            allRuleParts[i] = false
        end
    end

    local cdTotalCount, cdFirstSeenOrder, cdSeen = {}, {}, {}
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for _, part in ipairs(rp.parts) do
                for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                    cdTotalCount[id] = (cdTotalCount[id] or 0) + 1
                    if not cdSeen[id] then cdSeen[id] = true; cdFirstSeenOrder[#cdFirstSeenOrder + 1] = id end
                end
            end
        end
    end

    local hoisted = {}
    for _, id in ipairs(cdFirstSeenOrder) do
        if (cdTotalCount[id] or 0) > 1 then
            local varName = "cd_" .. id
            L[#L + 1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
            hoisted[id] = varName
        end
    end
    if next(hoisted) then L[#L + 1] = "" end

    for _, rp in ipairs(allRuleParts) do
        if rp then
            for id, varName in pairs(hoisted) do
                local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                for pi, part in ipairs(rp.parts) do rp.parts[pi] = part:gsub(pattern, varName) end
            end
        end
    end

    local sbaPattern = "C_AssistedCombat%.GetNextCastSpell%(%)"
    local sbaFound = false
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for _, part in ipairs(rp.parts) do if part:find(sbaPattern) then sbaFound = true; break end end
        end
        if sbaFound then break end
    end
    if sbaFound then
        L[#L + 1] = "local sba_next = C_AssistedCombat.GetNextCastSpell()"
        L[#L + 1] = ""
        for _, rp in ipairs(allRuleParts) do
            if rp then
                for pi, part in ipairs(rp.parts) do rp.parts[pi] = part:gsub(sbaPattern, "sba_next") end
            end
        end
    end

    local hasUnconditional = false
    for i, rule in ipairs(rules) do
        local rp = allRuleParts[i]
        if rp then
            local parts, junctions = rp.parts, rp.junctions

            if #parts > 1 then
                local cdCount = {}
                for _, part in ipairs(parts) do
                    for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                        if not hoisted[id] then cdCount[id] = (cdCount[id] or 0) + 1 end
                    end
                end
                for id, count in pairs(cdCount) do
                    if count > 1 then
                        local varName = "cd_" .. id
                        L[#L + 1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
                        local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                        for pi, part in ipairs(parts) do parts[pi] = part:gsub(pattern, varName) end
                        hoisted[id] = varName
                    end
                end
            end

            L[#L + 1] = ("-- Priority %d: %s (%d)"):format(i, rule.name or "?", rule.spellID)
            if #parts > 0 then
                local expr = parts[1]
                for pi = 2, #parts do expr = expr .. " " .. (junctions[pi] or "and") .. " " .. parts[pi] end
                if rule.spellID == M.SBA_BUTTON_SPELL_ID then
                    L[#L + 1] = ("if %s then return C_AssistedCombat.GetNextCastSpell(), %d end"):format(expr, i)
                else
                    L[#L + 1] = ("if %s then return %d, %d end"):format(expr, rule.spellID, i)
                end
            else
                if rule.spellID == M.SBA_BUTTON_SPELL_ID then
                    L[#L + 1] = ("return C_AssistedCombat.GetNextCastSpell(), %d  -- unconditional"):format(i)
                else
                    L[#L + 1] = ("return %d, %d  -- unconditional"):format(rule.spellID, i)
                end
                hasUnconditional = true
            end
            L[#L + 1] = ""
            if hasUnconditional then break end
        end
    end

    if not hasUnconditional then L[#L + 1] = "return nil" end
    return table.concat(L, "\n")
end
