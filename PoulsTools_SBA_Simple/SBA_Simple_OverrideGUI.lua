-- SBA_Simple_OverrideGUI.lua
-- Graphical priority-list override builder for SBA_Simple.
--
-- Usage:   /sbas override_gui     → open for the current spec
--
-- Rules are stored in SBA_SimpleDB.gui[specID] and compiled to
-- SBA_SimpleDB.specs[specID].overrideCode when saved.
-- The text-editor (/sbas override) still works independently.

-------------------------------------------------------------------------------
-- 1.  Condition type registry
--     Each entry defines one kind of condition that can be added to a rule.
--     Fields:
--       id            key stored in saved data
--       label         displayed in the picker
--       needsValue    (opt) true → show a numeric input field
--       valueLabel    (opt) label for the value field
--       default       (opt) default numeric value
--       needsSpell    (opt) true → show This Spell / Other Spell toggle
--       needsResource (opt) true → show resource type + operator selectors + value input
--       generate(cond, ruleSpellID) → Lua fragment string
-------------------------------------------------------------------------------
-- Resolves which spell ID to use: "this"/nil → rule's spell; number → that ID.
-- Also handles old saved data that used the targetID field.
local function ResolveSpell(c, s)
    if not c.spell or c.spell == "this" then return s end
    if type(c.spell) == "number"        then return c.spell end
    return c.targetID or s
end

local COND_TYPES = {
    -- Spell-based checks (needsSpell = true → picker shows This Spell / Other Spell toggle)
    { id = "on_cd",        label = "Ready (Off-Cooldown)",        shortLabel = "Ready",   needsSpell = true,
      generate = function(c, s) local id = ResolveSpell(c,s) return ("(not C_Spell.GetSpellCooldown(%d).isActive or C_Spell.GetSpellCooldown(%d).isOnGCD)"):format(id, id) end },
    { id = "reactive_enabled", label = "Reactive Spell Enabled",  shortLabel = "Enabled", needsSpell = true,
      generate = function(c, s) return ("C_Spell.GetSpellCooldown(%d).isEnabled"):format(ResolveSpell(c,s)) end },
    { id = "usable",       label = "Is Usable",                  shortLabel = "Usable",  needsSpell = true,
      generate = function(c, s) return ("C_Spell.IsSpellUsable(%d)"):format(ResolveSpell(c,s)) end },
    { id = "talented",     label = "Talented",                  needsSpell = true,
      generate = function(c, s) return ("IsPlayerSpell(%d)"):format(ResolveSpell(c,s)) end },
    { id = "last_combo_eq",label = "Last Combo Strike = Spell", needsSpell = true,
      generate = function(c, s) return ("LastComboStrikeSpellID == %d"):format(ResolveSpell(c,s)) end },
    -- SBA
    { id = "sba_suggests", label = "SBA Suggests", needsSpell = true,
      generate = function(c, s)
          local id = (not c.spell or c.spell == "this") and s
                     or (type(c.spell) == "number" and c.spell or c.targetID or s)
          return ("spellID == %d"):format(id)
      end },
    -- Resource (Chi / Energy with operator)
    { id = "resource",     label = "Resource Check", needsResource = true,
      generate = function(c, s)
          local var = (c.resource == "energy") and "currentEnergy" or "chi"
          local op  = c.operator or ">="
          return ("%s %s %d"):format(var, op, c.value or 0)
      end },
    -- Plugin / Proc (Zenith, BOK, RWK, DOCJ — pick via dropdown)
    { id = "plugin",       label = "Plugin / Proc", needsPlugin = true,
      generate = function(c, s)
          if c.plugin == "zenith"     then return "ZenithActiveTracker" end
          if c.plugin == "bok_proc"   then return "bok_proc_active" end
          if c.plugin == "rwk_proc"   then return "rwk_proc_active" end
          if c.plugin == "docj_proc"  then return "docj_proc_active" end
          if c.plugin == "docj_timer" then return ("docj_proc_timer %s %d"):format(c.operator or "<", c.value or 4) end
          return "false"
      end },
}

local COND_BY_ID = {}
for _, ct in ipairs(COND_TYPES) do COND_BY_ID[ct.id] = ct end

-- Plugin options shown inside the Plugin / Proc condition picker
local PLUGIN_OPTS = {
    { id = "zenith",     label = "Zenith Active"    },
    { id = "bok_proc",   label = "BOK Proc Active"  },
    { id = "rwk_proc",   label = "RWK Proc Active"  },
    { id = "docj_proc",  label = "DOCJ Proc Active" },
    { id = "docj_timer", label = "DOCJ Timer", needsValue = true, needsOperator = true, default = 4 },
}

-------------------------------------------------------------------------------
-- 2.  Data helpers
-------------------------------------------------------------------------------

-- The SBA "Single-Button Assistant" virtual button spell ID.
-- When a player tries to add this spell to the priority list we substitute
-- the spell that the Assisted Combat system is currently recommending.
local SBA_BUTTON_SPELL_ID = 1229376

-- Resolves a spell ID / name pair before inserting into the priority list.
-- Returns: resolvedID, resolvedName  (both nil if resolution fails)
local function ResolveSpellForAdd(id, name)
    return id, name
end

local function GuiDB()
    SBA_SimpleDB       = SBA_SimpleDB or {}
    SBA_SimpleDB.gui   = SBA_SimpleDB.gui or {}
    return SBA_SimpleDB.gui
end

local function GetGuiRules(specID)
    local db = GuiDB()
    db[specID] = db[specID] or {}
    return db[specID]
end

local function DeepCopyRules(src)
    local out = {}
    for i, r in ipairs(src) do
        local conds = {}
        for j, c in ipairs(r.conditions or {}) do
            conds[j] = {
                type     = c.type,
                value    = c.value,
                negate   = c.negate,
                spell    = c.spell,
                targetID = c.targetID,
                resource = c.resource,
                operator = c.operator,
                plugin   = c.plugin,
                junction = c.junction,
                lparen   = c.lparen,
                rparen   = c.rparen,
            }
        end
        out[i] = { spellID = r.spellID, name = r.name, conditions = conds }
    end
    return out
end

