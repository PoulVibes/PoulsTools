-- shmIcons_Hotkeys.lua
-- Binding lookup and hotkey display cache.

function GetBindingActionForActionSlot(slot)
    if slot >= 1  and slot <= 12 then return "ACTIONBUTTON"          .. slot        end
    if slot >= 13 and slot <= 24 then return "MULTIACTIONBAR5BUTTON" .. (slot - 12) end
    if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR3BUTTON" .. (slot - 24) end
    if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR4BUTTON" .. (slot - 36) end
    if slot >= 49 and slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. (slot - 48) end
    if slot >= 61 and slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. (slot - 60) end
    if slot >= 73 and slot <= 84 then return "MULTIACTIONBAR6BUTTON" .. (slot - 72) end
    if slot >= 85 and slot <= 96 then return "MULTIACTIONBAR7BUTTON" .. (slot - 84) end
    return nil
end

function ShortenHotkey(key)
    if type(key) ~= "string" or key == "" then return nil end

    local function replacePlain(str, token, replacement)
        local out = str
        local from = 1
        while true do
            local s, e = out:find(token, from, true)
            if not s then break end
            out = out:sub(1, s - 1) .. replacement .. out:sub(e + 1)
            from = s + #replacement
        end
        return out
    end

    local hasCtrl  = key:find("CTRL-", 1, true)  ~= nil
    local hasAlt   = key:find("ALT-", 1, true)   ~= nil
    local hasShift = key:find("SHIFT-", 1, true) ~= nil

    local base = key
    base = replacePlain(base, "CTRL-", "")
    base = replacePlain(base, "ALT-", "")
    base = replacePlain(base, "SHIFT-", "")
    base = replacePlain(base, "BUTTON", "B")
    base = replacePlain(base, "NUMPAD", "N")
    base = replacePlain(base, "PLUS", "[+]")
    base = replacePlain(base, "MINUS", "[-]")
    base = replacePlain(base, "EQUAL", "[=]")
    base = replacePlain(base, "MULTIPLY", "[*]")
    base = replacePlain(base, "DIVIDE", "[/]")
    base = replacePlain(base, "DECIMAL", "[.]")
    base = replacePlain(base, "PAGE_UP", "PG_UP")
    base = replacePlain(base, "PAGE_DOWN", "PG_DN")
    local mods = (hasCtrl and "C+" or "") .. (hasAlt and "A+" or "") .. (hasShift and "S+" or "")
    return mods ~= "" and (mods .. base) or base
end
hotkeyCache = {}

local hotkeyEventFrame = CreateFrame("Frame")
hotkeyEventFrame:RegisterEvent("PLAYER_LOGIN")
hotkeyEventFrame:RegisterEvent("PLAYER_LOGOUT")
hotkeyEventFrame:RegisterEvent("UPDATE_BINDINGS")
hotkeyEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
hotkeyEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        shmIconsDB = shmIconsDB or {}
        if shmIconsDB.hotkeyCache then
            hotkeyCache = shmIconsDB.hotkeyCache
        end
    elseif event == "PLAYER_LOGOUT" then
        shmIconsDB = shmIconsDB or {}
        shmIconsDB.hotkeyCache = hotkeyCache
    else
        hotkeyCache = {}
    end
end)

function LookupHotkeyForTexture(textureID)
    if not textureID then return nil end

    local cached = hotkeyCache[textureID]
    if cached ~= nil then return cached end

    for slot = 1, 96 do
        if C_ActionBar.HasAction(slot) then
            local tex = (C_ActionBar.GetActionTexture and C_ActionBar.GetActionTexture(slot))
                     or (GetActionTexture and GetActionTexture(slot))
            if tex == textureID then
                local bindingAction = GetBindingActionForActionSlot(slot)
                if bindingAction then
                    local key = GetBindingKey(bindingAction)
                    if key then
                        local short = ShortenHotkey(key)
                        hotkeyCache[textureID] = short
                        return short
                    end
                end
            end
        end
    end

    return nil
end
