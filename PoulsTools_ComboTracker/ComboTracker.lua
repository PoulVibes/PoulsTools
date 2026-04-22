local ADDON_NAME = "PoulsTools_ComboTracker"
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
    --[1272696] = true, -- Zenith Stomp -- Currently not triggering mastery combo strikes probably a bug.
}

local function ResetStreak()
    --print("Streak Reset ", LastComboStrikeSpellID, " used twice.")
    if timerHandle then timerHandle:Cancel() end
    ComboStrikeStreak      = 0
    LastComboStrikeSpellID = 0
    timerHandle            = nil
    shmIcons:SetVisible(ADDON_NAME, "Hit Combo", false)
    shmIcons:SetCooldownRaw(ADDON_NAME, "Hit Combo", 0, 0)
    shmIcons:SetStacks(ADDON_NAME, "Hit Combo", 0)
    shmIcons:SetGlow(ADDON_NAME, "Hit Combo", false)
end

local REQUIRED_CLASS = "MONK"
local REQUIRED_SPEC_ID = 269
local addonEnabled = false

-- Create event frame early so helpers can register/unregister safely
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

local function IsPlayerMonk()
    local _, classToken = UnitClass("player")
    return classToken == REQUIRED_CLASS
end

local function IsPlayerWindwalkerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == REQUIRED_SPEC_ID
end

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    --print("[" .. ADDON_NAME .. "] enabled (Windwalker).")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if timerHandle then timerHandle:Cancel(); timerHandle = nil end
    ComboStrikeStreak = 0
    LastComboStrikeSpellID = 0
    shmIcons:SetVisible(ADDON_NAME, "Hit Combo", false)
    shmIcons:SetCooldownRaw(ADDON_NAME, "Hit Combo", 0, 0)
    shmIcons:SetStacks(ADDON_NAME, "Hit Combo", 0)
    shmIcons:SetGlow(ADDON_NAME, "Hit Combo", false)
    --print("[" .. ADDON_NAME .. "] disabled (not Windwalker).")
end

local function UpdateEnabledState()
    if not IsPlayerMonk() then
        --print("[" .. ADDON_NAME .. "] abort: wrong class (not Monk).")
        eventFrame:UnregisterAllEvents()
        return
    end
    if IsPlayerWindwalkerSpec() then
        EnableAddon()
    else

        DisableAddon()
    end
end

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
        
        shmIcons:Register(ADDON_NAME, "Hit Combo", db, {
            onResize = function(sq) db.size = sq end,
            onMove   = function(_db) end,
        })
        shmIcons:SetIcon(ADDON_NAME, "Hit Combo", TRACKER_ICON)
        shmIcons:SetVisible(ADDON_NAME, "Hit Combo", false)
        -- Hide this addon's icons when shmIcons are locked
        if shmIcons and shmIcons.RegisterLockCallback then
            shmIcons:RegisterLockCallback(function(locked)
                if locked then
                    shmIcons:SetVisible(ADDON_NAME, "Hit Combo", false)
                    shmIcons:SetCooldownRaw(ADDON_NAME, "Hit Combo", 0, 0)
                    shmIcons:SetStacks(ADDON_NAME, "Hit Combo", 0)
                    shmIcons:SetGlow(ADDON_NAME, "Hit Combo", false)
                end
            end)
        end
        -- After initialization, enable/disable based on class/spec
        UpdateEnabledState()

    elseif event == "PLAYER_LOGIN" then
        -- Abort if not a Monk (no point continuing)
        local _, classToken = UnitClass("player")
        if classToken ~= "MONK" then
            --print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
            --print("  ProcViewer disabled: not a Monk.")
            eventFrame:UnregisterAllEvents()
            return
        end
        -- Enable only if Windwalker, otherwise stay disabled but listen for spec changes
        if IsPlayerWindwalkerSpec() then
            EnableAddon()
        else
            DisableAddon()
            --print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
            --print("  ProcViewer loaded but inactive (not Windwalker).")
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = select(1,...)
        if unit == "player" then UpdateEnabledState() end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if not comboStrikesAbilities[spellID] then return end

            if spellID == LastComboStrikeSpellID then
            -- Buzzer Logic: Same spell breaks the combo
            -- commented out for now but here is a print statement for debugging should I need it later. do not remove
            -- print("Combo Broken Spell:", LastComboStrikeSpellID)
            ComboStrikeStreak = 0
            PlaySound(847, "Master") -- Quest Failed Sound
            shmIcons:SetVisible(ADDON_NAME, "Hit Combo", false)
            shmIcons:SetCooldownRaw(ADDON_NAME, "Hit Combo", 0, 0)
            shmIcons:SetStacks(ADDON_NAME, "Hit Combo", 0)
            shmIcons:SetGlow(ADDON_NAME, "Hit Combo", false)
            if timerHandle then timerHandle:Cancel() end
            timerHandle = nil
        else
            ComboStrikeStreak = math.min(5, ComboStrikeStreak + 1)
            shmIcons:SetVisible(ADDON_NAME, "Hit Combo", true)
            shmIcons:SetCooldownRaw(ADDON_NAME, "Hit Combo", GetTime(), 29)
            shmIcons:SetStacks(ADDON_NAME, "Hit Combo", ComboStrikeStreak)
            shmIcons:SetGlow(ADDON_NAME, "Hit Combo", false)
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
