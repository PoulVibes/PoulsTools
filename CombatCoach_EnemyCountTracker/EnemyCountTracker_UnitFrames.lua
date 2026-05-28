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
-- Pre-create one frame per nameplate slot (1-40)
-- ---------------------------------------------------------------------------

local frames = {}
local framesHidden = false

anchor:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        framesHidden = not framesHidden
        local tracked = _G.ECT_TrackedUnits or {}
        for i = 1, 40 do
            local f = frames[i]
            if tracked["nameplate" .. i] then
                if framesHidden then f:Hide() else f:Show() end
            end
        end
        anchor:SetBackdropColor(framesHidden and 0.4 or 0.2, framesHidden and 0.1 or 0.6, framesHidden and 0.1 or 1, 0.5)
        anchorLabel:SetTextColor(framesHidden and 0.4 or 1, framesHidden and 0.4 or 1, framesHidden and 0.4 or 1, 1)
    end
end)

for i = 1, 40 do
    local f = CreateFrame("Frame", "ECT_UnitFrame" .. i, anchor, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    f:SetBackdropColor(0.6, 0.1, 0.1, 0.85)
    f:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
    f.unit = "nameplate" .. i
    f.npLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.npLabel:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.npLabel:SetText(tostring(i))
    f.npLabel:SetTextColor(1, 1, 1, 1)
    f:Hide()
    frames[i] = f
end

-- ---------------------------------------------------------------------------
-- Sync: show tracked frames in order, hide the rest
-- ---------------------------------------------------------------------------

function ECT_UnitFrames_Sync(trackedSet)
    local DBT = _G.DynamicBuffTracker
    local specID = DBT and DBT.currentSpecID or 0
    if specID == 0 or not DynamicBuffTracker_GetSpecEctOverlay or not DynamicBuffTracker_GetSpecEctOverlay(specID) then return end
    local col = 0
    for i = 1, 40 do
        local f = frames[i]
        if trackedSet["nameplate" .. i] then
            col = col + 1
            f:ClearAllPoints()
            f:SetPoint("LEFT", anchor, "LEFT", (FRAME_W + FRAME_GAP) * col, 0)
            if not framesHidden then f:Show() end
        else
            f:Hide()
        end
    end
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
-- Scale: called from DebuffOverlay on login / spec change
-- ---------------------------------------------------------------------------

function ECT_SetOverlayScale(scale)
    anchor:SetScale(scale or 1.0)
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