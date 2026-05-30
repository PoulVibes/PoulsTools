-- SBA_Simple_OverrideGUI_Core_PublicAPI.lua
-- Installs override GUI public API and slash command hook.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.InstallOverrideGUIPublicAPI(deps)
    _G.SBAS_OpenOverrideGUI = deps.openGUI

    _G.SBAS_ResetToBlizzardSBA = function(specID)
        local state = deps.buildOpenLoadState()
        if M.ResetToBlizzardSBA then
            M.ResetToBlizzardSBA(state, {
                getBlizzardSBADefaultRules = deps.getBlizzardSBADefaultRules,
                setGuiTabRules = deps.setGuiTabRules,
                generateCode = deps.generateCode,
                deepCopyRules = deps.deepCopyRules,
                isGUIOpen = deps.isGUIOpen,
                refreshRuleList = deps.refreshRuleList,
                refreshRightPanel = deps.refreshRightPanel,
            }, specID)
        end
        deps.applyOpenLoadState(state)
    end

    _G.SBAS_LoadImportTextIntoOverrideGUI = function(specID, displayName, payload)
        if type(payload) ~= "string" or payload:match("^%s*$") then
            return false, "import payload is empty"
        end

        deps.openGUI(specID, displayName)

        local state = deps.buildOpenLoadState()
        local ok, modeOrErr = M.ApplyImportPayload and M.ApplyImportPayload(state, deps.buildOpenLoadDeps(), payload)
        if not ok then
            return false, modeOrErr or "invalid import payload"
        end
        deps.applyOpenLoadState(state)
        return true
    end

    _G.SBAS_NormalizeImportText = function(importText, specID)
        if type(importText) ~= "string" or importText:match("^%s*$") then
            return nil, "empty import text"
        end
        local tabs = deps.deserializeAllTabsFromExport(importText, specID)
        if tabs then
            local tabsRules = {}
            for t, tab in ipairs(tabs) do tabsRules[t] = tab.rules end
            return deps.serializeAllTabsForExport(specID, tabsRules, #tabs)
        end
        local rules, err = deps.deserializeRulesFromExport(importText, specID)
        if not rules then return nil, err or "parse error" end
        return deps.serializeAllTabsForExport(specID, { rules }, 1)
    end

    _G.SBAS_LoadRulesIntoOverrideGUI = function(specID, displayName, rules)
        if type(rules) ~= "table" then
            return false, "rules must be a table"
        end

        deps.openGUI(specID, displayName)

        local state = deps.buildOpenLoadState()
        if M.ApplyRulesTable then
            M.ApplyRulesTable(state, deps.buildOpenLoadDeps(), rules)
        end
        deps.applyOpenLoadState(state)

        return true
    end

    _G.SBAS_GetDefaultOverrideCodeForSpec = function(specID)
        local state = deps.buildOpenLoadState()
        local code = M.GetDefaultOverrideCodeForSpec and M.GetDefaultOverrideCodeForSpec(state, deps.buildOpenLoadDeps(), specID)
        deps.applyOpenLoadState(state)
        return code
    end

    _G.SBAS_CondSummaryText = deps.condSummaryText

    _G.SBAS_BuildCondRowText = function(cond, ruleSpellID, isFirst, parenDepthIn)
        if M.BuildCondRowText then
            return M.BuildCondRowText(cond, ruleSpellID, isFirst, parenDepthIn, {
                condById = deps.condById,
                parenColorCode = deps.parenColorCode,
                buildPluginSummary = deps.buildPluginSummary,
                specSecondary = deps.specSecondary,
                specSecondaryDefault = deps.specSecondaryDefault,
                getEditSpecID = deps.getEditSpecID,
            })
        end
        return ("[" .. (cond.type or "?") .. "]"), (parenDepthIn or 0)
    end

    local origSlash = SlashCmdList["SBASIMPLE"]
    SlashCmdList["SBASIMPLE"] = function(msg)
        local cmd = (msg or ""):match("^%s*(.-)%s*$"):lower()
        if cmd == "override_gui" then
            deps.openGUI()
        else
            if origSlash then origSlash(msg) end
        end
    end
end

return M
