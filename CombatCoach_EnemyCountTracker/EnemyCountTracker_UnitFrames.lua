-- EnemyCountTracker_UnitFrames.lua
-- Draws a plain coloured box per tracked nameplate token.
-- The whole group moves together via an invisible anchor frame.
-- No UnitHealth / UnitName calls; taint-safe.

local FRAME_W   = 36
local FRAME_H   = 36
local FRAME_GAP = 4

-- ---------------------------------------------------------------------------
-- Anchor (drag handle for the whole group)
-- ---------------------------------------------------------------------------

local anchor = CreateFrame("Frame", "ECT_UnitFramesAnchor", UIParent, "BackdropTemplate")
anchor:SetSize(FRAME_W, FRAME_H)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
anchor:SetFrameStrata("MEDIUM")
anchor:SetMovable(true)
anchor:EnableMouse(true)
anchor:RegisterForDrag("LeftButton")
anchor:SetClampedToScreen(true)
anchor:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
})
anchor:SetBackdropColor(0.2, 0.6, 1, 0.5)
anchor:SetBackdropBorderColor(0.4, 0.8, 1, 1)

local anchorLabel = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
anchorLabel:SetAllPoints()
anchorLabel:SetText("ECT")
anchorLabel:SetTextColor(1, 1, 1, 1)

anchor:SetScript("OnDragStart", anchor.StartMoving)
anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Persist position
    local point, _, _, x, y = self:GetPoint()
    EnemyCountTrackerDB.ufPoint = point
    EnemyCountTrackerDB.ufX     = x
    EnemyCountTrackerDB.ufY     = y
end)

anchor:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("ECT Unit Frames\nDrag to move\nRight-click to toggle", 1, 1, 1, 1, true)
    GameTooltip:Show()
end)
anchor:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ---------------------------------------------------------------------------
-- Frame pool
-- ---------------------------------------------------------------------------

local pool      = {}
local active    = {}   -- [unit] = frame
local unitOrder = {}
local frameCount = 0

local framesHidden = false

anchor:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        framesHidden = not framesHidden
        for _, f in pairs(active) do
            if framesHidden then f:Hide() else f:Show() end
        end
        anchor:SetBackdropColor(framesHidden and 0.4 or 0.2, framesHidden and 0.1 or 0.6, framesHidden and 0.1 or 1, 0.5)
    end
end)

local function NewFrame(idx)
    local f = CreateFrame("Frame", "ECT_UnitFrame" .. idx, anchor, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    f:SetBackdropColor(0.6, 0.1, 0.1, 0.85)
    f:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
    f:Hide()
    return f
end

local function AcquireFrame()
    local f = table.remove(pool)
    if not f then
        frameCount = frameCount + 1
        f = NewFrame(frameCount)
    end
    return f
end

local function ReleaseFrame(f)
    f:Hide()
    f.unit = nil
    table.insert(pool, f)
end

-- ---------------------------------------------------------------------------
-- Layout: stack boxes to the right of the anchor
-- ---------------------------------------------------------------------------

local function LayoutFrames()
    for i, unit in ipairs(unitOrder) do
        local f = active[unit]
        if f then
            f:ClearAllPoints()
            f:SetPoint("LEFT", anchor, "LEFT", (FRAME_W + FRAME_GAP) * i, 0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Sync: called whenever ECT's tracked set changes
-- ---------------------------------------------------------------------------

function ECT_UnitFrames_Sync(trackedSet)
    for unit, f in pairs(active) do
        if not trackedSet[unit] then
            active[unit] = nil
            ReleaseFrame(f)
        end
    end

    for unit in pairs(trackedSet) do
        if not active[unit] then
            local f = AcquireFrame()
            f.unit = unit
            if not framesHidden then f:Show() end
            active[unit] = f
        end
    end

    wipe(unitOrder)
    for unit in pairs(active) do
        unitOrder[#unitOrder + 1] = unit
    end
    table.sort(unitOrder)

    LayoutFrames()
end

-- ---------------------------------------------------------------------------
-- Hook EnemyCountTracker_UpdateDebugDisplay to piggyback our sync.
-- Rebuilds a mirror set from visible nameplate tokens.
-- Swap to EnemyCountTracker_GetTrackedSet() if you expose that from ECT.
-- ---------------------------------------------------------------------------

local mirrorSet = {}

local _origUpdate = EnemyCountTracker_UpdateDebugDisplay
function EnemyCountTracker_UpdateDebugDisplay()
    _origUpdate()
    ECT_UnitFrames_Sync(_G.ECT_TrackedUnits or mirrorSet)
end

-- ---------------------------------------------------------------------------
-- Restore saved anchor position on load
-- ---------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= "CombatCoach_EnemyCountTracker" then return end
    local db = EnemyCountTrackerDB
    if db and db.ufPoint then
        anchor:ClearAllPoints()
        anchor:SetPoint(db.ufPoint, UIParent, db.ufPoint, db.ufX or 0, db.ufY or 0)
    end
end)