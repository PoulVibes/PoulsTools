-- SBA_Simple_Events.lua
-- Event registration and spec-change refresh for SBA_Simple.

local MONK_ADDONS = {
    "CombatCoach_VivifyProcTracker",
    "CombatCoach_ComboTracker",
    "CombatCoach_SpellGlowTracker",
    "CombatCoach_EnergyGuesstimator",
    "CombatCoach_GuesstimatorHaste",
}

function SBAS_RegisterRuntimeEvents(context)
    if _G.SBAS_RuntimeEventsRegistered then return end
    local monkAddonsLoaded = false
    local wipeFn = (table and table.wipe) or wipe

    local function CompactSpellGCDState()
        local count = 0
        for _ in pairs(context.spellGCDState) do
            count = count + 1
            if count > 256 then
                if wipeFn then
                    wipeFn(context.spellGCDState)
                else
                    for k in pairs(context.spellGCDState) do
                        context.spellGCDState[k] = nil
                    end
                end
                return
            end
        end
    end

    local function LoadMonkAddons()
        if monkAddonsLoaded then return end
        local _, classToken = UnitClass("player")
        if classToken ~= "MONK" then return end
        monkAddonsLoaded = true
        for _, addonName in ipairs(MONK_ADDONS) do
            if not C_AddOns.IsAddOnLoaded(addonName) then
                C_AddOns.LoadAddOn(addonName)
            end
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    events:SetScript("OnEvent", function(_, event)
        if event == "SPELL_UPDATE_COOLDOWN" then
            CompactSpellGCDState()
            for sid in pairs(context.spellGCDState) do
                local cd = C_Spell.GetSpellCooldown(sid)
                context.spellGCDState[sid] = cd and cd.isOnGCD or false
            end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            LoadMonkAddons()
        end
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            if wipeFn then
                wipeFn(context.spellGCDState)
            else
                for k in pairs(context.spellGCDState) do
                    context.spellGCDState[k] = nil
                end
            end
            shmIcons:Unregister(context.addonName, context.iconKey)
            context.registerIcon()
            C_Timer.After(0, function() context.updateExtraIconsForSpec(context.getCurrentSpecID()) end)
            C_Timer.After(0, function()
                local specDB = context.getSpecDB()
                local code = specDB.overrideSource and specDB.overrideCode
                if code and not code:match("^%s*$") then
                    context.compileOverride(code)
                else
                    local defaultCode = _G.SBAS_GetDefaultOverrideCodeForSpec
                        and _G.SBAS_GetDefaultOverrideCodeForSpec(context.getCurrentSpecID())
                    context.compileOverride(defaultCode or "return C_AssistedCombat.GetNextCastSpell()")
                end
            end)
        end
    end)
    _G.SBAS_RuntimeEventsRegistered = true
    _G.SBAS_RuntimeEventsFrame = events
end

SBAS_RegisterRuntimeEvents(SBA_Simple_GetEventContext())
