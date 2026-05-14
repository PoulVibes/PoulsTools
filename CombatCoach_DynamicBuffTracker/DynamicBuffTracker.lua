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

-- Looks up AuraData trying player (HELPFUL) then target (HARMFUL).
-- auraInstanceID is unit-scoped, so both units must be tried.
-- Returns auraData, unitToken (or nil, nil if not found).
local function GetChildAuraData(child, spellName)
    if child.auraInstanceID then
        local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                             "player", child.auraInstanceID)
        if ok and ad then return ad, "player" end
        ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,
                       "target", child.auraInstanceID)
        if ok and ad then return ad, "target" end
    end
    if spellName then
        local ad = C_UnitAuras.GetAuraDataBySpellName("player", spellName, "HELPFUL")
        if ad then return ad, "player" end
        ad = C_UnitAuras.GetAuraDataBySpellName("target", spellName, "HARMFUL")
        if ad then return ad, "target" end
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

-- Hooks OnHide/OnShow and two UNIT_AURA frames (player + target) on a
-- BuffIconCooldownViewer child to drive shmIcon visibility, stacks,
-- and cooldown sweep.
--
-- Before clearing on a nil aura lookup, the other unit is cross-checked so
-- a target UNIT_AURA event cannot falsely clear a player buff (and vice-versa).
local function HookViewerChild(spellID, child)
    local spellIDStr = tostring(spellID)
    -- Guard: only hook each (spellID, child) pair once.
    if hookedChildren[spellIDStr] == child then return end
    hookedChildren[spellIDStr] = child

    local hookSpecID = currentSpecID
    local activeFlag = MakeActiveFlag(hookSpecID, spellID)
    local key        = MakeKey(spellID)
    local ok2, spellInfo2 = pcall(C_Spell.GetSpellInfo, spellID)
    local spellName = (ok2 and spellInfo2) and spellInfo2.name or nil

    local function UpdateFromChild()
        if currentSpecID ~= hookSpecID then return end

        local auraData, unitFound = GetChildAuraData(child, spellName)
        --print("Updating", spellName, "found on unit:", unitFound or "none")
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
        if currentSpecID ~= hookSpecID then return end
        hideTimer = C_Timer.NewTimer(0.1, function()
            hideTimer = nil
            _G[activeFlag] = false
            pcall(shmIcons.SetVisible,  shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetGlow,     shmIcons, ADDON_NAME, key, false)
            pcall(shmIcons.SetStacks,   shmIcons, ADDON_NAME, key, 0)
            pcall(shmIcons.SetCooldown, shmIcons, ADDON_NAME, key, nil)
        end)
    end)
    child:HookScript("OnShow", function()
        if hideTimer then hideTimer:Cancel() hideTimer = nil end
        if currentSpecID ~= hookSpecID then return end
        UpdateFromChild()
    end)

    -- Register both units: BuffIconCooldownViewer tracks player buffs and target debuffs.
    -- UpdateFromChild checks both units itself so neither event causes a false clear.
    local playerFrame = CreateFrame("Frame")
    playerFrame:RegisterUnitEvent("UNIT_AURA", "player")
    playerFrame:SetScript("OnEvent", UpdateFromChild)

    local targetFrame = CreateFrame("Frame")
    targetFrame:RegisterUnitEvent("UNIT_AURA", "target")
    targetFrame:SetScript("OnEvent", UpdateFromChild)

    UpdateFromChild()
    -- Defer a second update so that aura duration / stack data is correct
    -- even when the icon is first discovered right at login, before the
    -- aura system has fully settled.
    C_Timer.After(1.0, function()
        if currentSpecID == hookSpecID then UpdateFromChild() end
    end)
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
-- Spell book scanning
-- ============================================================

