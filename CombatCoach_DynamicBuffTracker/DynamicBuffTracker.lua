-- DynamicBuffTracker.lua
-- Dynamically generates shmIcons and SBAS plugin conditions for every
-- selected talent in the player's active talent tree.
--
-- Discovery uses C_Traits / C_ClassTalents (no protected frame access,
-- no secret texture IDs). Active-buff state is tracked via UNIT_AURA events.
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
-- Talent tree scanning
-- ============================================================

-- Walks the active talent config and returns two lookup tables:
--   spellMap[spellID] = { spellID, spellName, iconID }  (every purchased node)
--   iconMap[iconID]   = spellID  (for fast texture-ID to spell resolution)
local function ScanTalentTree()
    local spellMap = {}
    local iconMap  = {}
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return spellMap, iconMap end
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return spellMap, iconMap end

    if not C_Traits then return spellMap, iconMap end
    local configInfo = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs then return spellMap, iconMap end

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
                                    local sid    = defInfo.spellID
                                    local iconID = spellInfo.iconID
                                    spellMap[sid] = {
                                        spellID   = sid,
                                        spellName = spellInfo.name,
                                        iconID    = iconID,
                                    }
                                    -- First purchased talent found for an icon wins.
                                    if not iconMap[iconID] then
                                        iconMap[iconID] = sid
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return spellMap, iconMap
end

-- ============================================================
-- Viewer child helpers
-- ============================================================

-- Looks up the AuraData for a viewer child using child.auraInstanceID when
-- available (same pattern as DebugTracker Test SpellCD — direct, unambiguous).
-- Falls back to GetAuraDataBySpellName if the instance ID isn't set yet.
-- Returns AuraData table or nil.
local function GetChildAuraData(child, spellName, unitToken)
    if child.auraInstanceID then
        local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                             unitToken, child.auraInstanceID)
        if ok and ad then return ad end
    end
    -- Fallback: look up by name (works on initial hook before first UNIT_AURA).
    if spellName then
        if unitToken == "player" then
            return C_UnitAuras.GetAuraDataBySpellName(unitToken, spellName, "HELPFUL")
        else
            return C_UnitAuras.GetAuraDataBySpellName(unitToken, spellName, "HARMFUL")
        end
    end
    return nil
end


local function GetChildAuraDuration(child, unitToken)
    if child.auraInstanceID then
        local ok, ad = pcall(C_UnitAuras.GetAuraDuration,
                             unitToken, child.auraInstanceID)
        if ok and ad then return ad end
    end
    
    return nil
end

-- ============================================================
-- Viewer child hook (active-state driver)
-- ============================================================

-- Hooks OnHide and two UNIT_AURA frames (player + target) on a
-- BuffIconCooldownViewer child to drive shmIcon visibility, stacks,
-- and cooldown sweep.
--
-- Two separate RegisterUnitEvent calls are required — passing multiple
-- unit tokens to a single RegisterUnitEvent is not supported.
--
-- UpdateFromChild is called on every UNIT_AURA (player or target) and
-- on initial load so stacks and cooldown are always current.
local function HookViewerChild(spellID, child)
    local spellIDStr = tostring(spellID)
    -- Guard: only hook each (spellID, child) pair once.
    if hookedChildren[spellIDStr] == child then return end
    hookedChildren[spellIDStr] = child

    local hookSpecID = currentSpecID          -- capture spec at hook time
    local activeFlag = MakeActiveFlag(hookSpecID, spellID)
    local key        = MakeKey(spellID)
    -- Resolve spell name once for the GetAuraDataBySpellName fallback.
    local ok2, spellInfo2 = pcall(C_Spell.GetSpellInfo, spellID)
    local spellName = (ok2 and spellInfo2) and spellInfo2.name or nil
    
    

    local function UpdateFromChild(unitToken)
        -- Discard events that arrive after a spec change has replaced this hook.
        if currentSpecID ~= hookSpecID then return end

        -- C_UnitAuras lookup via child.auraInstanceID (DebugTracker Test SpellCD pattern).
        -- Returns plain Lua values — no secret values, no taint in combat.
        local auraData = GetChildAuraData(child, spellName, unitToken)
        local auraDuration = GetChildAuraDuration(child, unitToken)
        
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
        -- Stacks: plain number from aura data.
        pcall(shmIcons.SetStacks, shmIcons, ADDON_NAME, key, auraData.applications or 0)
        -- Cooldown: prefer durationObject (C DurationObject) when present, otherwise
        -- derive start time from plain expirationTime/duration numbers.
        if auraDuration then
            pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, auraDuration)
        else
            pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, nil)
        end
    end

    -- OnHide: buff fell off — clear immediately without waiting for UNIT_AURA.
    child:HookScript("OnHide", function()
        if currentSpecID ~= hookSpecID then return end
        _G[activeFlag] = false
        pcall(shmIcons.SetVisible,  shmIcons, ADDON_NAME, key, false)
        pcall(shmIcons.SetGlow,     shmIcons, ADDON_NAME, key, false)
        pcall(shmIcons.SetStacks,   shmIcons, ADDON_NAME, key, 0)
        pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, nil)
    end)

    -- Player aura frame: drives buff updates on player-sourced auras.
    local playerFrame = CreateFrame("Frame")
    playerFrame:RegisterUnitEvent("UNIT_AURA", "player")
    playerFrame:SetScript("OnEvent", function()
        UpdateFromChild("player")
    end)

    -- Target aura frame: drives updates for debuffs tracked on the target.
    -- Must be a separate RegisterUnitEvent call — multi-unit registration
    -- in one call is not supported.
    local targetFrame = CreateFrame("Frame")
    targetFrame:RegisterUnitEvent("UNIT_AURA", "target")
    targetFrame:SetScript("OnEvent", function()
        UpdateFromChild("target")
    end)

    -- Sync immediately on hook so initial shown/hidden state is correct.
    UpdateFromChild("player")
