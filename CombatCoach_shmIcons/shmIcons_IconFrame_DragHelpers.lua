-- shmIcons_IconFrame_DragHelpers.lua
-- Shared drag helper functions for icon frames.

function shmIcons_IconFrameApplySnap(ctx, candidate, isCtrl)
    ctx.dragState.sizeAtSnapEnter = ctx.frame:GetWidth()
    ctx.frame:StopMovingOrSizing()
    if isCtrl then
        local cornerSize = math.max(MIN_SIZE, math.floor(candidate.targetSize * 0.35))
        ctx.frame:SetSize(cornerSize, cornerSize)
        ScaleText(ctx.cd, ctx.stackLabel, cornerSize)
        ResizeGlow(ctx.icon.glow, ctx.frame, cornerSize)
        ctx.frame:SetFrameStrata("HIGH")
        ctx.frame:ClearAllPoints()
        ctx.frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
    else
        ctx.frame:SetFrameStrata("MEDIUM")
        ctx.frame:ClearAllPoints()
        ctx.frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
    end
end

function shmIcons_IconFrameRevertSnap(ctx)
    local revertTo = (ctx.dragState and ctx.dragState.sizeAtSnapEnter)
        or (ctx.dragState and ctx.dragState.originalSize)
    if revertTo then
        ctx.frame:SetSize(revertTo, revertTo)
        ScaleText(ctx.cd, ctx.stackLabel, revertTo)
        ResizeGlow(ctx.icon.glow, ctx.frame, revertTo)
    end
    ctx.frame:SetFrameStrata("MEDIUM")
end

function shmIcons_IconFrameResolveOverlaps(ctx)
    if not ctx or not ctx.frame then return end
    local myCX, myCY = ctx.frame:GetCenter()
    local myHalf = ctx.frame:GetWidth() * 0.5
    local uiCX, uiCY = UIParent:GetCenter()

    local changed = true
    local iters = 0
    while changed and iters < 8 do
        changed = false
        iters = iters + 1
        for otherID, other in pairs(icons) do
            if otherID ~= ctx.globalID and other and other.frame and other.frame:IsShown()
                and not other.isNameplateManaged then
                local oCX, oCY = other.frame:GetCenter()
                local oHalf = other.frame:GetHeight() * 0.5
                local absDX = math.abs(myCX - oCX)
                local absDY = math.abs(myCY - oCY)
                local minDist = myHalf + oHalf
                if absDX < minDist and absDY < minDist then
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

    ctx.frame:ClearAllPoints()
    ctx.frame:SetPoint("CENTER", UIParent, "CENTER", myCX - uiCX, myCY - uiCY)
end

function shmIcons_IconFrameFindSnapCandidate(ctx, myCX, myCY, mySize, isCtrl)
    local uiCX, uiCY = UIParent:GetCenter()

    if isCtrl then
        local function nearestCornerOf(otherID, other)
            local oH = other.frame:GetHeight()
            local oCX, oCY = other.frame:GetCenter()
            local oHalf = oH * 0.5
            local cHalf = math.max(MIN_SIZE, math.floor(oH * 0.35)) * 0.5

            local bestDist = math.huge
            local result = nil
            local offsets = {
                { ox = oHalf, oy = oHalf },
                { ox = -oHalf, oy = oHalf },
                { ox = oHalf, oy = -oHalf },
                { ox = -oHalf, oy = -oHalf },
            }
            for _, c in ipairs(offsets) do
                local dist = math.sqrt((myCX - (oCX + c.ox))^2 + (myCY - (oCY + c.oy))^2)
                if dist < bestDist then
                    bestDist = dist
                    local signX = (c.ox > 0) and 1 or -1
                    local signY = (c.oy > 0) and 1 or -1
                    result = {
                        dist = dist,
                        cx = (oCX + c.ox - signX * cHalf) - uiCX,
                        cy = (oCY + c.oy - signY * cHalf) - uiCY,
                        targetID = otherID,
                        targetSize = oH,
                    }
                end
            end
            return result
        end

        for otherID, other in pairs(icons) do
            if otherID ~= ctx.globalID and other and other.frame and other.frame:IsShown()
                and not other.isNameplateManaged then
                local oH = other.frame:GetHeight()
                local oCX, oCY = other.frame:GetCenter()
                local oHalf = oH * 0.5
                if myCX >= oCX - oHalf and myCX <= oCX + oHalf
                    and myCY >= oCY - oHalf and myCY <= oCY + oHalf then
                    return nearestCornerOf(otherID, other)
                end
            end
        end

        local bestDist = math.huge
        local best = nil
        for otherID, other in pairs(icons) do
            if otherID ~= ctx.globalID and other and other.frame and other.frame:IsShown()
                and not other.isNameplateManaged then
                local c = nearestCornerOf(otherID, other)
                if c and c.dist < bestDist then
                    bestDist = c.dist
                    best = c
                end
            end
        end
        return best
    end

    local bestDist = math.huge
    local best = nil
    for otherID, other in pairs(icons) do
        if otherID ~= ctx.globalID and other and other.frame and other.frame:IsShown()
            and not other.isNameplateManaged
            and not other.db.ctrlAttachedTo
            and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
            local oCX, oCY = other.frame:GetCenter()
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if not (dx == 0 and dy == 0) then
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
