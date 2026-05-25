local DAT = DynamicActivationTracker

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

local function Initialize()
    if DAT.initialized then return end
    DAT.initialized = true
    DynamicActivationTracker_EnsureDatabase()
end

local function LoadCurrentSpec()
    local specID = DynamicActivationTracker_GetCurrentSpecID()
    DynamicActivationTracker_LoadSpec(specID)
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == DAT.ADDON_FOLDER then
        Initialize()

    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Initialize()
        LoadCurrentSpec()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if arg1 == "player" then
            LoadCurrentSpec()
        end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        LoadCurrentSpec()

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        DynamicActivationTracker_RefreshAllTimerCooldowns()

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        DynamicActivationTracker_ShowActivation(arg1)

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        DynamicActivationTracker_HideActivation(arg1)
    end
end)

SLASH_DYNAMICACTIVATIONTRACKER1 = "/dat"
SlashCmdList["DYNAMICACTIVATIONTRACKER"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))

    elseif msg == "list" then
        DynamicActivationTracker_ListCurrentSpecIcons()

    elseif msg == "clear" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicActivationTracker: Cannot clear in combat.|r")
            return
        end
        DynamicActivationTracker_ClearCurrentSpec()
        DynamicActivationTracker_RefreshCurrentSpecList()
        print("|cFFFFFF00DynamicActivationTracker: Cleared saved icons for this spec.|r")

    elseif msg == "reset" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicActivationTracker: Cannot reset in combat.|r")
            return
        end
        local specID = DAT.currentSpecID
        local specDB = specID and DynamicActivationTracker_GetSpecDB(specID)
        if specDB then
            for spellIDStr in pairs(specDB.icons) do
                local spellID = tonumber(spellIDStr)
                if spellID then
                    shmIcons:ResetIcon(DAT.ADDON_NAME, spellIDStr, DAT.DEFAULT_SIZE)
                end
            end
        end
        print("|cFF00FF00DynamicActivationTracker: All icon positions reset.|r")

    else
        print("|cFFFFFF00DynamicActivationTracker commands:|r")
        print("  /dat list   - list saved icons for the current spec")
        print("  /dat lock   - toggle icon lock/unlock")
        print("  /dat reset  - reset all icon positions for this spec")
        print("  /dat clear  - clear saved icons for this spec")
    end
end