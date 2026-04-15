local ADDON_NAME = ...

local frame = CreateFrame("Frame")

-- Spell ID for Whirling Dragon Punch
local WDP_SPELL_ID = 152175

-- Track last known usable state
local lastUsable = false

-- Cache action slot once found
local wdpSlot = nil

-- Safely find the action slot containing WDP
local function FindWDPSlot()
    for slot = 1, 180 do
        local actionType, id = GetActionInfo(slot)

        if actionType == "spell" and id == WDP_SPELL_ID then
            return slot
        end
    end

    return nil
end

-- Safe usability check using action system only
local function IsWDPUsable(slot)
    if not slot then return false end

    local usable = IsUsableAction(slot)
    local start, duration = GetActionCooldown(slot)

    -- duration == 0 is safe here (sanitized action API, not secret values)
    if usable and duration == 0 then
        return true
    end

    return false
end

-- Core update logic
local function Update()
    if not wdpSlot then
        wdpSlot = FindWDPSlot()
        if not wdpSlot then return end
    end

    local usable = IsWDPUsable(wdpSlot)

    -- Detect transition: false -> true
    if usable and not lastUsable then
        print("Whirling Dragon Punch is ready!")
    end

    lastUsable = usable
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        wdpSlot = FindWDPSlot()
        Update()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        wdpSlot = FindWDPSlot()
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        Update()
    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        Update()
    end
end)

-- Register only safe, relevant events
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")