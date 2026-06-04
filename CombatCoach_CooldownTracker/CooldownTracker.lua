-- CooldownTracker.lua: tracks ability cooldowns by spell name per spec; delegates UI to shmIcons.
-- State initialization moved to CooldownTracker_State.lua (loads first).

local CT          = CooldownTracker
local FOLDER_NAME = CT.FOLDER_NAME
local ADDON_NAME  = CT.ADDON_NAME
local DEFAULT_SIZE = CT.DEFAULT_SIZE
local POLL_INTERVAL_SECONDS = CT.POLL_INTERVAL

-- spellKey → { spellName, spellID } for the currently active specialization.
local tracked = CT.tracked

-- Change listeners for UI integrations (called when trackers change)
local changeListeners = CT.changeListeners

-- Tracks which spell keys have already emitted the dormant warning this session.
local warnedDormant = CT.warnedDormant

local function NotifyChangeListeners()
    for _, cb in ipairs(changeListeners) do
        local ok, err = pcall(cb)
        if not ok then print("|cFFFF4444CooldownTracker: listener error: " .. tostring(err) .. "|r") end
    end
end

-- The spec ID we last loaded icons for (stored on module table)
local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

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
            x     = (n % 5) * (DEFAULT_SIZE + 4) - (2 * (DEFAULT_SIZE + 4)),
            y     = -math.floor(n / 5) * (DEFAULT_SIZE + 4),
            point = "CENTER",
            size  = DEFAULT_SIZE,
            enabled      = true,
            glow_enabled = false,
            sound_enabled = false,
            -- Glow trigger conditions (AND gate; none checked = always glow when available)
            glow_cond_reactive = false,
            glow_cond_usable   = false,
            glow_cond_charges  = false,
            glow_cond_offcd    = false,
            -- Audio alert conditions (AND gate; none checked = no sound)
            sound_cond_reactive = false,
            sound_cond_usable   = false,
            sound_cond_charges  = false,
            sound_cond_offcd    = false,
            ready_sound         = nil,
            -- Show/Hide conditions (master switch; none checked = always show)
            show_enabled = false,
            show_cond_reactive = false,
            show_cond_usable   = false,
            show_cond_charges  = false,
            show_cond_offcd    = false,
            show_cond_reactive_not = false,
            show_cond_usable_not   = false,
            show_cond_charges_not  = false,
            show_cond_offcd_not    = false,
            show_join_usable  = "and",  -- junction before Usable row
            show_join_charges = "and",  -- junction before Charges row
            show_join_offcd   = "and",  -- junction before OffCd row
            -- Hotkey display
            show_hotkey = false,
        }
    end
    return spells[key]
end

local function PlayReadySound(db)
    if not db or not db.ready_sound then return end
    local s = db.ready_sound
    if type(s) == "number" then
        if C_Sound and C_Sound.PlaySound then
            pcall(C_Sound.PlaySound, s)
        else
            pcall(PlaySound, s, "Master")
        end
    elseif type(s) == "string" then
        pcall(PlaySoundFile, s, "Master")
    end
end

-- Evaluates AND-gated conditions for glow/sound/show; returns nil when no boxes checked.
local function CondGate(db, prefix, condReactive, condUsable, condCharges, condOffCd)
    local anyChecked = db[prefix.."reactive"] or db[prefix.."usable"]
                    or db[prefix.."charges"]  or db[prefix.."offcd"]
    if not anyChecked then return nil end
    if db[prefix.."reactive"] and not condReactive then return false end
    if db[prefix.."charges"]  and not condCharges  then return false end
    if db[prefix.."offcd"]    and not condOffCd    then return false end
    if db[prefix.."usable"] and not condUsable then return false end
    return true
end

