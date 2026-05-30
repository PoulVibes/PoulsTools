-- SBA_Simple_OverrideGUI_Core_Conditions.lua
-- Shared condition metadata and visibility helpers for the override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M._getEditSpecID = M._getEditSpecID or function()
    return 0
end

function M.SetEditSpecIDAccessor(fn)
    if type(fn) == "function" then
        M._getEditSpecID = fn
    end
end

function M.GetEditSpecID()
    return tonumber(M._getEditSpecID and M._getEditSpecID() or 0) or 0
end

function M.ResolveSpell(c, s)
    if not c.spell or c.spell == "this" then return s end
    if type(c.spell) == "number" then return c.spell end
    return c.targetID or s
end

M.SPEC_SECONDARY_DEFAULT = M.SPEC_SECONDARY_DEFAULT or { varName = "chi", powerType = "Chi", label = "Chi" }
M.SPEC_SECONDARY = M.SPEC_SECONDARY or {
    [269] = { varName = "chi",         powerType = "Chi",         label = "Chi" },
    [259] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts" },
    [260] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts" },
    [261] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts" },
    [103] = { varName = "comboPoints", powerType = "ComboPoints", label = "Combo Pts" },
    [250] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr" },
    [251] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr" },
    [252] = { varName = "runicPower",  powerType = "RunicPower",  label = "Runic Pwr" },
    [65]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr" },
    [66]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr" },
    [70]  = { varName = "holyPower",   powerType = "HolyPower",   label = "Holy Pwr" },
    [265] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" },
    [266] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" },
    [267] = { varName = "soulShards",  powerType = "SoulShards",  label = "Soul Shards" },
    [258] = { varName = "insanity",    powerType = "Insanity",    label = "Insanity" },
    [253] = { varName = "currentFocus", inlineExpr = "(_G.currentFocus or 0)", label = "Focus" },
}

M.PLUGIN_OPTS_WW = M.PLUGIN_OPTS_WW or {
    { id = "zenith", label = "Zenith" },
    { id = "last_combo_eq", label = "Combo" },
    { id = "vivify_proc", label = "Vivify Proc", supportsProcMode = true, default = 20 },
    { id = "hojs", label = "Heart of the Jade Serpent", supportsProcMode = true, default = 4 },
}

M.PLUGIN_OPTS_BM = M.PLUGIN_OPTS_BM or {
    { id = "bestial_wrath_active", label = "Bestial Wrath Active" },
    { id = "bestial_wrath_cooldown", label = "Bestial Wrath Cooldown", supportsProcMode = true, default = 90 },
    { id = "barbed_shot_debuff", label = "Barbed Shot Debuff", supportsProcMode = true, default = 12 },
    { id = "withering_fire_active", label = "Withering Fire Active" },
    { id = "withering_fire", label = "Withering Fire", supportsProcMode = true, default = 10 },
    { id = "natures_ally", label = "Nature's Ally Active" },
    { id = "beast_cleave", label = "Beast Cleave", supportsProcMode = true, default = 8 },
}

M.PLUGIN_OPTS_SV = M.PLUGIN_OPTS_SV or {
    { id = "tots_stacks", label = "Tip of the Spear Stacks", supportsProcMode = true, default = 1, valueLabel = "Stacks", procCompareOnly = true },
    { id = "tots_timer", label = "Tip of the Spear Timer", supportsProcMode = true, default = 5 },
    { id = "takedown_buff", label = "Takedown Buff", supportsProcMode = true, default = 5 },
    { id = "raptor_swipe_override", label = "Raptor Swipe Override" },
}

M.PLUGIN_OPTS_VIVIFY_MONK = M.PLUGIN_OPTS_VIVIFY_MONK or {
    { id = "vivify_proc", label = "Vivify Proc", supportsProcMode = true, default = 20 },
}

M.WINDWALKER_SPEC_ID = M.WINDWALKER_SPEC_ID or 269
M.BM_HUNTER_SPEC_ID = M.BM_HUNTER_SPEC_ID or 253
M.SURVIVAL_HUNTER_SPEC_ID = M.SURVIVAL_HUNTER_SPEC_ID or 255
M.BM_MONK_SPEC_ID = M.BM_MONK_SPEC_ID or 268
M.MW_MONK_SPEC_ID = M.MW_MONK_SPEC_ID or 270

