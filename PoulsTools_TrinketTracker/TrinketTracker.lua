-- ============================================================
-- TrinketTracker.lua  (WoW Midnight 12.0.1)
-- Tracks any equipment slot cooldown on demand, per specialization.
-- Delegates all icon/glow/snap/drag UI to shmIcons.
--
-- /tt                  → toggle lock/unlock all frames
-- /tt slot <1-19>      → add or remove a slot tracker
-- /tt glow <#>         → toggle ready glow for a slot
-- /tt reset <#>        → reset one slot's position/size
-- /tt reset all        → reset all positions/sizes
-- /tt list             → list tracked slots
-- ============================================================

local ADDON_NAME   = "PoulsTools_TrinketTracker"
local DEFAULT_SIZE = 64

local SLOT_NAMES = {
    [1]  = "Head",      [2]  = "Neck",      [3]  = "Shoulder",
    [4]  = "Shirt",     [5]  = "Chest",     [6]  = "Belt",
    [7]  = "Legs",      [8]  = "Feet",      [9]  = "Wrist",
    [10] = "Gloves",    [11] = "Ring 1",    [12] = "Ring 2",
    [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",  [18] = "Ranged",
    [19] = "Tabard",
}

-- slotID → true for the currently active spec's tracked slots
local trackedSlots = {}

-- The spec ID we last loaded icons for
local currentSpecID = nil

-- Change listeners for UI integrations (called when trackers change)
local changeListeners = {}

local function NotifyChangeListeners()
    for _, cb in ipairs(changeListeners) do
        local ok, err = pcall(cb)
        if not ok then print("|cFFFF4444TrinketTracker: listener error: " .. tostring(err) .. "|r") end
    end
end

-- ============================================================
-- Spec helper
-- ============================================================

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

-- ============================================================
-- Saved variable helpers
-- ============================================================

-- Return the slots table for the given specID, creating it if needed.
local function GetSpecSlots(specID)
    TrinketTrackerDB.specs             = TrinketTrackerDB.specs             or {}
    TrinketTrackerDB.specs[specID]     = TrinketTrackerDB.specs[specID]     or {}
    TrinketTrackerDB.specs[specID].slots = TrinketTrackerDB.specs[specID].slots or {}
    return TrinketTrackerDB.specs[specID].slots
end

local function CountTracked()
    local n = 0
    for _ in pairs(trackedSlots) do n = n + 1 end
    return n
end

local function GetSlotDB(specID, slotID)
    local slots = GetSpecSlots(specID)
    if not slots[slotID] then
        local n = CountTracked()
        slots[slotID] = {
            x            = (n % 5) * (DEFAULT_SIZE + 4) - (2 * (DEFAULT_SIZE + 4)),
            y            = -math.floor(n / 5) * (DEFAULT_SIZE + 4),
            point        = "CENTER",
            size         = DEFAULT_SIZE,
            enabled      = true,
            glow_enabled = false,
        }
    end
    -- Migrate old width/height schema to size
    local db = slots[slotID]
    if not db.size and (db.width or db.height) then
        db.size   = db.width or db.height or DEFAULT_SIZE
        db.width  = nil
        db.height = nil
    end
    return db
end

-- ============================================================
-- Cooldown + icon update for one slot
-- ============================================================

local function UpdateSlot(slotID)
    if not trackedSlots[slotID] then return end

    local itemID = GetInventoryItemID("player", slotID)
    local texture = itemID and select(10, GetItemInfo(itemID))
    shmIcons:SetIcon(ADDON_NAME, slotID, texture or 134400)

    local start, duration = GetInventoryItemCooldown("player", slotID)
    local onCooldown = start and duration and duration > 1.5

    shmIcons:SetCooldownRaw(ADDON_NAME, slotID, start, duration)
    shmIcons:SetGlow(ADDON_NAME, slotID, not onCooldown and itemID ~= nil)
end

local function UpdateAllSlots()
    for slotID in pairs(trackedSlots) do UpdateSlot(slotID) end
end

-- ============================================================
-- Add / remove slot
-- ============================================================

local function AddSlot(slotID, specID)
    specID = specID or currentSpecID
    local db = GetSlotDB(specID, slotID)
    shmIcons:Register(ADDON_NAME, slotID, db, {
        onResize = function(sq)
            GetSpecSlots(specID)[slotID].size = sq
        end,
    })
    trackedSlots[slotID] = true
    GetSpecSlots(specID)[slotID].enabled = true
    UpdateSlot(slotID)
    NotifyChangeListeners()
end

local function RemoveSlot(slotID)
    shmIcons:Unregister(ADDON_NAME, slotID)
    trackedSlots[slotID] = nil
    local slots = GetSpecSlots(currentSpecID)
    if slots[slotID] then slots[slotID].enabled = false end
    NotifyChangeListeners()
end

-- Unregister all current icons and clear trackedSlots.
local function UnloadSpec()
    for slotID in pairs(trackedSlots) do
        shmIcons:Unregister(ADDON_NAME, slotID)
    end
    trackedSlots = {}
    NotifyChangeListeners()
end

-- Load all enabled slots for the given specID.
local function LoadSpec(specID)
    UnloadSpec()
    currentSpecID = specID
    local slots = GetSpecSlots(specID)
    for slotID, db in pairs(slots) do
        if db.enabled then
            AddSlot(slotID, specID)
        end
    end
    shmIcons:RestoreSnapGroups()
    UpdateAllSlots()
    NotifyChangeListeners()
end

-- ============================================================
-- Slash Commands
-- ============================================================

SLASH_TRINKETTRACKER1 = "/tt"
SlashCmdList["TRINKETTRACKER"] = function(msg)
    local cmd = msg:lower():trim()

    local slotArg = cmd:match("^slot%s+(%d+)$")
    if slotArg then
        local slotID = tonumber(slotArg)
        if slotID < 1 or slotID > 19 then
            print("|cFFFF0000TrinketTracker: slot must be between 1 and 19.|r")
            return
        end
        local name = SLOT_NAMES[slotID] or ("Slot " .. slotID)
        if trackedSlots[slotID] then
            RemoveSlot(slotID)
            print("|cFFFFFF00TrinketTracker: removed tracker for " .. name .. ".|r")
        else
            AddSlot(slotID)
            print("|cFF00FF00TrinketTracker: now tracking " .. name .. ".|r")
        end
        return
    end

    local glowArg = cmd:match("^glow%s+(%d+)$")
    if glowArg then
        local slotID = tonumber(glowArg)
        if not trackedSlots[slotID] then
            print("|cFFFF0000TrinketTracker: slot " .. slotID .. " is not tracked.|r")
            return
        end
        local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, slotID)
        local state = enabled and "|cFF00FF00enabled|r" or "|cFFFFFF00disabled|r"
        print("TrinketTracker: glow " .. state .. " for slot " .. slotID .. ".")
        UpdateSlot(slotID)
        return
    end

    if cmd == "reset all" then
        for slotID in pairs(trackedSlots) do
            shmIcons:ResetIcon(ADDON_NAME, slotID, DEFAULT_SIZE)
        end
        print("|cFF00FF00TrinketTracker: All positions reset.|r")
        return
    end

    local resetArg = cmd:match("^reset%s+(%d+)$")
    if resetArg then
        local slotID = tonumber(resetArg)
        if not trackedSlots[slotID] then
            print("|cFFFF0000TrinketTracker: slot " .. slotID .. " is not tracked.|r")
            return
        end
        shmIcons:ResetIcon(ADDON_NAME, slotID, DEFAULT_SIZE)
        print("|cFF00FF00TrinketTracker: reset slot " .. slotID .. ".|r")
        return
    end

    if cmd == "lock" or cmd == "" then
        local locked = shmIcons:ToggleLock()
        local state = locked
            and "|cFF00FF00Locked.|r"
            or  "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
        print("shmIcons: All icons " .. state)
        return
    end

    if cmd == "list" then
        local found = false
        for slotID in pairs(trackedSlots) do
            local db        = GetSpecSlots(currentSpecID)[slotID]
            local name      = SLOT_NAMES[slotID] or ("Slot " .. slotID)
            local glowState = db and db.glow_enabled and "glow on" or "glow off"
            print(string.format("|cFFFFFF00  [%d] %s|r  [%s]", slotID, name, glowState))
            found = true
        end
        if not found then print("|cFFFFFF00TrinketTracker: no slots tracked yet.|r") end
        return
    end

    print("|cFFFFFF00TrinketTracker commands:|r")
    print("  /tt                  - toggle lock/unlock")
    print("  /tt slot <1-19>      - add or remove a slot tracker")
    print("  /tt glow <#>         - toggle ready glow for a slot")
    print("  /tt reset <#>        - reset one slot's position/size")
    print("  /tt reset all        - reset all positions/sizes")
    print("  /tt list             - list tracked slots")
