local Core = _G.SBAS_GUI or {}

local editSpecID = 0
if Core.SetEditSpecIDAccessor then Core.SetEditSpecIDAccessor(function() return editSpecID end) end
local SPEC_SECONDARY = Core.SPEC_SECONDARY
local SPEC_SECONDARY_DEFAULT = Core.SPEC_SECONDARY_DEFAULT
local COND_BY_ID = Core.COND_BY_ID
local GetVisibleCondTypes = Core.GetVisibleCondTypes
local GetVisiblePluginOptions = Core.GetVisiblePluginOptions
local GetTabName, SetTabName = Core.GetTabName, Core.SetTabName
local GetTabCount, SetTabCount = Core.GetTabCount, Core.SetTabCount
local GetGuiTabRules, SetGuiTabRules = Core.GetGuiTabRules, Core.SetGuiTabRules
local DeepCopyRules = Core.DeepCopyRules
local SerializeRulesForExportV2 = Core.SerializeRulesForExportV2
local SerializeAllTabsForExport = Core.SerializeAllTabsForExport
local DeserializeAllTabsFromExport = Core.DeserializeAllTabsFromExport
local DeserializeRulesFromExport = Core.DeserializeRulesFromExport
local GetBlizzardSBADefaultRules = Core.GetBlizzardSBADefaultRules

local function SetBD(f, r, g, b, a, er, eg, eb)
    f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropColor(r or 0.05, g or 0.08, b or 0.12, a or 0.95)
    f:SetBackdropBorderColor(er or 0.2, eg or 0.35, eb or 0.5, 1)
end

local function CurrentSpecID() local si = GetSpecialization(); if not si then return 0 end; return select(1, GetSpecializationInfo(si)) or 0 end
local function GetSpecName(specID) if specID and specID > 0 and GetSpecializationInfoByID then local n = select(2, GetSpecializationInfoByID(specID)); if n then return n end end; return "Spec " .. tostring(specID) end
if Core.SetCurrentSpecIDAccessor then Core.SetCurrentSpecIDAccessor(CurrentSpecID) end

local popupController = Core.NewPopupController({ setBD = SetBD, getVisibleCondTypes = GetVisibleCondTypes, getVisiblePluginOptions = GetVisiblePluginOptions, serializeAllTabsForExport = SerializeAllTabsForExport })
local function CloseAllPopups() popupController.CloseAllPopups() end
local function ShowCondPicker(a, cb) popupController.ShowCondPicker(a, cb) end
local function ShowPluginPicker(a, cb) popupController.ShowPluginPicker(a, cb) end
local function ShowExportPopup(a, s, r, c) popupController.ShowExportPopup(a, s, r, c) end
local function ShowImportPopup(a, cb) popupController.ShowImportPopup(a, cb) end

local GUI_W, GUI_H, LEFT_W, RIGHT_W, PAD, ROW_H = 680, 590, 388, 268, 6, 72
local GUI_MIN_W, GUI_MIN_H, MIN_LEFT_W, MIN_RIGHT_W, MAX_TABS = 680, 590, 320, 240, 5
local activeTabIdx, tabCount, selectedIdx = 1, 1, 0
local tabNames = {}
local allTabRules, sessionAllTabs, tabBarBtns = {}, {}, {}
local tabBar, guiFrame, leftChild, rightPanel, condInputArea = nil, nil, nil, nil, nil
local workingRules, isAddingCond, selectedCondIdx = {}, false, nil
local rowFrames, condRowPool, condJunctionPool, condGroupBoxPool, condRowYList = {}, {}, {}, {}, {}
local ruleDrag, condDrag, dragIconFrame, dragCatcher, condCatcher, condDropLine = nil, nil, nil, nil, nil, nil
local dropIndicator, sbasDrag = nil, nil

local function GetPanelWidths(total) total = total or (guiFrame and guiFrame:GetWidth()) or GUI_W; local leftW = math.floor(total * (LEFT_W / GUI_W)); leftW = math.max(MIN_LEFT_W, math.min(leftW, total - MIN_RIGHT_W - PAD * 4)); return leftW, total - leftW - PAD * 4 end
local function GetLeftPanelWidth() return GetPanelWidths() end
local function GetRightPanelWidth() local _, r = GetPanelWidths(); return r end

local RefreshRuleList, RefreshRightPanel, RefreshTabBar, AddNewTab, DeleteTab
local function ResolveSpellForAdd(id, name) return id, name end
local function CondSummaryText(cond, ruleSpellID, specIDOverride) return Core.CondSummaryText(cond, ruleSpellID, specIDOverride) end
local function GenerateCode(rules) return Core.GenerateCode(rules) end

