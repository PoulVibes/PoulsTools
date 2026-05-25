local DAT = DynamicActivationTracker

local function SpellKey(spellID)
    return tostring(spellID or 0)
end

local function TimerKey(specID, spellID)
    return tostring(specID) .. ":" .. tostring(spellID)
end

local function RefreshTimerCooldownVisual(specID, spellID, handle)
    local key = SpellKey(spellID)
    if not DAT.runtimeIcons[key] then return end
    if not handle then
        shmIcons:SetCooldownRaw(DAT.ADDON_NAME, key, nil, nil)
        return
    end
    shmIcons:SetCooldownRaw(DAT.ADDON_NAME, key, handle.startTime, handle.duration)
end

local function GetSpellInfoData(spellID)
    if not C_Spell or not C_Spell.GetSpellInfo then return nil end
    local ok, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
    if ok then return spellInfo end
    return nil
end

local function StopConditionTimer(specID, spellID)
    local key = TimerKey(specID, spellID)
    local handle = DAT.conditionTimers[key]
    RefreshTimerCooldownVisual(specID, spellID, nil)
    if handle and handle.ticker then
        pcall(function() handle.ticker:Cancel() end)
    end
    DAT.conditionTimers[key] = nil
    local timerVar = "DynAct_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
    _G[timerVar] = nil
end

local function StartConditionTimer(specID, spellID, duration)
    duration = tonumber(duration)
    if not duration or duration <= 0 then return end

    StopConditionTimer(specID, spellID)

    local timerVar = "DynAct_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
    _G[timerVar] = duration
    local startTime = GetTime()
    local endTime = GetTime() + duration
    local key = TimerKey(specID, spellID)
    local ticker
    DAT.conditionTimers[key] = {
        ticker = nil,
        endTime = endTime,
        timerVar = timerVar,
        specID = specID,
        spellID = spellID,
        startTime = startTime,
        duration = duration,
    }
    RefreshTimerCooldownVisual(specID, spellID, DAT.conditionTimers[key])

    ticker = C_Timer.NewTicker(0.25, function()
        local rem = endTime - GetTime()
        if rem <= 0 then
            _G[timerVar] = 0
            StopConditionTimer(specID, spellID)
            return
        end
        _G[timerVar] = rem
        local liveHandle = DAT.conditionTimers[key]
        if liveHandle then
            RefreshTimerCooldownVisual(specID, spellID, liveHandle)
        end
    end)
    if DAT.conditionTimers[key] then
        DAT.conditionTimers[key].ticker = ticker
    end
end

local function RegisterIcon(specID, spellID, entry)
    local spellIDStr = SpellKey(spellID)

    local spellInfo = GetSpellInfoData(spellID)
    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)
    local iconObj = DAT.runtimeIcons[spellIDStr]
    if not iconObj then
        iconObj = shmIcons:Register(DAT.ADDON_NAME, spellIDStr, entry, {
            onResize = function(size)
                entry.size = size
            end,
            onMove = function()
            end,
        })
        DAT.runtimeIcons[spellIDStr] = iconObj
        if shmIcons and shmIcons.MarkCombatCoachListDirty then
            shmIcons.MarkCombatCoachListDirty()
        end
    end

    local displayIcon = entry.override_icon
        or (defaultOverride and defaultOverride.icon)
        or entry.iconID
        or (spellInfo and spellInfo.iconID)
        or 134400
    local displayName = DynamicActivationTracker_GetDisplayName(specID, spellID, entry)
    if shmIcons.SetDisplayName then
        pcall(shmIcons.SetDisplayName, shmIcons, DAT.ADDON_NAME, spellIDStr, displayName)
    end
    entry.spellName = displayName
    entry.label = displayName
    shmIcons:SetIcon(DAT.ADDON_NAME, spellIDStr, displayIcon)
    if shmIcons and shmIcons.SetEnabled then
        pcall(shmIcons.SetEnabled, shmIcons, DAT.ADDON_NAME, spellIDStr, entry.enabled == true)
    end
    if entry.enabled == false then
        shmIcons:SetGlow(DAT.ADDON_NAME, spellIDStr, false)
        shmIcons:SetVisible(DAT.ADDON_NAME, spellIDStr, false)
    end
    return iconObj
end

function DynamicActivationTracker_RefreshEntry(specID, spellID)
    if DynamicActivationTracker_IsIgnored(specID, spellID) then return end
    local entry = DynamicActivationTracker_GetOrCreateEntry(specID, spellID)
    if not entry then return end
    RegisterIcon(specID, spellID, entry)
    DynamicActivationTracker_RegisterSBASEntry(specID, spellID)
