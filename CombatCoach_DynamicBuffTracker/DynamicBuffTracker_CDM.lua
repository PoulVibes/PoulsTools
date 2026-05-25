-- DynamicBuffTracker_CDM.lua
-- CDM frame hooking, viewer child tracking, and SyncIconFromCDMFrame.
-- ScanTalentTree is also here; everything else depends on the sync functions.

local DBT = DynamicBuffTracker

-- ============================================================
-- Spell-ID resolution from a CDM child frame
-- ============================================================

local function GetFrameSpellID(frame)
    if not frame.cooldownInfo then return nil end
    local id = frame.cooldownInfo.spellID
    return (id and id > 0) and id or nil
end

-- ============================================================
-- Viewer child aura helpers
-- ============================================================

local function GetChildAuraData(child)
    if child.auraInstanceID then
        local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                             "player", child.auraInstanceID)
        if ok and ad then 
            return ad, "player" end
        ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                       "target", child.auraInstanceID)
        if ok and ad then            
            return ad, "target" end
    end
    return nil, nil
end

local function GetChildAuraDuration(child, unitToken)
    if child.auraInstanceID and unitToken then
        local ok, ad = pcall(C_UnitAuras.GetAuraDuration, unitToken, child.auraInstanceID)
        if ok and ad then return ad end
    end
    return nil
end

-- ============================================================
-- SyncIconFromCDMFrame
-- ============================================================

function DynamicBuffTracker_SyncIconFromCDMFrame(spellID, specID)
    local child = DBT.cdmSpellToFrame[spellID]
    if not child or DBT.cdmFrameToSpell[child] ~= spellID then return end

    specID = specID or DBT.currentSpecID
    local key        = DynamicBuffTracker_MakeKey(spellID)
    local activeFlag = DynamicBuffTracker_MakeActiveFlag(specID, spellID)
    local ADDON      = DBT.ADDON_NAME

    local auraData, unitFound = GetChildAuraData(child)
    local auraDuration        = GetChildAuraDuration(child, unitFound)

    local buffDB    = DynamicBuffTracker_GetSpecBuffDB(specID)
    local entry     = buffDB[tostring(spellID)]
    local isEnabled = entry and entry.enabled
    local spellIDStr = tostring(spellID)
    local wasShown = DBT.iconShown and DBT.iconShown[spellIDStr]

    if not auraData then
        _G[activeFlag] = false
        -- stop visibility and any running condition timer
        if DBT.iconShown and DBT.iconShown[spellIDStr] then
            DBT.iconShown[spellIDStr] = nil
            DynamicBuffTracker_StopBuffTimer(specID, spellID, "aura_missing")
        end
        shmIcons:SetVisible(ADDON, key, false)
        shmIcons:SetGlow(ADDON, key, false)
        shmIcons:SetStacks(ADDON, key, 0)
        shmIcons:SetCooldown(ADDON, key, nil)
        return
    end

    _G[activeFlag] = true
    if isEnabled then
        shmIcons:SetVisible(ADDON, key, true)
        shmIcons:SetGlow(ADDON, key, true)
        shmIcons:SetStacks(ADDON, key, auraData.applications or 0)
        shmIcons:SetCooldown(ADDON, key, auraDuration or nil)
        DBT.iconShown = DBT.iconShown or {}
        DBT.iconShown[spellIDStr] = true
        -- Start a condition timer on show transition, and also self-heal if the
        -- icon is shown but no timer handle exists (missed edge transition).
        local durationToUse = nil
        if entry and entry.buff_timer and tonumber(entry.buff_timer) then
            durationToUse = tonumber(entry.buff_timer)
        elseif DynamicBuffTracker_Defaults and DynamicBuffTracker_Defaults[spellID] and DynamicBuffTracker_Defaults[spellID].timer then
            durationToUse = tonumber(DynamicBuffTracker_Defaults[spellID].timer)
        end

        local runningHandle = DBT.buffTimerHandles and DBT.buffTimerHandles[spellIDStr]
        local hasRunningTimer = runningHandle
            and tostring(runningHandle.specID) == tostring(specID)

        if durationToUse and durationToUse > 0 then
            if (not wasShown) or (not hasRunningTimer) then
                DynamicBuffTracker_StartBuffTimer(specID, spellID, durationToUse)
            end
        end
    end
end

-- ============================================================
-- Shared UNIT_AURA listener
-- ============================================================

local unitAuraFrame = CreateFrame("Frame")
unitAuraFrame:RegisterUnitEvent("UNIT_AURA", "player")
unitAuraFrame:RegisterUnitEvent("UNIT_AURA", "target")
unitAuraFrame:SetScript("OnEvent", function()
    for _, spellID in pairs(DBT.trackedSpells) do
        DynamicBuffTracker_SyncIconFromCDMFrame(spellID)
    end
end)

-- ============================================================
-- HookViewerChild
-- ============================================================

