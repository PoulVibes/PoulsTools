-- ProcViewer.lua
-- Centered HUD proc icons with spell activation overlay glow.
--
-- Slots:
--   LEFT  : Blackout Kick      (glow event spell ID 100784)
--   RIGHT : Spinning Crane Kick (glow event spell ID 101546, Dance of Chi-Ji proc)
--
-- Slash command:
--   /pv lock   -- toggle lock/unlock mode (out of combat only)
--              Unlock: forces both icons visible, makes them draggable
--              and resizable with a resize handle.
--              Lock: saves positions/sizes and returns to normal proc display.
--
-- Version: 0.1.7
-- Compatible with WoW API 12.0.1 (Midnight)

------------------------------------------------------------------------
-- Saved variables (persisted across sessions by the WoW saved-vars system)
------------------------------------------------------------------------
ProcViewerDB = ProcViewerDB or {}   -- saved per slot: { point, relPoint, x, y, size }

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local ADDON    = "ProcViewer"
local VERSION  = "0.1.7"
local ICON_SIZE_DEFAULT = 64
local GAP               = 8

------------------------------------------------------------------------
-- Global Variables storing when the procs are active
------------------------------------------------------------------------
_G["bok_proc_active"] = false
_G["docj_proc_active"] = false
_G["tod_proc_active"] = false
_G["rwk_proc_active"] = false

------------------------------------------------------------------------
-- Global countdown timers (seconds remaining; 0 when inactive)
-- Updated every frame by the OnUpdate ticker below.
-- tod has no timer — it is not a duration-based proc.
------------------------------------------------------------------------
_G["bok_proc_timer"]  = 0
_G["docj_proc_timer"] = 0
_G["rwk_proc_timer"]  = 0

------------------------------------------------------------------------
-- Glow builder
------------------------------------------------------------------------
local function BuildGlow(parent, iconSize)
    local g = CreateFrame("Frame", nil, parent)
    g:SetAllPoints(parent)
    g:SetFrameLevel(parent:GetFrameLevel() + 5)

    local off = iconSize * 0.1875

    local corners = {
        { point = "TOPLEFT",     x = -off, y =  off },
        { point = "TOPRIGHT",    x =  off, y =  off },
        { point = "BOTTOMLEFT",  x = -off, y = -off },
        { point = "BOTTOMRIGHT", x =  off, y = -off },
    }
	

	g.textures = {}

	for _, c in ipairs(corners) do
		

        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        t:SetSize(iconSize * 1.4, iconSize * 1.4)
        t:SetPoint(c.point, parent, c.point, c.x, c.y)
        t:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
        local ag = t:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(0.3) ; a:SetToAlpha(1.0) ; a:SetDuration(0.6) ; a:SetOrder(1)
        ag:Play()
		table.insert(g.textures, t) -- Save the reference
    end

    return g
end

local function ResizeGlow(glowFrame, newSize)
    -- 1. Scale the offset based on the new size (12 is ~19% of a standard 64px icon)
    local offset = newSize * 0.1875 

    -- 2. Update the textures
    if glowFrame.textures then
        -- We need to know which corner is which to set the new offsets
        local points = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
        
        for i, tex in ipairs(glowFrame.textures) do
            -- Update Size
            tex:SetSize(newSize * 1.4, newSize * 1.4)
            
            -- Update Anchors (re-calculating the x and y)
            local p = points[i]
            local x = (p:find("LEFT") and -offset) or offset
            local y = (p:find("TOP") and offset) or -offset
            
            tex:ClearAllPoints()
            tex:SetPoint(p, glowFrame:GetParent(), p, x, y)
        end
    end
end