end

function DynamicActivationTracker_RemoveTrackedSpell(specID, spellID, ignoreSpell)
    if not specID or specID == 0 or not spellID then return end

    local spellIDStr = SpellKey(spellID)
    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    if not specDB then return end

    local entry = specDB.icons[spellIDStr]
    if ignoreSpell and entry then
        DynamicActivationTracker_EnsureIgnoredEntry(specID, spellID, entry)
    end

    specDB.icons[spellIDStr] = nil
    DynamicActivationTracker_ClearSBASEntriesForSpec(specID)
    if DAT.runtimeIcons[spellIDStr] then
        pcall(shmIcons.SetGlow, shmIcons, DAT.ADDON_NAME, spellIDStr, false)
        pcall(shmIcons.SetVisible, shmIcons, DAT.ADDON_NAME, spellIDStr, false)
        pcall(shmIcons.Unregister, shmIcons, DAT.ADDON_NAME, spellIDStr)
        DAT.runtimeIcons[spellIDStr] = nil
    end
    DAT.iconShown[spellIDStr] = nil
    StopConditionTimer(specID, spellID)
    _G[DynamicActivationTracker_MakeActiveFlag(specID, spellID)] = false
    if shmIcons and shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end

    for sid in pairs(specDB.icons) do
        local numSID = tonumber(sid)
        if numSID then
            DynamicActivationTracker_RegisterSBASEntry(specID, numSID)
        end
    end
end

function DynamicActivationTracker_UnloadSpec()
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then return end

    DynamicActivationTracker_ClearSBASEntriesForSpec(specID)
    for key, iconObj in pairs(DAT.runtimeIcons) do
        if iconObj then
            pcall(shmIcons.SetGlow, shmIcons, DAT.ADDON_NAME, key, false)
            pcall(shmIcons.SetVisible, shmIcons, DAT.ADDON_NAME, key, false)
            pcall(shmIcons.Unregister, shmIcons, DAT.ADDON_NAME, key)
        end
        DAT.runtimeIcons[key] = nil
        DAT.iconShown[key] = nil
        StopConditionTimer(specID, tonumber(key))
        _G[DynamicActivationTracker_MakeActiveFlag(specID, tonumber(key))] = false
    end
end

function DynamicActivationTracker_LoadSpec(specID)
    DynamicActivationTracker_UnloadSpec()
    DAT.currentSpecID = specID or 0
    if DAT.currentSpecID == 0 then return end

    DynamicActivationTracker_MigrateLegacyDB(DAT.currentSpecID)

    local specDB = DynamicActivationTracker_GetSpecDB(DAT.currentSpecID)
    if not specDB then return end

    for spellIDStr, entry in pairs(specDB.icons) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            DynamicActivationTracker_RefreshEntry(DAT.currentSpecID, spellID)
            if entry.enabled == false then
                shmIcons:SetVisible(DAT.ADDON_NAME, spellIDStr, false)
                shmIcons:SetGlow(DAT.ADDON_NAME, spellIDStr, false)
            end
        end
    end

    DynamicActivationTracker_ReevaluateVisibility()

    if shmIcons and shmIcons.RestoreSnapGroups then
        shmIcons:RestoreSnapGroups()
    end
end

function DynamicActivationTracker_ShowActivation(spellID)
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then return end
    if DynamicActivationTracker_IsIgnored(specID, spellID) then return end

    local key = SpellKey(spellID)
    local wasTracked = DAT.runtimeIcons[key] ~= nil

    local entry = DynamicActivationTracker_GetOrCreateEntry(specID, spellID)
    if not entry then return end

    -- Always register newly discovered DAT entries so the CombatCoach main
    -- shmIcons list updates immediately without requiring reload.
    DynamicActivationTracker_RefreshEntry(specID, spellID)
    if not wasTracked then
        DynamicActivationTracker_RefreshCurrentSpecList()
    end

    if entry.enabled == false then return end
    local defaultOverride = DynamicActivationTracker_GetDefaultOverride(specID, spellID)

    _G[DynamicActivationTracker_MakeActiveFlag(specID, spellID)] = true
    DAT.iconShown[key] = true
    shmIcons:SetVisible(DAT.ADDON_NAME, key, true)
    shmIcons:SetGlow(DAT.ADDON_NAME, key, entry.glow_enabled ~= false)
    local timerValue = entry.condition_timer
    if timerValue == nil and defaultOverride then
        timerValue = defaultOverride.timer
    end
    if timerValue then
        StartConditionTimer(specID, spellID, timerValue)
    end