-------------------------------------------------------------------------------
-- 3.  Code generator
-------------------------------------------------------------------------------
local function CondSummaryText(cond, ruleSpellID)
    local def = COND_BY_ID[cond.type]
    if not def then return "[obsolete: " .. (cond.type or "?") .. "]" end
    local prefix = cond.negate and "NOT " or ""
    local t
    if def.needsResource then
        local resName = (cond.resource == "energy") and "Energy" or "Chi"
        local op      = cond.operator or ">="
        t = resName .. " " .. op .. " " .. tostring(cond.value or 0)
    elseif def.needsPlugin then
        local PLUGIN_LABELS = {
            zenith     = "Zenith Active",
            bok_proc   = "BOK Proc",
            rwk_proc   = "RWK Proc",
            docj_proc  = "DOCJ Proc",
            docj_timer = "DOCJ Timer",
        }
        local pLabel = PLUGIN_LABELS[cond.plugin] or (cond.plugin or "?")
        t = (cond.plugin == "docj_timer")
            and (pLabel .. " " .. (cond.operator or "<") .. " " .. tostring(cond.value or 4))
            or  pLabel
    else
        if def.needsSpell then
            if cond.type == "sba_suggests" then
                if not cond.spell or cond.spell == "this" then
                    t = "SBA = [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
                    t = "SBA = [" .. (n or "?") .. "]"
                end
            else
                t = def.label
                if not cond.spell or cond.spell == "this" then
                    t = t .. " [this]"
                else
                    local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                    local n = id and (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
                    t = t .. " [" .. (n or "?") .. "]"
                end
            end
        else
            t = def.label
        end
        if cond.value then t = t .. " " .. tostring(cond.value) end
    end
    return prefix .. t
end

local function GenerateCode(rules)
    if not rules or #rules == 0 then return nil end
    local L = {}
    L[#L+1] = "local spellID = C_AssistedCombat.GetNextCastSpell()"
    L[#L+1] = "local chi = UnitPower(\"player\", Enum.PowerType.Chi)"
    L[#L+1] = ""

    -- Pre-pass: build all condition fragments for every rule so we can count
    -- how many times each C_Spell.GetSpellCooldown(N) call appears across the
    -- entire output.  IDs that appear more than once across ANY rule will be
    -- hoisted into a single top-level local so no duplicate declarations are
    -- emitted when multiple rules reference the same spell's cooldown.
    local allRuleParts = {}   -- allRuleParts[i] = {parts=..., junctions=...}
    for i, rule in ipairs(rules) do
        if (rule.spellID or 0) > 0 then
            local parts        = {}
            local junctions    = {}
            local prevJunction = nil   -- junction stored on the PREVIOUS processed condition;
                                       -- cond.junction means "connect me to the NEXT condition",
                                       -- so it becomes the junction BEFORE the next part.
            for ci, cond in ipairs(rule.conditions or {}) do
                local def = COND_BY_ID[cond.type]
                if def then
                    local frag = def.generate(cond, rule.spellID)
                    if cond.negate then frag = "not (" .. frag .. ")" end
                    local lp = (cond.lparen or 0) > 0 and string.rep("(", cond.lparen) or ""
                    local rp = (cond.rparen or 0) > 0 and string.rep(")", cond.rparen) or ""
                    parts[#parts+1]         = lp .. frag .. rp
                    junctions[#junctions+1] = prevJunction   -- junction leading INTO this part
                    prevJunction            = cond.junction or "and"  -- junction leading OUT of this part
                end
            end
            allRuleParts[i] = { parts = parts, junctions = junctions }
        else
            allRuleParts[i] = false
        end
    end

    -- Count total occurrences of each spell-ID across all rules.
    local cdTotalCount = {}
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for _, part in ipairs(rp.parts) do
                for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                    cdTotalCount[id] = (cdTotalCount[id] or 0) + 1
                end
            end
        end
    end

    -- Emit one top-level local for each spell ID that appears more than once,
    -- then substitute the variable name into every part that references it.
    local hoisted = {}   -- set of IDs already emitted as top-level locals
    for id, count in pairs(cdTotalCount) do
        if count > 1 then
            local varName = "cd_" .. id
            L[#L+1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
            hoisted[id] = varName
        end
    end
    if next(hoisted) then L[#L+1] = "" end

    -- Substitute hoisted variable names into all pre-built parts.
    for _, rp in ipairs(allRuleParts) do
        if rp then
            for id, varName in pairs(hoisted) do
                local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                for pi, part in ipairs(rp.parts) do
                    rp.parts[pi] = part:gsub(pattern, varName)
                end
            end
        end
    end

    local hasUnconditional = false
    for i, rule in ipairs(rules) do
        local rp = allRuleParts[i]
        if rp then
            local parts     = rp.parts
            local junctions = rp.junctions

            -- Within a single rule, hoist any cooldown calls that repeat
            -- more than once inside that rule alone (not already hoisted globally).
            if #parts > 1 then
                local cdCount = {}
                for _, part in ipairs(parts) do
                    for id in part:gmatch("C_Spell%.GetSpellCooldown%((%d+)%)") do
                        if not hoisted[id] then
                            cdCount[id] = (cdCount[id] or 0) + 1
                        end
                    end
                end
                for id, count in pairs(cdCount) do
                    if count > 1 then
                        local varName = "cd_" .. id
                        L[#L+1] = ("local %s = C_Spell.GetSpellCooldown(%s)"):format(varName, id)
                        local pattern = "C_Spell%.GetSpellCooldown%(" .. id .. "%)"
                        for pi, part in ipairs(parts) do
                            parts[pi] = part:gsub(pattern, varName)
                        end
                        hoisted[id] = varName  -- prevent re-hoisting in later rules
                    end
                end
            end

            L[#L+1] = ("-- Priority %d: %s (%d)"):format(i, rule.name or "?", rule.spellID)
            if #parts > 0 then
                local expr = parts[1]
                for pi = 2, #parts do
                    expr = expr .. " " .. (junctions[pi] or "and") .. " " .. parts[pi]
                end
                if rule.spellID == SBA_BUTTON_SPELL_ID then
                    L[#L+1] = ("if %s then return spellID end"):format(expr)
                else
                    L[#L+1] = ("if %s then return %d end"):format(expr, rule.spellID)
                end
            else
                -- No conditions: unconditional (this blocks everything below it)
                if rule.spellID == SBA_BUTTON_SPELL_ID then
                    L[#L+1] = "return spellID  -- unconditional"
                else
                    L[#L+1] = ("return %d  -- unconditional"):format(rule.spellID)
                end
                hasUnconditional = true
            end
            L[#L+1] = ""
            if hasUnconditional then break end
        end
    end
    if not hasUnconditional then
        L[#L+1] = "-- Fallback: SBA assisted-combat suggestion"
        L[#L+1] = "return spellID"
    end
    return table.concat(L, "\n")
end

-------------------------------------------------------------------------------
-- 4.  Backdrop helper
-------------------------------------------------------------------------------
local function SetBD(f, r, g, b, a, er, eg, eb)
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(r or 0.05, g or 0.08, b or 0.12, a or 0.95)
    f:SetBackdropBorderColor(er or 0.2, eg or 0.35, eb or 0.5, 1)
end

-------------------------------------------------------------------------------
-- 5.  Spec name helper
-------------------------------------------------------------------------------
local function GetSpecName(specID)
    if specID and specID > 0 and GetSpecializationInfoByID then
        local specName = select(2, GetSpecializationInfoByID(specID))
        if specName then return specName end
    end
    return "Spec " .. tostring(specID)
end

local function CurrentSpecID()
    local si = GetSpecialization()
    if not si then return 0 end
    return select(1, GetSpecializationInfo(si)) or 0
end

-------------------------------------------------------------------------------
-- 6.  Condition-type picker popup
--     A floating popup listing all condition types as clickable buttons.
-------------------------------------------------------------------------------
local condPicker    = nil
local pluginPicker  = nil   -- forward-declared so CloseAllPopups can reference it
local addSpellPopup = nil   -- forward-declared so CloseAllPopups can reference it
local opDropdownPopups = {} -- all MakeOpDropdown popup frames, closed by CloseAllPopups

local function CloseAllPopups()
    if condPicker   and condPicker:IsShown()   then condPicker:Hide()   end
    if pluginPicker and pluginPicker:IsShown() then pluginPicker:Hide() end
    if addSpellPopup and addSpellPopup:IsShown() then addSpellPopup:Hide() end
    for _, p in ipairs(opDropdownPopups) do if p:IsShown() then p:Hide() end end
end

local function CreateCondPicker()
    local f = CreateFrame("Frame", "SBAS_GUI_CondPicker", UIParent, "BackdropTemplate")
    f:SetSize(272, 336)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Condition Type")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",  3, -20)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 22, 0), m))
    end)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(266, #COND_TYPES * 22 + 4)
    sf:SetScrollChild(sc)

    f.callback = nil

    for i, ct in ipairs(COND_TYPES) do
        local btn = CreateFrame("Button", nil, sc)
        btn:SetSize(262, 20)
        btn:SetPoint("TOPLEFT", sc, "TOPLEFT", 2, -2 - (i - 1) * 22)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("LEFT")
        lbl:SetText("  " .. ct.label)
        lbl:SetTextColor(0.82, 0.9, 1, 1)

        local ctRef = ct
        btn:SetScript("OnClick", function()
            f:Hide()
            if f.callback then f.callback(ctRef) end
        end)
        btn:SetScript("OnEnter", function(self)
            bg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            bg:SetColorTexture(0, 0, 0, 0)
            lbl:SetTextColor(0.82, 0.9, 1, 1)
        end)
    end

    return f
end

local function ShowCondPicker(anchor, callback)
    if not condPicker then condPicker = CreateCondPicker() end
    condPicker.callback = callback
    condPicker:ClearAllPoints()
    condPicker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    condPicker:Show()
    -- Keep on-screen: if it clips the bottom, flip above
    local bot = condPicker:GetBottom()
    if bot and bot < 0 then
        condPicker:ClearAllPoints()
        condPicker:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
end

-------------------------------------------------------------------------------
-- 7.  "Add Spell" popup
--     Enter a spell ID, see name/icon, confirm to add to the priority list.
-------------------------------------------------------------------------------
local function CreateAddSpellPopup()
    local f = CreateFrame("Frame", "SBAS_GUI_AddSpell", UIParent, "BackdropTemplate")
    f:SetSize(320, 130)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.12, 0.97, 0.3, 0.5, 0.7)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Add Spell by Name or ID")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local namInLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    namInLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    namInLbl:SetText("Name or ID:")
    namInLbl:SetTextColor(0.65, 0.78, 0.9, 1)

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(196, 22)
    nameBox:SetPoint("LEFT", namInLbl, "RIGHT", 6, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(80)

    local iconTex = f:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(28, 28)
    iconTex:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)
    iconTex:Hide()

    -- Result row: resolved ID + status
    local resultLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultLbl:SetPoint("TOPLEFT", namInLbl, "BOTTOMLEFT", 0, -8)
    resultLbl:SetSize(296, 16)
    resultLbl:SetJustifyH("LEFT")

    -- Stores the last successfully resolved spell
    local resolvedID   = nil
    local resolvedName = nil

    local function DoLookup()
        local input = nameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            resultLbl:SetText("")
            iconTex:Hide()
            resolvedID = nil
            return
        end

        local id = nil
        -- Numeric input: treat as a direct spell ID
        local numericID = tonumber(input)
        if numericID then
            id = numericID
        elseif C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            -- Name lookup
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end

        if id and id > 0 then
            local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id)
            if isPassive then
                resolvedID = nil
                resolvedName = nil
                resultLbl:SetText("|cffff5555That spell is passive and cannot be added|r")
                iconTex:Hide()
                return
            end
            local n   = C_Spell.GetSpellName   and C_Spell.GetSpellName(id)
            local tex = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
            resolvedID   = id
            resolvedName = n or input
            resultLbl:SetText("|cff55ee55" .. (n or input) .. "|r  |cff8899bbID: " .. id .. "|r")
            if tex then iconTex:SetTexture(tex) iconTex:Show() else iconTex:Hide() end
        else
            resolvedID = nil
            resolvedName = nil
            resultLbl:SetText("|cffff5555Spell not found|r")
            iconTex:Hide()
        end
    end

    nameBox:SetScript("OnTextChanged", DoLookup)
    nameBox:SetScript("OnEnterPressed", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        end
    end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(88, 24)
    addBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 10)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        DoLookup()
        if resolvedID then
            f:Hide()
            if f.onAdd then f.onAdd(resolvedID, resolvedName) end
        else
            resultLbl:SetText("|cffff5555Enter a valid spell name or ID first|r")
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(88, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f.nameBox  = nameBox
    f.iconTex  = iconTex
    f.onAdd    = nil   -- set before showing

    return f
end

-------------------------------------------------------------------------------
-- 8.  Main GUI state
-------------------------------------------------------------------------------
local GUI_W    = 680
local GUI_H    = 560
local LEFT_W   = 388
local RIGHT_W  = 268
local PAD      = 6
local ROW_H    = 72
local GUI_MIN_W = 680
local GUI_MIN_H = 560
local MIN_LEFT_W = 320
local MIN_RIGHT_W = 240

local guiFrame     = nil   -- main frame (created once)
local leftChild    = nil   -- scroll child for rule rows
local rightPanel   = nil   -- condition editor panel
local condInputArea= nil   -- "add condition" sub-frame inside rightPanel

local workingRules = {}    -- deep-copy being edited
local editSpecID   = 0
local sessionRules = {}    -- in-session cache: specID -> workingRules table (survives close/reopen)
local selectedIdx  = 0     -- 1-based; 0 = none
local isAddingCond = false
local selectedCondIdx = nil  -- nil = adding new; number = editing existing cond at that index

local rowFrames        = {}    -- pool of rule-row frames
local condRowPool      = {}    -- pool of condition-row frames in right panel
local condJunctionPool = {}    -- pool of AND/OR junction toggles between condition rows
local condGroupBoxPool = {}    -- pool of backdrop boxes for matched parenthesis groups

-- Forward declarations
local RefreshRuleList, RefreshRightPanel
-- Drag-infrastructure forward declarations (defined in section 11)
local ruleDrag      -- assigned in section 11 initialiser block
local dragIconFrame, dragCatcher
local EnsureDragIcon, EnsureDragCatcher

local function GetPanelWidths(totalWidth)
    totalWidth = totalWidth or (guiFrame and guiFrame:GetWidth()) or GUI_W
    local leftW = math.floor(totalWidth * (LEFT_W / GUI_W))
    leftW = math.max(MIN_LEFT_W, math.min(leftW, totalWidth - MIN_RIGHT_W - PAD * 4))
    local rightW = totalWidth - leftW - PAD * 4
    return leftW, rightW
end

local function GetLeftPanelWidth()
    return GetPanelWidths()
end

local function GetRightPanelWidth()
    local _, rightW = GetPanelWidths()
    return rightW
end

-------------------------------------------------------------------------------
-- 9.  Rule-row frames
-------------------------------------------------------------------------------
local function CreateRowFrame(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(GetLeftPanelWidth() - PAD * 2, ROW_H - 4)
    SetBD(f, 0.06, 0.10, 0.16, 0.88, 0.14, 0.24, 0.40)
    f:EnableMouse(true)

    -- Priority badge
    f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.badge:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -4)
    f.badge:SetSize(20, 20)
    f.badge:SetJustifyH("CENTER")
    f.badge:SetTextColor(0.4, 0.62, 0.90, 1)

    -- Spell icon
    local iconBg = f:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(36, 36)
    iconBg:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -4)
    iconBg:SetColorTexture(0, 0, 0, 0.5)

    f.iconTex = f:CreateTexture(nil, "ARTWORK")
    f.iconTex:SetSize(34, 34)
    f.iconTex:SetPoint("CENTER", iconBg, "CENTER")
    f.iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- Spell name
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.nameLabel:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 6, 0)
    f.nameLabel:SetSize(LEFT_W - 186, 18)
    f.nameLabel:SetJustifyH("LEFT")
    f.nameLabel:SetTextColor(0.9, 0.95, 1, 1)

    -- Spell ID  
    f.idLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.idLabel:SetPoint("TOPLEFT", f.nameLabel, "BOTTOMLEFT", 0, -1)
    f.idLabel:SetTextColor(0.48, 0.60, 0.75, 1)

    -- Condition summary (anchored below ID label, grows downward)
    f.condLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.condLabel:SetPoint("TOPLEFT", f.idLabel, "BOTTOMLEFT", 0, -4)
    f.condLabel:SetWidth(LEFT_W - 130)
    f.condLabel:SetJustifyH("LEFT")
    f.condLabel:SetWordWrap(true)
    f.condLabel:SetTextColor(0.50, 0.72, 0.55, 1)

    -- Buttons (top-right)
    f.removeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.removeBtn:SetSize(20, 20)
    f.removeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    f:SetScript("OnMouseDown", function(self, mouseBtn)
        if mouseBtn ~= "LeftButton" then return end
        if not self._idx then return end
        -- Select the rule
        selectedIdx  = self._idx
        isAddingCond = false
        RefreshRuleList()
        RefreshRightPanel()
        -- Begin a *pending* drag — the visual only activates once the cursor
        -- moves more than 8 px, so normal clicks produce no floating icon.
        EnsureDragIcon()
        EnsureDragCatcher()
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        ruleDrag.pending  = true
        ruleDrag.fromIdx  = self._idx
        ruleDrag.pendingX = cx / s
        ruleDrag.pendingY = cy / s
        -- Pre-load the icon texture so it's ready the moment drag activates
        local rule = workingRules[self._idx]
        if rule and dragIconFrame then
            local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                         and C_Spell.GetSpellInfo(rule.spellID)
            local iconID = info and info.originalIconID
            dragIconFrame._tex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        -- Show catcher with mouse DISABLED so it doesn't block clicks;
        -- EnableMouse is turned on once the threshold is crossed.
        dragCatcher:EnableMouse(false)
        dragCatcher:Show()
    end)
    f:SetScript("OnMouseUp", function(self, mouseBtn)
        -- Cancel a pending drag that never crossed the movement threshold
        if mouseBtn == "LeftButton" and ruleDrag.pending then
            ruleDrag.pending = false
            ruleDrag.fromIdx = nil
            if dragCatcher then dragCatcher:Hide() end
        end
    end)
    f:SetScript("OnEnter", function(self)
        if self._idx ~= selectedIdx then
            f:SetBackdropColor(0.10, 0.16, 0.26, 0.88)
        end
    end)
    f:SetScript("OnLeave", function(self)
        if self._idx ~= selectedIdx then
            f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        end
    end)

    return f
end

local GROUP_BOX_COLORS = {
    { 0.78, 0.66, 0.14, 0.08, 0.92, 0.76, 0.18, 0.95 },
    { 0.18, 0.42, 0.72, 0.08, 0.28, 0.58, 0.90, 0.95 },
    { 0.18, 0.58, 0.34, 0.08, 0.24, 0.82, 0.46, 0.95 },
}

-- Returns a WoW color-code hex string for parenthesis at the given stack depth (1-based).
local function ParenColorCode(depth)
    local c = GROUP_BOX_COLORS[((depth - 1) % #GROUP_BOX_COLORS) + 1]
    return ("|cff%02x%02x%02x"):format(c[5]*255, c[6]*255, c[7]*255)
end

local function UpdateRowFrame(f, idx, rule)
    local leftW = GetLeftPanelWidth()
    f._idx = idx
    -- Positioning (ClearAllPoints + SetPoint) is handled by RefreshRuleList
    -- after _rowH is computed here.

    f.badge:SetText(tostring(idx))

    local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                 and C_Spell.GetSpellInfo(rule.spellID)
    local iconID  = info and info.originalIconID
    local dispName = (info and info.name) or rule.name or "Unknown"
    f.iconTex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    f.nameLabel:SetText(dispName)
    f.nameLabel:SetWidth(math.max(120, leftW - 186))
    f.idLabel:SetText("ID: " .. tostring(rule.spellID or 0))

    local condCount = #(rule.conditions or {})
    if condCount == 0 then
        local labelW = math.max(120, leftW - 130)
        f.condLabel:SetWidth(labelW)
        f.condLabel:SetText("|cffff9944No conditions — unconditional return|r")
    else
        -- Build one display-string per condition, then group by paren depth.
        local tokens = {}
        local depth  = 0  -- running paren depth for color selection
        for i = 1, condCount do
            local cond = rule.conditions[i] or {}
            local def  = COND_BY_ID[cond.type]
            if def then
                local junction = ""
                if i > 1 then
                    local j = cond.junction or "and"
                    junction = "|cff8899cc" .. j:upper() .. "|r "
                end
                local lp = ""
                local rp = ""
                do
                    local depthBefore = depth
                    for k = 1, (cond.lparen or 0) do
                        local d = depthBefore + k
                        lp = lp .. ParenColorCode(d) .. "(" .. "|r"
                    end
                    depth = depth + (cond.lparen or 0)
                    for k = 1, (cond.rparen or 0) do
                        local d = depth - (k - 1)
                        rp = rp .. ParenColorCode(d) .. ")" .. "|r"
                    end
                    depth = depth - (cond.rparen or 0)
                end
                local label = def.shortLabel or def.label
                if def.needsSpell then
                    if cond.type == "sba_suggests" then
                        -- Show as "SBA = icon" using the chosen spell's icon
                        local op = "="
                        if not cond.spell or cond.spell == "this" then
                            label = "SBA " .. op .. (iconID and (" |T" .. iconID .. ":14:14|t") or " [this]")
                        else
                            local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                            if sid then
                                local sInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                                local sIcon = sInfo and sInfo.iconID
                                if sIcon then
                                    label = "SBA " .. op .. " |T" .. sIcon .. ":14:14|t"
                                else
                                    label = "SBA " .. op .. " [" .. tostring(sid) .. "]"
                                end
                            else
                                label = "SBA " .. op
                            end
                        end
                    elseif not cond.spell or cond.spell == "this" then
                        -- Show the rule's own spell icon
                        if iconID then
                            label = label .. " |T" .. iconID .. ":14:14|t"
                        end
                    else
                        local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                        if sid then
                            local sInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                            local sIcon = sInfo and sInfo.iconID
                            if sIcon then
                                label = label .. " |T" .. sIcon .. ":14:14|t"
                            else
                                label = label .. " [" .. tostring(sid) .. "]"
                            end
                        end
                    end
                elseif def.needsPlugin then
                    -- Replace generic label with the specific chosen plugin proc name.
                    local pLabel = cond.plugin or "?"
                    for _, opt in ipairs(PLUGIN_OPTS) do
                        if opt.id == cond.plugin then
                            pLabel = opt.label
                            break
                        end
                    end
                    if cond.plugin == "docj_timer" then
                        label = pLabel .. " " .. (cond.operator or "<") .. " " .. tostring(cond.value or 4)
                    else
                        label = pLabel
                    end
                elseif def.needsResource then
                    -- Show as e.g. "chi >= 2" or "energy <= 60"
                    local res = cond.resource or "chi"
                    local op  = cond.operator or ">="
                    local val = tostring(cond.value or 0)
                    label = res .. " " .. op .. " " .. val
                end

                local labelText = cond.negate and ("|cffff4444NOT " .. label .. "|r") or label
                tokens[#tokens+1] = {
                    str = junction .. lp .. labelText .. rp,
                    lp  = cond.lparen or 0,
                    rp  = cond.rparen or 0,
                }
            end
        end

        -- Join all tokens into one continuous string; word-wrap handles line breaking.
        local parts = {}
        for _, tok in ipairs(tokens) do
            parts[#parts+1] = tok.str
        end
        local condText = table.concat(parts, " ")
        local labelW = math.max(120, leftW - 130)
        f.condLabel:SetWidth(labelW)
        f.condLabel:SetText(condText)
    end

    -- Use GetStringHeight() for accurate height now that width and text are set.
    -- Base header block ~44px + actual text height + 10px bottom pad.
    local textH = f.condLabel:GetStringHeight()
    local rowFrameH = math.max(ROW_H - 4, 44 + textH + 10)
    f._rowH = rowFrameH + 4   -- +4 gap between rows (used by RefreshRuleList)
    f:SetSize(leftW - PAD * 2, rowFrameH)
    f:Show()

    if idx == selectedIdx then
        f:SetBackdropColor(0.08, 0.20, 0.36, 0.95)
        f:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
    else
        f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        f:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
    end

    f.removeBtn:SetScript("OnClick", function()
        table.remove(workingRules, idx)
        if selectedIdx == idx then
            selectedIdx = math.min(idx, #workingRules)
        elseif selectedIdx > idx then
            selectedIdx = selectedIdx - 1
        end
        isAddingCond = false
        RefreshRuleList(); RefreshRightPanel()
    end)
end

RefreshRuleList = function()
    local count = #workingRules
    leftChild:SetWidth(GetLeftPanelWidth())
    local yOff = -PAD
    for i = 1, count do
        if not rowFrames[i] then
            rowFrames[i] = CreateRowFrame(leftChild)
        end
        UpdateRowFrame(rowFrames[i], i, workingRules[i])
        -- Position after UpdateRowFrame has set _rowH
        local rf = rowFrames[i]
        rf:ClearAllPoints()
        rf:SetPoint("TOPLEFT", leftChild, "TOPLEFT", PAD, yOff)
        yOff = yOff - (rf._rowH or ROW_H)
    end
    for i = count + 1, #rowFrames do
        if rowFrames[i] then rowFrames[i]:Hide() end
    end
    leftChild:SetHeight(math.max(-yOff + PAD, 100))
end

-------------------------------------------------------------------------------
-- 6b. Plugin / Proc picker popup
-------------------------------------------------------------------------------
local function CreatePluginPicker()
    local f = CreateFrame("Frame", "SBAS_GUI_PluginPicker", UIParent, "BackdropTemplate")
    f:SetSize(200, #PLUGIN_OPTS * 22 + 28)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:Hide()
    SetBD(f, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    hdr:SetText("Select Plugin / Proc")
    hdr:SetTextColor(0.5, 0.72, 0.92, 1)

    for i, opt in ipairs(PLUGIN_OPTS) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(192, 20)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -22 - (i - 1) * 22)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints() bg:SetColorTexture(0, 0, 0, 0)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetAllPoints() lbl:SetJustifyH("LEFT")
        lbl:SetText("  " .. opt.label)
        lbl:SetTextColor(0.82, 0.9, 1, 1)

        local optRef = opt
        btn:SetScript("OnClick", function()
            f:Hide()
            if f.callback then f.callback(optRef) end
        end)
        btn:SetScript("OnEnter", function()
            bg:SetColorTexture(0.14, 0.28, 0.50, 0.7) lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(0, 0, 0, 0) lbl:SetTextColor(0.82, 0.9, 1, 1)
        end)
    end

    return f
end

local function ShowPluginPicker(anchor, callback)
    if not pluginPicker then pluginPicker = CreatePluginPicker() end
    pluginPicker.callback = callback
    pluginPicker:ClearAllPoints()
    pluginPicker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    pluginPicker:Show()
    local bot = pluginPicker:GetBottom()
    if bot and bot < 0 then
        pluginPicker:ClearAllPoints()
        pluginPicker:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
end

-------------------------------------------------------------------------------
-- 10. Condition input area (inside right panel)
--     Shown when isAddingCond = true; lets the user pick a type + optional
--     numeric value and/or secondary spell-ID target.
-------------------------------------------------------------------------------

-- Scan every spellbook slot (all tabs, including passives) for a case-insensitive
-- name match.  Used as a fallback when GetSpellIDForSpellIdentifier fails, which
-- happens for many talent-granted spells.
local function SearchSpellBookByName(input)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return nil end
    local lower = input:lower()
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        if info then
            local offset = info.itemIndexOffset
            local count  = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name, _ =
                    C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local _, spellID =
                    C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if spellID and spellID ~= 0 then
                    -- Check the base spellbook entry name
                    if name and name:lower() == lower then
                        return spellID
                    end
                    -- Also check the GetSpellInfo name (may differ from spellbook display name)
                    if C_Spell and C_Spell.GetSpellInfo then
                        local si = C_Spell.GetSpellInfo(spellID)
                        if si and si.name and si.name:lower() == lower then
                            return spellID
                        end
                    end
                    -- Check the active override of this spell
                    if C_SpellBook.FindSpellOverrideByID then
                        local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                        if oid and oid ~= spellID then
                            local oi = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                            if oi and oi.name and oi.name:lower() == lower then
                                return oid
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Scan the active talent tree for a case-insensitive name match.
-- Catches passive talents (like Obsidian Spiral) that never appear in the spellbook.
-- Uses: C_ClassTalents.GetActiveConfigID → C_Traits.GetConfigInfo (treeIDs) →
--       GetTreeNodes → GetNodeInfo (entryIDs) → GetEntryInfo (definitionID) →
--       GetDefinitionInfo (spellID).
local function SearchTalentTreeByName(input)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
            and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo
            and C_Traits.GetDefinitionInfo) then return nil end

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not (configInfo and configInfo.treeIDs) then return nil end

    local lower = input:lower()
    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes(treeID)
        if nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.entryIDs then
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if defInfo and defInfo.spellID and defInfo.spellID ~= 0 then
                                local si = C_Spell.GetSpellInfo
                                           and C_Spell.GetSpellInfo(defInfo.spellID)
                                if si and si.name and si.name:lower() == lower then
                                    return defInfo.spellID
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Comparison operator options (shared by resource and DOCJ timer dropdowns)
-------------------------------------------------------------------------------
local OP_LIST = {
    { id = ">=", label = ">=" },
    { id = "<=", label = "<=" },
    { id = "==", label = "==" },
    { id = ">",  label = ">"  },
    { id = "<",  label = "<"  },
}

-- Creates a compact dropdown button that opens a popup list of options.
-- ops:   array of { id, label }
-- Returns a Frame container with methods:
--   :SetSelected(id)    – select an option by id and update button text
--   :GetSelected()      – return the currently selected id
--   :UpdateWidth(w)     – resize the button, popup, and all rows to w
--   :SetOnChange(fn)    – register a callback fn(id) fired on selection
local function MakeOpDropdown(parent, ops)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(80, 22)

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:SetToplevel(true)
    popup:SetSize(80, #ops * 22 + 6)
    popup:Hide()
    SetBD(popup, 0.04, 0.06, 0.11, 0.98, 0.28, 0.48, 0.68)

    -- Register so CloseAllPopups() can reach it.
    opDropdownPopups[#opDropdownPopups + 1] = popup

    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetAllPoints()

    local rows = {}
    local selected = ops[1].id
    local onChange = nil

    for i, op in ipairs(ops) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(80, 22)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -3 - (i - 1) * 22)
        rows[i] = row

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0, 0, 0, 0)

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowLbl:SetAllPoints()
        rowLbl:SetJustifyH("CENTER")
        rowLbl:SetText(op.label)
        rowLbl:SetTextColor(0.82, 0.9, 1, 1)

        local opRef = op
        row:SetScript("OnClick", function()
            popup:Hide()
            selected = opRef.id
            btn:SetText(opRef.label)
            if onChange then onChange(opRef.id) end
        end)
        row:SetScript("OnEnter", function()
            rowBg:SetColorTexture(0.14, 0.28, 0.50, 0.7)
            rowLbl:SetTextColor(1, 1, 1, 1)
        end)
        row:SetScript("OnLeave", function()
            rowBg:SetColorTexture(0, 0, 0, 0)
            rowLbl:SetTextColor(0.82, 0.9, 1, 1)
        end)
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            CloseAllPopups()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
            local bot = popup:GetBottom()
            if bot and bot < 0 then
                popup:ClearAllPoints()
                popup:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
            end
        end
    end)

    -- Initialize button text to first option.
    btn:SetText(ops[1].label)

    container.SetSelected = function(self, id)
        for _, op in ipairs(ops) do
            if op.id == id then
                selected = id
                btn:SetText(op.label)
                return
            end
        end
    end
    container.GetSelected  = function(self) return selected end
    container.UpdateWidth  = function(self, w)
        container:SetWidth(w)
        btn:SetWidth(w)
        popup:SetWidth(w)
        for _, row in ipairs(rows) do row:SetWidth(w) end
    end
    container.SetOnChange  = function(self, fn) onChange = fn end

    return container
end

local function CreateCondInputArea(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(GetRightPanelWidth() - 10, 95)
    SetBD(f, 0.04, 0.07, 0.13, 0.97, 0.20, 0.40, 0.60)

    local selType           = nil
    local spellSel          = "this"   -- "this" or "other"
    local resolvedOtherID   = nil
    local resolvedOtherName = nil
    local resSel            = "chi"    -- "chi" or "energy"
    local opSel             = ">="     -- resource operator (>=, <=, ==, >, <)
    local timerOpSel        = "<"      -- DOCJ timer operator
    local opDropdown        = nil      -- assigned after operatorFrame is built
    local timerOpDropdown   = nil      -- assigned after timerOpFrame is built
    -- Forward-declare so closures defined before their creation can capture them.
    local timerOpFrame
    local valLbl
    local valBox
    local selPlugin = nil
    local UpdateLayout  -- assigned below; forward-declared so all closures share it

    -- ── NOT checkbox ──────────────────────────────────────────────────────
    local notCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    notCheck:SetSize(20, 20)
    notCheck:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    local notLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notLbl:SetPoint("LEFT", notCheck, "RIGHT", 2, 0)
    notLbl:SetText("NOT (negate)")
    notLbl:SetTextColor(0.90, 0.55, 0.38, 1)

    -- ── Type selector ─────────────────────────────────────────────────────
    local typeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    typeBtn:SetSize(GetRightPanelWidth() - 18, 22)
    typeBtn:SetPoint("TOPLEFT", notCheck, "BOTTOMLEFT", 0, -4)
    typeBtn:SetText("Select condition type...")

    -- ── Spell toggle: This Spell / Other Spell ────────────────────────────
    local spellToggleFrame = CreateFrame("Frame", nil, f)
    spellToggleFrame:SetSize(GetRightPanelWidth() - 18, 22)
    spellToggleFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    spellToggleFrame:Hide()

    local halfW = math.floor((GetRightPanelWidth() - 22) / 2)
    local thisBtn = CreateFrame("Button", nil, spellToggleFrame, "UIPanelButtonTemplate")
    thisBtn:SetSize(halfW, 22)
    thisBtn:SetPoint("TOPLEFT", spellToggleFrame, "TOPLEFT")
    thisBtn:SetText("This Spell")

    local otherBtn = CreateFrame("Button", nil, spellToggleFrame, "UIPanelButtonTemplate")
    otherBtn:SetSize(halfW, 22)
    otherBtn:SetPoint("LEFT", thisBtn, "RIGHT", 2, 0)
    otherBtn:SetText("Other Spell")

    -- ── Other spell name input ────────────────────────────────────────────
    local otherFrame = CreateFrame("Frame", nil, f)
    otherFrame:SetSize(GetRightPanelWidth() - 18, 38)
    otherFrame:SetPoint("TOPLEFT", spellToggleFrame, "BOTTOMLEFT", 0, -2)
    otherFrame:Hide()

    local otherNameBox = CreateFrame("EditBox", nil, otherFrame, "InputBoxTemplate")
    otherNameBox:SetSize(GetRightPanelWidth() - 52, 20)
    otherNameBox:SetPoint("TOPLEFT", otherFrame, "TOPLEFT")
    otherNameBox:SetAutoFocus(false)
    otherNameBox:SetMaxLetters(80)

    local otherIcon = otherFrame:CreateTexture(nil, "ARTWORK")
    otherIcon:SetSize(18, 18)
    otherIcon:SetPoint("LEFT", otherNameBox, "RIGHT", 4, 0)
    otherIcon:Hide()

    local otherResultLbl = otherFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    otherResultLbl:SetPoint("TOPLEFT", otherNameBox, "BOTTOMLEFT", 0, -2)
    otherResultLbl:SetSize(GetRightPanelWidth() - 22, 14)
    otherResultLbl:SetJustifyH("LEFT")

    otherNameBox:SetScript("OnTextChanged", function()
        local input = otherNameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            otherResultLbl:SetText("") otherIcon:Hide() resolvedOtherID = nil; return
        end
        local id
        -- Numeric input: treat as a direct spell ID
        local numericID = tonumber(input)
        if numericID then
            id = numericID
        elseif C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end
        -- Fallback: scan spellbook by name (catches talent-granted spells)
        if not (id and id > 0) then
            id = SearchSpellBookByName(input)
        end
        -- Final fallback: scan talent tree (catches passive talents like Obsidian Spiral
        -- that never appear in the spellbook)
        if not (id and id > 0) then
            id = SearchTalentTreeByName(input)
        end
        if id and id > 0 then
            local n   = C_Spell.GetSpellName   and C_Spell.GetSpellName(id)
            local tex = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
            resolvedOtherID = id; resolvedOtherName = n or input
            otherResultLbl:SetText("|cff55ee55" .. (n or input) .. "|r  ID:" .. id)
            if tex then otherIcon:SetTexture(tex) otherIcon:Show() else otherIcon:Hide() end
        else
            resolvedOtherID = nil
            otherResultLbl:SetText("|cffff5555Not found|r") otherIcon:Hide()
        end
    end)

    -- ── Resource type selector: Chi / Energy ──────────────────────────────
    local resourceFrame = CreateFrame("Frame", nil, f)
    resourceFrame:SetSize(GetRightPanelWidth() - 18, 22)
    resourceFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    resourceFrame:Hide()

    local resLabel = resourceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resLabel:SetPoint("LEFT", resourceFrame, "LEFT", 0, 0)
    resLabel:SetWidth(60)
    resLabel:SetText("Resource:")
    resLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    local chiBtn = CreateFrame("Button", nil, resourceFrame, "UIPanelButtonTemplate")
    chiBtn:SetSize(88, 22)
    chiBtn:SetPoint("LEFT", resLabel, "RIGHT", 4, 0)
    chiBtn:SetText("Chi")

    local energyBtn = CreateFrame("Button", nil, resourceFrame, "UIPanelButtonTemplate")
    energyBtn:SetSize(88, 22)
    energyBtn:SetPoint("LEFT", chiBtn, "RIGHT", 2, 0)
    energyBtn:SetText("Energy")

    -- ── Operator selector: dropdown (>=, <=, ==, >, <) ──────────────────
    local operatorFrame = CreateFrame("Frame", nil, f)
    operatorFrame:SetSize(GetRightPanelWidth() - 18, 22)
    operatorFrame:SetPoint("TOPLEFT", resourceFrame, "BOTTOMLEFT", 0, -4)
    operatorFrame:Hide()

    local opLabel = operatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opLabel:SetPoint("LEFT", operatorFrame, "LEFT", 0, 0)
    opLabel:SetWidth(60)
    opLabel:SetText("Operator:")
    opLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    opDropdown = MakeOpDropdown(operatorFrame, OP_LIST)
    opDropdown:SetPoint("LEFT", opLabel, "RIGHT", 4, 0)
    opDropdown:SetSelected(">=")
    opDropdown:SetOnChange(function(id) opSel = id end)

    -- ── Plugin / Proc selector ────────────────────────────────────────────
    local pluginFrame = CreateFrame("Frame", nil, f)
    pluginFrame:SetSize(GetRightPanelWidth() - 18, 22)
    pluginFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    pluginFrame:Hide()

    local pluginBtn = CreateFrame("Button", nil, pluginFrame, "UIPanelButtonTemplate")
    pluginBtn:SetSize(GetRightPanelWidth() - 18, 22)
    pluginBtn:SetPoint("TOPLEFT", pluginFrame, "TOPLEFT")
    pluginBtn:SetText("Select plugin...")
    pluginBtn:SetScript("OnClick", function()
        if pluginPicker and pluginPicker:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        ShowPluginPicker(pluginBtn, function(opt)
            selPlugin = opt
            pluginBtn:SetText(opt.label)
            if opt.needsOperator then
                timerOpFrame:Show()
                timerOpSel = "<"
                if timerOpDropdown then timerOpDropdown:SetSelected("<") end
            else
                timerOpFrame:Hide()
            end
            if opt.needsValue then
                valLbl:SetText("Seconds:")
                valLbl:Show()
                valBox:SetText(tostring(opt.default or 4))
                valBox:Show()
            else
                valLbl:Hide(); valBox:Hide()
            end
            UpdateLayout()
        end)
    end)

    -- ── DOCJ Timer operator selector (shown only for docj_timer plugin) ───
    timerOpFrame = CreateFrame("Frame", nil, f)
    timerOpFrame:SetSize(GetRightPanelWidth() - 18, 22)
    timerOpFrame:SetPoint("TOPLEFT", pluginFrame, "BOTTOMLEFT", 0, -4)
    timerOpFrame:Hide()

    local timerOpLabel = timerOpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerOpLabel:SetPoint("LEFT", timerOpFrame, "LEFT", 0, 0)
    timerOpLabel:SetWidth(60)
    timerOpLabel:SetText("Operator:")
    timerOpLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    timerOpDropdown = MakeOpDropdown(timerOpFrame, OP_LIST)
    timerOpDropdown:SetPoint("LEFT", timerOpLabel, "RIGHT", 4, 0)
    timerOpDropdown:SetSelected("<")
    timerOpDropdown:SetOnChange(function(id) timerOpSel = id end)

    valLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valLbl:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -6)
    valLbl:SetTextColor(0.55, 0.72, 0.88, 1)
    valLbl:Hide()

    valBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    valBox:SetSize(72, 22)
    valBox:SetPoint("LEFT", valLbl, "RIGHT", 6, 0)
    valBox:SetAutoFocus(false)
    valBox:SetNumeric(true)
    valBox:SetMaxLetters(6)
    valBox:Hide()

    -- ── Confirm / Cancel ──────────────────────────────────────────────────
    local confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    confirmBtn:SetSize(88, 24)
    confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
    confirmBtn:SetText("Add")

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(76, 24)
    cancelBtn:SetPoint("LEFT", confirmBtn, "RIGHT", 6, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        selectedCondIdx = nil
        isAddingCond = false
        RefreshRightPanel()
    end)

    -- ── Resource / operator highlight helpers ─────────────────────────────
    local function HlBtn(btn, selected)
        btn:GetFontString():SetTextColor(
            selected and 1.0 or 0.65,
            selected and 1.0 or 0.65,
            selected and 0.5 or 0.65, 1)
    end

    local function SetResSel(mode)
        resSel = mode
        HlBtn(chiBtn,    mode == "chi")
        HlBtn(energyBtn, mode == "energy")
    end

    local function SetOpSel(mode)
        opSel = mode
        if opDropdown then opDropdown:SetSelected(mode) end
    end

    local function SetTimerOpSel(mode)
        timerOpSel = mode
        if timerOpDropdown then timerOpDropdown:SetSelected(mode) end
    end

    chiBtn:SetScript("OnClick",    function() SetResSel("chi")    end)
    energyBtn:SetScript("OnClick", function() SetResSel("energy") end)

    local function RefreshSize()
        local rightW = GetRightPanelWidth()
        local contentW = rightW - 18
        local spellHalfW = math.floor((contentW - 4) / 2)
        local otherBoxW = math.max(120, contentW - 34)
        local resBtnW = math.max(68, math.floor((contentW - 66) / 2))
        local opDropdownW = math.max(60, contentW - 64)   -- 64 = label 60 + gap 4

        f:SetWidth(rightW - 10)
        typeBtn:SetWidth(contentW)
        spellToggleFrame:SetWidth(contentW)
        thisBtn:SetWidth(spellHalfW)
        otherBtn:SetWidth(spellHalfW)
        otherFrame:SetWidth(contentW)
        otherNameBox:SetWidth(otherBoxW)
        otherResultLbl:SetWidth(contentW - 4)
        resourceFrame:SetWidth(contentW)
        operatorFrame:SetWidth(contentW)
        pluginFrame:SetWidth(contentW)
        timerOpFrame:SetWidth(contentW)
        pluginBtn:SetWidth(contentW)
        chiBtn:SetWidth(resBtnW)
        energyBtn:SetWidth(resBtnW)
        if opDropdown      then opDropdown:UpdateWidth(opDropdownW)      end
        if timerOpDropdown then timerOpDropdown:UpdateWidth(opDropdownW) end
        UpdateLayout()
    end

    -- ── Layout ────────────────────────────────────────────────────────────
    UpdateLayout = function()
        local above = typeBtn
        if selType and selType.needsSpell then
            above = (spellSel == "other") and otherFrame or spellToggleFrame
        elseif selType and selType.needsResource then
            above = operatorFrame
        elseif selType and selType.needsPlugin then
            above = (selPlugin and selPlugin.needsOperator) and timerOpFrame or pluginFrame
        end
        local showVal = selType and (
            selType.needsValue or selType.needsResource or
            (selType.needsPlugin and selPlugin and selPlugin.needsValue))
        if showVal then
            valLbl:ClearAllPoints()
            valLbl:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -6)
        end
        local h = 6 + 20 + 4 + 22 + 4  -- pad + notCheck + gap + typeBtn + gap
        if selType and selType.needsSpell then
            h = h + 22 + 4
            if spellSel == "other" then h = h + 38 + 4 end
        end
        if selType and selType.needsResource then
            h = h + 22 + 4   -- resource row
            h = h + 22 + 4   -- operator row
        end
        if selType and selType.needsPlugin then
            h = h + 22 + 4   -- plugin selector row
            if selPlugin and selPlugin.needsOperator then
                h = h + 22 + 4  -- timer operator row
            end
        end
        if showVal then h = h + 22 + 4 end
        h = h + 24 + 8                  -- buttons + bottom pad
        f:SetHeight(h)
    end

    local function SetSpellSel(mode)
        spellSel = mode
        if mode == "this" then
            otherFrame:Hide()
            thisBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            otherBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        else
            otherFrame:Show()
            otherBtn:GetFontString():SetTextColor(1.0, 1.0, 0.5, 1)
            thisBtn:GetFontString():SetTextColor(0.65, 0.65, 0.65, 1)
        end
        UpdateLayout()
    end

    thisBtn:SetScript("OnClick",  function() SetSpellSel("this")  end)
    otherBtn:SetScript("OnClick", function() SetSpellSel("other") end)

    typeBtn:SetScript("OnClick", function()
        if condPicker and condPicker:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        ShowCondPicker(typeBtn, function(ct)
            selType = ct
            typeBtn:SetText(ct.label)
            -- Hide all optional sections first
            spellToggleFrame:Hide(); otherFrame:Hide()
            resourceFrame:Hide(); operatorFrame:Hide()
            pluginFrame:Hide(); timerOpFrame:Hide()
            valLbl:Hide(); valBox:Hide()
            selPlugin = nil
            if ct.needsSpell then
                spellToggleFrame:Show()
                if ct.id == "sba_suggests" then
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell")
                elseif ct.id == "talented" then
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell / Talent")
                else
                    thisBtn:SetText("This Spell")
                    otherBtn:SetText("Other Spell")
                end
                SetSpellSel("this")
            end
            if ct.needsResource then
                resourceFrame:Show()
                operatorFrame:Show()
                SetResSel("chi")
                SetOpSel(">=")
                valLbl:SetText("Value:")
                valLbl:Show()
                valBox:SetText("0")
                valBox:Show()
            end
            if ct.needsPlugin then
                pluginFrame:Show()
                pluginBtn:SetText("Select plugin...")
            end
            if ct.needsValue then
                valLbl:SetText((ct.valueLabel or "Value") .. ":")
                valLbl:Show()
                valBox:SetText(tostring(ct.default or ""))
                valBox:Show()
            end
            UpdateLayout()
        end)
    end)

    -- ── Public interface ──────────────────────────────────────────────────
    f.confirmBtn = confirmBtn
    f.typeBtn    = typeBtn

    f.GetSelectedType = function() return selType end
    f.GetValue        = function() return tonumber(valBox:GetText()) end
    f.GetNegate       = function() return notCheck:GetChecked() and true or false end
    f.GetResource     = function() return resSel end
    f.GetOperator     = function() return opSel end
    f.GetTimerOperator= function() return timerOpSel end
    f.GetPlugin       = function() return selPlugin and selPlugin.id or nil end
    f.GetSpell        = function()
        if not selType or not selType.needsSpell then return nil end
        if spellSel == "this" then return "this" end
        return resolvedOtherID  -- number or nil if not yet resolved
    end
    f.RefreshSize     = RefreshSize

    f.Reset = function()
        selType = nil; spellSel = "this"; resSel = "chi"; opSel = ">="
        timerOpSel = "<"
        selPlugin = nil
        resolvedOtherID = nil; resolvedOtherName = nil
        notCheck:SetChecked(false)
        typeBtn:SetText("Select condition type...")
        spellToggleFrame:Hide(); otherFrame:Hide()
        resourceFrame:Hide(); operatorFrame:Hide()
        pluginFrame:Hide(); timerOpFrame:Hide(); pluginBtn:SetText("Select plugin...")
        otherNameBox:SetText(""); otherResultLbl:SetText(""); otherIcon:Hide()
        valLbl:Hide(); valBox:SetText(""); valBox:Hide()
        if opDropdown      then opDropdown:SetSelected(">=") end
        if timerOpDropdown then timerOpDropdown:SetSelected("<") end
        f:SetHeight(95)
    end

    f.Populate = function(cond)
        f.Reset()
        local ct = COND_BY_ID[cond.type]
        if not ct then return end
        selType = ct
        typeBtn:SetText(ct.label)
        notCheck:SetChecked(cond.negate and true or false)
        if ct.needsSpell then
            spellToggleFrame:Show()
            if ct.id == "sba_suggests" then
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell")
            elseif ct.id == "talented" then
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell / Talent")
            else
                thisBtn:SetText("This Spell")
                otherBtn:SetText("Other Spell")
            end
            if not cond.spell or cond.spell == "this" then
                SetSpellSel("this")
            else
                local spellID = type(cond.spell) == "number" and cond.spell or cond.targetID
                if spellID then
                    local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
                    otherNameBox:SetText(n or tostring(spellID))
                    resolvedOtherID = spellID  -- ensure ID is set even if name lookup fires first
                end
                SetSpellSel("other")
            end
        end
        if ct.needsResource then
            resourceFrame:Show()
            operatorFrame:Show()
            SetResSel(cond.resource or "chi")
            SetOpSel(cond.operator or ">=")
            valLbl:SetText("Value:")
            valLbl:Show()
            valBox:SetText(tostring(cond.value or 0))
            valBox:Show()
        end
        if ct.needsPlugin then
            pluginFrame:Show()
            for _, opt in ipairs(PLUGIN_OPTS) do
                if opt.id == cond.plugin then
                    selPlugin = opt
                    pluginBtn:SetText(opt.label)
                    if opt.needsOperator then
                        timerOpFrame:Show()
                        local savedOp = cond.operator or "<"
                        timerOpSel = savedOp
                        if timerOpDropdown then timerOpDropdown:SetSelected(savedOp) end
                    end
                    if opt.needsValue then
                        valLbl:SetText("Seconds:")
                        valLbl:Show()
                        valBox:SetText(tostring(cond.value or opt.default or 4))
                        valBox:Show()
                    end
                    break
                end
            end
        end
        if ct.needsValue then
            valLbl:SetText((ct.valueLabel or "Value") .. ":")
            valLbl:Show()
            valBox:SetText(tostring(cond.value or ct.default or ""))
            valBox:Show()
        end
        UpdateLayout()
    end

    RefreshSize()

    return f
end

local function AnalyzeParenGroups(conds)
    local spans = {}
    local unmatchedOpens  = {}
    local unmatchedCloses = {}
    local stack = {}

    for i, cond in ipairs(conds) do
        for _ = 1, (cond.lparen or 0) do
            stack[#stack + 1] = { startIdx = i, depth = #stack + 1 }
        end
        for _ = 1, (cond.rparen or 0) do
            local open = table.remove(stack)
            if open then
                spans[#spans + 1] = {
                    startIdx = open.startIdx,
                    endIdx   = i,
                    depth    = open.depth,
                }
            else
                unmatchedCloses[i] = (unmatchedCloses[i] or 0) + 1
            end
        end
    end

    for _, open in ipairs(stack) do
        unmatchedOpens[open.startIdx] = (unmatchedOpens[open.startIdx] or 0) + 1
    end

    table.sort(spans, function(a, b)
        local aLen = a.endIdx - a.startIdx
        local bLen = b.endIdx - b.startIdx
        if aLen ~= bLen then return aLen > bLen end
        return a.depth < b.depth
    end)

    return spans, unmatchedOpens, unmatchedCloses
end

-- Returns two tables: lpDepths[i] and rpDepths[i], each a list of depths for
-- the opening/closing parens of condition i (innermost depth last).
local function GetCondParenDepths(conds)
    local lpDepths = {}
    local rpDepths = {}
    local stack    = {}   -- each entry = depth at which that ( was opened
    for i, cond in ipairs(conds) do
        lpDepths[i] = {}
        for _ = 1, (cond.lparen or 0) do
            local d = #stack + 1
            stack[#stack + 1] = d
            lpDepths[i][#lpDepths[i] + 1] = d
        end
        rpDepths[i] = {}
        for _ = 1, (cond.rparen or 0) do
            local d = table.remove(stack) or 1
            rpDepths[i][#rpDepths[i] + 1] = d
        end
    end
    return lpDepths, rpDepths
end

local function DrawConditionGroupBoxes(spans, rowYTops)
    for _, box in ipairs(condGroupBoxPool) do
        box:Hide()
    end
    if not rightPanel then return end

    local panelLevel = rightPanel:GetFrameLevel()
    for i, span in ipairs(spans) do
        if not condGroupBoxPool[i] then
            local box = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
            box:SetFrameStrata(rightPanel:GetFrameStrata())
            condGroupBoxPool[i] = box
        end

        local topY = rowYTops[span.startIdx]
        local endY = rowYTops[span.endIdx]
        if topY and endY then
            local inset = 2 + (span.depth - 1) * 4
            local color = GROUP_BOX_COLORS[((span.depth - 1) % #GROUP_BOX_COLORS) + 1]
            local box = condGroupBoxPool[i]
            local height = (topY - (endY - 22)) + 4

            box:ClearAllPoints()
            box:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4 + inset, topY + 2)
            box:SetSize(rightPanel:GetWidth() - 8 - inset * 2, height)
            box:SetFrameLevel(panelLevel + math.min(i - 1, 8))
            SetBD(box, color[1], color[2], color[3], color[4], color[5], color[6], color[7])
            box:Show()
        end
    end
end

-------------------------------------------------------------------------------
-- 11. Right panel refresh
--     Rebuilds the condition list for the currently selected rule.
-------------------------------------------------------------------------------
RefreshRightPanel = function()
    if not rightPanel then return end

    -- Hide all pooled condition rows and junction toggles
    for _, row in ipairs(condRowPool)      do row:Hide() end
    for _, jf  in ipairs(condJunctionPool) do jf:Hide()  end
    for _, box in ipairs(condGroupBoxPool) do box:Hide() end

    local rule = workingRules[selectedIdx]

    if not rule then
        rightPanel.header:SetText("Select a spell to edit conditions")
        rightPanel.addCondBtn:Hide()
        if condInputArea then condInputArea:Hide() end
        return
    end

    rightPanel.header:SetText((rule.name or tostring(rule.spellID or "?"))
                               .. " — Conditions")
    rightPanel.header:SetWidth(GetRightPanelWidth() - 16)

    local conds  = rule.conditions or {}
    local spans, unmatchedOpens, unmatchedCloses = AnalyzeParenGroups(conds)
    local lpDepths, rpDepths = GetCondParenDepths(conds)
    local yBase  = -28  -- below the header
    local rowIdx = 0
    local rowYTops = {}

    for i, cond in ipairs(conds) do
        -- AND / OR junction toggle (shown between consecutive conditions)
        if i > 1 then
            local jIdx = i - 1
            if not condJunctionPool[jIdx] then
                local jf = CreateFrame("Button", nil, rightPanel)
                jf:SetSize(44, 14)
                jf:SetFrameLevel(rightPanel:GetFrameLevel() + 20)
                local jbg = jf:CreateTexture(nil, "BACKGROUND")
                jbg:SetAllPoints() jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
                jf._bg = jbg
                local jLbl = jf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                jLbl:SetAllPoints() jLbl:SetJustifyH("CENTER")
                jf._lbl = jLbl
                jf:SetScript("OnEnter", function() jbg:SetColorTexture(0.18, 0.28, 0.48, 0.9) end)
                jf:SetScript("OnLeave", function() jbg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)
                condJunctionPool[jIdx] = jf
            end
            local jf           = condJunctionPool[jIdx]
            local capturedCond = cond
            jf:ClearAllPoints()
            jf:SetPoint("TOP", rightPanel, "TOP", 0, yBase)
            local function RefreshJunction()
                local j = capturedCond.junction or "and"
                jf._lbl:SetText(j:upper())
                jf._lbl:SetTextColor(
                    j == "or" and 1.0 or 0.55,
                    j == "or" and 0.72 or 0.80,
                    j == "or" and 0.28 or 1.0, 1)
            end
            RefreshJunction()
            jf:SetScript("OnClick", function()
                local j = capturedCond.junction or "and"
                capturedCond.junction = (j == "and") and "or" or "and"
                RefreshJunction()
                RefreshRuleList()
            end)
            jf:Show()
            yBase = yBase - 16
        end

        rowIdx = rowIdx + 1
        -- Get or create a pooled row frame
        if not condRowPool[rowIdx] then
            local row = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
            row:SetSize(RIGHT_W - 12, 22)
            row:SetFrameLevel(rightPanel:GetFrameLevel() + 20)
            SetBD(row, 0.07, 0.11, 0.18, 0.85, 0.12, 0.22, 0.36)

            -- Left paren column button
            local lpBtn = CreateFrame("Button", nil, row)
            lpBtn:SetSize(20, 20)
            lpBtn:SetPoint("LEFT", row, "LEFT", 2, 0)
            local lpBg = lpBtn:CreateTexture(nil, "BACKGROUND")
            lpBg:SetAllPoints() lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            lpBtn._bg = lpBg
            local lpLbl = lpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lpLbl:SetAllPoints() lpLbl:SetJustifyH("CENTER")
            row._lpBtn = lpBtn
            row._lpLbl = lpLbl
            lpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            lpBtn:SetScript("OnEnter", function() lpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            lpBtn:SetScript("OnLeave", function() lpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            -- Right paren column button
            local rpBtn = CreateFrame("Button", nil, row)
            rpBtn:SetSize(20, 20)
            rpBtn:SetPoint("RIGHT", row, "RIGHT", -22, 0)
            local rpBg = rpBtn:CreateTexture(nil, "BACKGROUND")
            rpBg:SetAllPoints() rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7)
            rpBtn._bg = rpBg
            local rpLbl = rpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rpLbl:SetAllPoints() rpLbl:SetJustifyH("CENTER")
            row._rpBtn = rpBtn
            row._rpLbl = rpLbl
            rpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            rpBtn:SetScript("OnEnter", function() rpBg:SetColorTexture(0.20, 0.35, 0.60, 0.9) end)
            rpBtn:SetScript("OnLeave", function() rpBg:SetColorTexture(0.08, 0.12, 0.22, 0.7) end)

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT",  row, "LEFT",  24, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT", -44, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetTextColor(0.78, 0.90, 1, 1)
            row._lbl = lbl

            local xb = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            xb:SetSize(18, 18)
            xb:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row._xb = xb

            condRowPool[rowIdx] = row
        end

        local row = condRowPool[rowIdx]
        row:ClearAllPoints()
        row:SetSize(GetRightPanelWidth() - 12, 22)
        row:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase)
        rowYTops[i] = yBase
        row._lbl:SetText(CondSummaryText(cond, rule.spellID))
        row._lbl:SetTextColor(cond.negate and 1 or 0.78, cond.negate and 0.38 or 0.90, cond.negate and 0.38 or 1, 1)
        local capturedI    = i
        local capturedCond = cond
        -- Snapshot depth lists so closures don't capture by-reference after loop mutation.
        local capturedLpD  = lpDepths[i] or {}
        local capturedRpD  = rpDepths[i] or {}

        local function UpdateLPBtn()
            local n = capturedCond.lparen or 0
            local hasError = (unmatchedOpens[capturedI] or 0) > 0
            if n == 0 then
                row._lpLbl:SetText("(")
                row._lpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                -- Build a colored string per paren, each at its own depth.
                local parts = {}
                for k = 1, n do
                    local d = capturedLpD[k] or k
                    local c = GROUP_BOX_COLORS[((d - 1) % #GROUP_BOX_COLORS) + 1]
                    parts[k] = ("|cff%02x%02x%02x(|r"):format(c[5]*255, c[6]*255, c[7]*255)
                end
                row._lpLbl:SetText(table.concat(parts))
                if hasError then
                    row._lpLbl:SetTextColor(1.0, 0.30, 0.30, 1)
                end
            end
            row._lpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end
        local function UpdateRPBtn()
            local n = capturedCond.rparen or 0
            local hasError = (unmatchedCloses[capturedI] or 0) > 0
            if n == 0 then
                row._rpLbl:SetText(")")
                row._rpLbl:SetTextColor(hasError and 1.0 or 0.28, hasError and 0.30 or 0.36, hasError and 0.30 or 0.52, 1)
            else
                local parts = {}
                for k = 1, n do
                    local d = capturedRpD[k] or (n - k + 1)
                    local c = GROUP_BOX_COLORS[((d - 1) % #GROUP_BOX_COLORS) + 1]
                    parts[k] = ("|cff%02x%02x%02x)|r"):format(c[5]*255, c[6]*255, c[7]*255)
                end
                row._rpLbl:SetText(table.concat(parts))
                if hasError then
                    row._rpLbl:SetTextColor(1.0, 0.30, 0.30, 1)
                end
            end
            row._rpBtn._bg:SetColorTexture(hasError and 0.42 or 0.08, hasError and 0.08 or 0.12, hasError and 0.08 or 0.22, hasError and 0.85 or 0.7)
        end
        UpdateLPBtn()
        UpdateRPBtn()
        row._lpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.lparen = math.max(0, (capturedCond.lparen or 0) - 1)
            else
                capturedCond.lparen = ((capturedCond.lparen or 0) + 1) % 4
            end
            RefreshRightPanel()
            RefreshRuleList()
        end)
        row._rpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.rparen = math.max(0, (capturedCond.rparen or 0) - 1)
            else
                capturedCond.rparen = ((capturedCond.rparen or 0) + 1) % 4
            end
            RefreshRightPanel()
            RefreshRuleList()
        end)
        row._xb:SetScript("OnClick", function()
            if workingRules[selectedIdx] then
                table.remove(workingRules[selectedIdx].conditions, capturedI)
                selectedCondIdx = nil
                RefreshRightPanel()
                RefreshRuleList()
            end
        end)
        row:EnableMouse(true)
        row:SetScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" then
                selectedCondIdx = capturedI
                isAddingCond = true
                RefreshRightPanel()
            end
        end)
        row:SetScript("OnEnter", function()
            row:SetBackdropColor(0.14, 0.22, 0.35, 0.95)
        end)
        row:SetScript("OnLeave", function()
            row:SetBackdropColor(0.07, 0.11, 0.18, 0.85)
        end)
        row:Show()
        yBase = yBase - 26
    end

    DrawConditionGroupBoxes(spans, rowYTops)

    -- Add Condition button
    rightPanel.addCondBtn:SetWidth(GetRightPanelWidth() - 12)
    rightPanel.addCondBtn:ClearAllPoints()
    rightPanel.addCondBtn:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase - 4)
    rightPanel.addCondBtn:Show()
    yBase = yBase - 32

    -- Condition input area
    if isAddingCond then
        if not condInputArea then
            condInputArea = CreateCondInputArea(rightPanel)
        end
        condInputArea.confirmBtn:SetText(selectedCondIdx and "Update" or "Add")
        condInputArea.confirmBtn:SetScript("OnClick", function()
            local ct = condInputArea.GetSelectedType()
            if not ct then
                print("|cffff4444SBAS GUI:|r Select a condition type first.")
                return
            end
            local newCond = { type = ct.id, negate = condInputArea.GetNegate() }
            if ct.needsValue then newCond.value = condInputArea.GetValue() or ct.default end
            if ct.needsResource then
                newCond.resource = condInputArea.GetResource()
                newCond.operator = condInputArea.GetOperator()
                newCond.value    = condInputArea.GetValue() or 0
            end
            if ct.needsPlugin then
                local pid = condInputArea.GetPlugin()
                if not pid then
                    print("|cffff4444SBAS GUI:|r Select a plugin/proc first.")
                    return
                end
                newCond.plugin = pid
                if pid == "docj_timer" then
                    newCond.value    = condInputArea.GetValue() or 4
                    newCond.operator = condInputArea.GetTimerOperator()
                end
            end
            if ct.needsSpell then
                local sp = condInputArea.GetSpell()
                if sp == nil then
                    print("|cffff4444SBAS GUI:|r Enter a valid spell name for 'Other Spell'.")
                    return
                end
                newCond.spell = sp
            end
            local r = workingRules[selectedIdx]
            if r then
                r.conditions = r.conditions or {}
                if selectedCondIdx then
                    local existing = r.conditions[selectedCondIdx]
                    if existing then
                        for k in pairs(existing) do existing[k] = nil end
                        for k, v in pairs(newCond) do existing[k] = v end
                    end
                else
                    r.conditions[#r.conditions + 1] = newCond
                end
            end
            selectedCondIdx = nil
            isAddingCond = false
            RefreshRightPanel()
            RefreshRuleList()
        end)
        condInputArea:ClearAllPoints()
        if condInputArea.RefreshSize then condInputArea.RefreshSize() end
        condInputArea:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase - 4)
        if selectedCondIdx then
            local r = workingRules[selectedIdx]
            local existingCond = r and r.conditions and r.conditions[selectedCondIdx]
            if existingCond then
                condInputArea.Populate(existingCond)
            else
                condInputArea.Reset()
            end
        else
            condInputArea.Reset()
        end
        condInputArea:Show()
    else
        if condInputArea then condInputArea:Hide() end
    end
end

-------------------------------------------------------------------------------
-- 11b. Spellbook slide-out panel + drag-to-priority system
--
--  A tab button (spellbook icon) is attached to the left edge of the main
--  GUI frame.  Clicking it opens a 224-px-wide panel showing all active-spec
--  and general class spells pulled from the player's spellbook.
--
--  Interaction:
--    Left-click  a spell row → appends the spell to the bottom of the list.
--    Left-drag   a spell row → shows a floating icon; releasing over a rule
--                              row inserts the spell BEFORE that rule;
--                              releasing over the empty list area appends it.
-------------------------------------------------------------------------------
local sbasDrag = { active = false, spellID = nil, spellName = nil }
-- Assign into the forward-declared upvalues so CreateRowFrame closures can see them
ruleDrag      = { active = false, fromIdx = nil, pending = false, pendingX = 0, pendingY = 0 }
dragIconFrame = nil
dragCatcher   = nil
local dropIndicator = nil   -- horizontal line shown between rows while reordering

-- Forward declaration so CreateSpellbookPanel can call it for the reset button.
local ResetSeenCastsForCurrentSpec

-- Spells seen via successful player casts, persisted per spec in SavedVariables.
-- Only records spells that are overrides of a class ability (e.g. Rushing Wind Kick).
local seenCastSpells = {}
do
    local function CastsDB()
        SBA_SimpleDB           = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        return SBA_SimpleDB.castsSeen
    end

    local function LoadCastsForSpec()
        local specID = CurrentSpecID()
        wipe(seenCastSpells)
        if specID == 0 then return end
        local saved = CastsDB()[specID]
        if saved then
            for spellID, entry in pairs(saved) do
                seenCastSpells[spellID] = entry
            end
        end
    end

    ResetSeenCastsForCurrentSpec = function()
        local specID = CurrentSpecID()
        wipe(seenCastSpells)
        if specID ~= 0 then
            CastsDB()[specID] = {}
        end
    end

    local castTrackFrame = CreateFrame("Frame")
    castTrackFrame:RegisterEvent("PLAYER_LOGIN")
    castTrackFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    castTrackFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    castTrackFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            LoadCastsForSpec()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit ~= "player" or not spellID or seenCastSpells[spellID] then return end
            -- FindBaseSpellByID returns the spell this one overrides.
            -- If it returns a different ID, spellID is an override spell.
            local baseID = C_SpellBook.FindBaseSpellByID and C_SpellBook.FindBaseSpellByID(spellID)
            if not baseID or baseID == spellID then
                return
            end
            -- Confirm the base spell is actually a class/player ability
            if not IsPlayerSpell(baseID) then
                return
            end
            local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)
            if isPassive then return end
            local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            if not info or not info.name then return end
            local entry = {
                name    = info.name,
                spellID = spellID,
                texture = info.originalIconID or "Interface\\Icons\\INV_Misc_QuestionMark",
            }
            seenCastSpells[spellID] = entry
            local curSpec = CurrentSpecID()
            if curSpec ~= 0 then
                local db = CastsDB()
                db[curSpec]          = db[curSpec] or {}
                db[curSpec][spellID] = entry
            end
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            LoadCastsForSpec()
        end
    end)
end

-- Returns a sorted list of {name, spellID, texture} for the spec being edited.
-- When editing the player's current spec: scans the live spellbook, persists it
-- to SavedVariables, then merges any runtime-captured cast spells.
-- When editing a different spec: returns only the stored spells for that spec
-- (seeded on a prior session when you played that spec).
-- Excludes: off-spec lines, guild, flyouts, FutureSpell slots, and passives.
local function GetClassSpells()
    local curSpec    = CurrentSpecID()
    local targetSpec = (editSpecID ~= 0) and editSpecID or curSpec

    -- ── Cross-spec: skip live scan, just return stored spells for that spec ──
    if targetSpec ~= curSpec then
        local result, seenIDs = {}, {}
        local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
        if srcDB then
            for _, entry in pairs(srcDB) do
                if entry.spellID and not seenIDs[entry.spellID] then
                    seenIDs[entry.spellID] = true
                    result[#result + 1] = entry
                end
            end
        end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    end

    -- ── Own spec (or no API): live spellbook scan ─────────────────────────
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
        -- No spellbook API: fall back to stored data for the target spec.
        local result, seenIDs = {}, {}
        local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
        if srcDB then
            for _, entry in pairs(srcDB) do
                if entry.spellID and not seenIDs[entry.spellID] then
                    seenIDs[entry.spellID] = true
                    result[#result + 1] = entry
                end
            end
        end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    end
    local spells, seen = {}, {}
    local isFlyoutType = Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
    local isFutureType = Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell
    -- Primary tabs: class, active spec, racial — spells included freely (minus passives without icons)
    local primaryTabs = {}
    primaryTabs[UnitClass("player")] = true                        -- e.g. "Monk"
    primaryTabs[UnitRace("player")]  = true                        -- e.g. "Pandaren"
    local specIdx = GetSpecialization and GetSpecialization()
    if specIdx then
        local specName = select(2, GetSpecializationInfo(specIdx)) -- e.g. "Windwalker"
        if specName then primaryTabs[specName] = true end
    end
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for lineIdx = 1, numLines do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIdx)
        -- Visit all non-guild, non-offSpec tabs (includes General tab)
        if info and not info.isGuild and not info.offSpecID then
            local isPrimaryTab = primaryTabs[info.name]
            local offset = info.itemIndexOffset
            local count  = info.numSpellBookItems
            for j = offset + 1, offset + count do
                local name, subName =
                    C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                local itemType, spellID =
                    C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if name and spellID and spellID ~= 0 then
                    local isPassive = C_Spell.IsSpellPassive  and C_Spell.IsSpellPassive(spellID)
                    -- Non-primary tabs (e.g. General): only include if subtext contains "Racial"
                    local subtext   = (not isPrimaryTab) and C_Spell.GetSpellSubtext
                                      and C_Spell.GetSpellSubtext(spellID) or nil
                    local skip = (isFlyoutType and itemType == isFlyoutType)
                              or (isFutureType and itemType == isFutureType)
                              or (not isPrimaryTab and not (subtext and subtext:find("Racial")))
                              or (isPassive)   -- passives without an icon are excluded
                              or seen[spellID]
                    if not skip then
                        local baseInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
                        local baseName = (baseInfo and baseInfo.name) or name
                        seen[spellID] = true

                        local overID, overInfo, overName
                        if C_SpellBook.FindSpellOverrideByID then
                            local oid = C_SpellBook.FindSpellOverrideByID(spellID)
                            if oid and oid ~= spellID and not seen[oid] then
                                local isOverPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(oid)
                                if not isOverPassive then
                                    overID   = oid
                                    overInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(oid)
                                    overName = overInfo and overInfo.name
                                end
                            end
                        end

                        if overID then
                            seen[overID] = true
                            -- Names differ: both are distinct spells, add both
                            if overName and overName ~= baseName then
                                spells[#spells + 1] = {
                                    name    = baseName,
                                    spellID = spellID,
                                    texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                }
                            end
                            -- Always add the override (only entry when names match)
                            spells[#spells + 1] = {
                                name    = overName or baseName,
                                spellID = overID,
                                texture = (overInfo and overInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        else
                            -- No active override — add the base spell
                            spells[#spells + 1] = {
                                name    = baseName,
                                spellID = spellID,
                                texture = (baseInfo and baseInfo.originalIconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                            }
                        end
                    end
                end
            end
        end
    end
    -- Persist the freshly scanned spellbook spells into the current spec's store
    -- so they are available for cross-spec editing in future sessions.
    if curSpec ~= 0 then
        SBA_SimpleDB           = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        SBA_SimpleDB.castsSeen[curSpec] = SBA_SimpleDB.castsSeen[curSpec] or {}
        local curDB = SBA_SimpleDB.castsSeen[curSpec]
        for _, sp in ipairs(spells) do
            if not curDB[sp.spellID] then
                curDB[sp.spellID] = { name = sp.name, spellID = sp.spellID, texture = sp.texture }
            end
        end
    end

    -- Build name-index to avoid duplicates when merging stored data.
    local seenNames = {}
    for _, sp in ipairs(spells) do seenNames[sp.name] = true end

    -- Merge stored spells and any in-memory runtime captures for the current spec.
    local srcDB = SBA_SimpleDB and SBA_SimpleDB.castsSeen and SBA_SimpleDB.castsSeen[targetSpec]
    if srcDB then
        for castID, entry in pairs(srcDB) do
            if not seen[castID] and entry.name and not seenNames[entry.name] then
                seen[castID]           = true
                seenNames[entry.name]  = true
                spells[#spells + 1]    = entry
            end
        end
    end
    for castID, entry in pairs(seenCastSpells) do
        if not seen[castID] and entry.name and not seenNames[entry.name] then
            seen[castID] = true
            spells[#spells + 1] = entry
        end
    end
    table.sort(spells, function(a, b) return a.name < b.name end)
    return spells
end

EnsureDragIcon = function()
    if dragIconFrame then return end
    dragIconFrame = CreateFrame("Frame", "SBAS_SpellDragIcon", UIParent)
    dragIconFrame:SetSize(38, 38)
    dragIconFrame:SetFrameStrata("TOOLTIP")
    dragIconFrame:Hide()
    local tex = dragIconFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dragIconFrame._tex = tex
    local glow = dragIconFrame:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    glow:SetBlendMode("ADD")
    dragIconFrame:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
end

EnsureDragCatcher = function()
    if dragCatcher then return end
    dragCatcher = CreateFrame("Frame", "SBAS_SpellDragCatcher", UIParent)
    dragCatcher:SetAllPoints(UIParent)
    dragCatcher:SetFrameStrata("DIALOG")
    dragCatcher:EnableMouse(true)
    dragCatcher:Hide()

    -- Drop indicator: a bright horizontal line shown between rows during reorder
    dropIndicator = CreateFrame("Frame", "SBAS_DropIndicator", UIParent)
    dropIndicator:SetSize(1, 3)
    dropIndicator:SetFrameStrata("TOOLTIP")
    dropIndicator:Hide()
    local diTex = dropIndicator:CreateTexture(nil, "ARTWORK")
    diTex:SetAllPoints()
    diTex:SetColorTexture(0.3, 0.85, 1, 1)

    -- Helper: find which "slot" (1 = before row1, 2 = before row2, ..., n+1 = after last)
    -- the cursor is closest to, for the drop indicator.
    local function GetRuleDropSlot(mx, my)
        local best, bestDist = 1, math.huge
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rt = rf:GetTop()
                if rt then
                    local d = math.abs(my - rt)
                    if d < bestDist then bestDist = d; best = i end
                end
            end
        end
        -- Also check below the last visible row
        local lastVisible = 0
        for i, rf in ipairs(rowFrames) do if rf:IsShown() then lastVisible = i end end
        if lastVisible > 0 then
            local rb = rowFrames[lastVisible]:GetBottom()
            if rb and math.abs(my - rb) < bestDist then best = lastVisible + 1 end
        end
        return best
    end

    -- Shared drop-logic extracted so both OnUpdate (release-to-drop) and
    -- OnMouseUp (fallback) can call it without duplication.
    local function FinishRuleDrop()
        local fromIdx = ruleDrag.fromIdx
        ruleDrag.active  = false
        ruleDrag.fromIdx = nil
        if dragIconFrame then dragIconFrame:Hide() end
        if dropIndicator then dropIndicator:Hide() end
        dragCatcher:Hide()

        -- Restore borders
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                if rf._idx and rf._idx == selectedIdx then
                    rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else
                    rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                end
            end
        end

        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s
        local slot = GetRuleDropSlot(mx, my)
        slot = math.max(1, math.min(slot, #workingRules + 1))
        if slot ~= fromIdx and slot ~= fromIdx + 1 then
            local rule = table.remove(workingRules, fromIdx)
            local toIdx = (slot > fromIdx) and (slot - 1) or slot
            table.insert(workingRules, toIdx, rule)
            selectedIdx = toIdx
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end
    end

    local function FinishSpellDrop()
        sbasDrag.active = false
        if dragIconFrame then dragIconFrame:Hide() end
        dragCatcher:Hide()

        -- Restore row border colours
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                if rf._idx and rf._idx == selectedIdx then
                    rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                else
                    rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                end
            end
        end

        if not sbasDrag.spellID then return end

        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s

        local insertIdx = nil
        for i, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr = rf:GetLeft(),  rf:GetRight()
                local rt, rb = rf:GetTop(),   rf:GetBottom()
                if rl and rr and rt and rb
                   and mx >= rl and mx <= rr and my >= rb and my <= rt then
                    insertIdx = i
                    break
                end
            end
        end
        if not insertIdx and guiFrame and guiFrame._leftSF then
            local sf = guiFrame._leftSF
            local ll, lr = sf:GetLeft(),  sf:GetRight()
            local lt, lb = sf:GetTop(),   sf:GetBottom()
            if ll and lr and lt and lb
               and mx >= ll and mx <= lr and my >= lb and my <= lt then
                insertIdx = #workingRules + 1
            end
        end

        if insertIdx then
            local id   = sbasDrag.spellID
            local name = sbasDrag.spellName
            if insertIdx > #workingRules then
                workingRules[#workingRules + 1] = { spellID = id, name = name, conditions = {} }
                selectedIdx = #workingRules
            else
                table.insert(workingRules, insertIdx, { spellID = id, name = name, conditions = {} })
                selectedIdx = insertIdx
            end
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end

        sbasDrag.spellID   = nil
        sbasDrag.spellName = nil
    end

    -- Highlight row under cursor while dragging
    dragCatcher:SetScript("OnUpdate", function()
        -- ── Pending drag: wait for 8-px movement before activating ─────────
        if ruleDrag.pending then
            if not IsMouseButtonDown("LeftButton") then
                -- Mouse released before threshold — cancel cleanly
                ruleDrag.pending = false
                ruleDrag.fromIdx = nil
                dragCatcher:Hide()
                return
            end
            local cx, cy = GetCursorPosition()
            local s = UIParent:GetEffectiveScale()
            cx, cy = cx / s, cy / s
            local dx = cx - ruleDrag.pendingX
            local dy = cy - ruleDrag.pendingY
            if dx * dx + dy * dy > 64 then   -- 8-pixel threshold
                ruleDrag.pending = false
                ruleDrag.active  = true
                dragCatcher:EnableMouse(true)
                if dragIconFrame then dragIconFrame:Show() end
            end
            return
        end
        if not sbasDrag.active and not ruleDrag.active then return end
        local mx, my = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        mx, my = mx / s, my / s
        if ruleDrag.active then
            -- ── Drop as soon as the mouse button is released ─────────────
            if not IsMouseButtonDown("LeftButton") then
                FinishRuleDrop()
                return
            end
            -- Show drop indicator line between rows
            local slot = GetRuleDropSlot(mx, my)
            local indY = nil
            if slot <= #rowFrames and rowFrames[slot] and rowFrames[slot]:IsShown() then
                indY = rowFrames[slot]:GetTop()
            elseif slot > 1 and rowFrames[slot-1] and rowFrames[slot-1]:IsShown() then
                indY = rowFrames[slot-1]:GetBottom()
            end
            if indY and rowFrames[1] and rowFrames[1]:IsShown() then
                local rowW = rowFrames[1]:GetWidth()
                local rowL = rowFrames[1]:GetLeft()
                dropIndicator:ClearAllPoints()
                dropIndicator:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", rowL, indY)
                dropIndicator:SetWidth(rowW)
                dropIndicator:Show()
            end
            -- Dim the row being dragged
            for i, rf in ipairs(rowFrames) do
                if rf:IsShown() then
                    if i == ruleDrag.fromIdx then
                        rf:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
                    else
                        rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                    end
                end
            end
            return
        end
        -- sbasDrag: drop on release, otherwise highlight drop target row
        if not IsMouseButtonDown("LeftButton") then
            FinishSpellDrop()
            return
        end
        for _, rf in ipairs(rowFrames) do
            if rf:IsShown() then
                local rl, rr = rf:GetLeft(),  rf:GetRight()
                local rt, rb = rf:GetTop(),   rf:GetBottom()
                if rl and rr and rt and rb
                   and mx >= rl and mx <= rr and my >= rb and my <= rt then
                    rf:SetBackdropBorderColor(0.50, 0.88, 0.25, 1)
                else
                    if rf._idx and rf._idx == selectedIdx then
                        rf:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
                    else
                        rf:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
                    end
                end
            end
        end
    end)

    -- Finalise the drag on mouse-up (fallback; OnUpdate handles rule reorder
    -- via release detection, but spell-drop still needs this path)
    dragCatcher:SetScript("OnMouseUp", function(self, btn)
        -- Cancel a pending drag that never crossed the movement threshold
        if ruleDrag.pending then
            ruleDrag.pending = false
            ruleDrag.fromIdx = nil
            self:Hide()
            return
        end
        if btn ~= "LeftButton" then return end

        -- Rule reorder is handled by OnUpdate polling; call shared finish
        -- only if OnUpdate somehow missed it (e.g. very fast release)
        if ruleDrag.active then
            FinishRuleDrop()
            return
        end

        if not sbasDrag.active then self:Hide(); return end
        -- OnUpdate handles release-to-drop; this is just a fallback
        FinishSpellDrop()
    end)
end

local function CreateSpellbookPanel(f, leftSF)
    EnsureDragIcon()
    EnsureDragCatcher()
    f._leftSF = leftSF

    -- ── Slide-out spellbook panel ─────────────────────────────────────────
    -- The panel is parented to the main frame and positioned to its left.
    local PANEL_W = 264
    local panel   = CreateFrame("Frame", "SBAS_SpellbookPanel", f, "BackdropTemplate")
    panel:SetSize(PANEL_W, f:GetHeight())
    panel:SetPoint("TOPRIGHT", f, "TOPLEFT", -1, 0)
    panel:SetFrameLevel(f:GetFrameLevel() + 1)
    panel:Hide()
    SetBD(panel, 0.04, 0.06, 0.12, 0.97, 0.24, 0.44, 0.64)

    -- ── Tab button ────────────────────────────────────────────────────────
    -- Parented to the PANEL so it flies out with it when the panel shows.
    -- Positioned on the panel's RIGHT edge near the top so it peeks out
    -- against the main frame's left border.
    local TAB_W, TAB_H = 54, 56   -- taller to fit icon + label
    local tabBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    tabBtn:SetSize(TAB_W, TAB_H)
    tabBtn:SetFrameLevel(panel:GetFrameLevel() + 2)
    -- RIGHT edge of tab = LEFT edge of panel (tab peeks out to the far left)
    tabBtn:SetPoint("TOPRIGHT", panel, "TOPLEFT", 0, -14)
    SetBD(tabBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    -- Book icon above the label
    local tabIcon = tabBtn:CreateTexture(nil, "ARTWORK")
    tabIcon:SetSize(28, 28)
    tabIcon:SetPoint("TOP", tabBtn, "TOP", 0, -5)
    tabIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    tabIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- "Spells" label below the icon
    local tabLbl = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLbl:SetPoint("BOTTOM", tabBtn, "BOTTOM", 0, 6)
    tabLbl:SetJustifyH("CENTER")
    tabLbl:SetText("Spells")
    tabLbl:SetTextColor(0.65, 0.85, 1, 1)

    tabBtn:SetScript("OnEnter", function()
        tabIcon:SetVertexColor(0.5, 0.85, 1, 1)
        tabLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(tabBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    tabBtn:SetScript("OnLeave", function()
        tabIcon:SetVertexColor(1, 1, 1, 1)
        tabLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    -- When the panel is hidden the tab still needs to be clickable to reopen.
    -- We achieve this by keeping the panel's tab visible at all times and
    -- hooking the panel OnHide to show just the tab stub on the main frame.
    -- Simpler: keep a separate stub button parented to the main frame that
    -- is shown only when the panel is hidden.
    local stubBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    stubBtn:SetSize(TAB_W, TAB_H)
    stubBtn:SetFrameLevel(f:GetFrameLevel() + 3)
    stubBtn:SetPoint("TOPLEFT", f, "TOPLEFT", -TAB_W, -14)
    SetBD(stubBtn, 0.05, 0.08, 0.14, 0.95, 0.24, 0.44, 0.64)

    local stubIcon = stubBtn:CreateTexture(nil, "ARTWORK")
    stubIcon:SetSize(28, 28)
    stubIcon:SetPoint("TOP", stubBtn, "TOP", 0, -5)
    stubIcon:SetTexture("Interface\\Icons\\inv_misc_book_09")
    stubIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local stubLbl = stubBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stubLbl:SetPoint("BOTTOM", stubBtn, "BOTTOM", 0, 6)
    stubLbl:SetJustifyH("CENTER")
    stubLbl:SetText("Spells")
    stubLbl:SetTextColor(0.65, 0.85, 1, 1)

    stubBtn:SetScript("OnEnter", function()
        stubIcon:SetVertexColor(0.5, 0.85, 1, 1)
        stubLbl:SetTextColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(stubBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Spells")
        GameTooltip:AddLine("Click to add  ·  Drag to insert at position", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    stubBtn:SetScript("OnLeave", function()
        stubIcon:SetVertexColor(1, 1, 1, 1)
        stubLbl:SetTextColor(0.65, 0.85, 1, 1)
        GameTooltip:Hide()
    end)

    local phdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -12)
    phdr:SetText("Spells")
    phdr:SetTextColor(0.38, 0.74, 1, 1)

    -- Reset button: clears the persisted seen-spells list for the current spec
    local resetBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    resetBtn:SetSize(52, 16)
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -10)
    SetBD(resetBtn, 0.28, 0.05, 0.05, 0.90, 0.65, 0.18, 0.18)
    local resetLbl = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetLbl:SetAllPoints()
    resetLbl:SetJustifyH("CENTER")
    resetLbl:SetText("Reset")
    resetLbl:SetTextColor(1, 0.55, 0.55, 1)
    resetBtn:SetScript("OnEnter", function(self)
        resetLbl:SetTextColor(1, 0.8, 0.8, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Reset Spell Cache", 1, 0.6, 0.6)
        GameTooltip:AddLine("Clears the cached spell list for this spec.\nReopening the GUI will rebuild it from your spellbook.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        resetLbl:SetTextColor(1, 0.55, 0.55, 1)
        GameTooltip:Hide()
    end)
    -- OnClick wired up below, after RefreshSpellbookPanel is defined.

    local searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetSize(PANEL_W - 16, 22)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(64)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local divLine = panel:CreateTexture(nil, "ARTWORK")
    divLine:SetSize(PANEL_W - 8, 1)
    divLine:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -4)
    divLine:SetColorTexture(0.25, 0.40, 0.60, 0.6)

    local hintLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintLbl:SetPoint("TOPLEFT", divLine, "BOTTOMLEFT", 4, -3)
    hintLbl:SetSize(PANEL_W - 16, 24)
    hintLbl:SetJustifyH("LEFT")
    hintLbl:SetText("Click to add  ·  Drag to insert at position")
    hintLbl:SetTextColor(0.48, 0.62, 0.72, 1)

    local panelSF = CreateFrame("ScrollFrame", nil, panel)
    panelSF:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4, -92)
    panelSF:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4,  4)
    panelSF:EnableMouseWheel(true)
    panelSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * 28, 0), m))
    end)

    local panelContent = CreateFrame("Frame", nil, panelSF)
    panelContent:SetSize(PANEL_W - 8, 100)
    panelSF:SetScrollChild(panelContent)

    local spellRowPool  = {}
    local currentSpells = {}
    local SPELL_ROW_H   = 30

    local function CreateSpellEntry(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(PANEL_W - 8, SPELL_ROW_H - 2)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:RegisterForClicks("LeftButtonUp")

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        row._bg = bg

        local iconBg = row:CreateTexture(nil, "BACKGROUND")
        iconBg:SetSize(24, 24)
        iconBg:SetPoint("LEFT", row, "LEFT", 4, 0)
        iconBg:SetColorTexture(0, 0, 0, 0.45)

        local iconTex = row:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(22, 22)
        iconTex:SetPoint("CENTER", iconBg, "CENTER")
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = iconTex

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameLbl:SetPoint("LEFT",  iconBg, "RIGHT", 6, 0)
        nameLbl:SetPoint("RIGHT", row,    "RIGHT", -4, 0)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetTextColor(0.88, 0.92, 1, 1)
        row._nameLbl = nameLbl

        row:SetScript("OnEnter", function(self)
            self._bg:SetColorTexture(0.16, 0.28, 0.48, 0.70)
            if self._spellID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self._spellID)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)

        -- Left-click: append to end of priority list
        row:SetScript("OnClick", function(self)
            if not self._spellID then return end
            local addID, addName = ResolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            workingRules[#workingRules + 1] = {
                spellID    = addID,
                name       = addName,
                conditions = {},
            }
            selectedIdx  = #workingRules
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end)

        -- Left-drag: drag to a specific position in the priority list
        row:SetScript("OnDragStart", function(self)
            if not self._spellID then return end
            local addID, addName = ResolveSpellForAdd(self._spellID, self._spellName)
            if not addID then return end
            sbasDrag.active    = true
            sbasDrag.spellID   = addID
            sbasDrag.spellName = addName
            dragIconFrame._tex:SetTexture(self._icon:GetTexture())
            dragIconFrame:Show()
            dragCatcher:Show()
        end)

        return row
    end

    local function PopulatePanel(filterText)
        local filter = (filterText or ""):lower()
        local shown  = 0
        for _, spell in ipairs(currentSpells) do
            if filter == "" or spell.name:lower():find(filter, 1, true) then
                shown = shown + 1
                if not spellRowPool[shown] then
                    spellRowPool[shown] = CreateSpellEntry(panelContent)
                end
                local row = spellRowPool[shown]
                row._spellID   = spell.spellID
                row._spellName = spell.name
                row._icon:SetTexture(spell.texture)
                row._nameLbl:SetText(spell.name)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", panelContent, "TOPLEFT", 0, -(shown - 1) * SPELL_ROW_H)
                row:Show()
            end
        end
        for i = shown + 1, #spellRowPool do
            if spellRowPool[i] then spellRowPool[i]:Hide() end
        end
        panelContent:SetHeight(math.max(shown * SPELL_ROW_H + 4, 100))
    end

    local function RefreshSpellbookPanel()
        currentSpells = GetClassSpells()
        PopulatePanel(searchBox:GetText())
    end
    -- Expose so OpenGUI can force a refresh on every open.
    f._refreshSpellPanel = RefreshSpellbookPanel

    -- Wire up the reset button now that RefreshSpellbookPanel is in scope.
    resetBtn:SetScript("OnClick", function()
        ResetSeenCastsForCurrentSpec()
        RefreshSpellbookPanel()
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        PopulatePanel(self:GetText())
    end)

    local function OpenPanel()
        RefreshSpellbookPanel()
        stubBtn:Hide()
        panel:Show()
    end

    local function ClosePanel()
        panel:Hide()
        stubBtn:Show()
    end

    tabBtn:SetScript("OnClick",  function() ClosePanel() end)
    stubBtn:SetScript("OnClick", function() OpenPanel()  end)

    -- Start with the stub visible (panel closed)
    stubBtn:Show()

    -- Keep panel height in sync with the main frame
    f:HookScript("OnSizeChanged", function(self)
        panel:SetHeight(self:GetHeight())
    end)

    -- ── Rebuild spell list on talent/spec change ──────────────────────────
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshSpellbookPanel()
        else
            -- Mark stale so the next open rebuilds automatically
            currentSpells = nil
        end
    end)

    -- Rebuild when panel opens if the list was marked stale
    panel:HookScript("OnShow", function()
        if currentSpells == nil then
            RefreshSpellbookPanel()
        end
    end)
end

-------------------------------------------------------------------------------
-- 12. Main GUI frame
-------------------------------------------------------------------------------
local function CreateGUI()
    local f = CreateFrame("Frame", "SBAS_OverrideGUI_Frame", UIParent, "BackdropTemplate")
    f:SetSize(GUI_W, GUI_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:SetFrameStrata("HIGH")
    if f.SetResizeBounds then
        f:SetResizeBounds(GUI_MIN_W, GUI_MIN_H)
    elseif f.SetMinResize then
        f:SetMinResize(GUI_MIN_W, GUI_MIN_H)
    end
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    SetBD(f, 0.03, 0.05, 0.09, 0.97, 0.24, 0.44, 0.64)

    -- Do NOT add to UISpecialFrames — that table is iterated by CloseAllWindows()
    -- which WoW calls when the Settings window closes via Escape, causing the GUI
    -- to be hidden as an unintended side-effect.  Instead, handle Escape directly.
    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetTextColor(0.38, 0.74, 1, 1)

    local subNote = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subNote:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
    subNote:SetText("Top = highest priority · Saving overwrites override code for this spec")
    subNote:SetTextColor(0.44, 0.55, 0.68, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f:HookScript("OnHide", function()
        CloseAllPopups()
        -- Auto-save rule structure to the same store as the explicit Save button so
        -- rules survive close/reopen within a session and across /reload.  The compiled
        -- override code is NOT regenerated here — that still requires "Save & Apply".
        if editSpecID and editSpecID ~= 0 then
            sessionRules[editSpecID]    = workingRules          -- in-session reference
            GuiDB()[editSpecID]         = DeepCopyRules(workingRules) -- persisted storage
        end
    end)

    -- Belt-and-suspenders: also save on PLAYER_LOGOUT/PLAYER_QUITING so that
    -- a /reload where OnHide may not fire still persists the working rules.
    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:RegisterEvent("PLAYER_QUITING")
    logoutFrame:SetScript("OnEvent", function()
        if editSpecID and editSpecID ~= 0 then
            GuiDB()[editSpecID] = DeepCopyRules(workingRules)
        end
    end)

    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
        f.isSizing = true
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        if f.isSizing then
            f:StopMovingOrSizing()
            f.isSizing = false
        end
    end)

    -- ── Left panel: priority list ──────────────────────────────────────────
    local leftHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftHdr:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -48)
    leftHdr:SetText("Priority List")
    leftHdr:SetTextColor(0.50, 0.72, 0.90, 1)

    local leftSF = CreateFrame("ScrollFrame", nil, f)
    leftSF:SetPoint("TOPLEFT",     f, "TOPLEFT", PAD, -64)
    -- Reserve 64px top (header) + 38px footer buttons + 34px Add Spell btn + gap = 136px
    leftSF:SetSize(LEFT_W, GUI_H - 136)
    leftSF:EnableMouseWheel(true)
    leftSF:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * ROW_H, 0), m))
    end)
    f._leftSF = leftSF   -- stored for drag-drop drop-zone detection

    local lc = CreateFrame("Frame", nil, leftSF)
    lc:SetSize(LEFT_W, 100)
    leftSF:SetScrollChild(lc)
    leftChild = lc

    -- Add Spell button
    local addSpellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addSpellBtn:SetSize(LEFT_W, 26)
    addSpellBtn:SetPoint("TOPLEFT", leftSF, "BOTTOMLEFT", 0, -4)
    addSpellBtn:SetText("+ Add Spell")
    addSpellBtn:SetScript("OnClick", function()
        if addSpellPopup and addSpellPopup:IsShown() then CloseAllPopups(); return end
        CloseAllPopups()
        if not addSpellPopup then
            addSpellPopup = CreateAddSpellPopup()
        end
        addSpellPopup.onAdd = function(id, name)
            local addID, addName = ResolveSpellForAdd(id, name)
            if not addID then return end
            workingRules[#workingRules + 1] = { spellID = addID, name = addName, conditions = {} }
            selectedIdx  = #workingRules
            isAddingCond = false
            RefreshRuleList()
            RefreshRightPanel()
        end
        addSpellPopup.nameBox:SetText("")
        addSpellPopup.iconTex:Hide()
        addSpellPopup:ClearAllPoints()
        addSpellPopup:SetPoint("TOPLEFT", addSpellBtn, "BOTTOMLEFT", 0, -2)
        addSpellPopup:Show()
        addSpellPopup.nameBox:SetFocus()
    end)

    -- ── Right panel: condition editor ──────────────────────────────────────
    local rp = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rp:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    -PAD, -64)
    rp:SetSize(RIGHT_W, GUI_H - 110)
    SetBD(rp, 0.04, 0.07, 0.13, 0.90, 0.18, 0.33, 0.53)

    local rpHdr = rp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rpHdr:SetPoint("TOPLEFT", rp, "TOPLEFT", 8, -8)
    rpHdr:SetSize(RIGHT_W - 16, 18)
    rpHdr:SetJustifyH("LEFT")
    rpHdr:SetText("Conditions")
    rpHdr:SetTextColor(0.50, 0.72, 0.90, 1)
    rp.header = rpHdr

    local addCondBtn = CreateFrame("Button", nil, rp, "UIPanelButtonTemplate")
    addCondBtn:SetSize(RIGHT_W - 12, 24)
    addCondBtn:SetText("+ Add Condition")
    addCondBtn:SetScript("OnClick", function()
        if selectedIdx > 0 and workingRules[selectedIdx] then
            selectedCondIdx = nil
            isAddingCond = true
            RefreshRightPanel()
        end
    end)
    addCondBtn:Hide()
    rp.addCondBtn = addCondBtn

    rightPanel = rp

    -- ── Footer buttons ─────────────────────────────────────────────────────
    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(128, 28)
    saveBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD + 4)
    saveBtn:SetText("Save & Apply")
    saveBtn:SetScript("OnClick", function()
        -- Persist GUI rules
        GuiDB()[editSpecID] = DeepCopyRules(workingRules)
        -- Keep the session cache in sync
        sessionRules[editSpecID] = workingRules

        -- Generate and save override code
        local code = GenerateCode(workingRules) or ""
        SBA_SimpleDB.specs                         = SBA_SimpleDB.specs or {}
        SBA_SimpleDB.specs[editSpecID]             = SBA_SimpleDB.specs[editSpecID] or {}
        SBA_SimpleDB.specs[editSpecID].overrideCode = code
        SBA_SimpleDB.overrideCode                  = code

        -- Compile if editing current spec
        if editSpecID == CurrentSpecID() and type(SBA_Simple_SetOverrideCode) == "function" then
            SBA_Simple_SetOverrideCode(code)
        end

        print("|cff00ff99SBAS Override GUI:|r Priority list saved for "
              .. GetSpecName(editSpecID))
        f:Hide()
    end)

    local previewBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    previewBtn:SetSize(118, 28)
    previewBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    previewBtn:SetText("Preview Code")
    previewBtn:SetScript("OnClick", function()
        local code = GenerateCode(workingRules) or "-- (no rules defined)"
        -- Open raw override editor in temporary preview mode (non-persistent).
        if type(SBA_Simple_ShowOverridePreview) == "function" then
            SBA_Simple_ShowOverridePreview(code, editSpecID, GetSpecName(editSpecID))
        else
            -- Fallback for older SBA_Simple versions where preview API isn't available.
            local eb = _G["SBAS_OverrideEditBox"]
            local of = _G["SBAS_OverrideFrame"]
            if eb and of then
                eb:SetText(code)
                of:Show()
            else
                print("|cff00ccffSBAS Preview:|r\n" .. code)
            end
        end
    end)

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(104, 28)
    clearBtn:SetPoint("LEFT", previewBtn, "RIGHT", 6, 0)
    clearBtn:SetText("Clear All Rules")
    clearBtn:SetScript("OnClick", function()
        workingRules = {}
        selectedIdx  = 0
        isAddingCond = false
        RefreshRuleList()
        RefreshRightPanel()
    end)

    local function LayoutGUI()
        local leftW, rightW = GetPanelWidths(f:GetWidth())
        leftSF:SetSize(leftW, f:GetHeight() - 136)
        lc:SetWidth(leftW)
        addSpellBtn:SetWidth(leftW)
        rp:SetSize(rightW, f:GetHeight() - 110)
        rpHdr:SetWidth(rightW - 16)
        addCondBtn:SetWidth(rightW - 12)
        if condInputArea and condInputArea.RefreshSize then
            condInputArea.RefreshSize()
        end
        if f:IsShown() then
            RefreshRuleList()
            RefreshRightPanel()
        end
    end

    f:SetScript("OnSizeChanged", function()
        LayoutGUI()
    end)

    LayoutGUI()

    CreateSpellbookPanel(f, leftSF)

    guiFrame = f
end

-------------------------------------------------------------------------------
-- 13. Open the GUI
-------------------------------------------------------------------------------
local function OpenGUI(specID, displayName)
    if not guiFrame then CreateGUI() end

    local targetSpec = specID or CurrentSpecID()
    -- If the API can't determine the spec yet, keep whatever is loaded
    if targetSpec == 0 then targetSpec = editSpecID end

    if targetSpec ~= editSpecID then
        editSpecID = targetSpec
        if sessionRules[editSpecID] then
            -- Already seen this spec this session — reuse the live in-memory table
            workingRules = sessionRules[editSpecID]
        else
            -- First time opening this spec this session: load from persistent storage
            workingRules = DeepCopyRules(GetGuiRules(editSpecID))
        end
        selectedIdx  = (#workingRules > 0) and 1 or 0
        isAddingCond = false
    end
    -- Same spec: workingRules unchanged — all unsaved edits are still in memory.
    -- Seed the session cache if this is the very first open.
    if not sessionRules[editSpecID] then
        sessionRules[editSpecID] = workingRules
    end

    guiFrame.title:SetText("SBA Override Builder — " .. (displayName or GetSpecName(editSpecID)))
    guiFrame:Show()
    -- Refresh the flyout spell list on every open so it reflects the current
    -- spec, any newly cast override spells, and talent changes.
    if guiFrame._refreshSpellPanel then
        guiFrame._refreshSpellPanel()
    end
    RefreshRuleList()
    RefreshRightPanel()
end

_G.SBAS_OpenOverrideGUI = OpenGUI

-------------------------------------------------------------------------------
-- 14. Hook the existing slash command to add "override_gui"
--     This file loads after SBA_Simple.lua, so we wrap the existing handler.
--     OpenGUI is local to this file, so no global indirection is needed.
-------------------------------------------------------------------------------
local _origSBAS = SlashCmdList["SBASIMPLE"]
SlashCmdList["SBASIMPLE"] = function(msg)
    local cmd = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "override_gui" then
        OpenGUI()
    else
        if _origSBAS then _origSBAS(msg) end
    end
end
