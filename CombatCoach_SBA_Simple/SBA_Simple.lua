-- SBA_Simple.lua
-- Displays the next suggested cast from C_AssistedCombat using shmIcons.

local FOLDER_NAME    = "CombatCoach_SBA_Simple"
local ADDON_NAME     = "Rotation Assistant"
local ICON_KEY       = "Suggested_Spell"
local MAX_EXTRA_TABS = 4   -- tabs 2-5 (tab 1 is the main ICON_KEY)

-- spellID -> isOnGCD; populated for every spell that has been shown in the icon.
-- Updated on SPELL_UPDATE_COOLDOWN so SetStacks can ignore GCD-only lockouts.
local spellGCDState = {}

-- The spellID currently shown in the icon; used by SPELL_UPDATE_CHARGES.
local currentDisplayedSpellID = nil

-- Extra-tab tracking (tabs 2-5)
local activeExtraTabCount  = 0    -- how many extra icons are currently registered
local extraDisplayedSpell  = {}   -- [tabIdx] -> currently displayed spellID
local extraOverrideChunks  = {}   -- [tabIdx] -> compiled override function

SBA_SimpleDB = SBA_SimpleDB or {}

-- ── Extra-icon DB (one entry per extra tab, keyed by tab index) ─────────
local function GetExtraIconDB(tabIdx)
    SBA_SimpleDB.extraIcons = SBA_SimpleDB.extraIcons or {}
    local key = "tab" .. tabIdx
    if not SBA_SimpleDB.extraIcons[key] then
        SBA_SimpleDB.extraIcons[key] = {
            x = 0, y = 0, point = "CENTER",
            size = 64, enabled = true, glow_enabled = false,
        }
    end
    return SBA_SimpleDB.extraIcons[key]
end

-- ── Default DB schema (shmIcons will write x/y/size back on move/resize) ──
local function GetDB()
    local db = SBA_SimpleDB
    db.specs = db.specs or {}
    if db.x            == nil then db.x             = 0        end
    if db.y            == nil then db.y             = 0        end
    if db.point        == nil then db.point         = "CENTER" end
    if db.size         == nil then db.size          = 64       end
    if db.enabled      == nil then db.enabled       = true     end
    if db.glow_enabled == nil then db.glow_enabled  = false    end
    if db.overrideCode == nil then db.overrideCode  = ""       end
    if db.overrideDebug == nil then db.overrideDebug = true     end
    return db
end

-- Return the current specialization ID (0 when not set)
local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID or 0
end

-- Return the per-spec sub-table for specials; creates and seeds from
-- the global overrideCode when first created for backward compatibility.
local function GetSpecDB(specID)
    specID = specID or GetCurrentSpecID()
    local db = GetDB()
    db.specs = db.specs or {}
    db.specs[specID] = db.specs[specID] or {}
    if db.specs[specID].overrideCode == nil then
        db.specs[specID].overrideCode = db.overrideCode or ""
    end
    return db.specs[specID]
end

-- ── Override logic ────────────────────────────────────────────────────────
-- Compiles and runs saved override code. The code is expected to return a
-- spellID (number) or nil. If it returns a valid number that overrides the
-- C_AssistedCombat suggestion. Errors are swallowed silently per-frame to
-- avoid chat spam; compile errors are caught once at save time instead.

local overrideChunk = nil  -- compiled function, rebuilt when code is saved (tab 1)

-- target spec we're editing via the override editor (nil -> current spec)
local overrideEditorTargetSpec = nil
local overrideEditorTargetName = nil
local overrideEditorPreviewCode = nil
local overrideEditorPreviewMode = false
local lastOverrideRuntimeError = nil
local lastOverrideRuntimeErrorAt = 0

local function ReportOverrideRuntimeError(err)
    local db = GetDB()
    if not db.overrideDebug then return end
    local msg = tostring(err or "unknown error")
    local now = GetTime and GetTime() or 0
    if msg == lastOverrideRuntimeError and (now - lastOverrideRuntimeErrorAt) < 2 then
        return
    end
    lastOverrideRuntimeError = msg
    lastOverrideRuntimeErrorAt = now
    print("|cffff4444SBA_Simple override runtime error:|r " .. msg)
