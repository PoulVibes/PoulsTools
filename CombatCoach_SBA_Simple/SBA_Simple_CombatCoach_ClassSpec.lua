-- SBA_Simple_CombatCoach_ClassSpec.lua
-- Class and spec data helpers for SBA_Simple CombatCoach UI.

local staticClassSpecs = {
    ["Warrior"] = { {name = "Arms", id = 71}, {name = "Fury", id = 72}, {name = "Protection", id = 73} },
    ["Paladin"] = { {name = "Holy", id = 65}, {name = "Protection", id = 66}, {name = "Retribution", id = 70} },
    ["Hunter"] = { {name = "Beast Mastery", id = 253}, {name = "Marksmanship", id = 254}, {name = "Survival", id = 255} },
    ["Rogue"] = { {name = "Assassination", id = 259}, {name = "Outlaw", id = 260}, {name = "Subtlety", id = 261} },
    ["Priest"] = { {name = "Discipline", id = 256}, {name = "Holy", id = 257}, {name = "Shadow", id = 258} },
    ["Shaman"] = { {name = "Elemental", id = 262}, {name = "Enhancement", id = 263}, {name = "Restoration", id = 264} },
    ["Mage"] = { {name = "Arcane", id = 62}, {name = "Fire", id = 63}, {name = "Frost", id = 64} },
    ["Warlock"] = { {name = "Affliction", id = 265}, {name = "Demonology", id = 266}, {name = "Destruction", id = 267} },
    ["Monk"] = { {name = "Brewmaster", id = 268}, {name = "Mistweaver", id = 270}, {name = "Windwalker", id = 269} },
    ["Druid"] = { {name = "Balance", id = 102}, {name = "Feral", id = 103}, {name = "Guardian", id = 104}, {name = "Restoration", id = 105} },
    ["Demon Hunter"] = { {name = "Havoc", id = 577}, {name = "Vengeance", id = 581}, {name = "Devourer", id = 1480} },
    ["Death Knight"] = { {name = "Blood", id = 250}, {name = "Frost", id = 251}, {name = "Unholy", id = 252} },
    ["Evoker"] = { {name = "Devastation", id = 1467}, {name = "Preservation", id = 1468}, {name = "Augmentation", id = 1473} },
}

function SBAS_GetClassSpecData()
    local orderedClasses = {}
    local classSpecData  = {}

    if type(GetNumSpecializationsForClassID) ~= "function"
    or type(GetSpecializationInfoForClassID) ~= "function"
    or type(GetClassInfo) ~= "function" then
        return orderedClasses, classSpecData
    end

    for classID = 1, 13 do
        local cname = select(1, GetClassInfo(classID))
        if cname then
            orderedClasses[#orderedClasses + 1] = { name = cname, classID = classID }
            classSpecData[cname] = { specs = {} }

            local num = GetNumSpecializationsForClassID(classID) or 0
            local apiSpecByID = {}
            local apiSpecNameByID = {}
            local apiSpecByNameLow = {}
            for si = 1, num do
                local specID, specName = GetSpecializationInfoForClassID(classID, si)
                if specID and specName then
                    apiSpecByID[specID] = true
                    apiSpecNameByID[specID] = specName
                    apiSpecByNameLow[specName:lower()] = specID
                end
            end

            local expected = staticClassSpecs[cname]
            if expected and type(expected) == "table" then
                for _, expectedSpec in ipairs(expected) do
                    local expectedName = (type(expectedSpec) == "table" and expectedSpec.name) or expectedSpec
                    local expectedID   = (type(expectedSpec) == "table" and expectedSpec.id) or nil
                    local matchingID = nil
                    if expectedID and apiSpecByID[expectedID] then
                        matchingID = expectedID
                    elseif expectedName and apiSpecByNameLow[expectedName:lower()] then
                        matchingID = apiSpecByNameLow[expectedName:lower()]
                    end
                    local targetID = matchingID or expectedID
                    local dName = (targetID and apiSpecNameByID[targetID]) or expectedName
                    classSpecData[cname].specs[#classSpecData[cname].specs + 1] = {
                        id = targetID,
                        displayName = dName,
                        apiKnown = targetID and apiSpecByID[targetID] and true or false,
                    }
                end
            else
                for si = 1, num do
                    local specID, specName = GetSpecializationInfoForClassID(classID, si)
                    if specID and specName then
                        classSpecData[cname].specs[#classSpecData[cname].specs + 1] = {
                            id = specID,
                            displayName = specName,
                            apiKnown = true,
                        }
                    end
                end
            end
        end
    end

    table.sort(orderedClasses, function(a, b) return a.name < b.name end)
    return orderedClasses, classSpecData
end
