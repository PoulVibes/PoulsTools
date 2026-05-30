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
    { id = "last_combo_eq", label = "Combo (CT)" },
}

M.WINDWALKER_SPEC_ID = M.WINDWALKER_SPEC_ID or 269

function M.IsWindwalkerGUI()
    return M.GetEditSpecID() == M.WINDWALKER_SPEC_ID
end

function M.SupportsPluginGUI()
    if M.IsWindwalkerGUI() then return true end
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
    end

    local dynOpts = {}
    local seenDyn = {}
    local function AddDynOpts(registry, acronym)
        if not registry then return end
        for pluginID, entry in pairs(registry) do
            if entry.specID == M.GetEditSpecID() and not seenDyn[pluginID] then
                seenDyn[pluginID] = true
                local opt = { id = pluginID, label = entry.label .. " (" .. acronym .. ")" }
                if entry.timerVar then opt.supportsProcMode = true end
                dynOpts[#dynOpts + 1] = opt
            end
        end
    end

    if _G.SBAS_DynBuffRegistry or _G.SBAS_DynActivationRegistry then
        AddDynOpts(_G.SBAS_DynBuffRegistry, "DBT")
        AddDynOpts(_G.SBAS_DynActivationRegistry, "DAT")
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
                    label          = entry.label .. " (TT)",
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
