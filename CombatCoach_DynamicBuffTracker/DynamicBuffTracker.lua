-- DynamicBuffTracker.lua
-- Dynamically generates shmIcons and SBAS plugin conditions for every
-- selected talent in the player's active talent tree.
--
-- Discovery uses C_Traits / C_ClassTalents plus CDM child frame hooks
-- (same approach as TellMeWhen) to identify spells from cooldownInfo.spellID
-- rather than texture IDs, which works correctly even when aura data is
-- secret/tainted in combat.
--
-- Triggers a scan on: login, reload, spec change, and talent/trait update.
-- Per-spec discovered spells are persisted in DynamicBuffTrackerDB so icons
-- and conditions survive reloads.
--
-- SBAS integration: populates _G.SBAS_DynBuffRegistry[pluginID] for each
-- discovered spell. SBA_Simple_OverrideGUI reads this table to expose the
-- spell as a selectable Plugin/Proc condition for any spec.
--
-- Slash command: /dbt

local ADDON_FOLDER   = "CombatCoach_DynamicBuffTracker"
local ADDON_NAME     = "Dynamic Buff Tracker"
local DEFAULT_SIZE   = 64
local SCAN_INTERVAL  = 5.0   -- seconds between periodic viewer polls
local MAX_RETRIES    = 6     -- retry attempts when viewer/config isn't ready yet

-- ============================================================
-- Runtime state
-- ============================================================

local currentSpecID   = 0
local trackedSpells   = {}   -- [spellIDStr (string)] = spellID (number)
local hookedChildren  = {}   -- [spellIDStr (string)] = viewer child frame; prevents double-hook
local retryCount      = 0
local retryPending    = false
local rebuildCombatCoachList  -- set by OnBuildUI when the CombatCoach panel is constructed

-- CDM frame tracking (TellMeWhen approach)
-- cdmFrames[frame]        = true    (all frames we have hooked SetAuraInstanceInfo on)
-- cdmSpellToFrame[spellID] = frame  (most-recently-assigned frame for a spell ID)
-- cdmFrameToSpell[frame]  = spellID (reverse: current spell assigned to a frame)
--
-- cdmFrameToSpell is the key guard against stale hooks: HookScript accumulates
-- permanently, so when a frame is reassigned to a different spell, every old
-- closure checks cdmFrameToSpell[child] ~= spellID and returns immediately.
local cdmFrames       = {}
local cdmSpellToFrame = {}
local cdmFrameToSpell = {}

-- ============================================================
-- Utilities
-- ============================================================

local function GetCurrentSpecID()
    local si = GetSpecialization()
    if not si then return 0 end
    return select(1, GetSpecializationInfo(si)) or 0
end

-- Returns the buffs sub-table for a spec, creating it if absent.
local function GetSpecBuffDB(specID)
    DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
    if not DynamicBuffTrackerDB.specs[specID] then
        DynamicBuffTrackerDB.specs[specID] = { buffs = {} }
    end
    DynamicBuffTrackerDB.specs[specID].buffs =
        DynamicBuffTrackerDB.specs[specID].buffs or {}
    return DynamicBuffTrackerDB.specs[specID].buffs
end

-- shmIcons key for a given spell ID.
local function MakeKey(spellID)
    return "dbt_" .. tostring(spellID)
end

-- Global variable name that tracks whether a buff is currently active.
local function MakeActiveFlag(specID, spellID)
    return "DynBuff_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Active"
end

-- Plugin ID used in the SBAS condition registry and saved data.
local function MakePluginID(specID, spellID)
    return "dynbuff_" .. tostring(specID) .. "_" .. tostring(spellID)
end

-- ============================================================
-- CDM frame spell ID resolution (TellMeWhen approach)
-- ============================================================

-- Reads the base spell ID from a CDM child frame's cooldownInfo struct.
-- cooldownInfo.spellID is populated by Blizzard before secrets are applied,
-- so it is safe to read even in combat.
--
-- We always return this base ID as the canonical shmIcon key so it remains
-- stable regardless of whether an override talent (e.g. Wither for Immolate)
-- is currently purchased. The displayed name and icon are resolved separately
-- at runtime via GetOverrideSpell so they stay current without rehooking.
-- GetBaseSpell on an unlearned override spell is unreliable (the client may
-- not have the spell data loaded), so we avoid it entirely here.
local function GetFrameSpellID(frame)
    if not frame.cooldownInfo or not frame.cooldownID then return nil end
    return frame.cooldownInfo.spellID
