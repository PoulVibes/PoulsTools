-- 1. MAIN FRAME & DATABASE SETUP
local f = CreateFrame("Frame", "SBAEnhancedFrame", UIParent)
f:SetFrameStrata("LOW")
f:SetMovable(true); f:SetResizable(true)
if f.SetResizeBounds then f:SetResizeBounds(32, 32, 256, 256) end
f:EnableMouse(true); f:RegisterForDrag("LeftButton")

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

-- 2. TEXTURE & COOLDOWN LAYERS
local icon = f:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(f)

local gcd = CreateFrame("Cooldown", "SBAEnhancedGCD", f, "CooldownFrameTemplate")
gcd:SetAllPoints(f)
gcd:SetFrameLevel(f:GetFrameLevel() + 1)
gcd:SetDrawEdge(true)
gcd:SetSwipeColor(0, 0, 0, 0.7)
gcd:SetHideCountdownNumbers(true)

-- 3. RESIZE HANDLE
local rb = CreateFrame("Button", nil, f)
rb:SetPoint("BOTTOMRIGHT"); rb:SetSize(16, 16)
rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- 4. LOGGER SETUP
local lastLoggedMessage = ""
local lastLoggedMessage2 = ""
local logger = CreateFrame("ScrollingMessageFrame", "SBAELoggerFrame", UIParent, "BackdropTemplate")
logger:SetSize(300, 150)
logger:SetFontObject(ChatFontNormal)
logger:SetJustifyH("LEFT")
logger:SetMaxLines(50)
logger:SetFading(false)
logger:SetMovable(true); logger:EnableMouse(true); logger:RegisterForDrag("LeftButton")
logger:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
logger:SetBackdropColor(0, 0, 0, 0.5)

local function LogOverride(oldID, newID)
    if not SBA_Enhanced_DB or not SBA_Enhanced_DB.debug or oldID == newID then return end
    local oldInfo = C_Spell.GetSpellInfo(oldID)
    local newInfo = C_Spell.GetSpellInfo(newID)
    if oldInfo and newInfo then
        local msg = oldInfo.name .. " -> " .. newInfo.name
        if msg ~= lastLoggedMessage then
            logger:AddMessage("|cFF00FF00[SBAE]|r " .. msg)
            lastLoggedMessage = msg
        end
    end
end

local function LogMessage(msg)
    if not SBA_Enhanced_DB or not SBA_Enhanced_DB.debug then return end
	--if msg ~= lastLoggedMessage2 then
		logger:AddMessage("|cFF00FF00[SBAE]|r " .. msg)
		lastLoggedMessage2 = msg
	--end
end

-- 5. SLASH COMMAND LOGIC
SLASH_SBAE1 = "/sbae"
SlashCmdList["SBAE"] = function(msg)
    if msg == "lock" then
        SBA_Enhanced_DB.locked = not SBA_Enhanced_DB.locked
        local state = SBA_Enhanced_DB.locked and "Locked" or "Unlocked"
        print("|cFF00FF00SBA Enhanced:|r Frames are now " .. state)
        if SBA_Enhanced_DB.locked then rb:Hide() else rb:Show() end
    elseif msg == "debug" then
        SBA_Enhanced_DB.debug = not SBA_Enhanced_DB.debug
        if SBA_Enhanced_DB.debug then logger:Show() else logger:Hide() end
        print("|cFF00FF00SBA Enhanced:|r Debug " .. (SBA_Enhanced_DB.debug and "Enabled" or "Disabled"))
    else
        print("|cFF00FF00SBA Enhanced Commands:|r /sbae lock, /sbae debug")
    end
end

-- 6. INTERACTION & SAVING
f:SetScript("OnDragStart", function(self)
    if not SBA_Enhanced_DB.locked and not InCombatLockdown() then self:StartMoving() end
end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    SBA_Enhanced_DB.pos = { p = point, rp = relPoint, x = x, y = y }
end)

logger:SetScript("OnDragStart", function(self)
    if not SBA_Enhanced_DB.locked and not InCombatLockdown() then self:StartMoving() end
end)
logger:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    SBA_Enhanced_DB.logPos = { p = point, rp = relPoint, x = x, y = y }
end)

rb:SetScript("OnMouseDown", function() 
    if not SBA_Enhanced_DB.locked and not InCombatLockdown() then f:StartSizing("BOTTOMRIGHT") end 
end)
rb:SetScript("OnMouseUp", function() 
    f:StopMovingOrSizing() 
    SBA_Enhanced_DB.size = { w = f:GetWidth(), h = f:GetHeight() }
end)

