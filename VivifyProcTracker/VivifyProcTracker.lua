-- Initialize AceAddon
local VPT = LibStub("AceAddon-3.0"):NewAddon("VivifyProcTracker", "AceEvent-3.0")

-- Configuration & IDs
local VIVIFY_SPELL_ID = 116670
local RSK_SPELL_ID = 107428
local RWK_SPELL_ID = 467307
local PROC_DURATION = 20
local isLocked = true
local timerHandle

function VPT:OnInitialize()
    -- Setup Saved Variables
    VivifyProcTrackerDB = VivifyProcTrackerDB or { point = "CENTER", x = 0, y = -100, width = 50, height = 50 }
    
    self:CreateUI()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    
    -- Slash Command
    SLASH_VPT1 = "/vpt"
    SlashCmdList["VPT"] = function(msg) self:ToggleLock(msg) end
end

function VPT:CreateUI()
    local frame = CreateFrame("Frame", "VivifyProcTrackerFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetSize(VivifyProcTrackerDB.width, VivifyProcTrackerDB.height)
    frame:SetPoint(VivifyProcTrackerDB.point, UIParent, VivifyProcTrackerDB.relPoint or "CENTER", VivifyProcTrackerDB.x, VivifyProcTrackerDB.y)
    frame:Hide()

    -- Icon & Cooldown
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints(frame)
    frame.texture:SetTexture(C_Spell.GetSpellTexture(VIVIFY_SPELL_ID))

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame)
    frame.cooldown:SetReverse(true)
    frame.cooldown:SetHideCountdownNumbers(false)

    -- Visual Unlock BG
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(0, 0, 0, 0.5)
    frame.bg:Hide()

    -- Drag/Resize Logic
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); self:SavePos() end)
    frame:SetScript("OnDragStart", function(f) if not isLocked then f:StartMoving() end end)
end

function VPT:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit ~= "player" then return end

    -- Trigger the Proc
    if spellID == RSK_SPELL_ID or spellID == RWK_SPELL_ID then
        self.frame:Show()
        self.frame.cooldown:SetCooldown(GetTime(), PROC_DURATION)
        
        if timerHandle then timerHandle:Cancel() end
        timerHandle = C_Timer.After(PROC_DURATION, function() 
            if self.frame:IsVisible() and isLocked then
                self.frame:Hide()
            end
        end)

    -- Handle Vivify Logic
    elseif spellID == VIVIFY_SPELL_ID then
        -- If frame is visible and locked, it's a proc
        if self.frame:IsVisible() and isLocked then
            self.frame:Hide()
            if timerHandle then timerHandle:Cancel() end
            -- Custom Message: Proc Consumed
            self:SendMessage("VIVIFY_PROC_CONSUMED")
        else
            -- Custom Message: Normal Cast
            self:SendMessage("VIVIFY_NORMAL_CAST")
        end
    end
end

function VPT:SavePos()
    local point, _, relPoint, x, y = self.frame:GetPoint()
    VivifyProcTrackerDB.point, VivifyProcTrackerDB.relPoint = point, relPoint
    VivifyProcTrackerDB.x, VivifyProcTrackerDB.y = x, y
    VivifyProcTrackerDB.width, VivifyProcTrackerDB.height = self.frame:GetWidth(), self.frame:GetHeight()
end

function VPT:ToggleLock(msg)
    if msg:lower() == "lock" then
        isLocked = not isLocked
        if isLocked then
            self.frame:EnableMouse(false); self.frame.bg:Hide(); self.frame:Hide()
            print("|cFF00FF00VPT: Locked.|r")
        else
            self.frame:EnableMouse(true); self.frame.bg:Show(); self.frame:Show()
            print("|cFFFFFF00VPT: Unlocked. Drag to move/resize.|r")
        end
    end
end
