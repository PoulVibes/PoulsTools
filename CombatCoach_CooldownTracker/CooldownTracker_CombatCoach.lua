-- CooldownTracker_CombatCoach.lua
-- CombatCoach integration for CooldownTracker.
-- Look & Feel popup moved to CooldownTracker_CombatCoach_LookAndFeel.lua.

if not CombatCoach then return end

CooldownTrackerDB = CooldownTrackerDB or {}

-- Sound IDs and names for the ready-sound dropdown (shared with LookAndFeel file).
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
CooldownTracker_SOUND_CHOICES = SOUND_CHOICES
local SOUND_NAME_BY_ID = {}
for _, s in ipairs(SOUND_CHOICES) do SOUND_NAME_BY_ID[s.id] = s.text end

function FindSoundName(val)
    if not val then return "None" end
    return SOUND_NAME_BY_ID[val] or tostring(val)
end

function PlaySoundPreview(id)
    if not id then return end
    if C_Sound and C_Sound.PlaySound then pcall(C_Sound.PlaySound, id)
    else pcall(PlaySound, id, "Master") end
end

-- Shared handle for the Look & Feel popup; assigned by LookAndFeel file.
lafPopup = nil

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
                        if type(CooldownTracker_OpenLookAndFeel) == "function" then
                            CooldownTracker_OpenLookAndFeel(row.spellKey)
                        end
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