end

local function CompileOverride(code)
    if not code or code:match("^%s*$") then
        overrideChunk = nil
        return true, nil
    end
    local chunk, err = loadstring(code)
    if not chunk then
        ReportOverrideRuntimeError(err)
        return false, err
    end
    overrideChunk = chunk
    return true, nil
end

local function Override()
    if not overrideChunk then return nil end
    local ok, result = pcall(overrideChunk)
    if not ok then
        ReportOverrideRuntimeError(result)
        return nil
    end
    if result == nil then return nil end
    if type(result) ~= "number" then
        ReportOverrideRuntimeError("override returned non-number: " .. type(result))
        return nil
    end
    return result
end

-- ── Extra-tab override compile/run ──────────────────────────────────────
local function CompileExtraOverride(tabIdx, code)
    if not code or code:match("^%s*$") then
        extraOverrideChunks[tabIdx] = nil
        return
    end
    local chunk = loadstring(code)
    extraOverrideChunks[tabIdx] = chunk  -- nil on compile failure
end

local function RunExtraOverride(tabIdx)
    local chunk = extraOverrideChunks[tabIdx]
    if not chunk then return nil end
    local ok, result = pcall(chunk)
    if not ok or type(result) ~= "number" then return nil end
    return result
end

-- Public API: allows the GUI builder to push compiled override code for the
-- current spec without needing direct access to the local CompileOverride closure.
function SBA_Simple_SetOverrideCode(code)
    local specID = GetCurrentSpecID()
    local specDB = GetSpecDB(specID)
    specDB.overrideCode = code or ""
    GetDB().overrideCode = code or ""
    CompileOverride(code or "")
end

-- ── Registration ──────────────────────────────────────────────────────────
local function RegisterIcon()
    local db = GetDB()
    db.spellName = "Rotation"
    shmIcons:Register(ADDON_NAME, ICON_KEY, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function()   end,
    })
    shmIcons:RestoreSnapGroups()
    -- Ensure the icon visibility follows the DB setting
    if shmIcons and shmIcons.SetVisible then
        shmIcons:SetVisible(ADDON_NAME, ICON_KEY, (db.enabled ~= false))
    end
end

local function RegisterExtraIcon(tabIdx)
    local db  = GetExtraIconDB(tabIdx)
    local key = ICON_KEY .. "_" .. tabIdx
    -- Label shown in CombatCoach menu; updated when the tab is renamed
    if not db.spellName then
        SBA_SimpleDB.tabNames = SBA_SimpleDB.tabNames or {}
        local specID = GetCurrentSpecID()
        local names  = SBA_SimpleDB.tabNames[specID] or {}
        db.spellName = names[tabIdx] or ("Tab " .. tabIdx)
    end
    shmIcons:Register(ADDON_NAME, key, db, {
        onResize = function(sq) db.size = sq end,
        onMove   = function()   end,
    })
    shmIcons:SetVisible(ADDON_NAME, key, db.enabled ~= false)
end

local function UnregisterExtraIcon(tabIdx)
    shmIcons:Unregister(ADDON_NAME, ICON_KEY .. "_" .. tabIdx)
end

