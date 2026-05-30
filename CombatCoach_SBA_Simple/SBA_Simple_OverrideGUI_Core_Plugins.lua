-- SBA_Simple_OverrideGUI_Core_Plugins.lua
-- Shared plugin metadata, summaries, and condition expression builders.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.VALID_COMP_OPS = M.VALID_COMP_OPS or {
    [">="] = true,
    ["<="] = true,
    ["=="] = true,
    [">"] = true,
    ["<"] = true,
}

function M.IsCompOp(op)
    return op and M.VALID_COMP_OPS[op] or false
end

function M.NormalizePluginState(cond)
    local plugin = cond and cond.plugin or nil
    local op = cond and cond.operator or nil
    local value = cond and cond.value or nil

    return plugin, op, value
end

local function GetDynamicPluginRegistry(pluginID)
    if _G.SBAS_DynBuffRegistry and _G.SBAS_DynBuffRegistry[pluginID] then
        return _G.SBAS_DynBuffRegistry[pluginID], "DBT"
    end
    if _G.SBAS_DynActivationRegistry and _G.SBAS_DynActivationRegistry[pluginID] then
        return _G.SBAS_DynActivationRegistry[pluginID], "DAT"
    end
    return nil, nil
end

local function GetTriggerTrackerEntry(pluginID)
    if _G.SBAS_TriggerTrackerRegistry then
        return _G.SBAS_TriggerTrackerRegistry[pluginID]
    end
    return nil
end

function M.BuildPluginConditionExpr(cond, ruleSpellID)
    local plugin, op, value = M.NormalizePluginState(cond)
    if plugin == "last_combo_eq" then
        return ("LastComboStrikeSpellID == %d"):format(ruleSpellID or 0)
    end

    local reg = GetDynamicPluginRegistry(plugin)
    if reg then
        if M.IsCompOp(op) and reg.timerVar then
            return ("(tonumber(%s) or 0) %s %d"):format(reg.timerVar, op, value or 0)
        end
        return ("(%s == true)"):format(reg.activeFlag)
    end

    local ttreg = GetTriggerTrackerEntry(plugin)
    if ttreg then
        if M.IsCompOp(op) then
            if ttreg.hasTimer then
                return ("TriggerTracker_GetTimerRemaining(%q) %s %d"):format(ttreg.key, op, value or 0)
            else
                return ("TriggerTracker_GetActiveStacks(%q) %s %d"):format(ttreg.key, op, value or 0)
            end
        end
        if ttreg.hasTimer then
            return ("TriggerTracker_GetTimerRemaining(%q) > 0"):format(ttreg.key)
        end
        return ("TriggerTracker_GetActiveStacks(%q) > 0"):format(ttreg.key)
    end

    return "false"
end

function M.BuildPluginSummary(cond)
    local plugin, op, value = M.NormalizePluginState(cond)
    if plugin == "last_combo_eq" then return "Combo" end

    local reg, src = GetDynamicPluginRegistry(plugin)
    if reg then
        if M.IsCompOp(op) and reg.timerVar then
            return reg.label .. " " .. op .. " " .. tostring(value or "")
        end
        return reg.label .. " Active"
    end

    local ttreg = GetTriggerTrackerEntry(plugin)
    if ttreg then
        if M.IsCompOp(op) then
            return ttreg.label .. " " .. op .. " " .. tostring(value or 0)
        end
        return ttreg.label .. " Active"
    end

    return plugin or "?"
end