-- 7. EVENT HANDLER
f:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == "SBA_Enhanced" then
        -- Initialize Database with explicit check for missing fields
        SBA_Enhanced_DB = SBA_Enhanced_DB or {}
        SBA_Enhanced_DB.size = SBA_Enhanced_DB.size or {w = 64, h = 64}
        SBA_Enhanced_DB.pos = SBA_Enhanced_DB.pos or {p = "CENTER", rp = "CENTER", x = 0, y = 0}
        SBA_Enhanced_DB.logPos = SBA_Enhanced_DB.logPos or {p = "CENTER", rp = "CENTER", x = 350, y = 0}
        
        if SBA_Enhanced_DB.locked == nil then SBA_Enhanced_DB.locked = false end
        if SBA_Enhanced_DB.debug == nil then SBA_Enhanced_DB.debug = false end
        
        -- Apply settings
        self:SetSize(SBA_Enhanced_DB.size.w, SBA_Enhanced_DB.size.h)
        self:ClearAllPoints()
        self:SetPoint(SBA_Enhanced_DB.pos.p, UIParent, SBA_Enhanced_DB.pos.rp, SBA_Enhanced_DB.pos.x, SBA_Enhanced_DB.pos.y)
        
        logger:ClearAllPoints()
        logger:SetPoint(SBA_Enhanced_DB.logPos.p, UIParent, SBA_Enhanced_DB.logPos.rp, SBA_Enhanced_DB.logPos.x, SBA_Enhanced_DB.logPos.y)
        
        if SBA_Enhanced_DB.locked then rb:Hide() else rb:Show() end
        if SBA_Enhanced_DB.debug then logger:Show() else logger:Hide() end
        self:Show()
    elseif event == "PLAYER_REGEN_DISABLED" then 
        rb:Hide()
        logger:Clear()
        lastLoggedMessage = ""
    elseif event == "PLAYER_REGEN_ENABLED" then 
        if not SBA_Enhanced_DB.locked then rb:Show() end
    end
end)

-- 8. ROTATION LOGIC
local updateInterval = 0.1
local timeSinceLastUpdate = 0
local GCD_ID= 61304
-- Rotational Core
local TP_ID              = 100780  -- Tiger Palm
local RSK_ID             = 107428  -- Rising Sun Kick
local BOK_ID             = 100784  -- Blackout Kick
local FOF_ID             = 113656  -- Fists of Fury
local SCK_ID             = 101546  -- Spinning Crane Kick

-- 12.0.1 New & Talent Abilities
local WDP_ID             = 152175  -- Whirling Dragon Punch
local SW_ID   			 = 1217413 -- New in 12.0.1 (Replaces certain procs)
local RWK_ID             = 1250566 -- New in 12.0.1 (Replaces RSK in some builds)
local SOTW_ID            = 392983  -- Strike of the Windlord


-- Utility & Cooldowns (on GCD)
local TOD_ID             = 322109
local CJL_ID             = 117952  -- Crackling Jade Lightning


local function OverrideSBA(spellID)
	local chi = UnitPower("player", Enum.PowerType.Chi)