end

-- ============================================================
-- Event Handling
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        TrinketTrackerDB = TrinketTrackerDB or { specs = {} }
        TrinketTrackerDB.specs = TrinketTrackerDB.specs or {}
        -- Spec data not available until PLAYER_ENTERING_WORLD; wait.

    elseif event == "PLAYER_ENTERING_WORLD" then
        local specID = GetCurrentSpecID()
        if specID ~= currentSpecID then
            LoadSpec(specID)
        else
            UpdateAllSlots()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpec(GetCurrentSpecID())

    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or  event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateAllSlots()
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

-- ============================================================
-- Public API for PoulsTools UI and other integrations
-- ============================================================

function TrinketTracker_Add(slotID, specID)
    local id = tonumber(slotID)
    if not id or id < 1 or id > 19 then return end
    if not trackedSlots[id] then
        AddSlot(id, specID)
        local name = SLOT_NAMES[id] or ("Slot " .. id)
        print("|cFF00FF00TrinketTracker: now tracking " .. name .. ".|r")
    end
end

function TrinketTracker_Remove(slotID)
    local id = tonumber(slotID)
    if not id then return end
    if trackedSlots[id] then
        RemoveSlot(id)
        local name = SLOT_NAMES[id] or ("Slot " .. id)
        print("|cFFFFFF00TrinketTracker: removed tracker for " .. name .. ".|r")
    end
