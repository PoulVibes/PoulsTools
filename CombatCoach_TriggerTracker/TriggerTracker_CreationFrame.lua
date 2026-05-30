-- TriggerTracker_CreationFrame.lua
-- Main creation/edit frame. Calls helpers from TT.CF (loaded by prior files).

local TT = TriggerTracker
local CF = TT.CF

local creationFrame = nil

local function EnsureCreationFrame()
    if creationFrame then return creationFrame end

    local f = CreateFrame("Frame", "TriggerTracker_CreationFrame", UIParent, "BackdropTemplate")
    f:SetSize(720, 560)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    CF.SetBD(f, 0.04, 0.06, 0.12, 0.97, 0.28, 0.48, 0.68)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Trigger Tracker \226\128\148 Create / Edit Trigger")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Row 1: name / max stacks / timer ──────────────────────────────────
    local nameLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -34)
    nameLbl:SetText("Trigger Name:"); nameLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(180, 22)
    nameBox:SetPoint("LEFT", nameLbl, "RIGHT", 6, 0)
    nameBox:SetAutoFocus(false); nameBox:SetMaxLetters(64)

    local maxLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLbl:SetPoint("LEFT", nameBox, "RIGHT", 18, 0)
    maxLbl:SetText("Max Stacks:"); maxLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local maxBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    maxBox:SetSize(48, 22); maxBox:SetPoint("LEFT", maxLbl, "RIGHT", 6, 0)
    maxBox:SetAutoFocus(false); maxBox:SetMaxLetters(3); maxBox:SetNumeric(true)

    local timerLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerLbl:SetPoint("LEFT", maxBox, "RIGHT", 18, 0)
    timerLbl:SetText("Timer (s):"); timerLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local timerBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    timerBox:SetSize(52, 22); timerBox:SetPoint("LEFT", timerLbl, "RIGHT", 6, 0)
    timerBox:SetAutoFocus(false); timerBox:SetMaxLetters(6)

    -- ── Row 2: spend per cast ──────────────────────────────────────────────
    local SPEND_OPTS = {}
    for i = 1, 10 do SPEND_OPTS[i] = { l = tostring(i), v = i } end
    SPEND_OPTS[11] = { l = "20",  v = 20    }
    SPEND_OPTS[12] = { l = "All", v = "all" }

    local spendPerCastLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spendPerCastLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -58)
    spendPerCastLbl:SetText("Spend/cast:"); spendPerCastLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local spendDd = CF.CreateMinidropdown(f, SPEND_OPTS, 1, nil, 80)
    spendDd:SetPoint("LEFT", spendPerCastLbl, "RIGHT", 6, 0)

    -- ── Column layout constants ────────────────────────────────────────────
    local COL_W    = 160
    local COL_GAP  = 8
    local PANEL_H  = 230
    local TARGET_H = 24
    local TOP_Y    = -90

    local COL0_X  = 14
    local COL1_X  = COL0_X + COL_W + COL_GAP
    local COL2_X  = COL1_X + COL_W + COL_GAP
    local RIGHT_X = COL2_X + COL_W + COL_GAP
    local FLY_W   = 720 - RIGHT_X - 14

    local activeTarget = "gen"
    local targetBuffBtn, targetGenBtn, targetSpendBtn

    local function UpdateTargetButtons()
        local btns = { buff = targetBuffBtn, gen = targetGenBtn, spend = targetSpendBtn }
        for key, btn in pairs(btns) do
            if not btn then break end
            if key == activeTarget then
                btn:SetButtonState("PUSHED", true)
                btn:GetFontString():SetTextColor(0.3, 1.0, 0.5, 1)
            else
                btn:SetButtonState("NORMAL")
                btn:GetFontString():SetTextColor(0.85, 0.85, 0.85, 1)
            end
        end
    end

    -- ── Buff identity slot ────────────────────────────────────────────────
    targetBuffBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    targetBuffBtn:SetSize(COL_W, TARGET_H)
    targetBuffBtn:SetPoint("TOPLEFT", f, "TOPLEFT", COL0_X, TOP_Y)
    targetBuffBtn:SetText("\226\150\182 Buff Identity")
    targetBuffBtn:SetScript("OnClick", function() activeTarget = "buff"; UpdateTargetButtons() end)

    local buffSlot = CreateFrame("Frame", nil, f, "BackdropTemplate")
    buffSlot:SetSize(COL_W, PANEL_H)
    buffSlot:SetPoint("TOPLEFT", f, "TOPLEFT", COL0_X, TOP_Y - TARGET_H - 4)
    buffSlot:EnableMouse(true)
    CF.SetBD(buffSlot, 0.06, 0.10, 0.18, 0.90, 0.28, 0.48, 0.68)

    local buffSlotHdr = buffSlot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buffSlotHdr:SetPoint("TOPLEFT", buffSlot, "TOPLEFT", 6, -6)
    buffSlotHdr:SetText("BUFF IDENTITY")
    buffSlotHdr:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    buffSlotHdr:SetTextColor(0.4, 0.65, 0.85, 1)

    local buffHintLbl = buffSlot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buffHintLbl:SetPoint("TOPLEFT", buffSlotHdr, "BOTTOMLEFT", 0, -2)
    buffHintLbl:SetWidth(COL_W - 12); buffHintLbl:SetJustifyH("LEFT"); buffHintLbl:SetWordWrap(true)
    buffHintLbl:SetText("Click \226\150\182 Buff Identity then click a spell, or drag a spell here.")
    buffHintLbl:SetTextColor(0.5, 0.6, 0.7, 1)

    local buffIconTex = buffSlot:CreateTexture(nil, "ARTWORK")
    buffIconTex:SetSize(42, 42); buffIconTex:SetPoint("TOPLEFT", buffSlot, "TOPLEFT", 6, -62)
    buffIconTex:SetTexture(134400); buffIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local buffNameLbl = buffSlot:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    buffNameLbl:SetPoint("LEFT", buffIconTex, "RIGHT", 6, 0)
    buffNameLbl:SetPoint("RIGHT", buffSlot, "RIGHT", -4, 0)
    buffNameLbl:SetJustifyH("LEFT"); buffNameLbl:SetWordWrap(true)
    buffNameLbl:SetText("|cff667788(none set)|r")

    local selectedBuffSpellID, selectedBuffIconID, selectedBuffName = nil, nil, nil

    local function SetBuffSpell(spellID, name, iconID)
        selectedBuffSpellID = spellID
        selectedBuffIconID  = iconID or 134400
        selectedBuffName    = name or "Unknown"
        buffIconTex:SetTexture(selectedBuffIconID)
        buffNameLbl:SetText(name or "Unknown")
        if nameBox:GetText() == "" and name then nameBox:SetText(name) end
    end

    buffSlot:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" and CF.dragSpellID then
            SetBuffSpell(CF.dragSpellID, CF.dragSpellName, CF.dragSpellIcon)
            CF.EndDrag()
        end
    end)

    -- ── Gen / spend panels ────────────────────────────────────────────────
    targetGenBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    targetGenBtn:SetSize(COL_W, TARGET_H); targetGenBtn:SetPoint("TOPLEFT", f, "TOPLEFT", COL1_X, TOP_Y)
    targetGenBtn:SetText("\226\150\182 Generators")
    targetGenBtn:SetScript("OnClick", function() activeTarget = "gen"; UpdateTargetButtons() end)

    local GEN_OPTS = {}
    for i = 1, 10 do GEN_OPTS[i] = { l = tostring(i), v = i } end
    local genPanel = CF.CreateDropPanel(f, "Generators (add stacks)", COL_W, PANEL_H,
        "Spells that ADD stacks when successfully cast.",
        function() end, GEN_OPTS)
    genPanel:SetPoint("TOPLEFT", f, "TOPLEFT", COL1_X, TOP_Y - TARGET_H - 4)

    targetSpendBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    targetSpendBtn:SetSize(COL_W, TARGET_H); targetSpendBtn:SetPoint("TOPLEFT", f, "TOPLEFT", COL2_X, TOP_Y)
    targetSpendBtn:SetText("\226\150\182 Spenders")
    targetSpendBtn:SetScript("OnClick", function() activeTarget = "spend"; UpdateTargetButtons() end)

    local spendPanel = CF.CreateDropPanel(f, "Spenders (remove stacks)", COL_W, PANEL_H,
        "Spells that REMOVE one stack when successfully cast.",
        function() end)
    spendPanel:SetPoint("TOPLEFT", f, "TOPLEFT", COL2_X, TOP_Y - TARGET_H - 4)

    CF.dropTargets.genPanel   = genPanel
    CF.dropTargets.spendPanel = spendPanel
    CF.dropTargets.buffSlot   = buffSlot
    CF.dropTargets.onBuffDrop = SetBuffSpell
    UpdateTargetButtons()

    -- ── Flyout column ─────────────────────────────────────────────────────
    local function DispatchSpell(spellID, name, iconID)
        if activeTarget == "gen"   then genPanel:AddSpell(spellID, name, iconID)
        elseif activeTarget == "spend" then spendPanel:AddSpell(spellID, name, iconID)
        elseif activeTarget == "buff"  then SetBuffSpell(spellID, name, iconID) end
    end

    local flyout = CF.CreateFlyoutColumn(f, RIGHT_X, TOP_Y, FLY_W, DispatchSpell)

    -- ── Save / Cancel ──────────────────────────────────────────────────────
    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(160, 28); saveBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    saveBtn:SetText("Create / Save Trigger")
    saveBtn:SetScript("OnClick", function()
        local name      = nameBox:GetText():match("^%s*(.-)%s*$")
        local maxStacks = tonumber(maxBox:GetText()) or 5
        local timer     = tonumber(timerBox:GetText()) or 0
        if name == "" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444TriggerTracker:|r Enter a trigger name.")
            return
        end
        local genEntries   = genPanel:GetEntries()
        local spendEntries = spendPanel:GetEntries()
        if #genEntries == 0 and #spendEntries == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444TriggerTracker:|r Add at least one generator or spender spell.")
            return
        end
        local generators, spenders = {}, {}
        for _, e in ipairs(genEntries) do generators[e.spellID] = e.amount or 1 end
        for _, e in ipairs(spendEntries) do spenders[e.spellID] = true end
        local entry = {
            name         = name,
            iconID       = selectedBuffIconID or 134400,
            buffSpellID  = selectedBuffSpellID,
            generators   = generators,
            spenders     = spenders,
            maxStacks    = maxStacks,
            timer        = timer,
            spendPerCast = spendDd.value,
            enabled      = true,
        }
        local specID = TT.currentSpecID
        if specID == 0 then specID = TriggerTracker_GetCurrentSpecID() end
        if f._editIdx then
            local old = TriggerTracker_GetSpecDB(specID)[f._editIdx]
            if old then
                entry.x     = old.x;  entry.y     = old.y
                entry.point = old.point; entry.size  = old.size
            end
            TriggerTracker_UnregisterIcon(specID, f._editIdx)
            TriggerTracker_SetTrigger(specID, f._editIdx, entry)
            TriggerTracker_RegisterIcon(specID, f._editIdx, entry)
        else
            local idx = TriggerTracker_AddTrigger(specID, entry)
            TriggerTracker_RegisterIcon(specID, idx, entry)
        end
        TT.spellMap = TriggerTracker_BuildSpellMap(specID)
        if TT.rebuildCombatCoachList then TT.rebuildCombatCoachList() end
        f:Hide()
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 28); cancelBtn:SetPoint("LEFT", saveBtn, "RIGHT", 8, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Open helpers ───────────────────────────────────────────────────────
    function f:OpenForNew()
        f._editIdx = nil
        selectedBuffSpellID = nil; selectedBuffIconID = nil; selectedBuffName = nil
        nameBox:SetText(""); maxBox:SetText("5"); timerBox:SetText("0")
        buffIconTex:SetTexture(134400); buffNameLbl:SetText("|cff667788(none set)|r")
        genPanel:Clear(); spendPanel:Clear()
        flyout.ResetCache(); flyout.ResetToSpellTab()
        activeTarget = "gen"; spendDd:SetValue(1)
        UpdateTargetButtons(); flyout.Refresh()
        f:Show()
    end

    function f:OpenForEdit(specID, idx, entry)
        f._editIdx = idx
        selectedBuffSpellID = entry.buffSpellID
        selectedBuffIconID  = entry.iconID or 134400
        selectedBuffName    = entry.name
        nameBox:SetText(entry.name or ""); maxBox:SetText(tostring(entry.maxStacks or 5))
        timerBox:SetText(tostring(entry.timer or 0))
        buffIconTex:SetTexture(entry.iconID or 134400); buffNameLbl:SetText(entry.name or "(none set)")
        genPanel:LoadFromSet(entry.generators); spendPanel:LoadFromSet(entry.spenders)
        flyout.ResetCache(); flyout.ResetToSpellTab()
        activeTarget = "gen"; spendDd:SetValue(entry.spendPerCast or 1)
        UpdateTargetButtons(); flyout.Refresh()
        f:Show()
    end

    creationFrame = f
    return f
end

-- Public API
function TriggerTracker_OpenCreationFrame()
    EnsureCreationFrame():OpenForNew()
end

function TriggerTracker_OpenEditFrame(specID, idx, entry)
    EnsureCreationFrame():OpenForEdit(specID, idx, entry)
end


































    for i = 1, 10 do SPEND_OPTS[i] = { l = tostring(i), v = i } end
    SPEND_OPTS[11] = { l = "20",  v = 20    }
    SPEND_OPTS[12] = { l = "All", v = "all" }

    local spendPerCastLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spendPerCastLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -58)





























