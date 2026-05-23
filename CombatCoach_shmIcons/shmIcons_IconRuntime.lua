-- shmIcons_IconRuntime.lua
-- Icon frame runtime and drag/resize behavior.

function SaveIconPos(icon)
    local point, _, _, x, y = icon.frame:GetPoint()
    icon.db.point = point
    icon.db.x     = x
    icon.db.y     = y
    icon.db.strata = icon.frame:GetFrameStrata()
end

function ApplyLockState(icon)
    local frame = icon.frame
    if icon.isNameplateManaged then
        frame:EnableMouse(false)
        frame:SetBackdrop(nil)
        icon.resizeHandle:Hide()
        return
    end
    if isLocked then
        frame:EnableMouse(false)
        frame:SetBackdrop(nil)
        icon.resizeHandle:Hide()
    else
        if icon.enabled then
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton", "RightButton")
            frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            frame:SetBackdropColor(0, 0, 0, 0.5)
            frame:Show()
            icon.resizeHandle:Show()
        else
            frame:EnableMouse(false)
            frame:SetBackdrop(nil)
            frame:Hide()
            icon.resizeHandle:Hide()
        end
    end
end
