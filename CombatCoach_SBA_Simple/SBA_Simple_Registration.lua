-- SBA_Simple_Registration.lua
-- Icon registration and extra-tab lifecycle for SBA_Simple.

local context = SBA_Simple_GetRegistrationContext()

local function RegisterNPIcon(mainKey)
    local npKey = mainKey .. context.npKeySuffix
    local mainDB = (mainKey == context.iconKey) and context.getDB()
        or context.getExtraIconDB(tonumber(mainKey:match("_(%d+)$")))
    local npDB = context.getNPIconDB(mainKey)
    npDB.size = (mainDB and mainDB.size) or 64
    context.registeredIconObjects[npKey] = shmIcons:Register(context.addonName, npKey, npDB, {
        onResize = function(sq) npDB.size = sq end,
        onMove = function() end,
        isNameplateManaged = true,
    })
    shmIcons:SetVisible(context.addonName, npKey, false)
end

local function UnregisterNPIcon(mainKey)
    local npKey = mainKey .. context.npKeySuffix
    context.registeredIconObjects[npKey] = nil
    shmIcons:Unregister(context.addonName, npKey)
end

function SBA_Simple_RegisterMainIcon()
    local db = context.getDB()
    db.spellName = "Rotation"
    context.registeredIconObjects[context.iconKey] = shmIcons:Register(context.addonName, context.iconKey, db, {
        onResize = function(sq) db.size = sq end,
        onMove = function() end,
    })
    shmIcons:RestoreSnapGroups()
    shmIcons:SetDisplayHotkey(context.addonName, context.iconKey, true)
    local mode = db.display_mode or "movable"
    shmIcons:SetVisible(context.addonName, context.iconKey, mode ~= "disabled")
    RegisterNPIcon(context.iconKey)
end

local function RegisterExtraIcon(tabIdx)
    local db = context.getExtraIconDB(tabIdx)
    local key = context.iconKey .. "_" .. tabIdx
    if not db.spellName then
        SBA_SimpleDB.tabNames = SBA_SimpleDB.tabNames or {}
        local specID = context.getCurrentSpecID()
        local names = SBA_SimpleDB.tabNames[specID] or {}
        db.spellName = names[tabIdx] or ("Tab " .. tabIdx)
    end
    context.registeredIconObjects[key] = shmIcons:Register(context.addonName, key, db, {
        onResize = function(sq) db.size = sq end,
        onMove = function() end,
    })
    shmIcons:SetDisplayHotkey(context.addonName, key, true)
    local mode = db.display_mode or "movable"
    shmIcons:SetVisible(context.addonName, key, mode ~= "disabled")
    RegisterNPIcon(key)
end

local function UnregisterExtraIcon(tabIdx)
    local key = context.iconKey .. "_" .. tabIdx
    context.registeredIconObjects[key] = nil
    shmIcons:Unregister(context.addonName, key)
    UnregisterNPIcon(key)
end

function SBA_Simple_UpdateExtraIconsForSpec(specID)
    specID = specID or context.getCurrentSpecID()
    if specID == 0 then return end
    SBA_SimpleDB.tabCount = SBA_SimpleDB.tabCount or {}
    local newTotal = math.max(1, tonumber(SBA_SimpleDB.tabCount[specID]) or 1)
    local newExtra = newTotal - 1
    local activeExtraTabCount = context.getActiveExtraTabCount()

    for i = newExtra + 2, activeExtraTabCount + 1 do
        UnregisterExtraIcon(i)
        context.extraOverrideChunks[i] = nil
        context.extraDisplayedSpell[i] = nil
    end
    for i = activeExtraTabCount + 2, newExtra + 1 do
        RegisterExtraIcon(i)
        context.extraDisplayedSpell[i] = nil
    end
    context.setActiveExtraTabCount(newExtra)

    local specEntry = SBA_SimpleDB.specs and SBA_SimpleDB.specs[specID]
    for i = 2, newExtra + 1 do
        local code = specEntry and specEntry["overrideCode_" .. i] or ""
        context.compileExtraOverride(i, code)
    end
end
