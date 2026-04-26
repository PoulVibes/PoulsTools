local ADDON_NAME = ...

local SCREENSHOT_DELAY = 0.15
local HIDE_DELAY = 0.25
local ICON_SIZE = 96
local MAX_CAPTURES_PER_SPELL = 3

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

local iconFrame = CreateFrame("Frame", nil, UIParent)
iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
iconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
iconFrame:SetFrameStrata("FULLSCREEN_DIALOG")
iconFrame:Hide()

local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
iconTexture:SetAllPoints(iconFrame)

local requestToken = 0
local screenshotCountsBySpell = {}

local function TryScreenshot()
    if type(Screenshot) == "function" then
        Screenshot()
        return true
    elseif type(RunBinding) == "function" then
        RunBinding("SCREENSHOT")
        return true
    end

    return false
end

local function ShowAndCapture(spellID)
    local texture = C_Spell.GetSpellTexture(spellID)
    if not texture then
        return
    end

    requestToken = requestToken + 1
    local token = requestToken

    iconTexture:SetTexture(texture)
    iconFrame:Show()

    C_Timer.After(SCREENSHOT_DELAY, function()
        if token ~= requestToken then
            return
        end

        if TryScreenshot() then
            screenshotCountsBySpell[spellID] = (screenshotCountsBySpell[spellID] or 0) + 1
        end

        C_Timer.After(HIDE_DELAY, function()
            if token ~= requestToken then
                return
            end
            iconFrame:Hide()
        end)
    end)
end

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        return
    end

    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local spellID = arg1
        if spellID and spellID > 0 and (screenshotCountsBySpell[spellID] or 0) < MAX_CAPTURES_PER_SPELL then
            ShowAndCapture(spellID)
        end
    end
end)
