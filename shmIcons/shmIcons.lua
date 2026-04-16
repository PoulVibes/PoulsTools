-- ============================================================
-- shmIcons.lua  (WoW Midnight 12.0.1)
-- Shared icon / cooldown / glow / snap library.
--
-- Snap groups are persisted in shmIconsDB (account-wide) so icon
-- arrangements survive reloads and are shared across all addons.
--
-- Per-spec layout is the responsibility of each consumer addon —
-- they call Register/Unregister when the player changes spec, and
-- call RestoreSnapGroups() once all icons for the new spec are up.
-- ============================================================

if shmIcons then return end

shmIcons = {}

-- ============================================================
-- Constants
-- ============================================================

local FONT_RATIO     = 0.5
local FONT_PATH      = "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS     = "OUTLINE"
local FONT_MIN_PT    = 8
local MIN_SIZE       = 16
local MAX_SIZE       = 256
local SNAP_THRESHOLD = 20

-- Stack count text: pink
local STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B = 1.0, 0.4, 0.7

-- Range tint colors for SetVertexColorFromBoolean
local RANGE_COLOR_IN  = CreateColor(1.0, 1.0, 1.0, 1.0)
local RANGE_COLOR_OUT = CreateColor(1.0, 0.0, 0.0, 1.0)

-- Usability overlay colors for SetVertexColorFromBoolean
-- true  = usable   → fully transparent (no overlay)
-- false = unusable → semi-transparent gray
local USABLE_COLOR_YES = CreateColor(0.0, 0.0, 0.0, 0.0)
local USABLE_COLOR_NO  = CreateColor(0.4, 0.4, 0.4, 0.6)

local CORNER_COORDS = {
    { point = "TOPLEFT",     x = -1, y =  1 },
    { point = "TOPRIGHT",    x =  1, y =  1 },
    { point = "BOTTOMLEFT",  x = -1, y = -1 },
    { point = "BOTTOMRIGHT", x =  1, y = -1 },
}

-- ============================================================
-- Internal state
-- ============================================================

local icons          = {}  -- icons[globalID] = icon object
local snapNeighbours = {}  -- snapNeighbours[globalID] = { [otherGlobalID]=true }
local isLocked       = true

-- ============================================================
-- Snap DB helpers
-- ============================================================

-- Return the snap group storage table, creating it if needed.
local function GetSnapDB()
    shmIconsDB = shmIconsDB or {}
    shmIconsDB.snapGroups = shmIconsDB.snapGroups or {}
    return shmIconsDB.snapGroups
end

-- Persist the current in-memory snap graph to shmIconsDB.
local function SaveSnapGroups()
    local db = GetSnapDB()
    -- Wipe and reserialize the whole graph.
    for k in pairs(db) do db[k] = nil end
    for id, neighbours in pairs(snapNeighbours) do
        local list = {}
        for nb in pairs(neighbours) do
            table.insert(list, nb)
        end
        if #list > 0 then
            db[id] = list
        end
    end
end

-- ============================================================
-- Snap helpers
-- ============================================================

local function LinkSnap(a, b)
    snapNeighbours[a] = snapNeighbours[a] or {}
    snapNeighbours[b] = snapNeighbours[b] or {}
    snapNeighbours[a][b] = true
    snapNeighbours[b][a] = true
    SaveSnapGroups()
end

local function UnlinkSnap(id)
    if snapNeighbours[id] then
        for other in pairs(snapNeighbours[id]) do
            if snapNeighbours[other] then
                snapNeighbours[other][id] = nil
            end
        end
        snapNeighbours[id] = nil
        SaveSnapGroups()
    end
end

local function GetSnapGroup(startID)
    local group   = {}
    local visited = {}
    local queue   = { startID }
    while #queue > 0 do
        local id = table.remove(queue)
        if not visited[id] then
            visited[id] = true
            table.insert(group, id)
            if snapNeighbours[id] then
                for nb in pairs(snapNeighbours[id]) do
                    if not visited[nb] then
                        table.insert(queue, nb)
                    end
                end
            end
        end
    end
    return group
end

-- ============================================================
-- Internal UI helpers
-- ============================================================

