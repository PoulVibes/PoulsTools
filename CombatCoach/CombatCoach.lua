-- CombatCoach.lua
-- Main addon file; manages sub-addon registration and settings menu.

CombatCoach = CombatCoach or {}
local CC = CombatCoach

CC.defaults = {
    enabled = true,
    submenus = {},
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "CombatCoach" then
            CC:OnLoad()
        end
    elseif event == "PLAYER_LOGIN" then
        CC:OnLogin()
    end
end)

function CC:OnLoad()
    if not CombatCoachDB then
        CombatCoachDB = CopyTable(self.defaults)
    end
    self.db = CombatCoachDB

    for k, v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

    print("|cFF00CCFFCombatCoach|r loaded. Type |cFFFFFF00/coach|r or |cFFFFFF00/CombatCoach|r for options.")
end

function CC:OnLogin()
    CC.Menu:BuildSettingsPanel()
    if CC.Profiles then
        CC.Profiles:AddButtonsToMainPanel()
    end
end

SLASH_CombatCoach1 = "/coach"
SLASH_CombatCoach2 = "/CombatCoach"
SLASH_CombatCoach3 = "/pt" -- alias for coach based on former tool name PoulsTools

SlashCmdList["CombatCoach"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "" or msg == "options" or msg == "config" then
        if InCombatLockdown() then
            print("|cFFFF4444CombatCoach:|r Cannot open settings during combat.")
            return
        end
        if CC.Menu.mainCategory then
            Settings.OpenToCategory(CC.Menu.mainCategory:GetID())
        else
            print("|cFFFF4444CombatCoach:|r Settings panel not yet initialized.")
        end
    elseif msg == "help" then
        CC:PrintHelp()
    else
        CC:PrintHelp()
    end
end

function CC:PrintHelp()
    print("|cFF00CCFFCombatCoach|r commands:")
    print("  |cFFFFFF00/coach|r or |cFFFFFF00/coach options|r - Open CombatCoach settings")
    print("  |cFFFFFF00/coach help|r - Show this help")
end
