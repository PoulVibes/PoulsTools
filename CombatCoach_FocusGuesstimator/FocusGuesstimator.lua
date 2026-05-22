-- FocusGuesstimator.lua
-- Main event handler and UI frame.
-- Data tables and state  → FocusGuesstimator_Data.lua  (loads first)
-- Enable/disable helpers → FocusGuesstimator_Enable.lua (loads second)

local FG    = FocusGuesstimator          -- initialized by FocusGuesstimator_Data.lua
local frame = FocusGuesstimatorLogicFrame -- named frame from FocusGuesstimator_Data.lua

local ui = CreateFrame("Frame", "FocusGuesstimatorUI", UIParent, "BackdropTemplate")
ui:SetSize(160, 40)
ui:SetPoint("CENTER", 0, -60)
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)

ui:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
ui:SetBackdropColor(0, 0, 0, 0.6)

ui.text = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ui.text:SetPoint("CENTER")
ui.text:SetTextColor(0.2, 0.6, 1)   -- blue tint matches the focus bar colour

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if select(1, ...) == "CombatCoach_FocusGuesstimator" then
            ui:Hide()
            FocusGuesstimator_UpdateEnabledState()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        FocusGuesstimator_UpdateEnabledState()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if select(1, ...) == "player" then FocusGuesstimator_UpdateEnabledState() end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if FG.addonEnabled then FocusGuesstimator_RefreshTalents() end
        FocusGuesstimator_UpdateEnabledState()
        return
    end

    if not FG.addonEnabled then return end

    if event == "PLAYER_REGEN_ENABLED" then
        FG.playerInCombat = false
        local real = UnitPower("player", FG.FOCUS_POWER_TYPE)
        if not issecretvalue(real) then currentFocus = real end
        local crit = GetRangedCritChance()
        if crit and not issecretvalue(crit) then
            FG.lastKnownRangedCritChance = crit
            FG.cobraCritExpectedRefund   = (FG.lastKnownRangedCritChance / 100) * 10
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        FG.playerInCombat = true
        FG.autoShotTimer  = 0
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot = select(1, ...)
        if slot == INVSLOT_MAINHAND then
            FocusGuesstimator_RefreshWeaponSpeed()
        end
        return
    end

    -- All remaining runtime events carry unit as the first argument.
    local unit = select(1, ...)
    if unit ~= "player" then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = select(3, ...)

        if FG.currentSpec == FG.SV_SPEC_ID then
            local gain = 0
            if spellID == 259489 then  -- Kill Command
                gain = FG.SV_KILL_COMMAND_GAIN
                if FG.flankersAdvantageActive then gain = gain + 5 end
                if FG.invPulseActive          then gain = gain + 5 end
            elseif FG.SV_TAKEDOWN_ID > 0 and spellID == FG.SV_TAKEDOWN_ID then
                gain = FG.SV_TAKEDOWN_GAIN
            elseif spellID == FG.SV_MUZZLE_ID then
                gain = FG.SV_MUZZLE_GAIN
            end
            if gain > 0 then
                currentFocus = math.min(FG.maxFocus, currentFocus + gain)
            end

            if FG.shrapnelBombActive and spellID == 259495 then  -- Wildfire Bomb
                FG.shrapnelBombExpiry[#FG.shrapnelBombExpiry + 1] = GetTime() + FG.SHRAPNEL_BOMB_DURATION
            end

            local cost = FG.SV_ABILITY_COSTS[spellID]
            if cost and cost > 0 then
                currentFocus = math.max(0, currentFocus - cost)
            end
            return  -- skip BM focus-cost logic below
        end

        local cost = FG.ABILITY_COSTS[spellID]

        if spellID == FG.COBRA_SHOT_ID then
            if FG.cobraSensesActive then cost = cost - 5 end
            cost = cost - FG.cobraCritExpectedRefund
        end

        if cost and cost > 0 then
            currentFocus = math.max(0, currentFocus - cost)
        elseif cost and cost < 0 then
            currentFocus = math.min(FG.maxFocus, currentFocus - cost)
        end

        if spellID == FG.BARBED_SHOT_ID then
            FG.bardedShotRegenExpiry[#FG.bardedShotRegenExpiry + 1] = GetTime() + FG.BARBED_SHOT_DURATION
        end

    elseif event == "UNIT_POWER_UPDATE" then
        if FG.currentSpec == FG.REQUIRED_SPEC_ID then
            local powerType = select(2, ...)
            if powerType == "FOCUS" then
                local kcUsable = C_Spell.IsSpellUsable(34026)
                if not issecretvalue(kcUsable) and kcUsable then
                    if currentFocus < 30 then currentFocus = 30 end
                end
            end
        end

    elseif event == "UNIT_MAXPOWER" then
        local apiMax = UnitPowerMax("player", FG.FOCUS_POWER_TYPE)
        if apiMax and not issecretvalue(apiMax) then
            FG.maxFocus = apiMax
            if currentFocus > FG.maxFocus then currentFocus = FG.maxFocus end
        end
    end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    if not FG.addonEnabled then return end

    local regenRate = FG.BASE_REGEN * (1 + (_G.GuesstimatedHaste or 0)) * FG.regenMultiplier

    local now = GetTime()
    local activeStacks = 0
    local writeIdx = 0
    for i = 1, #FG.bardedShotRegenExpiry do
        local expiry = FG.bardedShotRegenExpiry[i]
        if expiry > now then
            writeIdx = writeIdx + 1
            FG.bardedShotRegenExpiry[writeIdx] = expiry
            activeStacks = activeStacks + 1
        end
    end
    for i = writeIdx + 1, #FG.bardedShotRegenExpiry do
        FG.bardedShotRegenExpiry[i] = nil
    end

    regenRate = regenRate + (activeStacks * FG.BARBED_SHOT_REGEN_RATE)

    if currentFocus < FG.maxFocus then
        currentFocus = math.min(FG.maxFocus, currentFocus + (regenRate * elapsed))
    end

    if FG.lethalBarbsActive and FG.playerInCombat then
        local focusPerTick, interval
        if FG.currentSpec == FG.SV_SPEC_ID then
            focusPerTick = 2
            interval     = FG.SV_MELEE_WEAPON_BASE_INTERVAL / (1 + (_G.GuesstimatedHaste or 0))
        elseif FG.baseRangedWeaponSpeed > 0 then
            focusPerTick = 1
            interval     = FG.baseRangedWeaponSpeed / (1 + (_G.GuesstimatedHaste or 0))
        end
        if interval then
            FG.autoShotTimer = FG.autoShotTimer + elapsed
            while FG.autoShotTimer >= interval do
                FG.autoShotTimer = FG.autoShotTimer - interval
                currentFocus     = math.min(FG.maxFocus, currentFocus + focusPerTick)
            end
        end
    end

    if FG.currentSpec == FG.SV_SPEC_ID and FG.shrapnelBombActive then
        local activeBombs = 0
        local wIdx = 0
        for i = 1, #FG.shrapnelBombExpiry do
            local expiry = FG.shrapnelBombExpiry[i]
            if expiry > now then
                wIdx = wIdx + 1
                FG.shrapnelBombExpiry[wIdx] = expiry
                activeBombs = activeBombs + 1
            end
        end
        for i = wIdx + 1, #FG.shrapnelBombExpiry do FG.shrapnelBombExpiry[i] = nil end
        if activeBombs > 0 then
            currentFocus = math.min(FG.maxFocus, currentFocus + activeBombs * FG.SHRAPNEL_BOMB_REGEN_RATE * elapsed)
        end
    end

    if ui:IsShown() then
        local actual = UnitPower("player", FG.FOCUS_POWER_TYPE)
        ui.text:SetFormattedText("%d vs %s", math.floor(currentFocus), actual)
    end
end)

SLASH_FOCUSGUESSTIMATE1 = "/fg"
SlashCmdList["FOCUSGUESSTIMATE"] = function()
    if not FocusGuesstimator_IsPlayerClass(FG.REQUIRED_CLASS) then return end
    if not FocusGuesstimator_IsPlayerSpec(FG.REQUIRED_SPEC_ID) and not FocusGuesstimator_IsPlayerSpec(FG.SV_SPEC_ID) then return end
    if ui:IsShown() then ui:Hide() else ui:Show() end
end