-- Adjust the set of registered extra icons and (re-)compile their overrides.
-- Called on spec change and when the GUI adds/removes a tab.
local function UpdateExtraIconsForSpec(specID)
    specID = specID or GetCurrentSpecID()
    if specID == 0 then return end
    SBA_SimpleDB.tabCount = SBA_SimpleDB.tabCount or {}
    local newTotal = math.max(1, tonumber(SBA_SimpleDB.tabCount[specID]) or 1)
    local newExtra = newTotal - 1

    -- Unregister icons beyond the new count
    for i = newExtra + 2, activeExtraTabCount + 1 do
        UnregisterExtraIcon(i)
        extraOverrideChunks[i] = nil
        extraDisplayedSpell[i] = nil
    end
    -- Register newly needed icons
    for i = activeExtraTabCount + 2, newExtra + 1 do
        RegisterExtraIcon(i)
        extraDisplayedSpell[i] = nil
    end
    activeExtraTabCount = newExtra

    -- (Re-)compile override code for each active extra tab
    local specEntry = SBA_SimpleDB.specs and SBA_SimpleDB.specs[specID]
    for i = 2, newExtra + 1 do
        local code = specEntry and specEntry["overrideCode_" .. i] or ""
        CompileExtraOverride(i, code)
    end
end

-- Public: called from OverrideGUI when a tab is renamed so the CombatCoach
-- menu label updates immediately without needing a re-register.
function SBA_Simple_SetTabName(tabIdx, name)
    if tabIdx == 1 then
        local db = GetDB()
        db.spellName = name or "Rotation"
        return
    end
    local db = GetExtraIconDB(tabIdx)
    db.spellName = name or ("Tab " .. tabIdx)
end

-- Public: called from OverrideGUI when the user adds or removes a tab
function SBA_Simple_UpdateTabCount(specID, newCount)
    SBA_SimpleDB.tabCount          = SBA_SimpleDB.tabCount or {}
    SBA_SimpleDB.tabCount[specID]  = math.max(1, newCount)
    UpdateExtraIconsForSpec(specID)
end

-- Public: store and live-apply override codes for all tabs of a spec.
-- codes[1] = tab-1 code, codes[2] = tab-2 code, etc.
function SBA_Simple_SetAllTabOverrideCodes(specID, codes)
    SBA_SimpleDB.specs         = SBA_SimpleDB.specs or {}
    SBA_SimpleDB.specs[specID] = SBA_SimpleDB.specs[specID] or {}
    local specEntry = SBA_SimpleDB.specs[specID]
    for i, code in ipairs(codes or {}) do
        if i == 1 then
            specEntry.overrideCode   = code
            specEntry.overrideSource = "gui"
        else
            specEntry["overrideCode_" .. i] = code
        end
    end
    SBA_SimpleDB.overrideCode = specEntry.overrideCode or ""
    -- Apply live only when editing the current spec
    if specID == GetCurrentSpecID() then
        CompileOverride(specEntry.overrideCode or "")
        for i = 2, activeExtraTabCount + 1 do
            CompileExtraOverride(i, specEntry["overrideCode_" .. i] or "")
        end
    end
end


-- Public helpers for UI to control the icon live
function SBA_Simple_SetEnabled(enabled)
    local db = GetDB()
    db.enabled = enabled
    if shmIcons and shmIcons.SetVisible then
        shmIcons:SetVisible(ADDON_NAME, ICON_KEY, enabled)
    end
end

function SBA_Simple_SetSize(size)
    local db = GetDB()
    db.size = tonumber(size) or db.size
    if shmIcons and shmIcons.Unregister then
        shmIcons:Unregister(ADDON_NAME, ICON_KEY)
    end
    -- Recreate the icon with the updated size
    RegisterIcon()
end

