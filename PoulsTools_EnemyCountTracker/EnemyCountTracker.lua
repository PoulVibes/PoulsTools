local ADDON_NAME = "PoulsTools_EnemyCountTracker"

EnemyCountTrackerDB = EnemyCountTrackerDB or {}

local frame = CreateFrame("Frame")
local unitToGUID = {}
local guidCounts = {}
local enemyCount = 0
local initialized = false
local debugFrame = nil
local debugCountText = nil

local function EnsureDB()
    EnemyCountTrackerDB = EnemyCountTrackerDB or {}
    local db = EnemyCountTrackerDB
    if db.enabled == nil then db.enabled = true end
    if db.onlyInCombat == nil then db.onlyInCombat = true end
    if db.requireThreat == nil then db.requireThreat = false end
    if db.includePetThreat == nil then db.includePetThreat = true end
    if db.debugDisplayEnabled == nil then db.debugDisplayEnabled = false end
    if db.debugPoint == nil then db.debugPoint = "CENTER" end
    if db.debugX == nil then db.debugX = 0 end
    if db.debugY == nil then db.debugY = -220 end
    return db
end

local function ResetTables()
    wipe(unitToGUID)
    wipe(guidCounts)
    enemyCount = 0
end

local function Recount()
    local n = 0
    for _, count in pairs(guidCounts) do
        if count and count > 0 then
            n = n + 1
        end
    end
    enemyCount = n
end

local function UpdateDebugDisplay()
    if not debugFrame then return end
    if debugCountText then
        debugCountText:SetText(tostring(enemyCount))
    end
    if EnemyCountTrackerDB.debugDisplayEnabled then
        debugFrame:Show()
    else
        debugFrame:Hide()
    end
end

local function SaveDebugFramePosition()
    if not debugFrame then return end
    local point, _, _, x, y = debugFrame:GetPoint()
    EnemyCountTrackerDB.debugPoint = point or "CENTER"
    EnemyCountTrackerDB.debugX = x or 0
    EnemyCountTrackerDB.debugY = y or 0
end

local function CreateDebugFrame()
    if debugFrame then return end

    local db = EnemyCountTrackerDB
    debugFrame = CreateFrame("Frame", "EnemyCountTrackerDebugFrame", UIParent, "BackdropTemplate")
    debugFrame:SetSize(90, 44)
    debugFrame:SetPoint(db.debugPoint, UIParent, db.debugPoint, db.debugX, db.debugY)
    debugFrame:SetFrameStrata("MEDIUM")
    debugFrame:SetMovable(true)
    debugFrame:EnableMouse(true)
    debugFrame:RegisterForDrag("LeftButton")
    debugFrame:SetClampedToScreen(true)

    debugFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    debugFrame:SetBackdropColor(0, 0, 0, 0.75)

    debugFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    debugFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveDebugFramePosition()
    end)

    local label = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", debugFrame, "TOP", 0, -6)
    label:SetText("ECT")
    label:SetTextColor(0.85, 0.85, 0.95, 1)

    debugCountText = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    debugCountText:SetPoint("CENTER", debugFrame, "CENTER", 0, -2)
    debugCountText:SetTextColor(1, 0.82, 0.2, 1)
    debugCountText:SetText("0")

    debugFrame:Hide()
end

