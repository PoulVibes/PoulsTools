-- CombatCoach.lua
-- Main addon file for CombatCoach - Addon Management Menu System
-- WoW API: 12.0.1 (The War Within)

CombatCoach = CombatCoach or {}
local CC = CombatCoach

-- ============================================================
-- Saved Variables defaults
-- ============================================================
CC.defaults = {
    enabled = true,
    submenus = {},
}

-- ============================================================
-- Core frame and event handling
-- ============================================================
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

-- ============================================================
-- OnLoad: initialize saved variables
-- ============================================================
function CC:OnLoad()
    -- Initialize saved variables
    if not CombatCoachDB then
        CombatCoachDB = CopyTable(self.defaults)
    end
    self.db = CombatCoachDB

    -- Merge any new defaults
    for k, v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

    print("|cFF00CCFFCombatCoach|r loaded. Type |cFFFFFF00/coach|r or |cFFFFFF00/CombatCoach|r for options.")
end

-- ============================================================
-- OnLogin: register settings panel after all addons are loaded
-- ============================================================
function CC:OnLogin()
    CC.Menu:BuildSettingsPanel()
    if CC.Profiles then
        CC.Profiles:AddButtonsToMainPanel()
    end
end

-- ============================================================
-- Slash commands
-- ============================================================
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