local function GetRuleRowDeps()
    return { LEFT_W = LEFT_W, ROW_H = ROW_H, PAD = PAD, SetBD = SetBD, COND_BY_ID = COND_BY_ID, SPEC_SECONDARY = SPEC_SECONDARY, SPEC_SECONDARY_DEFAULT = SPEC_SECONDARY_DEFAULT, BuildPluginSummary = Core.BuildPluginSummary, ParenColorCode = Core.ParenColorCode, HasParenMismatch = Core.HasParenMismatch, ruleDrag = ruleDrag, leftChild = leftChild, rowFrames = rowFrames, getLeftPanelWidth = GetLeftPanelWidth, getEditSpecID = function() return editSpecID end, getSelectedIdx = function() return selectedIdx end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, getWorkingRules = function() return workingRules end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, ensureDragIcon = function() if Core.EnsureDragIcon then Core.EnsureDragIcon({ getDragIconFrame = function() return dragIconFrame end, setDragIconFrame = function(v) dragIconFrame = v end }) end end, ensureDragCatcher = function() if Core.EnsureDragCatcher then Core.EnsureDragCatcher({ getDragCatcher = function() return dragCatcher end, setDragCatcher = function(v) dragCatcher = v end, getDropIndicator = function() return dropIndicator end, setDropIndicator = function(v) dropIndicator = v end, getDragIconFrame = function() return dragIconFrame end, getRuleDrag = function() return ruleDrag end, getSbasDrag = function() return sbasDrag end, getRowFrames = function() return rowFrames end, getWorkingRules = function() return workingRules end, getSelectedIdx = function() return selectedIdx end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, getGuiFrame = function() return guiFrame end }) end end, getDragIconFrame = function() return dragIconFrame end, getDragCatcher = function() return dragCatcher end }
end
RefreshRuleList = function() return Core.RefreshRuleList(GetRuleRowDeps()) end

local function MakeOpDropdown(parent, ops) return popupController.MakeOpDropdown(parent, ops) end
local function CreateCondInputArea(parent)
    return Core.CreateCondInputArea and Core.CreateCondInputArea(parent, { setBD = SetBD, getRightPanelWidth = GetRightPanelWidth, makeOpDropdown = MakeOpDropdown, closeAllPopups = CloseAllPopups, showCondPicker = ShowCondPicker, showPluginPicker = ShowPluginPicker, searchSpellBookByName = Core.SearchSpellBookByName, searchTalentTreeByName = Core.SearchTalentTreeByName, specSecondary = SPEC_SECONDARY, specSecondaryDefault = SPEC_SECONDARY_DEFAULT, condById = COND_BY_ID, getVisiblePluginOptions = GetVisiblePluginOptions, normalizePluginState = Core.NormalizePluginState, isCompOp = Core.IsCompOp, opList = Core.OP_LIST, procModeList = Core.PROC_MODE_LIST, stacksValueList = Core.STACKS_VALUE_LIST, isCondPickerShown = popupController.IsCondPickerShown, isPluginPickerShown = popupController.IsPluginPickerShown, getEditSpecID = function() return editSpecID end, setSelectedCondIdx = function(v) selectedCondIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRightPanel = function() RefreshRightPanel() end, opDropdownPopups = popupController.GetOpDropdownPopups() })
end

