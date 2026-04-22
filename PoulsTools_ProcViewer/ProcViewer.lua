-- ProcViewer.lua
-- Centered HUD proc icons using shmIcons for frame management.
--
-- Slots:
--   bok  : Blackout Kick       (glow event spell ID 100784)
--   sck  : Spinning Crane Kick (glow event spell ID 101546, Dance of Chi-Ji proc)
--   tod  : Touch of Death      (glow event spell ID 322109)
--   rwk  : Rushing Wind Kick   (glow event spell ID 107428 / RSK base)
--
-- Slash commands:
--   /pv        -- show help
--   /shm lock  -- lock/unlock all shmIcons (move/resize)
--
-- Version: 0.1.8
-- Compatible with WoW API 12.0.1 (Midnight)

------------------------------------------------------------------------
-- Saved variables
-- shmIcons writes position/size back into each db entry in-place.
-- Schema per slot: { x, y, point, size, enabled, glow_enabled, spellID }
------------------------------------------------------------------------
ProcViewerDB = ProcViewerDB or {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local ADDON             = "PoulsTools_ProcViewer"
local VERSION           = "0.1.8"
local ICON_SIZE_DEFAULT = 64
local GAP               = 8

local WINDWALKER_SPEC_ID = 269
local iconsRegistered = false
local addonEnabled = false
local procViewerInitialized = false

------------------------------------------------------------------------
-- Global proc-active booleans (readable by other addons)
------------------------------------------------------------------------
_G["bok_proc_active"]  = false
_G["docj_proc_active"] = false
_G["tod_proc_active"]  = false
_G["rwk_proc_active"]  = false

------------------------------------------------------------------------
-- Global countdown timers (seconds remaining; 0 when inactive)
-- tod has no timer — not a duration-based proc.
------------------------------------------------------------------------
_G["bok_proc_timer"]  = 0
_G["docj_proc_timer"] = 0
_G["rwk_proc_timer"]  = 0

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
    { key = "Black Out Kick!", x = -halfStep,  y =  halfStep, iconSpellID = 100784, timerKey = "bok_proc_timer",  buffDuration = 15 },
    { key = "Dance of Chi-JI",  x =  halfStep,  y =  halfStep, iconSpellID = 101546, timerKey = "docj_proc_timer", buffDuration = 15 },
    { key = "Touch of Death",   x = -halfStep,  y = -halfStep, iconSpellID = 322109, timerKey = nil },
    { key = "Rushing Wind Kick",x =  halfStep,  y = -halfStep, iconSpellID = 468179, timerKey = "rwk_proc_timer",  buffDuration = 15 },
}

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

-- TIMED_ENTRIES is populated later from PROC_REGISTRY; declare it
-- here so closures (e.g. lock callbacks) capture the local variable
-- rather than a global with the same name.
local TIMED_ENTRIES = nil   -- built after PROC_REGISTRY is defined (below)

-- `tickerFrame` is used in callbacks registered during icon registration.
-- Declare it here so closures capture the local upvalue rather than an
-- uninitialized global, avoiding "attempt to index global 'tickerFrame'".
local tickerFrame = nil
------------------------------------------------------------------------
-- Icon registration
------------------------------------------------------------------------
local iconObjs = {}   -- key -> shmIcons icon object