-- ── Shared per-icon update helper ────────────────────────────────────────
-- Updates texture, cooldown sweep, stacks, range, usability for one icon.
-- gcdState is a shared spellID->isOnGCD table; prevSpellID is what was shown
-- last frame (used to decide when to re-query charges).
-- Returns spellID (to store as new prevSpellID).
local function UpdateShmIcon(iconKey, spellID, prevSpellID)
    -- Stacks: refresh when spell first seen or when it changes
    if spellID then
        if spellGCDState[spellID] == nil then
            spellGCDState[spellID] = false
            local ci = C_Spell.GetSpellCharges(spellID)
            if ci and ci.maxCharges and ci.maxCharges > 1 then
                shmIcons:SetStacks(ADDON_NAME, iconKey, ci.currentCharges)
            end
        elseif spellID ~= prevSpellID then
            local ci = C_Spell.GetSpellCharges(spellID)
            if ci and ci.maxCharges and ci.maxCharges > 1 then
                shmIcons:SetStacks(ADDON_NAME, iconKey, ci.currentCharges)
            end
        end
    end

    -- Icon texture
    shmIcons:SetIcon(ADDON_NAME, iconKey,
        spellID and (C_Spell.GetSpellTexture(spellID) or 134400) or 134400)

    if spellID then
        local cdInfo         = C_Spell.GetSpellCooldown(spellID)
        local durationObject = C_Spell.GetSpellCooldownDuration(spellID)
        local chargeInfo     = C_Spell.GetSpellCharges(spellID)
        local isChargeSpell  = chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1
        local chargeDuration = C_Spell.GetSpellChargeDuration(spellID)
        shmIcons:SetGlow(ADDON_NAME, iconKey, false)
        if isChargeSpell then
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, iconKey, durationObject)
            elseif chargeDuration and chargeInfo and chargeInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, iconKey, chargeDuration)
            else
                shmIcons:SetCooldown(ADDON_NAME, iconKey, nil)
            end
            if cdInfo and (not cdInfo.isActive or cdInfo.isOnGCD) then
                shmIcons:SetStacks(ADDON_NAME, iconKey, chargeInfo.currentCharges)
            else
                shmIcons:SetStacks(ADDON_NAME, iconKey, 0)
            end
        else
            if durationObject and cdInfo and cdInfo.isActive then
                shmIcons:SetCooldown(ADDON_NAME, iconKey, durationObject)
            else
                shmIcons:SetCooldown(ADDON_NAME, iconKey, nil)
            end
            shmIcons:SetStacks(ADDON_NAME, iconKey, 0)
        end
        if UnitExists("target") then
            shmIcons:SetRange(ADDON_NAME, iconKey, C_Spell.IsSpellInRange(spellID, "target"))
        else
            shmIcons:SetRange(ADDON_NAME, iconKey, nil)
        end
        shmIcons:SetUsable(ADDON_NAME, iconKey, C_Spell.IsSpellUsable(spellID))
    else
        shmIcons:SetCooldown(ADDON_NAME, iconKey, nil)
        shmIcons:SetStacks(ADDON_NAME, iconKey, 0)
        shmIcons:SetRange(ADDON_NAME, iconKey, nil)
        shmIcons:SetUsable(ADDON_NAME, iconKey, true)
    end
    shmIcons:SetGlow(ADDON_NAME, iconKey, false)
    return spellID
end

-- ── Per-frame update ──────────────────────────────────────────────────────
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function()
    -- Tab 1: main icon
    local spellID = Override() or C_AssistedCombat.GetNextCastSpell()
    currentDisplayedSpellID = UpdateShmIcon(ICON_KEY, spellID, currentDisplayedSpellID)

    -- Extra tabs (tabs 2+)
    for tabIdx = 2, activeExtraTabCount + 1 do
        local db = GetExtraIconDB(tabIdx)
        if db.enabled ~= false then
            local extraSpell = RunExtraOverride(tabIdx) or C_AssistedCombat.GetNextCastSpell()
            extraDisplayedSpell[tabIdx] = UpdateShmIcon(
                ICON_KEY .. "_" .. tabIdx, extraSpell, extraDisplayedSpell[tabIdx])
        end
    end
end)

-- ── Monk add-on loader ───────────────────────────────────────────────────
local MONK_ADDONS = {
    "CombatCoach_VivifyProcTracker",
    "CombatCoach_ComboTracker",
    "CombatCoach_SpellGlowTracker",
    "CombatCoach_EnergyGuesstimator",
    "CombatCoach_GuesstimatorHaste",
    
}

local monkAddonsLoaded = false
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

