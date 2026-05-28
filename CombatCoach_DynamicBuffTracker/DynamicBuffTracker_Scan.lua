-- DynamicBuffTracker_Scan.lua
-- UnloadSpec, ScanAndSync, ScanOrRetry, LoadSpec.

local DBT = DynamicBuffTracker

-- ============================================================
-- Spec unload
-- ============================================================

function DynamicBuffTracker_UnloadSpec()
    local specID = DBT.currentSpecID
    DynamicBuffTracker_ClearSBASEntriesForSpec(specID)
    for spellIDStr in pairs(DBT.trackedSpells) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            DynamicBuffTracker_UnregisterIcon(spellID)
            _G[DynamicBuffTracker_MakeActiveFlag(specID, spellID)] = false
            -- stop any running condition timer and clear shown flag
            DynamicBuffTracker_StopBuffTimer(specID, spellID, "spec_unload")
            if DBT.iconShown then DBT.iconShown[spellIDStr] = nil end
        end
    end
    DBT.trackedSpells   = {}
    DBT.hookedChildren  = {}
    DBT.cdmSpellToFrame = {}
    DBT.cdmFrameToSpell = {}
end

-- ============================================================
-- Main scan
-- ============================================================

local function UpdateSingleTargetFlags(specID)
    local buffDB = DynamicBuffTracker_GetSpecBuffDB(specID)
    for spellIDStr, entry in pairs(buffDB) do
        local sid = tonumber(spellIDStr)
        if sid then
            local ok, desc = pcall(C_Spell.GetSpellDescription, sid)
            entry.singleTarget = ok and type(desc) == "string" and desc:lower():find("single target") ~= nil
        end
    end
end

function DynamicBuffTracker_ScanAndSync()
    if InCombatLockdown() then return end

    local viewer = _G["BuffIconCooldownViewer"]
    if not viewer then return end

    local specID = DBT.currentSpecID
    if specID == 0 then return end

    DynamicBuffTracker_HookViewerChildren(viewer)

    local buffDB    = DynamicBuffTracker_GetSpecBuffDB(specID)
    local removedDB = DynamicBuffTracker_GetSpecRemovedDB(specID)
    local ADDON     = DBT.ADDON_NAME
    local DEF_SIZE  = DBT.DEFAULT_SIZE

    for spellIDStr, spellID in pairs(DBT.trackedSpells) do
        local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and spellInfo then ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name) end
        if ok and spellInfo then
            if spellInfo.iconID then
                if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                local entry = buffDB[spellIDStr]
                local useIcon = (entry and entry.override_icon) or spellInfo.iconID
                shmIcons:SetDisplayName(ADDON, DynamicBuffTracker_MakeKey(spellID), spellInfo.name)
                shmIcons:SetIcon(ADDON, DynamicBuffTracker_MakeKey(spellID), useIcon)
            end
            if spellInfo.name then
                DynamicBuffTracker_RegisterSBASEntry(specID, spellID, spellInfo.name)
            end
        end
    end

    for spellID, child in pairs(DBT.cdmSpellToFrame) do
        local spellIDStr = tostring(spellID)

        if child.cooldownID then
            if not DBT.trackedSpells[spellIDStr] then
                local entry = buffDB[spellIDStr]
                if not entry and not removedDB[spellIDStr] then
                    local spellName, iconID
                    local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                    if ok and spellInfo and spellInfo.name then
                        spellName = spellInfo.name
                        iconID    = spellInfo.iconID
                    end

                    if spellName and iconID then
                        local count = 0
                        for _ in pairs(buffDB) do count = count + 1 end
                        local col  = count % 5
                        local row  = math.floor(count / 5)
                        local xOff = (col - 2) * (DEF_SIZE + 4)
                        local yOff = row > 0 and (-row * (DEF_SIZE + 4)) or 0

                        entry = {
                            spellID      = spellID,
                            spellName    = spellName,
                            iconID       = iconID,
                            label        = spellName,
                            x            = xOff,
                            y            = yOff,
                            point        = "CENTER",
                            size         = DEF_SIZE,
                            enabled      = false,
                            glow_enabled = false,
                        }
                        buffDB[spellIDStr] = entry
                    end
                end

                if entry then
                    DynamicBuffTracker_RegisterIcon(spellID, entry)
                    DBT.trackedSpells[spellIDStr] = spellID
                    DynamicBuffTracker_RegisterSBASEntry(specID, spellID, entry.label)
                end
            end

            DynamicBuffTracker_HookViewerChild(spellID, child)
            DynamicBuffTracker_SyncIconFromCDMFrame(spellID, specID)
        elseif DBT.trackedSpells[spellIDStr] then
            DynamicBuffTracker_HookViewerChild(spellID, child)
        end
    end

    UpdateSingleTargetFlags(specID)
    if DBT.rebuildCombatCoachList then DBT.rebuildCombatCoachList() end
end

-- ============================================================
-- Scan with retry
-- ============================================================

local ScanOrRetry  -- forward declare (self-referential)

ScanOrRetry = function()
    if InCombatLockdown() then return end
    local viewer   = _G["BuffIconCooldownViewer"]
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and
                     C_ClassTalents.GetActiveConfigID()
    if not viewer or not configID then
        if DBT.retryCount < DBT.MAX_RETRIES and not DBT.retryPending then
            DBT.retryCount   = DBT.retryCount + 1
            DBT.retryPending = true
            C_Timer.After(3, function()
                DBT.retryPending = false
                ScanOrRetry()
            end)
        end
        return
    end
    DBT.retryCount   = 0
    DBT.retryPending = false
    DynamicBuffTracker_ScanAndSync()
end

-- Store as global so the event file can call it.
DynamicBuffTracker_ScanOrRetry = ScanOrRetry

-- ============================================================
-- Spec load
-- ============================================================

function DynamicBuffTracker_LoadSpec(specID)
    DynamicBuffTracker_UnloadSpec()
    DBT.currentSpecID = specID
    if specID == 0 then return end
    local buffDB = DynamicBuffTracker_GetSpecBuffDB(specID)
    local ADDON  = DBT.ADDON_NAME
    for spellIDStr, entry in pairs(buffDB) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            DynamicBuffTracker_RegisterIcon(spellID, entry)
            DBT.trackedSpells[spellIDStr] = spellID
            DynamicBuffTracker_RegisterSBASEntry(specID, spellID, entry.label)
        end
    end
    for spellIDStr, spellID in pairs(DBT.trackedSpells) do
        local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and spellInfo then
            ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name)
        end
        if ok and spellInfo then
            if spellInfo.iconID then
                if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                local entry = buffDB[spellIDStr]
                local useIcon = (entry and entry.override_icon) or spellInfo.iconID
                shmIcons:SetDisplayName(ADDON, DynamicBuffTracker_MakeKey(spellID), spellInfo.name)
                shmIcons:SetIcon(ADDON, DynamicBuffTracker_MakeKey(spellID), useIcon)
            end
            if spellInfo.name then
                DynamicBuffTracker_RegisterSBASEntry(specID, spellID, spellInfo.name)
            end
        end
    end
    DynamicBuffTracker_ResyncCDMFrames()
    if not InCombatLockdown() then UpdateSingleTargetFlags(specID) end
    DynamicBuffTracker_ScanOrRetry()
end