local function ScaleText(cd, stackLabel, size)
    local pt = math.max(FONT_MIN_PT, math.floor(size * FONT_RATIO))
    for _, region in next, { cd:GetRegions() } do
        if region:GetObjectType() == "FontString" then
            region:SetFont(FONT_PATH, pt, FONT_FLAGS)
        end
    end
    if stackLabel then stackLabel:SetFont(FONT_PATH, pt, FONT_FLAGS) end
end

local function BuildGlow(frame, iconSize)
    local g = CreateFrame("Frame", nil, frame)
    g:SetAllPoints(frame)
    g:SetFrameLevel(frame:GetFrameLevel() + 6)
    g.textures = {}

    local off = iconSize * 0.1875
    for i, c in ipairs(CORNER_COORDS) do
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        t:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
        t:SetSize(iconSize * 1.4, iconSize * 1.4)
        t:SetPoint(c.point, frame, c.point, c.x * off, c.y * off)

        local ag = t:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(0.3)
        a:SetToAlpha(1.0)
        a:SetDuration(0.6)
        a:SetOrder(1)
        ag:Play()

        g.textures[i] = t
    end

    g:Hide()
    return g
end

local function ResizeGlow(glow, frame, iconSize)
    local off     = iconSize * 0.1875
    local texSize = iconSize * 1.4
    for i, c in ipairs(CORNER_COORDS) do
        local t = glow.textures[i]
        if t then
            t:SetSize(texSize, texSize)
            t:ClearAllPoints()
            t:SetPoint(c.point, frame, c.point, c.x * off, c.y * off)
        end
    end
end

local function SaveIconPos(icon)
    local point, _, _, x, y = icon.frame:GetPoint()
    icon.db.point = point
    icon.db.x     = x
    icon.db.y     = y
end

local function ApplyLockState(icon)
    local frame = icon.frame
    if isLocked then
        frame:EnableMouse(false)
        frame:SetBackdrop(nil)
        icon.resizeHandle:Hide()
    else
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton", "RightButton")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        frame:SetBackdropColor(0, 0, 0, 0.5)
		frame:Show()
        icon.resizeHandle:Show()
    end
end

-- ============================================================
-- Internal frame construction
-- ============================================================