end

function TrinketTracker_ToggleGlow(slotID)
    local id = tonumber(slotID)
    if not id or not trackedSlots[id] then return end
    local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, id)
    local db = GetSpecSlots(currentSpecID)[id]
    if db then db.glow_enabled = enabled end
    UpdateSlot(id)
    return enabled
end

function TrinketTracker_Reset(slotID)
    local id = tonumber(slotID)
    if not id or not trackedSlots[id] then return end
    shmIcons:ResetIcon(ADDON_NAME, id, DEFAULT_SIZE)
    local name = SLOT_NAMES[id] or ("Slot " .. id)
    print("|cFF00FF00TrinketTracker: reset " .. name .. ".|r")
end

function TrinketTracker_ResetAll()
    for slotID in pairs(trackedSlots) do
        shmIcons:ResetIcon(ADDON_NAME, slotID, DEFAULT_SIZE)
    end
    print("|cFF00FF00TrinketTracker: All positions reset.|r")
end

function TrinketTracker_ToggleLock()
    local locked = shmIcons:ToggleLock()
    local state = locked and "|cFF00FF00Locked.|r" or "|cFFFFFF00Unlocked.|r"
    print("shmIcons: All icons " .. state)
    return locked
end

function TrinketTracker_List()
    local found = false
    for slotID in pairs(trackedSlots) do
        local db        = GetSpecSlots(currentSpecID)[slotID]
        local name      = SLOT_NAMES[slotID] or ("Slot " .. slotID)
        local glowState = db and db.glow_enabled and "glow on" or "glow off"
        print(string.format("|cFFFFFF00  [%d] %s|r  [%s]", slotID, name, glowState))
        found = true
    end
    if not found then print("|cFFFFFF00TrinketTracker: no slots tracked yet.|r") end
end

-- Allow external UI to register a callback to be notified when the tracked
-- slots for the current spec change (add/remove/spec switch).
function TrinketTracker_RegisterChangeListener(fn)
    changeListeners[#changeListeners + 1] = fn
end

-- Return an array of tracked slot entries for the given specID.
function TrinketTracker_GetTrackedSlots(specID)
    local slots = GetSpecSlots(specID or currentSpecID or 0)
    local out = {}
    for slotID, db in pairs(slots) do
        if db.enabled then
            table.insert(out, {
                key      = tostring(slotID),
                slotID   = slotID,
                slotName = SLOT_NAMES[slotID] or ("Slot " .. slotID),
                db       = db,
            })
        end
    end
    return out
end