--Priorities
	--1.) TOD
	if C_Spell.IsSpellUsable(TOD_ID) and not C_Spell.GetSpellCooldown(TOD_ID) then return TOD_ID end
	--if tod_proc_active or spellID==TOD_ID then return TOD_ID end
	
	--2.) WDP
	if (IsPlayerSpell(WDP_ID) and not C_Spell.GetSpellCooldown(WDP_ID).isActive and C_Spell.IsSpellUsable(WDP_ID)) or spellID == WDP_ID then return WDP_ID end
	
	--3.) TP to not cap energy
	if (not ZenithActiveTracker or (ZenithActiveTracker and not IsPlayerSpell(1249832))) and chi < 4 and not bok_proc_active and (spellID == TP_ID or currentEnergy > 85) and LastComboStrikeSpellID ~= TP_ID then 
		return TP_ID end
    
	--4.) SOTW
	if (IsPlayerSpell(SOTW_ID) and not C_Spell.GetSpellCooldown(SOTW_ID).isActive and C_Spell.IsSpellUsable(SOTW_ID)) or spellID == SOTW_ID then return SOTW_ID end
	
	--5.) FOF
	--if not C_Spell.GetSpellCooldown(FOF_ID).isActive and C_Spell.IsSpellUsable(FOF_ID) then return FOF_ID end
	if (not C_Spell.GetSpellCooldown(FOF_ID).timeUntilEndOfStartRecovery and C_Spell.IsSpellUsable(FOF_ID)) or spellID == FOF_ID then return FOF_ID end
	
	--6.) RWK
	if (chi > 0 and ZenithActiveTracker and rwk_proc_active) or (chi > 1 and rwk_proc_active) or spellID==RWK_ID then return RWK_ID end
	
	--7.) SCK - to not waste procs
	if  not ZenithActiveTracker and docj_proc_active and docj_proc_timer < 4 and not bok_proc_active  and LastComboStrikeSpellID ~= SCK_ID then return SCK_ID end
	
	--8.) RSK
	if (not C_Spell.GetSpellCooldown(RSK_ID).isActive and C_Spell.IsSpellUsable(RSK_ID)) or (chi>0 and ZenithActiveTracker and spellID==RSK_ID) or (chi>1 and spellID==RSK_ID) then return RSK_ID end
	
	--8.5) BOK to build chi during zenith
	 if ZenithActiveTracker and LastComboStrikeSpellID ~= BOK_ID then return BOK_ID end
	
	--9.) TP to use high ability
	if not (C_Spell.GetSpellCooldown(RSK_ID).isActive or (IsPlayerSpell(RWK_ID) and not C_Spell.GetSpellCooldown(RWK_ID).isActive) or not C_Spell.GetSpellCooldown(FOF_ID).isActive or (IsPlayerSpell(SOTW_ID) and not C_Spell.GetSpellCooldown(SOTW_ID).isActive)) and chi < 3 and LastComboStrikeSpellID ~= TP_ID then
		return TP_ID
	end
	
	--10.) BOK with Proc or Zenith
	if (ZenithActiveTracker or bok_proc_active) and LastComboStrikeSpellID ~= BOK_ID then return BOK_ID end
	
	--11.) Zenith SCK
	if ZenithActiveTracker and chi > 3 then return SCK_ID end
	
	--12.) Slicing Winds
	if IsPlayerSpell(SW_ID) and not C_Spell.GetSpellCooldown(SW_ID).isActive and C_Spell.IsSpellUsable(SW_ID) then return SW_ID end
	
	
	--13.) chi ji Proc
	if docj_proc_active and LastComboStrikeSpellID ~= SCK_ID then return SCK_ID end
	
	--14.) BOK
	if (chi > 1 or (chi == 1 and LastComboStrikeSpellID == TP_ID)) and LastComboStrikeSpellID ~= BOK_ID then return BOK_ID end
	
	
	if spellID == SCK_ID then return SCK_ID end
	
	--15.) TP last resort
	if LastComboStrikeSpellID ~= TP_ID then return TP_ID end
	
	--16.) CJL last resort
	if LastComboStrikeSpellID == TP_ID then return CJL_ID end

	--if ZenithActiveTracker then
    --    if not C_Spell.GetSpellCooldown(FOF_ID).isActive and C_Spell.IsSpellUsable(FOF_ID) then
    --        return FOF_ID
    --    elseif not C_Spell.GetSpellCooldown(RSK_ID).isActive and C_Spell.IsSpellUsable(RSK_ID) then
    --        return RSK_ID
    --    elseif not C_Spell.GetSpellCooldown(WDP_ID).isActive then
    --        return WDP_ID            
    --    elseif spellID == TP_ID and LastComboStrikeSpellID ~= BOK_ID then 
    --        return BOK_ID
    --    end
    --elseif spellID == RSK_ID and not C_Spell.IsSpellUsable(RSK_ID) and LastComboStrikeSpellID ~= TP_ID then
    --    return TP_ID
    --elseif spellID == BOK_ID and (chi == 1 or chi == 3) and LastComboStrikeSpellID ~= TP_ID then 
    --    return TP_ID
    --end
	return spellID
end


f:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        timeSinceLastUpdate = 0
        
        local originalSpellID = C_AssistedCombat.GetNextCastSpell() or TP_ID
        local spellID = originalSpellID
        

        spellID = OverrideSBA(spellID)

        if spellID ~= originalSpellID then LogOverride(originalSpellID, spellID) end

        local texture = C_Spell.GetSpellTexture(spellID)
        if texture then
            icon:SetTexture(texture)
            local cdInfo = C_Spell.GetSpellCooldown(GCD_ID)
            if cdInfo and cdInfo.startTime then gcd:SetCooldown(cdInfo.startTime, cdInfo.duration) else gcd:Clear() end
            
            if C_Spell.IsSpellUsable(spellID) then
                icon:SetDesaturated(false); icon:SetVertexColor(1, 1, 1, 1)
            else
                icon:SetDesaturated(true); icon:SetVertexColor(0.4, 0.4, 0.4, 1)
            end
        end
    end
end)