end

-- ============================================================
-- Talent tree scanning
-- ============================================================

-- Walks the active talent config and returns a spellMap:
--   spellMap[spellID] = { spellID, spellName, iconID }  (every purchased node)
-- Only purchased nodes (currentRank > 0) are included. No alias expansion is
-- done; GetFrameSpellID already resolves override/linked IDs correctly, and
-- ScanAndSync falls back to C_Spell.GetSpellInfo for any spell not in spellMap.
local function ScanTalentTree()
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

-- ============================================================
-- Viewer child helpers
-- ============================================================

-- Looks up AuraData by auraInstanceID on player then target.
-- Returns auraData, unitToken (or nil, nil if not found).
local function GetChildAuraData(child)
    if child.auraInstanceID then
        local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                             "player", child.auraInstanceID)
        if ok and ad then return ad, "player" end
        ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                       "target", child.auraInstanceID)
        if ok and ad then return ad, "target" end
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
-- Viewer child hook (active-state driver)
-- ============================================================

-- Hooks OnHide/OnShow and UNIT_AURA listeners on a CDM child frame to drive
-- shmIcon visibility, stacks, and cooldown sweep.
-- child.auraInstanceID is kept current by the SetAuraInstanceInfo hook below,
-- so we never need to fall back to spell-name lookups here.
local function HookViewerChild(spellID, child)
    local spellIDStr = tostring(spellID)
    -- Guard: only hook each (spellID, child) pair once.
    if hookedChildren[spellIDStr] == child then return end
    hookedChildren[spellIDStr] = child

    local hookSpecID = currentSpecID
    local activeFlag = MakeActiveFlag(hookSpecID, spellID)
    local key        = MakeKey(spellID)

    -- This guard is the critical defence against stale closures.
    -- HookScript is permanent, so when the CDM frame pool reassigns this child
    -- to a different spell, cdmFrameToSpell[child] changes and every callback
    -- below returns immediately rather than updating the wrong shmIcon.
    local function IsOwner()
        return currentSpecID == hookSpecID and cdmFrameToSpell[child] == spellID
    end

    local function UpdateFromChild()
        if not IsOwner() then return end

        local auraData, unitFound = GetChildAuraData(child)
        local auraDuration = GetChildAuraDuration(child, unitFound)

        if not auraData then
            _G[activeFlag] = false
            pcall(shmIcons.SetVisible,  shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetGlow,     shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetStacks,   shmIcons, ADDON_NAME, key, 0)
            pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, nil)
            return
        end

        _G[activeFlag] = true
        pcall(shmIcons.SetVisible, shmIcons, ADDON_NAME, key, true)
        pcall(shmIcons.SetGlow,    shmIcons, ADDON_NAME, key, true)
        pcall(shmIcons.SetStacks,  shmIcons, ADDON_NAME, key, auraData.applications or 0)
        pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, auraDuration or nil)
    end

    -- Debounce OnHide so a same-frame Hide+Show (buff refresh) does not flicker.
    local hideTimer = nil
    child:HookScript("OnHide", function()
        if not IsOwner() then return end
        hideTimer = C_Timer.NewTimer(0.1, function()
            hideTimer = nil
            if not IsOwner() then return end
            _G[activeFlag] = false
            pcall(shmIcons.SetVisible,  shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetGlow,     shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetStacks,   shmIcons, ADDON_NAME, key, 0)
            pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, nil)
        end)
    end)
    child:HookScript("OnShow", function()
        if hideTimer then hideTimer:Cancel() hideTimer = nil end
        if not IsOwner() then return end
        UpdateFromChild()
    end)

    -- UNIT_AURA on both units so refresh/expiry is caught regardless of whether
    -- the buff is on player (HELPFUL) or target (HARMFUL).
    local playerFrame = CreateFrame("Frame")
    playerFrame:RegisterUnitEvent("UNIT_AURA", "player")
    playerFrame:SetScript("OnEvent", UpdateFromChild)

    local targetFrame = CreateFrame("Frame")
    targetFrame:RegisterUnitEvent("UNIT_AURA", "target")
    targetFrame:SetScript("OnEvent", UpdateFromChild)

    UpdateFromChild()
    C_Timer.After(1.0, function()
        if currentSpecID == hookSpecID then UpdateFromChild() end
    end)
end

