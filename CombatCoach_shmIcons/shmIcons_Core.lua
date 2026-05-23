-- shmIcons_Core.lua
-- Shared state, lock UI, and compatibility stubs for shmIcons.

if shmIcons then return end

shmIcons = {}

FONT_RATIO     = 0.5
FONT_PATH      = "Fonts\\FRIZQT__.TTF"
FONT_FLAGS     = "OUTLINE"
FONT_MIN_PT    = 8
MIN_SIZE       = 16
MAX_SIZE       = 256
SNAP_THRESHOLD = 20

STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B = 1.0, 0.4, 0.7
RANGE_COLOR_IN  = CreateColor(1.0, 1.0, 1.0, 1.0)
RANGE_COLOR_OUT = CreateColor(1.0, 0.0, 0.0, 1.0)
USABLE_COLOR_YES = CreateColor(0.0, 0.0, 0.0, 0.0)
USABLE_COLOR_NO  = CreateColor(0.4, 0.4, 0.4, 0.6)

CORNER_COORDS = {
    { point = "TOPLEFT",     x = -1, y =  1 },
    { point = "TOPRIGHT",    x =  1, y =  1 },
    { point = "BOTTOMLEFT",  x = -1, y = -1 },
    { point = "BOTTOMRIGHT", x =  1, y = -1 },
}

EDIT_MODE_REACTIVE_ADDONS = {
    ["Combo Tracker"]        = true,
    ["On Use Tracker"]       = true,
    ["Spell Glow Tracker"]   = true,
    ["Dynamic Buff Tracker"] = true,
}

icons          = {}
snapNeighbours = {}
isLocked       = true
lockCallbacks       = {}
isInEditMode        = false
editModeGroupFrames = {}

function shmIcons:RegisterLockCallback(fn)
    if type(fn) ~= "function" then return end
    for _, cb in ipairs(lockCallbacks) do
        if cb == fn then return end
    end
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

function LayoutInfoFrame()
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

function UpdateInfoFrameVisibility()
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

function GetSnapDB()
    return {}
end
function SaveSnapGroups() end
function LinkSnap(a, b) end
function UnlinkSnap(id) end
function GetSnapGroup(startID) return { startID } end
