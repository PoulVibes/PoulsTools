-- SBA_Simple_OverrideGUI_Core_SpellItemData.lua
-- Spellbook and bag item data providers for override GUI.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

local function GetStoredSpellsForSpec(specID)
    local result, seenIDs = {}, {}
    local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[specID]
    if srcDB then
        for _, entry in pairs(srcDB) do
            if entry.spellID and not seenIDs[entry.spellID] then
                seenIDs[entry.spellID] = true
                result[#result + 1] = entry
            end
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

function M.GetClassSpells(deps)
    local curSpec = deps.currentSpecID()
    local targetSpec = (deps.editSpecID() ~= 0) and deps.editSpecID() or curSpec

    if targetSpec ~= curSpec then
        return GetStoredSpellsForSpec(targetSpec)
    end

    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
        return GetStoredSpellsForSpec(targetSpec)
    end

    local spells, seen = {}, {}
    local isFlyoutType = Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
    local isFutureType = Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell

    local primaryTabs = {}
    primaryTabs[UnitClass("player")] = true
    primaryTabs[UnitRace("player")] = true
    local specIdx = GetSpecialization and GetSpecialization()
    if specIdx then
        local specName = select(2, GetSpecializationInfo(specIdx))
        if specName then primaryTabs[specName] = true end
    end

    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if info and not info.isGuild and not info.offSpecID then
            local isPrimaryTab = primaryTabs[info.name]
            local offset = info.itemIndexOffset
            local count = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name = C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local itemType, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if name and spellID and spellID ~= 0 then
                    local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)
                    local subtext = (not isPrimaryTab) and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID) or nil
                    local skip = (isFlyoutType and itemType == isFlyoutType)
                        or (isFutureType and itemType == isFutureType)
                        or (not isPrimaryTab and not (subtext and subtext:find("Racial")))
                        or isPassive
                        or seen[spellID]
                    if not skip then
                        local baseInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
                        local baseName = (baseInfo and baseInfo.name) or name
                        seen[spellID] = true

                        local overID, overInfo, overName
                        if C_SpellBook.FindSpellOverrideByID then
                            local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                            if oid and oid ~= spellID and not seen[oid] then
                                local isOverPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(oid)
                                if not isOverPassive then
                                    overID = oid
                                    overInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                                    overName = overInfo and overInfo.name
                                end
                            end
                        end

                        if overID then
                            seen[overID] = true
                            if overName and overName ~= baseName then
                                spells[#spells + 1] = {
                                    name = baseName,
                                    spellID = spellID,
                                    texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                }
                            end
                            spells[#spells + 1] = {
                                name = overName or baseName,
                                spellID = overID,
                                texture = (overInfo and overInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        else
                            spells[#spells + 1] = {
                                name = baseName,
                                spellID = spellID,
                                texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        end
                    end
                end
            end
        end
    end

    if curSpec ~= 0 then
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        SBA_SimpleDB.castsSeen[curSpec] = SBA_SimpleDB.castsSeen[curSpec] or {}
        local curDB = SBA_SimpleDB.castsSeen[curSpec]
        for _, sp in ipairs(spells) do
            if not curDB[sp.spellID] then
                curDB[sp.spellID] = { name = sp.name, spellID = sp.spellID, texture = sp.texture }
            end
        end
    end

    local seenNames = {}
    for _, sp in ipairs(spells) do seenNames[sp.name] = true end

    local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
    if srcDB then
        for castID, entry in pairs(srcDB) do
            if not seen[castID] and entry.name and not seenNames[entry.name] then
                seen[castID] = true
                seenNames[entry.name] = true
                spells[#spells + 1] = entry
            end
        end
    end

    for castID, entry in pairs(deps.seenCastSpells or {}) do
        if not seen[castID] and entry.name and not seenNames[entry.name] then
            seen[castID] = true
            spells[#spells + 1] = entry
        end
    end

    table.sort(spells, function(a, b) return a.name < b.name end)
    return spells
end

function M.GetBagItems()
    local items, seen = {}, {}

    for bag = 0, 4 do
        local numSlots = C_Container and C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and not seen[info.itemID] then
                local itemName = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(info.itemID)
                local _, spellID = GetItemSpell(info.itemID)
                if spellID and itemName then
                    seen[info.itemID] = true
                    items[#items + 1] = {
                        name = itemName,
                        itemID = info.itemID,
                        spellID = spellID,
                        texture = info.iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark",
                    }
                end
            end
        end
    end

    for slotID = 1, 19 do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID and not seen[itemID] then
            local itemName = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(itemID)
            local _, spellID = GetItemSpell(itemID)
            if spellID and itemName then
                seen[itemID] = true
                local tex = GetInventoryItemTexture("player", slotID)
                items[#items + 1] = {
                    name = itemName,
                    itemID = itemID,
                    spellID = spellID,
                    texture = tex or "Interface\\Icons\\INV_Misc_QuestionMark",
                }
            end
        end
    end

    table.sort(items, function(a, b) return a.name < b.name end)
    return items
end
