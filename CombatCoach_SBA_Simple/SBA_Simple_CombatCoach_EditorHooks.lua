-- SBA_Simple_CombatCoach_EditorHooks.lua
-- Shared helpers for spec-button state and editor open/close hooks.

function SBAS_SetSpecButtonsEnabled(specButtons, enabled)
    for _, e in ipairs(specButtons or {}) do
        for _, b in ipairs(e.btns or {}) do
            if enabled then
                if b._alwaysDisabled then b:Disable() else b:Enable() end
            else
                b:Disable()
            end
        end
    end
end

function SBAS_RefreshSpecButtonColors(specButtons, colors)
    local db = SBA_SimpleDB or {}
    for _, e in ipairs(specButtons or {}) do
        local id = e.id
        local hasText = false
        if id and db.specs and db.specs[id] and db.specs[id].overrideCode and not db.specs[id].overrideCode:match("^%s*$") then
            hasText = true
        end
        if e.label then
            if hasText then e.label:SetTextColor(unpack(colors.warning)) else e.label:SetTextColor(unpack(colors.textMuted)) end
        end
        if e.refreshHighlight then e.refreshHighlight() end
    end
end

function SBAS_InstallSpecEditorHooks(specButtons, onEditorClose)
    local state = _G.SBAS_CombatCoachEditorHooksState
    if not state then
        state = {}
        _G.SBAS_CombatCoachEditorHooksState = state
    end
    state.specButtons = specButtons
    state.onEditorClose = onEditorClose

    local function disableButtons()
        SBAS_SetSpecButtonsEnabled(state.specButtons, false)
    end

    local function closeEditor()
        if state.onEditorClose then state.onEditorClose() end
    end

    -- Hook the text code editor (SBAS_OverrideFrame — always exists at this point)
    local overrideCodeFrame = _G["SBAS_OverrideFrame"]
    if overrideCodeFrame and not overrideCodeFrame.__SBAS_CombatCoachHooked then
        overrideCodeFrame:HookScript("OnShow", disableButtons)
        overrideCodeFrame:HookScript("OnHide", closeEditor)
        overrideCodeFrame.__SBAS_CombatCoachHooked = true
    end

    -- Hook the graphical GUI editor (SBAS_OverrideGUI_Frame — created lazily; wrap opener)
    local function ensureGUIFrameHooked()
        local gf = _G["SBAS_OverrideGUI_Frame"]
        if gf and not gf.__SBAS_CombatCoachHooked then
            gf:HookScript("OnShow", disableButtons)
            gf:HookScript("OnHide", closeEditor)
            gf.__SBAS_CombatCoachHooked = true
        end
    end

    if type(_G.SBAS_OpenOverrideGUI) == "function" and not state.openWrapped then
        local origOpenGUI = _G.SBAS_OpenOverrideGUI
        _G.SBAS_OpenOverrideGUI = function(sid, dname)
            disableButtons()
            origOpenGUI(sid, dname)
            ensureGUIFrameHooked()
        end
        state.openWrapped = true
    end

    -- Recommended/default imports can open the GUI without going through SBAS_OpenOverrideGUI.
    -- Wrap those helpers too so button disable/enable state always stays in sync.
    if type(_G.SBAS_LoadImportTextIntoOverrideGUI) == "function" and not state.importWrapped then
        local origLoadImportTextIntoGUI = _G.SBAS_LoadImportTextIntoOverrideGUI
        _G.SBAS_LoadImportTextIntoOverrideGUI = function(specID, displayName, payload)
            disableButtons()
            local ok, err = origLoadImportTextIntoGUI(specID, displayName, payload)
            ensureGUIFrameHooked()
            if not ok then
                closeEditor()
            end
            return ok, err
        end
        state.importWrapped = true
    end

    if type(_G.SBAS_LoadRulesIntoOverrideGUI) == "function" and not state.rulesWrapped then
        local origLoadRulesIntoGUI = _G.SBAS_LoadRulesIntoOverrideGUI
        _G.SBAS_LoadRulesIntoOverrideGUI = function(specID, displayName, rules)
            disableButtons()
            local ok, err = origLoadRulesIntoGUI(specID, displayName, rules)
            ensureGUIFrameHooked()
            if not ok then
                closeEditor()
            end
            return ok, err
        end
        state.rulesWrapped = true
    end
end
