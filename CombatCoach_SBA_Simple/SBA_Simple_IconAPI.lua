-- SBA_Simple_IconAPI.lua
-- Public icon controls and shared icon update routine for SBA_Simple.

local context = SBA_Simple_GetIconAPIContext()

function SBA_Simple_SetEnabled(enabled)
    local db = context.getDB()
    db.enabled = enabled
    if shmIcons and shmIcons.SetVisible then
        shmIcons:SetVisible(context.addonName, context.iconKey, enabled)
    end
end

function SBA_Simple_SetIconEnabled(key, enabled)
    local db
    if key == context.iconKey then
        db = context.getDB()
    else
        local tabIdx = tonumber(key:match("_(%d+)$"))
        if tabIdx then db = context.getExtraIconDB(tabIdx) end
    end
    if db then
        if enabled then
            if db.display_mode == "disabled" or db.display_mode == nil then
                db.display_mode = "movable"
            end
        else
            db.display_mode = "disabled"
        end
    end
    if shmIcons and shmIcons.SetVisible then
        shmIcons:SetVisible(context.addonName, key, enabled)
        shmIcons:SetVisible(context.addonName, key .. context.npKeySuffix, false)
    end
end

function SBA_Simple_GetTrackedIconInfo()
    local result = {}
    local mainDB = context.getDB()
    result[1] = { key = context.iconKey, label = mainDB.spellName or "Tab 1", db = mainDB }
    local specID = context.getCurrentSpecID()
    local savedCount = SBA_SimpleDB.tabCount and SBA_SimpleDB.tabCount[specID] or 1
    local tabTotal = math.max(context.getActiveExtraTabCount() + 1, savedCount)
    for tabIdx = 2, tabTotal do
        local tabDB = context.getExtraIconDB(tabIdx)
        result[#result + 1] = {
            key = context.iconKey .. "_" .. tabIdx,
            label = tabDB.spellName or ("Tab " .. tabIdx),
            db = tabDB,
        }
    end
    return result
end

function SBA_Simple_SetSize(size)
    local db = context.getDB()
    db.size = tonumber(size) or db.size
    if shmIcons and shmIcons.Unregister then
        shmIcons:Unregister(context.addonName, context.iconKey)
        shmIcons:Unregister(context.addonName, context.iconKey .. context.npKeySuffix)
        context.registeredIconObjects[context.iconKey .. context.npKeySuffix] = nil
    end
    SBA_Simple_RegisterMainIcon()
end

function SBA_Simple_ResetMainIconPosition()
    local db = context.getDB()
    db.x = 0
    db.y = 0
    db.point = "CENTER"
    db.size = 64
    if shmIcons and shmIcons.Unregister then
        shmIcons:Unregister(context.addonName, context.iconKey)
    end
    SBA_Simple_RegisterMainIcon()
    print("|cff00ff99SBA_Simple:|r Icon position and size reset.")
end

function SBA_Simple_UpdateTrackedIcon(iconKey, spellID, prevSpellID)
    if spellID then
        if context.spellGCDState[spellID] == nil then
            context.spellGCDState[spellID] = false
            local chargeInfo = C_Spell.GetSpellCharges(spellID)
            if chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
                shmIcons:SetStacks(context.addonName, iconKey, chargeInfo.currentCharges)
            end
        elseif spellID ~= prevSpellID then
            local chargeInfo = C_Spell.GetSpellCharges(spellID)
            if chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
                shmIcons:SetStacks(context.addonName, iconKey, chargeInfo.currentCharges)
            end
        end
    end

    if not spellID then
        shmIcons:SetVisible(context.addonName, iconKey, false)
        shmIcons:SetCooldown(context.addonName, iconKey, nil)
        shmIcons:SetStacks(context.addonName, iconKey, 0)
        shmIcons:SetGlow(context.addonName, iconKey, false)
        return nil
    end

    shmIcons:SetVisible(context.addonName, iconKey, true)
    shmIcons:SetIcon(context.addonName, iconKey, C_Spell.GetSpellTexture(spellID) or 134400)

    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    local durationObject = C_Spell.GetSpellCooldownDuration(spellID)
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    local isChargeSpell = chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1
    local chargeDuration = C_Spell.GetSpellChargeDuration(spellID)
    shmIcons:SetGlow(context.addonName, iconKey, false)

    if isChargeSpell then
        if durationObject and cdInfo and cdInfo.isActive then
            shmIcons:SetCooldown(context.addonName, iconKey, durationObject)
        elseif chargeDuration and chargeInfo and chargeInfo.isActive then
            shmIcons:SetCooldown(context.addonName, iconKey, chargeDuration)
        else
            shmIcons:SetCooldown(context.addonName, iconKey, nil)
        end
        if cdInfo and (not cdInfo.isActive or cdInfo.isOnGCD) then
            shmIcons:SetStacks(context.addonName, iconKey, chargeInfo.currentCharges)
        else
            shmIcons:SetStacks(context.addonName, iconKey, 0)
        end
    else
        if durationObject and cdInfo and cdInfo.isActive then
            shmIcons:SetCooldown(context.addonName, iconKey, durationObject)
        else
            shmIcons:SetCooldown(context.addonName, iconKey, nil)
        end
        shmIcons:SetStacks(context.addonName, iconKey, 0)
    end

    if UnitExists("target") then
        shmIcons:SetRange(context.addonName, iconKey, C_Spell.IsSpellInRange(spellID, "target"))
    else
        shmIcons:SetRange(context.addonName, iconKey, nil)
    end
    shmIcons:SetUsable(context.addonName, iconKey, C_Spell.IsSpellUsable(spellID))
    shmIcons:SetGlow(context.addonName, iconKey, false)
    return spellID
end
