-- SBA_Simple_OverrideGUI_Core_CondRowText.lua
-- Public condition-row text rendering helper.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.BuildCondRowText(cond, ruleSpellID, isFirst, parenDepthIn, deps)
    local depth = parenDepthIn or 0
    local def = deps.condById[cond.type]
    if not def then
        return ("[" .. (cond.type or "?") .. "]"), depth
    end

    local junction = ""
    if not isFirst then
        local j = cond.junction or "and"
        junction = "|cff8899cc" .. j:upper() .. "|r "
    end

    local lp, rp = "", ""
    local depthBefore = depth
    for k = 1, (cond.lparen or 0) do
        local d = depthBefore + k
        lp = lp .. deps.parenColorCode(d) .. "(" .. "|r"
    end
    depth = depth + (cond.lparen or 0)
    for k = 1, (cond.rparen or 0) do
        local d = depth - (k - 1)
        rp = rp .. deps.parenColorCode(d) .. ")" .. "|r"
    end
    depth = depth - (cond.rparen or 0)

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
            if rIcon then label = label .. " |T" .. rIcon .. ":14:14|t" end
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
        label = deps.buildPluginSummary(cond)
    elseif def.needsLua then
        local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
        if expr == "" then expr = "(empty)" end
        if #expr > 30 then expr = expr:sub(1, 27) .. "..." end
        label = "Lua: " .. expr
    elseif def.needsResource then
        local op = cond.operator or ">="
        local val = tostring(cond.value or 0)
        local sec = deps.specSecondary[deps.getEditSpecID()] or deps.specSecondaryDefault
        local resName = (cond.resource == "energy") and "Energy" or sec.label
        label = resName .. " " .. op .. " " .. val
    elseif def.needsCompareValue then
        local op = cond.operator or ">="
        local val = tostring(cond.value or 0)
        label = (def.shortLabel or def.label) .. " " .. op .. " " .. val
    end

    if def.needsStacksValue then
        local v = cond.value
        local vStr = (v == "max") and "Max" or tostring(v or "?")
        label = vStr .. " " .. label
    end

    local labelText = cond.negate and ("|cffff4444NOT " .. label .. "|r") or label
    return junction .. lp .. labelText .. rp, depth
end