-- ============================================================
-- CDM frame hooking (TellMeWhen approach)
-- ============================================================

-- Forward declaration so HookCDMFrame can call ScanAndSync.
local ScanAndSync

-- Shared logic: update both CDM mapping tables for a frame's current spell and
-- call HookViewerChild if the spell is tracked. Safe to call at any time —
-- HookViewerChild is already guarded against re-hooking the same (spell, child) pair.
local function ProcessFrameCurrentSpell(frame)
    local spellID = GetFrameSpellID(frame)
    if not spellID then return end

    -- Clear stale entries for the spell this frame was previously carrying.
    -- This must happen before updating cdmFrameToSpell so that any in-flight
    -- closures for the old spell fail their IsOwner() check immediately.
    local oldSpellID = cdmFrameToSpell[frame]
    if oldSpellID and oldSpellID ~= spellID then
        if cdmSpellToFrame[oldSpellID] == frame then
            cdmSpellToFrame[oldSpellID] = nil
        end
        if hookedChildren[tostring(oldSpellID)] == frame then
            hookedChildren[tostring(oldSpellID)] = nil
        end
    end

    -- Update both directions of the mapping.
    cdmSpellToFrame[spellID] = frame
    cdmFrameToSpell[frame]   = spellID

    -- If we are already tracking this spell, wire up the child immediately.
    local spellIDStr = tostring(spellID)
    if trackedSpells[spellIDStr] and hookedChildren[spellIDStr] ~= frame then
        HookViewerChild(spellID, frame)
    end
end

-- Re-processes the current spell for every frame we have ever hooked.
-- Call this after trackedSpells is updated so that already-active frames
-- (whose SetAuraInstanceInfo fired before our hook was installed, e.g. on
-- login/reload with a buff already active) get their child wired up.
local function ResyncCDMFrames()
    for frame in pairs(cdmFrames) do
        ProcessFrameCurrentSpell(frame)
    end
end

-- Hooks SetAuraInstanceInfo on a CDM child frame.
-- When Blizzard assigns an aura to the frame:
--   1. frame.cooldownInfo.spellID is read (non-secret, safe in combat).
--   2. cdmSpellToFrame/cdmFrameToSpell are updated.
--   3. If the spell is already tracked, HookViewerChild is called immediately.
-- Also processes the frame's current spell immediately to handle the case where
-- SetAuraInstanceInfo already fired before this hook was installed.
local function HookCDMFrame(frame)
    if not frame or cdmFrames[frame] then return end
    if not frame.SetAuraInstanceInfo then return end

    cdmFrames[frame] = true

    hooksecurefunc(frame, "SetAuraInstanceInfo", function(f, _)
        ProcessFrameCurrentSpell(f)
    end)

    -- Process the frame's current spell right now in case SetAuraInstanceInfo
    -- already fired before we installed the hook (e.g. buff was already active
    -- at login/reload when HookViewerChildren iterates existing frames).
    ProcessFrameCurrentSpell(frame)
end

-- Iterates all current children of a viewer and hooks any that have
-- SetAuraInstanceInfo (i.e. are real CDM buff frames, not decorative children).
local function HookViewerChildren(viewer)
    if not viewer then return end
    for i = 1, viewer:GetNumChildren() do
        local child = select(i, viewer:GetChildren())
        HookCDMFrame(child)
    end
end

-- ============================================================
-- shmIcons management
-- ============================================================

local function RegisterIcon(spellID, db)
    local key = MakeKey(spellID)
    shmIcons:Register(ADDON_NAME, key, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function() end,
    })
    shmIcons:SetCooldownReverse(ADDON_NAME, key, true)
    shmIcons:SetHideCooldownText(ADDON_NAME, key, db.hide_cooldown_text or false)
    spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then spellInfo = C_Spell.GetSpellInfo(spellInfo.name) end
    if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
    --print("Registering icon for spellID:", spellID, " iconID:", spellInfo and spellInfo.iconID)
    shmIcons:SetIcon(ADDON_NAME, key, spellInfo.iconID)
    shmIcons:SetVisible(ADDON_NAME, key, false)
    shmIcons:SetGlow(ADDON_NAME, key, false)
end

local function UnregisterIcon(spellID)
    pcall(function() shmIcons:Unregister(ADDON_NAME, MakeKey(spellID)) end)
end

-- ============================================================
-- SBAS registry
-- ============================================================

