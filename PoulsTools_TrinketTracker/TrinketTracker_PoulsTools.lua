-- TrinketTracker_PoulsTools.lua
-- PoulsTools integration for TrinketTracker

if not PoulsTools then return end

TrinketTrackerDB = TrinketTrackerDB or {}

local SLOT_NAMES = {
    [1]  = "Head",      [2]  = "Neck",      [3]  = "Shoulder",
    [4]  = "Shirt",     [5]  = "Chest",     [6]  = "Belt",
    [7]  = "Legs",      [8]  = "Feet",      [9]  = "Wrist",
    [10] = "Gloves",    [11] = "Ring 1",    [12] = "Ring 2",
    [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",  [18] = "Ranged",
    [19] = "Tabard",
}

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("PoulsTools.Widgets missing. Install PoulsTools to configure TrinketTracker here.")
        note:SetTextColor(1, 0.8, 0.2, 1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "PoulsTools_TrinketTracker")
    anchor = div
    y = dy

    local input = ""
    local edit = W:EditBox(parent, anchor, y, "Add / Remove Slot", "e.g. 13 (Trinket 1), 14 (Trinket 2), 16 (Main Hand)",
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
        if not val or val:trim() == "" then
            print("|cFFFF0000TrinketTracker: enter a slot number (1-19).|r")
            return
        end
        local slotID = tonumber(val:trim())
        if not slotID or slotID < 1 or slotID > 19 then
            print("|cFFFF0000TrinketTracker: slot must be a number between 1 and 19.|r")
            return
        end
        if type(TrinketTracker_Add) == "function" then
            TrinketTracker_Add(slotID)
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
        if not val or val:trim() == "" then
            print("|cFFFF0000TrinketTracker: enter a slot number (1-19).|r")
            return
        end
        local slotID = tonumber(val:trim())
        if not slotID then
            print("|cFFFF0000TrinketTracker: slot must be a number.|r")
            return
        end
        if type(TrinketTracker_Remove) == "function" then
            TrinketTracker_Remove(slotID)
        end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    local div2, dy2 = W:SectionHeader(parent, anchor, y, "Tracked Slots")
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

        -- Prefer the public API; fallback to reading DB directly
        local slots = nil
        local trackedList = nil
        if type(TrinketTracker_GetTrackedSlots) == "function" then
            trackedList = TrinketTracker_GetTrackedSlots(specID)
        end
        if trackedList and #trackedList > 0 then
            slots = {}
            for _, entry in ipairs(trackedList) do
                if entry and entry.key and entry.db then
                    slots[entry.key] = entry.db
                    slots[entry.key].slotID   = slots[entry.key].slotID   or entry.slotID
                    slots[entry.key].slotName = slots[entry.key].slotName or entry.slotName
                end
            end
        else
            local raw = (TrinketTrackerDB and TrinketTrackerDB.specs
                         and TrinketTrackerDB.specs[specID]
                         and TrinketTrackerDB.specs[specID].slots) or {}
            slots = {}
            for slotID, db in pairs(raw) do
                if db.enabled then
                    slots[tostring(slotID)] = db
                    slots[tostring(slotID)].slotID   = slotID
                    slots[tostring(slotID)].slotName = SLOT_NAMES[slotID] or ("Slot " .. slotID)
                end
            end
        end

        local count = 0
        local used = {}
        for key, db in pairs(slots) do
            if db.enabled then
                count = count + 1
                local row = trackedRows[key]
                if not row then
                    row = CreateFrame("Frame", nil, trackedContainer)
                    row:SetSize(540, 26)

                    -- Glow toggle checkbox
                    row.removeLeft = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.removeLeft:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.removeLeft:SetSize(26, 20)
                    row.removeLeft:SetText("X")

                    -- Equipment slot icon
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(20, 20)
                    row.icon:SetPoint("LEFT", row.removeLeft, "RIGHT", 6, 0)

                    -- Slot name label
                    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.name:SetTextColor(unpack(W.colors.text))

                    -- Per-row Remove button
                    row.glowBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.glowBtn:SetSize(80, 20)
                    row.glowBtn:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                    row.glowBtn:SetText("Glow")
                    row.glowBtn:SetScript("OnClick", function()
                        local id = row.slotID
                        if not id then return end
                        if row.db then row.db.glow_enabled = not row.db.glow_enabled end
                        if type(TrinketTracker_ToggleGlow) == "function" then
                            TrinketTracker_ToggleGlow(id)
                        end
                    end)
                end

                -- Update values
                row.slotID = db.slotID
                row.removeLeft:SetScript("OnClick", function(self)
                    local id = row.slotID
                    if not id then return end
                    if type(TrinketTracker_Remove) == "function" then
                        TrinketTracker_Remove(id)
                    end
                end)

                -- Try to get the item icon from the equipment slot
                local itemID = GetInventoryItemID("player", db.slotID or 0)
                local texture = itemID and select(10, GetItemInfo(itemID))
                row.icon:SetTexture(texture or 134400)
                row.name:SetText(db.slotName or SLOT_NAMES[db.slotID] or ("Slot " .. (db.slotID or key)))

                row:SetPoint("TOPLEFT", trackedContainer, "TOPLEFT", 0, -(count - 1) * 26)
                row:Show()
                trackedRows[key] = row
                used[key] = true
            end
        end

        -- Hide rows no longer present
        for k, r in pairs(trackedRows) do
            if not used[k] then
                r:Hide()
                trackedRows[k] = nil
            end
        end

        local totalHeight = count * 26
        trackedContainer:SetHeight(totalHeight)

        if actionsHeaderFrame and actionsHeaderFrame.SetPoint then
            actionsHeaderFrame:SetPoint("TOPLEFT", trackedContainer, "BOTTOMLEFT", 0, -6)
        end
    end

    BuildTrackedList()

    if type(TrinketTracker_RegisterChangeListener) == "function" then
        TrinketTracker_RegisterChangeListener(BuildTrackedList)
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
        if not val or val:trim() == "" then
            print("|cFFFF0000TrinketTracker: enter slot number.|r")
            return
        end
        local slotID = tonumber(val:trim())
        if slotID and type(TrinketTracker_Reset) == "function" then
            TrinketTracker_Reset(slotID)
        end
        if edit and edit.box then edit.box:ClearFocus(); edit.box:SetText("") end
    end)
    anchor = btn
    y = -8

    btn = W:Button(parent, anchor, y, "Reset All", function()
        if type(TrinketTracker_ResetAll) == "function" then
            TrinketTracker_ResetAll()
        end
    end)
    anchor = btn
    y = -8

    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if type(TrinketTracker_ToggleLock) == "function" then
            local locked = TrinketTracker_ToggleLock()
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
        if type(TrinketTracker_List) == "function" then
            TrinketTracker_List()
        end
    end)
    anchor = btn

    parent:HookScript("OnShow", function()
        BuildTrackedList()
        if lockBtn and shmIcons and shmIcons.IsLocked then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end)
end

PoulsTools.Menu:RegisterAddon({
    name      = "PoulsTools_TrinketTracker",
    id        = "PoulsTools_TrinketTracker",
    desc      = "Track equipment slot cooldowns per specialization.",
    version   = "2.0.0",
    icon      = "Interface\\Icons\\inv_jewelry_trinketpvp_01",
    parentId  = "PoulsTools_shmIcons",
    OnBuildUI = OnBuildUI,
})