local function UpdateTracker(key, updateStacks, skipCooldownApi)
    local entry = tracked[key]
    if not entry then return end
    if entry.dormant or not entry.spellID then return end
    shmIcons:SetIcon(ADDON_NAME, key, entry.iconID or 134400)

    local cdInfo         = C_Spell.GetSpellCooldown(entry.spellID)
    local chargeInfo     = C_Spell.GetSpellCharges(entry.spellID)
    local isChargeSpell  = chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1
    local db             = GetSpecSpells(CT.currentSpecID)[key]

    if not skipCooldownApi then
        local durationObject = C_Spell.GetSpellCooldownDuration(entry.spellID)
        local chargeDuration = C_Spell.GetSpellChargeDuration(entry.spellID)

        if isChargeSpell then
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
            elseif chargeDuration and chargeInfo and chargeInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, key, chargeDuration)
            else
                shmIcons:SetCooldown(ADDON_NAME, key, nil)
            end
            if cdInfo and (not cdInfo.isActive or cdInfo.isOnGCD) then
                shmIcons:SetStacks(ADDON_NAME, key, chargeInfo.currentCharges)
            else
                shmIcons:SetStacks(ADDON_NAME, key, 0)
            end
        else
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, key, durationObject)
            else
                shmIcons:SetCooldown(ADDON_NAME, key, nil)
            end
            if updateStacks then shmIcons:SetStacks(ADDON_NAME, key, 0) end
        end
    end

    local condReactive = cdInfo and cdInfo.isEnabled == true
    local condUsable = C_Spell.IsSpellUsable(entry.spellID)
    local condCharges = false
    if chargeInfo and not chargeInfo.isActive then
        condCharges = true
    elseif cdInfo and (not cdInfo.isActive or cdInfo.isOnGCD) then
        condCharges = true
    end
    local condOffCd = false
    if chargeInfo then
        if not chargeInfo.isActive then condOffCd = true end
    elseif cdInfo and not cdInfo.isActive then
        condOffCd = true
    end

    -- ---- Glow ----
    local glowResult = db and CondGate(db, "glow_cond_", condReactive, condUsable, condCharges, condOffCd)
    if glowResult == nil then
        glowResult = isChargeSpell and condCharges or condOffCd
    end
    shmIcons:SetGlow(ADDON_NAME, key, glowResult)

    -- ---- Range + usable tint ----
    if UnitExists("target") then
        shmIcons:SetRange(ADDON_NAME, key, C_Spell.IsSpellInRange(entry.spellID, "target"))
    else
        shmIcons:SetRange(ADDON_NAME, key, nil)
    end
    shmIcons:SetUsable(ADDON_NAME, key, condUsable)

    -- ---- Visibility (Conditional Hide with AND/OR junctions) ----
    if db and db.show_enabled then
        local anyChecked = db.show_cond_reactive or db.show_cond_usable
                        or db.show_cond_charges  or db.show_cond_offcd
        if anyChecked then
            local result = nil  -- nil = no active conditions evaluated yet
            if db.show_cond_reactive then
                local v = condReactive
                if db.show_cond_reactive_not then v = not condReactive end
                result = v
            end
            if db.show_cond_usable then
                local uVal = false
                if condUsable then uVal = true end
                if db.show_cond_usable_not then uVal = not uVal end
                if result == nil then
                    result = uVal
                elseif (db.show_join_usable or "and") == "or" then
                    result = result or uVal
                else
                    result = result and uVal
                end
            end
            if db.show_cond_charges then
                local v = condCharges
                if db.show_cond_charges_not then v = not condCharges end
                if result == nil then
                    result = v
                elseif (db.show_join_charges or "and") == "or" then
                    result = result or v
                else
                    result = result and v
                end
            end
            if db.show_cond_offcd then
                local v = condOffCd
                if db.show_cond_offcd_not then v = not condOffCd end
                if result == nil then
                    result = v
                elseif (db.show_join_offcd or "and") == "or" then
                    result = result or v
                else
                    result = result and v
                end
            end
            if result ~= nil then
                shmIcons:SetVisible(ADDON_NAME, key, not result)
            end
        end
    end

    -- ---- Sound (fire on transition only) ----
    local soundGate = false
    if db and db.sound_enabled then
        local gate = CondGate(db, "sound_cond_", condReactive, condUsable, condCharges, condOffCd)
        soundGate = (gate ~= nil) and gate or false
    end
    if isChargeSpell then
        local chargeActive = chargeInfo and chargeInfo.isActive
        if tracked[key].lastChargeActive == nil then
            tracked[key].lastChargeActive = chargeActive
        else
            if tracked[key].lastChargeActive and (chargeActive == false) and soundGate then
                if db and db.ready_sound then PlayReadySound(db) end
            end
            tracked[key].lastChargeActive = chargeActive
        end
    else
        if tracked[key].lastAvailable == nil then
            tracked[key].lastAvailable = condOffCd
        else
            if not tracked[key].lastAvailable and condOffCd and soundGate then
                if db and db.ready_sound then PlayReadySound(db) end
            end
            tracked[key].lastAvailable = condOffCd
        end
    end

    -- ---- Hotkey ----
    if db then
        shmIcons:SetDisplayHotkey(ADDON_NAME, key, db.show_hotkey == true)
    end
