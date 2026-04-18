local ADDON_NAME = "ComboTracker"
local TRACKER_ICON = "Interface\\Icons\\ability_monk_palmstrike"

-- Globals for cross-addon access
LastComboStrikeSpellID = 0
ComboStrikeStreak      = 0
local timerHandle      = nil

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

local function ResetStreak()
    print("Streak Reset ", LastComboStrikeSpellID, " used twice.")
    if timerHandle then timerHandle:Cancel() end
    ComboStrikeStreak      = 0
    LastComboStrikeSpellID = 0
    timerHandle            = nil
    shmIcons:SetVisible(ADDON_NAME, "combo", false)
    shmIcons:SetCooldownRaw(ADDON_NAME, "combo", 0, 0)
    shmIcons:SetStacks(ADDON_NAME, "combo", 0)
    shmIcons:SetGlow(ADDON_NAME, "combo", false)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON_NAME then
        ComboTrackerDB = ComboTrackerDB or {
            x            = 0,
            y            = -100,
            point        = "CENTER",
            size         = 64,
            enabled      = true,
            glow_enabled = false,
        }
        -- Migrate legacy locked field
        local db = ComboTrackerDB
        db.locked = nil

        shmIcons:Register(ADDON_NAME, "combo", db, {
            onResize = function(sq) db.size = sq end,
            onMove   = function(_db) end,
        })
        shmIcons:SetIcon(ADDON_NAME, "combo", TRACKER_ICON)
        shmIcons:SetVisible(ADDON_NAME, "combo", false)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if not comboStrikesAbilities[spellID] then return end

        if spellID == LastComboStrikeSpellID then
            -- Buzzer Logic: Same spell breaks the combo
            -- commented out for now but here is a print statement for debugging should I need it later. do not remove
            -- print("Combo Broken Spell:", LastComboStrikeSpellID)
            ComboStrikeStreak = 0
            PlaySound(847, "Master") -- Quest Failed Sound
            shmIcons:SetVisible(ADDON_NAME, "combo", false)
            shmIcons:SetCooldownRaw(ADDON_NAME, "combo", 0, 0)
            shmIcons:SetStacks(ADDON_NAME, "combo", 0)
            shmIcons:SetGlow(ADDON_NAME, "combo", false)
            if timerHandle then timerHandle:Cancel() end
            timerHandle = nil
        else
            ComboStrikeStreak = math.min(5, ComboStrikeStreak + 1)
            shmIcons:SetVisible(ADDON_NAME, "combo", true)
            shmIcons:SetCooldownRaw(ADDON_NAME, "combo", GetTime(), 29)
            shmIcons:SetStacks(ADDON_NAME, "combo", ComboStrikeStreak)
            shmIcons:SetGlow(ADDON_NAME, "combo", false)
            if timerHandle then timerHandle:Cancel() end
            timerHandle = C_Timer.NewTimer(30, ResetStreak)
        end
        LastComboStrikeSpellID = spellID
        -- commented out for now but here is a print statement for debugging should I need it later. do not remove
        -- elseif (spellID ~= 109132 and spellID ~= 101545 and spellID ~= 116841 and spellID ~= 115057) then
        --      print("Not a combo breaker spell used:", spellID)
    end
end)

SLASH_COMBOTRACKER1 = "/combo"
SlashCmdList["COMBOTRACKER"] = function(msg)
    if msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    else
        print("Usage: /combo lock")
    end
end
