-- shmIcons: shared icon/cooldown/glow/snap library for CombatCoach addons.

if shmIcons then return end

shmIcons = {}

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

-- Usability overlay colors (true=usable=transparent, false=unusable=gray)
local USABLE_COLOR_YES = CreateColor(0.0, 0.0, 0.0, 0.0)
local USABLE_COLOR_NO  = CreateColor(0.4, 0.4, 0.4, 0.6)

local CORNER_COORDS = {
    { point = "TOPLEFT",     x = -1, y =  1 },
    { point = "TOPRIGHT",    x =  1, y =  1 },
    { point = "BOTTOMLEFT",  x = -1, y = -1 },
    { point = "BOTTOMRIGHT", x =  1, y = -1 },
}

-- Reactive addons shown during Edit Mode for positioning but hidden on exit.
local EDIT_MODE_REACTIVE_ADDONS = {
    ["Combo Tracker"]        = true,
    ["On Use Tracker"]       = true,
    ["Spell Glow Tracker"]   = true,
    ["Dynamic Buff Tracker"] = true,
}

local icons          = {}  -- icons[globalID] = icon object
local snapNeighbours = {}  -- (unused) kept for API compatibility
local isLocked       = true
local lockCallbacks       = {}  -- functions called when lock state changes: fn(isLocked)
local isInEditMode        = false  -- true while WoW Edit Mode is active
local editModeGroupFrames = {}  -- group overlay frames built on Edit Mode enter

local hotkeyCache    = {}     -- [textureID] = shortened key string (populated by BuildHotkeyMap)
local hotkeyMapBuilt = false  -- true once the first full action-bar scan has completed

function shmIcons:RegisterLockCallback(fn)
    if type(fn) ~= "function" then return end
    table.insert(lockCallbacks, fn)
end

function shmIcons:UnregisterLockCallback(fn)
    for i, f in ipairs(lockCallbacks) do
        if f == fn then
            table.remove(lockCallbacks, i)
            return
        end
    end
end
-- Informational frame: shown when unlocked and not in combat.
local infoFrame = CreateFrame("Frame", "shmIconsInfoFrame", UIParent, "BackdropTemplate")
infoFrame:SetPoint("TOP", UIParent, "TOP", 0, -140)
infoFrame:SetFrameStrata("HIGH")
infoFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
})
infoFrame:SetBackdropColor(0, 0, 0, 0.6)

local titleFS = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local bodyFS  = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleFS:SetFont(FONT_PATH, 14, FONT_FLAGS)
bodyFS:SetFont(FONT_PATH, 13, FONT_FLAGS)
bodyFS:SetJustifyH("LEFT")
bodyFS:SetJustifyV("TOP")
bodyFS:SetWordWrap(true)

local lockBtn = CreateFrame("Button", "shmIconsInfoLockBtn", infoFrame, "UIPanelButtonTemplate")
lockBtn:SetSize(100, 22)
lockBtn:SetText("Lock")
lockBtn:SetScript("OnClick", function()
    if not isLocked then
        shmIcons:ToggleLock()
    end
    infoFrame:Hide()
end)

local function LayoutInfoFrame()
    local linesTitle = "CombatCoach Icons Unlocked:"
    local bodyText = table.concat({
        "- Left Click = Drag move / Corner Resize (edge-snap to same-size icons)",
        "- Right Click = Group drag (drag all adjacent same-size icons together)",
        "- Shift = Live resize to nearest icon size while dragging",
        "- Ctrl = Corner-attach: shrink and attach to corner while dragging",
    }, "\n")

    titleFS:SetText(linesTitle)
    bodyFS:SetText(bodyText)

    local paddingX = 12
    local paddingY = 8
    local spacing  = 4

    local naturalW = math.max(titleFS:GetStringWidth(), bodyFS:GetStringWidth())
    local uiWidth = UIParent:GetWidth() or 1024
    local maxAllowed = math.max(200, uiWidth - 60)
    local width = math.min(math.ceil(naturalW + paddingX * 2), maxAllowed)

    local btnW = (lockBtn and lockBtn:GetWidth()) or 100
    if width < btnW + paddingX * 2 then
        width = math.min(maxAllowed, btnW + paddingX * 2)
    end

    bodyFS:SetWidth(width - paddingX * 2)
    local titleH = math.ceil(titleFS:GetStringHeight())
    local bodyH  = math.ceil(bodyFS:GetStringHeight())
    local btnH   = (lockBtn and lockBtn:GetHeight()) or 22

    local totalH = paddingY * 2 + titleH + spacing + bodyH + spacing + btnH
    infoFrame:SetSize(width, totalH)

    titleFS:ClearAllPoints()
    titleFS:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", paddingX, -paddingY)
    bodyFS:ClearAllPoints()
    bodyFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -spacing)

    if lockBtn then
        lockBtn:ClearAllPoints()
        lockBtn:SetPoint("BOTTOM", infoFrame, "BOTTOM", 0, paddingY)
    end