-- ── Events ────────────────────────────────────────────────────────────────
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
--events:RegisterEvent("SPELL_UPDATE_CHARGES")
events:SetScript("OnEvent", function(_, event)
    if event == "SPELL_UPDATE_COOLDOWN" then
        for sid in pairs(spellGCDState) do
            local cd = C_Spell.GetSpellCooldown(sid)
            spellGCDState[sid] = cd and cd.isOnGCD or false
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        LoadMonkAddons()
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        shmIcons:Unregister(ADDON_NAME, ICON_KEY)
        RegisterIcon()
        -- Re-setup extra icons for the new spec
        C_Timer.After(0, function() UpdateExtraIconsForSpec(GetCurrentSpecID()) end)
        -- Defer override compilation by one frame so spec data is fully available.
        -- GetSpecialization() may return nil during PLAYER_ENTERING_WORLD otherwise.
        C_Timer.After(0, function()
            local specDB = GetSpecDB()
            local code = specDB.overrideCode or GetDB().overrideCode
            if code and not code:match("^%s*$") then
                CompileOverride(code)
            elseif not specDB.overrideSource then
                -- No user-saved override yet for this spec; try to use the
                -- recommended optimized code as the default.
                local defaultCode = _G.SBAS_GetDefaultOverrideCodeForSpec
                                    and _G.SBAS_GetDefaultOverrideCodeForSpec(GetCurrentSpecID())
                CompileOverride(defaultCode or nil)
            else
                CompileOverride(nil)
            end
        end)
    end
end)