------------------------------------------------------------------------
-- Slot factory
-- key        : string key used in ProcViewerDB for saved position/size
-- defaultX/Y : default offset from screen center
-- iconSpellID: spell whose texture fills this slot
-- timerKey   : (optional) _G key of the countdown timer to display;
--              nil = no timer label (used for ToD)
------------------------------------------------------------------------
local function CreateSlot(key, defaultX, defaultY, iconSpellID, timerKey)
    local db = ProcViewerDB[key] or {}

    -- Outer frame
    local hud = CreateFrame("Frame", "ProcViewer_" .. key, UIParent, "BackdropTemplate")
    local size = db.size or ICON_SIZE_DEFAULT
	hud:SetSize(size, size)
    hud:SetFrameStrata("HIGH")
    hud:SetClampedToScreen(true)

    -- Restore saved position or use default
    if db.point then
        hud:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    else
        hud:SetPoint("CENTER", UIParent, "CENTER", defaultX, defaultY)
    end
    hud:Hide()

    -- Icon texture
    local icon = hud:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(hud)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Border
    local border = CreateFrame("Frame", nil, hud, "BackdropTemplate")
    border:SetPoint("TOPLEFT",     hud, "TOPLEFT",     -2,  2)
    border:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT",  2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)

    -- Timer label (only created for slots that have a timerKey)
    local timerText = nil
    if timerKey then
        timerText = hud:CreateFontString(nil, "OVERLAY")
        timerText:SetFont("Fonts\\FRIZQT__.TTF", size * 0.6, "OUTLINE")
        timerText:SetPoint("CENTER", hud, "CENTER", 0, 0)
        timerText:SetTextColor(1, 0.4, 0.8, 1)   -- bright pink
        timerText:SetText("")
    end

    -- Resize handle (bottom-right corner, shown only in edit mode)
    local resizeHandle = CreateFrame("Button", nil, hud)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeHandle:Hide()
    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            hud:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function(self, button)
        hud:StopMovingOrSizing()
        -- Save size
        local w = math.max(24, hud:GetWidth())
        hud:SetSize(w, w)      -- keep square
        ProcViewerDB[key].size = w
    end)

    -- Enable resizing
    hud:SetResizable(true)
    hud:SetResizeBounds(24, 24, 256, 256)
    hud:SetScript("OnSizeChanged", function(self, w, h)
        -- Keep square by enforcing width == height
        local s = math.max(w, h)
        self:SetSize(s, s)
        -- Rescale the timer font to 60% of the new icon size
        if timerText then
            timerText:SetFont("Fonts\\FRIZQT__.TTF", s * 0.6, "OUTLINE")
        end
    end)

    -- Drag support (applied in edit mode)
    hud:SetMovable(true)
    hud:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and self.editMode then
            self:StartMoving()
        end
    end)
    hud:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint(1)
        ProcViewerDB[key] = ProcViewerDB[key] or {}
        ProcViewerDB[key].point    = point
        ProcViewerDB[key].relPoint = relPoint
        ProcViewerDB[key].x        = x
        ProcViewerDB[key].y        = y
    end)

    -- Glow (lazy)
    local glowFrame = nil

    local slot = { hud = hud, resizeHandle = resizeHandle }

    function slot.Show()
        if not glowFrame then
            glowFrame = BuildGlow(hud, hud:GetWidth())
        else
            ResizeGlow(glowFrame, hud:GetWidth())
        end
        glowFrame:SetAlpha(0.85)
        icon:SetTexture(C_Spell.GetSpellTexture(iconSpellID))
        glowFrame:Show()
        hud:Show()
    end

    function slot.Hide()
        if glowFrame then glowFrame:Hide() end
        if timerText then timerText:SetText("") end
        hud:Hide()
    end

    -- Called each ticker frame to refresh the displayed time.
    -- t is the current remaining seconds (a float).
    function slot.UpdateTimer(t)
        if not timerText then return end
        if t > 0 then
            timerText:SetText(string.format("%d", math.ceil(t)))
        else
            timerText:SetText("")
        end
    end

    -- Called when entering edit mode: show frame with label, enable drag/resize
    function slot.SetEditMode(enabled)
        hud.editMode = enabled
        resizeHandle:SetShown(enabled)
        hud:EnableMouse(enabled)
        if enabled then
            -- Force visible with a semi-transparent tint so the player can see it
            icon:SetTexture(C_Spell.GetSpellTexture(iconSpellID))
            if glowFrame then glowFrame:Hide() end  -- hide glow in edit mode
            hud:SetAlpha(0.8)
            hud:Show()
        else
            hud:SetAlpha(1.0)
			if glowFrame then ResizeGlow(glowFrame, hud:GetWidth()) end
            -- Re-hide unless a real proc is active (event system handles that)
            hud:Hide()
        end
    end

    return slot
end

------------------------------------------------------------------------
-- Create slots — 2×2 grid centred on screen
--   Top row    : BOK (left)  | SCK (right)
--   Bottom row : ToD (left)  | RWK (right)
------------------------------------------------------------------------
local halfStep = (ICON_SIZE_DEFAULT / 2) + (GAP / 2)

local bokSlot = CreateSlot("bok", -halfStep,  halfStep, 100784, "bok_proc_timer")   -- Blackout Kick
local sckSlot = CreateSlot("sck",  halfStep,  halfStep, 101546, "docj_proc_timer")  -- Spinning Crane Kick
local todSlot = CreateSlot("tod", -halfStep, -halfStep, 322109, nil)               -- Touch of Death (no timer)
local rwkSlot = CreateSlot("rwk",  halfStep, -halfStep, 468179, "rwk_proc_timer")   -- Rushing Wind Kick

-- Convenience table for iterating all slots
local ALL_SLOTS = { bokSlot, sckSlot, todSlot, rwkSlot }
local SLOT_KEYS = { "bok", "sck", "tod", "rwk" }

------------------------------------------------------------------------
-- Edit mode state
------------------------------------------------------------------------
local editModeActive = false