end

local function UpdateInfoFrameVisibility()
    if isLocked or InCombatLockdown() then
        infoFrame:Hide()
    else
        LayoutInfoFrame()
        infoFrame:Show()
    end
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if infoFrame:IsShown() then
            infoFrame._wasShownBeforeCombat = true
        else
            infoFrame._wasShownBeforeCombat = false
        end
        infoFrame:Hide()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not isLocked then
            LayoutInfoFrame()
            infoFrame:Show()
        end
    else
        UpdateInfoFrameVisibility()
    end
end)

UpdateInfoFrameVisibility()

-- Snap groups removed; keep stubs for compatibility.
local function GetSnapDB()
    return {}
end
local function SaveSnapGroups() end

local function LinkSnap(a, b) end
local function UnlinkSnap(id) end
local function GetSnapGroup(startID) return { startID } end

-- Returns the WoW binding action name for a given action bar slot (1-96).
local function GetBindingActionForActionSlot(slot)
    if slot >= 1  and slot <= 12 then return "ACTIONBUTTON"          .. slot        end
    if slot >= 13 and slot <= 24 then return "MULTIACTIONBAR5BUTTON" .. (slot - 12) end
    if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR4BUTTON" .. (slot - 24) end
    if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR3BUTTON" .. (slot - 36) end
    if slot >= 49 and slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. (slot - 48) end
    if slot >= 61 and slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. (slot - 60) end
    if slot >= 73 and slot <= 84 then return "MULTIACTIONBAR6BUTTON" .. (slot - 72) end
    if slot >= 85 and slot <= 96 then return "MULTIACTIONBAR7BUTTON" .. (slot - 84) end
    return nil
end

-- Shorten a WoW binding key string for compact display (SHIFT-1 → S+1).
local function ShortenHotkey(key)
    if not key then return nil end
    local hasCtrl  = key:find("CTRL%-")  ~= nil
    local hasAlt   = key:find("ALT%-")   ~= nil
    local hasShift = key:find("SHIFT%-") ~= nil
    local base = key:gsub("CTRL%-", ""):gsub("ALT%-", ""):gsub("SHIFT%-", ""):gsub("BUTTON", "B")
    local mods = (hasCtrl and "C+" or "") .. (hasAlt and "A+" or "") .. (hasShift and "S+" or "")
    return mods ~= "" and (mods .. base) or base
end

-- Look up the hotkey for a texture ID; falls back to a live scan if map not ready.
local function LookupHotkeyForTexture(textureID)
    if not textureID then return nil end
    if hotkeyMapBuilt then
        return hotkeyCache[textureID] or nil
    end
    local cached = hotkeyCache[textureID]
    if cached ~= nil then return cached or nil end
    for slot = 1, 60 do
        if C_ActionBar.HasAction(slot) then
            local tex = (C_ActionBar.GetActionTexture and C_ActionBar.GetActionTexture(slot))
                     or (GetActionTexture and GetActionTexture(slot))
            if tex == textureID then
                local bindingAction = GetBindingActionForActionSlot(slot)
                if bindingAction then
                    local key = GetBindingKey(bindingAction)
                    if key then
                        local short = ShortenHotkey(key)
                        hotkeyCache[textureID] = short
                        return short
                    end
                end
            end
        end
    end
    hotkeyCache[textureID] = false
    return nil
end

-- Scan all action bar slots and build the textureID→hotkey map.
local function BuildHotkeyMap()
    hotkeyCache    = {}
    hotkeyMapBuilt = false
    for slot = 1, 96 do
        if C_ActionBar.HasAction(slot) then
            local tex = (C_ActionBar.GetActionTexture and C_ActionBar.GetActionTexture(slot))
                     or (GetActionTexture and GetActionTexture(slot))
            if tex and not hotkeyCache[tex] then
                local bindingAction = GetBindingActionForActionSlot(slot)
                if bindingAction then
                    local key = GetBindingKey(bindingAction)
                    if key then
                        hotkeyCache[tex] = ShortenHotkey(key)
                    end
                end
            end
        end
    end
    hotkeyMapBuilt = true
    for _, icon in pairs(icons) do
        if icon.displayHotkey and icon.hotkeyLabel and icon.currentTextureID then
            local key = hotkeyCache[icon.currentTextureID]
            if key then
                icon.hotkeyLabel:SetText(key)
                icon.hotkeyLabel:Show()
            else
                icon.hotkeyLabel:SetText("")
                icon.hotkeyLabel:Hide()
            end
        end
    end
