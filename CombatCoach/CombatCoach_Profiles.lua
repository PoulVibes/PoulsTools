-- CombatCoach_Profiles.lua
-- Profile export/import system for CombatCoach.

CombatCoach          = CombatCoach or {}
CombatCoach.Profiles = CombatCoach.Profiles or {}
local CC       = CombatCoach
local Profiles = CombatCoach.Profiles

-- Profile schema version; bump if the format changes incompatibly.
Profiles.VERSION = 1

-- Known addon SavedVariable globals included in a profile.
-- specKeys: top-level fields in the DB keyed by [specID]; omit for globals-only DBs.
Profiles.knownDBs = {
    { dbName = "ComboTrackerDB",      label = "CombatCoach_ComboTracker"                                                         },
    { dbName = "CooldownTrackerDB",   label = "CombatCoach_CooldownTracker",  specKeys = { "specs" }                             },
    { dbName = "ItemTrackerDB",       label = "CombatCoach_ItemTracker",       specKeys = { "specs" }                            },
    { dbName = "SpellGlowTrackerDB",  label = "CombatCoach_SpellGlowTracker"                                                     },
    { dbName = "SBA_SimpleDB",        label = "CombatCoach_SBA_Simple",        specKeys = { "gui", "guiTabs", "tabNames", "tabCount", "specs" } },
    { dbName = "TrinketTrackerDB",    label = "CombatCoach_TrinketTracker",    specKeys = { "specs" }                            },
    { dbName = "VivifyProcTrackerDB", label = "CombatCoach_VivifyProcTracker"                                                    },
}

-- Define the reload-after-import static popup once at load time
StaticPopupDialogs["CombatCoach_PROFILE_RELOAD"] = {
    text         = "Profile imported!\n\nUpdated: %s\n\nA UI reload is required to apply the changes. Reload now?",
    button1      = "Reload UI",
    button2      = "Later",
    OnAccept     = function() ReloadUI() end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- Converts a Lua value to a valid Lua-syntax string (booleans, numbers, strings, tables).
local function serializeValue(val, depth)
    depth = depth or 0
    local vt = type(val)

    if vt == "boolean" then
        return tostring(val)
    elseif vt == "number" then
        if val ~= val then return "0" end       -- NaN guard
        return string.format("%.10g", val)
    elseif vt == "string" then
        return string.format("%q", val)
    elseif vt == "table" then
        if depth > 32 then return "{}" end
        local ind  = string.rep("  ", depth + 1)
        local clos = string.rep("  ", depth)
        local parts = {}
        for k, v in pairs(val) do
            local kStr
            if type(k) == "number" then
                kStr = "[" .. k .. "]"
            elseif type(k) == "string" then
                if k:match("^[%a_][%w_]*$") then
                    kStr = k
                else
                    kStr = "[" .. string.format("%q", k) .. "]"
                end
            end
            if kStr then
                parts[#parts + 1] = ind .. kStr .. " = " .. serializeValue(v, depth + 1)
            end
        end
        if #parts == 0 then return "{}" end
        table.sort(parts)
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. clos .. "}"
    end
    return "nil"
end

-- Returns the numeric spec ID for the active specialization, or 0.
local function GetCurrentSpecID()
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

-- Snapshots the current spec's data from all spec-aware DBs.
-- Returns (serializedString, labelList, specID, specName) or (nil, errMsg).
function Profiles:SerializeSpec()
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then
        return nil, "No active specialization found."
    end
    local specID, specName = GetSpecializationInfo(specIndex)
    if not specID or specID == 0 then
        return nil, "Could not determine current specialization."
    end
    local profile = {
        _addon   = "CombatCoach",
        _version = self.VERSION,
        _date    = date("%Y-%m-%d"),
        _specID  = specID,
    }
    local included = {}
    for _, entry in ipairs(self.knownDBs) do
        if entry.specKeys then
            local db = _G[entry.dbName]
            if db ~= nil then
                local specData = {}
                local hasData  = false
                for _, key in ipairs(entry.specKeys) do
                    if db[key] ~= nil and db[key][specID] ~= nil then
                        local v = db[key][specID]
                        specData[key] = type(v) == "table" and CopyTable(v) or v
                        hasData = true
                    end
                end
                if hasData then
                    profile[entry.dbName]        = specData
                    included[#included + 1] = entry.label
                end
            end
        end
    end
    if #included == 0 then
        return nil, "No spec data found for the current specialization."
    end
    return serializeValue(profile), included, specID, specName
end

-- Snapshots all currently-loaded addon DBs; returns (serializedString, labelList) or (nil, error).
function Profiles:Serialize()
    local profile = {
        _addon   = "CombatCoach",
        _version = self.VERSION,
        _date    = date("%Y-%m-%d"),
    }
    local included = {}
    for _, entry in ipairs(self.knownDBs) do
        local db = _G[entry.dbName]
        if db ~= nil then
            profile[entry.dbName] = CopyTable(db)
            included[#included + 1] = entry.label
        end
    end
    if #included == 0 then
        return nil, "No addon databases are currently loaded."
    end
    return serializeValue(profile), included
end

-- Parses a profile string back into a Lua table; returns (table, nil) or (nil, errMsg).
function Profiles:Deserialize(str)
    if type(str) ~= "string" or #str == 0 then
        return nil, "Profile string is empty."
    end
    local forbidden = {
        "function%s*%(",
        "loadstring%s*%(",
        "dofile%s*%(",
        "require%s*%(",
        "io%.%a",
        "os%.%a",
        "debug%.%a",
        "rawset%s*%(",
        "rawget%s*%(",
        "setfenv%s*%(",
    }
    for _, pat in ipairs(forbidden) do
        if str:find(pat) then
            return nil, "Profile contains disallowed content."
        end
    end

    local fn, parseErr = loadstring("return " .. str)
    if not fn then
        return nil, "Parse error: " .. tostring(parseErr)
    end
    local ok, result = pcall(fn)
    if not ok then
        return nil, "Load error: " .. tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "Profile is not a valid table."
    end
    if result._addon ~= "CombatCoach" then
        return nil, "String does not appear to be a CombatCoach profile."
    end
    return result
end

-- Copies each known DB from the profile into the matching global; returns label list.
-- Routes spec-scoped profiles (those with _specID) to _ApplySpec.
function Profiles:Apply(profileData)
    if profileData._specID then
        return self:_ApplySpec(profileData)
    end
    local applied = {}
    for _, entry in ipairs(self.knownDBs) do
        if type(profileData[entry.dbName]) == "table" then
            _G[entry.dbName] = CopyTable(profileData[entry.dbName])
            applied[#applied + 1] = entry.label
        end
    end
    return applied
end

-- Writes spec-scoped profile data back into the matching per-spec DB slots.
function Profiles:_ApplySpec(profileData)
    local specID  = profileData._specID
    local applied = {}
    for _, entry in ipairs(self.knownDBs) do
        if entry.specKeys and type(profileData[entry.dbName]) == "table" then
            local db  = _G[entry.dbName]
            if not db then
                _G[entry.dbName] = {}
                db = _G[entry.dbName]
            end
            local src       = profileData[entry.dbName]
            local didApply  = false
            for _, key in ipairs(entry.specKeys) do
                if src[key] ~= nil then
                    db[key] = db[key] or {}
                    db[key][specID] = type(src[key]) == "table"
                        and CopyTable(src[key])
                        or  src[key]
                    didApply = true
                end
            end
            if didApply then
                applied[#applied + 1] = entry.label
            end
        end
    end
    return applied
end