RefreshRightPanel = function()
    if not rightPanel then return end
    local rule = workingRules[selectedIdx]
    if not rule then rightPanel.header:SetText("Select a spell to edit conditions"); rightPanel.addCondBtn:Hide(); if condInputArea then condInputArea:Hide() end; return end
    rightPanel.header:SetText((rule.name or tostring(rule.spellID or "?")) .. " — Conditions")
    rightPanel.header:SetWidth(GetRightPanelWidth() - 16)
    local yBase = Core.RenderConditionRows(rule, { RIGHT_W = RIGHT_W, rightPanel = rightPanel, condRowPool = condRowPool, condJunctionPool = condJunctionPool, condGroupBoxPool = condGroupBoxPool, condRowYList = condRowYList, condDrag = condDrag, condDropLine = condDropLine, workingRules = workingRules, groupBoxColors = Core.GROUP_BOX_COLORS, setBD = SetBD, condSummaryText = CondSummaryText, analyzeParenGroups = Core.AnalyzeParenGroups, getCondParenDepths = Core.GetCondParenDepths, drawConditionGroupBoxes = function(spans, rowYTops) Core.DrawConditionGroupBoxes(spans, rowYTops, { condGroupBoxPool = condGroupBoxPool, rightPanel = rightPanel, setBD = SetBD }) end, getRightPanelWidth = GetRightPanelWidth, getSelectedIdx = function() return selectedIdx end, setSelectedCondIdx = function(v) selectedCondIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRightPanel = function() RefreshRightPanel() end, refreshRuleList = function() RefreshRuleList() end, ensureCondCatcher = function() if Core.EnsureCondCatcher then Core.EnsureCondCatcher({ getCondCatcher = function() return condCatcher end, setCondCatcher = function(v) condCatcher = v end, getCondDropLine = function() return condDropLine end, setCondDropLine = function(v) condDropLine = v end, getCondDrag = function() return condDrag end, getSelectedIdx = function() return selectedIdx end, getWorkingRules = function() return workingRules end, getRightPanel = function() return rightPanel end, getCondRowYList = function() return condRowYList end, getRightPanelWidth = GetRightPanelWidth }) end end })
    Core.RenderRightPanelFooter(rule, yBase, { rightPanel = rightPanel, workingRules = workingRules, procPluginByID = Core.PROC_PLUGIN_BY_ID, isCompOp = Core.IsCompOp, getRightPanelWidth = GetRightPanelWidth, getSelectedIdx = function() return selectedIdx end, getSelectedCondIdx = function() return selectedCondIdx end, setSelectedCondIdx = function(v) selectedCondIdx = v end, getIsAddingCond = function() return isAddingCond end, setIsAddingCond = function(v) isAddingCond = v end, getCondInputArea = function() return condInputArea end, setCondInputArea = function(v) condInputArea = v end, createCondInputArea = CreateCondInputArea, refreshRightPanel = function() RefreshRightPanel() end, refreshRuleList = function() RefreshRuleList() end })
end

sbasDrag = { active = false, spellID = nil, spellName = nil, itemID = nil }
ruleDrag = { active = false, fromIdx = nil, pending = false, pendingX = 0, pendingY = 0 }
condDrag = { active = false, pending = false, fromIdx = nil, pendingX = 0, pendingY = 0, toSlot = nil }
local castState = Core.InitSeenCastTracker and Core.InitSeenCastTracker({}, { currentSpecID = CurrentSpecID }) or {}
local seenCastSpells = castState.seenCastSpells or {}
local ResetSeenCastsForCurrentSpec = castState.resetSeenCastsForCurrentSpec or function() wipe(seenCastSpells) end
SBAS_GetClassSpells = function() return Core.GetClassSpells({ currentSpecID = CurrentSpecID, editSpecID = function() return editSpecID end, seenCastSpells = seenCastSpells }) end

local function CreateSpellbookPanel(f, leftSF)
    return Core.CreateSpellbookPanel(f, leftSF, { setBD = SetBD, sbasDrag = sbasDrag, ensureDragIcon = function() if Core.EnsureDragIcon then Core.EnsureDragIcon({ getDragIconFrame = function() return dragIconFrame end, setDragIconFrame = function(v) dragIconFrame = v end }) end end, ensureDragCatcher = function() if Core.EnsureDragCatcher then Core.EnsureDragCatcher({ getDragCatcher = function() return dragCatcher end, setDragCatcher = function(v) dragCatcher = v end, getDropIndicator = function() return dropIndicator end, setDropIndicator = function(v) dropIndicator = v end, getDragIconFrame = function() return dragIconFrame end, getRuleDrag = function() return ruleDrag end, getSbasDrag = function() return sbasDrag end, getRowFrames = function() return rowFrames end, getWorkingRules = function() return workingRules end, getSelectedIdx = function() return selectedIdx end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, getGuiFrame = function() return guiFrame end }) end end, getDragIconFrame = function() return dragIconFrame end, getDragCatcher = function() return dragCatcher end, resolveSpellForAdd = ResolveSpellForAdd, getClassSpells = SBAS_GetClassSpells, resetSeenCastsForCurrentSpec = ResetSeenCastsForCurrentSpec, getWorkingRules = function() return workingRules end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end })
end
local function CreateBagPanel(f) return Core.CreateBagPanel(f, { setBD = SetBD, sbasDrag = sbasDrag, ensureDragIcon = function() if Core.EnsureDragIcon then Core.EnsureDragIcon({ getDragIconFrame = function() return dragIconFrame end, setDragIconFrame = function(v) dragIconFrame = v end }) end end, ensureDragCatcher = function() if Core.EnsureDragCatcher then Core.EnsureDragCatcher({ getDragCatcher = function() return dragCatcher end, setDragCatcher = function(v) dragCatcher = v end, getDropIndicator = function() return dropIndicator end, setDropIndicator = function(v) dropIndicator = v end, getDragIconFrame = function() return dragIconFrame end, getRuleDrag = function() return ruleDrag end, getSbasDrag = function() return sbasDrag end, getRowFrames = function() return rowFrames end, getWorkingRules = function() return workingRules end, getSelectedIdx = function() return selectedIdx end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, getGuiFrame = function() return guiFrame end }) end end, getDragIconFrame = function() return dragIconFrame end, getDragCatcher = function() return dragCatcher end, getBagItems = Core.GetBagItems, getWorkingRules = function() return workingRules end, setSelectedIdx = function(v) selectedIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end }) end