end

-- ============================================================
-- Viewer child scanning
-- ============================================================

-- Texture IDs to ignore (placeholder icons always present in the viewer).
local IGNORED_TEX_IDS = {
    [4554359] = true,
    [6739577] = true,
}

-- Returns the primary non-secret texture file-ID from a viewer child, or nil.
local function GetChildTexID(child)
    for j = 1, select("#", child:GetRegions()) do
        local r = select(j, child:GetRegions())
        if r:GetObjectType() == "Texture" then
            local ok, tid = pcall(r.GetTexture, r)
            if ok and type(tid) == "number" and not issecretvalue(tid) then
                return tid
            end
        end
    end
    for j = 1, child:GetNumChildren() do
        local gc = select(j, child:GetChildren())
        for k = 1, select("#", gc:GetRegions()) do
            local r = select(k, gc:GetRegions())
            if r:GetObjectType() == "Texture" then
                local ok, tid = pcall(r.GetTexture, r)
                if ok and type(tid) == "number" and not issecretvalue(tid) then
                    return tid
                end
            end
        end
    end
    return nil
end

-- Returns [texID -> child] for all viewer children with a plain texture ID.
local function GetViewerChildren(viewer)
    local result = {}
    for i = 1, viewer:GetNumChildren() do
        local child = select(i, viewer:GetChildren())
        if child then
            local texID = GetChildTexID(child)
            if texID and not IGNORED_TEX_IDS[texID] then
                result[texID] = child
            end
        end
    end
    return result
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
    shmIcons:SetIcon(ADDON_NAME, key, db.iconID)
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

local function ScanAndSync()
    if InCombatLockdown() then return end

    local viewer = _G["BuffIconCooldownViewer"]
    if not viewer then return end

    local specID = currentSpecID
    if specID == 0 then return end

    local buffDB = GetSpecBuffDB(specID)

    -- Build iconID -> spellID map from the talent tree.
    local _, iconMap = ScanTalentTree()

    -- Map each viewer child's plain texture ID to its talent spell.
    local viewerKids   = GetViewerChildren(viewer)
    local viewerSpells = {}
    for texID in pairs(viewerKids) do
        local spellID = iconMap[texID]
        if spellID then
            viewerSpells[spellID] = texID
        end
    end

    for spellID, texID in pairs(viewerSpells) do
        local spellIDStr = tostring(spellID)
        local child      = viewerKids[texID]

        -- Create DB entry and register icon for newly-discovered spells.
        if not trackedSpells[spellIDStr] then
            local entry = buffDB[spellIDStr]
            if not entry then
                local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                local spellName = (ok and spellInfo and spellInfo.name) or ("Spell " .. spellIDStr)
                local count = 0
                for _ in pairs(buffDB) do count = count + 1 end
                local col  = count % 5
                local row  = math.floor(count / 5)
                local xOff = (col - 2) * (DEFAULT_SIZE + 4)
                local yOff = row > 0 and (-row * (DEFAULT_SIZE + 4)) or 0

                entry = {
                    spellID      = spellID,
                    spellName    = spellName,
                    iconID       = texID,
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
            RegisterIcon(spellID, entry)
            trackedSpells[spellIDStr] = spellID
            RegisterSBASEntry(specID, spellID, entry.label)
        end

        -- Hook viewer child for ALL tracked spells (new and existing).
        -- HookViewerChild guards against re-hooking the same child.
        if child then
            HookViewerChild(spellID, child)
        end
    end
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
    ScanOrRetry()
end

-- ============================================================
-- Periodic check (re-scan if viewer contents change)
-- ============================================================

local pollFrame   = CreateFrame("Frame")
local pollElapsed = 0

pollFrame:SetScript("OnUpdate", function(_, elapsed)
    if InCombatLockdown() then return end
    pollElapsed = pollElapsed + elapsed
    if pollElapsed < SCAN_INTERVAL then return end
    pollElapsed = 0
    ScanAndSync()
end)

pollFrame:Show()

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

    elseif event == "PLAYER_ENTERING_WORLD" then
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

    elseif event == "PLAYER_REGEN_ENABLED" then
        ScanAndSync()
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

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
            print(string.format(
                "  |cFFFFFF00%s|r (spell:%s, pluginID:%s) %s",
                entry.label, spellIDStr,
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

                local icon = r:CreateTexture(nil, "ARTWORK")
                icon:SetSize(20, 20)
                icon:SetPoint("LEFT", r, "LEFT", 0, 0)
                icon:SetTexture(entry.iconID)

                local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                local spellID = tonumber(spellIDStr)
                lbl:SetText(entry.label
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

                r:Show()
                rows[spellIDStr] = r
            end

            listContainer:SetHeight(math.max(4, rowCount * 24))
        end

        RebuildList()

        if parent.SetScript then
            parent:HookScript("OnShow", RebuildList)
        end
    end

    CombatCoach.Menu:RegisterAddon({
        id        = "DynamicBuffTracker",
        name      = "Dynamic Buff Tracker",
        desc      = "Discovers selected talents and creates shmIcons / SBAS conditions for each one.",
        OnBuildUI = OnBuildUI,
    })
end