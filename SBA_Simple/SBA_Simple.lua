-- SBA_Simple.lua
-- Displays the next suggested cast from C_AssistedCombat using shmIcons.

local ADDON_NAME = "SBA_Simpled"
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
    -- spellID left nil; filled each frame from C_AssistedCombat
    return db
end

-- ── Registration ──────────────────────────────────────────────────────────
local function RegisterIcon()
    local db = GetDB()
    shmIcons:Register(ADDON_NAME, ICON_KEY, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function()   end,  -- db updated in-place by library
    })
    shmIcons:RestoreSnapGroups()
end

-- ── Per-frame update ──────────────────────────────────────────────────────
--
-- Reads the next suggested spell from the Assisted Combat system and pushes
-- icon texture, cooldown (with charge support), stacks, range, and usability
-- to shmIcons. All secret-value rules from the integration guide are followed:
--   - cdInfo.isActive used only as an `if` condition, never compared.
--   - startTime/duration never touched; DurationObject passed opaquely.
--   - IsSpellInRange gated behind UnitExists("target") to avoid nil crash.
--   - IsSpellUsable() and IsSpellInRange() passed directly (secret booleans).
--   - chargeInfo.currentCharges passed to SetStacks; library handles issecretvalue.
--   - chargeInfo.maxCharges compared freely (non-secret structural data).

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function()
    local spellID = C_AssistedCombat.GetNextCastSpell()

    -- ── Icon texture ─────────────────────────────────────────────────────
    if spellID then
        local iconID = C_Spell.GetSpellTexture(spellID) or 134400
        shmIcons:SetIcon(ADDON_NAME, ICON_KEY, iconID)
    else
        shmIcons:SetIcon(ADDON_NAME, ICON_KEY, 134400)  -- question-mark fallback
    end

    -- ── Cooldown ─────────────────────────────────────────────────────────
    if spellID then
        local cdInfo         = C_Spell.GetSpellCooldown(spellID)
        local durationObject = C_Spell.GetSpellCooldownDuration(spellID)
        local chargeInfo     = C_Spell.GetSpellCharges(spellID)

        if chargeInfo and chargeInfo.maxCharges > 1 then
            -- Charge spell: two-frame technique
            if durationObject and cdInfo and cdInfo.isActive then
                -- All charges exhausted: full cooldown sweep
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, durationObject)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            elseif durationObject then
                -- Has charges, one recharging: edge-only (no dark swipe overlay)
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, durationObject)
            else
                -- Fully recharged
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
                shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            end

            -- Safe: currentCharges is secret in combat; library guards internally
            shmIcons:SetStacks(ADDON_NAME, ICON_KEY, chargeInfo.currentCharges)
        else
            -- Non-charge spell
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, durationObject)
            else
                shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
            end
            shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
            shmIcons:SetStacks(ADDON_NAME, ICON_KEY, 0)
        end

        -- ── Range ─────────────────────────────────────────────────────────
        -- UnitExists gate is required: IsSpellInRange returns nil with no target,
        -- which crashes SetVertexColorFromBoolean inside shmIcons.
        if UnitExists("target") then
            -- Secret boolean — pass directly; library calls SetVertexColorFromBoolean
            shmIcons:SetRange(ADDON_NAME, ICON_KEY, C_Spell.IsSpellInRange(spellID, "target"))
        else
            shmIcons:SetRange(ADDON_NAME, ICON_KEY, nil)  -- nil = white (no target)
        end

        -- ── Usability ─────────────────────────────────────────────────────
        -- Secret boolean — pass directly; library calls SetVertexColorFromBoolean
        local usable = C_Spell.IsSpellUsable(spellID)
        shmIcons:SetUsable(ADDON_NAME, ICON_KEY, usable)
    else
        -- No suggested spell: clear everything
        shmIcons:SetCooldown(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetChargeCooldown(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetStacks(ADDON_NAME, ICON_KEY, 0)
        shmIcons:SetRange(ADDON_NAME, ICON_KEY, nil)
        shmIcons:SetUsable(ADDON_NAME, ICON_KEY, true)
    end

    -- Glow is always off per design requirement
    shmIcons:SetGlow(ADDON_NAME, ICON_KEY, false)
end)

-- ── Events ────────────────────────────────────────────────────────────────
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Re-register (handles spec changes cleanly)
        shmIcons:Unregister(ADDON_NAME, ICON_KEY)
        RegisterIcon()
    end
end)

-- ── Dev Override Frame ───────────────────────────────────────────────────
-- A large editable frame for live-executing arbitrary Lua during development.
-- loadstring() compiles the entered string as a Lua chunk; pcall() catches
-- any runtime errors and prints them rather than crashing the addon.
-- NOTE: loadstring is available in the Midnight Lua runtime but Blizzard may
-- block it in future patches. This is intentionally a developer tool only.

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

    -- Title bar
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("SBAS Lua Override")

    -- Close button (top-right)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ScrollFrame + EditBox (fills most of the frame)
    local scroll = CreateFrame("ScrollFrame", "SBAS_OverrideScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",  16, -44)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 48)

    local editBox = CreateFrame("EditBox", "SBAS_OverrideEditBox", scroll)
    editBox:SetSize(scroll:GetWidth(), 1)  -- height grows with content
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(0)               -- no character limit
    editBox:SetTextInsets(6, 6, 4, 4)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)

    -- Grow height to fit content so scrolling works correctly
    editBox:SetScript("OnTextChanged", function(self)
        local needed = self:GetNumLines() * 14 + 16
        self:SetHeight(math.max(needed, scroll:GetHeight()))
    end)

    scroll:SetScrollChild(editBox)

    -- Override button
    local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    btn:SetSize(120, 28)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    btn:SetText("Override")
    btn:SetScript("OnClick", function()
        local code = editBox:GetText()
        if not code or code:match("^%s*$") then
            print("|cffff4444SBAS:|r Override frame is empty.")
            return
        end

        -- Compile the chunk; loadstring returns (fn, err) or (nil, err)
        local chunk, compileErr = loadstring(code)
        if not chunk then
            print("|cffff4444SBAS compile error:|r " .. tostring(compileErr))
            return
        end

        -- Execute with pcall to catch runtime errors
        local ok, runErr = pcall(chunk)
        if not ok then
            print("|cffff4444SBAS runtime error:|r " .. tostring(runErr))
        else
            print("|cff00ff99SBAS:|r Override executed successfully.")
        end
    end)

    return f
end

local overrideFrame = CreateOverrideFrame()

-- ── Slash command ─────────────────────────────────────────────────────────
-- /SBAS lock — delegates to shmIcons shared lock so the icon can be
-- moved/resized alongside any other shmIcons addon icons.
SLASH_SBASIMPLE1 = "/SBAS"
SlashCmdList["SBASNHANCED"] = function(msg)
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
        print("  /SBAS override  — toggle the Lua override editor")
    end
end