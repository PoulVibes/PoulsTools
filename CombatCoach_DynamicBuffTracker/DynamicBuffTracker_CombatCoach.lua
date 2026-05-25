-- DynamicBuffTracker_CombatCoach.lua
-- CombatCoach settings panel for DynamicBuffTracker.

if not CombatCoach then return end

local DBT = DynamicBuffTracker

local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
    if not W then return end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "Dynamic Buff Tracker")
    anchor = div
    y = dy

    local hideBarChk = W:Checkbox(parent, anchor, y,
        "Hide Blizzard Buff Icon Bar",
        "Sets the Blizzard BuffIconCooldownViewer alpha to 0, hiding it while"
            .. " Dynamic Buff Tracker continues to read it in the background.",
        function() return DynamicBuffTrackerDB and DynamicBuffTrackerDB.hideCDMBar == true end,
        function(val)
            DynamicBuffTrackerDB.hideCDMBar = val
            DynamicBuffTracker_ApplyCDMBarVisibility()
        end)
    anchor = hideBarChk
    y = -4

    local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y - 4)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    note:SetTextColor(0.72, 0.82, 0.92, 1)
    note:SetText(
        "Discovers spells tracked in Blizzard's CooldownManager (BuffIconCooldownViewer) "
        .. "and allows the user to use conditions in the rotation helper based on the buffs. "
        .. "Add buff icons in the CooldownManager settings, Trigger buffs at least once. "
        .. "then click Scan Now (or change talents) to update.")
    anchor = note
    y = -8

    local openCDMBtn = W:Button(parent, anchor, y, "Blizz Cooldown Manager", function()
        local function OpenCooldownManager()
            if not CooldownViewerSettings then
                local okLoad = pcall(UIParentLoadAddOn, "Blizzard_CooldownViewer")
                if not okLoad then
                    print("|cFFFF4444DynamicBuffTracker: Could not load Blizzard_CooldownViewer.|r")
                    return
                end
            end

            if CooldownViewerSettings then
                if CooldownViewerSettings:IsShown() then
                    CooldownViewerSettings:Show()
                elseif CooldownViewerSettings.TogglePanel then
                    CooldownViewerSettings:TogglePanel()
                else
                    print("|cFFFF4444DynamicBuffTracker: Cooldown Manager UI is unavailable.|r")
                end
            else
                print("|cFFFF4444DynamicBuffTracker: Cooldown Manager UI is unavailable.|r")
            end
        end

        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
            C_Timer.After(0, OpenCooldownManager)
        else
            OpenCooldownManager()
        end
    end)
    openCDMBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("How to make DBT shmIcons appear", 1, 1, 1)
        GameTooltip:AddLine(
            "1) Click this button to open Blizzard's Cooldown Manager.\n"
            .. "2) Open the Buffs Tab.\n"
            .. "3) Add the buff you want track to the icons section.\n"
            .. "4) Trigger any buffs you want to track at least once.\n"
            .. "5) Return here and click Scan Now (or type /dbt scan).\n"
            .. "DBT only mirrors entries that exist in Blizzard's viewer.",
            nil, nil, nil, true)
        GameTooltip:Show()
    end)
    openCDMBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    anchor = openCDMBtn
    y = -4

    anchor = W:Button(parent, anchor, y, "Scan Now", function()
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot scan in combat.|r")
            return
        end
        DBT.retryCount   = 0
        DBT.retryPending = false
        DynamicBuffTracker_ScanAndSync()
        print("|cFF00FF00DynamicBuffTracker: Scan complete.|r")
    end)
    y = -4

    anchor = W:Button(parent, anchor, y, "Clear This Spec", function()
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot clear in combat.|r")
            return
        end
        DynamicBuffTracker_UnloadSpec()
        if DynamicBuffTrackerDB and DynamicBuffTrackerDB.specs then
            DynamicBuffTrackerDB.specs[DBT.currentSpecID] = nil
        end
        print("|cFFFFFF00DynamicBuffTracker: Cleared all tracked buffs for this spec.|r")
        if DBT.rebuildCombatCoachList then DBT.rebuildCombatCoachList() end
    end)
    y = -4

    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if shmIcons and shmIcons.ToggleLock then
            local locked = shmIcons:ToggleLock()
            if lockBtn then lockBtn:SetText(locked and "Unlock Icons" or "Lock Icons") end
        end
    end)
    lockBtn = anchor
    y = -4

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Tracked Talents (this spec)")
    anchor = div2
    y = dy2

    local listContainer = CreateFrame("Frame", nil, parent)
    listContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    listContainer:SetSize(540, 0)

    local rows     = {}
    local rowCount = 0

    local function RebuildList()
        for _, r in pairs(rows) do r:Hide() end
        rows     = {}
        rowCount = 0
        if DBT.currentSpecID == 0 then return end
        local buffDB  = DynamicBuffTracker_GetSpecBuffDB(DBT.currentSpecID)
        local ADDON   = DBT.ADDON_NAME
        local specID  = DBT.currentSpecID

        for spellIDStr, entry in pairs(buffDB) do
            rowCount = rowCount + 1
            local r = CreateFrame("Frame", nil, listContainer)
            r:SetSize(540, 50)
            r:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -(rowCount - 1) * 52)

            local spellID = tonumber(spellIDStr)
            local displayIconID = entry.iconID
            local displayLabel  = entry.label
            if spellID then
                local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and spellInfo then ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name) end
                if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                if ok and spellInfo then
                    if spellInfo.iconID then displayIconID = spellInfo.iconID end
                    if spellInfo.name   then displayLabel  = spellInfo.name  end
                end
            end
            local icon = r:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -1)
            icon:SetTexture(displayIconID)

            local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            lbl:SetText(displayLabel
                .. " |cFF888888(plugin: "
                .. (spellID and DynamicBuffTracker_MakePluginID(specID, spellID) or spellIDStr)
                .. ")|r")
            lbl:SetTextColor(0.9, 0.95, 1, 1)

            local rmBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
            rmBtn:SetSize(22, 18)
            rmBtn:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -2)
            rmBtn:SetText("X")
            do
                local capturedSpellID = tonumber(spellIDStr)
                rmBtn:SetScript("OnClick", function()
                    if InCombatLockdown() then return end
                    if capturedSpellID then
                        DynamicBuffTracker_UnregisterIcon(capturedSpellID)
                        DynamicBuffTracker_UnregisterSBASEntry(specID, capturedSpellID)
                        _G[DynamicBuffTracker_MakeActiveFlag(specID, capturedSpellID)] = false
                        local sid = tostring(capturedSpellID)
                        DBT.trackedSpells[sid] = nil
                        buffDB[sid]            = nil
                        DynamicBuffTracker_GetSpecRemovedDB(specID)[sid] = true
                    end
                    RebuildList()
                end)
            end

            local cdTextChk = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
            cdTextChk:SetSize(20, 20)
            cdTextChk:SetPoint("RIGHT", rmBtn, "LEFT", -6, 0)
            cdTextChk:SetChecked(not (entry.hide_cooldown_text))
            cdTextChk:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Show Cooldown Text", 1, 1, 1)
                GameTooltip:AddLine(
                    "Show or hide the countdown number on this buff icon.",
                    nil, nil, nil, true)
                GameTooltip:Show()
            end)
            cdTextChk:SetScript("OnLeave", function() GameTooltip:Hide() end)
            do
                local capturedEntry    = entry
                local capturedSpellID2 = spellID
                cdTextChk:SetScript("OnClick", function(self)
                    capturedEntry.hide_cooldown_text = not self:GetChecked()
                    if capturedSpellID2 then
                        pcall(shmIcons.SetHideCooldownText, shmIcons, ADDON,
                            DynamicBuffTracker_MakeKey(capturedSpellID2),
                            capturedEntry.hide_cooldown_text)
                    end
                end)
            end

            local cdTextLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cdTextLbl:SetPoint("RIGHT", cdTextChk, "LEFT", -2, 0)
            cdTextLbl:SetText("Timer")
            cdTextLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local enableChk = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
            enableChk:SetSize(20, 20)
            enableChk:SetPoint("RIGHT", cdTextLbl, "LEFT", -10, 0)
            enableChk:SetChecked(entry.enabled == true)
            enableChk:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Show Icon", 1, 1, 1)
                GameTooltip:AddLine(
                    "Enable or disable the visible shmIcon for this buff.\n"
                    .. "The SBAS condition flag is always tracked regardless.",
                    nil, nil, nil, true)
                GameTooltip:Show()
            end)
            enableChk:SetScript("OnLeave", function() GameTooltip:Hide() end)
            do
                local capturedSpellID4 = spellID
                local capturedSpecID4  = specID
                enableChk:SetScript("OnClick", function(self)
                    if not capturedSpellID4 then return end
                    local nowEnabled = self:GetChecked() and true or false
                    local key = DynamicBuffTracker_MakeKey(capturedSpellID4)
                    pcall(shmIcons.SetEnabled, shmIcons, ADDON, key, nowEnabled)
                    if nowEnabled then
                        DynamicBuffTracker_SyncIconFromCDMFrame(capturedSpellID4, capturedSpecID4)
                    end
                end)
            end

            local enableLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            enableLbl:SetPoint("RIGHT", enableChk, "LEFT", -2, 0)
            enableLbl:SetText("Show")
            enableLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            -- Icon Override input
            local iconOvrLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            iconOvrLbl:SetPoint("TOPLEFT", r, "TOPLEFT", 26, -32)
            iconOvrLbl:SetText("Icon Override:")
            iconOvrLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local iconOvrBox = CreateFrame("EditBox", nil, r, "InputBoxTemplate")
            iconOvrBox:SetPoint("TOPLEFT", r, "TOPLEFT", 116, -27)
            iconOvrBox:SetSize(110, 20)
            iconOvrBox:SetAutoFocus(false)
            iconOvrBox:SetNumeric(true)
            iconOvrBox:SetMaxLetters(10)
            local dbtDef = DynamicBuffTracker_Defaults and spellID and DynamicBuffTracker_Defaults[spellID]
            iconOvrBox:SetText(
                entry.override_icon and tostring(entry.override_icon)
                or (dbtDef and dbtDef.icon and tostring(dbtDef.icon))
                or "")
            iconOvrBox:SetCursorPosition(0)
            do
                local capturedEntry5 = entry
                local capturedSpellID5 = spellID
                local function applyIconOverride(self)
                    local val = tonumber(self:GetText())
                    capturedEntry5.override_icon = val
                    if capturedSpellID5 then
                        local key5 = DynamicBuffTracker_MakeKey(capturedSpellID5)
                        local useIcon = val or capturedEntry5.iconID
                        pcall(shmIcons.SetIcon, shmIcons, ADDON, key5, useIcon)
                    end
                end
                iconOvrBox:SetScript("OnEnterPressed", function(self)
                    applyIconOverride(self)
                    self:ClearFocus()
                end)
                iconOvrBox:SetScript("OnEditFocusLost", applyIconOverride)
            end

            -- Buff Timer input
            local buffTimerLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            buffTimerLbl:SetPoint("TOPLEFT", r, "TOPLEFT", 244, -32)
            buffTimerLbl:SetText("Condition Timer:")
            buffTimerLbl:SetTextColor(0.72, 0.82, 0.92, 1)

            local buffTimerBox = CreateFrame("EditBox", nil, r, "InputBoxTemplate")
            buffTimerBox:SetPoint("TOPLEFT", r, "TOPLEFT", 344, -27)
            buffTimerBox:SetSize(80, 20)
            buffTimerBox:SetAutoFocus(false)
            buffTimerBox:SetNumeric(true)
            buffTimerBox:SetMaxLetters(6)
            buffTimerBox:SetText(
                entry.buff_timer and tostring(entry.buff_timer)
                or (dbtDef and dbtDef.timer and tostring(dbtDef.timer))
                or "")
            buffTimerBox:SetCursorPosition(0)
            do
                local capturedEntry6 = entry
                local capturedSpellID6 = spellID
                local capturedSpecID6 = specID
                local function applyBuffTimer(self)
                    local val = tonumber(self:GetText())
                    capturedEntry6.buff_timer = val
                    -- refresh SBAS registry entry for this spell so GUI knows about timerVar
                    DynamicBuffTracker_RegisterSBASEntry(capturedSpecID6, capturedSpellID6, capturedEntry6.label)
                    -- restart condition timer if the icon is currently shown
                    if DBT.iconShown and DBT.iconShown[tostring(capturedSpellID6)] then
                        DynamicBuffTracker_StartBuffTimer(capturedSpecID6, capturedSpellID6, val)
                    end
                end
                buffTimerBox:SetScript("OnEnterPressed", function(self)
                    applyBuffTimer(self)
                    self:ClearFocus()
                end)
                buffTimerBox:SetScript("OnEditFocusLost", applyBuffTimer)
            end

            r:Show()
            rows[spellIDStr] = r
        end

        listContainer:SetHeight(math.max(4, rowCount * 52))
    end

    DBT.rebuildCombatCoachList = function()
        if listContainer:IsVisible() then RebuildList() end
    end
    RebuildList()

    local canvasFrame = parent
    while canvasFrame:GetParent() and canvasFrame:GetParent() ~= UIParent do
        canvasFrame = canvasFrame:GetParent()
    end
    canvasFrame:HookScript("OnShow", function()
        RebuildList()
        if lockBtn and shmIcons and shmIcons.IsLocked then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end)
end

CombatCoach.Menu:RegisterAddon({
    id        = "DynamicBuffTracker",
    name      = "Dynamic Buff Tracker",
    icon      = "Interface\\Icons\\inv_misc_eye_02",
    desc      = "Buffs mirroring Blizz cooldown manager.",
    OnBuildUI = OnBuildUI,
})
