-- SBA_Simple_OverrideGUI_Core_DB.lua
-- Shared DB/tab helpers for the override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.MAX_TABS_LIMIT = M.MAX_TABS_LIMIT or 5
M.SBA_BUTTON_SPELL_ID = M.SBA_BUTTON_SPELL_ID or 1229376

function M.GuiDB()
    SBA_SimpleDB = SBA_SimpleDB or {}
    SBA_SimpleDB.gui = SBA_SimpleDB.gui or {}
    return SBA_SimpleDB.gui
end

function M.GetBlizzardSBADefaultRules()
    return {
        {
            spellID = M.SBA_BUTTON_SPELL_ID,
            name = "Single-Button Assistant",
            conditions = {},
        }
    }
end

function M.GetGuiRules(specID)
    local db = M.GuiDB()
    if not db[specID] or #db[specID] == 0 then
        db[specID] = M.GetBlizzardSBADefaultRules()
    end
    return db[specID]
end

function M.GetTabName(specID, tabIdx)
    if tabIdx == 1 then return "Rotation" end
    SBA_SimpleDB.tabNames = SBA_SimpleDB.tabNames or {}
    SBA_SimpleDB.tabNames[specID] = SBA_SimpleDB.tabNames[specID] or {}
    return SBA_SimpleDB.tabNames[specID][tabIdx] or ("Tab " .. tabIdx)
end

function M.SetTabName(specID, tabIdx, name)
    if tabIdx == 1 then return end
    SBA_SimpleDB.tabNames = SBA_SimpleDB.tabNames or {}
    SBA_SimpleDB.tabNames[specID] = SBA_SimpleDB.tabNames[specID] or {}
    SBA_SimpleDB.tabNames[specID][tabIdx] = name or ("Tab " .. tabIdx)
end

function M.GetTabCount(specID)
    SBA_SimpleDB.tabCount = SBA_SimpleDB.tabCount or {}
    return math.max(1, tonumber(SBA_SimpleDB.tabCount[specID]) or 1)
end

function M.SetTabCount(specID, count)
    SBA_SimpleDB.tabCount = SBA_SimpleDB.tabCount or {}
    SBA_SimpleDB.tabCount[specID] = math.max(1, math.min(M.MAX_TABS_LIMIT, tonumber(count) or 1))
end

function M.GetGuiTabRules(specID, tabIdx)
    if tabIdx == 1 then return M.GetGuiRules(specID) end
    SBA_SimpleDB.guiTabs = SBA_SimpleDB.guiTabs or {}
    SBA_SimpleDB.guiTabs[specID] = SBA_SimpleDB.guiTabs[specID] or {}
    SBA_SimpleDB.guiTabs[specID][tabIdx] = SBA_SimpleDB.guiTabs[specID][tabIdx] or {}
    return SBA_SimpleDB.guiTabs[specID][tabIdx]
end

function M.SetGuiTabRules(specID, tabIdx, rules)
    if tabIdx == 1 then
        M.GuiDB()[specID] = rules
        return
    end
    SBA_SimpleDB.guiTabs = SBA_SimpleDB.guiTabs or {}
    SBA_SimpleDB.guiTabs[specID] = SBA_SimpleDB.guiTabs[specID] or {}
    SBA_SimpleDB.guiTabs[specID][tabIdx] = rules
end

function M.DeepCopyRules(src)
    local out = {}
    for i, r in ipairs(src) do
        local conds = {}
        for j, c in ipairs(r.conditions or {}) do
            conds[j] = {
                type = c.type,
                value = c.value,
                luaCode = c.luaCode,
                negate = c.negate,
                spell = c.spell,
                targetID = c.targetID,
                resource = c.resource,
                operator = c.operator,
                plugin = c.plugin,
                junction = c.junction,
                lparen = c.lparen,
                rparen = c.rparen,
            }
        end
        out[i] = { spellID = r.spellID, name = r.name, conditions = conds, itemID = r.itemID }
    end
    return out
end