local function BuildIconFrame(globalID, db)
    local frame = CreateFrame("Frame", "shmIconsFrame_" .. globalID, UIParent, "BackdropTemplate")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_SIZE, MIN_SIZE, MAX_SIZE, MAX_SIZE)
    frame:SetClampedToScreen(true)
    frame:SetSize(db.size, db.size)
    frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)

    local iconTex = frame:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints(frame)
    iconTex:SetTexture(134400)

    local cd = CreateFrame("Cooldown", "shmIconsCD_" .. globalID, frame, "CooldownFrameTemplate")
    cd:SetAllPoints(frame)
    cd:SetFrameLevel(frame:GetFrameLevel() + 2)
    cd:SetReverse(false)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(true)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(false)
    ScaleText(cd, nil, db.size)

    -- Second cooldown frame for charge recharge timers.
    -- DrawSwipe=false + DrawEdge=true shows only the clock hand — no dark
    -- overlay — signalling "a charge is available but one is recharging".
    -- This is the same two-frame technique used by TellMeWhen.
    local cd2 = CreateFrame("Cooldown", "shmIconsCD2_" .. globalID, frame, "CooldownFrameTemplate")
    cd2:SetAllPoints(frame)
    cd2:SetFrameLevel(frame:GetFrameLevel() + 3)  -- just above cd
    cd2:SetReverse(false)
    cd2:SetDrawSwipe(false)   -- no dark overlay — charge is still available
    cd2:SetDrawEdge(true)     -- show the clock hand to indicate recharging
    cd2:SetDrawBling(false)
    cd2:SetHideCountdownNumbers(true)  -- cd handles numbers; cd2 is visual only

    local stackLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stackLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO)), FONT_FLAGS)
    stackLabel:SetTextColor(STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B, 1)
    stackLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    stackLabel:SetJustifyH("RIGHT")
    -- Draw above the cooldown sweep (cd is at frameLevel+2, cd2 at +3)
    stackLabel:SetDrawLayer("OVERLAY", 7)
    stackLabel:Hide()

    local glow = BuildGlow(frame, db.size)

    -- Usability overlay: a solid black-ish texture that sits above the icon
    -- and cooldown sweep. Made transparent when usable, gray when not.
    -- Driven exclusively via SetVertexColorFromBoolean — never compared.
    local usableOverlay = frame:CreateTexture(nil, "OVERLAY")
    usableOverlay:SetAllPoints(frame)
    usableOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    usableOverlay:SetVertexColor(0, 0, 0, 0)  -- fully transparent by default

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 10)
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripTex:SetAllPoints(resizeHandle)
    resizeHandle:Hide()

    local icon = {
        globalID       = globalID,
        db             = db,
        frame          = frame,
        iconTex        = iconTex,
        cd             = cd,
        cd2            = cd2,
        stackLabel     = stackLabel,
        glow           = glow,
        usableOverlay  = usableOverlay,
        resizeHandle   = resizeHandle,
        glowEnabled    = db.glow_enabled,
        groupDragFrame = nil,
    }

    frame:SetScript("OnSizeChanged", function(self, width, height)
        local sq = math.max(MIN_SIZE, math.min(math.floor(width), MAX_SIZE))
        if math.abs(self:GetWidth() - sq) > 0.5 or math.abs(self:GetHeight() - sq) > 0.5 then
            self:SetSize(sq, sq)
            return
        end
        ScaleText(cd, stackLabel, sq)
        ResizeGlow(icon.glow, frame, sq)
        db.size = sq
        if icon.onResize then icon.onResize(sq) end
    end)

    -- dragState tracks everything about the current solo left-drag
    local dragState = nil

    -- Apply a snap candidate immediately (called live from OnUpdate)
    local function ApplySnap(candidate, isShift, isCtrl)
        if isCtrl then
            -- Corner-attach: 20% size, raised strata, corner-to-corner
            local cornerSize = math.max(MIN_SIZE, math.floor(candidate.targetSize * 0.2))
            frame:SetSize(cornerSize, cornerSize)
            ScaleText(cd, stackLabel, cornerSize)
            ResizeGlow(icon.glow, frame, cornerSize)
            frame:SetFrameStrata("HIGH")
        elseif isShift then
            -- Resize to match target
            local sz = candidate.targetSize
            frame:SetSize(sz, sz)
            ScaleText(cd, stackLabel, sz)
            ResizeGlow(icon.glow, frame, sz)
            frame:SetFrameStrata("MEDIUM")
        else
            -- Default: no resize
            frame:SetFrameStrata("MEDIUM")
        end
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
    end

    -- Revert any live snap changes made during dragging (size/strata)
    local function RevertSnap()
        if dragState and dragState.originalSize then
            local orig = dragState.originalSize
            frame:SetSize(orig, orig)
            ScaleText(cd, stackLabel, orig)
            ResizeGlow(icon.glow, frame, orig)
        end
        frame:SetFrameStrata("MEDIUM")
    end

    -- Find snap candidates by checking each axis independently.
    -- For each other icon we compute:
    --   - horizontal snaps: left/right edges flush, Y axis free
    --   - vertical snaps:   top/bottom edges flush, X axis free
    -- Then we combine the nearest X-axis snap and nearest Y-axis snap
    -- to allow corner multi-snapping when two icons are nearby on both axes.
    -- When shift is held and sizes match, prioritize diagonal corner-to-corner snaps.
    -- Returns a candidate table or nil.
    local function FindSnapCandidate(myCX, myCY, mySize, isShift, isCtrl)
        local uiCX, uiCY = UIParent:GetCenter()
        local myHalf = mySize * 0.5

        if isCtrl then
            -- Corner-attach mode: single nearest corner across all icons
            local bestDist = math.huge
            local best     = nil

            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown() then
                    local oH   = other.frame:GetHeight()
                    local oCX, oCY = other.frame:GetCenter()
                    local oHalf = oH * 0.5
                    local cornerSize = math.max(MIN_SIZE, math.floor(oH * 0.2))
                    local cHalf = cornerSize * 0.5

                    local corners = {
                        { cx = oCX + oHalf - cHalf, cy = oCY + oHalf - cHalf },
                        { cx = oCX - oHalf + cHalf, cy = oCY + oHalf - cHalf },
                        { cx = oCX + oHalf - cHalf, cy = oCY - oHalf + cHalf },
                        { cx = oCX - oHalf + cHalf, cy = oCY - oHalf + cHalf },
                    }
                    for _, c in ipairs(corners) do
                        local dist = math.sqrt((myCX - c.cx)^2 + (myCY - c.cy)^2)
                        if dist < SNAP_THRESHOLD and dist < bestDist then
                            bestDist = dist
                            best = {
                                cx         = c.cx - uiCX,
                                cy         = c.cy - uiCY,
                                targetID   = otherID,
                                targetSize = oH,
                            }
                        end
                    end
                end
            end
            return best
        end

        -- Check for diagonal corner-to-corner snaps when shift is held and sizes match
        if isShift then
            local bestDiagonalDist = math.huge
            local bestDiagonal = nil
            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown() and other.frame:GetHeight() == mySize then
                    local oCX, oCY = other.frame:GetCenter()
                    local oHalf = mySize * 0.5
                    -- 4 diagonal positions relative to the target icon
                    local diagonals = {
                        { cx = oCX + 2*oHalf, cy = oCY + 2*oHalf }, -- top-right
                        { cx = oCX - 2*oHalf, cy = oCY + 2*oHalf }, -- top-left
                        { cx = oCX + 2*oHalf, cy = oCY - 2*oHalf }, -- bottom-right
                        { cx = oCX - 2*oHalf, cy = oCY - 2*oHalf }, -- bottom-left
                    }
                    for _, d in ipairs(diagonals) do
                        local dist = math.sqrt((myCX - d.cx)^2 + (myCY - d.cy)^2)
                        if dist < SNAP_THRESHOLD and dist < bestDiagonalDist then
                            bestDiagonalDist = dist
                            bestDiagonal = {
                                cx         = d.cx - uiCX,
                                cy         = d.cy - uiCY,
                                targetID   = otherID,
                                snapIDs    = {otherID},
                                targetSize = mySize,
                            }
                        end
                    end
                end
            end
            if bestDiagonal then
                return bestDiagonal
            end
        end

        -- Normal / shift mode: independent axis snapping.
        -- For each icon find the closest flush edge on X and Y separately.
        local bestX, bestXDist, bestXTargetID = nil, math.huge, nil
        local bestY, bestYDist, bestYTargetID = nil, math.huge, nil

        for otherID, other in pairs(icons) do
            if otherID ~= globalID and other.frame:IsShown() then
                local oH   = other.frame:GetHeight()
                local oCX, oCY = other.frame:GetCenter()
                local oHalf = oH * 0.5

                -- X-axis snap candidates: right edge of other / left edge of other
                -- The dragged icon's left edge meets other's right edge, and vice versa.
                -- Y position: align the dragged icon's center to the other's center
                -- only if they are already roughly vertically aligned; otherwise
                -- allow the Y to be free (handled by Y snap below).
                local xRight = oCX + oHalf + myHalf  -- dragged left edge meets other right edge
                local xLeft  = oCX - oHalf - myHalf  -- dragged right edge meets other left edge

                local dxRight = math.abs(myCX - xRight)
                local dxLeft  = math.abs(myCX - xLeft)

                if dxRight < SNAP_THRESHOLD and dxRight < bestXDist then
                    bestXDist     = dxRight
                    bestX         = xRight
                    bestXTargetID = otherID
                end
                if dxLeft < SNAP_THRESHOLD and dxLeft < bestXDist then
                    bestXDist     = dxLeft
                    bestX         = xLeft
                    bestXTargetID = otherID
                end

                -- Y-axis snap candidates: top edge / bottom edge
                local yTop    = oCY + oHalf + myHalf
                local yBottom = oCY - oHalf - myHalf

                local dyTop    = math.abs(myCY - yTop)
                local dyBottom = math.abs(myCY - yBottom)

                if dyTop < SNAP_THRESHOLD and dyTop < bestYDist then
                    bestYDist     = dyTop
                    bestY         = yTop
                    bestYTargetID = otherID
                end
                if dyBottom < SNAP_THRESHOLD and dyBottom < bestYDist then
                    bestYDist     = dyBottom
                    bestY         = yBottom
                    bestYTargetID = otherID
                end
            end
        end

        -- No snap on either axis
        if not bestX and not bestY then return nil end

        -- Use snapped axis values, free axis stays at current position
        local snapCX = bestX or myCX
        local snapCY = bestY or myCY

        -- Primary target is whichever axis snapped closer (or X if tied)
        local primaryTargetID = bestX and bestXTargetID or bestYTargetID

        return {
            cx         = snapCX - uiCX,
            cy         = snapCY - uiCY,
            targetID   = primaryTargetID,
            -- Pass all snapped IDs so we can LinkSnap to all of them
            snapIDs    = {
                bestXTargetID ~= nil and bestXTargetID or nil,
                bestYTargetID ~= nil and bestYTargetID or nil,
            },
            targetSize = icons[primaryTargetID] and icons[primaryTargetID].frame:GetHeight() or mySize,
        }
    end

    frame:SetScript("OnDragStart", function(self, button)
        if button == "LeftButton" then
            UnlinkSnap(globalID)
            -- Record starting state so we can revert live snaps on move-away
            dragState = {
                originalSize    = frame:GetWidth(),
                currentSnapID   = nil,
            }
            self:StartMoving()

            -- Solo drag OnUpdate: real-time snap preview
            local soloUpdateFrame = CreateFrame("Frame")
            icon.groupDragFrame = soloUpdateFrame  -- reuse field for cleanup

            soloUpdateFrame:SetScript("OnUpdate", function()
                local myCX, myCY = frame:GetCenter()
                local mySize     = frame:GetWidth()
                local isShift    = IsShiftKeyDown()
                local isCtrl     = IsControlKeyDown()

                local candidate = FindSnapCandidate(myCX, myCY, mySize, isShift, isCtrl)

                if candidate then
                    if dragState.currentSnapID ~= candidate.targetID then
                        -- New snap target — apply live
                        dragState.currentSnapID = candidate.targetID
                        dragState.pendingSnap   = candidate
                        dragState.pendingShift  = isShift
                        dragState.pendingCtrl   = isCtrl
                        ApplySnap(candidate, isShift, isCtrl)
                    end
                else
                    if dragState.currentSnapID then
                        -- Moved out of snap range — revert
                        dragState.currentSnapID = nil
                        dragState.pendingSnap   = nil
                        RevertSnap()
                        -- Resume free movement from current cursor position
                        self:StopMovingOrSizing()
                        self:StartMoving()
                    end
                end
            end)

        elseif button == "RightButton" then
            -- Group drag: move all snapped icons together
            local group = GetSnapGroup(globalID)
            local smX, smY = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            local groupStart = {}
            for _, gID in ipairs(group) do
                local ic = icons[gID]
                if ic then
                    local cx, cy = ic.frame:GetCenter()
                    groupStart[gID] = { cx = cx, cy = cy }
                end
            end

            local dragFrame = CreateFrame("Frame")
            icon.groupDragFrame = dragFrame

            dragFrame:SetScript("OnUpdate", function()
                local curX, curY = GetCursorPosition()
                local dx = (curX - smX) / scale
                local dy = (curY - smY) / scale
                local uiCX, uiCY = UIParent:GetCenter()

                for _, gID in ipairs(group) do
                    local ic = icons[gID]
                    local gs = groupStart[gID]
                    if ic and gs then
                        ic.frame:ClearAllPoints()
                        ic.frame:SetPoint("CENTER", UIParent, "CENTER",
                            gs.cx + dx - uiCX,
                            gs.cy + dy - uiCY)
                    end
                end
            end)
        end
    end)

    frame:SetScript("OnDragStop", function(self, button)
        -- Clean up the OnUpdate frame (used by both solo and group drag)
        if icon.groupDragFrame then
            icon.groupDragFrame:SetScript("OnUpdate", nil)
            icon.groupDragFrame = nil
        end

        if button == "RightButton" then
            -- Group drag: save positions of all group members
            local group = GetSnapGroup(globalID)
            for _, gID in ipairs(group) do
                local ic = icons[gID]
                if ic then
                    SaveIconPos(ic)
                    if ic.onMove then ic.onMove(ic.db) end
                end
            end
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
            dragState = nil
            return
        end

        -- Left-button drop: finalise whatever the live preview landed on
        self:StopMovingOrSizing()

        if dragState and dragState.pendingSnap then
            -- A snap was active at release — commit it
            local snap    = dragState.pendingSnap
            local isShift = dragState.pendingShift
            local isCtrl  = dragState.pendingCtrl

            local finalSize
            if isCtrl then
                finalSize = math.max(MIN_SIZE, math.floor(snap.targetSize * 0.2))
            elseif isShift then
                finalSize = snap.targetSize
            else
                finalSize = frame:GetWidth()  -- unchanged
            end

            frame:SetSize(finalSize, finalSize)
            ScaleText(cd, stackLabel, finalSize)
            ResizeGlow(icon.glow, frame, finalSize)
            db.size = finalSize
            if icon.onResize then icon.onResize(finalSize) end

            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", snap.cx, snap.cy)
            db.point = "CENTER"
            db.x     = snap.cx
            db.y     = snap.cy
            if icon.onMove then icon.onMove(db) end

            LinkSnap(globalID, snap.targetID)
            -- Also link to any additional icons snapped on the other axis
            if snap.snapIDs then
                for _, sid in ipairs(snap.snapIDs) do
                    if sid and sid ~= snap.targetID then
                        LinkSnap(globalID, sid)
                    end
                end
            end
        else
            -- No snap — just save the free position
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
        end

        dragState = nil
    end)

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        local sq = math.max(MIN_SIZE, math.min(math.floor(frame:GetWidth()), MAX_SIZE))
        frame:SetSize(sq, sq)
        ScaleText(cd, icon.stackLabel, sq)
        ResizeGlow(icon.glow, frame, sq)
        db.size = sq
        if icon.onResize then icon.onResize(sq) end
    end)

    ApplyLockState(icon)
    return icon
