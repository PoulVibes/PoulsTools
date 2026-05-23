-- shmIcons_Hotkeys.lua
-- Binding lookup and hotkey display cache.

function GetBindingActionForActionSlot(slot)
    if slot >= 1  and slot <= 12 then return "ACTIONBUTTON"          .. slot        end
    if slot >= 13 and slot <= 24 then return "MULTIACTIONBAR5BUTTON" .. (slot - 12) end
    if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR4BUTTON" .. (slot - 24) end
    if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR3BUTTON" .. (slot - 36) end
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
    local mods = (hasCtrl and "C+" or "") .. (hasAlt and "A+" or "") .. (hasShift and "S+" or "")
    return mods ~= "" and (mods .. base) or base
end

function LookupHotkeyForTexture(textureID)
    if not textureID then return nil end
    if not hotkeyMapBuilt and type(BuildHotkeyMap) == "function" then
        BuildHotkeyMap()
    end
    if hotkeyMapBuilt then
        return hotkeyCache[textureID] or nil
    end
    local cached = hotkeyCache[textureID]
    if cached ~= nil then return cached or nil end
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
    hotkeyCache[textureID] = false
    return nil
end

function BuildHotkeyMap()
    local wipeFn = (table and table.wipe) or wipe
    hotkeyCache = hotkeyCache or {}
    if wipeFn then
        wipeFn(hotkeyCache)
    else
        hotkeyCache = {}
    end
    hotkeyMapBuilt = false
    for slot = 1, 96 do
        if C_ActionBar.HasAction(slot) then
            local tex = (C_ActionBar.GetActionTexture and C_ActionBar.GetActionTexture(slot))
                     or (GetActionTexture and GetActionTexture(slot))
            if tex and not hotkeyCache[tex] then
                local bindingAction = GetBindingActionForActionSlot(slot)
                if bindingAction then
                    local key = GetBindingKey(bindingAction)
                    if key then
                        hotkeyCache[tex] = ShortenHotkey(key)
                    end
                end
            end
        end
    end
    hotkeyMapBuilt = true
    for _, icon in pairs(icons) do
        if icon.displayHotkey and icon.hotkeyLabel and icon.currentTextureID then
            local key = hotkeyCache[icon.currentTextureID]
            if key then
                icon.hotkeyLabel:SetText(key)
                icon.hotkeyLabel:Show()
            else
                icon.hotkeyLabel:SetText("")
                icon.hotkeyLabel:Hide()
            end
        end
    end
end

local hotkeyEventFrame = CreateFrame("Frame")
local hotkeyRebuildPending = false
local function ScheduleHotkeyMapRebuild()
    if hotkeyRebuildPending then return end
    hotkeyRebuildPending = true
    C_Timer.After(0.05, function()
        hotkeyRebuildPending = false
        BuildHotkeyMap()
    end)
end
hotkeyEventFrame:RegisterEvent("PLAYER_LOGIN")
hotkeyEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
hotkeyEventFrame:RegisterEvent("UPDATE_BINDINGS")
hotkeyEventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
hotkeyEventFrame:SetScript("OnEvent", function() ScheduleHotkeyMapRebuild() end)
ScheduleHotkeyMapRebuild()
