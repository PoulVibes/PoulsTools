-- EnemyCountTracker_Debug.lua
-- Debug overlay frame for EnemyCountTracker.
-- Loaded after EnemyCountTracker.lua; reads the enemy count via the global
-- EnemyCountTracker_GetCount() so it has no dependency on local upvalues.

local debugFrame     = nil
local debugCountText = nil

local function SaveDebugFramePosition()
    if not debugFrame then return end
    local point, _, _, x, y = debugFrame:GetPoint()
    EnemyCountTrackerDB.debugPoint = point or "CENTER"
    EnemyCountTrackerDB.debugX = x or 0
    EnemyCountTrackerDB.debugY = y or 0
end

function EnemyCountTracker_UpdateDebugDisplay()
    if not debugFrame then return end
    if debugCountText then
        debugCountText:SetText(tostring(EnemyCountTracker_GetCount()))
    end
    if EnemyCountTrackerDB and EnemyCountTrackerDB.debugDisplayEnabled then
        debugFrame:Show()
    else
        debugFrame:Hide()
    end
end

function EnemyCountTracker_CreateDebugFrame()
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
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
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
