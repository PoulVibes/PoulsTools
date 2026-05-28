-- DynamicBuffTracker_Icons.lua
-- shmIcons registration and SBAS condition-registry helpers.

local DBT = DynamicBuffTracker

function DynamicBuffTracker_RegisterIcon(spellID, db)
    local key      = DynamicBuffTracker_MakeKey(spellID)
    local ADDON    = DBT.ADDON_NAME
    local DEF_SIZE = DBT.DEFAULT_SIZE
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then spellInfo = C_Spell.GetSpellInfo(spellInfo.name) end
    if not spellInfo then spellInfo = C_Spell.GetSpellInfo(spellID) end
    db.spellName = spellInfo and spellInfo.name or ("Unknown Spell " .. tostring(spellID))
    shmIcons:Register(ADDON, key, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function() end,
    })
    shmIcons:SetCooldownReverse(ADDON, key, true)
    shmIcons:SetHideCooldownText(ADDON, key, db.hide_cooldown_text or false)
    local resolvedIcon = db.override_icon or (spellInfo and spellInfo.iconID)
    DBT.spellIconCache = DBT.spellIconCache or {}
    DBT.spellIconCache[spellID] = resolvedIcon
    shmIcons:SetIcon(ADDON, key, resolvedIcon)
    shmIcons:SetVisible(ADDON, key, false)
    shmIcons:SetGlow(ADDON, key, false)
    if shmIcons and shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end
end

function DynamicBuffTracker_UnregisterIcon(spellID)
    pcall(function()
        shmIcons:Unregister(DBT.ADDON_NAME, DynamicBuffTracker_MakeKey(spellID))
    end)
    if shmIcons and shmIcons.MarkCombatCoachListDirty then
        shmIcons.MarkCombatCoachListDirty()
    end
end

-- Starts a visible-duration timer for a tracked buff. Updates a global
-- variable named: DynBuff_<specID>_<spellID>_Remaining (seconds remaining).
function DynamicBuffTracker_StartBuffTimer(specID, spellID, duration)
    if not duration or tonumber(duration) <= 0 then return end
    local spellIDStr = tostring(spellID)
    -- cancel existing
    DynamicBuffTracker_StopBuffTimer(specID, spellID, "restart")
    local timerVar = "DynBuff_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
    _G[timerVar] = tonumber(duration)
    local endTime = GetTime() + tonumber(duration)
    local ticker
    ticker = C_Timer.NewTicker(0.25, function()
        local rem = endTime - GetTime()
        if rem <= 0 then
            _G[timerVar] = 0
            if DBT.buffTimerHandles then DBT.buffTimerHandles[spellIDStr] = nil end
            pcall(function() ticker:Cancel() end)
            return
        end
        _G[timerVar] = rem
    end)
    DBT.buffTimerHandles = DBT.buffTimerHandles or {}
    DBT.buffTimerHandles[spellIDStr] = { ticker = ticker, endTime = endTime, timerVar = timerVar, specID = specID }
    DBT.buffTimerStart = DBT.buffTimerStart or {}
    DBT.buffTimerStart[spellIDStr] = GetTime()
end

function DynamicBuffTracker_StopBuffTimer(specID, spellID, reason)
    local spellIDStr = tostring(spellID)
    if DBT.buffTimerHandles and DBT.buffTimerHandles[spellIDStr] then
        local h = DBT.buffTimerHandles[spellIDStr]
        if h.ticker then pcall(function() h.ticker:Cancel() end) end
        DBT.buffTimerHandles[spellIDStr] = nil
    end
    local timerVar = "DynBuff_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
    _G[timerVar] = nil
    if DBT.buffTimerStart then DBT.buffTimerStart[spellIDStr] = nil end
end

function DynamicBuffTracker_RegisterSBASEntry(specID, spellID, label)
    _G.SBAS_DynBuffRegistry = _G.SBAS_DynBuffRegistry or {}
    local pid = DynamicBuffTracker_MakePluginID(specID, spellID)
    -- Determine whether a condition-timer exists (saved value or defaults)
    local buffDB = DynamicBuffTracker_GetSpecBuffDB(specID)
    local entry = buffDB and buffDB[tostring(spellID)]
    local timerVal = nil
    if entry and entry.buff_timer and tonumber(entry.buff_timer) then
        timerVal = tonumber(entry.buff_timer)
    elseif DynamicBuffTracker_Defaults and DynamicBuffTracker_Defaults[spellID] and DynamicBuffTracker_Defaults[spellID].timer then
        timerVal = tonumber(DynamicBuffTracker_Defaults[spellID].timer)
    end
    local timerVar = nil
    if timerVal and timerVal > 0 then
        timerVar = "DynBuff_" .. tostring(specID) .. "_" .. tostring(spellID) .. "_Remaining"
        _G[timerVar] = nil
    end
    _G.SBAS_DynBuffRegistry[pid] = {
        label      = label,
        activeFlag = DynamicBuffTracker_MakeActiveFlag(specID, spellID),
        specID     = specID,
        timerVar   = timerVar,
    }
end

function DynamicBuffTracker_UnregisterSBASEntry(specID, spellID)
    if not _G.SBAS_DynBuffRegistry then return end
    local pid = DynamicBuffTracker_MakePluginID(specID, spellID)
    local reg = _G.SBAS_DynBuffRegistry[pid]
    if reg then
        if reg.timerVar then
            _G[reg.timerVar] = nil
            DynamicBuffTracker_StopBuffTimer(specID, spellID, "unregister")
        end
        _G.SBAS_DynBuffRegistry[pid] = nil
    end
end

function DynamicBuffTracker_ClearSBASEntriesForSpec(specID)
    if not _G.SBAS_DynBuffRegistry then return end
    for pid, entry in pairs(_G.SBAS_DynBuffRegistry) do
        if entry.specID == specID then
            if entry.timerVar then
                _G[entry.timerVar] = nil
                -- pid format: dynbuff_<specID>_<spellID>
                local s_spec, s_spell = pid:match("^dynbuff_(%d+)_(%d+)$")
                if s_spec and tonumber(s_spec) == specID and tonumber(s_spell) then
                    DynamicBuffTracker_StopBuffTimer(specID, tonumber(s_spell), "clear_spec")
                end
            end
            _G.SBAS_DynBuffRegistry[pid] = nil
        end
    end
end
