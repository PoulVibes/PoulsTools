-- SBA_Simple_OverrideGUI_Core_CondSummary.lua
-- Shared human-readable condition summary rendering.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CondSummaryText(cond, ruleSpellID, specIDOverride)
    local def = M.COND_BY_ID[cond.type]
    if not def then return "[obsolete: " .. (cond.type or "?") .. "]" end

    local prefix = cond.negate and "NOT " or ""
    local text

    if def.needsResource then
        local sid = (specIDOverride and specIDOverride > 0) and specIDOverride or (M.GetEditSpecID and M.GetEditSpecID() or 0)
        local resName = (cond.resource == "energy") and "Energy"
            or (M.SPEC_SECONDARY[sid] or M.SPEC_SECONDARY_DEFAULT).label
        text = resName .. " " .. (cond.operator or ">=") .. " " .. tostring(cond.value or 0)
    elseif def.needsCompareValue then
        text = (def.shortLabel or def.label) .. " " .. (cond.operator or ">=") .. " " .. tostring(cond.value or 0)
    elseif def.needsLua then
        local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
        if expr == "" then expr = "(empty)" end
        if #expr > 52 then expr = expr:sub(1, 49) .. "..." end
        text = "Lua: " .. expr
    elseif def.needsPlugin then
        text = M.BuildPluginSummary(cond)
    else
        if def.needsSpell then
            if cond.type == "sba_suggests" then
                if not cond.spell or cond.spell == "this" then
                    text = "SBA = [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or tostring(id)
                    text = "SBA = [" .. (n or "?") .. "]"
                end
            else
                text = def.label
                if not cond.spell or cond.spell == "this" then
                    text = text .. " [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or tostring(id)
                    text = text .. " [" .. (n or "?") .. "]"
                end
            end
        else
            text = def.label
        end
        if cond.value then text = text .. " " .. tostring(cond.value) end
    end

    return prefix .. text
end
