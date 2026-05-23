-- shmIcons_IconFrame_Behavior.lua
-- Script attachment helpers for icon frames.

function shmIcons_AttachIconSizeHandler(icon, db, cd, stackLabel, frame, resizeHandle)
    frame:SetScript("OnSizeChanged", function(self, width)
        local rounded = math.floor((width or self:GetWidth()) + 0.5)
        local sq = math.max(MIN_SIZE, math.min(rounded, MAX_SIZE))
        if math.abs(self:GetWidth() - sq) > 0.5 or math.abs(self:GetHeight() - sq) > 0.5 then
            self:SetSize(sq, sq)
            return
        end
        ScaleText(cd, stackLabel, sq)
        ResizeGlow(icon.glow, frame, sq)
        resizeHandle:SetSize(math.max(10, math.floor(sq * 0.25)), math.max(10, math.floor(sq * 0.25)))
        if icon.hotkeyLabel then
            icon.hotkeyLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(sq * FONT_RATIO * 0.4)), FONT_FLAGS)
        end
        db.size = sq
        if icon.onResize then icon.onResize(sq) end
    end)
end

function shmIcons_AttachIconDragHandlers(icon, globalID, db, cd, stackLabel, frame)
    local ctx = {
        icon = icon,
        globalID = globalID,
        db = db,
        cd = cd,
        stackLabel = stackLabel,
        frame = frame,
        dragState = nil,
    }

    frame:SetScript("OnDragStart", function(self, button)
        if button == "LeftButton" then
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX = nil
            db.ctrlOffsetY = nil
            ctx.dragState = {
                originalSize = frame:GetWidth(),
                currentSnapID = nil,
            }
            self:StartMoving()

            if not icon.groupDragFrame then
                icon.groupDragFrame = CreateFrame("Frame")
            end
            local soloUpdateFrame = icon.groupDragFrame

            soloUpdateFrame:SetScript("OnUpdate", function()
                local rawX, rawY = GetCursorPosition()
                local uiScale = UIParent:GetEffectiveScale()
                local myCX = rawX / uiScale
                local myCY = rawY / uiScale
                local mySize = frame:GetWidth()
                local isCtrl = IsControlKeyDown()

                if IsShiftKeyDown() then
                    local nearestDist = math.huge
                    local nearestSize = nil
                    for otherID, other in pairs(icons) do
                        if otherID ~= globalID and other.frame:IsShown() and not other.isNameplateManaged then
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
                        ctx.dragState.currentSnapID = nil
                    end
                end

                local searchSize = (isCtrl and ctx.dragState.sizeAtSnapEnter) or mySize
                local candidate = shmIcons_IconFrameFindSnapCandidate(ctx, myCX, myCY, searchSize, isCtrl)

                if candidate then
                    if ctx.dragState.currentSnapID ~= candidate.targetID or ctx.dragState.pendingCtrl ~= isCtrl then
                        ctx.dragState.currentSnapID = candidate.targetID
                        ctx.dragState.pendingSnap = candidate
                        ctx.dragState.pendingCtrl = isCtrl
                        shmIcons_IconFrameApplySnap(ctx, candidate, isCtrl)
                    end
                else
                    if ctx.dragState.currentSnapID then
                        ctx.dragState.currentSnapID = nil
                        ctx.dragState.pendingSnap = nil
                        shmIcons_IconFrameRevertSnap(ctx)
                        self:StopMovingOrSizing()
                        self:StartMoving()
                    end
                end
            end)

        elseif button == "RightButton" then
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX = nil
            db.ctrlOffsetY = nil
            local mySize = frame:GetWidth()
            local initCX, initCY = frame:GetCenter()
            local uiCX, uiCY = UIParent:GetCenter()

            local groupMembers = {}
            local visited = { [globalID] = true }
            local queue = { { id = globalID, cx = initCX, cy = initCY } }

            while #queue > 0 do
                local curr = table.remove(queue, 1)
                for otherID, other in pairs(icons) do
                    if not visited[otherID] and other.frame:IsShown()
                        and not other.db.ctrlAttachedTo
                        and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
                        local ocx, ocy = other.frame:GetCenter()
                        local adx = math.abs(ocx - curr.cx)
                        local ady = math.abs(ocy - curr.cy)
                        if adx <= mySize + 4 and ady <= mySize + 4 and (adx > 2 or ady > 2) then
                            visited[otherID] = true
                            table.insert(queue, { id = otherID, cx = ocx, cy = ocy })
                            table.insert(groupMembers, {
                                icon = other,
                                offsetX = ocx - initCX,
                                offsetY = ocy - initCY,
                            })
                        end
                    end
                end
            end

            ctx.dragState = {
                isGroupDrag = true,
                groupMembers = groupMembers,
                originalSize = mySize,
            }
            self:StartMoving()

            if not icon.groupDragFrame then
                icon.groupDragFrame = CreateFrame("Frame")
            end
            local groupUpdateFrame = icon.groupDragFrame

            groupUpdateFrame:SetScript("OnUpdate", function()
                local newCX, newCY = frame:GetCenter()
                for _, member in ipairs(groupMembers) do
                    member.icon.frame:ClearAllPoints()
                    member.icon.frame:SetPoint("CENTER", UIParent, "CENTER", newCX + member.offsetX - uiCX, newCY + member.offsetY - uiCY)
                end
            end)
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        if icon.groupDragFrame then
            icon.groupDragFrame:SetScript("OnUpdate", nil)
        end
        self:StopMovingOrSizing()

        if ctx.dragState and ctx.dragState.isGroupDrag then
            local finalCX, finalCY = frame:GetCenter()
            local finalUiCX, finalUiCY = UIParent:GetCenter()
            for _, member in ipairs(ctx.dragState.groupMembers) do
                member.icon.frame:ClearAllPoints()
                member.icon.frame:SetPoint("CENTER", UIParent, "CENTER", finalCX + member.offsetX - finalUiCX, finalCY + member.offsetY - finalUiCY)
            end
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
            RepositionCtrlChildren(globalID)
            for _, member in ipairs(ctx.dragState.groupMembers) do
                SaveIconPos(member.icon)
                if member.icon.onMove then member.icon.onMove(member.icon.db) end
                RepositionCtrlChildren(member.icon.globalID)
            end
        elseif ctx.dragState and ctx.dragState.pendingSnap then
            local snap = ctx.dragState.pendingSnap
            local isCtrl = ctx.dragState.pendingCtrl

            local finalSize
            if isCtrl then
                finalSize = math.max(MIN_SIZE, math.floor(snap.targetSize * 0.35 + 0.5))
            else
                finalSize = math.max(MIN_SIZE, math.min(math.floor(frame:GetWidth() + 0.5), MAX_SIZE))
            end

            frame:SetSize(finalSize, finalSize)
            ScaleText(cd, stackLabel, finalSize)
            ResizeGlow(icon.glow, frame, finalSize)
            db.size = finalSize
            if icon.onResize then icon.onResize(finalSize) end

            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", snap.cx, snap.cy)
            db.point = "CENTER"
            db.x = snap.cx
            db.y = snap.cy
            db.strata = frame:GetFrameStrata()
            if isCtrl then
                db.ctrlAttachedTo = snap.targetID
                local parentIcon = icons[snap.targetID]
                if parentIcon then
                    local pCX, pCY = parentIcon.frame:GetCenter()
                    local puiCX, puiCY = UIParent:GetCenter()
                    db.ctrlOffsetX = snap.cx - (pCX - puiCX)
                    db.ctrlOffsetY = snap.cy - (pCY - puiCY)
                end
            else
                db.ctrlAttachedTo = nil
                db.ctrlOffsetX = nil
                db.ctrlOffsetY = nil
            end
            if icon.onMove then icon.onMove(db) end
            RepositionCtrlChildren(globalID)
        else
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX = nil
            db.ctrlOffsetY = nil
            local finalSize = frame:GetWidth()
            if finalSize ~= ctx.dragState.originalSize then
                db.size = finalSize
                if icon.onResize then icon.onResize(finalSize) end
            end
            if not IsControlKeyDown() then
                shmIcons_IconFrameResolveOverlaps(ctx)
            end
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
            RepositionCtrlChildren(globalID)
        end

        ctx.dragState = nil
    end)
end

function shmIcons_AttachIconResizeHandlers(icon, db, cd, frame, resizeHandle)
    resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX = nil
            db.ctrlOffsetY = nil
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        local sq = math.max(MIN_SIZE, math.min(math.floor(frame:GetWidth() + 0.5), MAX_SIZE))
        frame:SetSize(sq, sq)
        ScaleText(cd, icon.stackLabel, sq)
        ResizeGlow(icon.glow, frame, sq)
        db.size = sq
        if icon.onResize then icon.onResize(sq) end
    end)
end
