-- TriggerTracker_CombatCoach.lua
-- CombatCoach settings submenu for TriggerTracker.

if not CombatCoach then return end

local TT = TriggerTracker

local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
    if not W then return end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "Trigger Tracker")
    anchor = div
    y = dy

    -- "Add New Trigger" button
    local addBtn = W:Button(parent, anchor, y, "+ Add Trigger", function()
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        TriggerTracker_OpenCreationFrame()
    end)
    anchor = addBtn
    y = -4

    -- Lock / Unlock icons button
    local lockBtn = nil
    local function UpdateLock()
        if lockBtn then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end
    anchor = W:Button(parent, anchor, y,
        shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons",
        function()
            local locked = shmIcons:ToggleLock()
            print("shmIcons: All icons " .. (locked and "|cFF00FF00Locked.|r" or "|cFFFFFF00Unlocked.|r"))
            UpdateLock()
        end)
    lockBtn = anchor
    y = -8

    -- Trigger list section
    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Triggers (this spec)")
    anchor = div2
    y = dy2

    local listContainer = CreateFrame("Frame", nil, parent)
    listContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    listContainer:SetSize(540, 0)

    local rows     = {}
    local rowCount = 0

    local function RebuildList()
        for _, r in ipairs(rows) do r:Hide() end
        rows     = {}
        rowCount = 0

        local specID = TT.currentSpecID
        if specID == 0 then return end

        TriggerTracker_ForEachTrigger(specID, function(idx, entry)
            rowCount = rowCount + 1
            local r = CreateFrame("Frame", nil, listContainer)
            r:SetSize(540, 48)
            r:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -(rowCount - 1) * 52)

            local iconTex = r:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(36, 36)
            iconTex:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -6)
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            local iconID = entry.iconID or 134400
            if entry.buffSpellID then
                local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(entry.buffSpellID)
                if si and si.iconID then iconID = si.iconID end
            end
            iconTex:SetTexture(iconID)

            local nameLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLbl:SetPoint("TOPLEFT", iconTex, "TOPRIGHT", 8, -2)
            nameLbl:SetText(entry.name or ("Trigger " .. idx))
            nameLbl:SetTextColor(0.85, 0.92, 1, 1)

            local metaLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            metaLbl:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -2)
            local genCount   = 0
            local spendCount = 0
            if entry.generators then for _ in pairs(entry.generators) do genCount = genCount + 1 end end
            if entry.spenders   then for _ in pairs(entry.spenders)   do spendCount = spendCount + 1 end end
            metaLbl:SetText(string.format(
                "Max: %d stacks  |  Timer: %ss  |  Gen: %d  |  Spend: %d",
                entry.maxStacks or 5,
                tostring(entry.timer or 0),
                genCount,
                spendCount))
            metaLbl:SetTextColor(0.55, 0.65, 0.75, 1)

            -- Edit button
            local editBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
            editBtn:SetSize(52, 22)
            editBtn:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -6)
            editBtn:SetText("Edit")
            local captureIdx   = idx
            local captureEntry = entry
            editBtn:SetScript("OnClick", function()
                if SettingsPanel and SettingsPanel:IsShown() then
                    HideUIPanel(SettingsPanel)
                end
                TriggerTracker_OpenEditFrame(specID, captureIdx, TriggerTracker_CopyEntry(captureEntry))
            end)

            -- Delete button
            local delBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
            delBtn:SetSize(52, 22)
            delBtn:SetPoint("RIGHT", editBtn, "LEFT", -4, 0)
            delBtn:SetText("X")
            delBtn:SetScript("OnClick", function()
                TriggerTracker_RemoveTrigger(specID, captureIdx)
                TriggerTracker_RefreshSBASConditions(specID)
                RebuildList()
            end)

            -- Enable/disable toggle
            local enableChk = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
            enableChk:SetSize(20, 20)
            enableChk:SetPoint("RIGHT", delBtn, "LEFT", -6, 0)
            enableChk:SetChecked(entry.enabled ~= false)
            enableChk:SetScript("OnClick", function(self)
                entry.enabled = self:GetChecked() and true or false
                shmIcons:SetEnabled(TT.ADDON_NAME, TriggerTracker_MakeKey(specID, captureIdx), entry.enabled)
                TT.spellMap = TriggerTracker_BuildSpellMap(specID)
            end)
            enableChk:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Enable this trigger", 1, 1, 1)
                GameTooltip:Show()
            end)
            enableChk:SetScript("OnLeave", function() GameTooltip:Hide() end)

            table.insert(rows, r)
        end)

        listContainer:SetHeight(math.max(1, rowCount * 52))
    end

    TT.rebuildCombatCoachList = RebuildList
    RebuildList()
end

CombatCoach.Menu:RegisterAddon({
    id        = "TriggerTracker",
    name      = "Trigger Tracker",
    desc      = "Manually Configured Trackers for Rotation Assistant",
    version   = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("CombatCoach_TriggerTracker", "Version")) or "1.0.5",
    icon      = "Interface\\Icons\\inv_gizmo_goblingtonkcontroller",
    OnBuildUI = OnBuildUI,
})
