-- SpellGlowTracker.lua
-- Centered HUD proc icons using shmIcons for frame management.
--
-- Slots:
--   bok  : Blackout Kick       (glow event spell ID 100784)
--   sck  : Spinning Crane Kick (glow event spell ID 101546, Dance of Chi-Ji proc)
--   tod  : Touch of Death      (glow event spell ID 322109)
--   rwk  : Rushing Wind Kick   (glow event spell ID 107428 / RSK base)
--
-- Slash commands:
--   /sgt       -- show help
--   /shm lock  -- lock/unlock all shmIcons (move/resize)
--
-- Version: 0.1.8
-- Compatible with WoW API 12.0.1 (Midnight)

------------------------------------------------------------------------
-- Saved variables
-- shmIcons writes position/size back into each db entry in-place.
-- Schema per slot: { x, y, point, size, enabled, glow_enabled, spellID }
------------------------------------------------------------------------
SpellGlowTrackerDB = SpellGlowTrackerDB or ProcViewerDB or {}
ProcViewerDB = SpellGlowTrackerDB

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local FOLDER_NAME       = "CombatCoach_SpellGlowTracker"
local ADDON             = "Spell Glow Tracker"
local VERSION           = "0.1.8"
local ICON_SIZE_DEFAULT = 64
local GAP               = 8

local WINDWALKER_SPEC_ID = 269
local BM_HUNTER_SPEC_ID  = 253
local iconsRegistered = false
local addonEnabled = false
local lockCallbackRegistered = false
local spellGlowTrackerInitialized = false

------------------------------------------------------------------------
-- Global proc-active booleans (readable by other addons)
------------------------------------------------------------------------
_G["bok_proc_active"]  = false
_G["docj_proc_active"] = false
_G["tod_proc_active"]  = false
_G["rwk_proc_active"]  = false
_G["howl_proc_active"] = false
_G["black_arrow_proc_active"] = false
_G["wailing_arrow_proc_active"] = false

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

------------------------------------------------------------------------
-- Default DB initialiser for a slot
------------------------------------------------------------------------
local function DefaultSlotDB(x, y, spellID)
    return {
        x           = x,
        y           = y,
        point       = "CENTER",
        size        = ICON_SIZE_DEFAULT,
        enabled     = true,
        glow_enabled = false,
        spellID     = spellID,
    }
end

------------------------------------------------------------------------
-- Default positions — 2×2 grid centred on screen
--   Top row    : bok (left)  | sck (right)
--   Bottom row : tod (left)  | rwk (right)
------------------------------------------------------------------------
local halfStep = (ICON_SIZE_DEFAULT / 2) + (GAP / 2)

local SLOT_DEFS = {
    { key = "Black Out Kick!",           x = -halfStep,      y =  halfStep,      iconSpellID = 100784, iconTexture = 572033,   timerKey = "bok_proc_timer",          buffDuration = 15, classSpec = "MONK_WW"    },
    { key = "Dance of Chi-JI",           x =  halfStep,      y =  halfStep,      iconSpellID = 101546, iconTexture = 607849,   timerKey = "docj_proc_timer",         buffDuration = 15, classSpec = "MONK_WW"    },
    { key = "Touch of Death",            x = -halfStep,      y = -halfStep,      iconSpellID = 322109, timerKey = nil,                                         classSpec = "MONK_ALL"   },
    { key = "Rushing Wind Kick",         x =  halfStep,      y = -halfStep,      iconSpellID = 468179, timerKey = "rwk_proc_timer",          buffDuration = 15, classSpec = "MONK_WW"    },
    -- Hunter entries (Beast Mastery spec only)
    { key = "Howl of the Pack Leader",   x =  3 * halfStep,  y =  halfStep,      iconSpellID = 34026,  iconTexture = 5927643, timerKey = "howl_proc_timer",         buffDuration = 29, classSpec = "HUNTER_BM"  },
    { key = "Black Arrow",               x =  3 * halfStep,  y = -halfStep,      iconSpellID = 466930, timerKey = nil,                                         classSpec = "HUNTER_BM"  },
    { key = "Wailing Arrow",             x =  0,             y = -3 * halfStep,  iconSpellID = 392060, timerKey = "wailing_arrow_proc_timer", buffDuration = 15, classSpec = "HUNTER_BM"  },
    { key = "Hogstrider",                x = -3 * halfStep,  y =  halfStep,      iconSpellID = 193455, iconTexture = 463878,  timerKey = "hogstrider_proc_timer",   buffDuration = 19, classSpec = "HUNTER_BM"  },
}