-- ── Dev Override Frame ────────────────────────────────────────────────────
local function CreateOverrideFrame()
    local f = CreateFrame("Frame", "SBAS_OverrideFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    -- default size: 30% of screen width, 80% of screen height (unless saved)
    local db = GetDB()
    local uiw, uih = UIParent:GetWidth() or 1024, UIParent:GetHeight() or 768
    local defaultW = math.max(320, math.floor(uiw * 0.30))
    local defaultH = math.max(120, math.floor(uih * 0.80))
    f:SetResizable(true)
    f:SetSize(defaultW, defaultH)
    f:SetScale(2.0)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:SetFrameStrata("DIALOG")
    f:SetHitRectInsets(-8, -8, -8, -8)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropBorderColor(0.5, 0.5, 0.5)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("SBA Simple — Override Logic")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Save / restore position
    function f:SavePosition()
        local db = GetDB()
        local left = self:GetLeft()
        local bottom = self:GetBottom()
        if left and bottom then
            db.x = left
            db.y = bottom
        end
        db.width = self:GetWidth()
        db.height = self:GetHeight()
    end

    -- dragging to move
    f:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
        self.isMoving = true
    end)
    f:SetScript("OnMouseUp", function(self, button)
        if self.isMoving then
            self:StopMovingOrSizing()
            self:SavePosition()
            self.isMoving = false
        end
    end)

    -- resize grip
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetHitRectInsets(-2, -8, -2, -8)
    resizeGrip:SetFrameStrata("HIGH")
    resizeGrip:SetScript("OnMouseDown", function(self)
        self:GetParent():StartSizing("BOTTOMRIGHT")
        self:GetParent().isSizing = true
    end)
    resizeGrip:SetScript("OnMouseUp", function(self)
        local p = self:GetParent()
        if p.isSizing then
            p:StopMovingOrSizing()
            p:SavePosition()
            p.isSizing = false
        end
    end)

    -- make ESC close this panel via UISpecialFrames
    table.insert(UISpecialFrames, "SBAS_OverrideFrame")

    local scroll = CreateFrame("ScrollFrame", "SBAS_OverrideScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",  16, -44)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 48)

    local editBox = CreateFrame("EditBox", "SBAS_OverrideEditBox", scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetMaxLetters(0)
    editBox:SetTextInsets(6, 6, 4, 4)
    editBox:EnableMouse(true)
    editBox:SetCountInvisibleLetters(false)
    editBox:SetIgnoreParentAlpha(true)
    editBox:SetHyperlinksEnabled(true)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self)
        local needed = self:GetNumLines() * 14 + 16
        self:SetHeight(math.max(needed, scroll:GetHeight()))
    end)

    -- Make the editbox fill the scroll area so it receives mouse/cursor events
    editBox:SetAllPoints()
    -- Keep the editbox width in sync when the scroll frame is resized
    scroll:SetScript("OnSizeChanged", function(_, w, h) editBox:SetWidth(w) end)
    -- Clicking the scroll area focuses the editbox and places the caret at end
    scroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    scroll:SetScript("OnMouseUp", function()
        editBox:SetFocus()
        editBox:SetCursorPosition(editBox:GetNumLetters())
    end)

    -- Keep the caret visible when it moves by adjusting vertical scroll
    scroll:HookScript("OnVerticalScroll", function(self, offset)
        local editH = editBox:GetHeight()
        editBox:SetHitRectInsets(0, 0, offset, editH - offset - self:GetHeight())
    end)

    scroll:HookScript("OnScrollRangeChanged", function(self, xrange, yrange)
        if yrange == 0 then
            editBox:SetHitRectInsets(0, 0, 0, 0)
        else
            local offset = self:GetVerticalScroll()
            local editH = editBox:GetHeight()
            editBox:SetHitRectInsets(0, 0, offset, editH - offset - self:GetHeight())
        end
    end)

    -- Support dragging spells/items into the editbox (inserts name at caret)
    local function OnReceiveDrag()
        local ctype, id, info, extra = GetCursorInfo()
        if ctype == "spell" then
            if C_Spell and C_Spell.GetSpellName then
                info = C_Spell.GetSpellName(extra)
            else
                info = GetSpellInfo(id, info)
            end
        elseif ctype ~= "item" then
            return
        end
        ClearCursor()
        if not editBox:HasFocus() then
            editBox:SetFocus()
            editBox:SetCursorPosition(editBox:GetNumLetters())
        end
        editBox:Insert(info)
    end

    editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
    scroll:SetScript("OnReceiveDrag", OnReceiveDrag)

    editBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)

    scroll:SetScrollChild(editBox)

    -- Populate editbox on show.
    -- In preview mode we show temporary code that is not persisted unless
    -- the user explicitly clicks "Override Logic".
    f:SetScript("OnShow", function()
        local db = GetDB()
        -- restore saved position/size if present
        if db.x and db.y then
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", db.x, db.y)
        elseif db.point then
            f:ClearAllPoints()
            f:SetPoint(db.point)
        end
        if db.width and db.height then
            f:SetSize(db.width, db.height)
        end

        local specID = overrideEditorTargetSpec or GetCurrentSpecID()
        local specDB = GetSpecDB(specID)
        if overrideEditorPreviewMode and overrideEditorPreviewCode ~= nil then
            editBox:SetText(overrideEditorPreviewCode)
        else
            editBox:SetText(specDB.overrideCode or "")
        end
        editBox:SetFocus()
        if overrideEditorTargetName then
            local suffix = overrideEditorPreviewMode and " (Preview)" or ""
            title:SetText("SBA Simple — Override Logic: " .. overrideEditorTargetName .. suffix)
        else
            local suffix = overrideEditorPreviewMode and " (Preview)" or ""
            title:SetText("SBA Simple — Override Logic" .. suffix)
        end
    end)

    -- Closing without pressing Override should discard any preview buffer.
    f:SetScript("OnHide", function()
        overrideEditorPreviewCode = nil
        overrideEditorPreviewMode = false
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

    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        self.cursorOffset = y
        self.cursorHeight = h
        self.handleCursorChange = true
        self:SetScript("OnUpdate", function(frame, elapsed)
            frame:SetScript("OnUpdate", nil)
            ScrollingEdit_OnUpdate(frame, elapsed, scroll)
            UpdateCursorPos()
        end)
    end)
    editBox:SetScript("OnTextChanged", function() UpdateCursorPos() end)

    local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    btn:SetSize(140, 28)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    btn:SetText("Override Logic")
    btn:SetScript("OnClick", function()
        local code = editBox:GetText()
        local specID = overrideEditorTargetSpec or GetCurrentSpecID()
        local specDB = GetSpecDB(specID)
        specDB.overrideCode   = code
        specDB.overrideSource = "code"
        -- mirror to top-level for legacy compatibility
        GetDB().overrideCode = code

        -- quick compile check; only make live if editing current spec
        local chunk, err = loadstring(code)
        if not chunk then
            print("|cffff4444SBAS compile error:|r " .. tostring(err))
        else
            if specID == GetCurrentSpecID() then
                overrideChunk = chunk
            end
            if code:match("^%s*$") then
                print("|cff00ff99SBA_Simple:|r Override cleared for spec " .. tostring(specID))
            else
                print("|cff00ff99SBA_Simple:|r Override logic saved for spec " .. tostring(specID))
            end
        end
        overrideEditorTargetSpec = nil
        overrideEditorTargetName = nil
        overrideEditorPreviewCode = nil
        overrideEditorPreviewMode = false
        f:Hide()
        -- Code override makes the analyzer irrelevant; hide it if open
        local af = _G["SBAS_OverrideAnalyzerFrame"]
        if af and af:IsShown() then af:Hide() end
    end)

    return f