end

function DynamicActivationTracker_HideActivation(spellID)
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then return end

    local key = SpellKey(spellID)
    if not DAT.runtimeIcons[key] then return end

    _G[DynamicActivationTracker_MakeActiveFlag(specID, spellID)] = false
    DAT.iconShown[key] = nil
    shmIcons:SetGlow(DAT.ADDON_NAME, key, false)
    shmIcons:SetVisible(DAT.ADDON_NAME, key, false)
    StopConditionTimer(specID, spellID)
end

function DynamicActivationTracker_ClearCurrentSpec()
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then return end
    DynamicActivationTracker_UnloadSpec()
    DynamicActivationTracker_ClearSpecDB(specID)
end

function DynamicActivationTracker_ListCurrentSpecIcons()
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then
        print("DynamicActivationTracker: no spec active.")
        return
    end

    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    local count = 0
    for spellIDStr, entry in pairs(specDB.icons) do
        count = count + 1
        local spellID = tonumber(spellIDStr)
        print(string.format(
            "  %s (spellID=%s, override=%s, timer=%s, %s)",
            spellID and DynamicActivationTracker_GetDisplayName(specID, spellID, entry) or (entry.label or entry.spellName or spellIDStr),
            spellIDStr,
            tostring(entry.override_icon or "-"),
            tostring(entry.condition_timer or "-"),
            entry.enabled == false and "hidden" or "shown"))
    end
    if count == 0 then
        print("DynamicActivationTracker: no saved icons for this spec.")
    end
end

function DynamicActivationTracker_RefreshCurrentSpecList()
    if DAT.rebuildCombatCoachList then
        DAT.rebuildCombatCoachList()
    end
end

function DynamicActivationTracker_ReevaluateVisibility()
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then return end

    local specDB = DynamicActivationTracker_GetSpecDB(specID)
    if not specDB or not specDB.icons then return end

    for spellIDStr, entry in pairs(specDB.icons) do
        local spellID = tonumber(spellIDStr)
        if spellID then
            if entry.enabled == false then
                shmIcons:SetVisible(DAT.ADDON_NAME, spellIDStr, false)
                shmIcons:SetGlow(DAT.ADDON_NAME, spellIDStr, false)
                StopConditionTimer(specID, spellID)
                _G[DynamicActivationTracker_MakeActiveFlag(specID, spellID)] = false
                DAT.iconShown[spellIDStr] = nil
            else
                DynamicActivationTracker_RefreshEntry(specID, spellID)
                local activeFlag = DynamicActivationTracker_MakeActiveFlag(specID, spellID)
                local isActive = (_G[activeFlag] == true)
                shmIcons:SetVisible(DAT.ADDON_NAME, spellIDStr, isActive)
                shmIcons:SetGlow(DAT.ADDON_NAME, spellIDStr, isActive and (entry.glow_enabled ~= false))
                if not isActive then
                    StopConditionTimer(specID, spellID)
                end
            end
        end
    end
end

function DynamicActivationTracker_RefreshAllTimerCooldowns()
    for _, handle in pairs(DAT.conditionTimers) do
        if handle and handle.specID == DAT.currentSpecID and handle.spellID then
            local rem = handle.endTime - GetTime()
            if rem > 0 then
                RefreshTimerCooldownVisual(handle.specID, handle.spellID, handle)
            else
                StopConditionTimer(handle.specID, handle.spellID)
            end
        end
    end
end

function DynamicActivationTracker_ListCurrentSpecIgnored()
    local specID = DAT.currentSpecID
    if not specID or specID == 0 then
        print("DynamicActivationTracker: no spec active.")
        return
    end

    local removedDB = DynamicActivationTracker_GetSpecRemovedDB(specID)
    local count = 0
    for spellIDStr, entry in pairs(removedDB) do
        count = count + 1
        local label = nil
        if type(entry) == "table" then
            local spellID = tonumber(spellIDStr)
            label = entry.display_name
                or (spellID and DynamicActivationTracker_GetDisplayName(specID, spellID, entry))
                or entry.label
                or entry.spellName
        end
        print(string.format("  %s (spellID=%s, ignored)", label or spellIDStr, spellIDStr))
    end
    if count == 0 then
        print("DynamicActivationTracker: no ignored spells for this spec.")
    end
end