function DynamicBuffTracker_HookViewerChild(spellID, child)
    local spellIDStr = tostring(spellID)
    if DBT.hookedChildren[spellIDStr] == child then return end
    DBT.hookedChildren[spellIDStr] = child

    local hookSpecID = DBT.currentSpecID
    local activeFlag = DynamicBuffTracker_MakeActiveFlag(hookSpecID, spellID)
    local key        = DynamicBuffTracker_MakeKey(spellID)
    local ADDON      = DBT.ADDON_NAME

    local function IsOwner()
        return DBT.currentSpecID == hookSpecID and DBT.cdmFrameToSpell[child] == spellID
    end

    local function UpdateFromChild()
        if not IsOwner() then return end
        DynamicBuffTracker_SyncIconFromCDMFrame(spellID, hookSpecID)
    end

    local hideTimer = nil
    child:HookScript("OnHide", function()
        if not IsOwner() then return end
        hideTimer = C_Timer.NewTimer(0.1, function()
            hideTimer = nil
            if not IsOwner() then return end
            _G[activeFlag] = false
            DBT.iconShown = DBT.iconShown or {}
            DBT.iconShown[tostring(spellID)] = nil
            DynamicBuffTracker_StopBuffTimer(hookSpecID, spellID, "child_hide")
            shmIcons:SetVisible(ADDON, key, false)
            shmIcons:SetGlow(ADDON, key, false)
            shmIcons:SetStacks(ADDON, key, 0)
            shmIcons:SetCooldown(ADDON, key, nil)
        end)
    end)
    child:HookScript("OnShow", function()
        if hideTimer then hideTimer:Cancel() hideTimer = nil end
        if not IsOwner() then return end
        UpdateFromChild()
    end)

    UpdateFromChild()
    C_Timer.After(1.0, function()
        if DBT.currentSpecID == hookSpecID then UpdateFromChild() end
    end)
end

-- ============================================================
-- CDM frame hooking
-- ============================================================

local function ProcessFrameCurrentSpell(frame)
    local spellID = GetFrameSpellID(frame)
    if not spellID then
        local oldSpellID = DBT.cdmFrameToSpell[frame]
        if oldSpellID then
            if DBT.cdmSpellToFrame[oldSpellID] == frame then
                DBT.cdmSpellToFrame[oldSpellID] = nil
            end
            DBT.cdmFrameToSpell[frame] = nil
        end
        return
    end

    local oldSpellID = DBT.cdmFrameToSpell[frame]
    if oldSpellID and oldSpellID ~= spellID then
        if DBT.cdmSpellToFrame[oldSpellID] == frame then
            DBT.cdmSpellToFrame[oldSpellID] = nil
        end
        if DBT.hookedChildren[tostring(oldSpellID)] == frame then
            DBT.hookedChildren[tostring(oldSpellID)] = nil
        end
    end

    DBT.cdmSpellToFrame[spellID] = frame
    DBT.cdmFrameToSpell[frame]   = spellID

    local spellIDStr = tostring(spellID)
    if DBT.trackedSpells[spellIDStr] then
        if DBT.hookedChildren[spellIDStr] ~= frame then
            DynamicBuffTracker_HookViewerChild(spellID, frame)
        end
        local capturedSpec = DBT.currentSpecID
        C_Timer.After(0, function()
            if DBT.currentSpecID == capturedSpec then
                DynamicBuffTracker_SyncIconFromCDMFrame(spellID, capturedSpec)
            end
        end)
    end
end

function DynamicBuffTracker_ResyncCDMFrames()
    for frame in pairs(DBT.cdmFrames) do
        ProcessFrameCurrentSpell(frame)
    end
end

function DynamicBuffTracker_ReevaluateVisibility()
    local specID = DBT.currentSpecID
    if not specID or specID == 0 then return end

    for spellIDStr, spellID in pairs(DBT.trackedSpells) do
        if DBT.cdmSpellToFrame[spellID] then
            DynamicBuffTracker_SyncIconFromCDMFrame(spellID, specID)
        else
            local key = DynamicBuffTracker_MakeKey(spellID)
            _G[DynamicBuffTracker_MakeActiveFlag(specID, spellID)] = false
            if DBT.iconShown then DBT.iconShown[spellIDStr] = nil end
            DynamicBuffTracker_StopBuffTimer(specID, spellID, "reevaluate_no_frame")
            shmIcons:SetVisible(DBT.ADDON_NAME, key, false)
            shmIcons:SetGlow(DBT.ADDON_NAME, key, false)
            shmIcons:SetStacks(DBT.ADDON_NAME, key, 0)
            shmIcons:SetCooldown(DBT.ADDON_NAME, key, nil)
        end
    end
end

function DynamicBuffTracker_HookCDMFrame(frame)
    if not frame or DBT.cdmFrames[frame] then return end
    if not frame.SetAuraInstanceInfo then return end

    DBT.cdmFrames[frame] = true

    hooksecurefunc(frame, "SetAuraInstanceInfo", function(f, _)
        ProcessFrameCurrentSpell(f)
    end)

    ProcessFrameCurrentSpell(frame)
end

function DynamicBuffTracker_HookViewerChildren(viewer)
    if not viewer then return end
    for i = 1, viewer:GetNumChildren() do
        local child = select(i, viewer:GetChildren())
        DynamicBuffTracker_HookCDMFrame(child)
    end
end

-- ============================================================
-- Talent tree scanning
-- ============================================================

function DynamicBuffTracker_ScanTalentTree()
    local spellMap = {}
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return spellMap end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return spellMap end
    if not C_Traits then return spellMap end
    local configInfo = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs then return spellMap end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeID)
        if nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo and
                                 C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.currentRank and nodeInfo.currentRank > 0 then
                    local entryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
                    if not entryID and nodeInfo.entryIDs and nodeInfo.entryIDs[1] then
                        entryID = nodeInfo.entryIDs[1]
                    end
                    if entryID then
                        local entryInfo = C_Traits.GetEntryInfo and
                                          C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local defInfo = C_Traits.GetDefinitionInfo and
                                            C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if defInfo and defInfo.spellID and defInfo.spellID > 0 then
                                local ok, spellInfo = pcall(C_Spell.GetSpellInfo, defInfo.spellID)
                                if ok and spellInfo and spellInfo.name and spellInfo.iconID then
                                    local sid = defInfo.spellID
                                    spellMap[sid] = {
                                        spellID   = sid,
                                        spellName = spellInfo.name,
                                        iconID    = spellInfo.iconID,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return spellMap
end
