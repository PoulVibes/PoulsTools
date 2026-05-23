-- shmIcons_EditMode.lua
-- Edit mode grouping, settings window, and edit-mode hooks.

function RepositionCtrlChildren(parentGlobalID)
    local parentIcon = icons[parentGlobalID]
    if not parentIcon or not parentIcon.frame then return end
    local pCX, pCY   = parentIcon.frame:GetCenter()
    local uiCX, uiCY = UIParent:GetCenter()
    for childID, childIcon in pairs(icons) do
        if childIcon and childIcon.frame and childIcon.db and childIcon.db.ctrlAttachedTo == parentGlobalID then
            local newX = (pCX - uiCX) + childIcon.db.ctrlOffsetX
            local newY = (pCY - uiCY) + childIcon.db.ctrlOffsetY
            childIcon.frame:ClearAllPoints()
            childIcon.frame:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
            SaveIconPos(childIcon)
            if childIcon.onMove then childIcon.onMove(childIcon.db) end
            RepositionCtrlChildren(childID)
        end
    end
end

local editModeSettingsWindow = nil
local editModeGroupFramePool = {}

function CloseEditModeSettingsWindow()
    if editModeSettingsWindow then
        editModeSettingsWindow:Hide()
        editModeSettingsWindow = nil
    end
end

function ComputeIconGroups()
    local visited = {}
    local groups  = {}
    for startID, startIcon in pairs(icons) do
        if not visited[startID] and startIcon and startIcon.frame and startIcon.frame:IsShown()
           and not startIcon.isNameplateManaged then
            local mySize        = math.floor(startIcon.frame:GetWidth() + 0.5)
            local startCX, startCY = startIcon.frame:GetCenter()
            visited[startID]    = true
            local group = { startIcon }
            local queue = { { cx = startCX, cy = startCY } }

            while #queue > 0 do
                local curr = table.remove(queue, 1)
                for otherID, other in pairs(icons) do
                    if not visited[otherID] and other and other.frame and other.frame:IsShown()
                       and not other.isNameplateManaged
                       and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
                        local ocx, ocy = other.frame:GetCenter()
                        local adx = math.abs(ocx - curr.cx)
                        local ady = math.abs(ocy - curr.cy)
                        if adx <= mySize + 4 and ady <= mySize + 4
                           and (adx > 2 or ady > 2) then
                            visited[otherID] = true
                            table.insert(group, other)
                            table.insert(queue, { cx = ocx, cy = ocy })
                        end
                    end
                end
            end

            table.insert(groups, group)
        end
    end
    return groups
end

function shmIcons:EnterEditMode()
    -- Tear down any stale frames from a previous session
    for _, f in ipairs(editModeGroupFrames) do
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
        f:SetScript("OnUpdate",    nil)
        f:SetScript("OnDragStop",  nil)
        f:Hide()
        editModeGroupFramePool[#editModeGroupFramePool + 1] = f
    end
    editModeGroupFrames = {}
    isInEditMode = true

    for _, icon in pairs(icons) do
        if icon and icon.frame and icon.enabled then
            icon.frame:Show()
        end
    end

    local groups = ComputeIconGroups()
    for _, group in ipairs(groups) do
        local recycled = table.remove(editModeGroupFramePool)
        table.insert(editModeGroupFrames, BuildEditModeGroupFrame(group, recycled))
    end
end

function shmIcons:ExitEditMode()
    isInEditMode = false
    for _, f in ipairs(editModeGroupFrames) do
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
        f:SetScript("OnUpdate",    nil)
        f:SetScript("OnDragStop",  nil)
        f:Hide()
        editModeGroupFramePool[#editModeGroupFramePool + 1] = f
    end
    editModeGroupFrames = {}

    CloseEditModeSettingsWindow()

    for globalID, icon in pairs(icons) do
        local addonName = globalID:match("^(.+):.+$")
        if addonName and icon and icon.frame and EDIT_MODE_REACTIVE_ADDONS[addonName] then
            icon.frame:Hide()
        end
    end
end

function shmIcons:IsInEditMode()
    return isInEditMode
end

-- Hook WoW Edit Mode panel to auto-sync shmIcons overlays.
do
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("PLAYER_LOGIN")
    hookFrame:SetScript("OnEvent", function(self)
        if EditModeManagerFrame then
            EditModeManagerFrame:HookScript("OnShow", function()
                shmIcons:EnterEditMode()
            end)
            EditModeManagerFrame:HookScript("OnHide", function()
                shmIcons:ExitEditMode()
            end)
            if EditModeManagerFrame:IsShown() then
                shmIcons:EnterEditMode()
            end
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end)
end
