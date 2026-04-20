local ADDON_NAME = "PoulsTools_VivifyProcTracker"

-- Addon table
local VPT = {}
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        VPT:OnInitialize()
    end
end)

-- Configuration & IDs
local VIVIFY_SPELL_ID            = 116670
local RSK_SPELL_ID               = 107428
local RWK_SPELL_ID               = 467307
local VIVACIOUS_VIVIFICATION_MW  = 137024  -- Mistweaver
local VIVACIOUS_VIVIFICATION_WW  = 388812  -- Windwalker / Brewmaster
local PROC_DURATION   = 20
local timerHandle     = nil
local procActive      = false
local hasTalent       = false

local function UpdateTalentState()
    hasTalent = IsPlayerSpell(VIVACIOUS_VIVIFICATION_MW) or IsPlayerSpell(VIVACIOUS_VIVIFICATION_WW)
end

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

    -- Hide this addon's icon when shmIcons are locked
    if shmIcons and shmIcons.RegisterLockCallback then
        shmIcons:RegisterLockCallback(function(locked)
            if locked then
                shmIcons:SetVisible(ADDON_NAME, "vivify", false)
                shmIcons:SetCooldownRaw(ADDON_NAME, "vivify", 0, 0)
                shmIcons:SetGlow(ADDON_NAME, "vivify", false)
            end
        end)
    end

    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:SetScript("OnEvent", function(self, event, ...)        VPT:UNIT_SPELLCAST_SUCCEEDED(event, ...)
    end)

    -- Slash Command: /vpt lock  →  delegates to shmIcons global lock toggle
    SLASH_VPT1 = "/vpt"
    SlashCmdList["VPT"] = function(msg)
        if msg:lower() == "lock" then
            local locked = shmIcons:ToggleLock()
            print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
        end
    end
end

local function FireVivifyEvent(event)
    if _G.VivifyProc_OnEvent then
        _G.VivifyProc_OnEvent(event)
    end
end

function VPT:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit ~= "player" then return end
    UpdateTalentState()

    -- Trigger the Proc
    if (spellID == RSK_SPELL_ID or spellID == RWK_SPELL_ID) and hasTalent then
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
            FireVivifyEvent("VIVIFY_PROC_CONSUMED")
        else
            FireVivifyEvent("VIVIFY_NORMAL_CAST")
        end
    end
end
