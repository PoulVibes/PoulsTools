-- CooldownTracker_CombatCoach.lua
-- CombatCoach integration for CooldownTracker.

if not CombatCoach then return end

CooldownTrackerDB = CooldownTrackerDB or {}

-- Sound IDs and names for the ready-sound dropdown.
local SOUND_CHOICES = {
    { id = 3081,   text = "Tell Message" },
    { id = 120,    text = "Loot Window Coin Sound" },
    { id = 8960,   text = "Ready Check" },
    { id = 888,    text = "Level Up" },
    { id = 8959,   text = "Raid Warning" },
    { id = 12197,  text = "Raid Boss Emote Warning" },
    { id = 5274,   text = "Auction Window Open" },
    { id = 11461,  text = "Horde PvP Warning" },
    { id = 8446,   text = "A Thing" },
    { id = 11773,  text = "PVP Flag Taken" },
    { id = 12889,  text = "Alarm Clock Warning" },
    { id = 74437,  text = "Keystone Upgrade" },
    { id = 278769, text = "Event Scheduler Chime" },
}
local SOUND_NAME_BY_ID = {}
for _, s in ipairs(SOUND_CHOICES) do SOUND_NAME_BY_ID[s.id] = s.text end

local function FindSoundName(val)
    if not val then return "None" end
    return SOUND_NAME_BY_ID[val] or tostring(val)
end

local function PlaySoundPreview(id)
    if not id then return end
    if C_Sound and C_Sound.PlaySound then pcall(C_Sound.PlaySound, id)
    else pcall(PlaySound, id, "Master") end
end

local lafPopup = nil

-- Builds the shared Look & Feel popup frame.
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
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -10)
    hdr:SetText("LOOK & FEEL")
    hdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    hdr:SetTextColor(0.4, 0.6, 0.8, 1.0)

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

