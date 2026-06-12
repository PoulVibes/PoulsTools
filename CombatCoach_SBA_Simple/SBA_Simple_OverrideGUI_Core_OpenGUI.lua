-- SBA_Simple_OverrideGUI_Core_OpenGUI.lua
-- OpenGUI orchestration for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.OpenGUIState(state, deps, specID, displayName)
    if not deps.hasGUI() then deps.createGUI() end

    if deps.prepareOpenState then
        deps.prepareOpenState(state, deps.buildOpenLoadDeps(), specID)
    end
    deps.applyOpenLoadState(state)

    local guiFrame = deps.getGUIFrame()
    if not guiFrame then return end

    guiFrame.title:SetText("Rotation Builder — " .. (displayName or deps.getSpecName(state.editSpecID)))
    guiFrame:Show()
    deps.refreshTabBar()

    if guiFrame._refreshSpellPanel then
        guiFrame._refreshSpellPanel()
    end

    deps.refreshRuleList()
    deps.refreshRightPanel()
end