local function RegisterSBASEntry(specID, spellID, label)
    _G.SBAS_DynBuffRegistry = _G.SBAS_DynBuffRegistry or {}
    _G.SBAS_DynBuffRegistry[MakePluginID(specID, spellID)] = {
        label      = label,
        activeFlag = MakeActiveFlag(specID, spellID),
        specID     = specID,
    }
end

local function UnregisterSBASEntry(specID, spellID)
    if not _G.SBAS_DynBuffRegistry then return end
    _G.SBAS_DynBuffRegistry[MakePluginID(specID, spellID)] = nil
end

local function ClearSBASEntriesForSpec(specID)
    if not _G.SBAS_DynBuffRegistry then return end
    for pid, entry in pairs(_G.SBAS_DynBuffRegistry) do
        if entry.specID == specID then
            _G.SBAS_DynBuffRegistry[pid] = nil
        end
    end
end

-- ============================================================
-- Spec unload
-- ============================================================

local function UnloadSpec()
    local specID = currentSpecID
    ClearSBASEntriesForSpec(specID)
    for spellIDStr in pairs(trackedSpells) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            UnregisterIcon(spellID)
            _G[MakeActiveFlag(specID, spellID)] = false
        end
    end
    trackedSpells  = {}
    hookedChildren = {}
end

-- ============================================================
-- Main scan
-- ============================================================

ScanAndSync = function()
    if InCombatLockdown() then return end

    local viewer = _G["BuffIconCooldownViewer"]
    if not viewer then return end

    local specID = currentSpecID
    if specID == 0 then return end

    -- Ensure all current CDM children are hooked so cdmSpellToFrame is populated.
    HookViewerChildren(viewer)

    local buffDB   = GetSpecBuffDB(specID)

    -- Refresh the runtime display icon and SBAS label for every tracked spell.
    -- GetSpellInfo(baseID) resolves active overrides natively in WoW Midnight:
    -- GetSpellInfo(immolateID) returns Wither's name/icon when the Wither talent
    -- is active. We intentionally do NOT mutate the DB entry here so the base
    -- spell ID remains the permanent canonical key regardless of talent state.
    for spellIDStr, spellID in pairs(trackedSpells) do
        local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and spellInfo then ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name) end
        if ok and spellInfo then
            if spellInfo.iconID then
                if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                --print("Updating icon for spellID:", spellID, " iconID:", spellInfo.iconID)
                shmIcons:SetIcon(ADDON_NAME, MakeKey(spellID), spellInfo.iconID)
            end
            if spellInfo.name then
                RegisterSBASEntry(specID, spellID, spellInfo.name)
            end
        end
    end
    -- Iterate ALL active CDM frames rather than just the talent spellMap.
    -- This handles both talent spells and any other spell the user has added
    -- to the CDM (e.g. base spells, class spells without a talent node).
    for spellID, child in pairs(cdmSpellToFrame) do
        -- child.cooldownID is a canary that the frame is actively in use.
        if child.cooldownID then
            local spellIDStr = tostring(spellID)

            if not trackedSpells[spellIDStr] then
                local entry = buffDB[spellIDStr]
                if not entry then
                    -- GetSpellInfo(spellID) resolves active overrides natively:
                    -- GetSpellInfo(immolateID) returns Wither's name/icon when
                    -- the Wither talent is active. No GetOverrideSpell needed.
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
                        local xOff = (col - 2) * (DEFAULT_SIZE + 4)
                        local yOff = row > 0 and (-row * (DEFAULT_SIZE + 4)) or 0

                        entry = {
                            spellID      = spellID,
                            spellName    = spellName,
                            iconID       = iconID,
                            label        = spellName,
                            x            = xOff,
                            y            = yOff,
                            point        = "CENTER",
                            size         = DEFAULT_SIZE,
                            enabled      = true,
                            glow_enabled = false,
                        }
                        buffDB[spellIDStr] = entry
                    end
                end

                if entry then
                    RegisterIcon(spellID, entry)
                    trackedSpells[spellIDStr] = spellID
                    RegisterSBASEntry(specID, spellID, entry.label)
                end
            end

            HookViewerChild(spellID, child)
        end
    end
    if rebuildCombatCoachList then rebuildCombatCoachList() end
end

-- ============================================================
-- Scan with retry
-- ============================================================

local ScanOrRetry