-- Scans the player's spell book and returns an iconMap:
--   iconMap[iconID] = { spellID = ..., spellName = ... }
-- Used as the authoritative source for spell names before the talent tree.
local function ScanSpellBook()
    local iconMap = {}
    if not C_SpellBook then return iconMap end

    local numLines = C_SpellBook.GetNumSpellBookSkillLines
                     and C_SpellBook.GetNumSpellBookSkillLines() or 0
    for i = 1, numLines do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo
                         and C_SpellBook.GetSpellBookSkillLineInfo(i)
        if lineInfo and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
            for slot = lineInfo.itemIndexOffset + 1,
                       lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                local ok, itemInfo = pcall(C_SpellBook.GetSpellBookItemInfo,
                                           slot, Enum.SpellBookSpellBank.Player)
                if ok and itemInfo and itemInfo.spellID and itemInfo.spellID > 0 then
                    local ok2, spellInfo = pcall(C_Spell.GetSpellInfo, itemInfo.spellID)
                    if ok2 and spellInfo and spellInfo.name then
                        local entry = {
                            spellID   = itemInfo.spellID,
                            spellName = spellInfo.name,
                        }
                        -- Register icons from the spell itself.
                        if spellInfo.iconID and not iconMap[spellInfo.iconID] then
                            iconMap[spellInfo.iconID] = entry
                        end
                        if spellInfo.originalIconID
                           and spellInfo.originalIconID ~= spellInfo.iconID
                           and not iconMap[spellInfo.originalIconID] then
                            iconMap[spellInfo.originalIconID] = entry
                        end
                        -- Also register icons from the base spell, if different.
                        -- Use a separate entry so we can record displayIconID: the viewer
                        -- child will show the base spell's texture, but shmIcons should
                        -- display the override (spell book) spell's icon instead.
                        local baseID = C_Spell.GetBaseSpell and
                                       C_Spell.GetBaseSpell(itemInfo.spellID)
                        if baseID and baseID ~= itemInfo.spellID then
                            local ok3, baseInfo = pcall(C_Spell.GetSpellInfo, baseID)
                            if ok3 and baseInfo then
                                local baseEntry = {
                                    spellID       = itemInfo.spellID,
                                    spellName     = spellInfo.name,
                                    displayIconID = spellInfo.iconID,
                                }
                                if baseInfo.iconID and not iconMap[baseInfo.iconID] then
                                    iconMap[baseInfo.iconID] = baseEntry
                                end
                                if baseInfo.originalIconID
                                   and baseInfo.originalIconID ~= baseInfo.iconID
                                   and not iconMap[baseInfo.originalIconID] then
                                    iconMap[baseInfo.originalIconID] = baseEntry
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return iconMap
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

    -- Build iconID -> spell maps; spell book takes priority over talent tree.
    local sbIconMap        = ScanSpellBook()
    local _, talentIconMap = ScanTalentTree()

    -- Map each viewer child's plain texture ID to its spell.
    -- Spell book match wins over talent tree match for name resolution.
    local viewerKids   = GetViewerChildren(viewer)
    local viewerSpells = {}   -- [spellID] = { texID, spellName }
    for texID in pairs(viewerKids) do
        local sbEntry = sbIconMap[texID]
        if sbEntry then
            viewerSpells[sbEntry.spellID] = { texID = texID, spellName = sbEntry.spellName, displayIconID = sbEntry.displayIconID }
        else
            local spellID = talentIconMap[texID]
            if spellID then
                viewerSpells[spellID] = { texID = texID, spellName = nil }
            end
        end
    end

    for spellID, info in pairs(viewerSpells) do
        local spellIDStr = tostring(spellID)
        local child      = viewerKids[info.texID]

        -- Create DB entry and register icon for newly-discovered spells.
        if not trackedSpells[spellIDStr] then
            local entry = buffDB[spellIDStr]
            if not entry then
                local spellName = info.spellName
                if not spellName then
                    local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                    spellName = (ok and spellInfo and spellInfo.name) or ("Spell " .. spellIDStr)
                end
                local count = 0
                for _ in pairs(buffDB) do count = count + 1 end
                local col  = count % 5
                local row  = math.floor(count / 5)
                local xOff = (col - 2) * (DEFAULT_SIZE + 4)
                local yOff = row > 0 and (-row * (DEFAULT_SIZE + 4)) or 0

                entry = {
                    spellID      = spellID,
                    spellName    = spellName,
                    iconID       = info.displayIconID or info.texID,
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