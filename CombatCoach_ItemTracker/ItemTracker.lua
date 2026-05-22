-- ItemTracker.lua: tracks inventory items by name or itemID; delegates UI to shmIcons.

local FOLDER_NAME  = "CombatCoach_ItemTracker"
local ADDON_NAME   = "Item Tracker"
local DEFAULT_SIZE = 64

-- itemKey → { itemName, itemID }
local tracked = {}

local currentSpecID = nil

-- Change listeners for UI integrations (called when trackers change)
local changeListeners = {}

local function NotifyChangeListeners()
    for _, cb in ipairs(changeListeners) do
        local ok, err = pcall(cb)
        if not ok then print("|cFFFF4444ItemTracker: listener error: " .. tostring(err) .. "|r") end
    end
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

local function KeyFor(name)
    return tostring(name):lower():gsub("%s+", "_")
end

local function GetSpecItems(specID)
    ItemTrackerDB.specs               = ItemTrackerDB.specs               or {}
    ItemTrackerDB.specs[specID]       = ItemTrackerDB.specs[specID]       or {}
    ItemTrackerDB.specs[specID].items = ItemTrackerDB.specs[specID].items or {}
    return ItemTrackerDB.specs[specID].items
end

local function CountTracked()
    local n = 0
    for _ in pairs(tracked) do n = n + 1 end
    return n
end

local function GetItemDB(specID, key)
    local items = GetSpecItems(specID)
    if not items[key] then
        local n = CountTracked()
        items[key] = {
            x            = (n % 5) * (DEFAULT_SIZE + 4) - (2 * (DEFAULT_SIZE + 4)),
            y            = -math.floor(n / 5) * (DEFAULT_SIZE + 4),
            point        = "CENTER",
            size         = DEFAULT_SIZE,
            enabled      = true,
            glow_enabled = false,
        }
    end
    return items[key]
end

-- ============================================================
-- Item resolution
-- ============================================================

-- Resolve an item name or numeric itemID string to { itemName, itemID }.
-- For names: uses C_Item.GetItemInfoInstant which works even when the item
-- is not in the player's inventory, as long as the client has cached it.
-- For numeric input: treats it as an itemID directly.
-- Returns name, itemID or nil, nil on failure.
local function ResolveItem(input)
    -- Numeric input — treat as itemID
    local numericID = tonumber(input)
    if numericID then
        local name = select(1, GetItemInfo(numericID))
        if name then
            return name, numericID
        end
        -- Item data not yet cached — queue a server request and return nil.
        -- The player should re-run the command after a moment.
        C_Item.RequestLoadItemDataByID(numericID)
        return nil, nil
    end

    -- Name input — resolve to itemID
    local itemID = select(1, C_Item.GetItemInfoInstant(input))
    if itemID then
        -- Verify full data is available (needed for icon)
        local name = select(1, GetItemInfo(itemID))
        if name then
            return name, itemID
        end
        -- Cache miss — request and ask player to retry
        C_Item.RequestLoadItemDataByID(itemID)
        return nil, nil
    end

    return nil, nil
end

-- ============================================================
-- Update one tracked item
-- ============================================================

local function UpdateItem(key)
    local entry = tracked[key]
    if not entry then return end

    local itemID = entry.itemID

    -- Icon — only push to shmIcons when the texture actually changes
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
    local newIcon = texture or 134400
    if entry.cachedIcon ~= newIcon then
        entry.cachedIcon = newIcon
        shmIcons:SetIcon(ADDON_NAME, key, newIcon)
    end

    -- Stack count — only push to shmIcons when count changes
    local count = GetItemCount(itemID, false, true) or 0
    if entry.cachedCount ~= count then
        entry.cachedCount = count
        shmIcons:SetStacks(ADDON_NAME, key, count)
    end

    -- Cooldown — only meaningful if we have at least one
    if count > 0 then
        local start, duration, enable = GetItemCooldown(itemID)
        local onCooldown = start and duration and duration > 1.5
        
        if itemID == 5512 then --Healthstone
           local durationObject = C_Spell.GetSpellCooldownDuration(5512)
           if(durationObject) then
            shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
           end
           if(enable) then
            shmIcons:SetUsable(ADDON_NAME, key, true)
            else
            shmIcons:SetUsable(ADDON_NAME, key, false)            
           end
        else
            local onCooldown = start and duration and duration > 1.5
            shmIcons:SetCooldownRaw(ADDON_NAME, key, start, duration)
            shmIcons:SetGlow(ADDON_NAME, key, not onCooldown)
            shmIcons:SetUsable(ADDON_NAME, key, true)
        end
    else
        -- Item not in inventory: clear cooldown, no glow, gray out
        shmIcons:SetCooldownRaw(ADDON_NAME, key, nil, nil)
        shmIcons:SetGlow(ADDON_NAME, key, false)
        shmIcons:SetUsable(ADDON_NAME, key, false)
    end
