-- PoulsTools.lua
-- Main addon file for PoulsTools - Addon Management Menu System
-- WoW API: 12.0.1 (The War Within)

PoulsTools = PoulsTools or {}
local PT = PoulsTools

-- ============================================================
-- Saved Variables defaults
-- ============================================================
PT.defaults = {
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
        if addonName == "PoulsTools" then
            PT:OnLoad()
        end
    elseif event == "PLAYER_LOGIN" then
        PT:OnLogin()
    end
end)

-- ============================================================
-- OnLoad: initialize saved variables
-- ============================================================
function PT:OnLoad()
    -- Initialize saved variables
    if not PoulsToolsDB then
        PoulsToolsDB = CopyTable(self.defaults)
    end
    self.db = PoulsToolsDB

    -- Merge any new defaults
    for k, v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

    print("|cFF00CCFFPoulsTools|r loaded. Type |cFFFFFF00/pt|r or |cFFFFFF00/poulstools|r for options.")
end

-- ============================================================
-- OnLogin: register settings panel after all addons are loaded
-- ============================================================
function PT:OnLogin()
    PT.Menu:BuildSettingsPanel()
    if PT.Profiles then
        PT.Profiles:AddButtonsToMainPanel()
    end
end

-- ============================================================
-- Slash commands
-- ============================================================
SLASH_POULSTOOLS1 = "/pt"
SLASH_POULSTOOLS2 = "/poulstools"

SlashCmdList["POULSTOOLS"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "" or msg == "options" or msg == "config" then
        if InCombatLockdown() then
            print("|cFFFF4444PoulsTools:|r Cannot open settings during combat.")
            return
        end
        if PT.Menu.mainCategory then
            Settings.OpenToCategory(PT.Menu.mainCategory:GetID())
        else
            print("|cFFFF4444PoulsTools:|r Settings panel not yet initialized.")
        end
    elseif msg == "help" then
        PT:PrintHelp()
    else
        PT:PrintHelp()
    end
end

function PT:PrintHelp()
    print("|cFF00CCFFPoulsTools|r commands:")
    print("  |cFFFFFF00/pt|r or |cFFFFFF00/pt options|r - Open PoulsTools settings")
    print("  |cFFFFFF00/pt help|r - Show this help")
end