end

-- Rebuild hotkey map on login and whenever bars or bindings change.
local hotkeyEventFrame = CreateFrame("Frame")
hotkeyEventFrame:RegisterEvent("PLAYER_LOGIN")
hotkeyEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
hotkeyEventFrame:RegisterEvent("UPDATE_BINDINGS")
hotkeyEventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
hotkeyEventFrame:SetScript("OnEvent", function() BuildHotkeyMap() end)

local function ScaleText(cd, stackLabel, size)
    local coach = math.max(FONT_MIN_PT, math.floor(size * FONT_RATIO))
    for _, region in next, { cd:GetRegions() } do
        if region:GetObjectType() == "FontString" then
            region:SetFont(FONT_PATH, coach, FONT_FLAGS)
        end
    end
    if stackLabel then stackLabel:SetFont(FONT_PATH, coach, FONT_FLAGS) end
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

-- Reposition all ctrl corner-attached icons that belong to the given parent.
local function RepositionCtrlChildren(parentGlobalID)
    local parentIcon = icons[parentGlobalID]
    if not parentIcon then return end
    local pCX, pCY   = parentIcon.frame:GetCenter()
    local uiCX, uiCY = UIParent:GetCenter()
    for childID, childIcon in pairs(icons) do
        if childIcon.db.ctrlAttachedTo == parentGlobalID then
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

-- Single edit-mode settings window; only one allowed open at a time.
local editModeSettingsWindow = nil

local function CloseEditModeSettingsWindow()
    if editModeSettingsWindow then
        editModeSettingsWindow:Hide()
        editModeSettingsWindow = nil
    end
end

-- BFS: return all connected groups of adjacent same-size shown icons.
local function ComputeIconGroups()
    local visited = {}
    local groups  = {}
    for startID, startIcon in pairs(icons) do
        if not visited[startID] and startIcon.frame:IsShown()
           and not startIcon.isNameplateManaged then
            local mySize        = math.floor(startIcon.frame:GetWidth() + 0.5)
            local startCX, startCY = startIcon.frame:GetCenter()
            visited[startID]    = true
            local group = { startIcon }
            local queue = { { cx = startCX, cy = startCY } }

            while #queue > 0 do
                local curr = table.remove(queue, 1)
                for otherID, other in pairs(icons) do
                    if not visited[otherID] and other.frame:IsShown()
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