end

local function UpdateAllItems()
    for key in pairs(tracked) do UpdateItem(key) end
end

-- ============================================================
-- Add / remove tracker
-- ============================================================

local function AddItem(input, specID)
    specID = specID or currentSpecID

    local itemName, itemID = ResolveItem(input)
    if not itemID then
        if tonumber(input) then
            print("|cFFFF0000ItemTracker: item ID " .. input .. " not found. Item data may still be loading — try again in a moment.|r")
        else
            print("|cFFFF0000ItemTracker: item '" .. input .. "' not found. Check the spelling or try the numeric item ID.|r")
        end
        return
    end

    local key = KeyFor(itemName)
    local db  = GetItemDB(specID, key)

    db.enabled  = true
    db.itemName = itemName
    db.itemID   = itemID

    shmIcons:Register(ADDON_NAME, key, db, {
        onResize = function(sq)
            GetSpecItems(specID)[key].size = sq
        end,
    })

    tracked[key] = { itemName = itemName, itemID = itemID, cachedIcon = nil, cachedCount = nil }
    UpdateItem(key)
    -- notify external UIs (CombatCoach) so they can refresh lists
    NotifyChangeListeners()
end

local function RemoveItem(key)
    shmIcons:Unregister(ADDON_NAME, key)
    tracked[key] = nil
    local items = GetSpecItems(currentSpecID)
    if items[key] then items[key].enabled = false end
    -- notify external UIs (CombatCoach) so they can refresh lists
    NotifyChangeListeners()
end

local function UnloadSpec()
    for key in pairs(tracked) do
        shmIcons:Unregister(ADDON_NAME, key)
    end
    tracked = {}
    -- notify external UIs that tracked list changed (cleared)
    NotifyChangeListeners()
end

local function LoadSpec(specID)
    UnloadSpec()
    currentSpecID = specID
    local items = GetSpecItems(specID)
    for key, db in pairs(items) do
        -- Restore by itemID (which we stored) so items not in inventory
        -- are still tracked correctly.
        if db.enabled and db.itemID then
            local itemName = db.itemName or tostring(db.itemID)
            -- Use itemID directly to avoid re-resolving by name
            local name = select(1, GetItemInfo(db.itemID)) or itemName
            shmIcons:Register(ADDON_NAME, key, db, {
                onResize = function(sq)
                    GetSpecItems(specID)[key].size = sq
                end,
            })
            tracked[key] = { itemName = name, itemID = db.itemID, cachedIcon = nil, cachedCount = nil }
        end
    end
    shmIcons:RestoreSnapGroups()
    UpdateAllItems()
    -- notify external UIs so they can refresh when specialization changes
    NotifyChangeListeners()
end

-- ============================================================
-- Public API (used by ItemTracker_Commands.lua and external callers)
-- ============================================================

function ItemTracker_KeyFor(name)            return KeyFor(name)                          end
function ItemTracker_IsTracked(key)          return tracked[key] ~= nil                   end
function ItemTracker_GetTracked()            return tracked                               end
function ItemTracker_GetCurrentSpecItems()   return GetSpecItems(currentSpecID)           end
function ItemTracker_UpdateItem(key)         UpdateItem(key)                              end
function ItemTracker_Remove(key)             RemoveItem(key)                              end
function ItemTracker_Add(name)               AddItem(name)                               end