end

-- ============================================================
-- Public API
-- ============================================================

function shmIcons:Register(addonName, id, db, callbacks)
    local globalID = addonName .. ":" .. tostring(id)

    if icons[globalID] then
        return icons[globalID]
    end

    if not db.size or db.size == 0 then
        db.size = db.width or db.height or 64
    end
    db.size         = tonumber(db.size)  or 64
    db.x            = tonumber(db.x)     or 0
    db.y            = tonumber(db.y)     or 0
    db.point        = db.point           or "CENTER"
    db.glow_enabled = (db.glow_enabled == true)

    local icon = BuildIconFrame(globalID, db)
    icon.onMove   = callbacks and callbacks.onMove
    icon.onResize = callbacks and callbacks.onResize

    icons[globalID] = icon
    return icon
end

-- Restore snap relationships from shmIconsDB for all currently registered icons.
-- Call this once after all icons for the current spec have been registered.
-- Only links pairs where BOTH icons are currently registered — stale entries
-- for icons that belong to a different spec are silently ignored.
function shmIcons:RestoreSnapGroups()
    -- Clear the in-memory graph first so we start clean.
    for k in pairs(snapNeighbours) do snapNeighbours[k] = nil end

    local db = GetSnapDB()
    for id, neighbours in pairs(db) do
        if icons[id] then
            for _, nb in ipairs(neighbours) do
                if icons[nb] then
                    -- Use raw table writes to avoid triggering SaveSnapGroups
                    -- on every pair during the restore loop.
                    snapNeighbours[id] = snapNeighbours[id] or {}
                    snapNeighbours[nb] = snapNeighbours[nb] or {}
                    snapNeighbours[id][nb] = true
                    snapNeighbours[nb][id] = true
                end
            end
        end
    end
