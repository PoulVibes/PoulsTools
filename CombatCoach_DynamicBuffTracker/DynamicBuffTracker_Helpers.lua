-- DynamicBuffTracker_Helpers.lua
-- DB accessors and key/flag/plugin-ID helper functions.

local DBT = DynamicBuffTracker

-- Returns the buffs sub-table for a spec, creating it if absent.
function DynamicBuffTracker_GetSpecBuffDB(specID)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    if not DynamicBuffTrackerDB.specs[specID] then
        DynamicBuffTrackerDB.specs[specID] = { buffs = {} }
    end
    DynamicBuffTrackerDB.specs[specID].buffs =
        DynamicBuffTrackerDB.specs[specID].buffs or {}
    return DynamicBuffTrackerDB.specs[specID].buffs
end

-- Returns the removed-spells deny-list for a spec.
function DynamicBuffTracker_GetSpecRemovedDB(specID)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    if not DynamicBuffTrackerDB.specs[specID] then
        DynamicBuffTrackerDB.specs[specID] = { buffs = {} }
    end
    DynamicBuffTrackerDB.specs[specID].removed =
        DynamicBuffTrackerDB.specs[specID].removed or {}
    return DynamicBuffTrackerDB.specs[specID].removed
end

-- shmIcons key for a given spell ID.
function DynamicBuffTracker_MakeKey(spellID)
    return "dbt_" .. tostring(spellID)
end

-- Global variable name that tracks whether a buff is currently active.
function DynamicBuffTracker_MakeActiveFlag(specID, spellID)
    return "DynBuff_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Active"
end

-- Plugin ID used in the SBAS condition registry and saved data.
function DynamicBuffTracker_MakePluginID(specID, spellID)
    return "dynbuff_" .. tostring(specID) .. "_" .. tostring(spellID)
end

function DynamicBuffTracker_GetCurrentSpecID()
    local si = GetSpecialization()
    if not si then return 0 end
    return select(1, GetSpecializationInfo(si)) or 0
end

function DynamicBuffTracker_GetSpecEctOverlay(specID)
    if not DynamicBuffTrackerDB or not DynamicBuffTrackerDB.specs then return false end
    local s = DynamicBuffTrackerDB.specs[specID]
    return s ~= nil and s.ectOverlayEnabled == true
end

function DynamicBuffTracker_SetSpecEctOverlay(specID, val)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    DynamicBuffTrackerDB.specs[specID] = DynamicBuffTrackerDB.specs[specID] or { buffs = {} }
    DynamicBuffTrackerDB.specs[specID].ectOverlayEnabled = val
end

function DynamicBuffTracker_GetSpecEctScale(specID)
    if not DynamicBuffTrackerDB or not DynamicBuffTrackerDB.specs then return 1.0 end
    local s = DynamicBuffTrackerDB.specs[specID]
    if not s or s.ectOverlayScale == nil then return 1.0 end
    return s.ectOverlayScale
end

function DynamicBuffTracker_SetSpecEctScale(specID, val)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    DynamicBuffTrackerDB.specs[specID] = DynamicBuffTrackerDB.specs[specID] or { buffs = {} }
    DynamicBuffTrackerDB.specs[specID].ectOverlayScale = val
end

function DynamicBuffTracker_GetSpecEctHideAnchor(specID)
    if not DynamicBuffTrackerDB or not DynamicBuffTrackerDB.specs then return false end
    local s = DynamicBuffTrackerDB.specs[specID]
    return s ~= nil and s.ectHideAnchor == true
end

function DynamicBuffTracker_SetSpecEctHideAnchor(specID, val)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    DynamicBuffTrackerDB.specs[specID] = DynamicBuffTrackerDB.specs[specID] or { buffs = {} }
    DynamicBuffTrackerDB.specs[specID].ectHideAnchor = val
end
