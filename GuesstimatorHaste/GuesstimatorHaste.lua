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

-- Single-spec gating (Monk - Windwalker)
local REQUIRED_CLASS = "MONK"
local REQUIRED_SPEC_ID = 269
local addonEnabled = false

local function IsPlayerClass(token)
    local _, classToken = UnitClass("player")
    return classToken == token
end

local function IsPlayerSpec(specID)
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local id = select(1, GetSpecializationInfo(specIndex))
    return id == specID
end

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    if not GuesstimatorHasteDB or GuesstimatorHasteDB.isVisible == nil or GuesstimatorHasteDB.isVisible then
        frame:Hide()
        logFrame:Hide()
    end
    print("[GuesstimatorHaste] enabled for required spec")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:Hide()
    logFrame:Hide()
    print("[GuesstimatorHaste] disabled (not required spec)")
end

local function UpdateEnabledState()
    if not IsPlayerClass(REQUIRED_CLASS) then
        print("[GuesstimatorHaste] abort: wrong class")
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
        logFrame:Hide()
        print("Not a Monk please disable GuesstimatorHaste")
        return
    end
    if IsPlayerSpec(REQUIRED_SPEC_ID) then
        print("I am the required class and spec.")
        EnableAddon()
    else
        print("Not a windwalker GuesstimatedHaste will be disabled")
        DisableAddon()
    end
end

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
    if not IsPlayerClass(REQUIRED_CLASS) then
        print("[GuesstimatorHaste] only available for Monks")
        return
    end
    if not IsPlayerSpec(REQUIRED_SPEC_ID) then
        print("[GuesstimatorHaste] only active for Windwalker")
        return
    end
    local show = not frame:IsShown()
    GuesstimatorHasteDB = GuesstimatorHasteDB or {}
    GuesstimatorHasteDB.isVisible = show
    if show then frame:Show() logFrame:Show() else frame:Hide() logFrame:Hide() end
end

-- 4. Event Handler
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

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

    elseif event == "PLAYER_LOGIN" then
        UpdateEnabledState()
        UpdateLogUI()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if arg1 == "player" then UpdateEnabledState() end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()

    elseif event == "PLAYER_REGEN_DISABLED" then
        if not addonEnabled then return end
        logLines = {} 
        combatStartTime = GetTime()
        lastLoggedDummyValue = -99 
        UpdateLogUI()
    end
end)

-- 5. The OnUpdate Loop
frame:SetScript("OnUpdate", function(self, elapsed)   
    if not addonEnabled or not self:IsShown() then print("self not shown") return end

    local cdInfo = C_Spell.GetSpellCooldown(GCD_DUMMY_ID)
    if cdInfo and cdInfo.duration and cdInfo.duration > 0 then
        local currentDummyHaste = (baseGCD / cdInfo.duration - 1.0) * 100 - 0.1
        if currentDummyHaste > 0 then
            local official = GetHaste()
            local now = GetTime()
            
            -- Detect the 0.75s cap
            local isCapped = (cdInfo.duration <= GCD_FLOOR)
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
