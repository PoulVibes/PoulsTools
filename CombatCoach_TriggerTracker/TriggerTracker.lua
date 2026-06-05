-- TriggerTracker.lua
-- Event handler, spell cast tracking, and slash commands.

local TT = TriggerTracker

local lockCallbackRegistered = false

-- ============================================================
-- Spell cast handler
-- ============================================================

local eventFrame = CreateFrame("Frame")

local function OnSpellCastSucceeded(spellID)
    if not TT.spellMap then return end
    local actions = TT.spellMap[spellID]
    if not actions then return end

    -- Extenders run first. Track which keys were successfully extended.
    -- Rule 6: if a spell is both a generator and an extender for the same key,
    -- and the buff is currently active (timer running), use extend logic only.
    local extendedKeys = {}
    for _, action in ipairs(actions) do
        if action.mode == "extend" then
            local remaining = TriggerTracker_GetTimerRemaining(action.key)
            if remaining > 0 and action.maxDuration and action.maxDuration > 0 then
                TriggerTracker_ExtendTimer(action.key, action.extendAmount, action.maxDuration)
                extendedKeys[action.key] = true
            end
        end
    end

    -- Generators run before spenders; skip keys already handled by extend.
    for _, action in ipairs(actions) do
        if action.mode == "generate" and not extendedKeys[action.key] then
            TriggerTracker_AddStack(action.key, action.maxStacks, action.timer, action.perCast)
        end
    end
    for _, action in ipairs(actions) do
        if action.mode == "spend" then
            TriggerTracker_SpendStack(action.key, action.perCast)
        end
    end
end

-- ============================================================
-- Events
-- ============================================================

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= TT.ADDON_FOLDER then return end
        TriggerTrackerDB       = TriggerTrackerDB or {}
        TriggerTrackerDB.specs = TriggerTrackerDB.specs or {}

        if not lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
            lockCallbackRegistered = true
            shmIcons:RegisterLockCallback(function(locked)
                if locked then
                    local specID = TT.currentSpecID
                    if specID == 0 then return end
                    TriggerTracker_ForEachTrigger(specID, function(idx, _entry)
                        local key = TriggerTracker_MakeKey(specID, idx)
                        shmIcons:SetVisible(TT.ADDON_NAME, key, false)
                        shmIcons:SetGlow(TT.ADDON_NAME, key, false)
                    end)
                end
            end)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        local specID = TriggerTracker_GetCurrentSpecID()
        TriggerTracker_LoadSpec(specID)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        TriggerTracker_UnloadSpec()
        local specID = TriggerTracker_GetCurrentSpecID()
        TriggerTracker_LoadSpec(specID)
        if TT.rebuildCombatCoachList then TT.rebuildCombatCoachList() end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- varargs: unitToken, castGUID, spellID
        local _, _, spellID = ...
        if spellID then OnSpellCastSucceeded(spellID) end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat with no further action needed for now.
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- ============================================================
-- Slash commands
-- ============================================================

SLASH_TRIGGERTRACKER1 = "/tt"
SLASH_TRIGGERTRACKER2 = "/triggertracker"
SlashCmdList["TRIGGERTRACKER"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "new" or msg == "add" then
        TriggerTracker_OpenCreationFrame()

    elseif msg == "lock" then
        if shmIcons and shmIcons.ToggleLock then
            local locked = shmIcons:ToggleLock()
            print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
        end

    elseif msg == "list" then
        local specID = TT.currentSpecID
        if specID == 0 then
            print("|cFFFFFF00TriggerTracker:|r No spec active.")
            return
        end
        print("|cFF00CCFFTriggerTracker:|r Triggers for spec " .. specID .. ":")
        TriggerTracker_ForEachTrigger(specID, function(idx, entry)
            print(string.format("  [%d] %s  gen:%d  spend:%d  max:%d  timer:%s",
                idx,
                entry.name or "?",
                entry.generators and select(2, next(entry.generators)) and
                    (function() local c=0 for _ in pairs(entry.generators) do c=c+1 end return c end)() or 0,
                entry.spenders and
                    (function() local c=0 for _ in pairs(entry.spenders) do c=c+1 end return c end)() or 0,
                entry.maxStacks or 5,
                tostring(entry.timer or 0) .. "s"))
        end)

    elseif msg == "export" then
        TriggerTracker_OpenExportWindow()

    elseif msg == "reset" then
        local specID = TT.currentSpecID
        if specID == 0 then return end
        TriggerTracker_ForEachTrigger(specID, function(idx, _entry)
            local key = TriggerTracker_MakeKey(specID, idx)
            TT.activeStacks[key] = 0
            TriggerTracker_CancelTimer(key)
            shmIcons:SetStacks(TT.ADDON_NAME, key, 0)
            shmIcons:SetGlow(TT.ADDON_NAME, key, false)
            shmIcons:SetVisible(TT.ADDON_NAME, key, false)
        end)
        print("|cFF00FF00TriggerTracker:|r All stacks reset.")

    else
        print("|cFF00CCFFTriggerTracker commands:|r")
        print("  /tt new       — open Create Trigger frame")
        print("  /tt list      — list triggers for this spec")
        print("  /tt export    — export all saved triggers as Lua")
        print("  /tt reset     — reset all stack counts")
        print("  /tt lock      — toggle icon lock")
    end
end
