-- FocusGuesstimator_Enable.lua
-- Class/spec helpers, talent refresh, and addon enable/disable logic.
-- Loads after FocusGuesstimator_Data.lua; all globals use the FG module table
-- and reference named frames created by Data.lua and the main file.

local FG    = FocusGuesstimator
local frame = FocusGuesstimatorLogicFrame  -- created by FocusGuesstimator_Data.lua

------------------------------------------------------------------------
-- Class/spec helpers
------------------------------------------------------------------------
function FocusGuesstimator_IsPlayerClass(token)
    local _, classToken = UnitClass("player")
    return classToken == token
end

function FocusGuesstimator_IsPlayerSpec(specID)
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    return select(1, GetSpecializationInfo(specIndex)) == specID
end

------------------------------------------------------------------------
-- Talent/weapon refresh
------------------------------------------------------------------------
function FocusGuesstimator_RefreshTalents()
    FG.regenMultiplier = 1.0

    local apiMax = UnitPowerMax("player", FG.FOCUS_POWER_TYPE)
    if apiMax and not issecretvalue(apiMax) then
        FG.maxFocus = apiMax
    else
        FG.maxFocus = 100
    end

    FG.cobraSensesActive = IsPlayerSpell(FG.COBRA_SENSES_SPELL_ID)

    if not InCombatLockdown() then
        local crit = GetRangedCritChance()
        if crit and not issecretvalue(crit) then
            FG.lastKnownRangedCritChance = crit
            FG.cobraCritExpectedRefund   = (FG.lastKnownRangedCritChance / 100) * 10
        end
    end

    if FG.currentSpec == FG.SV_SPEC_ID then
        FG.flankersAdvantageActive = IsPlayerSpell(FG.FLANKERS_ADVANTAGE_SPELL_ID)
        FG.invPulseActive          = IsPlayerSpell(FG.INVIGORATING_PULSE_SPELL_ID)
        FG.shrapnelBombActive      = IsPlayerSpell(FG.SHRAPNEL_BOMB_SPELL_ID)
    else
        FG.flankersAdvantageActive = false
        FG.invPulseActive          = false
        FG.shrapnelBombActive      = false
    end
    FG.lethalBarbsActive = IsPlayerSpell(FG.LETHAL_BARBS_SPELL_ID)

    if currentFocus > FG.maxFocus then currentFocus = FG.maxFocus end
end

function FocusGuesstimator_RefreshWeaponSpeed()
    if InCombatLockdown() then return end
    local hastedSpeed = UnitAttackSpeed("player")
    if hastedSpeed and not issecretvalue(hastedSpeed) and hastedSpeed > 0 then
        local haste = _G.GuesstimatedHaste or 0
        FG.baseRangedWeaponSpeed = hastedSpeed * (1 + haste)
    end
end

------------------------------------------------------------------------
-- Enable / Disable / UpdateEnabledState
------------------------------------------------------------------------
function FocusGuesstimator_EnableAddon()
    if FG.addonEnabled then return end
    FG.addonEnabled  = true
    currentFocus     = FG.maxFocus
    FG.autoShotTimer = 0
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function FocusGuesstimator_DisableAddon()
    if not FG.addonEnabled then return end
    FG.addonEnabled            = false
    FG.autoShotTimer           = 0
    FG.playerInCombat          = false
    FG.currentSpec             = 0
    FG.flankersAdvantageActive = false
    FG.invPulseActive          = false
    FG.shrapnelBombActive      = false
    wipe(FG.bardedShotRegenExpiry)
    wipe(FG.shrapnelBombExpiry)
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:UnregisterEvent("UNIT_MAXPOWER")
    frame:UnregisterEvent("UNIT_POWER_UPDATE")
    frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    FocusGuesstimatorUI:Hide()
end

function FocusGuesstimator_UpdateEnabledState()
    if not FocusGuesstimator_IsPlayerClass(FG.REQUIRED_CLASS) then
        frame:UnregisterAllEvents()
        FocusGuesstimatorUI:Hide()
        return
    end
    if FocusGuesstimator_IsPlayerSpec(FG.REQUIRED_SPEC_ID) then
        FG.currentSpec = FG.REQUIRED_SPEC_ID
        FocusGuesstimator_RefreshTalents()
        FocusGuesstimator_RefreshWeaponSpeed()
        FocusGuesstimator_EnableAddon()
    elseif FocusGuesstimator_IsPlayerSpec(FG.SV_SPEC_ID) then
        FG.currentSpec = FG.SV_SPEC_ID
        FocusGuesstimator_RefreshTalents()
        FocusGuesstimator_RefreshWeaponSpeed()
        FocusGuesstimator_EnableAddon()
    else
        FG.currentSpec = 0
        FocusGuesstimator_DisableAddon()
    end
end
