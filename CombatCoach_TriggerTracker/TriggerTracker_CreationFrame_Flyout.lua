-- TriggerTracker_CreationFrame_Flyout.lua
-- Spell flyout column (search, tabs, scroll lists, Add-by-ID popup).
-- CF.CreateFlyoutColumn(parent, RIGHT_X, TOP_Y, FLY_W, onDispatch)
-- Returns a table: { spellList, talentList, addByIDBtn, Refresh, ResetCache }

local TT = TriggerTracker
local CF = TT.CF
local SetBD = CF.SetBD

CF.CreateFlyoutColumn = function(parent, RIGHT_X, TOP_Y, FLY_W, onDispatch)
    -- Filter / search box
    local searchBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    searchBox:SetSize(FLY_W, 22)
    searchBox:SetPoint("TOPLEFT", parent, "TOPLEFT", RIGHT_X, TOP_Y + 2)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(64)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Tab buttons
    local TAB_W = math.floor(FLY_W / 2) - 2
    local TAB_H = 22
    local tabSpellBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tabSpellBtn:SetSize(TAB_W, TAB_H)
    tabSpellBtn:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -4)
    tabSpellBtn:SetText("Spells")

    local tabTalentBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tabTalentBtn:SetSize(TAB_W, TAB_H)
    tabTalentBtn:SetPoint("LEFT", tabSpellBtn, "RIGHT", 4, 0)
    tabTalentBtn:SetText("Talents")

    local function UpdateTabButtons(showingSpells)
        if showingSpells then
            tabSpellBtn:SetButtonState("PUSHED", true)
            tabSpellBtn:GetFontString():SetTextColor(0.3, 1.0, 0.5, 1)
            tabTalentBtn:SetButtonState("NORMAL")
            tabTalentBtn:GetFontString():SetTextColor(0.85, 0.85, 0.85, 1)
        else
            tabTalentBtn:SetButtonState("PUSHED", true)
            tabTalentBtn:GetFontString():SetTextColor(0.3, 1.0, 0.5, 1)
            tabSpellBtn:SetButtonState("NORMAL")
            tabSpellBtn:GetFontString():SetTextColor(0.85, 0.85, 0.85, 1)
        end
    end

    local LIST_H = 180
    local spellList  = CF.CreateScrollList(parent, FLY_W, LIST_H, onDispatch)
    spellList:SetPoint("TOPLEFT", tabSpellBtn, "BOTTOMLEFT", 0, -30)

    local talentList = CF.CreateScrollList(parent, FLY_W, LIST_H, onDispatch)
    talentList:SetPoint("TOPLEFT", tabSpellBtn, "BOTTOMLEFT", 0, -30)
    talentList:Hide()

    local cachedSpells, cachedTalents = nil, nil

    local function RefreshFlyout()
        local filter = searchBox:GetText()
        if spellList:IsShown() then
            if not cachedSpells then cachedSpells = CF.GetSpellbookSpells() end
            spellList.Rebuild(cachedSpells, filter)
        else
            if not cachedTalents then cachedTalents = CF.GetTalentSpells() end
            talentList.Rebuild(cachedTalents, filter)
        end
    end

    tabSpellBtn:SetScript("OnClick", function()
        spellList:Show(); talentList:Hide()
        UpdateTabButtons(true); RefreshFlyout()
    end)
    tabTalentBtn:SetScript("OnClick", function()
        talentList:Show(); spellList:Hide()
        UpdateTabButtons(false); RefreshFlyout()
    end)
    searchBox:SetScript("OnTextChanged", function() RefreshFlyout() end)

    -- Add by ID button + popup
    local addByIDBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    addByIDBtn:SetSize(FLY_W, 22)
    addByIDBtn:SetPoint("TOPLEFT", tabSpellBtn, "BOTTOMLEFT", 0, -4)
    addByIDBtn:SetText("Add by ID")

    local idPopup = CreateFrame("Frame", "TT_AddSpellPopup", UIParent, "BackdropTemplate")
    idPopup:SetSize(300, 110)
    idPopup:SetFrameStrata("TOOLTIP")
    idPopup:SetToplevel(true)
    idPopup:SetClampedToScreen(true)
    idPopup:Hide()
    SetBD(idPopup, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local popTitle = idPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popTitle:SetPoint("TOP", idPopup, "TOP", 0, -8)
    popTitle:SetText("Add Spell by Name or ID")
    popTitle:SetTextColor(0.55, 0.82, 1, 1)

    local popBox = CreateFrame("EditBox", nil, idPopup, "InputBoxTemplate")
    popBox:SetSize(200, 22)
    popBox:SetPoint("TOPLEFT", idPopup, "TOPLEFT", 12, -30)
    popBox:SetAutoFocus(true)
    popBox:SetMaxLetters(80)

    local popResult = idPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    popResult:SetPoint("TOPLEFT", popBox, "BOTTOMLEFT", 0, -4)
    popResult:SetSize(276, 16)
    popResult:SetJustifyH("LEFT")

    local popResolvedID, popResolvedName, popResolvedIcon = nil, nil, nil

    local function DoPopLookup()
        local input = popBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then popResult:SetText("") popResolvedID = nil return end
        local id = tonumber(input)
        if not id and C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end
        if id and id > 0 then
            local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            if si then
                popResolvedID   = id
                popResolvedName = si.name
                popResolvedIcon = si.iconID or 134400
                popResult:SetText("|cff55ee55" .. si.name .. "|r  |cff8899bbID: " .. id .. "|r")
            else
                popResolvedID = nil
                popResult:SetText("|cffff5555Spell not found|r")
            end
        else
            popResolvedID = nil
            popResult:SetText("|cffff5555Spell not found|r")
        end
    end

    popBox:SetScript("OnTextChanged", DoPopLookup)
    popBox:SetScript("OnEnterPressed", function()
        DoPopLookup()
        if popResolvedID then
            onDispatch(popResolvedID, popResolvedName, popResolvedIcon)
            idPopup:Hide(); popBox:SetText("")
        end
    end)

    local popAdd = CreateFrame("Button", nil, idPopup, "UIPanelButtonTemplate")
    popAdd:SetSize(80, 24)
    popAdd:SetPoint("BOTTOMLEFT", idPopup, "BOTTOMLEFT", 12, 8)
    popAdd:SetText("Add")
    popAdd:SetScript("OnClick", function()
        DoPopLookup()
        if popResolvedID then
            onDispatch(popResolvedID, popResolvedName, popResolvedIcon)
            idPopup:Hide(); popBox:SetText("")
        else
            popResult:SetText("|cffff5555Enter a valid name or ID first|r")
        end
    end)

    local popCancel = CreateFrame("Button", nil, idPopup, "UIPanelButtonTemplate")
    popCancel:SetSize(80, 24)
    popCancel:SetPoint("BOTTOMRIGHT", idPopup, "BOTTOMRIGHT", -12, 8)
    popCancel:SetText("Cancel")
    popCancel:SetScript("OnClick", function() idPopup:Hide() end)

    addByIDBtn:SetScript("OnClick", function()
        if idPopup:IsShown() then idPopup:Hide() return end
        idPopup:ClearAllPoints()
        idPopup:SetPoint("TOPLEFT", addByIDBtn, "BOTTOMLEFT", 0, -4)
        idPopup:Show(); popBox:SetFocus()
    end)

    local function ResetCache()
        cachedSpells  = nil
        cachedTalents = nil
        searchBox:SetText("")
    end

    local function ResetToSpellTab()
        spellList:Show(); talentList:Hide()
        UpdateTabButtons(true)
    end

    return {
        spellList      = spellList,
        talentList     = talentList,
        addByIDBtn     = addByIDBtn,
        Refresh        = RefreshFlyout,
        ResetCache     = ResetCache,
        ResetToSpellTab = ResetToSpellTab,
    }
end