end

local function UpdateAllTrackers(updateStacks)
    for key in pairs(tracked) do UpdateTracker(key, updateStacks) end
end

local ticker = CreateFrame("Frame")

local function EnsureTickerState()
    if next(tracked) == nil then
        ticker:Hide()
    else
        ticker:Show()
    end
end

local function AddTracker(spellName, specID)
    specID = specID or CT.currentSpecID
    local spellID = C_Spell.GetSpellIDForSpellIdentifier(spellName)

    local key = KeyFor(spellName)
    local db  = GetSpellDB(specID, key)

    db.enabled   = true
    db.spellName = spellName
    if spellID then
        db.spellID = spellID
    end
    -- db.spellID may remain nil when the spell is a talent not currently trained.

    shmIcons:Register(ADDON_NAME, key, db, {
        onResize = function(sq)
            GetSpecSpells(specID)[key].size = sq
        end,
    })
    shmIcons:SetDisplayHotkey(ADDON_NAME, key, db.show_hotkey == true)

    if spellID then
        local si = C_Spell.GetSpellInfo(spellID)
        tracked[key] = { spellName = spellName, spellID = spellID, iconID = si and si.iconID or 134400 }
        UpdateTracker(key, true)
    else
        -- Spell not found — talent likely unlearned. Create a dormant tracker;
        -- the frame exists but is disabled until the talent is learned.
        tracked[key] = { spellName = spellName, spellID = nil, dormant = true }
        shmIcons:SetIcon(ADDON_NAME, key, 134400)  -- question-mark placeholder
        shmIcons:SetEnabled(ADDON_NAME, key, false)
        shmIcons:SetVisible(ADDON_NAME, key, false)
        -- shmIcons:SetEnabled writes db.enabled=false; restore it so LoadSpec
        -- still picks this entry up on the next login/spec-change and can
        -- attempt to remap it once the talent is (re-)learned.
        db.enabled = true
        if not warnedDormant[key] then
            warnedDormant[key] = true
            print("|cFFFFFF00CooldownTracker: '" .. spellName .. "' is not currently talented. Tracker inactive until talent is learned.|r")
        end
    end
    EnsureTickerState()
    -- notify any UI listeners so they can refresh lists
    NotifyChangeListeners()
end