end

function shmIcons:Unregister(addonName, id)
    local globalID = addonName .. ":" .. tostring(id)
    local icon = icons[globalID]
    if not icon then return end

    UnlinkSnap(globalID)
    icon.frame:Hide()
    icon.frame:SetScript("OnSizeChanged", nil)
    icon.frame:SetScript("OnDragStart",   nil)
    icon.frame:SetScript("OnDragStop",    nil)
    icons[globalID] = nil
end

function shmIcons:SetIcon(addonName, id, textureID)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if icon then icon.iconTex:SetTexture(textureID or 134400) end
end

function shmIcons:SetCooldown(addonName, id, durationObject)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if durationObject then
        icon.cd:SetCooldownFromDurationObject(durationObject)
        icon.cd:Show()
    else
        icon.cd:Clear()
    end
end

function shmIcons:SetCooldownRaw(addonName, id, start, duration)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if start and duration and duration > 1.5 then
        icon.cd:SetCooldown(start, duration)
        icon.cd:Show()
    else
        icon.cd:Clear()
    end
end

-- Show the per-charge recharge timer on the secondary cooldown frame (cd2).
-- cd2 uses DrawSwipe=false so there is no dark overlay — it shows only the
-- clock-hand edge, indicating "a charge is available but one is recharging".
-- Pass a DurationObject from C_Spell.GetSpellCooldownDuration, or nil to clear.
function shmIcons:SetChargeCooldown(addonName, id, durationObject)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if durationObject then
        icon.cd2:SetCooldownFromDurationObject(durationObject)
        icon.cd2:Show()
    else
        icon.cd2:Clear()
    end
