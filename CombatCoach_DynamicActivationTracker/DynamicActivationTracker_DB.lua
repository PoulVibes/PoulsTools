DynamicActivationTrackerDB = DynamicActivationTrackerDB or {}

local DAT = DynamicActivationTracker

local function GetSpellInfoData(spellID)
    if not C_Spell or not C_Spell.GetSpellInfo then return nil end
    local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
    if ok then return spellInfo end
    return nil
end

function DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    if not DynamicActivationTracker_Defaults then return nil end
    local specDefaults = DynamicActivationTracker_Defaults[specID]
    if not specDefaults then return nil end
    return specDefaults[spellID]
end

function DynamicActivationTracker_GetDisplayName(specID, spellID, entry)
    local function NonEmpty(v)
        return type(v) == "string" and v:match("%S") and v or nil
    end

    local name = entry and NonEmpty(entry.display_name)
    if name then return name end

    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    name = defaultOverride and NonEmpty(defaultOverride.display_name)
    if name then return name end

    name = entry and (NonEmpty(entry.label) or NonEmpty(entry.spellName))
    if name then return name end

    local spellInfo = GetSpellInfoData(spellID)
    return (spellInfo and spellInfo.name) or ("Spell " .. tostring(spellID))
end

function DynamicActivationTracker_MakeActiveFlag(specID, spellID)
    return "DynAct_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Active"
end

function DynamicActivationTracker_MakePluginID(specID, spellID)
    return "dynact_" .. tostring(specID) .. "_" .. tostring(spellID)
end

function DynamicActivationTracker_GetCurrentSpecID()
    local idx = GetSpecialization()
    if not idx then return 0 end
    return select(1, GetSpecializationInfo(idx)) or 0
end

function DynamicActivationTracker_EnsureDatabase()
    DynamicActivationTrackerDB = DynamicActivationTrackerDB or {}
    DynamicActivationTrackerDB.specs = DynamicActivationTrackerDB.specs or {}
end

local function IsLegacyEntry(entry)
    return type(entry) == "table" and entry.spellID ~= nil
end

function DynamicActivationTracker_GetSpecDB(specID)
    if not specID or specID == 0 then return nil end
    DynamicActivationTracker_EnsureDatabase()
    local specDB = DynamicActivationTrackerDB.specs[specID]
    if not specDB then
        specDB = { icons = {}, removed = {} }
        DynamicActivationTrackerDB.specs[specID] = specDB
    end
    specDB.icons = specDB.icons or {}
    specDB.removed = specDB.removed or {}
    return specDB
end

function DynamicActivationTracker_GetSpecIconDB(specID)
    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    return specDB and specDB.icons or nil
end

function DynamicActivationTracker_GetSpecRemovedDB(specID)
    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    return specDB and specDB.removed or nil
end

function DynamicActivationTracker_IsIgnored(specID, spellID)
    local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
    if not removedDB then return false end
    return removedDB[tostring(spellID)] ~= nil
end

function DynamicActivationTracker_GetIgnoredEntry(specID, spellID)
    local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
    if not removedDB then return nil end
    return removedDB[tostring(spellID)]
end

function DynamicActivationTracker_EnsureIgnoredEntry(specID, spellID, sourceEntry)
    local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
    if not removedDB then return nil end

    local spellIDStr = tostring(spellID)
    local entry = removedDB[spellIDStr]
    if type(entry) ~= "table" then
        entry = {}
        removedDB[spellIDStr] = entry
    end

    local spellInfo = GetSpellInfoData(spellID)
    local resolvedName = DynamicActivationTracker_GetDisplayName(specID, spellID, sourceEntry)
    entry.spellID = spellID
    entry.display_name = entry.display_name
        or (sourceEntry and sourceEntry.display_name)
    entry.spellName = entry.spellName
        or (sourceEntry and (sourceEntry.spellName or sourceEntry.label))
        or (spellInfo and spellInfo.name)
        or ("Spell " .. spellIDStr)
    entry.label = entry.label
        or resolvedName
        or entry.spellName
    entry.iconID = entry.iconID
        or (sourceEntry and (sourceEntry.override_icon or sourceEntry.iconID))
        or (spellInfo and spellInfo.iconID)
    return entry