-- ============================================================
-- Event Handling
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == FOLDER_NAME then
        ItemTrackerDB = ItemTrackerDB or { specs = {} }
        ItemTrackerDB.specs = ItemTrackerDB.specs or {}

    elseif event == "PLAYER_ENTERING_WORLD" then
        local specID = GetCurrentSpecID()
        if specID ~= currentSpecID then
            LoadSpec(specID)
        else
            UpdateAllItems()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpec(GetCurrentSpecID())

    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- Item data just loaded from server — refresh icons that may have
        -- been showing a question mark placeholder.
        UpdateAllItems()

    elseif event == "BAG_UPDATE_COOLDOWN"
        or  event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateAllItems()

    elseif event == "BAG_UPDATE"
        or  event == "ITEM_COUNT_CHANGED" then
        UpdateAllItems()
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("ITEM_COUNT_CHANGED")


-- Public API wrappers for CombatCoach UI and other integrations
function ItemTracker_Add(itemName, specID)
    AddItem(itemName, specID)
end

function ItemTracker_Remove(itemName)
    local key = KeyFor(itemName)
    if tracked[key] then RemoveItem(key) end
end

function ItemTracker_ToggleGlow(itemName)
    local key = KeyFor(itemName)
    if not tracked[key] then
        print("|cFFFF0000ItemTracker: not tracking '" .. itemName .. "'.|r")
        return
    end
    local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, key)
    local state = enabled and "|cFF00FF00enabled|r" or "|cFFFFFF00disabled|r"
    print("ItemTracker: glow " .. state .. " for " .. itemName .. ".")
    UpdateItem(key)
end

function ItemTracker_Reset(itemName)
    local key = KeyFor(itemName)
    if not tracked[key] then
        print("|cFFFF0000ItemTracker: not tracking '" .. itemName .. "'.|r")
        return
    end
    shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
    print("|cFF00FF00ItemTracker: reset " .. itemName .. ".|r")
end

function ItemTracker_ResetAll()
    for key in pairs(tracked) do
        shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
    end
    print("|cFF00FF00ItemTracker: All positions reset.|r")
end

function ItemTracker_ToggleLock()
    local locked = shmIcons:ToggleLock()
    local state = locked
        and "|cFF00FF00Locked.|r"
        or  "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
    print("shmIcons: All icons " .. state)
    return locked
end

function ItemTracker_List()
    local found = false
    for key, entry in pairs(tracked) do
        local db        = GetSpecItems(currentSpecID)[key]
        local glowState = db and db.glow_enabled and "glow on" or "glow off"
        local count     = GetItemCount(entry.itemID, false, false) or 0
        local countStr  = count > 0 and ("|cFFFFFFFFx" .. count .. "|r") or "|cFFFF4444none in bags|r"
        print(string.format("|cFFFFFF00  %s|r  [ID:%d]  %s  [%s]",
            entry.itemName, entry.itemID, countStr, glowState))
        found = true
    end
    if not found then print("|cFFFFFF00ItemTracker: no items tracked yet.|r") end
end

-- Allow external UI to register a callback to be notified when the tracked
-- items for the current spec change (add/remove).
function ItemTracker_RegisterChangeListener(fn)
    changeListeners[#changeListeners + 1] = fn
end

-- Return a simple array of tracked item entries for the given specID.
function ItemTracker_GetTrackedItems(specID)
    specID = specID or GetCurrentSpecID()
    local items = GetSpecItems(specID)
    local out = {}
    for key, db in pairs(items) do
        if db and db.enabled and db.itemID then
            out[#out + 1] = { key = key, db = db, itemName = db.itemName, itemID = db.itemID }
        end
    end
    return out
end

-- Central command handler (optional) so UI and slash both use the same logic
function ItemTracker_HandleCommand(msg)
    if SlashCmdList and SlashCmdList["ITEMTRACKER"] then
        SlashCmdList["ITEMTRACKER"](msg)
    end
end