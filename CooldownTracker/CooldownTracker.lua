-- ============================================================
-- CooldownTracker.lua  (WoW Midnight 12.0.1)
-- Tracks any ability cooldown by spell name, per specialization.
-- Delegates all icon/glow/snap/drag UI to shmIcons.
--
-- /cdt <ability name>       → add tracker (or remove if already tracked)
-- /cdt glow <ability name>  → toggle ready glow for that ability
-- /cdt lock                 → toggle lock/unlock all frames
-- /cdt reset <ability name> → reset that ability's frame to default pos/size
-- /cdt reset all            → reset all frames
-- /cdt list                 → list all tracked abilities
-- ============================================================

local ADDON_NAME   = "CooldownTracker"
local DEFAULT_SIZE = 64

-- spellKey → { spellName, spellID } for the currently active spec
local tracked = {}

-- Change listeners for UI integrations (called when trackers change)
local changeListeners = {}

local function NotifyChangeListeners()
    for _, cb in ipairs(changeListeners) do
        local ok, err = pcall(cb)
        if not ok then print("|cFFFF4444CooldownTracker: listener error: " .. tostring(err) .. "|r") end
    end
end

-- The spec ID we last loaded icons for
local currentSpecID = nil

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

local function KeyFor(spellName)
    return spellName:lower():gsub("%s+", "_")
end

-- Return the spells table for the given specID, creating it if needed.
local function GetSpecSpells(specID)
    CooldownTrackerDB.specs             = CooldownTrackerDB.specs             or {}
    CooldownTrackerDB.specs[specID]     = CooldownTrackerDB.specs[specID]     or {}
    CooldownTrackerDB.specs[specID].spells = CooldownTrackerDB.specs[specID].spells or {}
    return CooldownTrackerDB.specs[specID].spells
end

local function CountTracked()
    local n = 0
    for _ in pairs(tracked) do n = n + 1 end
    return n
end

local function GetSpellDB(specID, key)
    local spells = GetSpecSpells(specID)
    if not spells[key] then
        local n = CountTracked()
        spells[key] = {
            x            = (n % 5) * (DEFAULT_SIZE + 4) - (2 * (DEFAULT_SIZE + 4)),
            y            = -math.floor(n / 5) * (DEFAULT_SIZE + 4),
            point        = "CENTER",
            size         = DEFAULT_SIZE,
            enabled      = true,
            glow_enabled = false,
        }
    end
    return spells[key]
end

-- ============================================================
-- Cooldown + icon update for one spell
-- ============================================================

local function UpdateTracker(key)
    local entry = tracked[key]
    if not entry then return end
    local spellInfo = C_Spell.GetSpellInfo(entry.spellID)
    shmIcons:SetIcon(ADDON_NAME, key, spellInfo and spellInfo.iconID or 134400)
    local cdInfo            = C_Spell.GetSpellCooldown(entry.spellID)
    local durationObject    = C_Spell.GetSpellCooldownDuration(entry.spellID)
    local chargeInfo        = C_Spell.GetSpellCharges(entry.spellID)
    local isChargeSpell     = chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1
    local chargeDuration    = C_Spell.GetSpellChargeDuration(entry.spellID)
    if isChargeSpell then
        if chargeDuration then
            shmIcons:SetCooldown(ADDON_NAME, key, chargeDuration)
            shmIcons:SetGlow(ADDON_NAME, key, false)
        elseif durationObject then
            shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
            if cdInfo.isActive then
                shmIcons:SetGlow(ADDON_NAME, key, true)
            else
                shmIcons:SetGlow(ADDON_NAME, key, false)
            end
        else
            shmIcons:SetCooldown(ADDON_NAME, key, nil)
            shmIcons:SetGlow(ADDON_NAME, key, true)
        end
        shmIcons:SetStacks(ADDON_NAME, key, chargeInfo.currentCharges)
    else
        shmIcons:SetChargeCooldown(ADDON_NAME, key, nil)
        if durationObject and cdInfo and cdInfo.isActive then
            shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
            shmIcons:SetGlow(ADDON_NAME, key, false)
        else
            shmIcons:SetCooldown(ADDON_NAME, key, nil)
            shmIcons:SetGlow(ADDON_NAME, key, true)
        end
        shmIcons:SetStacks(ADDON_NAME, key, 0)
    end
    if UnitExists("target") then
        shmIcons:SetRange(ADDON_NAME, key, C_Spell.IsSpellInRange(entry.spellID, "target"))
    else
        shmIcons:SetRange(ADDON_NAME, key, nil)
    end
    shmIcons:SetUsable(ADDON_NAME, key, C_Spell.IsSpellUsable(entry.spellID))