-- Build a draggable Edit Mode overlay frame covering all icons in a group.
local function BuildEditModeGroupFrame(group)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, icon in ipairs(group) do
        local cx, cy = icon.frame:GetCenter()
        local half   = icon.frame:GetWidth() * 0.5
        minX = math.min(minX, cx - half)
        minY = math.min(minY, cy - half)
        maxX = math.max(maxX, cx + half)
        maxY = math.max(maxY, cy + half)
    end

    local PAD    = 6
    local uiCX, uiCY = UIParent:GetCenter()
    local grpCX  = (minX + maxX) * 0.5
    local grpCY  = (minY + maxY) * 0.5

    local offsets = {}
    for _, icon in ipairs(group) do
        local cx, cy = icon.frame:GetCenter()
        offsets[#offsets + 1] = {
            icon    = icon,
            offsetX = cx - grpCX,
            offsetY = cy - grpCY,
        }
    end

    local groupIDSet = {}
    for _, icon in ipairs(group) do
        groupIDSet[icon.globalID] = true
    end
    local mySize = math.floor(group[1].frame:GetWidth() + 0.5)

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize((maxX - minX) + PAD * 2, (maxY - minY) + PAD * 2)
    f:SetPoint("CENTER", UIParent, "CENTER", grpCX - uiCX, grpCY - uiCY)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:EnableMouse(true)

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.1, 0.5, 1.0, 0.12)
    f:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOM", f, "TOP", 0, 2)
    label:SetFont(FONT_PATH, 11, FONT_FLAGS)
    label:SetText(#group == 1 and "Icon" or (#group .. " Icons"))
    label:SetTextColor(0.3, 0.8, 1.0, 1.0)

    local isDragging    = false
    local isSnapFrozen  = false
    local cursorOffX    = 0
    local cursorOffY    = 0
    local soloEntry     = nil
    local soloIconOffX  = 0
    local soloIconOffY  = 0
    local clickPending  = false

    -- Opens a settings panel for this group's icons.
    local function OpenSettingsWindow()
        CloseEditModeSettingsWindow()

        local currentSize = mySize

        local half0 = currentSize * 0.5
        local minCX0, minCY0 =  math.huge,  math.huge
        local maxCX0, maxCY0 = -math.huge, -math.huge
        for _, entry in ipairs(offsets) do
            local cx, cy = entry.icon.frame:GetCenter()
            minCX0 = math.min(minCX0, cx - half0)
            minCY0 = math.min(minCY0, cy - half0)
            maxCX0 = math.max(maxCX0, cx + half0)
            maxCY0 = math.max(maxCY0, cy + half0)
        end
        local fixedGCX = (minCX0 + maxCX0) * 0.5
        local fixedGCY = (minCY0 + maxCY0) * 0.5
        for _, entry in ipairs(offsets) do
            entry.nx = (currentSize > 0) and (entry.offsetX / currentSize) or 0
            entry.ny = (currentSize > 0) and (entry.offsetY / currentSize) or 0
        end

        local win = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        win:SetSize(300, 100)
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
        win:SetFrameStrata("TOOLTIP")
        win:SetFrameLevel(100)
        win:SetMovable(true)
        win:SetClampedToScreen(true)
        win:EnableMouse(true)
        win:RegisterForDrag("LeftButton")
        win:SetScript("OnDragStart", function(self) self:StartMoving() end)
        win:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
        win:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        win:SetBackdropColor(0.05, 0.05, 0.12, 0.95)
        win:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)

        win:SetScript("OnHide", function()
            if editModeSettingsWindow == win then
                editModeSettingsWindow = nil
            end
        end)

        local title = win:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_PATH, 12, FONT_FLAGS)
        title:SetPoint("TOP", win, "TOP", 0, -12)
        title:SetText(#group == 1 and "Icon Settings" or (#group .. " Icon Group Settings"))
        title:SetTextColor(0.3, 0.8, 1.0, 1.0)

        local closeBtn = CreateFrame("Button", nil, win)
        closeBtn:SetSize(22, 22)
        closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
        closeBtn:EnableMouse(true)
        local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY")
        closeLabel:SetFont(FONT_PATH, 16, FONT_FLAGS)
        closeLabel:SetText("x")
        closeLabel:SetTextColor(0.7, 0.2, 0.2, 1.0)
        closeLabel:SetAllPoints(closeBtn)
        closeBtn:SetScript("OnEnter", function() closeLabel:SetTextColor(1.0, 0.5, 0.5, 1.0) end)
        closeBtn:SetScript("OnLeave", function() closeLabel:SetTextColor(0.7, 0.2, 0.2, 1.0) end)
        closeBtn:SetScript("OnClick", function()
            CloseEditModeSettingsWindow()
            shmIcons:EnterEditMode()
        end)

        local sizeLabel = win:CreateFontString(nil, "OVERLAY")
        sizeLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
        sizeLabel:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -52)
        sizeLabel:SetText("Size:")
        sizeLabel:SetTextColor(1, 1, 1, 1)

        local slider = CreateFrame("Slider", nil, win, "BackdropTemplate")
        slider:SetOrientation("HORIZONTAL")
        slider:SetPoint("LEFT", sizeLabel, "RIGHT", 8, 0)
        slider:SetSize(190, 16)
        slider:SetMinMaxValues(MIN_SIZE, MAX_SIZE)
        slider:SetValueStep(1)

        local thumb = slider:CreateTexture(nil, "OVERLAY")
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        thumb:SetSize(32, 18)
        slider:SetThumbTexture(thumb)
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
            edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
            edgeSize = 8,
            insets   = { left = 3, right = 3, top = 6, bottom = 6 },
        })

        local sizeValue = win:CreateFontString(nil, "OVERLAY")
        sizeValue:SetFont(FONT_PATH, 11, FONT_FLAGS)
        sizeValue:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        sizeValue:SetText(tostring(currentSize))
        sizeValue:SetTextColor(1, 1, 1, 1)

        slider:SetScript("OnValueChanged", function(self, value)
            local newSize = math.max(MIN_SIZE, math.min(math.floor(value + 0.5), MAX_SIZE))
            if newSize == currentSize then return end

            local uiCX, uiCY = UIParent:GetCenter()
            currentSize = newSize
            sizeValue:SetText(tostring(newSize))

            for _, entry in ipairs(offsets) do
                entry.offsetX = entry.nx * newSize
                entry.offsetY = entry.ny * newSize
                entry.icon.frame:SetSize(newSize, newSize)
                entry.icon.frame:ClearAllPoints()
                entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                    fixedGCX + entry.offsetX - uiCX,
                    fixedGCY + entry.offsetY - uiCY)
                SaveIconPos(entry.icon)
                if entry.icon.onMove then entry.icon.onMove(entry.icon.db) end
            end

            for _, entry in ipairs(offsets) do
                RepositionCtrlChildren(entry.icon.globalID)
            end

            mySize = newSize

            local half2 = newSize * 0.5
            local minX2, minY2 =  math.huge,  math.huge
            local maxX2, maxY2 = -math.huge, -math.huge
            for _, entry in ipairs(offsets) do
                local icx = fixedGCX + entry.offsetX
                local icy = fixedGCY + entry.offsetY
                minX2 = math.min(minX2, icx - half2)
                minY2 = math.min(minY2, icy - half2)
                maxX2 = math.max(maxX2, icx + half2)
                maxY2 = math.max(maxY2, icy + half2)
            end
            local PAD2 = 6
            f:SetSize((maxX2 - minX2) + PAD2 * 2, (maxY2 - minY2) + PAD2 * 2)
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER",
                (minX2 + maxX2) * 0.5 - uiCX,
                (minY2 + maxY2) * 0.5 - uiCY)
        end)

        slider:SetValue(currentSize)

        editModeSettingsWindow = win
        win:Show()
    end

    f:SetScript("OnDragStart", function(self)
        clickPending = false
        isDragging   = true
        isSnapFrozen = false
        local rawX, rawY = GetCursorPosition()
        local uiScale    = UIParent:GetEffectiveScale()
        local curX       = rawX / uiScale
        local curY       = rawY / uiScale
        local cx, cy     = self:GetCenter()
        cursorOffX = cx - curX
        cursorOffY = cy - curY

        if IsShiftKeyDown() and #offsets > 1 then
            local bestDist = math.huge
            soloEntry = nil
            for _, entry in ipairs(offsets) do
                local icx, icy = entry.icon.frame:GetCenter()
                local d = math.sqrt((curX - icx)^2 + (curY - icy)^2)
                if d < bestDist then
                    bestDist     = d
                    soloEntry    = entry
                    soloIconOffX = icx - curX
                    soloIconOffY = icy - curY
                end
            end
            if soloEntry then
                soloEntry.icon.db.ctrlAttachedTo = nil
                soloEntry.icon.db.ctrlOffsetX    = nil
                soloEntry.icon.db.ctrlOffsetY    = nil
                f:SetBackdropBorderColor(1.0, 0.8, 0.2, 1.0)
            end
        else
            for _, entry in ipairs(offsets) do
                entry.icon.db.ctrlAttachedTo = nil
                entry.icon.db.ctrlOffsetX    = nil
                entry.icon.db.ctrlOffsetY    = nil
            end
            soloEntry = nil
        end

        self:StartMoving()
    end)

    f:SetScript("OnUpdate", function(self)
        if not isDragging then return end

        local rawX, rawY = GetCursorPosition()
        local uiScale    = UIParent:GetEffectiveScale()
        local curX       = rawX / uiScale
        local curY       = rawY / uiScale
        local puiCX, puiCY = UIParent:GetCenter()

        if soloEntry then
            soloEntry.icon.frame:ClearAllPoints()
            soloEntry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                curX + soloIconOffX - puiCX,
                curY + soloIconOffY - puiCY)
            return
        end

        local virtualCX = curX + cursorOffX
        local virtualCY = curY + cursorOffY

        if IsShiftKeyDown() then
            do
                local nearestDist = math.huge
                local nearestSize = nil
                for _, entry in ipairs(offsets) do
                    local memberCX = virtualCX + entry.offsetX
                    local memberCY = virtualCY + entry.offsetY
                    for otherID, other in pairs(icons) do
                        if not groupIDSet[otherID] and other.frame:IsShown()
                           and not other.db.ctrlAttachedTo then
                            local oCX, oCY = other.frame:GetCenter()
                            local d = math.sqrt((memberCX - oCX)^2 + (memberCY - oCY)^2)
                            if d < nearestDist then
                                nearestDist = d
                                nearestSize = math.floor(other.frame:GetHeight() + 0.5)
                            end
                        end
                    end
                end
                if nearestSize and nearestSize ~= mySize then
                    local scale = nearestSize / mySize
                    for _, entry in ipairs(offsets) do
                        entry.offsetX = entry.offsetX * scale
                        entry.offsetY = entry.offsetY * scale
                        entry.icon.frame:SetSize(nearestSize, nearestSize)
                    end
                    mySize = nearestSize
                    isSnapFrozen = false
                end
            end

            local bestDist  = math.huge
            local bestSnapCX, bestSnapCY = nil, nil

            for _, entry in ipairs(offsets) do
                local memberCX = virtualCX + entry.offsetX
                local memberCY = virtualCY + entry.offsetY
                for otherID, other in pairs(icons) do
                    if not groupIDSet[otherID] and other.frame:IsShown()
                       and not other.db.ctrlAttachedTo
                       and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
                        local oCX, oCY = other.frame:GetCenter()
                        for dx = -1, 1 do
                            for dy = -1, 1 do
                                if not (dx == 0 and dy == 0) then
                                    local posX = oCX + dx * mySize
                                    local posY = oCY + dy * mySize
                                    local dist = math.sqrt((memberCX - posX)^2 + (memberCY - posY)^2)
                                    if dist < SNAP_THRESHOLD and dist < bestDist then
                                        bestDist  = dist
                                        -- Shift the whole group so this member lands at posX/posY
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
                if not isSnapFrozen then
                    self:StopMovingOrSizing()
                    isSnapFrozen = true
                end
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER",
                    bestSnapCX - puiCX, bestSnapCY - puiCY)
                for _, entry in ipairs(offsets) do
                    entry.icon.frame:ClearAllPoints()
                    entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                        bestSnapCX + entry.offsetX - puiCX,
                        bestSnapCY + entry.offsetY - puiCY)
                end
                return
            end
        end

        if isSnapFrozen then
            isSnapFrozen = false
            self:StartMoving()
            return
        end

        local cx, cy = self:GetCenter()
        for _, entry in ipairs(offsets) do
            entry.icon.frame:ClearAllPoints()
            entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                cx + entry.offsetX - puiCX,
                cy + entry.offsetY - puiCY)
        end
    end)

    f:SetScript("OnDragStop", function(self)
        isDragging   = false
        isSnapFrozen = false
        self:StopMovingOrSizing()
        f:SetBackdropBorderColor(0.3, 0.8, 1.0, 1.0)
        local puiCX, puiCY = UIParent:GetCenter()

        if soloEntry then
            local rawX, rawY = GetCursorPosition()
            local uiScale    = UIParent:GetEffectiveScale()
            local curX = rawX / uiScale
            local curY = rawY / uiScale
            soloEntry.icon.frame:ClearAllPoints()
            soloEntry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                curX + soloIconOffX - puiCX,
                curY + soloIconOffY - puiCY)
            SaveIconPos(soloEntry.icon)
            if soloEntry.icon.onMove then soloEntry.icon.onMove(soloEntry.icon.db) end
            RepositionCtrlChildren(soloEntry.icon.globalID)
            soloEntry = nil
            shmIcons:EnterEditMode()
            return
        end

        local cx, cy = self:GetCenter()
        for _, entry in ipairs(offsets) do
            entry.icon.frame:ClearAllPoints()
            entry.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                cx + entry.offsetX - puiCX,
                cy + entry.offsetY - puiCY)
            SaveIconPos(entry.icon)
            if entry.icon.onMove then entry.icon.onMove(entry.icon.db) end
        end
        for _, entry in ipairs(offsets) do
            RepositionCtrlChildren(entry.icon.globalID)
        end
        shmIcons:EnterEditMode()
    end)

    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then clickPending = true end
    end)

    f:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and clickPending then
            clickPending = false
            OpenSettingsWindow()
        end
    end)

    return f
