local FOLDER_NAME = "CombatCoach_OnUseTracker"

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- Module registry: populated by OnUseTracker_RegisterModule() calls in class files.
local ClassModules = {}

-- Called by class-specific files (loaded after this one) to register themselves.
function OnUseTracker_RegisterModule(module)
    ClassModules[module.specID] = module
end

local addonEnabled  = false
local currentSpecID = nil
local iconFrame

local function GetCurrentTrackedSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = select(1, GetSpecializationInfo(specIndex))
    if ClassModules[specID] then
        return specID
    end
    return nil
end

-- Keep legacy globals for SBA plugin compatibility.
_G["ZenithActiveTracker"]            = false
_G["BestialWrathActiveTracker"]      = false
_G["BestialWrathCooldownActiveTracker"] = false
_G["BestialWrathCooldownRemaining"]  = 0
_G["WitheringFireActiveTracker"]     = false
_G["WitheringFireRemaining"]         = 0
_G["BarbedShotDebuffActiveTracker"]  = false
_G["BarbedShotDebuffRemaining"]      = 0
_G["NaturesAllyActiveTracker"]       = false
_G["BeastCleaveActiveTracker"]       = false
_G["BeastCleaveRemaining"]           = 0
_G["VivifyProcActiveTracker"]        = false
_G["VivifyProcRemaining"]            = 0
_G["HojsActiveTracker"]              = false
_G["HojsRemaining"]                  = 0
_G["SentinelMarkActiveTracker"]      = false
_G["SentinelMarkRemaining"]          = 0
_G["TipOfTheSpearStacks"]            = 0
_G["TipOfTheSpearTimerActive"]       = false
_G["TipOfTheSpearRemaining"]         = 0
_G["RaptorSwipeOverrideActive"]      = false
_G["SentinelMarkTrackerReady"]       = false

local OUT_IconEnabled = false

-- Legacy visual icon (shown when the main ability window activates).
iconFrame = CreateFrame("Frame", "OnUseTrackerIcon", UIParent)
iconFrame:SetSize(64, 64)
iconFrame:SetPoint("CENTER", 0, 0)
iconFrame:Hide()

local texture = iconFrame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(iconFrame)

local function UpdateIconTexture()
    if currentSpecID and ClassModules[currentSpecID] then
        local spellID = ClassModules[currentSpecID].GetIconTextureSpellID()
        if spellID then
            texture:SetTexture(C_Spell.GetSpellTexture(spellID))
        end
    end
end

-- Slash command
SLASH_OUT1 = "/out"
SlashCmdList["OUT"] = function(_)
    OUT_IconEnabled = not OUT_IconEnabled
    if not OUT_IconEnabled then iconFrame:Hide() end
end

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    if currentSpecID and ClassModules[currentSpecID] then
        ClassModules[currentSpecID].Enable(iconFrame)
    end
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if currentSpecID and ClassModules[currentSpecID] then
        ClassModules[currentSpecID].Disable()
    end
    iconFrame:Hide()
end

local function UpdateEnabledState()
    local specID = GetCurrentTrackedSpec()
    if specID then
        -- If the spec changed while the addon was active, tear down the old module first.
        if specID ~= currentSpecID then
            if addonEnabled and currentSpecID and ClassModules[currentSpecID] then
                ClassModules[currentSpecID].Disable()
            end
            addonEnabled = false
            currentSpecID = specID
        end
        EnableAddon()
    else
        -- Switching to an untracked spec: tear down the old module before clearing state.
        if addonEnabled and currentSpecID and ClassModules[currentSpecID] then
            ClassModules[currentSpecID].Disable()
            addonEnabled = false
        end
        currentSpecID = nil
        DisableAddon()
    end
end

frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "ADDON_LOADED" and unit == FOLDER_NAME then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_LOGIN" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit == "player" then
            -- Defer one frame: GetSpecialization() may not yet reflect the new
            -- spec at the moment PLAYER_SPECIALIZATION_CHANGED fires, which would
            -- cause UpdateEnabledState to see the old spec and skip teardown.
            C_Timer.After(0, function()
                UpdateEnabledState()
                UpdateIconTexture()
            end)
        end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()
        UpdateIconTexture()
        return
    end

    if not addonEnabled then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player"
        and currentSpecID and ClassModules[currentSpecID] then
        ClassModules[currentSpecID].OnSpellCast(spellID, OUT_IconEnabled)
    end
end)
