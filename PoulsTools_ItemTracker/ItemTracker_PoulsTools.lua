-- ItemTracker_PoulsTools.lua
-- PoulsTools integration for ItemTracker

if not PoulsTools then return end

ItemTrackerDB = ItemTrackerDB or {}

local ADDON_NAME = "PoulsTools_ItemTracker"

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("PoulsTools.Widgets missing. Install PoulsTools to configure ItemTracker here.")
        note:SetTextColor(1,0.8,0.2,1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "PoulsTools_ItemTracker")
    anchor = div
    y = dy

    local input = ""
    local edit = W:EditBox(parent, anchor, y, "Add / Remove Item", "e.g. Healthstone or 5512",
        function() return input end,
        function(val) input = val end)
    anchor = edit
    y = -8

    local btn = W:Button(parent, anchor, y, "Add Tracker", function()
        local val = input
        if edit and edit.box then
            val = edit.box:GetText()
            if edit.placeholder and val == edit.placeholder then val = "" end
        end
        if not val or val:trim() == "" then print("|cFFFF0000ItemTracker: enter item name or ID.|r"); return end

        if type(ItemTracker_HandleCommand) == "function" then
            ItemTracker_HandleCommand(val)
        elseif type(ItemTracker_Add) == "function" then
            ItemTracker_Add(val, nil)
        else
            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                SlashCmdList["ITEMTRACKER"](val)
            end
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
        if not val or val:trim() == "" then print("|cFFFF0000ItemTracker: enter item name or ID.|r"); return end

        if type(ItemTracker_Remove) == "function" then
            ItemTracker_Remove(val)
        else
            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                SlashCmdList["ITEMTRACKER"](val)
            end
        end

        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Tracked Items")
    anchor = div2
    y = dy2

    local trackedContainer = CreateFrame("Frame", nil, parent)
    trackedContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    trackedContainer:SetSize(540, 0)

    local trackedRows = {}
    local actionsHeaderFrame = nil

    local function BuildTrackedList()
        local specIndex = GetSpecialization()
        local specID = 0
        if specIndex then specID = select(1, GetSpecializationInfo(specIndex)) end

        local items = nil
        local trackedList = nil
        if type(ItemTracker_GetTrackedItems) == "function" then
            trackedList = ItemTracker_GetTrackedItems(specID)
        end
        if trackedList and #trackedList > 0 then
            items = {}
            for _, entry in ipairs(trackedList) do
                if entry and entry.key and entry.db then
                    items[entry.key] = entry.db
                    items[entry.key].itemName = items[entry.key].itemName or entry.itemName
                    items[entry.key].itemID   = items[entry.key].itemID   or entry.itemID
                end
            end
        else
            items = (ItemTrackerDB and ItemTrackerDB.specs and ItemTrackerDB.specs[specID] and ItemTrackerDB.specs[specID].items) or {}
        end

        local count = 0
        local used = {}
        for key, db in pairs(items) do
            if db and db.enabled and db.itemID then
                count = count + 1
                local row = trackedRows[key]
                if not row then
                    row = CreateFrame("Frame", nil, trackedContainer)
                    row:SetSize(540, 26)

                    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    row.check:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.check:SetSize(22, 22)

                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(20, 20)
                    row.icon:SetPoint("LEFT", row.check, "RIGHT", 6, 0)

                    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.name:SetTextColor(unpack(W.colors.text))

                    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.remove:SetSize(80, 20)
                    row.remove:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                    row.remove:SetText("Remove")
                    row.remove:SetScript("OnClick", function()
                        local item = row.itemName
                        if not item or item:trim() == "" then return end
                        if type(ItemTracker_Remove) == "function" then
                            ItemTracker_Remove(item)
                        else
                            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                                SlashCmdList["ITEMTRACKER"](item)
                            end
                        end
                    end)
                end

                row.check:SetChecked(db.glow_enabled)
                row.check:SetScript("OnClick", function(self)
                    local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, key)
                    db.glow_enabled = enabled
                end)

                local name = db.itemName or tostring(db.itemID)
                local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(db.itemID)
                row.icon:SetTexture(texture or 134400)
                row.itemName = name
                row.name:SetText(name)

                row:SetPoint("TOPLEFT", trackedContainer, "TOPLEFT", 0, -(count - 1) * 26)
                row:Show()
                trackedRows[key] = row
                used[key] = true
            end
        end

        for k, r in pairs(trackedRows) do
            if not used[k] then
                r:Hide()
                trackedRows[k] = nil
            end
        end

        trackedContainer:SetHeight(count * 26)

        if actionsHeaderFrame and actionsHeaderFrame.SetPoint then
            actionsHeaderFrame:SetPoint("TOPLEFT", trackedContainer, "BOTTOMLEFT", 0, -6)
        end
    end

    BuildTrackedList()

    if type(ItemTracker_RegisterChangeListener) == "function" then
        ItemTracker_RegisterChangeListener(BuildTrackedList)
    end

    local div3, dy3 = W:SectionHeader(parent, trackedContainer, -6, "Actions")
    actionsHeaderFrame = div3
    anchor = div3
    y = dy3

    btn = W:Button(parent, anchor, y, "Reset Selected (use input box)", function()
        local val = input
        if edit and edit.box then
            val = edit.box:GetText()
            if edit.placeholder and val == edit.placeholder then val = "" end
        end
        if not val or val:trim() == "" then print("|cFFFF0000ItemTracker: enter item name.|r"); return end
        if type(ItemTracker_HandleCommand) == "function" then
            ItemTracker_HandleCommand("reset " .. val)
        elseif type(ItemTracker_Reset) == "function" then
            ItemTracker_Reset(val)
        else
            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                SlashCmdList["ITEMTRACKER"]("reset " .. val)
            end
        end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    btn = W:Button(parent, anchor, y, "Reset All", function()
        if type(ItemTracker_HandleCommand) == "function" then
            ItemTracker_HandleCommand("reset all")
        elseif type(ItemTracker_ResetAll) == "function" then
            ItemTracker_ResetAll()
        else
            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                SlashCmdList["ITEMTRACKER"]("reset all")
            end
        end
    end)
    anchor = btn
    y = -8

    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if type(ItemTracker_ToggleLock) == "function" then
            local locked = ItemTracker_ToggleLock()
            local nextLabel = locked and "Unlock Icons" or "Lock Icons"
            if lockBtn then lockBtn:SetText(nextLabel) end
        else
            local locked = shmIcons:ToggleLock()
            local nextLabel = locked and "Unlock Icons" or "Lock Icons"
            if lockBtn then lockBtn:SetText(nextLabel) end
        end
    end)
    lockBtn = anchor
    y = -8

    btn = W:Button(parent, anchor, y, "Print List", function()
        if type(ItemTracker_HandleCommand) == "function" then
            ItemTracker_HandleCommand("list")
        elseif type(ItemTracker_List) == "function" then
            ItemTracker_List()
        else
            if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
                SlashCmdList["ITEMTRACKER"]("list")
            end
        end
    end)
    anchor = btn

    parent:HookScript("OnShow", function()
        if lockBtn and shmIcons and shmIcons.IsLocked then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end)
end

PoulsTools.Menu:RegisterAddon({
    name      = "PoulsTools_ItemTracker",
    id        = "PoulsTools_ItemTracker",
    desc      = "Track inventory items per specialization.",
    version   = "1.0.0",
    icon      = "Interface\\Icons\\inv_misc_bag_01",
    parentId  = "PoulsTools_shmIcons",
    OnBuildUI = OnBuildUI,
})
