-- CooldownTracker_CombatCoach_LookAndFeel.lua
-- Look & Feel popup for the CooldownTracker CombatCoach panel.
-- Loads after CooldownTracker_CombatCoach.lua provides SOUND_CHOICES,
-- FindSoundName, PlaySoundPreview, and lafPopup.

------------------------------------------------------------------------
-- File-scope UI helpers (take `content` frame as first argument so they
-- can be called from outside PopulateContent).
------------------------------------------------------------------------
local function SL(content, anchor, yOff, text)
    local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    local ap = (anchor == content) and "TOPLEFT" or "BOTTOMLEFT"
    lbl:SetPoint("TOPLEFT", anchor, ap, 0, yOff - 8)
    lbl:SetText(text:upper())
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetTextColor(0.4, 0.6, 0.8, 1.0)
    local line = content:CreateTexture(nil, "OVERLAY")
    line:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -2)
    line:SetSize(350, 1)
    line:SetColorTexture(0.15, 0.25, 0.35, 0.8)
    return line, -20
end

local function CR(content, anchor, yOff, label, getVal, setVal, xOff)
    xOff = xOff or 0
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(350, 22)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOff, yOff - 2)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
    cb:SetSize(20, 20)
    cb:SetChecked(getVal())
    cb:SetScript("OnClick", function(self) setVal(self:GetChecked()) end)
    local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    txt:SetText(label)
    txt:SetTextColor(0.9, 0.95, 1.0, 1.0)
    return row
end

local function DCR(content, anchor, yOff, label, getCondVal, setCondVal, getNotVal, setNotVal)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(350, 22)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff - 2)
    local cbNot = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cbNot:SetPoint("LEFT", row, "LEFT", 0, 0)
    cbNot:SetSize(20, 20)
    cbNot:SetChecked(getNotVal())
    cbNot:SetScript("OnClick", function(self) setNotVal(self:GetChecked()) end)
    local notLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notLbl:SetPoint("LEFT", cbNot, "RIGHT", 2, 0)
    notLbl:SetText("not")
    notLbl:SetTextColor(0.5, 0.5, 0.7, 1.0)
    local cbCond = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cbCond:SetPoint("LEFT", row, "LEFT", 44, 0)
    cbCond:SetSize(20, 20)
    cbCond:SetChecked(getCondVal())
    cbCond:SetScript("OnClick", function(self) setCondVal(self:GetChecked()) end)
    local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("LEFT", cbCond, "RIGHT", 4, 0)
    txt:SetText(label)
    txt:SetTextColor(0.9, 0.95, 1.0, 1.0)
    return row
end

local function JunctionBtn(content, anchor, getVal, setVal)
    local btn = CreateFrame("Button", nil, content)
    btn:SetSize(40, 14)
    btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetAllPoints()
    local function Refresh()
        local j = getVal() or "and"
        lbl:SetText(j:upper())
        if j == "or" then
            bg:SetColorTexture(0.55, 0.30, 0.05, 0.75)
            lbl:SetTextColor(1.0, 0.72, 0.28, 1)
        else
            bg:SetColorTexture(0.08, 0.12, 0.35, 0.75)
            lbl:SetTextColor(0.55, 0.80, 1.0, 1)
        end
    end
    Refresh()
    btn:SetScript("OnClick", function()
        local j = getVal() or "and"
        setVal((j == "and") and "or" or "and")
        Refresh()
    end)
    return btn
end

------------------------------------------------------------------------
-- BuildLookAndFeelPopup: creates the popup frame once, reused each open.
------------------------------------------------------------------------
local function BuildLookAndFeelPopup()
    local f = CreateFrame("Frame", "CDT_LookAndFeelPopup", UIParent, "BackdropTemplate")
    f:SetSize(400, 536)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets   = { left=4, right=4, top=4, bottom=4 },
    })
    f:SetBackdropColor(0.05, 0.08, 0.15, 0.97)
    f:Hide()

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOP", f, "TOP", 0, -8)
    hdr:SetText("LOOK & FEEL")
    hdr:SetTextColor(0.6, 0.75, 0.9, 1.0)

    local spellDrop = CreateFrame("Frame", "CDT_LookAndFeelSpellDrop", f, "UIDropDownMenuTemplate")
    spellDrop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -20)
    UIDropDownMenu_SetWidth(spellDrop, 280)
    f.spellDrop = spellDrop

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     8, -56)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28,  8)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(360, 800)
    sf:SetScrollChild(content)

    f.content = content
    return f
end