local function ShouldCountUnit(unit)
    if not unit or not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsFriend("player", unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end

    local db = EnemyCountTrackerDB
    if db.onlyInCombat and not UnitAffectingCombat("player") then
        return false
    end

    local hasThreat = UnitThreatSituation("player", unit) ~= nil
    if not hasThreat and db.includePetThreat and UnitExists("pet") then
        hasThreat = UnitThreatSituation("pet", unit) ~= nil
    end

    if hasThreat then
        return true
    end

    if db.requireThreat and not hasThreat then
        return false
    end

    -- Threat can be unavailable/late for some situations. Fall back to
    -- combat state + hostility so the debug display reflects live pulls.
    if UnitAffectingCombat(unit) then
        return true
    end

    if UnitIsUnit(unit, "target") and UnitCanAttack("player", "target") then
        return true
    end

    return false
end

local function AddGUID(guid)
    if not guid then return end
    local current = guidCounts[guid] or 0
    guidCounts[guid] = current + 1
    if current == 0 then
        enemyCount = enemyCount + 1
    end
end

local function RemoveGUID(guid)
    if not guid then return end
    local current = guidCounts[guid]
    if not current then return end

    if current <= 1 then
        guidCounts[guid] = nil
        if enemyCount > 0 then
            enemyCount = enemyCount - 1
        end
    else
        guidCounts[guid] = current - 1
    end
end

local function TrackUnit(unit)
    if not unit then return end
    local oldGUID = unitToGUID[unit]
    local newGUID = nil

    if ShouldCountUnit(unit) then
        newGUID = UnitGUID(unit)
    end

    if oldGUID and oldGUID ~= newGUID then
        RemoveGUID(oldGUID)
    end

    if newGUID and newGUID ~= oldGUID then
        AddGUID(newGUID)
    end

    unitToGUID[unit] = newGUID
end

local function ForEachVisibleNameplateUnit(cb)
    local plates = C_NamePlate.GetNamePlates(false)
    if not plates then return end

    for _, plateFrame in ipairs(plates) do
        local unit = plateFrame and plateFrame.namePlateUnitToken
        if unit then
            cb(unit)
        end
    end
end

local function RefreshAll()
    local seenUnits = {}

    ForEachVisibleNameplateUnit(function(unit)
        seenUnits[unit] = true
        TrackUnit(unit)
    end)

    for unit, guid in pairs(unitToGUID) do
        if not seenUnits[unit] then
            if guid then
                RemoveGUID(guid)
            end
            unitToGUID[unit] = nil
        end
    end

    Recount()
    UpdateDebugDisplay()
end

local function PrintCount()
    print(string.format("EnemyCountTracker: %d tracked enemy nameplate%s.", enemyCount, enemyCount == 1 and "" or "s"))
end

local function HandleSlash(msg)
    local cmd = (msg or ""):lower():trim()

    if cmd == "" then
        EnemyCountTrackerDB.debugDisplayEnabled = not EnemyCountTrackerDB.debugDisplayEnabled
        UpdateDebugDisplay()
        print("EnemyCountTracker: debug display " .. (EnemyCountTrackerDB.debugDisplayEnabled and "enabled." or "disabled."))
        return
    end

    if cmd == "count" then
        PrintCount()
        return
    end

    if cmd == "refresh" then
        RefreshAll()
        PrintCount()
        return
    end

    if cmd == "on" then
        EnemyCountTrackerDB.enabled = true
        RefreshAll()
        print("EnemyCountTracker: enabled.")
        return
    end

    if cmd == "off" then
        EnemyCountTrackerDB.enabled = false
        ResetTables()
        UpdateDebugDisplay()
        print("EnemyCountTracker: disabled.")
        return
    end

    print("Usage: /ect (toggle debug) | /ect [count|refresh|on|off]")
end

function EnemyCountTracker_GetCount()
    return enemyCount
end

function EnemyCountTracker_ForceRefresh()
    RefreshAll()
end

function EnemyCountTracker_SetEnabled(enabled)
    EnemyCountTrackerDB.enabled = not not enabled
    if EnemyCountTrackerDB.enabled then
        RefreshAll()
    else
        ResetTables()
        UpdateDebugDisplay()
    end
end

function EnemyCountTracker_SetOnlyInCombat(enabled)
    EnemyCountTrackerDB.onlyInCombat = not not enabled
    RefreshAll()
end

function EnemyCountTracker_SetRequireThreat(enabled)
    EnemyCountTrackerDB.requireThreat = not not enabled
    RefreshAll()
end

function EnemyCountTracker_SetIncludePetThreat(enabled)
    EnemyCountTrackerDB.includePetThreat = not not enabled
    RefreshAll()
end

function EnemyCountTracker_SetDebugDisplayEnabled(enabled)
    EnemyCountTrackerDB.debugDisplayEnabled = not not enabled
    UpdateDebugDisplay()
end

function EnemyCountTracker_IsDebugDisplayEnabled()
    return EnemyCountTrackerDB and EnemyCountTrackerDB.debugDisplayEnabled == true
end

SLASH_ENEMYCOUNTTRACKER1 = "/ect"
SlashCmdList["ENEMYCOUNTTRACKER"] = HandleSlash

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME then return end

        EnsureDB()
        CreateDebugFrame()
        initialized = true
        RefreshAll()
        return
    end

    if not initialized or not EnemyCountTrackerDB.enabled then
        if event == "PLAYER_REGEN_ENABLED" then
            ResetTables()
            UpdateDebugDisplay()
        end
        return
    end

    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        TrackUnit(unit)
        UpdateDebugDisplay()
        return
    end

    if event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        local guid = unitToGUID[unit]
        if guid then
            RemoveGUID(guid)
        end
        unitToGUID[unit] = nil
        UpdateDebugDisplay()
        return
    end

    if event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_FLAGS" then
        local unit = ...
        if unit and unit:match("^nameplate%d+$") then
            TrackUnit(unit)
            UpdateDebugDisplay()
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        RefreshAll()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        RefreshAll()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        RefreshAll()
        return
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
frame:RegisterEvent("UNIT_FLAGS")
