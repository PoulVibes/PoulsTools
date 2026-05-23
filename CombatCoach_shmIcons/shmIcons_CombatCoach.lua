-- shmIcons_CombatCoach.lua
-- CombatCoach integration for shmIcons.

if not CombatCoach then return end
if not shmIcons   then return end

-- Slot names for TrinketTracker entries (localID is the numeric slotID as a string)
local TRINKET_SLOT_NAMES = {
    [1]  = "Head",      [2]  = "Neck",      [3]  = "Shoulder",
    [4]  = "Shirt",     [5]  = "Chest",     [6]  = "Belt",
    [7]  = "Legs",      [8]  = "Feet",      [9]  = "Wrist",
    [10] = "Gloves",    [11] = "Ring 1",    [12] = "Ring 2",
    [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",  [18] = "Ranged",
    [19] = "Tabard",
}

local function OnBuildUI(parent)
    if parent.__SHMIconsPanelInitialized then
        if parent.__SHMIconsRefresh then parent.__SHMIconsRefresh() end
        return
    end

    local W = CombatCoach.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("CombatCoach.Widgets missing. Install CombatCoach to use this panel.")
        note:SetTextColor(1, 0.8, 0.2, 1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "shmIcons Controls")
    anchor = div
    y = dy

    local lockBtn = nil
    local function UpdateLockLabel()
        if lockBtn then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end

    anchor = W:Button(parent, anchor, y,
        shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons",
        function()
            local locked = shmIcons:ToggleLock()
            print("shmIcons: All icons " .. (locked and "|cFF00FF00Locked.|r" or "|cFFFFFF00Unlocked.|r"))
            UpdateLockLabel()
        end)
    lockBtn = anchor
    y = -8

    anchor = W:Button(parent, anchor, y, "Reset All Icons", function()
        local all = shmIcons:GetAll()
        for _, entry in ipairs(all) do
            shmIcons:ResetIcon(entry.addonName, entry.localID)
        end
        print("|cFF00FF00shmIcons:|r All icons reset to center.")
    end)
    y = -8

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "All Tracked Icons")
    anchor = div2
    y = dy2

    local listContainer = CreateFrame("Frame", nil, parent)
    listContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    listContainer:SetSize(540, 0)

    local activeRows = {}
    local listDirty = true

    local function BuildIconList()
        for _, f in ipairs(activeRows) do
            f:Hide()
        end
        activeRows = {}

        local allIcons = (shmIcons and shmIcons.GetAll) and shmIcons:GetAll() or {}

        table.sort(allIcons, function(a, b)
            local aAddon = tostring((a and a.addonName) or "")
            local bAddon = tostring((b and b.addonName) or "")
            if aAddon ~= bAddon then return aAddon < bAddon end
            local aLocalID = tostring((a and a.localID) or "")
            local bLocalID = tostring((b and b.localID) or "")
            return aLocalID < bLocalID
        end)

        local rowY      = 0
        local lastAddon = nil

        for _, entry in ipairs(allIcons) do
            local addonName = tostring(entry.addonName or "Unknown Addon")
            local localID   = tostring(entry.localID or "")

            -- Skip NP-clone icons (suffix "_np"): their enabled/glow state is
            -- driven each frame by the main icon and should not be user-editable.
            if localID ~= "" and localID:sub(-3) ~= "_np" then
            local icon      = entry.icon
            local db        = icon and icon.db

            if addonName ~= lastAddon then
                lastAddon = addonName

                local hdr = CreateFrame("Frame", nil, listContainer)
                hdr:SetSize(540, 20)
                hdr:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)

                local lbl = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                lbl:SetPoint("LEFT", hdr, "LEFT", 0, 0)
                lbl:SetText("|cFF7EC8E3" .. addonName .. "|r")

                hdr:Show()
                table.insert(activeRows, hdr)
                rowY = rowY + 20
            end

            local displayName = db and (db.spellName or db.itemName)
            if not displayName then
                local slotNum = tonumber(localID)
                if slotNum and TRINKET_SLOT_NAMES[slotNum] then
                    displayName = TRINKET_SLOT_NAMES[slotNum]
                else
                    displayName = localID:gsub("_", " ")
                end
            end

            local row = CreateFrame("Frame", nil, listContainer)
            row:SetSize(540, 26)
            row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -rowY)

            -- Left control: either an X remove button for registered (tracker) addons
            -- or an enable/disable checkbox for external addons. The right-side
            -- action will be a Glow button (created below).
            local capturedAddon = addonName
            local capturedID    = localID
            local capturedDB    = db

            local leftControl = nil
            local TRACKER_ADDON_NAMES = {
                ["Cooldown Tracker"] = true,
                ["Item Tracker"]     = true,
                ["Trinket Tracker"]  = true,
            }
            if TRACKER_ADDON_NAMES[capturedAddon] then
                local rem = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                rem:SetPoint("LEFT", row, "LEFT", 10, 0)
                rem:SetSize(26, 20)
                rem:SetText("X")
                rem:SetScript("OnClick", function()
                    if capturedAddon == "CombatCoach_CooldownTracker" then
                        local spellName = capturedDB and capturedDB.spellName
                        if spellName and type(CooldownTracker_Remove) == "function" then
                            CooldownTracker_Remove(spellName)
                        end
                    elseif capturedAddon == "CombatCoach_ItemTracker" then
                        local itemName = capturedDB and capturedDB.itemName
                        if itemName and type(ItemTracker_Remove) == "function" then
                            ItemTracker_Remove(itemName)
                        end
                    elseif capturedAddon == "CombatCoach_TrinketTracker" then
                        local slotNum = tonumber(capturedID)
                        if slotNum and type(TrinketTracker_Remove) == "function" then
                            TrinketTracker_Remove(slotNum)
                        end
                    else
                        if shmIcons and shmIcons.Unregister then
                            shmIcons:Unregister(capturedAddon, capturedID)
                        end
                    end
                    BuildIconList()
                end)
                leftControl = rem
            else
                local chk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                chk:SetPoint("LEFT", row, "LEFT", 10, 0)
                chk:SetSize(22, 22)
                local isEnabled = false
                if shmIcons and shmIcons.IsEnabled then isEnabled = shmIcons:IsEnabled(capturedAddon, capturedID) end
                chk:SetChecked(isEnabled)
                chk:SetScript("OnClick", function(self)
                    if shmIcons and shmIcons.ToggleEnabled then
                        local enabled = shmIcons:ToggleEnabled(capturedAddon, capturedID)
                        if capturedDB then capturedDB.enabled = enabled end
                    end
                    -- If this is SBA_Simple, also make sure its own helper stays in sync
                    if capturedAddon == "CombatCoach_SBA_Simple" and type(SBA_Simple_SetEnabled) == "function" then
                        SBA_Simple_SetEnabled(capturedDB and capturedDB.enabled)
                    end
                end)
                leftControl = chk
            end

            local iconTex = row:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(20, 20)
            iconTex:SetPoint("LEFT", leftControl, "RIGHT", 6, 0)
            iconTex:SetTexture(
                (icon and icon.iconTex and icon.iconTex:GetTexture()) or 134400)

            local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLbl:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
            nameLbl:SetText(displayName)
            nameLbl:SetTextColor(unpack(W.colors.text))

            if capturedAddon == "Cooldown Tracker" then
                local optBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                optBtn:SetSize(70, 20)
                optBtn:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                optBtn:SetText("Options")
                optBtn:SetScript("OnClick", function()
                    if type(CooldownTracker_OpenLookAndFeel) == "function" then
                        CooldownTracker_OpenLookAndFeel(capturedID)
                    end
                end)
            else
                local glowBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                glowBtn:SetSize(80, 20)
                glowBtn:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                glowBtn:SetText("Glow")
                glowBtn:SetScript("OnClick", function()
                    if shmIcons and shmIcons.ToggleGlowEnabled then
                        local enabled = shmIcons:ToggleGlowEnabled(capturedAddon, capturedID)
                        if capturedDB then capturedDB.glow_enabled = enabled end
                    end
                end)

                -- Failure Sound toggle: only for the Hit Combo icon
                if capturedAddon == "Combo Tracker" and capturedID == "Hit Combo" then
                    local sndChk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    sndChk:SetSize(22, 22)
                    sndChk:SetPoint("LEFT", glowBtn, "RIGHT", 6, 0)
                    sndChk:SetChecked(ComboTrackerDB and ComboTrackerDB.failureSound or false)
                    sndChk:SetScript("OnClick", function(self)
                        if ComboTrackerDB then ComboTrackerDB.failureSound = self:GetChecked() end
                    end)

                    local sndLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    sndLbl:SetPoint("LEFT", sndChk, "RIGHT", 2, 0)
                    sndLbl:SetText("Sound")
                    sndLbl:SetTextColor(unpack(W.colors.textMuted))

                    sndChk:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText("Failure Sound", 1, 1, 1)
                        GameTooltip:AddLine("Play the Quest Failed sound when the same ability breaks your Combo Strike streak.", nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    sndChk:SetScript("OnLeave", function() GameTooltip:Hide() end)

                end
            end

            row:Show()
            table.insert(activeRows, row)
            rowY = rowY + 26
            end -- if localID:sub(-3) ~= "_np"
        end

        if #allIcons == 0 then
            local emptyRow = CreateFrame("Frame", nil, listContainer)
            emptyRow:SetSize(540, 26)
            emptyRow:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, 0)
            local lbl = emptyRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", emptyRow, "LEFT", 10, 0)
            lbl:SetText("|cFFAAAAAA(No icons are currently registered)|r")
            emptyRow:Show()
            table.insert(activeRows, emptyRow)
            rowY = 26
        end

        listContainer:SetHeight(rowY)
        listDirty = false
    end

    BuildIconList()

    local function MarkListDirty()
        listDirty = true
        if parent:IsShown() then
            BuildIconList()
        end
    end

    if not parent.__SHMIconsListenersRegistered then
        if type(CooldownTracker_RegisterChangeListener) == "function" then
            CooldownTracker_RegisterChangeListener(MarkListDirty)
        end
        if type(ItemTracker_RegisterChangeListener) == "function" then
            ItemTracker_RegisterChangeListener(MarkListDirty)
        end
        if type(TrinketTracker_RegisterChangeListener) == "function" then
            TrinketTracker_RegisterChangeListener(MarkListDirty)
        end
        parent.__SHMIconsListenersRegistered = true
    end

    parent.__SHMIconsRefresh = function()
        if listDirty then
            BuildIconList()
        end
        UpdateLockLabel()
    end
    if not parent.__SHMIconsRefreshHooked then
        parent:HookScript("OnShow", function(self)
            if self.__SHMIconsRefresh then self.__SHMIconsRefresh() end
        end)
        parent.__SHMIconsRefreshHooked = true
    end
    if parent.__SHMIconsRefresh then parent.__SHMIconsRefresh() end
    parent.__SHMIconsPanelInitialized = true
end

CombatCoach.Menu:RegisterMainPanelContent(OnBuildUI)
