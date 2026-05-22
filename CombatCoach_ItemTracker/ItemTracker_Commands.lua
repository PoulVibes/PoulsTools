-- ItemTracker_Commands.lua
-- Slash command registration for ItemTracker.
-- All heavy lifting delegated to public API globals in ItemTracker.lua.
-- Loads after ItemTracker.lua.

local ADDON_NAME   = "Item Tracker"
local DEFAULT_SIZE = 64

SLASH_ITEMTRACKER1 = "/it"
SlashCmdList["ITEMTRACKER"] = function(msg)
    local cmd = msg:lower():trim()

    -- /it glow <item name>
    local glowName = cmd:match("^glow%s+(.+)$")
    if glowName then
        local key = ItemTracker_KeyFor(glowName)
        if not ItemTracker_IsTracked(key) then
            print("|cFFFF0000ItemTracker: not tracking '" .. glowName .. "'.|r")
            return
        end
        local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, key)
        local state = enabled and "|cFF00FF00enabled|r" or "|cFFFFFF00disabled|r"
        print("ItemTracker: glow " .. state .. " for " .. glowName .. ".")
        ItemTracker_UpdateItem(key)
        return
    end

    -- /it reset all
    if cmd == "reset all" then
        for key in pairs(ItemTracker_GetTracked()) do
            shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
        end
        print("|cFF00FF00ItemTracker: All positions reset.|r")
        return
    end

    -- /it reset <item name>
    local resetName = cmd:match("^reset%s+(.+)$")
    if resetName then
        local key = ItemTracker_KeyFor(resetName)
        if not ItemTracker_IsTracked(key) then
            print("|cFFFF0000ItemTracker: not tracking '" .. resetName .. "'.|r")
            return
        end
        shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
        print("|cFF00FF00ItemTracker: reset " .. resetName .. ".|r")
        return
    end

    -- /it lock
    if cmd == "lock" then
        local locked = shmIcons:ToggleLock()
        local state = locked
            and "|cFF00FF00Locked.|r"
            or  "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
        print("shmIcons: All icons " .. state)
        return
    end

    -- /it list
    if cmd == "list" then
        local tracked   = ItemTracker_GetTracked()
        local specItems = ItemTracker_GetCurrentSpecItems()
        local found = false
        for key, entry in pairs(tracked) do
            local db        = specItems[key]
            local glowState = db and db.glow_enabled and "glow on" or "glow off"
            local count     = GetItemCount(entry.itemID, false, false) or 0
            local countStr  = count > 0 and ("|cFFFFFFFFx" .. count .. "|r") or "|cFFFF4444none in bags|r"
            print(string.format("|cFFFFFF00  %s|r  [ID:%d]  %s  [%s]",
                entry.itemName, entry.itemID, countStr, glowState))
            found = true
        end
        if not found then print("|cFFFFFF00ItemTracker: no items tracked yet.|r") end
        return
    end

    -- /it  (no args) → help
    if cmd == "" then
        print("|cFFFFFF00ItemTracker commands:|r")
        print("  /it <name or itemID>   - add or remove a tracker")
        print("  /it glow <name>        - toggle ready glow")
        print("  /it lock               - toggle lock/unlock all frames")
        print("  /it reset <name>       - reset position/size")
        print("  /it reset all          - reset all positions/sizes")
        print("  /it list               - list tracked items with counts")
        return
    end

    -- /it <name or itemID> → add or remove
    local key = ItemTracker_KeyFor(msg:trim())
    if ItemTracker_IsTracked(key) then
        ItemTracker_Remove(key)
        print("|cFFFFFF00ItemTracker: removed tracker for " .. msg:trim() .. ".|r")
    else
        ItemTracker_Add(msg:trim())
    end
end
