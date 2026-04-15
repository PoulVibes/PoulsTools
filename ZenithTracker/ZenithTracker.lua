local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

-- Initialize globals
_G["ZenithActiveTracker"] = false
_G["ZenithIconEnabled"] = false -- Defaulted to false as requested
local timerDuration = 15 

-- Tracked Spell IDs
local ZENITH_IDS = {
    [1249625] = true, -- Zenith (Main Talent ID)
    [1249763] = true, -- Zenith (Mastery Trigger ID)
    [1272696] = true, -- Zenith Stomp
}

-- Create the Visual Icon
local iconFrame = CreateFrame("Frame", "ZenithIconFrame", UIParent)
iconFrame:SetSize(64, 64)
iconFrame:SetPoint("CENTER", 0, 0)
iconFrame:Hide()

local texture = iconFrame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(iconFrame)
-- Using C_Spell for 12.0.1 compatibility
texture:SetTexture(C_Spell.GetSpellTexture(1249625))

-- Slash Command Logic
SLASH_ZENITH1 = "/zenith"
SlashCmdList["ZENITH"] = function(msg)
    _G["ZenithIconEnabled"] = not _G["ZenithIconEnabled"]
    local status = _G["ZenithIconEnabled"] and "|cff00FF00Enabled|r" or "|cffFF0000Disabled|r"
    print("|cff00FFFFZenith Tracker:|r Icon display is now " .. status)
    
    -- If disabled while active, hide immediately
    if not _G["ZenithIconEnabled"] then iconFrame:Hide() end
end

local function UpdateTimerDuration()
    -- Check for Drinking Horn Cover talent
    if IsPlayerSpell(391370) then 
        timerDuration = 20
    else
        timerDuration = 15
    end
end

frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" then
        UpdateTimerDuration()
        return
    end

    -- Trigger tracker if Zenith cast succeeded and tracker isn't already active
    if unit == "player" and ZENITH_IDS[spellID] and not _G["ZenithActiveTracker"] then 
        _G["ZenithActiveTracker"] = true
        
        -- Only show icon if the user has enabled it via /zenith
        if _G["ZenithIconEnabled"] then
            iconFrame:Show()
        end
        
        C_Timer.After(timerDuration, function()
            _G["ZenithActiveTracker"] = false
            iconFrame:Hide()
        end)
    end
end)