local function OpenLookAndFeelWindow(db, spellName, spellKey)
    if not lafPopup then lafPopup = BuildLookAndFeelPopup() end
    local f         = lafPopup
    local content   = f.content
    local spellDrop = f.spellDrop

    -- Forward-declare so dropdown func can reference it
    local PopulateContent

    -- ---- Spell selector dropdown ----
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

    -- ---- Content builder (called on open and on dropdown selection change) ----
    PopulateContent = function(pdb, pSpellName, pSpellKey)
        f.currentSpellKey = pSpellKey

        -- Destroy old dynamic children
        for _, child in ipairs({ content:GetChildren() }) do
            child:Hide(); child:SetParent(nil)
        end
        for _, region in ipairs({ content:GetRegions() }) do region:Hide() end

        -- Section label helper
        local function SL(anchor, yOff, text)
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

        -- Checkbox row helper
        local function CR(anchor, yOff, label, getVal, setVal, xOff)
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

        -- Double checkbox row: [ ] not  [ ] condition label (used for Conditional Hide)
        local function DCR(anchor, yOff, label, getCondVal, setCondVal, getNotVal, setNotVal)
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

        -- AND/OR junction toggle button rendered between condition rows
        local function JunctionBtn(anchor, getVal, setVal)
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

        local anchor, y = content, 0

        -- ---- GLOW TRIGGERS ----
        local div, dy = SL(anchor, y, "Glow Triggers")
        anchor, y = div, dy
        anchor = CR(anchor, y, "Enable Glow",
            function() return pdb.glow_enabled end,
            function(v)
                local want = (v == true)
                if want ~= (pdb.glow_enabled == true) then
                    shmIcons:ToggleGlowEnabled("Cooldown Tracker", pSpellKey)
                end
                pdb.glow_enabled = want
            end)
        y = -2
        anchor = CR(anchor, y, "Reactive Spell Enabled  (cdInfo.isEnabled)",
            function() return pdb.glow_cond_reactive end, function(v) pdb.glow_cond_reactive = v end, 14)
        y = -2
        anchor = CR(anchor, y, "Usable  (resource + range check)",
            function() return pdb.glow_cond_usable end, function(v) pdb.glow_cond_usable = v end)
        anchor = CR(anchor, y, "Has 1+ Charges ready",
            function() return pdb.glow_cond_charges end, function(v) pdb.glow_cond_charges = v end)
        anchor = CR(anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.glow_cond_offcd end, function(v) pdb.glow_cond_offcd = v end)
        -- Reset x to 0 before next section header (sub-CRs above are indented at x=14)
        local glowReset = CreateFrame("Frame", nil, content)
        glowReset:SetSize(350, 1)
        glowReset:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -14, 0)
        anchor = glowReset

        -- ---- AUDIO ALERT ----
        local div2, dy2 = SL(anchor, -6, "Audio Alert Triggers")
        anchor, y = div2, dy2
        anchor = CR(anchor, y, "Enable Sound",
            function() return pdb.sound_enabled end,
            function(v) pdb.sound_enabled = (v == true) end)
        y = -2
        anchor = CR(anchor, y, "Reactive Spell Enabled",
            function() return pdb.sound_cond_reactive end, function(v) pdb.sound_cond_reactive = v end, 14)
        y = -2
        anchor = CR(anchor, y, "Usable  (resource + range check)",
            function() return pdb.sound_cond_usable end, function(v) pdb.sound_cond_usable = v end)
        anchor = CR(anchor, y, "Has 1+ Charges ready",
            function() return pdb.sound_cond_charges end, function(v) pdb.sound_cond_charges = v end)
        anchor = CR(anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.sound_cond_offcd end, function(v) pdb.sound_cond_offcd = v end)
        -- Reset x to 0 before sound label (sub-CRs above are indented at x=14)
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
            ni.text = "None"; ni.value = nil
            ni.checked = (pdb.ready_sound == nil)
            ni.func = function()
                pdb.ready_sound = nil
                UIDropDownMenu_SetSelectedValue(soundDrop, nil)
                UIDropDownMenu_SetText(soundDrop, "None")
            end
            UIDropDownMenu_AddButton(ni, level)
            for _, s in ipairs(SOUND_CHOICES) do
                local si = UIDropDownMenu_CreateInfo()
                si.text = s.text; si.value = s.id
                si.checked = (pdb.ready_sound == s.id)
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
        -- Spacer to avoid UIDropDownMenuTemplate's internal x offset on subsequent anchors
        local dropSpacer = CreateFrame("Frame", nil, content)
        dropSpacer:SetSize(350, 1)
        dropSpacer:SetPoint("TOPLEFT", soundLbl, "BOTTOMLEFT", 0, -42)
        anchor = dropSpacer

        -- ---- CONDITIONAL HIDE ----
        local div3, dy3 = SL(anchor, -10, "Conditional Hide")
        anchor, y = div3, dy3
        anchor = CR(anchor, y, "Conditionally hide icon",
            function() return pdb.show_enabled end,
            function(v) pdb.show_enabled = (v == true) end)
        y = -2
        anchor = DCR(anchor, y, "Reactive Spell Enabled",
            function() return pdb.show_cond_reactive end, function(v) pdb.show_cond_reactive = v end,
            function() return pdb.show_cond_reactive_not end, function(v) pdb.show_cond_reactive_not = v end)
        anchor = JunctionBtn(anchor,
            function() return pdb.show_join_usable end, function(v) pdb.show_join_usable = v end)
        y = -2
        anchor = DCR(anchor, y, "Usable  (resource + range check)",
            function() return pdb.show_cond_usable end, function(v) pdb.show_cond_usable = v end,
            function() return pdb.show_cond_usable_not end, function(v) pdb.show_cond_usable_not = v end)
        anchor = JunctionBtn(anchor,
            function() return pdb.show_join_charges end, function(v) pdb.show_join_charges = v end)
        anchor = DCR(anchor, y, "Has 1+ Charges ready",
            function() return pdb.show_cond_charges end, function(v) pdb.show_cond_charges = v end,
            function() return pdb.show_cond_charges_not end, function(v) pdb.show_cond_charges_not = v end)
        anchor = JunctionBtn(anchor,
            function() return pdb.show_join_offcd end, function(v) pdb.show_join_offcd = v end)
        anchor = DCR(anchor, y, "Off-Cooldown  (max charges full)",
            function() return pdb.show_cond_offcd end, function(v) pdb.show_cond_offcd = v end,
            function() return pdb.show_cond_offcd_not end, function(v) pdb.show_cond_offcd_not = v end)

        -- ---- HOTKEY ----
        local div4, dy4 = SL(anchor, -6, "Hotkey")
        anchor, y = div4, dy4
        CR(anchor, y, "Show action-bar hotkey on icon",
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

-- Public entry point so other modules (e.g. the shmIcons panel) can open this popup
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

local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("CombatCoach.Widgets missing. Install CombatCoach to configure CooldownTracker here.")
        note:SetTextColor(1,0.8,0.2,1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "CombatCoach_CooldownTracker")
    anchor = div
    y = dy

    -- Forward-declare so the spell-picker dropdown closure can reference them
    local input = ""
    local edit  -- assigned below after the dropdown

    -- ---- Spell Picker dropdown (populated from SBAS Spellbook) ----
    local spellPickLbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellPickLbl:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    spellPickLbl:SetText("SPELL PICKER  (from SBAS Spellbook)")
    spellPickLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    spellPickLbl:SetTextColor(0.4, 0.6, 0.8, 1.0)

    local spellPickDrop = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    spellPickDrop:SetPoint("TOPLEFT", spellPickLbl, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(spellPickDrop, 240)
    UIDropDownMenu_SetText(spellPickDrop, "Select a spell...")
    UIDropDownMenu_Initialize(spellPickDrop, function(self, level)
        local spells = type(SBAS_GetClassSpells) == "function" and SBAS_GetClassSpells() or {}
        if #spells == 0 then
            local ni = UIDropDownMenu_CreateInfo()
            ni.text = "(No spells \226\128\148 open SBAS Override GUI first)"
            ni.func = function() end
            UIDropDownMenu_AddButton(ni, level)
            return
        end
        for _, sp in ipairs(spells) do
            local si = UIDropDownMenu_CreateInfo()
            local capturedName = sp.name
            si.text  = capturedName
            si.value = capturedName
            si.func  = function()
                input = capturedName
                if edit and edit.box then
                    edit.box:SetText(capturedName)
                end
                UIDropDownMenu_SetText(spellPickDrop, capturedName)
            end
            UIDropDownMenu_AddButton(si, level)
        end
    end)
    -- Spacer: resets x to 0 for elements anchored below (UIDropDownMenu has internal -16px x offset)
    local spellPickSpacer = CreateFrame("Frame", nil, parent)
    spellPickSpacer:SetSize(540, 1)
    spellPickSpacer:SetPoint("TOPLEFT", spellPickLbl, "BOTTOMLEFT", 0, -44)
    anchor = spellPickSpacer
    y = 0

    edit = W:EditBox(parent, anchor, y, "Add / Remove Spell", "e.g. Fireball", function() return input end, function(val) input = val end)
    anchor = edit
    y = -8

    local btn = W:Button(parent, anchor, y, "Add Tracker", function()
        local val = input
        if edit and edit.box then
            val = edit.box:GetText()
            if edit.placeholder and val == edit.placeholder then val = "" end
        end
        if not val or val:trim() == "" then print("|cFFFF0000CooldownTracker: enter spell name.|r"); return end
        if type(CooldownTracker_HandleCommand) == "function" then
            CooldownTracker_HandleCommand(val)
        else
            if type(CooldownTracker_Add) == "function" then CooldownTracker_Add(val, nil) end
        end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    btn = W:Button(parent, anchor, y, "Remove Tracker", function()
        local val = input
        if edit and edit.box then
            val = edit.box:GetText()
            if edit.placeholder and val == edit.placeholder then val = "" end
        end
        if not val or val:trim() == "" then print("|cFFFF0000CooldownTracker: enter spell name.|r"); return end
        -- Use the public API to remove explicitly
        if type(CooldownTracker_Remove) == "function" then CooldownTracker_Remove(val) end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Tracked Abilities")
    anchor = div2
    y = dy2

    -- Container to hold the dynamic tracked-abilities list. We build and
    -- rebuild rows inside this container so the rest of the settings layout
    -- (Actions header / buttons) can be repositioned when the list changes.
    local trackedContainer = CreateFrame("Frame", nil, parent)
    trackedContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    trackedContainer:SetSize(540, 0)

    local trackedRows = {}
    local actionsHeaderFrame = nil

    local function BuildTrackedList()
        local specIndex = GetSpecialization()
        local specID = 0
        if specIndex then specID = select(1, GetSpecializationInfo(specIndex)) end

        -- Prefer the public API when available; it returns an array of entries.
        local spells = nil
        local trackedList = nil
        if type(CooldownTracker_GetTrackedSpells) == "function" then
            trackedList = CooldownTracker_GetTrackedSpells(specID)
        end
        if trackedList and #trackedList > 0 then
            spells = {}
            for _, entry in ipairs(trackedList) do
                if entry and entry.key and entry.db then
                    spells[entry.key] = entry.db
                    spells[entry.key].spellName = spells[entry.key].spellName or entry.spellName
                    spells[entry.key].spellID   = spells[entry.key].spellID   or entry.spellID
                end
            end
        else
            spells = (CooldownTrackerDB and CooldownTrackerDB.specs and CooldownTrackerDB.specs[specID] and CooldownTrackerDB.specs[specID].spells) or {}
        end

        local count = 0
        local used = {}
        for key, db in pairs(spells) do
            if db.enabled and db.spellName then
                count = count + 1
                local row = trackedRows[key]
                if not row then
                    row = CreateFrame("Frame", nil, trackedContainer)
                    row:SetSize(540, 26)

                    -- small left remove button (dynamic trackers use X to remove)
                    row.removeLeft = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.removeLeft:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.removeLeft:SetSize(26, 20)
                    row.removeLeft:SetText("X")

                    -- spell icon
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(20, 20)
                    row.icon:SetPoint("LEFT", row.removeLeft, "RIGHT", 6, 0)

                    -- name label
                    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.name:SetTextColor(unpack(W.colors.text))

                    -- [Options] button anchored just right of the spell name
                    row.optionsBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.optionsBtn:SetSize(70, 20)
                    row.optionsBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
                    row.optionsBtn:SetText("Options")
                    row.optionsBtn:SetScript("OnClick", function()
                        OpenLookAndFeelWindow(row.db, row.spellName, row.spellKey)
                    end)
                end

                -- update values
                row.removeLeft:SetScript("OnClick", function(self)
                    local spell = row.spellName
                    if not spell or spell:trim() == "" then return end
                    if type(CooldownTracker_Remove) == "function" then CooldownTracker_Remove(spell) end
                end)

                local sInfo = (db.spellID and C_Spell.GetSpellInfo(db.spellID)) or nil
                row.icon:SetTexture((sInfo and sInfo.iconID) or 134400)
                row.spellName = db.spellName
                row.spellKey  = key
                row.db        = db
                row.name:SetText(db.spellName)

                row:SetPoint("TOPLEFT", trackedContainer, "TOPLEFT", 0, -(count - 1) * 26)
                row:Show()
                trackedRows[key] = row
                used[key] = true
            end
        end
        -- (dropdowns are created per-row inside the loop)

        -- hide rows that are no longer present
        for k, r in pairs(trackedRows) do
            if not used[k] then
                r:Hide()
                trackedRows[k] = nil
            end
        end

        local totalHeight = count * 26
        trackedContainer:SetHeight(totalHeight)

        -- if actions header exists, reanchor it so buttons move with the list
        if actionsHeaderFrame and actionsHeaderFrame.SetPoint then
            actionsHeaderFrame:SetPoint("TOPLEFT", trackedContainer, "BOTTOMLEFT", 0, -6)
        end
    end

    -- initial build
    BuildTrackedList()

    -- register for runtime updates when trackers are added/removed
    if parent._cdtChangeListener and type(CooldownTracker_UnregisterChangeListener) == "function" then
        CooldownTracker_UnregisterChangeListener(parent._cdtChangeListener)
    end
    parent._cdtChangeListener = BuildTrackedList
    if type(CooldownTracker_RegisterChangeListener) == "function" then
        CooldownTracker_RegisterChangeListener(parent._cdtChangeListener)
    end

    local div3, dy3 = W:SectionHeader(parent, trackedContainer, -6, "Actions")
    -- keep a reference so the tracked list can reanchor this header on updates
    actionsHeaderFrame = div3
    anchor = div3
    y = dy3

    btn = W:Button(parent, anchor, y, "Reset Position", function()
        local val = input
        if edit and edit.box then
            val = edit.box:GetText()
            if edit.placeholder and val == edit.placeholder then val = "" end
        end
        if not val or val:trim() == "" then print("|cFFFF0000CooldownTracker: enter spell name.|r"); return end
        if type(CooldownTracker_HandleCommand) == "function" then
            CooldownTracker_HandleCommand("reset " .. val)
        else
            if type(CooldownTracker_Reset) == "function" then CooldownTracker_Reset(val) end
        end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    btn = W:Button(parent, anchor, y, "Reset All", function()
        if type(CooldownTracker_HandleCommand) == "function" then
            CooldownTracker_HandleCommand("reset all")
        else
            if type(CooldownTracker_ResetAll) == "function" then CooldownTracker_ResetAll() end
        end
    end)
    anchor = btn
    y = -8

    -- Lock / Unlock button similar to SBA_Simple
    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if type(CooldownTracker_ToggleLock) == "function" then
            local locked = CooldownTracker_ToggleLock()
            local nextLabel = locked and "Unlock Icons" or "Lock Icons"
            if lockBtn then lockBtn:SetText(nextLabel) end
        else
            print("|cFFFF4444CooldownTracker:|r lock API not available.")
        end
    end)
    lockBtn = anchor
    parent._cdtLockBtn = lockBtn
    y = -8

    btn = W:Button(parent, anchor, y, "Print List", function()
        if type(CooldownTracker_HandleCommand) == "function" then
            CooldownTracker_HandleCommand("list")
        else
            if type(CooldownTracker_List) == "function" then CooldownTracker_List() end
        end
    end)
    anchor = btn
    -- Keep lock button label in sync when the settings panel is shown
    if not parent._cdtOnShowHooked then
        parent._cdtOnShowHooked = true
        parent:HookScript("OnShow", function()
            local btn = parent._cdtLockBtn
            if btn and shmIcons and shmIcons.IsLocked then
                btn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
            end
        end)
    end
end

CombatCoach.Menu:RegisterAddon({
    name      = "Cooldown Tracker",
    id        = "CombatCoach_CooldownTracker",
    desc      = "Track ability cooldowns and charges.",
    version   = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("CombatCoach_CooldownTracker", "Version")) or "2.1.5",
    icon      = "Interface\\Icons\\inv_misc_book_11",
    OnBuildUI = OnBuildUI,
})
