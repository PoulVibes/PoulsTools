-- SpellGlowTracker.lua: centered HUD proc icons managed via shmIcons.
-- Data tables, proc registry, class helpers  → SpellGlowTracker_Config.lua
-- Icon registration, timer UI, ticker, slash → SpellGlowTracker_UI.lua

SpellGlowTrackerDB = SpellGlowTrackerDB or ProcViewerDB or {}
ProcViewerDB = SpellGlowTrackerDB

local FOLDER_NAME = "CombatCoach_SpellGlowTracker"
local ADDON       = "Spell Glow Tracker"
local SGT         = SpellGlowTracker  -- initialized by SpellGlowTracker_Config.lua

local addonEnabled = false
local spellGlowTrackerInitialized = false

_G["bok_proc_active"]  = false
_G["docj_proc_active"] = false
_G["tod_proc_active"]  = false
_G["rwk_proc_active"]  = false
_G["howl_proc_active"] = false
_G["black_arrow_proc_active"] = false
_G["wailing_arrow_proc_active"] = false
_G["moonlight_chakram_proc_active"] = false

------------------------------------------------------------------------
-- Global countdown timers (seconds remaining; 0 when inactive)
-- tod has no timer — not a duration-based proc.
------------------------------------------------------------------------
_G["bok_proc_timer"]  = 0
_G["docj_proc_timer"] = 0
_G["rwk_proc_timer"]  = 0
_G["howl_proc_timer"] = 0
_G["wailing_arrow_proc_timer"] = 0
_G["hogstrider_proc_timer"] = 0
_G["moonlight_chakram_proc_timer"] = 0

------------------------------------------------------------------------
-- MaybeStopTicker: only stops the ticker when no timed entries remain active.
------------------------------------------------------------------------
local function MaybeStopTicker()
    for _, entry in pairs(SGT.TIMED_ENTRIES) do
        if entry.endTime > 0 then return end
    end
    SpellGlowTracker_StopTicker()
end





local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

------------------------------------------------------------------------
-- Enable/disable helpers
------------------------------------------------------------------------
local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    if not SpellGlowTracker_AreIconsRegistered() then SpellGlowTracker_RegisterIcons() end
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    SpellGlowTracker_UnregisterIcons()
    for _, entry in pairs(SGT.PROC_REGISTRY) do
        _G[entry.globalKey] = false
        if entry.timerKey then
            entry.endTime = 0
            _G[entry.timerKey] = 0
        end
    end
    SpellGlowTracker_StopTicker()
end

local function UpdateEnabledState()
    DisableAddon()
    if SpellGlowTracker_HasEligibleSlot() then EnableAddon() end
end

------------------------------------------------------------------------
-- Event handler
------------------------------------------------------------------------
local function InitializeSpellGlowTracker()
    if spellGlowTrackerInitialized then return end
    local _, classToken = UnitClass("player")
    if classToken ~= "MONK" and classToken ~= "HUNTER" then
        eventFrame:UnregisterAllEvents()
        return
    end
    spellGlowTrackerInitialized = true
    _G["bok_proc_timer"]  = 0
    _G["docj_proc_timer"] = 0
    _G["rwk_proc_timer"]  = 0
    _G["howl_proc_timer"] = 0
    _G["wailing_arrow_proc_timer"] = 0
    _G["hogstrider_proc_timer"] = 0
    _G["moonlight_chakram_proc_timer"] = 0
    _G["howl_proc_active"] = false
    _G["black_arrow_proc_active"]   = false
    _G["wailing_arrow_proc_active"] = false
    _G["moonlight_chakram_proc_active"] = false
    for _, entry in pairs(SGT.TIMED_ENTRIES) do
        entry.endTime = 0
    end
    SpellGlowTracker_StopTicker()
    UpdateEnabledState()
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == FOLDER_NAME then
        InitializeSpellGlowTracker()

    elseif event == "PLAYER_LOGIN" then
        local _, classToken = UnitClass("player")
        if classToken ~= "MONK" and classToken ~= "HUNTER" then
            eventFrame:UnregisterAllEvents()
            return
        end
        UpdateEnabledState()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if arg1 == "player" then
            UpdateEnabledState()
        end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        UpdateEnabledState()

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        if not addonEnabled then return end
        local entry = SGT.PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = true
            shmIcons:SetVisible(ADDON, entry.key, true)
            shmIcons:SetGlow(ADDON, entry.key, true)
            if entry.timerKey then
                entry.endTime = GetTime() + entry.buffDuration
                SpellGlowTracker_StartTicker()
            end
        end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if not addonEnabled then return end
        local entry = SGT.PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = false
            shmIcons:SetGlow(ADDON, entry.key, false)
            shmIcons:SetVisible(ADDON, entry.key, false)
            if entry.timerKey then
                entry.endTime = 0
                _G[entry.timerKey] = 0
                MaybeStopTicker()
            end
        end
    end
end)
