-- Register the Addon Object with AceEvent
local Guesstimator = LibStub("AceAddon-3.0"):NewAddon("Guesstimator", "AceEvent-3.0")
local frame = CreateFrame("Frame", "EnergyGuesstimatorLogicFrame")

-- 1. Configuration & Constants
local TIGER_PALM_ID = 100780
local VIVIFY_ID = 116670
local CJL_ID = 117952

local ENERGY_COST_TP = 60
local ENERGY_COST_VIVIFY_NORMAL = 30
local ENERGY_COST_VIVIFY_PROC = 7.5
local VIVIFY_THRESHOLD = 30
local CJL_THRESHOLD = 20

local BASE_REGEN = 10
local ASCENSION_MODIFIER = 1.10

_G.GuesstimatedHaste = _G.GuesstimatedHaste or 0.21

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
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UNIT_MAXPOWER")
    --print("[Guesstimator] enabled for required spec")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:UnregisterEvent("UNIT_POWER_UPDATE")
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    frame:UnregisterEvent("UNIT_MAXPOWER")
    ui:Hide()
    --print("[Guesstimator] disabled (not required spec)")
end

local function UpdateEnabledState()
    if not IsPlayerClass(REQUIRED_CLASS) then
        --print("[Guesstimator] abort: wrong class")
        frame:UnregisterAllEvents()
        ui:SetScript("OnUpdate", nil)
        ui:Hide()
        return
    end
    if IsPlayerSpec(REQUIRED_SPEC_ID) then
        EnableAddon()
    else
        DisableAddon()
    end
end

-- 2. Internal "Clean" State
local maxEnergy = UnitPowerMax("player", 3) or 120
currentEnergy = maxEnergy

-- 3. UI Setup
local ui = CreateFrame("Frame", "EnergyGuesstimatorUI", UIParent, "BackdropTemplate")
ui:SetSize(160, 40) -- Increased width for comparison text
ui:SetPoint("CENTER", 0, 0)
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)

ui:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
ui:SetBackdropColor(0, 0, 0, 0.6)

ui.text = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ui.text:SetPoint("CENTER", 0, 0)
ui.text:SetTextColor(1, 0.8, 0)

-- 4. AceEvent Message Handling
function Guesstimator:OnInitialize()
    self:RegisterMessage("VIVIFY_PROC_CONSUMED", "HandleVivifyProc")
    self:RegisterMessage("VIVIFY_NORMAL_CAST", "HandleVivifyNormal")
	ui:Hide()
end

function Guesstimator:HandleVivifyProc()
    currentEnergy = math.max(0, currentEnergy - ENERGY_COST_VIVIFY_PROC)
end

function Guesstimator:HandleVivifyNormal()
    currentEnergy = math.max(0, currentEnergy - ENERGY_COST_VIVIFY_NORMAL)
end

-- 5. Standard Event Logic
-- Runtime events are registered only when the addon is enabled
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...) == "EnergyGuesstimator" then
        -- no saved-vars for this addon; keep UI hidden until enabled/toggled
        return
    end

    if event == "PLAYER_LOGIN" then
        UpdateEnabledState()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if select(1, ...) == "player" then UpdateEnabledState() end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()
        return
    end

    if not addonEnabled then return end

    if event == "PLAYER_REGEN_ENABLED" then
        local realPower = UnitPower("player", 3)
        if not issecretvalue(realPower) then currentEnergy = realPower end
        return
    end

    local unit = select(1, ...)
    if unit ~= "player" then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = select(3, ...)
        if spellID == TIGER_PALM_ID then
            currentEnergy = math.max(0, currentEnergy - ENERGY_COST_TP)
        end
    elseif event == "UNIT_POWER_UPDATE" then
        local powerType = select(2, ...)
        if powerType == "ENERGY" then
            local isVivify = C_Spell.IsSpellUsable(VIVIFY_ID)
            local isCJL = C_Spell.IsSpellUsable(CJL_ID)
            if not issecretvalue(isVivify) and isVivify then
                if currentEnergy < VIVIFY_THRESHOLD then currentEnergy = VIVIFY_THRESHOLD end
            end
            if not issecretvalue(isCJL) and isCJL then
                if currentEnergy < CJL_THRESHOLD then currentEnergy = CJL_THRESHOLD end
            end
        end
    elseif event == "UNIT_MAXPOWER" then
        maxEnergy = UnitPowerMax("player", 3) or 120
    end
end)

-- 6. UI Update with Secret Value Comparison
ui:SetScript("OnUpdate", function(self, elapsed)
    if not addonEnabled or not self:IsShown() then return end

    local currentRegenRate = (BASE_REGEN * (1 + _G.GuesstimatedHaste)) * ASCENSION_MODIFIER

    if currentEnergy < maxEnergy then
        currentEnergy = math.min(maxEnergy, currentEnergy + (currentRegenRate * elapsed))
    end

    -- SAFE DISPLAY for 12.0.1
    -- We use %s to allow the Secret Value to be 'wrapped' into the string visually
    -- without the Lua script attempting to read the number inside.
    local actualEnergy = UnitPower("player", 3)
    self.text:SetFormattedText("%d vs %s", math.floor(currentEnergy), actualEnergy)
end)

-- 7. Slash Commands
SLASH_GUESSTIMATE1 = "/ge"
SlashCmdList["GUESSTIMATE"] = function()
    if not IsPlayerClass(REQUIRED_CLASS) then
        --print("[Guesstimator] only available for Monks")
        return
    end
    if not IsPlayerSpec(REQUIRED_SPEC_ID) then
        --print("[Guesstimator] only active for Windwalker")
        return
    end
    if ui:IsShown() then ui:Hide() else ui:Show() end
end
