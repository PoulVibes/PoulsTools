-- SBA_Simple_OverrideGUI_Core_Plugins.lua
-- Shared plugin metadata, summaries, and condition expression builders.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M.PROC_PLUGIN_BY_ID = M.PROC_PLUGIN_BY_ID or {
    withering_fire = { label = "Withering Fire", activeFlag = "WitheringFireActiveTracker", timerVar = "WitheringFireRemaining" },
    bestial_wrath_cooldown = { label = "Bestial Wrath Cooldown", activeFlag = "BestialWrathCooldownActiveTracker", timerVar = "BestialWrathCooldownRemaining" },
    barbed_shot_debuff = { label = "Barbed Shot Debuff", activeFlag = "BarbedShotDebuffActiveTracker", timerVar = "BarbedShotDebuffRemaining" },
    natures_ally = { label = "Nature's Ally", activeFlag = "NaturesAllyActiveTracker" },
    beast_cleave = { label = "Beast Cleave", activeFlag = "BeastCleaveActiveTracker", timerVar = "BeastCleaveRemaining" },
    vivify_proc = { label = "Vivify Proc", activeFlag = "VivifyProcActiveTracker", timerVar = "VivifyProcRemaining" },
    hojs = { label = "Heart of the Jade Serpent", activeFlag = "HojsActiveTracker", timerVar = "HojsRemaining" },
    tots_stacks = { label = "Tip of the Spear Stacks", timerVar = "TipOfTheSpearStacks" },
    tots_timer = { label = "Tip of the Spear Timer", activeFlag = "TipOfTheSpearTimerActive", timerVar = "TipOfTheSpearRemaining" },
    takedown_buff = { label = "Takedown Buff", activeFlag = "TakedownBuffActive", timerVar = "TakedownBuffRemaining" },
    raptor_swipe_override = { label = "Raptor Swipe Override", activeFlag = "RaptorSwipeOverrideActive" },
}

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
        return _G.SBAS_DynBuffRegistry[pluginID]
    end
    if _G.SBAS_DynActivationRegistry and _G.SBAS_DynActivationRegistry[pluginID] then
        return _G.SBAS_DynActivationRegistry[pluginID]
    end
    return nil
end

function M.BuildPluginConditionExpr(cond, ruleSpellID)
    local plugin, op, value = M.NormalizePluginState(cond)
    if plugin == "zenith" then return "ZenithActiveTracker" end
    if plugin == "bestial_wrath_active" then return "BestialWrathActiveTracker" end
    if plugin == "withering_fire_active" then return "WitheringFireActiveTracker" end
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

    local meta = M.PROC_PLUGIN_BY_ID[plugin]
    if not meta then return "false" end
    if M.IsCompOp(op) then
        if plugin == "withering_fire" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 10) end
        if plugin == "bestial_wrath_cooldown" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 90) end
        if plugin == "barbed_shot_debuff" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 12) end
        if plugin == "beast_cleave" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 8) end
        if plugin == "tots_timer" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 5) end
        if plugin == "takedown_buff" then return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 5) end
        return ("(tonumber(%s) or 0) %s %d"):format(meta.timerVar, op, value or 4)
    end

    if plugin == "tots_stacks" then
        return ("(tonumber(%s) or 0) > 0"):format(meta.timerVar)
    end
    if plugin == "tots_timer" then
        return ("(%s == true)"):format(meta.activeFlag)
    end
    return ("(%s == true)"):format(meta.activeFlag)
end

function M.BuildPluginSummary(cond)
    local plugin, op, value = M.NormalizePluginState(cond)
    if plugin == "zenith" then return "Zenith" end
    if plugin == "bestial_wrath_active" then return "Bestial Wrath Active" end
    if plugin == "withering_fire_active" then return "Withering Fire Active" end
    if plugin == "last_combo_eq" then return "Combo" end

    local reg = GetDynamicPluginRegistry(plugin)
    if reg then
        if M.IsCompOp(op) and reg.timerVar then
            return reg.label .. " " .. op .. " " .. tostring(value or "")
        end
        return reg.label .. " Active"
    end

    local meta = M.PROC_PLUGIN_BY_ID[plugin]
    if not meta then return plugin or "?" end
    if M.IsCompOp(op) then
        return meta.label .. " " .. op .. " " .. tostring(value or 4)
    end
    return meta.label .. " Active"
end