end

local function UpdateAllTrackers()
    for key in pairs(tracked) do UpdateTracker(key) end
end

-- ============================================================
-- Add / remove tracker
-- ============================================================

local function AddTracker(spellName, specID)
    specID = specID or currentSpecID
    local spellID = C_Spell.GetSpellIDForSpellIdentifier(spellName)
    if not spellID then
        print("|cFFFF0000CooldownTracker: spell not found: " .. spellName .. "|r")
        return
    end

    local key = KeyFor(spellName)
    local db  = GetSpellDB(specID, key)

    db.enabled   = true
    db.spellName = spellName
    db.spellID   = spellID

    shmIcons:Register(ADDON_NAME, key, db, {
        onResize = function(sq)
            GetSpecSpells(specID)[key].size = sq
        end,
    })

    tracked[key] = { spellName = spellName, spellID = spellID }
    UpdateTracker(key)
    -- notify any UI listeners so they can refresh lists
    NotifyChangeListeners()
end

local function RemoveTracker(key)
    shmIcons:Unregister(ADDON_NAME, key)
    tracked[key] = nil
    local spells = GetSpecSpells(currentSpecID)
    if spells[key] then spells[key].enabled = false end
    -- notify UI listeners
    NotifyChangeListeners()
end

-- Unregister all current icons and clear tracked table.
local function UnloadSpec()
    for key in pairs(tracked) do
        shmIcons:Unregister(ADDON_NAME, key)
    end
    tracked = {}
    -- notify UI listeners that the tracked list changed (cleared)
    NotifyChangeListeners()
end

-- Load all enabled spells for the given specID.
local function LoadSpec(specID)
    UnloadSpec()
    currentSpecID = specID
    local spells = GetSpecSpells(specID)
    for key, db in pairs(spells) do
        if db.enabled and db.spellName and db.spellID then
            AddTracker(db.spellName, specID)
        end
    end
    shmIcons:RestoreSnapGroups()
    UpdateAllTrackers()
    -- Notify listeners so UI (PoulsTools) can refresh when specialization changes
    NotifyChangeListeners()
end

-- ============================================================
-- Slash Commands
-- ============================================================

SLASH_COOLDOWNTRACKER1 = "/cdt"

-- Central command handler so UI and slash both use the same logic
function CooldownTracker_HandleCommand(msg)
    local raw = (type(msg) == "string") and msg or ""
    local cmd = (raw or ""):lower():trim()

    local glowName = cmd:match("^glow%s+(.+)$")
    if glowName then
        local key = KeyFor(glowName)
        if not tracked[key] then
            print("|cFFFF0000CooldownTracker: not tracking '" .. glowName .. "'.|r")
            return
        end
        local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, key)
        local state = enabled and "|cFF00FF00enabled|r" or "|cFFFFFF00disabled|r"
        print("CooldownTracker: glow " .. state .. " for " .. glowName .. ".")
        UpdateTracker(key)
        return
    end

    if cmd == "reset all" then
        for key in pairs(tracked) do
            shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
        end
        print("|cFF00FF00CooldownTracker: All positions reset.|r")
        return
    end

    local resetName = cmd:match("^reset%s+(.+)$")
    if resetName then
        local key = KeyFor(resetName)
        if not tracked[key] then
            print("|cFFFF0000CooldownTracker: not tracking '" .. resetName .. "'.|r")
            return
        end
        shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
        print("|cFF00FF00CooldownTracker: reset " .. resetName .. ".|r")
        return
    end

    if cmd == "lock" then
        local locked = shmIcons:ToggleLock()
        local state = locked
            and "|cFF00FF00Locked.|r"
            or  "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
        print("shmIcons: All icons " .. state)
        return
    end

    if cmd == "list" then
        local found = false
        for key, entry in pairs(tracked) do
            local db        = GetSpecSpells(currentSpecID)[key]
            local glowState = db and db.glow_enabled and "glow on" or "glow off"
            print(string.format("|cFFFFFF00  %s|r  [%s]", entry.spellName, glowState))
            found = true
        end
        if not found then print("|cFFFFFF00CooldownTracker: no abilities tracked yet.|r") end
        return
    end

    if cmd == "" then
        print("|cFFFFFF00CooldownTracker commands:|r")
        print("  /cdt <ability>         - add or remove a tracker")
        print("  /cdt glow <ability>    - toggle ready glow")
        print("  /cdt lock              - toggle lock/unlock all frames")
        print("  /cdt reset <ability>   - reset position/size for one ability")
        print("  /cdt reset all         - reset all positions/sizes")
        print("  /cdt list              - list tracked abilities")
        return
    end

    local key = KeyFor(raw:trim())
    if tracked[key] then
        RemoveTracker(key)
        print("|cFFFFFF00CooldownTracker: removed tracker for " .. raw:trim() .. ".|r")
    else
        AddTracker(raw:trim())
        print("|cFF00FF00CooldownTracker: now tracking " .. raw:trim() .. ".|r")
    end
