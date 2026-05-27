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

-- Attempt to auto-detect a good display name and override icon for a new entry
-- by scanning the talent tree for a talent whose description contains
-- "your next <activated spell name>".  Only runs when neither a saved value
-- (priority 1) nor a default-override value (priority 2) is present.
function DynamicActivationTracker_AutoFillEntryFromTalents(specID, spellID, entry)
    -- Priority 1: saved display_name or override_icon already present.
    if entry.display_name or entry.override_icon then return end

    -- Priority 2: default override provides display_name or icon.
    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    if defaultOverride and (defaultOverride.display_name or defaultOverride.icon) then return end

    -- Need talent-tree APIs.
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
        and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo
        and C_Traits.GetDefinitionInfo) then return end

    local spellInfo = GetSpellInfoData(spellID)
    if not spellInfo or not spellInfo.name then return end
    local pattern = "your next " .. spellInfo.name:lower()

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end
    local configInfo = C_Traits.GetConfigInfo(configID)
    if not (configInfo and configInfo.treeIDs) then return end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes(treeID)
        if nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.entryIDs then
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if defInfo and defInfo.spellID and defInfo.spellID ~= 0 then
                                local desc
                                if C_Spell and C_Spell.GetSpellDescription then
                                    local ok, d = pcall(C_Spell.GetSpellDescription, defInfo.spellID)
                                    if ok then desc = d end
                                end
                                if not desc and _G.GetSpellDescription then
                                    local ok, d = pcall(_G.GetSpellDescription, defInfo.spellID)
                                    if ok then desc = d end
                                end
                                if desc and desc:lower():find(pattern, 1, true) then
                                    local ok, si = pcall(C_Spell.GetSpellInfo, defInfo.spellID)
                                    if ok and si and si.iconID and si.iconID ~= 134400 then
                                        entry.display_name = si.name
                                        entry.override_icon = si.iconID
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
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
            if entry.enabled == nil then
                entry.enabled = false
            end
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
        if entry.enabled == nil then
            entry.enabled = false
        end
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
        glow_enabled = false,
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