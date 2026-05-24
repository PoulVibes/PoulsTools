-- SBA_Simple_OverrideGUI_Core_SpellSearch.lua
-- Shared spell lookup fallbacks for override GUI inputs.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.SearchSpellBookByName(input)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return nil end

    local lower = input:lower()
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()

    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if info then
            local offset = info.itemIndexOffset
            local count = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name = C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local _, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if spellID and spellID ~= 0 then
                    if name and name:lower() == lower then return spellID end

                    if C_Spell and C_Spell.GetSpellInfo then
                        local si = C_Spell.GetSpellInfo(spellID)
                        if si and si.name and si.name:lower() == lower then return spellID end
                    end

                    if C_SpellBook.FindSpellOverrideByID then
                        local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                        if oid and oid ~= spellID then
                            local oi = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                            if oi and oi.name and oi.name:lower() == lower then return oid end
                        end
                    end
                end
            end
        end
    end

    return nil
end

function M.SearchTalentTreeByName(input)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo
        and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then
        return nil
    end

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not (configInfo and configInfo.treeIDs) then return nil end

    local lower = input:lower()
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
                                local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(defInfo.spellID)
                                if si and si.name and si.name:lower() == lower then
                                    return defInfo.spellID
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end