------------------------------------------------------------------------
-- OpenLookAndFeelWindow: (re-)uses the popup to edit a spell's options.
------------------------------------------------------------------------
local function OpenLookAndFeelWindow(db, spellName, spellKey)
    if not lafPopup then lafPopup = BuildLookAndFeelPopup() end
    local f         = lafPopup
    local content   = f.content
    local spellDrop = f.spellDrop

    local PopulateContent  -- forward declare

    UIDropDownMenu_Initialize(spellDrop, function(self, level)
        local spells = type(CooldownTracker_GetTrackedSpells) == "function"
            and CooldownTracker_GetTrackedSpells() or {}
        for _, entry in ipairs(spells) do
            local si = UIDropDownMenu_CreateInfo()
            si.text    = entry.spellName
            si.value   = entry.key
            si.checked = (entry.key == f.currentSpellKey)
            si.func = function(btn)
                local list = type(CooldownTracker_GetTrackedSpells) == "function"
                    and CooldownTracker_GetTrackedSpells() or {}
                for _, e in ipairs(list) do
                    if e.key == btn.value then
                        UIDropDownMenu_SetSelectedValue(spellDrop, e.key)
                        UIDropDownMenu_SetText(spellDrop, e.spellName)
                        PopulateContent(e.db, e.spellName, e.key)
                        break
                    end
                end
            end
            UIDropDownMenu_AddButton(si, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(spellDrop, spellKey)
    UIDropDownMenu_SetText(spellDrop, spellName or "?")

    PopulateContent = function(pdb, pSpellName, pSpellKey)
        f.currentSpellKey = pSpellKey
        for _, child in ipairs({ content:GetChildren() }) do child:Hide(); child:SetParent(nil) end
        for _, region in ipairs({ content:GetRegions() }) do region:Hide() end

        local anchor, y = content, 0

        -- ---- GLOW TRIGGERS ----
        local div, dy = SL(content, anchor, y, "Glow Triggers")
        anchor, y = div, dy
        anchor = CR(content, anchor, y, "Enable Glow",
            function() return pdb.glow_enabled end,
            function(v)
                local want = (v == true)
                if want ~= (pdb.glow_enabled == true) then shmIcons:ToggleGlowEnabled("Cooldown Tracker", pSpellKey) end
                pdb.glow_enabled = want
            end)
        y = -2
        anchor = CR(content, anchor, y, "Reactive Spell Enabled  (cdInfo.isEnabled)",
            function() return pdb.glow_cond_reactive end, function(v) pdb.glow_cond_reactive = v end, 14)
        y = -2
        anchor = CR(content, anchor, y, "Usable  (resource + range check)",
            function() return pdb.glow_cond_usable end, function(v) pdb.glow_cond_usable = v end)
        anchor = CR(content, anchor, y, "Has 1+ Charges ready",
            function() return pdb.glow_cond_charges end, function(v) pdb.glow_cond_charges = v end)
        anchor = CR(content, anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.glow_cond_offcd end, function(v) pdb.glow_cond_offcd = v end)
        local glowReset = CreateFrame("Frame", nil, content)
        glowReset:SetSize(350, 1)
        glowReset:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -14, 0)
        anchor = glowReset

        -- ---- AUDIO ALERT ----
        local div2, dy2 = SL(content, anchor, -6, "Audio Alert Triggers")
        anchor, y = div2, dy2
        anchor = CR(content, anchor, y, "Enable Sound",
            function() return pdb.sound_enabled end, function(v) pdb.sound_enabled = (v == true) end)
        y = -2
        anchor = CR(content, anchor, y, "Reactive Spell Enabled",
            function() return pdb.sound_cond_reactive end, function(v) pdb.sound_cond_reactive = v end, 14)
        y = -2
        anchor = CR(content, anchor, y, "Usable  (resource + range check)",
            function() return pdb.sound_cond_usable end, function(v) pdb.sound_cond_usable = v end)
        anchor = CR(content, anchor, y, "Has 1+ Charges ready",
            function() return pdb.sound_cond_charges end, function(v) pdb.sound_cond_charges = v end)
        anchor = CR(content, anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.sound_cond_offcd end, function(v) pdb.sound_cond_offcd = v end)
        local sndReset = CreateFrame("Frame", nil, content)
        sndReset:SetSize(350, 1)
        sndReset:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -14, 0)
        anchor = sndReset

        local soundLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        soundLbl:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
        soundLbl:SetText("Sound:")
        soundLbl:SetTextColor(0.6, 0.75, 0.9, 1.0)

        local soundDrop = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
        soundDrop:SetPoint("TOPLEFT", soundLbl, "BOTTOMLEFT", -16, -4)
        UIDropDownMenu_SetWidth(soundDrop, 200)
        UIDropDownMenu_Initialize(soundDrop, function(self, level)
            local ni = UIDropDownMenu_CreateInfo()
            ni.text = "None"; ni.value = nil; ni.checked = (pdb.ready_sound == nil)
            ni.func = function()
                pdb.ready_sound = nil
                UIDropDownMenu_SetSelectedValue(soundDrop, nil)
                UIDropDownMenu_SetText(soundDrop, "None")
            end
            UIDropDownMenu_AddButton(ni, level)
            for _, s in ipairs(SOUND_CHOICES) do
                local si = UIDropDownMenu_CreateInfo()
                si.text = s.text; si.value = s.id; si.checked = (pdb.ready_sound == s.id)
                si.func = function(btn)
                    pdb.ready_sound = btn.value
                    UIDropDownMenu_SetSelectedValue(soundDrop, btn.value)
                    UIDropDownMenu_SetText(soundDrop, btn.text)
                    PlaySoundPreview(btn.value)
                end
                UIDropDownMenu_AddButton(si, level)
            end
        end)
        UIDropDownMenu_SetSelectedValue(soundDrop, pdb.ready_sound)
        UIDropDownMenu_SetText(soundDrop, FindSoundName(pdb.ready_sound))
        local dropSpacer = CreateFrame("Frame", nil, content)
        dropSpacer:SetSize(350, 1)
        dropSpacer:SetPoint("TOPLEFT", soundLbl, "BOTTOMLEFT", 0, -42)
        anchor = dropSpacer

        -- ---- CONDITIONAL HIDE ----
        local div3, dy3 = SL(content, anchor, -10, "Conditional Hide")
        anchor, y = div3, dy3
        anchor = CR(content, anchor, y, "Conditionally hide icon",
            function() return pdb.show_enabled end, function(v) pdb.show_enabled = (v == true) end)
        y = -2
        anchor = DCR(content, anchor, y, "Reactive Spell Enabled",
            function() return pdb.show_cond_reactive end, function(v) pdb.show_cond_reactive = v end,
            function() return pdb.show_cond_reactive_not end, function(v) pdb.show_cond_reactive_not = v end)
        anchor = JunctionBtn(content, anchor,
            function() return pdb.show_join_usable end, function(v) pdb.show_join_usable = v end)
        y = -2
        anchor = DCR(content, anchor, y, "Usable  (resource + range check)",
            function() return pdb.show_cond_usable end, function(v) pdb.show_cond_usable = v end,
            function() return pdb.show_cond_usable_not end, function(v) pdb.show_cond_usable_not = v end)
        anchor = JunctionBtn(content, anchor,
            function() return pdb.show_join_charges end, function(v) pdb.show_join_charges = v end)
        anchor = DCR(content, anchor, y, "Has 1+ Charges ready",
            function() return pdb.show_cond_charges end, function(v) pdb.show_cond_charges = v end,
            function() return pdb.show_cond_charges_not end, function(v) pdb.show_cond_charges_not = v end)
        anchor = JunctionBtn(content, anchor,
            function() return pdb.show_join_offcd end, function(v) pdb.show_join_offcd = v end)
        anchor = DCR(content, anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.show_cond_offcd end, function(v) pdb.show_cond_offcd = v end,
            function() return pdb.show_cond_offcd_not end, function(v) pdb.show_cond_offcd_not = v end)

        -- ---- HOTKEY ----
        local div4, dy4 = SL(content, anchor, -6, "Hotkey")
        anchor, y = div4, dy4
        CR(content, anchor, y, "Show action-bar hotkey on icon",
            function() return pdb.show_hotkey end,
            function(v)
                pdb.show_hotkey = v
                if pSpellKey and shmIcons then
                    shmIcons:SetDisplayHotkey("Cooldown Tracker", pSpellKey, v == true)
                end
            end)

        content:SetHeight(710)
    end

    PopulateContent(db, spellName, spellKey)
    f:Show()
    f:Raise()
end

------------------------------------------------------------------------
-- Public entry point
------------------------------------------------------------------------
function CooldownTracker_OpenLookAndFeel(spellKey)
    if type(CooldownTracker_GetTrackedSpells) == "function" then
        local spells = CooldownTracker_GetTrackedSpells()
        for _, entry in ipairs(spells) do
            if entry.key == spellKey then
                OpenLookAndFeelWindow(entry.db, entry.spellName, entry.key)
                return
            end
        end
    end
end
