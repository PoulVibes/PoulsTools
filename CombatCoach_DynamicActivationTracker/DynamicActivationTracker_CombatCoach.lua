if not CombatCoach then return end

local DAT = DynamicActivationTracker

local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
    if not W then return end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "Dynamic Activation Tracker")
    anchor = div
    y = dy

    local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y - 4)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    note:SetTextColor(0.72, 0.82, 0.92, 1)
    note:SetText(
        "Icons are created from spell activation overlay events and saved per spec. "
        .. "Override icon IDs and timers are stored with each saved entry."
        .. "These can be used for triggering conditions in rotation helper. "
        .. "Most Spell Activations happen when a particular buff is present. "
        .. "Set the Timer, Icon, and Display Name to match the buff you want to track.")
    anchor = note
    y = -8

    anchor = W:Button(parent, anchor, y, "Clear This Spec", function()
        if InCombatLockdown() then
            print("|cFFFF4444DynamicActivationTracker: Cannot clear in combat.|r")
            return
        end
        DynamicActivationTracker_ClearCurrentSpec()
        DynamicActivationTracker_RefreshCurrentSpecList()
        print("|cFFFFFF00DynamicActivationTracker: Cleared saved icons for this spec.|r")
    end)
    y = -4

    local lockLabel = (shmIcons and shmIcons.IsLocked and shmIcons:IsLocked()) and "Unlock Icons" or "Lock Icons"
    local lockBtn = nil
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if shmIcons and shmIcons.ToggleLock then
            local locked = shmIcons:ToggleLock()
            if lockBtn then lockBtn:SetText(locked and "Unlock Icons" or "Lock Icons") end
        end
    end)
    lockBtn = anchor
    y = -4

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Saved Icons (this spec)")
    anchor = div2
    y = dy2

    local listContainer = CreateFrame("Frame", nil, parent)
    listContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    listContainer:SetSize(540, 0)

    local rows = {}
    local RebuildList

    local function QueueRebuild()
        C_Timer.After(0, function()
            if parent and parent:IsShown() then
                RebuildList()
            end
        end)
    end

    RebuildList = function()
        for _, row in ipairs(rows) do
            row:Hide()
            row:SetParent(nil)
        end
        rows = {}

        local specID = DAT.currentSpecID
        if specID == 0 then return end

        local specDB = DynamicActivationTracker_GetSpecDB(specID)
        if not specDB then return end

        local rowY = 0
        for spellIDStr, entry in pairs(specDB.icons) do
            local row = CreateFrame("Frame", nil, listContainer)
            row:SetSize(540, 94)
            row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)
            rowY = rowY + 96

            local spellID = tonumber(spellIDStr)
            local defaultOverride = spellID and DynamicActivationTracker_GetDefaultOverride(specID, spellID) or nil
            local displayName = spellID and DynamicActivationTracker_GetDisplayName(specID, spellID, entry) or (entry.label or entry.spellName or spellIDStr)
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
            icon:SetTexture(entry.override_icon or (defaultOverride and defaultOverride.icon) or entry.iconID or 134400)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            label:SetText((displayName or spellIDStr)
                .. " |cFF888888(plugin: "
                .. DynamicActivationTracker_MakePluginID(specID, spellID or spellIDStr)
                .. ")|r")
            label:SetTextColor(0.9, 0.95, 1, 1)

            local rmBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            rmBtn:SetSize(22, 18)
            rmBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
            rmBtn:SetText("X")
            rmBtn:SetScript("OnClick", function()
                if InCombatLockdown() then return end
                if spellID then
                    DynamicActivationTracker_RemoveTrackedSpell(specID, spellID, false)
                    QueueRebuild()
                end
            end)

            local ignoreBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            ignoreBtn:SetSize(48, 18)
            ignoreBtn:SetPoint("TOPRIGHT", rmBtn, "TOPLEFT", -6, 0)
            ignoreBtn:SetText("Ignore")
            ignoreBtn:SetScript("OnClick", function()
                if InCombatLockdown() then return end
                if spellID then
                    DynamicActivationTracker_RemoveTrackedSpell(specID, spellID, true)
                    QueueRebuild()
                end
            end)

            local showChk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            showChk:SetSize(20, 20)
            showChk:SetPoint("RIGHT", ignoreBtn, "LEFT", -12, -1)
            showChk:SetChecked(entry.enabled ~= false)
            showChk:SetScript("OnClick", function(self)
                entry.enabled = self:GetChecked() and true or false
                if spellID and specID == DAT.currentSpecID then
                    if entry.enabled then
                        DynamicActivationTracker_RefreshEntry(specID, spellID)
                    else
                        shmIcons:SetEnabled(DAT.ADDON_NAME, spellIDStr, false)
                        shmIcons:SetGlow(DAT.ADDON_NAME, spellIDStr, false)
                        shmIcons:SetVisible(DAT.ADDON_NAME, spellIDStr, false)
                    end
                end
            end)

            local showLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            showLbl:SetPoint("RIGHT", showChk, "LEFT", -2, 0)
            showLbl:SetText("Show")
            showLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local overrideLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            overrideLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 28, -34)
            overrideLbl:SetText("Override Icon:")
            overrideLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local overrideBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            overrideBox:SetPoint("LEFT", overrideLbl, "RIGHT", 6, 0)
            overrideBox:SetSize(84, 20)
            overrideBox:SetAutoFocus(false)
            overrideBox:SetNumeric(true)
            overrideBox:SetMaxLetters(10)
            overrideBox:SetText(
                entry.override_icon and tostring(entry.override_icon)
                or (defaultOverride and defaultOverride.icon and tostring(defaultOverride.icon))
                or "")
            overrideBox:SetCursorPosition(0)
            overrideBox:SetScript("OnEnterPressed", function(self)
                local val = tonumber(self:GetText())
                entry.override_icon = val
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RefreshEntry(specID, spellID)
                end
                RebuildList()
                self:ClearFocus()
            end)
            overrideBox:SetScript("OnEditFocusLost", function(self)
                local val = tonumber(self:GetText())
                entry.override_icon = val
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RefreshEntry(specID, spellID)
                end
                RebuildList()
            end)

            local timerLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timerLbl:SetPoint("LEFT", overrideBox, "RIGHT", 16, 0)
            timerLbl:SetText("Timer:")
            timerLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local timerBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            timerBox:SetPoint("LEFT", timerLbl, "RIGHT", 6, 0)
            timerBox:SetSize(56, 20)
            timerBox:SetAutoFocus(false)
            timerBox:SetNumeric(true)
            timerBox:SetMaxLetters(8)
            timerBox:SetText(
                entry.condition_timer and tostring(entry.condition_timer)
                or (defaultOverride and defaultOverride.timer and tostring(defaultOverride.timer))
                or "")
            timerBox:SetCursorPosition(0)
            timerBox:SetScript("OnEnterPressed", function(self)
                local val = tonumber(self:GetText())
                entry.condition_timer = val
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RegisterSBASEntry(specID, spellID)
                end
                self:ClearFocus()
            end)
            timerBox:SetScript("OnEditFocusLost", function(self)
                local val = tonumber(self:GetText())
                entry.condition_timer = val
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RegisterSBASEntry(specID, spellID)
                end
            end)

            local displayNameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            displayNameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 28, -60)
            displayNameLbl:SetText("Display Name:")
            displayNameLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local displayNameBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            displayNameBox:SetPoint("LEFT", displayNameLbl, "RIGHT", 6, 0)
            displayNameBox:SetSize(182, 20)
            displayNameBox:SetAutoFocus(false)
            displayNameBox:SetMaxLetters(64)
            displayNameBox:SetText(entry.display_name or (defaultOverride and defaultOverride.display_name) or "")
            displayNameBox:SetCursorPosition(0)
            displayNameBox:SetScript("OnEnterPressed", function(self)
                local val = (self:GetText() or ""):match("^%s*(.-)%s*$")
                entry.display_name = (val ~= "") and val or nil
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RefreshEntry(specID, spellID)
                end
                RebuildList()
                self:ClearFocus()
            end)
            displayNameBox:SetScript("OnEditFocusLost", function(self)
                local val = (self:GetText() or ""):match("^%s*(.-)%s*$")
                entry.display_name = (val ~= "") and val or nil
                if spellID and specID == DAT.currentSpecID then
                    DynamicActivationTracker_RefreshEntry(specID, spellID)
                end
                RebuildList()
            end)

            rows[#rows + 1] = row
            row:Show()
        end

        local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
        local ignoredCount = 0
        if removedDB and next(removedDB) then
            local header = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            header:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY - 8)
            header:SetText("IGNORED SPELLS")
            header:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            header:SetTextColor(0.4, 0.6, 0.8, 1.0)
            rows[#rows + 1] = header
            rowY = rowY + 28

            local line = listContainer:CreateTexture(nil, "OVERLAY")
            line:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)
            line:SetSize(540, 1)
            line:SetColorTexture(0.15, 0.25, 0.35, 0.8)
            rows[#rows + 1] = line
            rowY = rowY + 8

            for ignoredSpellIDStr, ignoredEntry in pairs(removedDB) do
                ignoredCount = ignoredCount + 1
                local ignoredSpellID = tonumber(ignoredSpellIDStr)
                local displayName = type(ignoredEntry) == "table"
                    and (ignoredEntry.display_name or ignoredEntry.label or ignoredEntry.spellName)
                    or nil
                local displayIcon = type(ignoredEntry) == "table" and ignoredEntry.iconID or nil

                local row = CreateFrame("Frame", nil, listContainer)
                row:SetSize(540, 24)
                row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(20, 20)
                icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
                icon:SetTexture(displayIcon or 134400)

                local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                label:SetText((displayName or ignoredSpellIDStr)
                    .. " |cFF888888(plugin: "
                    .. DynamicActivationTracker_MakePluginID(specID, ignoredSpellID or ignoredSpellIDStr)
                    .. ")|r")
                label:SetTextColor(0.9, 0.95, 1, 1)

                local unignoreBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                unignoreBtn:SetSize(22, 18)
                unignoreBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
                unignoreBtn:SetText("X")
                unignoreBtn:SetScript("OnClick", function()
                    if InCombatLockdown() then return end
                    if ignoredSpellID then
                        DynamicActivationTracker_UnignoreSpell(specID, ignoredSpellID)
                        QueueRebuild()
                    end
                end)

                rows[#rows + 1] = row
                row:Show()
                rowY = rowY + 26
            end
        end

        if rowY == 0 then
            local empty = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            empty:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, 0)
            empty:SetText("|cFFAAAAAANo tracked or ignored spells for this spec.|r")
            rows[#rows + 1] = empty
            rowY = 24
        elseif ignoredCount == 0 then
            local header = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            header:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY - 8)
            header:SetText("IGNORED SPELLS")
            header:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            header:SetTextColor(0.4, 0.6, 0.8, 1.0)
            rows[#rows + 1] = header
            rowY = rowY + 28

            local emptyIgnored = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            emptyIgnored:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)
            emptyIgnored:SetText("|cFFAAAAAANo ignored spells for this spec.|r")
            rows[#rows + 1] = emptyIgnored
            rowY = rowY + 24
        end

        listContainer:SetHeight(math.max(4, rowY))
    end

    local function RefreshPanel()
        RebuildList()
        if lockBtn and shmIcons and shmIcons.IsLocked then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end

    DAT.rebuildCombatCoachList = function()
        if parent:IsShown() then
            RefreshPanel()
        end
    end

    RebuildList()

    if not parent.__DATRefreshHooked then
        parent:HookScript("OnShow", RefreshPanel)
        parent.__DATRefreshHooked = true
    end

    C_Timer.After(0, function()
        if parent and parent:IsShown() then
            RefreshPanel()
        end
    end)
end

CombatCoach.Menu:RegisterAddon({
    id = "DynamicActivationTracker",
    name = "Dynamic Activation Tracker",
    icon = "Interface\\Icons\\spell_holy_layonhands",
    desc = "Data & Trackers based on Spell Glows.",
    OnBuildUI = OnBuildUI,
})