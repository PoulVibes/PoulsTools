local ADDON_NAME = "VivifyProcTracker"

-- Initialize AceAddon
local VPT = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0")

-- Configuration & IDs
local VIVIFY_SPELL_ID = 116670
local RSK_SPELL_ID    = 107428
local RWK_SPELL_ID    = 467307
local PROC_DURATION   = 20
local timerHandle     = nil
local procActive      = false

local REQUIRED_CLASS = "MONK"
local function IsPlayerMonk()
    local _, classToken = UnitClass("player")
    return classToken == REQUIRED_CLASS
end

function VPT:OnInitialize()
    -- Setup Saved Variables with shmIcons-compatible schema
    VivifyProcTrackerDB = VivifyProcTrackerDB or {
        point        = "CENTER",
        x            = 0,
        y            = -100,
        size         = 50,
        enabled      = true,
        glow_enabled = false,
    }

    -- Migrate legacy width/height fields to size
    local db = VivifyProcTrackerDB
    if db.width and not db.size then
        db.size   = db.width
        db.width  = nil
        db.height = nil
    end

    -- Only enable this addon for Monks
    if not IsPlayerMonk() then
        return
    end

    -- Register icon with shmIcons; library owns the frame
    shmIcons:Register(ADDON_NAME, "vivify", db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function(_db) end,
    })
    shmIcons:SetIcon(ADDON_NAME, "vivify", C_Spell.GetSpellTexture(VIVIFY_SPELL_ID))
    shmIcons:SetVisible(ADDON_NAME, "vivify", false)

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    -- Slash Command: /vpt lock  →  delegates to shmIcons global lock toggle
    SLASH_VPT1 = "/vpt"
    SlashCmdList["VPT"] = function(msg)
        if msg:lower() == "lock" then
            local locked = shmIcons:ToggleLock()
            print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
        end
    end
end

function VPT:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit ~= "player" then return end

    -- Trigger the Proc
    if spellID == RSK_SPELL_ID or spellID == RWK_SPELL_ID then
        procActive = true
        shmIcons:SetVisible(ADDON_NAME, "vivify", true)
        shmIcons:SetCooldownRaw(ADDON_NAME, "vivify", GetTime(), PROC_DURATION)
        shmIcons:SetGlow(ADDON_NAME, "vivify", false)

        if timerHandle then timerHandle:Cancel() end
        timerHandle =  C_Timer.NewTimer(PROC_DURATION, function()
            procActive = false
            if timerHandle then timerHandle:Cancel() end
            timerHandle = nil
            shmIcons:SetVisible(ADDON_NAME, "vivify", false)
            shmIcons:SetCooldownRaw(ADDON_NAME, "vivify", 0, 0)
            shmIcons:SetGlow(ADDON_NAME, "vivify", false)
        end)

    -- Handle Vivify Logic
    elseif spellID == VIVIFY_SPELL_ID then
        if procActive then
            -- Proc consumed by this cast
            procActive = false
            if timerHandle then timerHandle:Cancel() end
            timerHandle = nil
            shmIcons:SetVisible(ADDON_NAME, "vivify", false)
            shmIcons:SetCooldownRaw(ADDON_NAME, "vivify", 0, 0)
            shmIcons:SetGlow(ADDON_NAME, "vivify", false)
            self:SendMessage("VIVIFY_PROC_CONSUMED")
        else
            self:SendMessage("VIVIFY_NORMAL_CAST")
        end
    end
end
