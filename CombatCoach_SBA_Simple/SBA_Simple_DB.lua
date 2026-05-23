-- SBA_Simple_DB.lua
-- DB and spec helper functions for SBA_Simple.

function SBA_Simple_GetExtraIconDB(tabIdx)
    SBA_SimpleDB = SBA_SimpleDB or {}
    SBA_SimpleDB.extraIcons = SBA_SimpleDB.extraIcons or {}
    local key = "tab" .. tabIdx
    if not SBA_SimpleDB.extraIcons[key] then
        SBA_SimpleDB.extraIcons[key] = {
            x = 0, y = 0, point = "CENTER",
            size = 64, enabled = true, glow_enabled = false,
            display_mode = "movable",
        }
    end
    return SBA_SimpleDB.extraIcons[key]
end

function SBA_Simple_GetDB()
    SBA_SimpleDB = SBA_SimpleDB or {}
    local db = SBA_SimpleDB
    db.specs = db.specs or {}
    if db.x            == nil then db.x             = 0        end
    if db.y            == nil then db.y             = 0        end
    if db.point        == nil then db.point         = "CENTER" end
    if db.size         == nil then db.size          = 64       end
    if db.enabled          == nil then db.enabled          = true  end
    if db.glow_enabled     == nil then db.glow_enabled     = false end
    if db.overrideCode     == nil then db.overrideCode     = ""    end
    if db.overrideDebug    == nil then db.overrideDebug    = true  end
    if db.display_mode == nil then db.display_mode = "movable" end
    return db
end

function SBA_Simple_GetNPSettings()
    SBA_SimpleDB = SBA_SimpleDB or {}
    local db = SBA_SimpleDB
    if db.np_opacity == nil then db.np_opacity = 1 end
    if db.np_scale   == nil then db.np_scale   = 1 end
    if db.np_x       == nil then db.np_x       = 0 end
    if db.np_y       == nil then db.np_y       = 0 end
    return db
end

function SBA_Simple_GetNPIconDB(mainKey)
    SBA_SimpleNPDB = SBA_SimpleNPDB or {}
    if not SBA_SimpleNPDB[mainKey] then
        SBA_SimpleNPDB[mainKey] = {
            size = 64, enabled = true, glow_enabled = false,
            x = 0, y = 0, point = "CENTER",
        }
    end
    return SBA_SimpleNPDB[mainKey]
end

function SBA_Simple_GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

function SBA_Simple_GetSpecDB(specID)
    specID = specID or SBA_Simple_GetCurrentSpecID()
    local db = SBA_Simple_GetDB()
    db.specs = db.specs or {}
    db.specs[specID] = db.specs[specID] or {}
    return db.specs[specID]
end