local SLOT_DEF_BY_KEY = {}
for _, def in ipairs(SLOT_DEFS) do SLOT_DEF_BY_KEY[def.key] = def end

------------------------------------------------------------------------
-- Timer FontStrings
-- shmIcons owns its frames; we parent a FontString as a purely additive
-- child after registration. The library ignores unknown children.
-- We keep references here so the ticker can update them.
------------------------------------------------------------------------
local timerTexts = {}   -- key -> FontString (nil for tod)

local function AttachTimerText(key, iconObj, size)
    if not iconObj or not iconObj.frame then return end
    local fs = iconObj.frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size * 0.6, "OUTLINE")
    fs:SetPoint("CENTER", iconObj.frame, "CENTER", 0, 0)
    fs:SetTextColor(1, 0.4, 0.8, 1)
    fs:SetText("")
    timerTexts[key] = fs
end

local TIMED_ENTRIES = nil
local tickerFrame = nil

------------------------------------------------------------------------
-- Class/spec helpers (must be defined before RegisterIcons calls them)
------------------------------------------------------------------------
local function IsPlayerMonk()
    local _, classToken = UnitClass("player")
    return classToken == "MONK"
end

local function IsPlayerHunter()
    local _, classToken = UnitClass("player")
    return classToken == "HUNTER"
end

local function IsPlayerWindwalkerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == WINDWALKER_SPEC_ID
end

local function IsPlayerBMHunterSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == BM_HUNTER_SPEC_ID
end

local function IsSlotEligible(def)
    local cs = def.classSpec
    if cs == "MONK_ALL"  then return IsPlayerMonk() end
    if cs == "MONK_WW"   then return IsPlayerMonk() and IsPlayerWindwalkerSpec() end
    if cs == "HUNTER_BM" then return IsPlayerHunter() and IsPlayerBMHunterSpec() end
    return false
end

------------------------------------------------------------------------
-- Icon registration
------------------------------------------------------------------------
local iconObjs = {}

local function RegisterIcons()
    local _migrate = { bok = "Black Out Kick!", sck = "Dance of Chi-JI", tod = "Touch of Death", rwk = "Rushing Wind Kick" }
    for oldKey, newKey in pairs(_migrate) do
        if SpellGlowTrackerDB[oldKey] and not SpellGlowTrackerDB[newKey] then
            SpellGlowTrackerDB[newKey] = SpellGlowTrackerDB[oldKey]
        end
    end
    for _, def in ipairs(SLOT_DEFS) do
        if IsSlotEligible(def) then
            local k = def.key
            if not SpellGlowTrackerDB[k] then
                SpellGlowTrackerDB[k] = DefaultSlotDB(def.x, def.y, def.iconSpellID)
            end
            local db = SpellGlowTrackerDB[k]

            local iconObj = shmIcons:Register(ADDON, k, db, {
                onResize = function(sq)
                    db.size = sq
                    local fs = timerTexts[k]
                    if fs then
                        fs:SetFont("Fonts\\FRIZQT__.TTF", sq * 0.6, "OUTLINE")
                    end
                end,
                onMove = function() end,
            })

            shmIcons:SetIcon(ADDON, k, def.iconTexture or C_Spell.GetSpellTexture(def.iconSpellID))
            shmIcons:SetVisible(ADDON, k, false)

            iconObjs[k] = iconObj

            if def.timerKey then
                AttachTimerText(k, iconObj, db.size)
            end
        end
    end

    iconsRegistered = true
    shmIcons:RestoreSnapGroups()
    if not lockCallbackRegistered and shmIcons and shmIcons.RegisterLockCallback then
        lockCallbackRegistered = true
        shmIcons:RegisterLockCallback(function(locked)
            if locked then
                for k in pairs(iconObjs) do
                    shmIcons:SetGlow(ADDON, k, false)
                    shmIcons:SetVisible(ADDON, k, false)
                end
                for _, entry in pairs(TIMED_ENTRIES) do entry.endTime = 0 end
                tickerFrame:Hide()
            end
        end)
    end
end

------------------------------------------------------------------------
-- Timer helpers
------------------------------------------------------------------------
local function SetTimerText(key, t)
    local fs = timerTexts[key]
    if not fs then return end
    if t > 0 then
        fs:SetText(string.format("%d", math.ceil(t)))
    else
        fs:SetText("")
    end
end

------------------------------------------------------------------------
-- Countdown ticker
------------------------------------------------------------------------
tickerFrame = CreateFrame("Frame")
tickerFrame:Hide()

