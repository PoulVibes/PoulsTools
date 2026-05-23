-- SBA_Simple_SlashCommands.lua
-- Slash commands for SBA_Simple.

SLASH_SBASIMPLE1 = "/SBAS"
SlashCmdList["SBASIMPLE"] = function(msg)
    local cmd = msg:match("^%s*(.-)%s*$"):lower()
    if cmd == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    elseif cmd == "reset" then
        SBA_Simple_ResetMainIconPosition()
    elseif cmd == "override" then
        SBA_Simple_ToggleOverrideEditor()
    elseif cmd == "override_debug" then
        local db = SBA_Simple_GetDB()
        db.overrideDebug = not db.overrideDebug
        print("|cff00ff99SBA_Simple:|r override runtime debug " .. (db.overrideDebug and "enabled." or "disabled."))
    elseif cmd == "override_error" then
        local lastError = SBA_Simple_GetLastOverrideRuntimeError()
        if lastError then
            print("|cffff4444SBA_Simple override last error:|r " .. lastError)
        else
            print("|cff00ff99SBA_Simple:|r no runtime override error recorded yet.")
        end
    else
        print("|cff00ccffSBA_Simple|r commands:")
        print("  /SBAS lock          - toggle move/resize lock for all shmIcons")
        print("  /SBAS override      - toggle the raw Lua override code editor")
        print("  /SBAS override_debug - toggle runtime override error prints")
        print("  /SBAS override_error - print the last runtime override error")
        print("  /SBAS reset         - reset icon position and size")
    end
end