local function BuildOpenLoadState() return { editSpecID = editSpecID, tabCount = tabCount, sessionAllTabs = sessionAllTabs, allTabRules = allTabRules, tabNames = tabNames, activeTabIdx = activeTabIdx, workingRules = workingRules, selectedIdx = selectedIdx, isAddingCond = isAddingCond, selectedCondIdx = selectedCondIdx } end
local function ApplyOpenLoadState(s) editSpecID = s.editSpecID; tabCount = s.tabCount; sessionAllTabs = s.sessionAllTabs; allTabRules = s.allTabRules; tabNames = s.tabNames or tabNames or {}; activeTabIdx = s.activeTabIdx; workingRules = s.workingRules; selectedIdx = s.selectedIdx; isAddingCond = s.isAddingCond; selectedCondIdx = s.selectedCondIdx end
local function BuildOpenLoadDeps() return { currentSpecID = CurrentSpecID, refreshCondInputSpec = function() if condInputArea and condInputArea.RefreshSpec then condInputArea.RefreshSpec() end end, getTabCount = GetTabCount, getGuiTabRules = GetGuiTabRules, deepCopyRules = DeepCopyRules, getTabName = GetTabName, setGuiTabRules = SetGuiTabRules, setTabName = SetTabName, setTabCount = SetTabCount, deserializeAllTabsFromExport = DeserializeAllTabsFromExport, deserializeRulesFromExport = DeserializeRulesFromExport, refreshTabBar = function() RefreshTabBar() end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, generateCode = GenerateCode } end

local function SwitchTab(newTabIdx) local s = BuildOpenLoadState(); if Core.SwitchTabState then Core.SwitchTabState(s, { refreshTabBar = function() ApplyOpenLoadState(s); RefreshTabBar() end, refreshRuleList = function() ApplyOpenLoadState(s); RefreshRuleList() end, refreshRightPanel = function() ApplyOpenLoadState(s); RefreshRightPanel() end }, newTabIdx) end; ApplyOpenLoadState(s) end
RefreshTabBar = function() local s = BuildOpenLoadState(); if Core.RefreshTabBarState then Core.RefreshTabBarState(s, { getTabBar = function() return tabBar end, getTabBarButtons = function() return tabBarBtns end, setBD = SetBD, maxTabs = MAX_TABS, getTabName = GetTabName, setTabName = SetTabName, switchTab = function(idx) SwitchTab(idx) end, deleteTab = function(idx) DeleteTab(idx) end, refreshTabBar = function() RefreshTabBar() end }) end; ApplyOpenLoadState(s) end
AddNewTab = function() local s = BuildOpenLoadState(); if Core.AddNewTabState then Core.AddNewTabState(s, { maxTabs = MAX_TABS, setTabCount = SetTabCount, setTabName = SetTabName, refreshTabBar = function() ApplyOpenLoadState(s); RefreshTabBar() end, refreshRuleList = function() ApplyOpenLoadState(s); RefreshRuleList() end, refreshRightPanel = function() ApplyOpenLoadState(s); RefreshRightPanel() end }) end; ApplyOpenLoadState(s) end
DeleteTab = function(tabIdx) local s = BuildOpenLoadState(); if Core.DeleteTabState then Core.DeleteTabState(s, { setTabCount = SetTabCount, refreshTabBar = function() ApplyOpenLoadState(s); RefreshTabBar() end, refreshRuleList = function() ApplyOpenLoadState(s); RefreshRuleList() end, refreshRightPanel = function() ApplyOpenLoadState(s); RefreshRightPanel() end }, tabIdx) end; ApplyOpenLoadState(s) end