end

SlashCmdList["COOLDOWNTRACKER"] = function(msg)
    CooldownTracker_HandleCommand(msg)
end

-- ============================================================
-- Event Handling
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        CooldownTrackerDB = CooldownTrackerDB or { specs = {} }
        CooldownTrackerDB.specs = CooldownTrackerDB.specs or {}
        -- Spec data not available until PLAYER_ENTERING_WORLD; wait.

    elseif event == "PLAYER_ENTERING_WORLD" then
        local specID = GetCurrentSpecID()
        if specID ~= currentSpecID then
            LoadSpec(specID)
        else
            UpdateAllTrackers()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpec(GetCurrentSpecID())

    elseif event == "PLAYER_TARGET_CHANGED"
        or  event == "SPELL_UPDATE_COOLDOWN" then
        UpdateAllTrackers()
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

-- Public API wrappers for PoulsTools UI and other integrations
function CooldownTracker_Add(spellName, specID)
    AddTracker(spellName, specID)
end

function CooldownTracker_Remove(spellName)
    if not spellName then return end
    local key = KeyFor(spellName)
    if tracked[key] then
        RemoveTracker(key)
    else
        print("|cFFFF0000CooldownTracker: not tracking '" .. spellName .. "'.|r")
    end
end

function CooldownTracker_ToggleGlow(spellName)
    if not spellName then return end
    local key = KeyFor(spellName)
    if tracked[key] then
        local enabled = shmIcons:ToggleGlowEnabled(ADDON_NAME, key)
        local state = enabled and "|cFF00FF00enabled|r" or "|cFFFFFF00disabled|r"
        print("CooldownTracker: glow " .. state .. " for " .. spellName .. ".")
        UpdateTracker(key)
        return enabled
    else
        print("|cFFFF0000CooldownTracker: not tracking '" .. spellName .. "'.|r")
        return nil
    end
end

function CooldownTracker_Reset(spellName)
    if not spellName then return end
    local key = KeyFor(spellName)
    if tracked[key] then
        shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE)
        print("|cFF00FF00CooldownTracker: reset " .. spellName .. ".|r")
    else
        print("|cFFFF0000CooldownTracker: not tracking '" .. spellName .. "'.|r")
    end
end

function CooldownTracker_ResetAll()
    for key in pairs(tracked) do shmIcons:ResetIcon(ADDON_NAME, key, DEFAULT_SIZE) end
    print("|cFF00FF00CooldownTracker: All positions reset.|r")
end

function CooldownTracker_ToggleLock()
    local locked = shmIcons:ToggleLock()
    local state = locked and "|cFF00FF00Locked.|r" or "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
    print("shmIcons: All icons " .. state)
    return locked
end

function CooldownTracker_List()
    local found = false
    for key, entry in pairs(tracked) do
        local db = GetSpecSpells(currentSpecID)[key]
        local glowState = db and db.glow_enabled and "glow on" or "glow off"
        print(string.format("|cFFFFFF00  %s|r  [%s]", entry.spellName, glowState))
        found = true
    end
    if not found then print("|cFFFFFF00CooldownTracker: no abilities tracked yet.|r") end
end

-- Allow external UI to register a callback to be notified when the tracked
-- abilities for the current spec change (add/remove).
function CooldownTracker_RegisterChangeListener(fn)
    if type(fn) ~= "function" then return end
    changeListeners[#changeListeners + 1] = fn
end

-- Return a simple array of tracked spell entries for the given specID.
function CooldownTracker_GetTrackedSpells(specID)
    specID = specID or GetCurrentSpecID()
    local out = {}
    local spells = GetSpecSpells(specID)
    for key, db in pairs(spells) do
        if db.enabled and db.spellName then
            table.insert(out, { key = key, spellName = db.spellName, spellID = db.spellID, db = db })
        end
    end
    return out
end

-- PoulsTools integration moved to CooldownTracker_PoulsTools.lua