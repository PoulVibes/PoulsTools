local frame = CreateFrame("Frame", "GuesstimatorHasteFrame", UIParent, "BackdropTemplate")
local logFrame = CreateFrame("Frame", "GuesstimatorHasteLog", UIParent, "BackdropTemplate")

-- Global Variable for external access
GuestimatedHaste = 0

-- Configuration
local baseGCD = 1.0
local GCD_DUMMY_ID = 61304
local GCD_FLOOR = 0.75

-- Runtime Trackers
local lastLoggedDummyValue = -99
local lastChangeTime = 0
local combatStartTime = 0
local logLines = {}

-- 1. UI Appearance Setup
local function SetupFrame(f, w, h)
    f:SetSize(w, h)
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        GuesstimatorHasteDB = GuesstimatorHasteDB or {}
        GuesstimatorHasteDB[self == frame and "main" or "log"] = { p = p, rp = rp, x = x, y = y }
    end)
end

SetupFrame(frame, 240, 45)
SetupFrame(logFrame, 340, 160)

local hasteText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hasteText:SetPoint("CENTER")
hasteText:SetTextColor(0.2, 0.6, 1.0)
hasteText:SetText("Off: --% vs Dummy: --%")

local logText = logFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
logText:SetPoint("TOPLEFT", 10, -10)
logText:SetJustifyH("LEFT")

-- 2. Logic Functions
local function UpdateLogUI()
    local str = "|cff3399ffCombat Haste Log:|r\n"
    for i = #logLines, math.max(1, #logLines - 7), -1 do 
        str = str .. logLines[i] .. "\n" 
    end
    logText:SetText(str)
end

-- 3. Slash Command & Visibility
SLASH_GUESSHASTE1 = "/gh"
SlashCmdList["GUESSHASTE"] = function()
    local show = not frame:IsShown()
    GuesstimatorHasteDB = GuesstimatorHasteDB or {}
    GuesstimatorHasteDB.isVisible = show
    if show then frame:Show() logFrame:Show() else frame:Hide() logFrame:Hide() end
end

-- 4. Event Handler
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GuesstimatorHaste" then
        GuesstimatorHasteDB = GuesstimatorHasteDB or { isVisible = true }
        if GuesstimatorHasteDB.main then
            frame:ClearAllPoints()
            frame:SetPoint(GuesstimatorHasteDB.main.p, UIParent, GuesstimatorHasteDB.main.rp, GuesstimatorHasteDB.main.x, GuesstimatorHasteDB.main.y)
        else frame:SetPoint("CENTER", 0, 100) end
        if GuesstimatorHasteDB.log then
            logFrame:ClearAllPoints()
            logFrame:SetPoint(GuesstimatorHasteDB.log.p, UIParent, GuesstimatorHasteDB.log.rp, GuesstimatorHasteDB.log.x, GuesstimatorHasteDB.log.y)
        else logFrame:SetPoint("CENTER", 0, -100) end
        if not GuesstimatorHasteDB.isVisible then frame:Hide() logFrame:Hide() end
        UpdateLogUI()
    elseif event == "PLAYER_REGEN_DISABLED" then
        logLines = {} 
        combatStartTime = GetTime()
        lastLoggedDummyValue = -99 
        UpdateLogUI()
    end
end)

-- 5. The OnUpdate Loop
frame:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then return end

    local cdInfo = C_Spell.GetSpellCooldown(GCD_DUMMY_ID)
    
    if cdInfo and cdInfo.duration and cdInfo.duration > 0 then
        local currentDummyHaste = (baseGCD / cdInfo.duration - 1) * 100
        
        if currentDummyHaste > 0 then
            local official = GetHaste()
            local now = GetTime()
            
            -- Detect the 0.75s cap
            local isCapped = (cdInfo.duration <= GCD_FLOOR + 0.001)
            local capText = isCapped and "|cffff0000(CAP)|r" or ""

            -- Update the visible text
            hasteText:SetText(string.format("Off: %.1f%% vs Dummy: %.1f%% %s", official, currentDummyHaste, capText))

            -- Logging Logic (1.0% threshold)
            if math.abs(currentDummyHaste - lastLoggedDummyValue) >= 1.0 then
                -- UPDATE GLOBAL VARIABLE
                GuestimatedHaste = currentDummyHaste
                
                local timeInCombat = (combatStartTime > 0) and (now - combatStartTime) or 0
                local logEntry = string.format("[%.1fs] Dummy: %.1f%% %s | Off: %.1f%%", 
                    timeInCombat, currentDummyHaste, (isCapped and "CAP" or ""), official)
                
                table.insert(logLines, logEntry)
                lastLoggedDummyValue = currentDummyHaste
                UpdateLogUI()
            end
        end
    end
end)
