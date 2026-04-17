-- CooldownTracker_PoulsTools.lua
-- PoulsTools integration for CooldownTracker

if not PoulsTools then return end

CooldownTrackerDB = CooldownTrackerDB or {}

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("PoulsTools.Widgets missing. Install PoulsTools to configure CooldownTracker here.")
        note:SetTextColor(1,0.8,0.2,1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "CooldownTracker")
    anchor = div
    y = dy

    local input = ""
    local edit = W:EditBox(parent, anchor, y, "Add / Remove Spell", "e.g. Fireball", function() return input end, function(val) input = val end)
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

                    -- small left checkbox (toggle glow)
                    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    row.check:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.check:SetSize(22, 22)

                    -- spell icon
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(20, 20)
                    row.icon:SetPoint("LEFT", row.check, "RIGHT", 6, 0)

                    -- name label
                    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.name:SetTextColor(unpack(W.colors.text))

                    -- per-row Remove button (right side)
                    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.remove:SetSize(80, 20)
                    -- align the remove column closer to the abilities (fixed column)
                    row.remove:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                    row.remove:SetText("Remove")
                    row.remove:SetScript("OnClick", function(self)
                        local spell = row.spellName
                        if not spell or spell:trim() == "" then return end
                        if type(CooldownTracker_Remove) == "function" then CooldownTracker_Remove(spell) end
                    end)
                end

                -- update values
                row.check:SetChecked(db.glow_enabled)
                row.check:SetScript("OnClick", function(self)
                    db.glow_enabled = self:GetChecked()
                    if type(CooldownTracker_ToggleGlow) == "function" then CooldownTracker_ToggleGlow(db.spellName) end
                end)

                local sInfo = (db.spellID and C_Spell.GetSpellInfo(db.spellID)) or nil
                row.icon:SetTexture((sInfo and sInfo.iconID) or 134400)
                row.name:SetText(db.spellName)

                row:SetPoint("TOPLEFT", trackedContainer, "TOPLEFT", 0, -(count - 1) * 26)
                row:Show()
                trackedRows[key] = row
                used[key] = true
            end
        end

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
    if type(CooldownTracker_RegisterChangeListener) == "function" then
        CooldownTracker_RegisterChangeListener(BuildTrackedList)
    end

    local div3, dy3 = W:SectionHeader(parent, trackedContainer, -6, "Actions")
    -- keep a reference so the tracked list can reanchor this header on updates
    actionsHeaderFrame = div3
    anchor = div3
    y = dy3

    btn = W:Button(parent, anchor, y, "Reset Selected (use input box)", function()
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
    parent:HookScript("OnShow", function()
        if lockBtn and shmIcons and shmIcons.IsLocked then
            lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
        end
    end)
end

PoulsTools.Menu:RegisterAddon({
    name    = "CooldownTracker",
    id      = "CooldownTracker",
    desc    = "Track ability cooldowns per specialization.",
    version = "2.0.0",
    icon    = "Interface\\Icons\\INV_Misc_Gear_01",
    OnBuildUI = OnBuildUI,
})