local function EnterEditMode()
    if InCombatLockdown() then
        print("|cffff9900[" .. ADDON .. "]|r Cannot unlock during combat.")
        return
    end
    editModeActive = true
    for _, slot in ipairs(ALL_SLOTS) do slot.SetEditMode(true) end
    print("|cff00ff00[" .. ADDON .. "]|r Icons unlocked. Drag to move, resize from bottom-right corner. Type |cffffd700/pv lock|r to save.")
end

local function LeaveEditMode()
    editModeActive = false
    for _, slot in ipairs(ALL_SLOTS) do slot.SetEditMode(false) end
    print("|cff00ff00[" .. ADDON .. "]|r Icons locked and positions saved.")
end

------------------------------------------------------------------------
-- Slash command: /pv lock
------------------------------------------------------------------------
SLASH_PROCVIEWER1 = "/pv"
SlashCmdList["PROCVIEWER"] = function(msg)
    local cmd = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if cmd == "lock" then
        if editModeActive then
            LeaveEditMode()
        else
            EnterEditMode()
        end
    else
        print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
        print("  |cffffd700/pv lock|r  -- toggle move/resize mode (out of combat only)")
    end
end

------------------------------------------------------------------------
-- Proc state registry
-- Maps each tracked glow spell ID to:
--   globalKey   : the _G key that stores the active boolean
--   slot        : HUD slot to show/hide
--   timerKey    : (optional) _G key for the displayed countdown (seconds)
--   buffDuration: (optional) buff duration in seconds
--   endTime     : (internal) GetTime() timestamp when the buff expires;
--                 0 when inactive. Written by GLOW_SHOW/HIDE, read by ticker.
------------------------------------------------------------------------
local PROC_REGISTRY = {
    [100784] = { globalKey = "bok_proc_active",  slot = bokSlot, timerKey = "bok_proc_timer",  buffDuration = 15, endTime = 0 },
    [101546] = { globalKey = "docj_proc_active", slot = sckSlot, timerKey = "docj_proc_timer", buffDuration = 15, endTime = 0 },
    [322109] = { globalKey = "tod_proc_active",  slot = todSlot },   -- no timer for ToD
    [107428] = { globalKey = "rwk_proc_active",  slot = rwkSlot, timerKey = "rwk_proc_timer",  buffDuration = 15, endTime = 0 },
}

------------------------------------------------------------------------
-- Countdown ticker
-- Runs every frame while at least one timed proc is active.
-- Computes remaining time from endTime anchor — no drift, and refreshes
-- automatically when endTime is updated by UNIT_AURA resync.
------------------------------------------------------------------------
local tickerFrame = CreateFrame("Frame")
tickerFrame:Hide()

local function StartTicker()
    tickerFrame:Show()
end

local function MaybeStopTicker()
    for _, entry in pairs(PROC_REGISTRY) do
        if entry.endTime and entry.endTime > 0 then return end
    end
    tickerFrame:Hide()
end

tickerFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local anyActive = false
    for _, entry in pairs(PROC_REGISTRY) do
        if entry.timerKey then
            local remaining = 0
            if entry.endTime and entry.endTime > 0 then
                remaining = entry.endTime - now
                if remaining < 0 then remaining = 0 end
                if remaining > 0 then anyActive = true end
            end
            _G[entry.timerKey] = remaining
            if entry.slot then
                entry.slot.UpdateTimer(remaining)
            end
        end
    end
    if not anyActive then
        tickerFrame:Hide()
    end
end)

------------------------------------------------------------------------
-- Event handler
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        for _, k in ipairs(SLOT_KEYS) do
            ProcViewerDB[k] = ProcViewerDB[k] or {}
        end
        _G["bok_proc_timer"]  = 0
        _G["docj_proc_timer"] = 0
        _G["rwk_proc_timer"]  = 0
        for _, entry in pairs(PROC_REGISTRY) do
            if entry.endTime then entry.endTime = 0 end
        end
        tickerFrame:Hide()
        for _, slot in ipairs(ALL_SLOTS) do slot.Hide() end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local entry = PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = true
            if entry.timerKey then
                entry.endTime = GetTime() + entry.buffDuration
                StartTicker()
            end
            if entry.slot and not editModeActive then
                entry.slot.Show()
            end
        end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local entry = PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = false
            if entry.timerKey then
                entry.endTime = 0
                _G[entry.timerKey] = 0
                if entry.slot then entry.slot.UpdateTimer(0) end
                MaybeStopTicker()
            end
            if entry.slot and not editModeActive then
                entry.slot.Hide()
            end
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        if editModeActive then
            editModeActive = false
            for _, slot in ipairs(ALL_SLOTS) do slot.SetEditMode(false) end
            print("|cffff9900[" .. ADDON .. "]|r Edit mode closed: entered combat.")
        end
    end
end)
