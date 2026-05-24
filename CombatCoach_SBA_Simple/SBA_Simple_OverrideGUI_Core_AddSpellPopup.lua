-- SBA_Simple_OverrideGUI_Core_AddSpellPopup.lua
-- Shared Add Spell popup builder.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.CreateAddSpellPopup(setBD)
    local f = CreateFrame("Frame", "SBAS_GUI_AddSpell", UIParent, "BackdropTemplate")
    f:SetSize(320, 130)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    setBD(f, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Add Spell by Name or ID")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local namInLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    namInLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    namInLbl:SetText("Name or ID:")
    namInLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(196, 22)
    nameBox:SetPoint("LEFT", namInLbl, "RIGHT", 6, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(80)

    local iconTex = f:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(28, 28)
    iconTex:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)
    iconTex:Hide()

    local resultLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultLbl:SetPoint("TOPLEFT", namInLbl, "BOTTOMLEFT", 0, -8)
    resultLbl:SetSize(296, 16)
    resultLbl:SetJustifyH("LEFT")

    local resolvedID = nil
    local resolvedName = nil

    local function DoLookup()
        local input = nameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            resultLbl:SetText("")
            iconTex:Hide()
            resolvedID = nil
            return
        end

        local id = tonumber(input)
        if not id and C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end

        if id and id > 0 then
            local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id)
            if isPassive then
                resolvedID = nil
                resolvedName = nil
                resultLbl:SetText("|cffff5555That spell is passive and cannot be added|r")
                iconTex:Hide()
                return
            end
            local n = C_Spell.GetSpellName and C_Spell.GetSpellName(id)
            local tex = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
            resolvedID = id
            resolvedName = n or input
            resultLbl:SetText("|cff55ee55" .. (n or input) .. "|r  |cff8899bbID: " .. id .. "|r")
            if tex then iconTex:SetTexture(tex) iconTex:Show() else iconTex:Hide() end
        else
            resolvedID = nil
            resolvedName = nil
            resultLbl:SetText("|cffff5555Spell not found|r")
            iconTex:Hide()
        end
    end

    nameBox:SetScript("OnTextChanged", DoLookup)
    nameBox:SetScript("OnEnterPressed", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        end
    end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(88, 24)
    addBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 10)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        else
            resultLbl:SetText("|cffff5555Enter a valid spell name or ID first|r")
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(88, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f.nameBox = nameBox
    f.iconTex = iconTex
    f.onAdd = nil

    return f
end