ScanOrRetry = function()
    if InCombatLockdown() then return end
    local viewer   = _G["BuffIconCooldownViewer"]
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and
                     C_ClassTalents.GetActiveConfigID()
    if not viewer or not configID then
        if retryCount < MAX_RETRIES and not retryPending then
            retryCount   = retryCount + 1
            retryPending = true
            C_Timer.After(3, function()
                retryPending = false
                ScanOrRetry()
            end)
        end
        return
    end
    retryCount   = 0
    retryPending = false
    ScanAndSync()
end

-- ============================================================
-- Spec load
-- ============================================================

local function LoadSpec(specID)
    UnloadSpec()
    currentSpecID = specID
    if specID == 0 then return end
    local buffDB = GetSpecBuffDB(specID)
    for spellIDStr, entry in pairs(buffDB) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            RegisterIcon(spellID, entry)
            trackedSpells[spellIDStr] = spellID
            RegisterSBASEntry(specID, spellID, entry.label)
        end
    end
    -- Apply runtime display icons. GetSpellInfo(baseID) resolves active overrides
    -- natively in WoW Midnight (e.g. GetSpellInfo(immolateID) returns Wither's
    -- name/icon when the Wither talent is taken). We do NOT write this back to the
    -- DB entry so the base spell ID is permanently the canonical key.
    for spellIDStr, spellID in pairs(trackedSpells) do
        local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and spellInfo then
            ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellInfo.name)
        end
        if ok and spellInfo then
            if spellInfo.iconID then
                if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                --print("Setting icon for spellID:", spellID, " iconID:", spellInfo.iconID)
                shmIcons:SetIcon(ADDON_NAME, MakeKey(spellID), spellInfo.iconID)
            end
            if spellInfo.name then
                --print("Setting icon for spellID:", spellID, " iconID:", spellInfo.iconID)
                RegisterSBASEntry(specID, spellID, spellInfo.name)
            end
        end
    end
    -- trackedSpells is now populated. Resync all already-hooked CDM frames so that
    -- any spell whose SetAuraInstanceInfo fired before our hook was installed
    -- (buff already active at login/reload) gets its child wired up immediately.
    -- This is what makes non-talent tracked spells work on the first load.
    ResyncCDMFrames()
    ScanOrRetry()
end

-- ============================================================
-- Event handling
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_FOLDER then
        DynamicBuffTrackerDB       = DynamicBuffTrackerDB or {}
        DynamicBuffTrackerDB.specs = DynamicBuffTrackerDB.specs or {}
        for _, specData in pairs(DynamicBuffTrackerDB.specs) do
            if type(specData) == "table" and specData.buffs then
                for k, entry in pairs(specData.buffs) do
                    if type(entry) == "table" and entry.texID and not entry.spellID then
                        specData.buffs[k] = nil
                    end
                end
            end
        end
        -- Hook OnAcquireItemFrame so new CDM children are wired up as soon as
        -- Blizzard hands them out from the frame pool.
        local viewer = _G["BuffIconCooldownViewer"]
        if viewer and viewer.OnAcquireItemFrame then
            hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, frame)
                HookCDMFrame(frame)
            end)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Hook any children that already exist (e.g. on /reload).
        HookViewerChildren(_G["BuffIconCooldownViewer"])
        currentSpecID = GetCurrentSpecID()
        LoadSpec(currentSpecID)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpec(GetCurrentSpecID())

    elseif event == "TRAIT_CONFIG_UPDATED" then
        if not InCombatLockdown() then
            C_Timer.After(0.5, function()
                if not InCombatLockdown() then ScanAndSync() end
            end)
        end

    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

-- ============================================================
-- Slash commands
-- ============================================================

