-- DynamicBuffTracker.lua
-- Event handler, slash commands, and CDM bar visibility.
-- All logic is in the helper files loaded before this one.

local DBT = DynamicBuffTracker
local lockCallbackRegistered = false

-- ============================================================
-- CDM bar visibility
-- ============================================================

function DynamicBuffTracker_ApplyCDMBarVisibility()
    local viewer = _G["BuffIconCooldownViewer"]
    if viewer then
        viewer:SetAlpha(DynamicBuffTrackerDB and DynamicBuffTrackerDB.hideCDMBar and 0 or 1)
    end
end

-- ============================================================
-- Events
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == DBT.ADDON_FOLDER then
        DynamicBuffTrackerDB       = DynamicBuffTrackerDB or {}
        DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
        if not lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
            lockCallbackRegistered = true
            shmIcons:RegisterLockCallback(function()
                DynamicBuffTracker_ReevaluateVisibility()
            end)
        end
        for _, specData in pairs(DynamicBuffTrackerDB.specs) do
            if type(specData) == "table" and specData.buffs then
                for k, entry in pairs(specData.buffs) do
                    if type(entry) == "table" and entry.texID and not entry.spellID then
                        specData.buffs[k] = nil
                    end
                end
            end
        end
        local viewer = _G["BuffIconCooldownViewer"]
        if viewer and viewer.OnAcquireItemFrame then
            hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, frame)
                DynamicBuffTracker_HookCDMFrame(frame)
            end)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        DynamicBuffTracker_HookViewerChildren(_G["BuffIconCooldownViewer"])
        DynamicBuffTracker_ApplyCDMBarVisibility()
        DBT.currentSpecID = DynamicBuffTracker_GetCurrentSpecID()
        DynamicBuffTracker_LoadSpec(DBT.currentSpecID)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        DynamicBuffTracker_LoadSpec(DynamicBuffTracker_GetCurrentSpecID())

    elseif event == "TRAIT_CONFIG_UPDATED" then
        if not InCombatLockdown() then
            C_Timer.After(0.5, function()
                if not InCombatLockdown() then DynamicBuffTracker_ScanAndSync() end
            end)
        end
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

-- ============================================================
-- Slash commands
-- ============================================================

SLASH_DYNAMICBUFFTRACKER1 = "/dbt"
SlashCmdList["DYNAMICBUFFTRACKER"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "scan" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot scan in combat.|r")
            return
        end
        DBT.retryCount   = 0
        DBT.retryPending = false
        DynamicBuffTracker_ScanAndSync()
        print("|cFF00FF00DynamicBuffTracker: Scan complete.|r")

    elseif msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))

    elseif msg == "list" then
        if DBT.currentSpecID == 0 then
            print("|cFFFFFF00DynamicBuffTracker: No spec active.|r")
            return
        end
        local buffDB = DynamicBuffTracker_GetSpecBuffDB(DBT.currentSpecID)
        local count  = 0
        for spellIDStr, entry in pairs(buffDB) do
            count = count + 1
            local spellID = tonumber(spellIDStr)
            local active  = spellID and _G[DynamicBuffTracker_MakeActiveFlag(DBT.currentSpecID, spellID)]
            local label   = entry.label
            if spellID then
                local ok, si = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and si and si.name then label = si.name end
            end
            print(string.format(
                "  |cFFFFFF00%s|r (spell:%s, pluginID:%s) %s",
                label, spellIDStr,
                spellID and DynamicBuffTracker_MakePluginID(DBT.currentSpecID, spellID) or "?",
                active and "|cFF00FF00ACTIVE|r" or "inactive"))
        end
        if count == 0 then
            print("|cFFFFFF00DynamicBuffTracker: No talents tracked for spec "
                .. tostring(DBT.currentSpecID) .. ".|r")
        end

    elseif msg == "clear" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot clear in combat.|r")
            return
        end
        DynamicBuffTracker_UnloadSpec()
        if DynamicBuffTrackerDB and DynamicBuffTrackerDB.specs then
            DynamicBuffTrackerDB.specs[DBT.currentSpecID] = nil
        end
        print("|cFFFFFF00DynamicBuffTracker: Cleared all tracked talents for this spec.|r")

    elseif msg == "reset" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot reset in combat.|r")
            return
        end
        local buffDB = DynamicBuffTracker_GetSpecBuffDB(DBT.currentSpecID)
        for spellIDStr in pairs(buffDB) do
            local spellID = tonumber(spellIDStr)
            local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
            if ok and spellInfo then ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name) end
            if spellID then
                pcall(function()
                    if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                    shmIcons:ResetIcon(DBT.ADDON_NAME, DynamicBuffTracker_MakeKey(spellID), DBT.DEFAULT_SIZE)
                end)
            end
        end
        print("|cFF00FF00DynamicBuffTracker: All icon positions reset.|r")

    else
        print("|cFFFFFF00DynamicBuffTracker commands:|r")
        print("  /dbt scan    - rescan talent tree for tracked spells")
        print("  /dbt list    - list all tracked talents for this spec")
        print("  /dbt lock    - toggle icon lock/unlock")
        print("  /dbt reset   - reset all icon positions for this spec")
        print("  /dbt clear   - clear saved talent data for this spec")
    end
end