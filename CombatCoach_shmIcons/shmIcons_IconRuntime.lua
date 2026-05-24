-- shmIcons_IconRuntime.lua
-- Icon frame runtime and drag/resize behavior.

function SaveIconPos(icon)
    if not icon or not icon.frame then return end
    local point, _, _, x, y = icon.frame:GetPoint()
    icon.db.point = point
    icon.db.x     = x
    icon.db.y     = y
    icon.db.strata = icon.frame:GetFrameStrata()
end

function ApplyLockState(icon)
    if not icon or not icon.frame then return end
    local frame = icon.frame
    if icon.isNameplateManaged then
        frame:EnableMouse(false)
        frame:SetBackdrop(nil)
        if icon.resizeHandle then icon.resizeHandle:Hide() end
        return
    end
    if isLocked then
        frame:EnableMouse(false)
        frame:SetBackdrop(nil)
        if icon.resizeHandle then icon.resizeHandle:Hide() end
    else
        if icon.enabled then
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton", "RightButton")
            frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            frame:SetBackdropColor(0, 0, 0, 0.5)
            frame:Show()
            if icon.resizeHandle then icon.resizeHandle:Show() end
        else
            frame:EnableMouse(false)
            frame:SetBackdrop(nil)
            frame:Hide()
            if icon.resizeHandle then icon.resizeHandle:Hide() end
        end
    end
end
