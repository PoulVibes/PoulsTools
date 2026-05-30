-- CombatCoach_Profiles.lua
-- Profile export/import system for CombatCoach.

CombatCoach          = CombatCoach or {}
CombatCoach.Profiles = CombatCoach.Profiles or {}
local CC       = CombatCoach
local Profiles = CombatCoach.Profiles

-- Profile schema version; bump if the format changes incompatibly.
Profiles.VERSION = 1

-- Known addon SavedVariable globals included in a profile.
Profiles.knownDBs = {
    { dbName = "ComboTrackerDB",      label = "CombatCoach_ComboTracker"      },
    { dbName = "CooldownTrackerDB",   label = "CombatCoach_CooldownTracker"   },
    { dbName = "ItemTrackerDB",       label = "CombatCoach_ItemTracker"       },
    { dbName = "SpellGlowTrackerDB",  label = "CombatCoach_SpellGlowTracker"  },
    { dbName = "SBA_SimpleDB",        label = "CombatCoach_SBA_Simple"        },
    { dbName = "TrinketTrackerDB",    label = "CombatCoach_TrinketTracker"    },
    { dbName = "VivifyProcTrackerDB", label = "CombatCoach_VivifyProcTracker" },
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
function Profiles:Apply(profileData)
    local applied = {}
    for _, entry in ipairs(self.knownDBs) do
        if type(profileData[entry.dbName]) == "table" then
            _G[entry.dbName] = CopyTable(profileData[entry.dbName])
            applied[#applied + 1] = entry.label
        end
    end
    return applied
end
