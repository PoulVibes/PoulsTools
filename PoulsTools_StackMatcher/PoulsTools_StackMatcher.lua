local BARBED_SHOT_SPELL_ID = 217200
local BARBED_SHOT_MAX_CHARGES = 2

local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
local previousStacks = nil

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
    if stacks ~= previousStacks then
        if previousStacks == nil then
            print(("PoulsTools_StackMatcher: Barbed Shot stacks initialized -> %d"):format(stacks))
        else
            print(("PoulsTools_StackMatcher: Barbed Shot stacks changed %d -> %d"):format(previousStacks, stacks))
        end
        previousStacks = stacks
    end
    _G["StackMatcher_BarbedShotStacks"] = stacks
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
        UpdateBarbedShotStack()
    end
end)

-- Initialize global
local initialStacks = GetBarbedShotCharges()
_G["StackMatcher_BarbedShotStacks"] = initialStacks
previousStacks = initialStacks
