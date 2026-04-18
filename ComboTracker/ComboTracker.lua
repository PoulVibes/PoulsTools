-- Global variables for other addons to access
LastComboStrikeSpellID = 0 
ComboStrikeStreak = 0
local timerRemaining = 0
local TRACKER_ICON = "Interface\\Icons\\ability_monk_palmstrike"

-- Midnight (12.0.1) Mastery: Combo Strikes Triggers
local comboStrikesAbilities = {
    [100780] = true, -- Tiger Palm
    [100784] = true, -- Blackout Kick
    [107428] = true, -- Rising Sun Kick
    [113656] = true, -- Fists of Fury
    [322109] = true, -- Touch of Death
    [101546] = true, -- Spinning Crane Kick
    [152175] = true, -- Whirling Dragon Punch
    [392983] = true, -- Strike of the Windlord
    [117952] = true, -- Crackling Jade Lightning
    [467307] = true, -- Rushing Wind Kick
    [467396] = true, -- Slicing Winds
    [1249625] = true, -- Zenith (Main Talent ID)
    [1249763] = true, -- Zenith (Mastery Trigger ID)
    [1272696] = true, -- Zenith Stomp
}

local frame = CreateFrame("Frame", "ComboTrackerFrame", UIParent)
frame:SetSize(64, 64)
frame:SetPoint("CENTER", 0, -100)
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetResizeBounds(32, 32, 256, 256)
frame:SetClampedToScreen(true)
frame:Hide()

local texture = frame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(frame)
texture:SetTexture(TRACKER_ICON)
frame.texture = texture

-- Blizzard Cooldown Swipe (Inverted)
local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
cooldown:SetAllPoints(frame)
cooldown:SetDrawEdge(false)
cooldown:SetSwipeColor(0, 0, 0, 0.8)
cooldown:SetHideCountdownNumbers(true) 
cooldown:SetReverse(true) 
frame.cooldown = cooldown

-- Counter Text Setup
local countText = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
countText:SetPoint("CENTER", frame, "CENTER", 0, 0)
frame.countText = countText

-- Dynamic Scaling: Sets font to 50% of frame height
local function UpdateTextScale()
    local height = frame:GetHeight()
    countText:SetFont("Fonts\\ARIALN.TTF", height * 0.5, "OUTLINE")
end

-- Update font size live during resize
frame:SetScript("OnSizeChanged", UpdateTextScale)

-- Resize Handle (Bottom-Left)
local resizer = CreateFrame("Frame", nil, frame)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMLEFT")
resizer:Hide()
local resTexture = resizer:CreateTexture(nil, "OVERLAY")
resTexture:SetAllPoints()
resTexture:SetColorTexture(1, 1, 1, 0.5)

-- Slash Command & Locking Logic
local function UpdateLockState()
    if ComboTrackerDB.locked then
        frame:EnableMouse(false)
        resizer:Hide()
        if ComboStrikeStreak == 0 then frame:Hide() end
        print("|cFF00FF00ComboTracker Locked|r")
    else
        frame:EnableMouse(true)
        resizer:Show()
        frame:Show() 
        print("|cFFFFFF00ComboTracker Unlocked (Drag to move, Corner to resize)|r")
    end
end

SLASH_COMBOTRACKER1 = "/combo"
SlashCmdList["COMBOTRACKER"] = function(msg)
    if msg == "lock" then
        ComboTrackerDB.locked = not ComboTrackerDB.locked
        UpdateLockState()
    else
        print("Usage: /combo lock")
    end
end

-- Dragging Logic
frame:SetScript("OnMouseDown", function(self, button)
    if not ComboTrackerDB.locked and button == "LeftButton" then self:StartMoving() end
end)
frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(true)
end)

resizer:EnableMouse(true)
resizer:SetScript("OnMouseDown", function() if not ComboTrackerDB.locked then frame:StartSizing("BOTTOMLEFT") end end)
resizer:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

-- Internal Timer Logic
frame:SetScript("OnUpdate", function(self, elapsed)
    if timerRemaining > 0 then
        timerRemaining = timerRemaining - elapsed
        if timerRemaining <= 0 or ComboStrikeStreak <= 0 then
            timerRemaining = 0
            ComboStrikeStreak = 0
			LastComboStrikeSpellID = 0
            if ComboTrackerDB.locked then self:Hide() end
            self.countText:SetText("")
            self.cooldown:SetCooldown(0, 0)
        end
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "ComboTracker" then
        ComboTrackerDB = ComboTrackerDB or { locked = true }
        UpdateLockState()
        UpdateTextScale()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if comboStrikesAbilities[spellID] then
			-- Buzzer Logic: Same spell breaks the combo
            if spellID == LastComboStrikeSpellID then
                -- commented out for now but here is a print statement for debugging should I need it later. do not remove
				-- print("Combo Broken Spell:", LastComboStrikeSpellID)
				ComboStrikeStreak = 0
                PlaySound(847, "Master") -- Quest Failed Sound
                if ComboTrackerDB.locked then self:Hide() end
            else
                ComboStrikeStreak = math.min(5, ComboStrikeStreak + 1)
                self.countText:SetTextColor(1, 1, 1)
                self:Show()
            end
            LastComboStrikeSpellID = spellID
            timerRemaining = 29 
            self.cooldown:SetCooldown(GetTime(), 29)
            self.countText:SetText(ComboStrikeStreak)
        -- commented out for now but here is a print statement for debugging should I need it later. do not remove
		-- elseif (spellID ~= 109132 and spellID ~= 101545 and spellID ~= 116841 and spellID ~= 115057) then
		--		print("Not a combo breaker spell used:", spellID)
		end
		
    end
end)