end

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

    -- Second cooldown frame: DrawSwipe=false shows only the clock hand for charge recharge.
    local cd2 = CreateFrame("Cooldown", "shmIconsCD2_" .. globalID, frame, "CooldownFrameTemplate")
    cd2:SetAllPoints(frame)
    cd2:SetFrameLevel(frame:GetFrameLevel() + 3)  -- just above cd
    cd2:SetReverse(false)
    cd2:SetDrawSwipe(false)   -- no dark overlay
    cd2:SetDrawEdge(true)     -- show the clock hand
    cd2:SetDrawBling(false)
    cd2:SetHideCountdownNumbers(true)

    local labelFrame = CreateFrame("Frame", nil, frame)
    labelFrame:SetAllPoints(frame)
    labelFrame:SetFrameLevel(cd2:GetFrameLevel() + 1)

    local stackLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stackLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO)), FONT_FLAGS)
    stackLabel:SetTextColor(STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B, 1)
    stackLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    stackLabel:SetJustifyH("RIGHT")
    stackLabel:Hide()

    local hotkeyLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hotkeyLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO * 0.4)), FONT_FLAGS)
    hotkeyLabel:SetTextColor(1, 1, 1, 1)
    hotkeyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    hotkeyLabel:SetJustifyH("LEFT")
    hotkeyLabel:Hide()

    local glow = BuildGlow(frame, db.size)

    -- Usability overlay: semi-transparent gray when unusable, transparent when usable.
    local usableOverlay = frame:CreateTexture(nil, "OVERLAY")
    usableOverlay:SetAllPoints(frame)
    usableOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    usableOverlay:SetVertexColor(0, 0, 0, 0)

    local resizeHandle = CreateFrame("Button", nil, frame)
    local initHandleSz = math.max(10, math.floor(db.size * 0.25))
    resizeHandle:SetSize(initHandleSz, initHandleSz)
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
        hotkeyLabel      = hotkeyLabel,
        displayHotkey    = false,
        currentTextureID = nil,
        glow             = glow,
        usableOverlay  = usableOverlay,
        resizeHandle   = resizeHandle,
        glowEnabled    = db.glow_enabled,
        groupDragFrame = nil,
    }

    frame:SetScript("OnSizeChanged", function(self, width, height)
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

    local dragState = nil

    -- Apply a snap candidate immediately (called live from OnUpdate).
    local function ApplySnap(candidate, isCtrl)
        dragState.sizeAtSnapEnter = frame:GetWidth()
        frame:StopMovingOrSizing()
        if isCtrl then
            local cornerSize = math.max(MIN_SIZE, math.floor(candidate.targetSize * 0.35))
            frame:SetSize(cornerSize, cornerSize)
            ScaleText(cd, stackLabel, cornerSize)
            ResizeGlow(icon.glow, frame, cornerSize)
            frame:SetFrameStrata("HIGH")
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
        else
            frame:SetFrameStrata("MEDIUM")
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", candidate.cx, candidate.cy)
        end
    end

    -- Revert live snap changes (size/strata) made during dragging.
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
                if otherID ~= globalID and other.frame:IsShown()
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

        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", myCX - uiCX, myCY - uiCY)
    end

    -- Find snap candidate for the dragged icon (ctrl=corner-attach, default=edge-align).
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

            for otherID, other in pairs(icons) do
                if otherID ~= globalID and other.frame:IsShown()
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
                if otherID ~= globalID and other.frame:IsShown()
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
            if otherID ~= globalID and other.frame:IsShown()
               and not other.isNameplateManaged
               and not other.db.ctrlAttachedTo
               and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
                local oCX, oCY = other.frame:GetCenter()
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        if not (dx == 0 and dy == 0) then  -- skip: would overlap target
                            local posX = oCX + dx * mySize
                            local posY = oCY + dy * mySize
                            local dist = math.sqrt((myCX - posX)^2 + (myCY - posY)^2)
                            if dist < SNAP_THRESHOLD and dist < bestDist then                                bestDist = dist
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
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX    = nil
            db.ctrlOffsetY    = nil
            dragState = {
                originalSize  = frame:GetWidth(),
                currentSnapID = nil,
            }
            self:StartMoving()

            local soloUpdateFrame = CreateFrame("Frame")
            icon.groupDragFrame = soloUpdateFrame

            soloUpdateFrame:SetScript("OnUpdate", function()
                local rawX, rawY = GetCursorPosition()
                local uiScale    = UIParent:GetEffectiveScale()
                local myCX = rawX / uiScale
                local myCY = rawY / uiScale
                local mySize     = frame:GetWidth()
                local isCtrl     = IsControlKeyDown()

                if IsShiftKeyDown() then
                    local nearestDist = math.huge
                    local nearestSize = nil
                    for otherID, other in pairs(icons) do
                        if otherID ~= globalID and other.frame:IsShown()
                           and not other.isNameplateManaged then
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
                        dragState.currentSnapID = nil
                    end
                end

                local searchSize = (isCtrl and dragState.sizeAtSnapEnter) or mySize
                local candidate = FindSnapCandidate(myCX, myCY, searchSize, isCtrl)

                if candidate then
                    if dragState.currentSnapID ~= candidate.targetID
                       or dragState.pendingCtrl ~= isCtrl then
                        dragState.currentSnapID = candidate.targetID
                        dragState.pendingSnap   = candidate
                        dragState.pendingCtrl   = isCtrl
                        ApplySnap(candidate, isCtrl)
                    end
                else
                    if dragState.currentSnapID then
                        dragState.currentSnapID = nil
                        dragState.pendingSnap   = nil
                        RevertSnap()
                        self:StopMovingOrSizing()
                        self:StartMoving()
                    end
                end
            end)

        elseif button == "RightButton" then
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX    = nil
            db.ctrlOffsetY    = nil
            local mySize         = frame:GetWidth()
            local initCX, initCY = frame:GetCenter()
            local uiCX, uiCY     = UIParent:GetCenter()

            local groupMembers = {}
            local visited = { [globalID] = true }
            local queue   = { { id = globalID, cx = initCX, cy = initCY } }

            while #queue > 0 do
                local curr = table.remove(queue, 1)
                for otherID, other in pairs(icons) do
                    if not visited[otherID] and other.frame:IsShown()
                       and not other.db.ctrlAttachedTo
                       and math.abs(other.frame:GetHeight() - mySize) < 0.5 then
                        local ocx, ocy = other.frame:GetCenter()
                        local adx = math.abs(ocx - curr.cx)
                        local ady = math.abs(ocy - curr.cy)
                        if adx <= mySize + 4 and ady <= mySize + 4
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
        if icon.groupDragFrame then
            icon.groupDragFrame:SetScript("OnUpdate", nil)
            icon.groupDragFrame = nil
        end
        self:StopMovingOrSizing()

        if dragState and dragState.isGroupDrag then
            local finalCX, finalCY     = frame:GetCenter()
            local finalUiCX, finalUiCY = UIParent:GetCenter()
            for _, member in ipairs(dragState.groupMembers) do
                member.icon.frame:ClearAllPoints()
                member.icon.frame:SetPoint("CENTER", UIParent, "CENTER",
                    finalCX + member.offsetX - finalUiCX,
                    finalCY + member.offsetY - finalUiCY)
            end
            SaveIconPos(icon)
            if icon.onMove then icon.onMove(icon.db) end
            RepositionCtrlChildren(globalID)
            for _, member in ipairs(dragState.groupMembers) do
                SaveIconPos(member.icon)
                if member.icon.onMove then member.icon.onMove(member.icon.db) end
                RepositionCtrlChildren(member.icon.globalID)
            end
        elseif dragState and dragState.pendingSnap then
            local snap   = dragState.pendingSnap
            local isCtrl = dragState.pendingCtrl

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
            db.x     = snap.cx
            db.y     = snap.cy
            db.strata = frame:GetFrameStrata()
            if isCtrl then
                db.ctrlAttachedTo = snap.targetID
                local parentIcon = icons[snap.targetID]
                if parentIcon then
                    local pCX, pCY   = parentIcon.frame:GetCenter()
                    local puiCX, puiCY = UIParent:GetCenter()
                    db.ctrlOffsetX = snap.cx - (pCX - puiCX)
                    db.ctrlOffsetY = snap.cy - (pCY - puiCY)
                end
            else
                db.ctrlAttachedTo = nil
                db.ctrlOffsetX    = nil
                db.ctrlOffsetY    = nil
            end
            if icon.onMove then icon.onMove(db) end
            -- Reposition any ctrl children of this icon (it may have been moved).
            RepositionCtrlChildren(globalID)
        else
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX    = nil
            db.ctrlOffsetY    = nil
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
            RepositionCtrlChildren(globalID)
        end

        dragState = nil
    end)

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            db.ctrlAttachedTo = nil
            db.ctrlOffsetX    = nil
            db.ctrlOffsetY    = nil
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

    ApplyLockState(icon)
    return icon