end

function DynamicActivationTracker_UnignoreSpell(specID, spellID)
    local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
    if not removedDB then return end
    removedDB[tostring(spellID)] = nil
end

function DynamicActivationTracker_MigrateLegacyDB(specID)
    DynamicActivationTracker_EnsureDatabase()
    if next(DynamicActivationTrackerDB.specs) then return end
    local legacyFound = false
    for _, entry in pairs(DynamicActivationTrackerDB) do
        if IsLegacyEntry(entry) then
            legacyFound = true
            break
        end
    end
    if not legacyFound or not specID or specID == 0 then return end

    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    for key, entry in pairs(DynamicActivationTrackerDB) do
        if IsLegacyEntry(entry) then
            specDB.icons[tostring(entry.spellID)] = entry
            DynamicActivationTrackerDB[key] = nil
        end
    end
end

function DynamicActivationTracker_GetOrCreateEntry(specID, spellID)
    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    if not specDB then return nil end
    if DynamicActivationTracker_IsIgnored(specID, spellID) then return nil end

    local spellIDStr = tostring(spellID)
    local entry = specDB.icons[spellIDStr]
    if entry then
        entry.spellID = entry.spellID or spellID
        return entry
    end

    local spellInfo = GetSpellInfoData(spellID)
    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    local count = 0
    for _ in pairs(specDB.icons) do count = count + 1 end
    local size = DAT.DEFAULT_SIZE
    local col = count % 5
    local row = math.floor(count / 5)
    entry = {
        spellID = spellID,
        spellName = spellInfo and spellInfo.name or ("Spell " .. spellIDStr),
        iconID = spellInfo and spellInfo.iconID or nil,
        label = spellInfo and spellInfo.name or ("Spell " .. spellIDStr),
        display_name = defaultOverride and defaultOverride.display_name or nil,
        override_icon = defaultOverride and defaultOverride.icon or nil,
        condition_timer = defaultOverride and defaultOverride.timer or nil,
        x = (col - 2) * (size + 4),
        y = row > 0 and (-row * (size + 4)) or 0,
        point = "CENTER",
        size = size,
        enabled = false,
        glow_enabled = true,
    }
    specDB.icons[spellIDStr] = entry
    return entry
end

function DynamicActivationTracker_ClearSpecDB(specID)
    DynamicActivationTracker_EnsureDatabase()
    DynamicActivationTrackerDB.specs[specID] = nil
end

function DynamicActivationTracker_RegisterSBASEntry(specID, spellID)
    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    if not specDB then return end
    local entry = specDB.icons[tostring(spellID)]
    if not entry then return end

    _G.SBAS_DynActivationRegistry = _G.SBAS_DynActivationRegistry or {}
    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    local timerValue = entry.condition_timer
    if timerValue == nil and defaultOverride then
        timerValue = defaultOverride.timer
    end

    local timerVar = nil
    if tonumber(timerValue or 0) and tonumber(timerValue or 0) > 0 then
        timerVar = "DynAct_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
        _G[timerVar] = _G[timerVar] or 0
    end

    _G.SBAS_DynActivationRegistry[DynamicActivationTracker_MakePluginID(specID, spellID)] = {
        label = DynamicActivationTracker_GetDisplayName(specID, spellID, entry),
        activeFlag = DynamicActivationTracker_MakeActiveFlag(specID, spellID),
        specID = specID,
        timerVar = timerVar,
    }
end

function DynamicActivationTracker_ClearSBASEntriesForSpec(specID)
    if not _G.SBAS_DynActivationRegistry then return end
    for pid, entry in pairs(_G.SBAS_DynActivationRegistry) do
        if entry.specID == specID then
            if entry.timerVar then
                _G[entry.timerVar] = nil
            end
            _G.SBAS_DynActivationRegistry[pid] = nil
        end
    end
end