SLASH_DYNAMICBUFFTRACKER1 = "/dbt"
SlashCmdList["DYNAMICBUFFTRACKER"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "scan" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot scan in combat.|r")
            return
        end
        retryCount   = 0
        retryPending = false
        ScanAndSync()
        print("|cFF00FF00DynamicBuffTracker: Scan complete.|r")

    elseif msg == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))

    elseif msg == "list" then
        if currentSpecID == 0 then
            print("|cFFFFFF00DynamicBuffTracker: No spec active.|r")
            return
        end
        local buffDB = GetSpecBuffDB(currentSpecID)
        local count  = 0
        for spellIDStr, entry in pairs(buffDB) do
            count = count + 1
            local spellID = tonumber(spellIDStr)
            local active  = spellID and _G[MakeActiveFlag(currentSpecID, spellID)]
            local label   = entry.label
            if spellID then
                local ok, si = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and si and si.name then label = si.name end
            end
            print(string.format(
                "  |cFFFFFF00%s|r (spell:%s, pluginID:%s) %s",
                label, spellIDStr,
                spellID and MakePluginID(currentSpecID, spellID) or "?",
                active and "|cFF00FF00ACTIVE|r" or "inactive"))
        end
        if count == 0 then
            print("|cFFFFFF00DynamicBuffTracker: No talents tracked for spec "
                .. tostring(currentSpecID) .. ".|r")
        end

    elseif msg == "clear" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot clear in combat.|r")
            return
        end
        UnloadSpec()
        if DynamicBuffTrackerDB and DynamicBuffTrackerDB.specs then
            DynamicBuffTrackerDB.specs[currentSpecID] = nil
        end
        print("|cFFFFFF00DynamicBuffTracker: Cleared all tracked talents for this spec.|r")

    elseif msg == "reset" then
        if InCombatLockdown() then
            print("|cFFFF4444DynamicBuffTracker: Cannot reset in combat.|r")
            return
        end
        local buffDB = GetSpecBuffDB(currentSpecID)
        for spellIDStr in pairs(buffDB) do
            local spellID = tonumber(spellIDStr)
            if spellID then
                pcall(function()
                    if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
                    print("Resetting icon for spellID:", spellID, " iconID:", spellIDStr)
                    shmIcons:ResetIcon(ADDON_NAME, MakeKey(spellID), DEFAULT_SIZE)
                end)
            end
        end
        print("|cFF00FF00DynamicBuffTracker: All icon positions reset.|r")

    else
        print("|cFFFFFF00DynamicBuffTracker commands:|r")
        print("  /dbt scan    - rescan talent tree for tracked spells")
        print("  /dbt list    - list all tracked talents for this spec")
        print("  /dbt lock    - toggle icon lock/unlock")
        print("  /dbt reset   - reset all icon positions for this spec")
        print("  /dbt clear   - clear saved talent data for this spec")
    end
end

-- ============================================================
-- CombatCoach settings panel (optional)
-- ============================================================