end

local overrideFrame = CreateOverrideFrame()

-- Open the override editor targeting a specific specID (and optional display name)
function SBA_Simple_ShowOverrideForSpec(specID, displayName)
    overrideEditorTargetSpec = specID
    overrideEditorTargetName = displayName
    overrideEditorPreviewCode = nil
    overrideEditorPreviewMode = false
    if overrideFrame then overrideFrame:Show() end
end

-- Open the override editor with temporary preview code that is not saved
-- unless the user clicks "Override Logic".
function SBA_Simple_ShowOverridePreview(code, specID, displayName)
    overrideEditorTargetSpec = specID
    overrideEditorTargetName = displayName
    overrideEditorPreviewCode = code or ""
    overrideEditorPreviewMode = true
    if overrideFrame then overrideFrame:Show() end
end

-- ── Slash command ─────────────────────────────────────────────────────────
SLASH_SBASIMPLE1 = "/SBAS"
SlashCmdList["SBASIMPLE"] = function(msg)
    local cmd = msg:match("^%s*(.-)%s*$"):lower()
    if cmd == "lock" then
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    elseif cmd == "reset" then
        local db = GetDB()
        db.x = 0
        db.y = 0
        db.point = "CENTER"
        db.size = 64
        if shmIcons and shmIcons.Unregister then shmIcons:Unregister(ADDON_NAME, ICON_KEY) end
        RegisterIcon()
        print("|cff00ff99SBA_Simple:|r Icon position and size reset.")
    elseif cmd == "override" then
        if overrideFrame:IsShown() then
            overrideFrame:Hide()
        else
            -- always open editor for the current specialization
            SBA_Simple_ShowOverrideForSpec(nil)
        end
    elseif cmd == "override_debug" then
        local db = GetDB()
        db.overrideDebug = not db.overrideDebug
        print("|cff00ff99SBA_Simple:|r override runtime debug " .. (db.overrideDebug and "enabled." or "disabled."))
    elseif cmd == "override_error" then
        if lastOverrideRuntimeError then
            print("|cffff4444SBA_Simple override last error:|r " .. lastOverrideRuntimeError)
        else
            print("|cff00ff99SBA_Simple:|r no runtime override error recorded yet.")
        end
    else
        print("|cff00ccffSBA_Simple|r commands:")
        print("  /SBAS lock          — toggle move/resize lock for all shmIcons")
        print("  /SBAS override      — toggle the raw Lua override code editor")
        print("  /SBAS override_debug — toggle runtime override error prints")
        print("  /SBAS override_error — print the last runtime override error")
        --override GUI not fully functional still in development
        --print("  /SBAS override_gui  — open the graphical priority-list builder")
        print("  /SBAS reset         — reset icon position and size")
    end
end