local function RegisterIcons()
    -- Migrate legacy short-key DB entries (bok/sck/tod/rwk) to
    -- human-friendly keys so existing saved positions are preserved.
    local _migrate = { bok = "Black Out Kick!", sck = "Dance of Chi-JI", tod = "Touch of Death", rwk = "Rushing Wind Kick" }
    for oldKey, newKey in pairs(_migrate) do
        if ProcViewerDB[oldKey] and not ProcViewerDB[newKey] then
            ProcViewerDB[newKey] = ProcViewerDB[oldKey]
        end
    end
    for _, def in ipairs(SLOT_DEFS) do
        local k = def.key
        -- Ensure DB entry exists with correct defaults
        if not ProcViewerDB[k] then
            ProcViewerDB[k] = DefaultSlotDB(def.x, def.y, def.iconSpellID)
        end
        local db = ProcViewerDB[k]

        local iconObj = shmIcons:Register(ADDON, k, db, {
            onResize = function(sq)
                db.size = sq
                -- Rescale the timer FontString to match new icon size
                local fs = timerTexts[k]
                if fs then
                    fs:SetFont("Fonts\\FRIZQT__.TTF", sq * 0.6, "OUTLINE")
                end
            end,
            onMove = function() end,  -- db updated in-place by library
        })

        shmIcons:SetIcon(ADDON, k, C_Spell.GetSpellTexture(def.iconSpellID))
        shmIcons:SetVisible(ADDON, k, false)

        iconObjs[k] = iconObj

        -- Attach timer FontString for timed procs
        if def.timerKey then
            AttachTimerText(k, iconObj, db.size)
        end
    end

    iconsRegistered = true
    shmIcons:RestoreSnapGroups()
    -- Hide all ProcViewer icons when shmIcons are locked
    if shmIcons and shmIcons.RegisterLockCallback then
        shmIcons:RegisterLockCallback(function(locked)
            if locked then
                for _, def in ipairs(SLOT_DEFS) do
                    shmIcons:SetGlow(ADDON, def.key, false)
                    shmIcons:SetVisible(ADDON, def.key, false)
                end
                -- clear timers
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
        _G[entry.timerKey] = remaining
        SetTimerText(entry.key, remaining)
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
}

-- Build timed-entries list for ticker (entries that have a timerKey)
TIMED_ENTRIES = {}
for _, entry in pairs(PROC_REGISTRY) do
    if entry.timerKey then
        table.insert(TIMED_ENTRIES, entry)
    end
end

-- Create event frame early so helper functions can register/unregister events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

------------------------------------------------------------------------
-- Enable/disable helpers (Monk + Windwalker checks)
------------------------------------------------------------------------
local function IsPlayerMonk()
    local _, classToken = UnitClass("player")
    return classToken == "MONK"
end

local function IsPlayerWindwalkerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == WINDWALKER_SPEC_ID
end

local function EnableAddon()
    if addonEnabled then return end
    addonEnabled = true
    if not iconsRegistered then RegisterIcons() end
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    --print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
    --print("  ProcViewer enabled (Windwalker).")
end

local function DisableAddon()
    if not addonEnabled then return end
    addonEnabled = false
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    for _, def in ipairs(SLOT_DEFS) do
        shmIcons:SetGlow(ADDON, def.key, false)
        shmIcons:SetVisible(ADDON, def.key, false)
    end
    _G["bok_proc_active"] = false
    _G["docj_proc_active"] = false
    _G["tod_proc_active"] = false
    _G["rwk_proc_active"] = false

    _G["bok_proc_timer"]  = 0
    _G["docj_proc_timer"] = 0
    _G["rwk_proc_timer"]  = 0

    for _, entry in pairs(TIMED_ENTRIES) do
        entry.endTime = 0
    end

    tickerFrame:Hide()
    --print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
    --print("  ProcViewer disabled (not Windwalker).")
end

local function UpdateEnabledState()
    if not IsPlayerMonk() then
        DisableAddon()
        return
    end
    if IsPlayerWindwalkerSpec() then
        EnableAddon()
    else
        DisableAddon()
    end
end

------------------------------------------------------------------------
-- Slash command
------------------------------------------------------------------------
SLASH_PROCVIEWER1 = "/pv"
SlashCmdList["PROCVIEWER"] = function(msg)
    print("|cff00ff00[" .. ADDON .. " v" .. VERSION .. "]|r")
    print("  |cffffd700/shm lock|r  -- toggle move/resize mode for all shmIcons")
end

------------------------------------------------------------------------
-- Event handler
------------------------------------------------------------------------
local function InitializeProcViewer()
    if procViewerInitialized then return end
    local _, classToken = UnitClass("player")
    if classToken ~= "MONK" then
        eventFrame:UnregisterAllEvents()
        return
    end
    procViewerInitialized = true
    if not iconsRegistered then RegisterIcons() end
    _G["bok_proc_timer"]  = 0
    _G["docj_proc_timer"] = 0
    _G["rwk_proc_timer"]  = 0
    for _, entry in pairs(TIMED_ENTRIES) do
        entry.endTime = 0
    end
    tickerFrame:Hide()
    UpdateEnabledState()
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        InitializeProcViewer()

    elseif event == "PLAYER_LOGIN" then
        InitializeProcViewer()

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
