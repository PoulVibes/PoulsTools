-- TriggerTracker_CreationFrame_Helpers.lua
-- Spell-query helpers shared by the creation-frame files.
-- Exposes functions via TT.CF sub-table so later-loaded files can access them.

local TT = TriggerTracker
TT.CF = TT.CF or {}
local CF = TT.CF

-- Shared backdrop helper (mirrors SBAS_GUI pattern without a hard dependency).
CF.SetBD = function(f, r, g, b, a, br, bg, bb)
    if not f.SetBackdrop then return end
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(r, g, b, a)
    f:SetBackdropBorderColor(br, bg, bb, 0.85)
end

-- Collect all talent spellIDs for the active config into a list.
CF.GetTalentSpells = function()
    local list = {}
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return list end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
        and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then
        return list
    end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return list end
    local info = C_Traits.GetConfigInfo(configID)
    if not (info and info.treeIDs) then return list end
    local seen = {}
    for _, treeID in ipairs(info.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes(treeID)
        if nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.entryIDs then
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if defInfo and defInfo.spellID and defInfo.spellID ~= 0
                                and not seen[defInfo.spellID] then
                                seen[defInfo.spellID] = true
                                local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(defInfo.spellID)
                                if si then
                                    table.insert(list, {
                                        spellID  = defInfo.spellID,
                                        name     = si.name or "Unknown",
                                        iconID   = si.iconID or 134400,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Resolve override: returns the player-visible spellID and info.
local function ResolveOverride(spellID)
    if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
        local oid = C_SpellBook.FindSpellOverrideByID(spellID)
        if oid and oid ~= 0 and oid ~= spellID then
            local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
            if si then return oid, si end
        end
    end
    return spellID, C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
end

-- Collect spellbook spells for the active class/spec, resolving overrides.
CF.GetSpellbookSpells = function()
    local list = {}
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return list end
    local seen = {}
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if lineInfo then
            local offset = lineInfo.itemIndexOffset
            local count  = lineInfo.numSpellBookItems
            for j = offset + 1, offset + count do
                local _, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if spellID and spellID ~= 0 and not seen[spellID] then
                    local resolvedID, si = ResolveOverride(spellID)
                    if si and not (C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(resolvedID)) then
                        seen[spellID] = true
                        seen[resolvedID] = true
                        table.insert(list, {
                            spellID = resolvedID,
                            name    = si.name or "Unknown",
                            iconID  = si.iconID or 134400,
                        })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
