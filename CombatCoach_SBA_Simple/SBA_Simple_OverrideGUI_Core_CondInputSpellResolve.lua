-- SBA_Simple_OverrideGUI_Core_CondInputSpellResolve.lua
-- Spell resolution helpers for condition input editor.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.ResolveCondInputOtherSpell(input, deps)
    local raw = tostring(input or "")
    local text = raw:match("^%s*(.-)%s*$")
    if text == "" then
        return nil, nil, nil, ""
    end

    local id
    local numericID = tonumber(text)
    if numericID then
        id = numericID
    elseif C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        id = C_Spell.GetSpellIDForSpellIdentifier(text)
    end

    if not (id and id > 0) and deps and deps.searchSpellBookByName then
        id = deps.searchSpellBookByName(text)
    end

    if not (id and id > 0) and deps and deps.searchTalentTreeByName then
        id = deps.searchTalentTreeByName(text)
    end

    if id and id > 0 then
        local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
        local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
        return id, (n or text), tex, nil
    end

    return nil, nil, nil, "|cffff5555Not found|r"
end