function M.IsWindwalkerGUI()
    return M.GetEditSpecID() == M.WINDWALKER_SPEC_ID
end

function M.IsBeastMasteryHunterGUI()
    return M.GetEditSpecID() == M.BM_HUNTER_SPEC_ID
end

function M.IsSurvivalHunterGUI()
    return M.GetEditSpecID() == M.SURVIVAL_HUNTER_SPEC_ID
end

function M.IsVivifyMonkGUI()
    local sid = M.GetEditSpecID()
    return sid == M.BM_MONK_SPEC_ID or sid == M.MW_MONK_SPEC_ID
end

function M.SupportsPluginGUI()
    if M.IsWindwalkerGUI() or M.IsBeastMasteryHunterGUI() or M.IsSurvivalHunterGUI() or M.IsVivifyMonkGUI() then
        return true
    end
    if _G.SBAS_DynBuffRegistry then
        for _, entry in pairs(_G.SBAS_DynBuffRegistry) do
            if entry.specID == M.GetEditSpecID() then return true end
        end
    end
    if _G.SBAS_DynActivationRegistry then
        for _, entry in pairs(_G.SBAS_DynActivationRegistry) do
            if entry.specID == M.GetEditSpecID() then return true end
        end
    end
    if _G.SBAS_TriggerTrackerRegistry then
        for _, entry in pairs(_G.SBAS_TriggerTrackerRegistry) do
            if entry.specID == M.GetEditSpecID() then return true end
        end
    end
    return false
end

function M.GetVisiblePluginOptions()
    local base
    if M.IsWindwalkerGUI() then
        base = M.PLUGIN_OPTS_WW
    elseif M.IsBeastMasteryHunterGUI() then
        base = M.PLUGIN_OPTS_BM
    elseif M.IsSurvivalHunterGUI() then
        base = M.PLUGIN_OPTS_SV
    elseif M.IsVivifyMonkGUI() then
        base = M.PLUGIN_OPTS_VIVIFY_MONK
    end

    local dynOpts = {}
    local seenDyn = {}
    local function AddDynOpts(registry)
        if not registry then return end
        for pluginID, entry in pairs(registry) do
            if entry.specID == M.GetEditSpecID() and not seenDyn[pluginID] then
                seenDyn[pluginID] = true
                local opt = { id = pluginID, label = entry.label }
                if entry.timerVar then opt.supportsProcMode = true end
                dynOpts[#dynOpts + 1] = opt
            end
        end
    end

    if _G.SBAS_DynBuffRegistry or _G.SBAS_DynActivationRegistry then
        AddDynOpts(_G.SBAS_DynBuffRegistry)
        AddDynOpts(_G.SBAS_DynActivationRegistry)
        table.sort(dynOpts, function(a, b) return a.label < b.label end)
    end

    if _G.SBAS_TriggerTrackerRegistry then
        local ttOpts = {}
        local specID = M.GetEditSpecID()
        for pluginID, entry in pairs(_G.SBAS_TriggerTrackerRegistry) do
            if entry.specID == specID and not seenDyn[pluginID] then
                seenDyn[pluginID] = true
                ttOpts[#ttOpts + 1] = {
                    id             = pluginID,
                    label          = entry.label,
                    supportsProcMode = true,
                    default        = entry.hasTimer and 3 or 1,
                    valueLabel     = entry.hasTimer and "Sec" or "Stacks",
                }
            end
        end
        table.sort(ttOpts, function(a, b) return a.label < b.label end)
        for _, opt in ipairs(ttOpts) do dynOpts[#dynOpts + 1] = opt end
    end

    if #dynOpts == 0 then return base or {} end
    if not base then return dynOpts end

    local merged = {}
    for _, opt in ipairs(base) do merged[#merged + 1] = opt end
    for _, opt in ipairs(dynOpts) do merged[#merged + 1] = opt end
    return merged
end