if CombatCoach then
    local function OnBuildUI(parent)
        local W = CombatCoach.Widgets
        if not W then return end

        local anchor = parent
        local y = 0

        local div, dy = W:SectionHeader(parent, anchor, y, "Dynamic Buff Tracker")
        anchor = div
        y = dy

        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y - 4)
        note:SetWidth(520)
        note:SetJustifyH("LEFT")
        note:SetWordWrap(true)
        note:SetTextColor(0.72, 0.82, 0.92, 1)
        note:SetText(
            "Discovers spells tracked in Blizzard\xe2\x80\x99s CooldownManager (BuffIconCooldownViewer) "
            .. "whose icons match a purchased talent. Add buff icons in the CooldownManager settings, "
            .. "then click Scan Now (or change talents) to update.")
        anchor = note
        y = -8

        anchor = W:Button(parent, anchor, y, "Scan Now", function()
            if InCombatLockdown() then
                print("|cFFFF4444DynamicBuffTracker: Cannot scan in combat.|r")
                return
            end
            retryCount   = 0
            retryPending = false
            ScanAndSync()
            print("|cFF00FF00DynamicBuffTracker: Scan complete.|r")
        end)
        y = -4

        local div2, dy2 = W:SectionHeader(parent, anchor, y, "Tracked Talents (this spec)")
        anchor = div2
        y = dy2

        local listContainer = CreateFrame("Frame", nil, parent)
        listContainer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
        listContainer:SetSize(540, 0)

        local rows     = {}
        local rowCount = 0

        local function RebuildList()
            for _, r in pairs(rows) do r:Hide() end
            rows     = {}
            rowCount = 0
            if currentSpecID == 0 then return end
            local buffDB = GetSpecBuffDB(currentSpecID)

            for spellIDStr, entry in pairs(buffDB) do
                rowCount = rowCount + 1
                local r = CreateFrame("Frame", nil, listContainer)
                r:SetSize(540, 22)
                r:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -(rowCount - 1) * 24)

                -- Resolve display icon/name at render time via GetSpellInfo(baseID).
                -- In WoW Midnight this natively returns the active override's data
                -- (e.g. Wither's icon/name when the Wither talent is taken).
                local spellID = tonumber(spellIDStr)
                local displayIconID = entry.iconID
                local displayLabel  = entry.label
                if spellID then
                    local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                    if ok and spellInfo then
                        if spellInfo.iconID then displayIconID = spellInfo.iconID end
                        if spellInfo.name   then displayLabel  = spellInfo.name  end
                    end
                end
                local icon = r:CreateTexture(nil, "ARTWORK")
                icon:SetSize(20, 20)
                icon:SetPoint("LEFT", r, "LEFT", 0, 0)
                icon:SetTexture(displayIconID)

                local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                lbl:SetText(displayLabel
                    .. " |cFF888888(plugin: "
                    .. (spellID and MakePluginID(currentSpecID, spellID) or spellIDStr)
                    .. ")|r")
                lbl:SetTextColor(0.9, 0.95, 1, 1)

                local rmBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
                rmBtn:SetSize(22, 18)
                rmBtn:SetPoint("RIGHT", r, "RIGHT", 0, 0)
                rmBtn:SetText("X")
                do
                    local capturedSpellID = tonumber(spellIDStr)
                    rmBtn:SetScript("OnClick", function()
                        if InCombatLockdown() then return end
                        if capturedSpellID then
                            UnregisterIcon(capturedSpellID)
                            UnregisterSBASEntry(currentSpecID, capturedSpellID)
                            _G[MakeActiveFlag(currentSpecID, capturedSpellID)] = false
                            trackedSpells[tostring(capturedSpellID)] = nil
                            buffDB[tostring(capturedSpellID)] = nil
                        end
                        RebuildList()
                    end)
                end

                -- Cooldown-text toggle: checkbox to the left of the remove button.
                local cdTextChk = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
                cdTextChk:SetSize(20, 20)
                cdTextChk:SetPoint("RIGHT", rmBtn, "LEFT", -6, 0)
                cdTextChk:SetChecked(not (entry.hide_cooldown_text))
                cdTextChk:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Show Cooldown Text", 1, 1, 1)
                    GameTooltip:AddLine(
                        "Show or hide the countdown number on this buff icon.",
                        nil, nil, nil, true)
                    GameTooltip:Show()
                end)
                cdTextChk:SetScript("OnLeave", function() GameTooltip:Hide() end)
                do
                    local capturedEntry    = entry
                    local capturedSpellID2 = spellID
                    cdTextChk:SetScript("OnClick", function(self)
                        capturedEntry.hide_cooldown_text = not self:GetChecked()
                        if capturedSpellID2 then
                            pcall(shmIcons.SetHideCooldownText, shmIcons, ADDON_NAME,
                                MakeKey(capturedSpellID2), capturedEntry.hide_cooldown_text)
                        end
                    end)
                end

                local cdTextLbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                cdTextLbl:SetPoint("RIGHT", cdTextChk, "LEFT", -2, 0)
                cdTextLbl:SetText("Timer")
                cdTextLbl:SetTextColor(0.72, 0.82, 0.92, 1)

                r:Show()
                rows[spellIDStr] = r
            end

            listContainer:SetHeight(math.max(4, rowCount * 24))
        end

        -- Only call RebuildList while the panel is actually visible so that
        -- frames are always created in a visible parent chain.  If the panel
        -- is closed when ScanAndSync fires, the canvas-frame OnShow below
        -- will rebuild the list the moment the user navigates to this page.
        rebuildCombatCoachList = function()
            if listContainer:IsVisible() then RebuildList() end
        end
        RebuildList()

        -- Walk up to the canvas frame registered with the Settings API
        -- (the highest ancestor before UIParent).  The Settings API
        -- explicitly Show()/Hide()s this frame when switching categories,
        -- so OnShow fires reliably on both the first and every subsequent
        -- visit — unlike hooking a scroll-child frame that is never
        -- explicitly hidden and therefore may not fire OnShow on first show.
        local canvasFrame = parent
        while canvasFrame:GetParent() and canvasFrame:GetParent() ~= UIParent do
            canvasFrame = canvasFrame:GetParent()
        end
        canvasFrame:HookScript("OnShow", RebuildList)
    end

    CombatCoach.Menu:RegisterAddon({
        id        = "DynamicBuffTracker",
        name      = "Dynamic Buff Tracker",
        icon      = "Interface\\Icons\\inv_misc_eye_02",
        desc      = "Buffs mirroring Blizz cooldown manager.",
        OnBuildUI = OnBuildUI,
    })
end