-- Reconcile all tracked entries against the current talent build.
-- • Dormant entries whose spell is now known  → activate.
-- • Active entries whose spell is no longer known → go dormant (hide/disable).
-- Called on TRAIT_CONFIG_UPDATED and PLAYER_SPECIALIZATION_CHANGED.
local function TryRemapDormant()
    for key, entry in pairs(tracked) do
        local spellID = C_Spell.GetSpellIDForSpellIdentifier(entry.spellName)

        if entry.dormant then
            -- Was dormant — check if the talent has been (re-)learned.
            if spellID then
                entry.spellID = spellID
                entry.dormant = false
                local si = C_Spell.GetSpellInfo(spellID)
                entry.iconID = si and si.iconID or 134400
                local db = GetSpecSpells(CT.currentSpecID)[key]
                if db then db.spellID = spellID end
                shmIcons:SetEnabled(ADDON_NAME, key, true)
                shmIcons:SetVisible(ADDON_NAME, key, true)
                print("|cFF00FF00CooldownTracker: '" .. entry.spellName .. "' talent found — tracker activated.|r")
                UpdateTracker(key, true)
            end
        else
            -- Was active — check if the talent has been removed.
            if not spellID then
                entry.spellID = nil
                entry.dormant = true
                local db = GetSpecSpells(CT.currentSpecID)[key]
                if db then db.enabled = true end  -- keep enabled so LoadSpec reloads it
                shmIcons:SetEnabled(ADDON_NAME, key, false)
                shmIcons:SetVisible(ADDON_NAME, key, false)
                print("|cFFFFFF00CooldownTracker: '" .. entry.spellName .. "' talent removed — tracker suspended.|r")
            end
        end
    end
end

ticker.elapsed = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    ticker.elapsed = ticker.elapsed + elapsed
    if ticker.elapsed < POLL_INTERVAL_SECONDS then
        return
    end
    ticker.elapsed = 0
    -- Avoid constant polling allocations while idle out of combat with no target.
    if not InCombatLockdown() and not UnitExists("target") then
        return
    end
    for key in pairs(tracked) do
        UpdateTracker(key, false, true)
    end
end)
ticker:Hide()

local function RemoveTracker(key)
    shmIcons:Unregister(ADDON_NAME, key)
    tracked[key] = nil
    warnedDormant[key] = nil
    local spells = GetSpecSpells(CT.currentSpecID)
    if spells[key] then spells[key].enabled = false end
    EnsureTickerState()
    NotifyChangeListeners()
end

-- Unregister all current icons and clear tracked table.
local function UnloadSpec()
    for key in pairs(tracked) do
        shmIcons:Unregister(ADDON_NAME, key)
        tracked[key] = nil
    end
    wipe(warnedDormant)
    EnsureTickerState()
    NotifyChangeListeners()
end

-- Load all enabled spells for the given specID.
local function LoadSpec(specID)
    UnloadSpec()
    CT.currentSpecID = specID
    local spells = GetSpecSpells(specID)
    for key, db in pairs(spells) do
        if db.enabled and db.spellName then
            AddTracker(db.spellName, specID)
        end
    end
    shmIcons:RestoreSnapGroups()
    UpdateAllTrackers()
    EnsureTickerState()
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
            local db        = GetSpecSpells(CT.currentSpecID)[key]
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

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == FOLDER_NAME then
        CooldownTrackerDB = CooldownTrackerDB or { specs = {} }
        CooldownTrackerDB.specs = CooldownTrackerDB.specs or {}

    elseif event == "PLAYER_ENTERING_WORLD" then
        local specID = GetCurrentSpecID()
        if specID ~= CT.currentSpecID then
            LoadSpec(specID)
        else
            UpdateAllTrackers()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpec(GetCurrentSpecID())

    elseif event == "TRAIT_CONFIG_UPDATED" then
        TryRemapDormant()

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        for key, entry in pairs(tracked) do
            if not entry.dormant and entry.spellID then
                UpdateTracker(key)
            end
        end
    elseif event == "SPELL_UPDATE_USABLE" then
        UpdateAllTrackers()
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateAllTrackers()
    elseif event == "SPELL_UPDATE_CHARGES" then
        UpdateAllTrackers(true)
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")


-- Public API wrappers for CombatCoach UI and other integrations
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
        local db = GetSpecSpells(CT.currentSpecID)[key]
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
    for _, existing in ipairs(changeListeners) do
        if existing == fn then
            return
        end
    end
    changeListeners[#changeListeners + 1] = fn
end

function CooldownTracker_UnregisterChangeListener(fn)
    if type(fn) ~= "function" then return end
    for i = #changeListeners, 1, -1 do
        if changeListeners[i] == fn then
            table.remove(changeListeners, i)
        end
    end
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

-- CombatCoach integration moved to CooldownTracker_CombatCoach.lua