local function CreateGUI()
    local cb = Core.BuildGUIFrameCallbacks({ closeAllPopups = CloseAllPopups, getEditSpecID = function() return editSpecID end, getAllTabRules = function() return allTabRules end, getActiveTabIdx = function() return activeTabIdx end, getWorkingRules = function() return workingRules end, setWorkingRules = function(v) workingRules = v end, getTabCountCurrent = function() return tabCount end, getSessionAllTabs = function() return sessionAllTabs end, setGuiTabRules = SetGuiTabRules, deepCopyRules = DeepCopyRules, addNewTab = function() AddNewTab() end, getAddSpellPopup = function() return popupController.GetAddSpellPopup() end, resolveSpellForAdd = ResolveSpellForAdd, setSelectedIdx = function(v) selectedIdx = v end, getSelectedIdx = function() return selectedIdx end, setSelectedCondIdx = function(v) selectedCondIdx = v end, setIsAddingCond = function(v) isAddingCond = v end, refreshTabBar = function() RefreshTabBar() end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, buildOpenLoadState = BuildOpenLoadState, applyOpenLoadState = ApplyOpenLoadState, buildOpenLoadDeps = BuildOpenLoadDeps, hasParenMismatch = Core.HasParenMismatch, generateCode = GenerateCode, currentSpecID = CurrentSpecID, getSpecName = GetSpecName, serializeAllTabsForExport = SerializeAllTabsForExport, serializeRulesForExportV2 = SerializeRulesForExportV2, showExportPopup = ShowExportPopup, showImportPopup = ShowImportPopup, getCondInputArea = function() return condInputArea end, getGUIFrame = function() return guiFrame end })
    local refs = Core.CreateGUIFrame and Core.CreateGUIFrame({ GUI_W = GUI_W, GUI_H = GUI_H, LEFT_W = LEFT_W, RIGHT_W = RIGHT_W, PAD = PAD, ROW_H = ROW_H, GUI_MIN_W = GUI_MIN_W, GUI_MIN_H = GUI_MIN_H, setBD = SetBD, getPanelWidths = GetPanelWidths, createSpellbookPanel = CreateSpellbookPanel, createBagPanel = CreateBagPanel, onHide = cb.onHide, onLogout = cb.onLogout, onAddTab = cb.onAddTab, onAddSpell = cb.onAddSpell, onAddCondition = cb.onAddCondition, onSave = cb.onSave, onPreview = cb.onPreview, onExport = cb.onExport, onImport = cb.onImport, onClear = cb.onClear, onLayout = cb.onLayout })
    if not refs then return end
    tabBar = refs.tabBar; leftChild = refs.leftChild; rightPanel = refs.rightPanel; guiFrame = refs.frame
end

local function OpenGUI(specID, displayName)
    local s = BuildOpenLoadState()
    if Core.OpenGUIState then
        Core.OpenGUIState(s, { hasGUI = function() return guiFrame ~= nil end, createGUI = function() CreateGUI() end, getGUIFrame = function() return guiFrame end, getSpecName = GetSpecName, buildOpenLoadDeps = BuildOpenLoadDeps, prepareOpenState = Core.PrepareOpenState, applyOpenLoadState = ApplyOpenLoadState, refreshTabBar = function() RefreshTabBar() end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end }, specID, displayName)
    else
        if not guiFrame then CreateGUI() end
        if Core.PrepareOpenState then Core.PrepareOpenState(s, BuildOpenLoadDeps(), specID) end
        ApplyOpenLoadState(s)
        guiFrame.title:SetText("SBA Override Builder — " .. (displayName or GetSpecName(editSpecID)))
        guiFrame:Show(); RefreshTabBar(); if guiFrame._refreshSpellPanel then guiFrame._refreshSpellPanel() end; RefreshRuleList(); RefreshRightPanel()
    end
end

Core.InstallOverrideGUIPublicAPI({ openGUI = OpenGUI, buildOpenLoadState = BuildOpenLoadState, applyOpenLoadState = ApplyOpenLoadState, buildOpenLoadDeps = BuildOpenLoadDeps, getBlizzardSBADefaultRules = GetBlizzardSBADefaultRules, setGuiTabRules = SetGuiTabRules, generateCode = GenerateCode, deepCopyRules = DeepCopyRules, isGUIOpen = function() return guiFrame and guiFrame:IsShown() end, refreshRuleList = function() RefreshRuleList() end, refreshRightPanel = function() RefreshRightPanel() end, serializeAllTabsForExport = SerializeAllTabsForExport, deserializeAllTabsFromExport = DeserializeAllTabsFromExport, deserializeRulesFromExport = DeserializeRulesFromExport, serializeRulesForExportV2 = SerializeRulesForExportV2, condSummaryText = CondSummaryText, condById = COND_BY_ID, parenColorCode = Core.ParenColorCode, buildPluginSummary = Core.BuildPluginSummary, specSecondary = SPEC_SECONDARY, specSecondaryDefault = SPEC_SECONDARY_DEFAULT, getEditSpecID = function() return editSpecID end })
