-- SBA_Simple.lua
-- Displays the next suggested cast from C_AssistedCombat using shmIcons.

local FOLDER_NAME    = "CombatCoach_SBA_Simple"
local ADDON_NAME     = "Rotation Assistant"
local ICON_KEY       = "Suggested_Spell"
local MAX_EXTRA_TABS = 4   -- tabs 2-5 (tab 1 is the main ICON_KEY)

-- spellID -> isOnGCD; populated for every spell that has been shown in the icon.
-- Updated on SPELL_UPDATE_COOLDOWN so SetStacks can ignore GCD-only lockouts.
local spellGCDState = {}

-- The spellID currently shown in the icon; used by SPELL_UPDATE_CHARGES.
local currentDisplayedSpellID = nil

-- shmIcon objects by icon key; populated on Register, cleared on Unregister.
-- Used by the per-frame nameplate repositioner.
local registeredIconObjects = {}

-- Suffix for nameplate-clone icon keys used in "Both" display mode.
local NP_KEY_SUFFIX = "_np"
-- In-memory DBs for NP-clone icons (not persisted in SavedVariables).
local npIconDBs = {}

-- Extra-tab tracking (tabs 2-5)
local activeExtraTabCount  = 0    -- how many extra icons are currently registered
local extraDisplayedSpell  = {}   -- [tabIdx] -> currently displayed spellID
local extraOverrideChunks  = {}   -- [tabIdx] -> compiled override function

SBA_SimpleDB = SBA_SimpleDB or {}

-- ── Extra-icon DB (one entry per extra tab, keyed by tab index) ─────────
local GetExtraIconDB = SBA_Simple_GetExtraIconDB
local GetDB          = SBA_Simple_GetDB
local GetNPSettings  = SBA_Simple_GetNPSettings
local GetNPIconDB    = SBA_Simple_GetNPIconDB
local GetCurrentSpecID = SBA_Simple_GetCurrentSpecID
local GetSpecDB      = SBA_Simple_GetSpecDB

-- ── Override logic ────────────────────────────────────────────────────────
-- Compiles and runs saved override code. The code is expected to return a
-- spellID (number) or nil. If it returns a valid number that overrides the
-- C_AssistedCombat suggestion. Errors are swallowed silently per-frame to
-- avoid chat spam; compile errors are caught once at save time instead.

local overrideChunk = nil  -- compiled function, rebuilt when code is saved (tab 1)
local lastOverrideRuntimeError = nil
local lastOverrideRuntimeErrorAt = 0
local lastOverridePriority = nil  -- priority index returned by the last Override() call; nil when not available

local function ReportOverrideRuntimeError(err)
    local db = GetDB()
    if not db.overrideDebug then return end
    local msg = tostring(err or "unknown error")
    local now = GetTime and GetTime() or 0
    if msg == lastOverrideRuntimeError and (now - lastOverrideRuntimeErrorAt) < 2 then
        return
    end
    lastOverrideRuntimeError = msg
    lastOverrideRuntimeErrorAt = now
    print("|cffff4444SBA_Simple override runtime error:|r " .. msg)
end

local function CompileOverride(code)
    if not code or code:match("^%s*$") then
        overrideChunk = nil
        return true, nil
    end
    local chunk, err = loadstring(code)
    if not chunk then
        ReportOverrideRuntimeError(err)
        return false, err
    end
    overrideChunk = chunk
    return true, nil
end

local function Override()
    if not overrideChunk then return nil, nil end
    local ok, result, priority = pcall(overrideChunk)
    if not ok then
        ReportOverrideRuntimeError(result)
        return nil, nil
    end
    if result == nil then return nil, nil end
    if type(result) ~= "number" then
        ReportOverrideRuntimeError("override returned non-number: " .. type(result))
        return nil, nil
    end
    local pri = (type(priority) == "number") and priority or nil
    return result, pri
end

-- Returns the priority index (1-based rule number) from the most recent Override() call,
-- or nil when the override did not return one (e.g. hand-written raw code).
function SBA_Simple_GetLastOverridePriority()
    return lastOverridePriority
end

-- ── Extra-tab override compile/run ──────────────────────────────────────
local function CompileExtraOverride(tabIdx, code)
    if not code or code:match("^%s*$") then
        extraOverrideChunks[tabIdx] = nil
        return
    end
    local chunk = loadstring(code)
    extraOverrideChunks[tabIdx] = chunk  -- nil on compile failure
end

local function RunExtraOverride(tabIdx)
    local chunk = extraOverrideChunks[tabIdx]
    if not chunk then return nil end
    local ok, result = pcall(chunk)
    if not ok or type(result) ~= "number" then return nil end
    return result
end

-- Public API: allows the GUI builder to push compiled override code for the
-- current spec without needing direct access to the local CompileOverride closure.
function SBA_Simple_SetOverrideCode(code)
    local specID = GetCurrentSpecID()
    local specDB = GetSpecDB(specID)
    specDB.overrideCode = code or ""
    GetDB().overrideCode = code or ""
    CompileOverride(code or "")
