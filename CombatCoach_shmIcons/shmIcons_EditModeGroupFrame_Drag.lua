-- shmIcons_EditModeGroupFrame_Drag.lua
-- Drag script helper for edit mode group frames.

function shmIcons_AttachEditModeGroupDragScripts(ctx)
    local function IsEditModeActive()
        return shmIcons and shmIcons.IsInEditMode and shmIcons:IsInEditMode()
    end

    local function HasEntryFrame(entry)
        return entry and entry.icon and entry.icon.frame
    end

    ctx.frame:SetScript("OnDragStart", function(self)
        if not IsEditModeActive() then return end
        ctx.clickPending = false
        ctx.isDragging = true
        ctx.isSnapFrozen = false
        local rawX, rawY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local curX = rawX / uiScale
        local curY = rawY / uiScale
        local cx, cy = self:GetCenter()
        ctx.cursorOffX = cx - curX
        ctx.cursorOffY = cy - curY

        if IsShiftKeyDown() and #ctx.offsets > 1 then
            local bestDist = math.huge
            ctx.soloEntry = nil
            for _, entry in ipairs(ctx.offsets) do
                if HasEntryFrame(entry) then
                    local icx, icy = entry.icon.frame:GetCenter()
                    local d = math.sqrt((curX - icx)^2 + (curY - icy)^2)
                    if d < bestDist then
                        bestDist = d
                        ctx.soloEntry = entry
                        ctx.soloIconOffX = icx - curX
                        ctx.soloIconOffY = icy - curY
                    end
                end
            end
            if ctx.soloEntry then
                ctx.soloEntry.icon.db.ctrlAttachedTo = nil
                ctx.soloEntry.icon.db.ctrlOffsetX = nil
                ctx.soloEntry.icon.db.ctrlOffsetY = nil
                ctx.frame:SetBackdropBorderColor(1.0, 0.8, 0.2, 1.0)
            end
        else
            for _, entry in ipairs(ctx.offsets) do
                if entry and entry.icon and entry.icon.db then
                    entry.icon.db.ctrlAttachedTo = nil
                    entry.icon.db.ctrlOffsetX = nil
                    entry.icon.db.ctrlOffsetY = nil
                end
            end
            ctx.soloEntry = nil
        end

        self:StartMoving()
    end)

    ctx.frame:SetScript("OnUpdate", function(self)
        if not ctx.isDragging then return end
        if not IsEditModeActive() then
            ctx.isDragging = false
            self:StopMovingOrSizing()
            return
        end

        local rawX, rawY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local curX = rawX / uiScale
        local curY = rawY / uiScale
        local puiCX, puiCY = UIParent:GetCenter()

        if ctx.soloEntry and HasEntryFrame(ctx.soloEntry) then
            ctx.soloEntry.icon.frame:ClearAllPoints()
            ctx.soloEntry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", curX + ctx.soloIconOffX - puiCX, curY + ctx.soloIconOffY - puiCY)
            return
        end

        local virtualCX = curX + ctx.cursorOffX
        local virtualCY = curY + ctx.cursorOffY

        if IsShiftKeyDown() then
            local nearestDist = math.huge
            local nearestSize = nil
            for _, entry in ipairs(ctx.offsets) do
                local memberCX = virtualCX + entry.offsetX
                local memberCY = virtualCY + entry.offsetY
                for otherID, other in pairs(icons) do
                    if not ctx.groupIDSet[otherID] and other and other.frame and other.db and other.frame:IsShown() and not other.db.ctrlAttachedTo then
                        local oCX, oCY = other.frame:GetCenter()
                        local d = math.sqrt((memberCX - oCX)^2 + (memberCY - oCY)^2)
                        if d < nearestDist then
                            nearestDist = d
                            nearestSize = math.floor(other.frame:GetHeight() + 0.5)
                        end
                    end
                end
            end
            if nearestSize and nearestSize ~= ctx.mySize then
                local scale = nearestSize / ctx.mySize
                for _, entry in ipairs(ctx.offsets) do
                    entry.offsetX = entry.offsetX * scale
                    entry.offsetY = entry.offsetY * scale
                    if HasEntryFrame(entry) then
                        entry.icon.frame:SetSize(nearestSize, nearestSize)
                    end
                end
                ctx.mySize = nearestSize
                ctx.isSnapFrozen = false
            end

            local bestDist = math.huge
            local bestSnapCX, bestSnapCY = nil, nil

            for _, entry in ipairs(ctx.offsets) do
                local memberCX = virtualCX + entry.offsetX
                local memberCY = virtualCY + entry.offsetY
                for otherID, other in pairs(icons) do
                    if not ctx.groupIDSet[otherID] and other and other.frame and other.db and other.frame:IsShown()
                        and not other.db.ctrlAttachedTo
                        and math.abs(other.frame:GetHeight() - ctx.mySize) < 0.5 then
                        local oCX, oCY = other.frame:GetCenter()
                        for dx = -1, 1 do
                            for dy = -1, 1 do
                                if not (dx == 0 and dy == 0) then
                                    local posX = oCX + dx * ctx.mySize
                                    local posY = oCY + dy * ctx.mySize
                                    local dist = math.sqrt((memberCX - posX)^2 + (memberCY - posY)^2)
                                    if dist < SNAP_THRESHOLD and dist < bestDist then
                                        bestDist = dist
                                        bestSnapCX = virtualCX + (posX - memberCX)
                                        bestSnapCY = virtualCY + (posY - memberCY)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if bestSnapCX then
                if not ctx.isSnapFrozen then
                    self:StopMovingOrSizing()
                    ctx.isSnapFrozen = true
                end
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", bestSnapCX - puiCX, bestSnapCY - puiCY)
                for _, entry in ipairs(ctx.offsets) do
                    if HasEntryFrame(entry) then
                        entry.icon.frame:ClearAllPoints()
                        entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", bestSnapCX + entry.offsetX - puiCX, bestSnapCY + entry.offsetY - puiCY)
                    end
                end
                return
            end
        end

        if ctx.isSnapFrozen then
            ctx.isSnapFrozen = false
            self:StartMoving()
            return
        end

        local cx, cy = self:GetCenter()
        for _, entry in ipairs(ctx.offsets) do
            if HasEntryFrame(entry) then
                entry.icon.frame:ClearAllPoints()
                entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", cx + entry.offsetX - puiCX, cy + entry.offsetY - puiCY)
            end
        end
    end)

    ctx.frame:SetScript("OnDragStop", function(self)
        ctx.isDragging = false
        ctx.isSnapFrozen = false
        self:StopMovingOrSizing()
        ctx.frame:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)
        local puiCX, puiCY = UIParent:GetCenter()

        if ctx.soloEntry and HasEntryFrame(ctx.soloEntry) then
            local rawX, rawY = GetCursorPosition()
            local uiScale = UIParent:GetEffectiveScale()
            local curX = rawX / uiScale
            local curY = rawY / uiScale
            ctx.soloEntry.icon.frame:ClearAllPoints()
            ctx.soloEntry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", curX + ctx.soloIconOffX - puiCX, curY + ctx.soloIconOffY - puiCY)
            SaveIconPos(ctx.soloEntry.icon)
            if ctx.soloEntry.icon.onMove then ctx.soloEntry.icon.onMove(ctx.soloEntry.icon.db) end
            RepositionCtrlChildren(ctx.soloEntry.icon.globalID)
            ctx.soloEntry = nil
            if IsEditModeActive() then
                shmIcons:EnterEditMode()
            end
            return
        end

        local cx, cy = self:GetCenter()
        for _, entry in ipairs(ctx.offsets) do
            if HasEntryFrame(entry) then
                entry.icon.frame:ClearAllPoints()
                entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER", cx + entry.offsetX - puiCX, cy + entry.offsetY - puiCY)
                SaveIconPos(entry.icon)
                if entry.icon.onMove then entry.icon.onMove(entry.icon.db) end
            end
        end
        for _, entry in ipairs(ctx.offsets) do
            if entry and entry.icon and entry.icon.globalID then
                RepositionCtrlChildren(entry.icon.globalID)
            end
        end
        if IsEditModeActive() then
            shmIcons:EnterEditMode()
        end
    end)

    ctx.frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and IsEditModeActive() then ctx.clickPending = true end
    end)

    ctx.frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and ctx.clickPending then
            ctx.clickPending = false
            shmIcons_OpenEditModeGroupSettings(ctx)
        end
    end)
end