end

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
    icon.iconTex:SetTexture(textureID or 134400)
    if icon.displayHotkey and icon.hotkeyLabel then
        icon.currentTextureID = textureID
        if textureID then
            local key = LookupHotkeyForTexture(textureID)
            if key then
                icon.hotkeyLabel:SetText(key)
                icon.hotkeyLabel:Show()
            else
                icon.hotkeyLabel:SetText("")
                icon.hotkeyLabel:Hide()
            end
        else
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

-- Build (or rebuild) edit-mode group overlay frames for all registered icons.
function shmIcons:EnterEditMode()
    -- Tear down any stale frames from a previous session
    for _, f in ipairs(editModeGroupFrames) do
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnUpdate",    nil)
        f:SetScript("OnDragStop",  nil)
        f:Hide()
    end
    editModeGroupFrames = {}
    isInEditMode = true

    for _, icon in pairs(icons) do
        if icon.enabled then
            icon.frame:Show()
        end
    end

    local groups = ComputeIconGroups()
    for _, group in ipairs(groups) do
        table.insert(editModeGroupFrames, BuildEditModeGroupFrame(group))
    end
end

-- Hide and destroy all edit-mode group overlay frames.
function shmIcons:ExitEditMode()
    isInEditMode = false
    for _, f in ipairs(editModeGroupFrames) do
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnUpdate",    nil)
        f:SetScript("OnDragStop",  nil)
        f:Hide()
    end
    editModeGroupFrames = {}

    CloseEditModeSettingsWindow()

    for globalID, icon in pairs(icons) do
        local addonName = globalID:match("^(.+):.+$")
        if addonName and EDIT_MODE_REACTIVE_ADDONS[addonName] then
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