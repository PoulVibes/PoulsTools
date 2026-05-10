local BARBED_SHOT_SPELL_ID = 217200
local BARBED_SHOT_MAX_CHARGES = 2

-- Kill Command (BM Hunter) spell id
local KILL_COMMAND_SPELL_ID = 34026
local KILL_COMMAND_MAX_CHARGES = 1

-- Wildfire Bomb (Survival Hunter) spell id
-- Max charges is 1 baseline; 2 with Guerrilla Tactics talent
local WILDFIRE_BOMB_SPELL_ID = 259495

local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

local function GetBarbedShotCharges()
    local cd = C_Spell.GetSpellCooldown(BARBED_SHOT_SPELL_ID)
    local chargeInfo = C_Spell.GetSpellCharges(BARBED_SHOT_SPELL_ID)
    
    
    if chargeInfo and not chargeInfo.isActive then
        return BARBED_SHOT_MAX_CHARGES
    elseif cd and (not cd.isActive or cd.isOnGCD) then
        return 1
    else
        return 0
    end
    
    -- Otherwise, 0 charges
    return 0
end

local function UpdateBarbedShotStack()
    local stacks = GetBarbedShotCharges()
    _G["StackMatcher_BarbedShotStacks"] = stacks
end

local function GetKillCommandCharges()
    local cd = C_Spell.GetSpellCooldown(KILL_COMMAND_SPELL_ID)
    local chargeInfo = C_Spell.GetSpellCharges(KILL_COMMAND_SPELL_ID)
    
    if chargeInfo and not chargeInfo.isActive then
        return KILL_COMMAND_MAX_CHARGES
    elseif cd and (not cd.isActive or cd.isOnGCD) then
        return 1
    else
        return 0
    end
    
    return 0
end

local function UpdateKillCommandStack()
    local stacks = GetKillCommandCharges()
    _G["StackMatcher_KillCommandStacks"] = stacks
end

local function GetWildfireBombCharges()
    local cd = C_Spell.GetSpellCooldown(WILDFIRE_BOMB_SPELL_ID)
    local chargeInfo = C_Spell.GetSpellCharges(WILDFIRE_BOMB_SPELL_ID)

    if chargeInfo and not chargeInfo.isActive then
        return chargeInfo.maxCharges or 1
    elseif cd and (not cd.isActive or cd.isOnGCD) then
        return 1
    else
        return 0
    end
end

local function UpdateWildfireBombStack()
    local stacks = GetWildfireBombCharges()
    _G["StackMatcher_WildfireBombStacks"] = stacks
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
        UpdateBarbedShotStack()
        UpdateKillCommandStack()
        UpdateWildfireBombStack()
    end
end)

-- Initialize global
local initialStacks = GetBarbedShotCharges()
_G["StackMatcher_BarbedShotStacks"] = initialStacks

local initialKCStacks = GetKillCommandCharges()
_G["StackMatcher_KillCommandStacks"] = initialKCStacks

local initialWFBStacks = GetWildfireBombCharges()
_G["StackMatcher_WildfireBombStacks"] = initialWFBStacks