end

function shmIcons:SetGlow(addonName, id, show)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if show and icon.glowEnabled then
        icon.glow:Show()
    else
        icon.glow:Hide()
    end
end

function shmIcons:ToggleGlowEnabled(addonName, id)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    icon.glowEnabled     = not icon.glowEnabled
    icon.db.glow_enabled = icon.glowEnabled
    if not icon.glowEnabled then icon.glow:Hide() end
    return icon.glowEnabled
end

function shmIcons:SetStacks(addonName, id, count)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end

    local drawStacks
    if issecretvalue(count) then
        drawStacks = not C_Spell.GetSpellCooldown(icon.db.spellID).isActive
    else
        drawStacks = count and count > 0
    end

    if count and drawStacks then
        icon.stackLabel:SetText(tostring(count))
        icon.stackLabel:Show()
    else
        icon.stackLabel:SetText("")
        icon.stackLabel:Hide()
    end
end

function shmIcons:SetVisible(addonName, id, visible)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if visible then icon.frame:Show() else icon.frame:Hide() end
end

function shmIcons:SetRange(addonName, id, inRange)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    -- IsSpellInRange returns nil for spells with no range requirement.
    -- Treat nil as in-range so the icon stays white rather than erroring.
    if inRange == nil then
        icon.iconTex:SetVertexColor(1, 1, 1, 1)
        return
    end
    icon.iconTex:SetVertexColorFromBoolean(inRange, RANGE_COLOR_IN, RANGE_COLOR_OUT)
