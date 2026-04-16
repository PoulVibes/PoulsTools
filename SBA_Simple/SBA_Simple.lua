-- SBA_Simple.lua
-- Displays the next suggested cast from C_AssistedCombat using shmIcons.

local ADDON_NAME = "SBA_Simple"
local ICON_KEY   = "nextcast"

SBA_SimpleDB = SBA_SimpleDB or {}

-- ── Default DB schema (shmIcons will write x/y/size back on move/resize) ──
local function GetDB()
    local db = SBA_SimpleDB
    if db.x            == nil then db.x             = 0        end
    if db.y            == nil then db.y             = 0        end
    if db.point        == nil then db.point         = "CENTER" end
    if db.size         == nil then db.size          = 64       end
    if db.enabled      == nil then db.enabled       = true     end
    if db.glow_enabled == nil then db.glow_enabled  = false    end
    if db.overrideCode == nil then db.overrideCode  = ""       end
    return db
end

-- ── Override logic ────────────────────────────────────────────────────────
-- Compiles and runs saved override code. The code is expected to return a
-- spellID (number) or nil. If it returns a valid number that overrides the
-- C_AssistedCombat suggestion. Errors are swallowed silently per-frame to
-- avoid chat spam; compile errors are caught once at save time instead.

local overrideChunk = nil  -- compiled function, rebuilt when code is saved

local function CompileOverride(code)
    if not code or code:match("^%s*$") then
        overrideChunk = nil
        return true, nil
    end
    local chunk, err = loadstring(code)
    if not chunk then
        return false, err
    end
    overrideChunk = chunk
    return true, nil
end

local function Override()
    if not overrideChunk then return nil end
    local ok, result = pcall(overrideChunk)
    if not ok or type(result) ~= "number" then return nil end
    return result
end

-- ── Registration ──────────────────────────────────────────────────────────
local function RegisterIcon()
    local db = GetDB()
    shmIcons:Register(ADDON_NAME, ICON_KEY, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function()   end,
    })
    shmIcons:RestoreSnapGroups()
end

-- ── Per-frame update ──────────────────────────────────────────────────────
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function()
    -- Override() takes priority over the assisted combat suggestion
    local spellID = Override() or C_AssistedCombat.GetNextCastSpell()

    -- ── Icon texture ─────────────────────────────────────────────────────
    if spellID then
        local iconID = C_Spell.GetSpellTexture(spellID) or 134400
        shmIcons:SetIcon(ADDON_NAME, ICON_KEY, iconID)
    else
        shmIcons:SetIcon(ADDON_NAME, ICON_KEY, 134400)
    end

    -- ── Cooldown ─────────────────────────────────────────────────────────
    if spellID then
        local cdInfo         = C_Spell.GetSpellCooldown(spellID)
        local durationObject = C_Spell.GetSpellCooldownDuration(spellID)
        local chargeInfo     = C_Spell.GetSpellCharges(spellID)

        if chargeInfo and chargeInfo.maxCharges > 1 then
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, durationObject)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            elseif durationObject then
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, durationObject)
            else
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            end
            shmIcons:SetStacks(ADDON_NAME, ICON_KEY, chargeInfo.currentCharges)
        else
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, durationObject)
            else
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
            end
            shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            shmIcons:SetStacks(ADDON_NAME, ICON_KEY, 0)
        end

        -- ── Range ─────────────────────────────────────────────────────────
        if UnitExists("target") then
            shmIcons:SetRange(ADDON_NAME, ICON_KEY, C_Spell.IsSpellInRange(spellID, "target"))
        else
            shmIcons:SetRange(ADDON_NAME, ICON_KEY, nil)
        end

        -- ── Usability ─────────────────────────────────────────────────────
        shmIcons:SetUsable(ADDON_NAME, ICON_KEY, C_Spell.IsSpellUsable(spellID))
    else
        shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetStacks(ADDON_NAME, ICON_KEY, 0)
        shmIcons:SetRange(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetUsable(ADDON_NAME, ICON_KEY, true)
    end

    shmIcons:SetGlow(ADDON_NAME, ICON_KEY, false)
end)

-- ── Events ────────────────────────────────────────────────────────────────
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        shmIcons:Unregister(ADDON_NAME, ICON_KEY)
        RegisterIcon()
        -- Re-compile any saved override code on load/spec change
        local db = GetDB()
        if db.overrideCode and not db.overrideCode:match("^%s*$") then
            CompileOverride(db.overrideCode)
        end
    end
end)

-- ── Dev Override Frame ────────────────────────────────────────────────────
local function CreateOverrideFrame()
    local f = CreateFrame("Frame", "SBAS_OverrideFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 420)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left=11, right=12, top=12, bottom=11 },
    })

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("SBA Simple — Override Logic")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local scroll = CreateFrame("ScrollFrame", "SBAS_OverrideScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",  16, -44)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 48)

    local editBox = CreateFrame("EditBox", "SBAS_OverrideEditBox", scroll)
    editBox:SetSize(scroll:GetWidth(), 1)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(0)
    editBox:SetTextInsets(6, 6, 4, 4)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self)
        local needed = self:GetNumLines() * 14 + 16
        self:SetHeight(math.max(needed, scroll:GetHeight()))
    end)

    scroll:SetScrollChild(editBox)

    -- Populate editbox with any previously saved code on show, then focus it
    f:SetScript("OnShow", function()
        local db = GetDB()
        editBox:SetText(db.overrideCode or "")
        editBox:SetFocus()
    end)

    -- Cursor position display (Line X, Col Y)
    local cursorLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorLabel:SetPoint("BOTTOMLEFT", scroll, "BOTTOMLEFT", 4, -18)
    cursorLabel:SetText("Ln 1, Col 1")

    local function UpdateCursorPos()
        local pos  = editBox:GetCursorPosition()
        local text = editBox:GetText()
        local line, col = 1, 1
        for i = 1, pos do
            local c = text:sub(i, i)
            if c == "\n" then
                line = line + 1
                col  = 1
            else
                col = col + 1
            end
        end
        cursorLabel:SetText("Ln " .. line .. ", Col " .. col)
    end

    editBox:HookScript("OnCursorChanged", function() UpdateCursorPos() end)
    editBox:HookScript("OnTextChanged",   function() UpdateCursorPos() end)

    local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    btn:SetSize(140, 28)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    btn:SetText("Override Logic")
    btn:SetScript("OnClick", function()
        local code = editBox:GetText()
        local db   = GetDB()

        -- Save code to DB regardless of whether it compiles
        db.overrideCode = code

        -- Attempt compile; report errors but keep the save
        local ok, err = CompileOverride(code)
        if not ok then
            print("|cffff4444SBAS compile error:|r " .. tostring(err))
        else
            if code:match("^%s*$") then
                print("|cff00ff99SBA_Simple:|r Override cleared.")
            else
                print("|cff00ff99SBA_Simple:|r Override logic saved and active.")
            end
        end
    end)

    return f
end

local overrideFrame = CreateOverrideFrame()

-- ── Slash command ─────────────────────────────────────────────────────────
SLASH_SBASIMPLE1 = "/SBAS"
SlashCmdList["SBASIMPLE"] = function(msg)
    local cmd = msg:match("^%s*(.-)%s*$"):lower()
    if cmd == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    elseif cmd == "override" then
        if overrideFrame:IsShown() then
            overrideFrame:Hide()
        else
            overrideFrame:Show()
        end
    else
        print("|cff00ccffSBA_Simple|r commands:")
        print("  /SBAS lock      — toggle move/resize lock for all shmIcons")
        print("  /SBAS override  — toggle the override logic editor")
    end
end