end

function SBA_Simple_CompileMainOverride(code)
    return CompileOverride(code or "")
end

function SBA_Simple_GetLastOverrideRuntimeError()
    return lastOverrideRuntimeError
end

function SBA_Simple_GetRegistrationContext()
    return {
        addonName = ADDON_NAME,
        iconKey = ICON_KEY,
        npKeySuffix = NP_KEY_SUFFIX,
        registeredIconObjects = registeredIconObjects,
        extraOverrideChunks = extraOverrideChunks,
        extraDisplayedSpell = extraDisplayedSpell,
        getDB = GetDB,
        getExtraIconDB = GetExtraIconDB,
        getNPIconDB = GetNPIconDB,
        getCurrentSpecID = GetCurrentSpecID,
        getActiveExtraTabCount = function() return activeExtraTabCount end,
        setActiveExtraTabCount = function(value) activeExtraTabCount = value end,
        compileExtraOverride = CompileExtraOverride,
    }
end

function SBA_Simple_GetIconAPIContext()
    return {
        addonName = ADDON_NAME,
        iconKey = ICON_KEY,
        npKeySuffix = NP_KEY_SUFFIX,
        spellGCDState = spellGCDState,
        registeredIconObjects = registeredIconObjects,
        getDB = GetDB,
        getExtraIconDB = GetExtraIconDB,
        getCurrentSpecID = GetCurrentSpecID,
        getActiveExtraTabCount = function() return activeExtraTabCount end,
    }
end

-- Public: called from OverrideGUI when a tab is renamed so the CombatCoach
-- menu label updates immediately without needing a re-register.
function SBA_Simple_SetTabName(tabIdx, name)
    if tabIdx == 1 then
        local db = GetDB()
        db.spellName = name or "Rotation"
        return
    end
    local db = GetExtraIconDB(tabIdx)
    db.spellName = name or ("Tab " .. tabIdx)
end

-- Public: called from OverrideGUI when the user adds or removes a tab
function SBA_Simple_UpdateTabCount(specID, newCount)
    SBA_SimpleDB.tabCount          = SBA_SimpleDB.tabCount or {}
    SBA_SimpleDB.tabCount[specID]  = math.max(1, newCount)
    SBA_Simple_UpdateExtraIconsForSpec(specID)
end

-- Public: store and live-apply override codes for all tabs of a spec.
-- codes[1] = tab-1 code, codes[2] = tab-2 code, etc.
function SBA_Simple_SetAllTabOverrideCodes(specID, codes)
    SBA_SimpleDB.specs         = SBA_SimpleDB.specs or {}
    SBA_SimpleDB.specs[specID] = SBA_SimpleDB.specs[specID] or {}
    local specEntry = SBA_SimpleDB.specs[specID]
    for i, code in ipairs(codes or {}) do
        if i == 1 then
            specEntry.overrideCode   = code
            specEntry.overrideSource = "gui"
        else
            specEntry["overrideCode_" .. i] = code
        end
    end
    SBA_SimpleDB.overrideCode = specEntry.overrideCode or ""
    -- Apply live only when editing the current spec
    if specID == GetCurrentSpecID() then
        CompileOverride(specEntry.overrideCode or "")
        for i = 2, activeExtraTabCount + 1 do
            CompileExtraOverride(i, specEntry["overrideCode_" .. i] or "")
        end
    end
end

function SBA_Simple_GetRuntimeContext()
    return {
        addonName = ADDON_NAME,
        iconKey = ICON_KEY,
        npKeySuffix = NP_KEY_SUFFIX,
        extraDisplayedSpell = extraDisplayedSpell,
        registeredIconObjects = registeredIconObjects,
        getMainDB = GetDB,
        runOverride = Override,
        setLastOverridePriority = function(value) lastOverridePriority = value end,
        updateIcon = SBA_Simple_UpdateTrackedIcon,
        getCurrentDisplayedSpellID = function() return currentDisplayedSpellID end,
        setCurrentDisplayedSpellID = function(value) currentDisplayedSpellID = value end,
        getActiveExtraTabCount = function() return activeExtraTabCount end,
        getExtraIconDB = GetExtraIconDB,
        runExtraOverride = RunExtraOverride,
        getNPSettings = GetNPSettings,
    }
end

function SBA_Simple_GetEventContext()
    return {
        addonName = ADDON_NAME,
        iconKey = ICON_KEY,
        spellGCDState = spellGCDState,
        registerIcon = SBA_Simple_RegisterMainIcon,
        updateExtraIconsForSpec = SBA_Simple_UpdateExtraIconsForSpec,
        getCurrentSpecID = GetCurrentSpecID,
        getSpecDB = GetSpecDB,
        compileOverride = CompileOverride,
    }
end