end

-- Apply a usability tint via a dedicated overlay texture.
-- usable : secret boolean from C_Spell.IsSpellUsable(spellID)
--          true  = usable   → overlay is transparent (no effect)
--          false = unusable → overlay is semi-transparent gray
-- The value is never compared — passed opaquely to SetVertexColorFromBoolean.
-- This composes correctly with SetRange since they operate on separate textures.
function shmIcons:SetUsable(addonName, id, usable)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    icon.usableOverlay:SetVertexColorFromBoolean(usable, USABLE_COLOR_YES, USABLE_COLOR_NO)
end

function shmIcons:ResetIcon(addonName, id, defaultSize)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    local sz = defaultSize or 64
    UnlinkSnap(addonName .. ":" .. tostring(id))
    icon.db.x     = 0
    icon.db.y     = 0
    icon.db.point = "CENTER"
    icon.db.size  = sz
    icon.frame:SetSize(sz, sz)
    icon.frame:ClearAllPoints()
    icon.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function shmIcons:ToggleLock()
    isLocked = not isLocked
    for _, icon in pairs(icons) do ApplyLockState(icon) end
    return isLocked
end

function shmIcons:IsLocked()
    return isLocked
end

-- ============================================================
-- Slash command: /shm lock  (canonical lock toggle for all icons)
-- Both /tt and /cdt also call ToggleLock, so any of the three works.
-- ============================================================

SLASH_SHMICONS1 = "/shm"
SlashCmdList["SHMICONS"] = function(msg)
    local cmd = msg:lower():trim()
    if cmd == "lock" or cmd == "" then
        local locked = shmIcons:ToggleLock()
        local state = locked
            and "|cFF00FF00Locked.|r"
            or  "|cFFFFFF00Unlocked. Left-drag: move solo. Right-drag: move group.|r"
        print("shmIcons: All icons " .. state)
    end
end

function shmIcons:GetAll()
    local result = {}
    for globalID, icon in pairs(icons) do
        local addonName, localID = globalID:match("^(.+):(.+)$")
        table.insert(result, {
            globalID       = globalID,
            addonName      = addonName,
            localID        = localID,
            icon           = icon,
            snapNeighbours = snapNeighbours[globalID],
        })
    end
    return result
end