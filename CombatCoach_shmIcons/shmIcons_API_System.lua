-- shmIcons_API_System.lua
-- System/control API methods.

function shmIcons:IsEnabled(addonName, id)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return false end
    return icon.enabled == true
end

function shmIcons:ToggleEnabled(addonName, id)
    local cur = shmIcons:IsEnabled(addonName, id)
    return shmIcons:SetEnabled(addonName, id, not cur)
end

function shmIcons:SetRange(addonName, id, inRange)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if inRange == nil then
        icon.iconTex:SetVertexColor(1, 1, 1, 1)
        return
    end
    icon.iconTex:SetVertexColorFromBoolean(inRange, RANGE_COLOR_IN, RANGE_COLOR_OUT)
end

-- Apply a usability tint overlay (transparent when usable, gray when not).
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
    UpdateInfoFrameVisibility()
    for _, cb in ipairs(lockCallbacks) do
        local ok, err = pcall(cb, isLocked)
        if not ok then
            print("shmIcons: lock callback error: " .. tostring(err))
        end
    end
    return isLocked
end

function shmIcons:IsLocked()
    return isLocked
end

-- /shm lock: canonical lock toggle for all shmIcons icons.
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