local function StartTicker() tickerFrame:Show() end
local function MaybeStopTicker()
    for _, entry in pairs(TIMED_ENTRIES) do
        if entry.endTime > 0 then return end
    end
    tickerFrame:Hide()
end

tickerFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local anyActive = false
    for _, entry in pairs(TIMED_ENTRIES) do
        local remaining = 0
        if entry.endTime > 0 then
            remaining = entry.endTime - now
            if remaining < 0 then remaining = 0 end
            if remaining > 0 then anyActive = true end
        end
        if entry.timerKey then
            _G[entry.timerKey] = remaining
            SetTimerText(entry.key, remaining)
        end
    end
    if not anyActive then tickerFrame:Hide() end
end)

------------------------------------------------------------------------
-- Proc state registry
------------------------------------------------------------------------
local PROC_REGISTRY = {
    [100784] = { globalKey = "bok_proc_active",  key = "Black Out Kick!",  timerKey = "bok_proc_timer",  buffDuration = 15, endTime = 0 },
    [101546] = { globalKey = "docj_proc_active", key = "Dance of Chi-JI",   timerKey = "docj_proc_timer", buffDuration = 15, endTime = 0 },
    [322109] = { globalKey = "tod_proc_active",  key = "Touch of Death" },
    [107428] = { globalKey = "rwk_proc_active",  key = "Rushing Wind Kick", timerKey = "rwk_proc_timer",  buffDuration = 15, endTime = 0 },
    -- Hunter procs
    [34026]  = { globalKey = "howl_proc_active",          key = "Howl of the Pack Leader", timerKey = "howl_proc_timer",         buffDuration = 29, endTime = 0 },
    [466930] = { globalKey = "black_arrow_proc_active",   key = "Black Arrow" },
    [392060] = { globalKey = "wailing_arrow_proc_active", key = "Wailing Arrow",            timerKey = "wailing_arrow_proc_timer", buffDuration = 15, endTime = 0 },
    [193455] = { globalKey = "hogstrider_proc_active",    key = "Hogstrider",               timerKey = "hogstrider_proc_timer",   buffDuration = 19, endTime = 0 },
}

TIMED_ENTRIES = {}
for _, entry in pairs(PROC_REGISTRY) do
    if entry.timerKey then
        table.insert(TIMED_ENTRIES, entry)
    end
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
    if not iconsRegistered then RegisterIcons() end
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    if iconsRegistered then
        for k in pairs(iconObjs) do
            shmIcons:Unregister(ADDON, k)
            timerTexts[k] = nil
            iconObjs[k] = nil
        end
        iconsRegistered = false
    end
    for _, entry in pairs(PROC_REGISTRY) do
        _G[entry.globalKey] = false
        if entry.timerKey then
            entry.endTime = 0
            _G[entry.timerKey] = 0
        end
    end
    tickerFrame:Hide()
end

local function UpdateEnabledState()
    local hasEligible = false
    for _, def in ipairs(SLOT_DEFS) do
        if IsSlotEligible(def) then hasEligible = true break end
    end
    DisableAddon()
    if hasEligible then EnableAddon() end
end

------------------------------------------------------------------------
-- Slash command
------------------------------------------------------------------------
SLASH_SPELLGLOWTRACKER1 = "/sgt"
SLASH_SPELLGLOWTRACKER2 = "/SGT"
SlashCmdList["SPELLGLOWTRACKER"] = function(msg)
    print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
    print("  |cffffd700/shm lock|r  -- toggle move/resize mode for all shmIcons")
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
    _G["howl_proc_active"] = false
    _G["black_arrow_proc_active"]   = false
    _G["wailing_arrow_proc_active"] = false
    for _, entry in pairs(TIMED_ENTRIES) do
        entry.endTime = 0
    end
    tickerFrame:Hide()
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
        local entry = PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = true
            shmIcons:SetVisible(ADDON, entry.key, true)
            shmIcons:SetGlow(ADDON, entry.key, true)
            if entry.timerKey then
                entry.endTime = GetTime() + entry.buffDuration
                StartTicker()
            end
        end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if not addonEnabled then return end
        local entry = PROC_REGISTRY[arg1]
        if entry then
            _G[entry.globalKey] = false
            shmIcons:SetGlow(ADDON, entry.key, false)
            shmIcons:SetVisible(ADDON, entry.key, false)
            if entry.timerKey then
                entry.endTime = 0
                _G[entry.timerKey] = 0
                SetTimerText(entry.key, 0)
                MaybeStopTicker()
            end
        end
    end
end)
