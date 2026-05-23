-- SBA_Simple_CombatCoach.lua
-- CombatCoach integration for SBA_Simple

if not CombatCoach then return end

SBA_SimpleDB = SBA_SimpleDB or {}

local function OnBuildUI(parent)
    if parent.__SBASPanelInitialized then
        if parent.__SBASRefreshOnShow then parent.__SBASRefreshOnShow() end
        return
    end

    local W = CombatCoach.Widgets
    local anchor = parent
    local y = 0

    local header, dy = W:SectionHeader(parent, anchor, y, "CombatCoach_SBA_Simple")
    anchor = header
    y = dy

    -- track all spec buttons so we can enable/disable and refresh their colors
    local specButtons = {}
    -- Pending optimized baseline per specID: stored when "Optimized" is clicked.
    -- Save & Apply compares the saved export with this to decide mode.
    local pendingOptimizedBaseline = {}
    local ACTION_BTN_W = 160
    local GetRecommendedImportTextForSpec = SBAS_GetRecommendedImportTextForSpec

    local sliderRow = W:Slider(parent, anchor, y,
        "Icon Size", 16, 128, 1,
        function() return (SBA_SimpleDB and SBA_SimpleDB.size) or 64 end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.size = val; if SBA_Simple_SetSize then SBA_Simple_SetSize(val) end end,
        "%d"
    )
    anchor = sliderRow
    y = -8
    -- Anchor Point dropdown removed: position is persisted but not editable here
    y = -8

    anchor = W:Checkbox(parent, anchor, y,
        "Glow Enabled",
        "Show glow around the icon.",
        function() return (SBA_SimpleDB and SBA_SimpleDB.glow_enabled) end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.glow_enabled = val end
    )
    y = -6

    -- Edit Override Logic button removed; per-spec buttons provide editors now

    anchor = W:Button(parent, anchor, y, "Reset Position", function()
        if SlashCmdList and SlashCmdList["SBASIMPLE"] then
            SlashCmdList["SBASIMPLE"]("reset")
        else
            -- Fallback: perform a minimal reset if slash handler isn't available
            SBA_SimpleDB = SBA_SimpleDB or {}
            SBA_SimpleDB.x = 0
            SBA_SimpleDB.y = 0
            SBA_SimpleDB.point = "CENTER"
            SBA_SimpleDB.size = 64
            print("|cff00ff99SBA_Simple:|r position reset to defaults (partial).")
        end
    end)
    y = -8

    -- Lock / Unlock button for shmIcons
    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if shmIcons and shmIcons.ToggleLock then
            local locked = shmIcons:ToggleLock()
            -- Update label to reflect the next action (clicking will toggle)
            local nextLabel = locked and "Unlock Icons" or "Lock Icons"
            if lockBtn then lockBtn:SetText(nextLabel) end
        else
            print("|cFFFF4444SBA_Simple:|r shmIcons not available.")
        end
    end)
    lockBtn = anchor
    y = -8

    -- ── Override Analyzer button ────────────────────────────────────────────
    local analyzerBtn
    analyzerBtn = W:Button(parent, anchor, y, "Priority Analyzer", function()
        -- Don't open if an editor is currently visible
        local guiEd  = _G["SBAS_OverrideGUI_Frame"]
        local codeEd = _G["SBAS_OverrideFrame"]
        if (guiEd and guiEd:IsShown()) or (codeEd and codeEd:IsShown()) then
            print("|cffFFCC00Priority Analyzer:|r Close the override editor first.")
            return
        end
        -- Determine current spec
        local specIndex = GetSpecialization and GetSpecialization()
        if not specIndex then
            print("|cffFF4444Priority Analyzer:|r Could not detect active spec.")
            return
        end
        local specID = select(1, GetSpecializationInfo(specIndex))
        if not specID then
            print("|cffFF4444Priority Analyzer:|r Could not detect active specID.")
            return
        end
        local db = SBA_SimpleDB
        local source = db and db.specs and db.specs[specID] and db.specs[specID].overrideSource
        local hasCode = db and db.specs and db.specs[specID] and db.specs[specID].overrideCode
                        and not db.specs[specID].overrideCode:match("^%s*$")
        local hasGui  = db and db.gui and db.gui[specID] and #db.gui[specID] > 0

        if source == "code" or (hasCode and not hasGui and source ~= "gui") then
            print("|cffFFCC00Priority Analyzer:|r Not available for coded overrides. Use the Override editor instead.")
            return
        end
        if not hasGui then
            print("|cffFFCC00Priority Analyzer:|r No GUI priority list found for the current spec.")
            return
        end
        -- Show the analyzer for this spec
        local specName = select(2, GetSpecializationInfo(specIndex)) or ("Spec "..specID)
        SBAS_OpenOrRefreshAnalyzer(specID, specName)
    end)
    anchor = analyzerBtn
    y = -8

    -- Debug error toggle button
    local debugToggleBtn
    local function GetDebugToggleLabel()
        local debug = SBA_SimpleDB and SBA_SimpleDB.overrideDebug
        return debug and "Suppress Errors" or "Show Errors"
    end
    debugToggleBtn = W:Button(parent, anchor, y, GetDebugToggleLabel(), function()
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.overrideDebug = not SBA_SimpleDB.overrideDebug
        if debugToggleBtn then debugToggleBtn:SetText(GetDebugToggleLabel()) end
    end)
    anchor = debugToggleBtn
    y = -8

    -- ── Dynamic icon settings (rebuilt on each panel open) ──────────────────
    -- iconSectionsTailMarker is a 1x1 frame that gets repositioned at the
    -- bottom of the last dynamic section.  The "Single-Button Suggestion
    -- Overrides" header is anchored to it, so it reflows automatically.
    local iconSectionsTailMarker = CreateFrame("Frame", nil, parent)
    iconSectionsTailMarker:SetSize(1, 1)
    iconSectionsTailMarker:SetPoint("TOPLEFT", debugToggleBtn, "BOTTOMLEFT", 0, -8)

    local RebuildDynamicIconSections = SBAS_BuildDynamicIconSections(parent, debugToggleBtn, iconSectionsTailMarker)

    local function GetDynamicIconSignature()
        local tracked = type(SBA_Simple_GetTrackedIconInfo) == "function" and SBA_Simple_GetTrackedIconInfo() or {}
        local parts = { tostring(#tracked) }
        for i = 1, #tracked do
            local info = tracked[i]
            parts[#parts + 1] = (info.key or "") .. ":" .. (info.label or "")
        end
        return table.concat(parts, "|")
    end

    RebuildDynamicIconSections()  -- initial build (tab 1 only at login)
    parent.__SBASDynamicIconSignature = GetDynamicIconSignature()

    local hdr, dy2 = W:SectionHeader(parent, iconSectionsTailMarker, 0, "Single-Button Suggestion Overrides (by Class / Spec)")
    local listAnchor = hdr
    y = dy2

    -- Keep controls in sync when the settings panel is shown (reflect manual resizes)
    parent.__SBASRefreshOnShow = function()
        if debugToggleBtn then debugToggleBtn:SetText(GetDebugToggleLabel()) end
        if sliderRow and sliderRow.slider and sliderRow.valText then
            local sig = GetDynamicIconSignature()
            if sig ~= parent.__SBASDynamicIconSignature then
                RebuildDynamicIconSections()
                parent.__SBASDynamicIconSignature = sig
            end
            local sz = (SBA_SimpleDB and SBA_SimpleDB.size) or 64
            sliderRow.slider:SetValue(sz)
            sliderRow.valText:SetText(string.format("%d", sz))
            -- refresh lock button label
            if lockBtn and shmIcons and shmIcons.IsLocked then
                lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
            end
            -- refresh spec button highlights
            for _, e in ipairs(specButtons) do
                if e.refreshHighlight then e.refreshHighlight() end
            end
        end
    end
    if not parent.__SBASRefreshHooked then
        parent:HookScript("OnShow", function(self)
            if self.__SBASRefreshOnShow then self.__SBASRefreshOnShow() end
        end)
        parent.__SBASRefreshHooked = true
    end

    local orderedClasses, classSpecData = SBAS_GetClassSpecData()
    specButtons = SBAS_BuildClassSpecUI(
        parent,
        listAnchor,
        y,
        orderedClasses,
        classSpecData,
        GetRecommendedImportTextForSpec,
        pendingOptimizedBaseline,
        ACTION_BTN_W,
        W
    )

    -- Manage spec buttons: re-enable and refresh label colors when any editor closes
    local function refreshSpecButtonColors()
        SBAS_RefreshSpecButtonColors(specButtons, W.colors)
    end

    -- Called by the GUI's Save & Apply with the serialized export of what was saved.
    -- Compares with the pending optimized baseline to determine mode, then refreshes highlights.
    _G.SBAS_OnGuiSaveAndApply = function(specID, savedExport)
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.specs = SBA_SimpleDB.specs or {}
        SBA_SimpleDB.specs[specID] = SBA_SimpleDB.specs[specID] or {}
        local baseline = pendingOptimizedBaseline and pendingOptimizedBaseline[specID]
        if baseline and savedExport == baseline then
            SBA_SimpleDB.specs[specID].overrideMode = "optimized"
        else
            SBA_SimpleDB.specs[specID].overrideMode = "custom"
        end
        if pendingOptimizedBaseline then pendingOptimizedBaseline[specID] = nil end
        refreshSpecButtonColors()
    end

    local function onEditorClose()
        SBAS_SetSpecButtonsEnabled(specButtons, true)
        refreshSpecButtonColors()
    end
    SBAS_InstallSpecEditorHooks(specButtons, onEditorClose)
    if parent.__SBASRefreshOnShow then parent.__SBASRefreshOnShow() end
    parent.__SBASPanelInitialized = true

end

CombatCoach.Menu:RegisterAddon({
    name      = "Rotation Assistant",
    id        = "CombatCoach_SBA_Simple",
    order     = 2,
    desc      = "Prioritized Combat Suggestion Display.",
    version   = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("CombatCoach_SBA_Simple", "Version")) or "1.2.0",
    icon      = "Interface\\Icons\\ui_spellbook_onebutton",
    OnBuildUI = OnBuildUI,
})
