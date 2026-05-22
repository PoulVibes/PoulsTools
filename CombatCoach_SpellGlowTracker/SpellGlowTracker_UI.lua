-- SpellGlowTracker_UI.lua
-- Icon registration, timer display, countdown ticker, and slash command.
-- Loads after SpellGlowTracker_Config.lua, before SpellGlowTracker.lua.

local SGT   = SpellGlowTracker
local ADDON = "Spell Glow Tracker"
local VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and
    C_AddOns.GetAddOnMetadata("CombatCoach_SpellGlowTracker", "Version")) or "1.2.1"
local ICON_SIZE_DEFAULT = 64

------------------------------------------------------------------------
-- Per-file state
------------------------------------------------------------------------
local timerTexts            = {}   -- key -> FontString
local iconObjs              = {}   -- key -> icon object returned by shmIcons
local iconsRegistered       = false
local lockCallbackRegistered = false

------------------------------------------------------------------------
-- Timer FontString helpers
------------------------------------------------------------------------
local function AttachTimerText(key, iconObj, size)
    if not iconObj or not iconObj.frame then return end
    local fs = iconObj.frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size * 0.6, "OUTLINE")
    fs:SetPoint("CENTER", iconObj.frame, "CENTER", 0, 0)
    fs:SetTextColor(1, 0.4, 0.8, 1)
    fs:SetText("")
    timerTexts[key] = fs
end

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
local TICKER_INTERVAL = 0.1
local tickerElapsed   = 0
local tickerFrame     = CreateFrame("Frame")
tickerFrame:Hide()

tickerFrame:SetScript("OnUpdate", function(self, elapsed)
    tickerElapsed = tickerElapsed + elapsed
    if tickerElapsed < TICKER_INTERVAL then return end
    tickerElapsed = 0

    local now      = GetTime()
    local anyActive = false
    for _, entry in pairs(SGT.TIMED_ENTRIES) do
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

function SpellGlowTracker_StartTicker()
    tickerFrame:Show()
end

function SpellGlowTracker_StopTicker()
    tickerFrame:Hide()
end

------------------------------------------------------------------------
-- Icon registration / unregistration
------------------------------------------------------------------------
function SpellGlowTracker_RegisterIcons()
    if iconsRegistered then return end

    -- Migrate old single-key DB entries to new key format
    local _migrate = { bok = "Black Out Kick!", sck = "Dance of Chi-JI", tod = "Touch of Death", rwk = "Rushing Wind Kick" }
    for oldKey, newKey in pairs(_migrate) do
        if SpellGlowTrackerDB[oldKey] and not SpellGlowTrackerDB[newKey] then
            SpellGlowTrackerDB[newKey] = SpellGlowTrackerDB[oldKey]
        end
    end

    for _, def in ipairs(SGT.SLOT_DEFS) do
        if SpellGlowTracker_IsSlotEligible(def) then
            local k = def.key
            if not SpellGlowTrackerDB[k] then
                SpellGlowTrackerDB[k] = {
                    x            = def.x,
                    y            = def.y,
                    point        = "CENTER",
                    size         = ICON_SIZE_DEFAULT,
                    enabled      = false,
                    glow_enabled = false,
                    spellID      = def.iconSpellID,
                }
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
                for _, entry in pairs(SGT.TIMED_ENTRIES) do entry.endTime = 0 end
                tickerFrame:Hide()
            end
        end)
    end
end

function SpellGlowTracker_UnregisterIcons()
    if not iconsRegistered then return end
    for k in pairs(iconObjs) do
        shmIcons:Unregister(ADDON, k)
        timerTexts[k] = nil
        iconObjs[k]   = nil
    end
    iconsRegistered = false
end

function SpellGlowTracker_AreIconsRegistered()
    return iconsRegistered
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
