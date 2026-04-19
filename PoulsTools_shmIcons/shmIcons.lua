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
local snapNeighbours = {}  -- (unused) kept for API compatibility
local isLocked       = true

-- ============================================================
-- Snap DB helpers
-- ============================================================

-- Snap groups have been removed. Keep API stubs for compatibility.
local function GetSnapDB()
    return {}
end
local function SaveSnapGroups() end

-- ============================================================
-- Snap helpers
-- ============================================================

local function LinkSnap(a, b) end
local function UnlinkSnap(id) end
local function GetSnapGroup(startID) return { startID } end

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
    icon.db.strata = icon.frame:GetFrameStrata()
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
    frame:SetFrameStrata(db.strata or "MEDIUM")

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

    -- Create a small overlay frame for the stack label and put it at a
    -- frame level above the cooldown frames (use cd2's level + 1 so the
    -- label is visible above the swipe and cooldown timer).
    local labelFrame = CreateFrame("Frame", nil, frame)
    labelFrame:SetAllPoints(frame)
    labelFrame:SetFrameLevel(cd2:GetFrameLevel() + 1)

    local stackLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stackLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO)), FONT_FLAGS)
    stackLabel:SetTextColor(STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B, 1)
    stackLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    stackLabel:SetJustifyH("RIGHT")
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
    local function ApplySnap(candidate, isCtrl)
        -- Save the size the frame has right now so RevertSnap can restore to it
        -- (the frame may already have been shift-resized before entering snap).
        dragState.sizeAtSnapEnter = frame:GetWidth()
        -- Must stop WoW's movement system before repositioning; otherwise
        -- StartMoving() tracking overrides SetPoint on the very next cursor move.
        frame:StopMovingOrSizing()
        if isCtrl then
            -- Corner-attach: 35% size, raised strata, corner-to-corner
            local cornerSize = math.max(MIN_SIZE, math.floor(candidate.targetSize * 0.35))
            frame:SetSize(cornerSize, cornerSize)
            ScaleText(cd, stackLabel, cornerSize)
            ResizeGlow(icon.glow, frame, cornerSize)
            frame:SetFrameStrata("HIGH")
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
        else
            -- Default: snap to edge-aligned candidate position (no live resize)
            frame:SetFrameStrata("MEDIUM")
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
        end
    end

    -- Revert any live snap changes made during dragging (size/strata).
    -- Restores to the size the frame had when snap was entered (which may be a
    -- shift-resized value), falling back to the original drag-start size.
    local function RevertSnap()
        local revertTo = (dragState and dragState.sizeAtSnapEnter)
                      or (dragState and dragState.originalSize)
        if revertTo then
            frame:SetSize(revertTo, revertTo)
            ScaleText(cd, stackLabel, revertTo)
            ResizeGlow(icon.glow, frame, revertTo)
        end
        frame:SetFrameStrata("MEDIUM")
    end

    -- Push the dragged icon out of any bounding-box overlaps after drop.
    -- Iterates until fully resolved or the iteration cap is hit.
    -- Not called when ctrl was held (ctrl corner-attach intentionally overlaps).
    local function ResolveOverlaps()
        local myCX, myCY = frame:GetCenter()
        local myHalf = frame:GetWidth() * 0.5
        local uiCX, uiCY = UIParent:GetCenter()

        local changed = true
        local iters = 0
        while changed and iters < 8 do
            changed = false
            iters = iters + 1
            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown() then
                    local oCX, oCY = other.frame:GetCenter()
                    local oHalf = other.frame:GetHeight() * 0.5
                    local absDX = math.abs(myCX - oCX)
                    local absDY = math.abs(myCY - oCY)
                    local minDist = myHalf + oHalf
                    if absDX < minDist and absDY < minDist then
                        -- Resolve along the axis of minimum penetration
                        local penX = minDist - absDX
                        local penY = minDist - absDY
                        if penX <= penY then
                            local dir = (myCX >= oCX) and 1 or -1
                            myCX = oCX + dir * minDist
                        else
                            local dir = (myCY >= oCY) and 1 or -1
                            myCY = oCY + dir * minDist
                        end
                        changed = true
                    end
                end
            end
        end

        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", myCX - uiCX, myCY - uiCY)
    end

    -- Find snap candidates:
    --  - Ctrl: corner-attach to nearest same-size icon. Detection is against the
    --    OUTER corners of the target (what the user visually approaches); the snap
    --    position is the inner corner (where the 35% icon's centre sits).
    --    Overlapping is intentional for ctrl corner-attach.
    --  - Default: snap edge-to-edge with nearest same-size icon.
    --    dx=0,dy=0 is excluded to prevent overlap.
    local function FindSnapCandidate(myCX, myCY, mySize, isCtrl)
        local uiCX, uiCY = UIParent:GetCenter()

        if isCtrl then
            -- Find the icon the cursor is currently inside, then snap to its
            -- nearest corner. If the cursor isn't inside any icon, use the icon
            -- whose nearest corner is overall closest (fallback).
            local function nearestCornerOf(otherID, other)
                local oH = other.frame:GetHeight()
                local oCX, oCY = other.frame:GetCenter()
                local oHalf = oH * 0.5
                local cHalf = math.max(MIN_SIZE, math.floor(oH * 0.35)) * 0.5

                local bestDist = math.huge
                local result = nil
                local offsets = {
                    { ox = oHalf,  oy = oHalf  },
                    { ox = -oHalf, oy = oHalf  },
                    { ox = oHalf,  oy = -oHalf },
                    { ox = -oHalf, oy = -oHalf },
                }
                for _, c in ipairs(offsets) do
                    local dist = math.sqrt((myCX - (oCX + c.ox))^2 + (myCY - (oCY + c.oy))^2)
                    if dist < bestDist then
                        bestDist = dist
                        local signX = (c.ox > 0) and 1 or -1
                        local signY = (c.oy > 0) and 1 or -1
                        result = {
                            dist     = dist,
                            cx       = (oCX + c.ox - signX * cHalf) - uiCX,
                            cy       = (oCY + c.oy - signY * cHalf) - uiCY,
                            targetID = otherID,
                            targetSize = oH,
                        }
                    end
                end
                return result
            end

            -- Pass 1: cursor is inside this icon's bounding box
            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown() then
                    local oH = other.frame:GetHeight()
                    local oCX, oCY = other.frame:GetCenter()
                    local oHalf = oH * 0.5
                    if myCX >= oCX - oHalf and myCX <= oCX + oHalf
                    and myCY >= oCY - oHalf and myCY <= oCY + oHalf then
                        return nearestCornerOf(otherID, other)
                    end
                end
            end

            -- Pass 2: fallback — nearest corner across all icons
            local bestDist = math.huge
            local best = nil
            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown() then
                    local c = nearestCornerOf(otherID, other)
                    if c and c.dist < bestDist then
                        bestDist = c.dist
                        best = c
                    end
                end
            end
            return best
        end

        -- Default: edge-aligned snap to nearest same-size icon.
        -- dx=0,dy=0 skipped — that position would perfectly overlap the target.
        local bestDist = math.huge
        local best = nil
        for otherID, other in pairs(icons) do
            if otherID ~= globalID and other.frame:IsShown() and other.frame:GetHeight() == mySize then
                local oCX, oCY = other.frame:GetCenter()
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        if not (dx == 0 and dy == 0) then  -- skip: would overlap target
                            local posX = oCX + dx * mySize
                            local posY = oCY + dy * mySize
                            local dist = math.sqrt((myCX - posX)^2 + (myCY - posY)^2)
                            if dist < SNAP_THRESHOLD and dist < bestDist then
                                bestDist = dist
                                best = {
                                    cx = posX - uiCX,
                                    cy = posY - uiCY,
                                    targetID = otherID,
                                    targetSize = mySize,
                                }
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    frame:SetScript("OnDragStart", function(self, button)
        if button == "LeftButton" then
            -- Solo drag with snap preview
            dragState = {
                originalSize  = frame:GetWidth(),
                currentSnapID = nil,
            }
            self:StartMoving()

            local soloUpdateFrame = CreateFrame("Frame")
            icon.groupDragFrame = soloUpdateFrame

            soloUpdateFrame:SetScript("OnUpdate", function()
                -- Use cursor position instead of frame:GetCenter().
                -- After ApplySnap calls StopMovingOrSizing() the frame is frozen,
                -- so frame:GetCenter() would always return the snap point and the
                -- icon could never escape. GetCursorPosition() tracks the mouse.
                local rawX, rawY = GetCursorPosition()
                local uiScale    = UIParent:GetEffectiveScale()
                local myCX = rawX / uiScale
                local myCY = rawY / uiScale
                local mySize     = frame:GetWidth()
                local isCtrl     = IsControlKeyDown()

                -- Shift: live resize to the nearest icon's size (no position snap).
                -- Runs every tick while shift is held; resets snap state when size
                -- changes so the next tick evaluates candidates with the new size.
                if IsShiftKeyDown() then
                    local nearestDist = math.huge
                    local nearestSize = nil
                    for otherID, other in pairs(icons) do
                        if otherID ~= globalID and other.frame:IsShown() then
                            local oCX, oCY = other.frame:GetCenter()
                            local d = math.sqrt((myCX - oCX)^2 + (myCY - oCY)^2)
                            if d < nearestDist then
                                nearestDist = d
                                nearestSize = other.frame:GetHeight()
                            end
                        end
                    end
                    if nearestSize and nearestSize ~= mySize then
                        frame:SetSize(nearestSize, nearestSize)
                        ScaleText(cd, stackLabel, nearestSize)
                        ResizeGlow(icon.glow, frame, nearestSize)
                        mySize = nearestSize
                        -- Force re-evaluation next tick with the new size
                        dragState.currentSnapID = nil
                    end
                end

                -- For ctrl mode: after ApplySnap shrinks the frame to 35%, read
                -- the pre-snap size so FindSnapCandidate can still match full-size
                -- neighbours. Without this the shrunken size finds no matches →
                -- instant RevertSnap every tick → oscillation.
                local searchSize = (isCtrl and dragState.sizeAtSnapEnter) or mySize
                local candidate = FindSnapCandidate(myCX, myCY, searchSize, isCtrl)

                if candidate then
                    if dragState.currentSnapID ~= candidate.targetID
                       or dragState.pendingCtrl ~= isCtrl then
                        -- New snap target or modifier change — apply live
                        dragState.currentSnapID = candidate.targetID
                        dragState.pendingSnap   = candidate
                        dragState.pendingCtrl   = isCtrl
                        ApplySnap(candidate, isCtrl)
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
            -- Group drag: BFS from this icon to find all recursively adjacent
            -- same-size icons. All members move together, maintaining offsets.
            local mySize         = frame:GetWidth()
            local initCX, initCY = frame:GetCenter()
            local uiCX, uiCY     = UIParent:GetCenter()

            -- BFS to collect adjacent same-size icons
            local groupMembers = {}  -- { icon, offsetX, offsetY }
            local visited = { [globalID] = true }
            local queue   = { { id = globalID, cx = initCX, cy = initCY } }

            while #queue > 0 do
                local curr = table.remove(queue, 1)
                for otherID, other in pairs(icons) do
                    if not visited[otherID] and other.frame:IsShown()
                       and other.frame:GetHeight() == mySize then
                        local ocx, ocy = other.frame:GetCenter()
                        local adx = math.abs(ocx - curr.cx)
                        local ady = math.abs(ocy - curr.cy)
                        -- Adjacent = within one icon-width in both axes,
                        -- but not occupying the same center (not the same icon)
                        if adx <= mySize + 2 and ady <= mySize + 2
                           and (adx > 2 or ady > 2) then
                            visited[otherID] = true
                            table.insert(queue, { id = otherID, cx = ocx, cy = ocy })
                            table.insert(groupMembers, {
                                icon    = other,
                                offsetX = ocx - initCX,
                                offsetY = ocy - initCY,
                            })
                        end
                    end
                end
            end

            dragState = {
                isGroupDrag  = true,
                groupMembers = groupMembers,
                originalSize = mySize,
            }
            self:StartMoving()

            -- OnUpdate: reposition group members to follow the dragged icon
            local groupUpdateFrame = CreateFrame("Frame")
            icon.groupDragFrame = groupUpdateFrame

            groupUpdateFrame:SetScript("OnUpdate", function()
                local newCX, newCY = frame:GetCenter()
                for _, member in ipairs(groupMembers) do
                    member.icon.frame:ClearAllPoints()
                    member.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                        newCX + member.offsetX - uiCX,
                        newCY + member.offsetY - uiCY)
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
        self:StopMovingOrSizing()

        if dragState and dragState.isGroupDrag then
            -- Commit final positions for the dragged icon and all group members
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
            for _, member in ipairs(dragState.groupMembers) do
                SaveIconPos(member.icon)
                if member.icon.onMove then member.icon.onMove(member.icon.db) end
            end
        elseif dragState and dragState.pendingSnap then
            local snap   = dragState.pendingSnap
            local isCtrl = dragState.pendingCtrl

            local finalSize = isCtrl
                and math.max(MIN_SIZE, math.floor(snap.targetSize * 0.35))
                or  frame:GetWidth()

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
            db.strata = frame:GetFrameStrata()
            if icon.onMove then icon.onMove(db) end
        else
            -- No snap — commit any shift-resize, resolve overlaps, then save
            local finalSize = frame:GetWidth()
            if finalSize ~= dragState.originalSize then
                db.size = finalSize
                if icon.onResize then icon.onResize(finalSize) end
            end
            if not IsControlKeyDown() then
                ResolveOverlaps()
            end
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
    -- Snap groups disabled; nothing to restore.
end

function shmIcons:Unregister(addonName, id)
    local globalID = addonName .. ":" .. tostring(id)
    local icon = icons[globalID]
    if not icon then return end
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
    icon.db.x     = 0
    icon.db.y     = 0
    icon.db.point = "CENTER"
    icon.db.size  = sz
    icon.db.strata = icon.db.strata or "MEDIUM"
    icon.frame:SetSize(sz, sz)
    icon.frame:ClearAllPoints()
    icon.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    icon.frame:SetFrameStrata(icon.db.strata)
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
            or  "|cFFFFFF00Unlocked. Left/Right-drag: move solo.|r"
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