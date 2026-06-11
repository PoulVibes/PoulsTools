-- shmIcons_API.lua
-- Public icon API and slash command.

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
    if db.enabled == nil then db.enabled = true end

    local icon = BuildIconFrame(globalID, db)
    icon.enabled = (db.enabled == true)
    icon.onMove              = callbacks and callbacks.onMove
    icon.onResize             = callbacks and callbacks.onResize
    icon.isNameplateManaged   = callbacks and callbacks.isNameplateManaged == true
    icons[globalID] = icon
    ApplyLockState(icon)
    if icon.enabled == false then
        icon.frame:Hide()
    end
    return icon
end

-- Restore snap groups (no-op; snap groups removed).
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
    if not icon then return end
    if textureID ~= icon.currentTextureID then
        icon.currentTextureID = textureID
        icon.iconTex:SetTexture(textureID or 134400)
    end
    if icon.displayHotkey and icon.hotkeyLabel then
        if textureID then
            local key = nil
            if type(LookupHotkeyForTexture) == "function" then
                key = LookupHotkeyForTexture(textureID)
            end
            if key then
                if key ~= icon.currentHotkey then
                    icon.currentHotkey = key
                    icon.hotkeyLabel:SetText(key)
                    icon.hotkeyLabel:Show()
                end
            else
                icon.currentHotkey = nil
                icon.hotkeyLabel:SetText("")
                icon.hotkeyLabel:Hide()
            end
        else
            icon.currentHotkey = nil
            icon.hotkeyLabel:SetText("")
            icon.hotkeyLabel:Hide()
        end
    end
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

-- Show the per-charge recharge timer on the secondary cooldown frame.
function shmIcons:SetChargeCooldown(addonName, id, durationObject)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if durationObject then
        icon.cd2:SetCooldownFromDurationObject(durationObject)
        icon.cd2:Hide()
    else
        icon.cd2:Clear()
    end
end

-- Reverse (or un-reverse) the cooldown swipe direction for an icon.
function shmIcons:SetCooldownReverse(addonName, id, reverse)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if icon then icon.cd:SetReverse(reverse and true or false) end
end

-- Show or hide the countdown numbers and swipe on the cooldown frame for an icon.
function shmIcons:SetHideCooldownText(addonName, id, hide)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    local show = not (hide and true or false)
    icon.cd:SetHideCountdownNumbers(not show)
    icon.cd:SetDrawSwipe(show)
    icon.cd:SetDrawEdge(show)
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

function shmIcons:SetDisplayName(addonName, id, displayName)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    icon.db.spellName = displayName
end

-- Enable or disable hotkey display for a specific icon.
function shmIcons:SetDisplayHotkey(addonName, id, enabled)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    icon.displayHotkey = (enabled == true)
    if not icon.displayHotkey and icon.hotkeyLabel then
        icon.hotkeyLabel:SetText("")
        icon.hotkeyLabel:Hide()
    end
end

function shmIcons:SetStacks(addonName, id, count)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end

    if count then
        icon.stackLabel:SetText(tostring(count))
        icon.stackLabel:Show()
        icon.stackLabel:SetAlpha(count)
    else
        icon.stackLabel:SetText("")
        icon.stackLabel:SetAlpha(0)
        icon.stackLabel:Hide()
    end
end

function shmIcons:SetVisible(addonName, id, visible)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    if not icon.enabled then
        icon.frame:Hide()
        return
    end
    if icon.isNameplateManaged then
        if visible then icon.frame:Show() else icon.frame:Hide() end
        return
    end
    if not isLocked or isInEditMode then
        icon.frame:Show()
        return
    end
    if visible then icon.frame:Show() else icon.frame:Hide() end
end

function shmIcons:SetEnabled(addonName, id, enabled)
    local icon = icons[addonName .. ":" .. tostring(id)]
    if not icon then return end
    icon.enabled = (enabled == true)
    icon.db.enabled = icon.enabled
    if not icon.enabled then
        icon.frame:Hide()
        icon.cd:Clear()
        icon.cd2:Clear()
        icon.stackLabel:SetText("")
        icon.stackLabel:Hide()
        icon.glow:Hide()
        icon.usableOverlay:SetVertexColor(0,0,0,0)
    else
        if not isLocked then
            if icon.glowEnabled then icon.glow:Show() end
            ApplyLockState(icon)
        else
            ApplyLockState(icon)
        end
    end
    return icon.enabled
end
