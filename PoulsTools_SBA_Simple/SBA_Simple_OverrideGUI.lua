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
    { id = "on_cd",        label = "On Cooldown",               needsSpell = true,
      generate = function(c, s) return ("C_Spell.GetSpellCooldown(%d).isActive"):format(ResolveSpell(c,s)) end },
    { id = "reactive_enabled", label = "Reactive Spell Enabled", needsSpell = true,
      generate = function(c, s) return ("C_Spell.GetSpellCooldown(%d).isEnabled"):format(ResolveSpell(c,s)) end },
    { id = "usable",       label = "Is Usable",                 needsSpell = true,
      generate = function(c, s) return ("C_Spell.IsSpellUsable(%d)"):format(ResolveSpell(c,s)) end },
    { id = "talented",     label = "Talented",                  needsSpell = true,
      generate = function(c, s) return ("IsPlayerSpell(%d)"):format(ResolveSpell(c,s)) end },
    { id = "last_combo_eq",label = "Last Combo Strike = Spell", needsSpell = true,
      generate = function(c, s) return ("LastComboStrikeSpellID == %d"):format(ResolveSpell(c,s)) end },
    -- SBA
    { id = "sba_suggests", label = "SBA Suggests This Spell",
      generate = function(c, s) return ("spellID == %d"):format(s) end },
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
          if c.plugin == "docj_timer" then return ("docj_proc_timer < %d"):format(c.value or 4) end
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
    { id = "docj_timer", label = "DOCJ Timer <", needsValue = true, default = 4 },
}

-------------------------------------------------------------------------------
-- 2.  Data helpers
-------------------------------------------------------------------------------
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
            docj_timer = "DOCJ Timer <",
        }
        local pLabel = PLUGIN_LABELS[cond.plugin] or (cond.plugin or "?")
        t = (cond.plugin == "docj_timer")
            and (pLabel .. " " .. tostring(cond.value or 4))
            or  pLabel
    else
        t = def.label
        if def.needsSpell then
            if not cond.spell or cond.spell == "this" then
                t = t .. " [this]"
            else
                local id = type(cond.spell) == "number" and cond.spell or cond.targetID
                local n = id and (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
                t = t .. " [" .. (n or "?") .. "]"
            end
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
    for i, rule in ipairs(rules) do
        if (rule.spellID or 0) > 0 then
            local parts     = {}
            local junctions = {}
            for ci, cond in ipairs(rule.conditions or {}) do
                local def = COND_BY_ID[cond.type]
                if def then
                    local frag = def.generate(cond, rule.spellID)
                    if cond.negate then frag = "not (" .. frag .. ")" end
                    local lp = (cond.lparen or 0) > 0 and string.rep("(", cond.lparen) or ""
                    local rp = (cond.rparen or 0) > 0 and string.rep(")", cond.rparen) or ""
                    parts[#parts+1]         = lp .. frag .. rp
                    junctions[#junctions+1] = (ci > 1) and (cond.junction or "and") or nil
                end
            end
            L[#L+1] = ("-- Priority %d: %s (%d)"):format(i, rule.name or "?", rule.spellID)
            if #parts > 0 then
                local expr = parts[1]
                for pi = 2, #parts do
                    expr = expr .. " " .. (junctions[pi] or "and") .. " " .. parts[pi]
                end
                L[#L+1] = ("if %s then return %d end"):format(expr, rule.spellID)
            else
                -- No conditions: unconditional (this blocks everything below it)
                L[#L+1] = ("return %d  -- unconditional"):format(rule.spellID)
            end
            L[#L+1] = ""
        end
    end
    L[#L+1] = "-- Fallback: SBA assisted-combat suggestion"
    L[#L+1] = "return spellID"
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
        local name = select(1, GetSpecializationInfoByID(specID))
        if name then return name end
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
local condPicker = nil

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
local addSpellPopup = nil

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
    title:SetText("Add Spell by Name")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local namInLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    namInLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -30)
    namInLbl:SetText("Spell Name:")
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
        -- Primary: exact name lookup (available in 12.x)
        local id = nil
        if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
        end
        if id and id > 0 then
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
        -- If resolved, confirm immediately on Enter
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
            resultLbl:SetText("|cffff5555Enter a valid spell name first|r")
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

local guiFrame     = nil   -- main frame (created once)
local leftChild    = nil   -- scroll child for rule rows
local rightPanel   = nil   -- condition editor panel
local condInputArea= nil   -- "add condition" sub-frame inside rightPanel

local workingRules = {}    -- deep-copy being edited
local editSpecID   = 0
local selectedIdx  = 0     -- 1-based; 0 = none
local isAddingCond = false
local selectedCondIdx = nil  -- nil = adding new; number = editing existing cond at that index

local rowFrames        = {}    -- pool of rule-row frames
local condRowPool      = {}    -- pool of condition-row frames in right panel
local condJunctionPool = {}    -- pool of AND/OR junction toggles between condition rows

-- Forward declarations
local RefreshRuleList, RefreshRightPanel

-------------------------------------------------------------------------------
-- 9.  Rule-row frames
-------------------------------------------------------------------------------
local function CreateRowFrame(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(LEFT_W - PAD * 2, ROW_H - 4)
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

    -- Condition summary
    f.condLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.condLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 6)
    f.condLabel:SetSize(LEFT_W - 130, 14)
    f.condLabel:SetJustifyH("LEFT")
    f.condLabel:SetTextColor(0.50, 0.72, 0.55, 1)

    -- Buttons (top-right)
    f.removeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.removeBtn:SetSize(20, 20)
    f.removeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    f.downBtn = CreateFrame("Button", nil, f)
    f.downBtn:SetSize(18, 18)
    f.downBtn:SetPoint("RIGHT", f.removeBtn, "LEFT", -3, 0)
    f.downBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
    f.downBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
    f.downBtn:SetHighlightTexture("Interface\\Buttons\\Arrow-Down-Up")
    f.downBtn:GetHighlightTexture():SetVertexColor(0.8, 0.9, 1, 0.5)

    f.upBtn = CreateFrame("Button", nil, f)
    f.upBtn:SetSize(18, 18)
    f.upBtn:SetPoint("RIGHT", f.downBtn, "LEFT", -3, 0)
    f.upBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
    f.upBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
    f.upBtn:SetHighlightTexture("Interface\\Buttons\\Arrow-Up-Up")
    f.upBtn:GetHighlightTexture():SetVertexColor(0.8, 0.9, 1, 0.5)

    f:SetScript("OnMouseDown", function(self)
        if self._idx then selectedIdx = self._idx; isAddingCond = false
            RefreshRuleList(); RefreshRightPanel() end
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

local function UpdateRowFrame(f, idx, rule)
    f._idx = idx
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", leftChild, "TOPLEFT", PAD, -PAD - (idx - 1) * ROW_H)
    f:Show()

    f.badge:SetText(tostring(idx))

    local tex = rule.spellID and C_Spell and C_Spell.GetSpellTexture
                and C_Spell.GetSpellTexture(rule.spellID)
    f.iconTex:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    f.nameLabel:SetText(rule.name or "Unknown")
    f.idLabel:SetText("ID: " .. tostring(rule.spellID or 0))

    local condCount = #(rule.conditions or {})
    if condCount == 0 then
        f.condLabel:SetText("|cffff9944No conditions — unconditional return|r")
    else
        local items = {}
        for i = 1, math.min(3, condCount) do
            local cond = rule.conditions[i] or {}
            local def  = COND_BY_ID[cond.type]
            if def then
                if #items > 0 then
                    local j = cond.junction or "and"
                    items[#items+1] = "|cff8899cc" .. j:upper() .. "|r"
                end
                local lp = (cond.lparen or 0) > 0 and "|cffffff55" .. string.rep("(", cond.lparen) .. "|r" or ""
                local rp = (cond.rparen or 0) > 0 and "|cffffff55" .. string.rep(")", cond.rparen) .. "|r" or ""
                local labelText = cond.negate and ("|cffff4444NOT " .. def.label .. "|r") or def.label
                items[#items+1] = lp .. labelText .. rp
            end
        end
        local txt = table.concat(items, " ")
        if condCount > 3 then txt = txt .. (" +%d more"):format(condCount - 3) end
        f.condLabel:SetText(txt)
    end

    if idx == selectedIdx then
        f:SetBackdropColor(0.08, 0.20, 0.36, 0.95)
        f:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
    else
        f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        f:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
    end

    f.upBtn:SetEnabled(idx > 1)
    f.upBtn:SetScript("OnClick", function()
        local r = table.remove(workingRules, idx)
        table.insert(workingRules, idx - 1, r)
        selectedIdx = idx - 1
        RefreshRuleList(); RefreshRightPanel()
    end)

    f.downBtn:SetEnabled(idx < #workingRules)
    f.downBtn:SetScript("OnClick", function()
        local r = table.remove(workingRules, idx)
        table.insert(workingRules, idx + 1, r)
        selectedIdx = idx + 1
        RefreshRuleList(); RefreshRightPanel()
    end)

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
    for i = 1, count do
        if not rowFrames[i] then
            rowFrames[i] = CreateRowFrame(leftChild)
        end
        UpdateRowFrame(rowFrames[i], i, workingRules[i])
    end
    for i = count + 1, #rowFrames do
        if rowFrames[i] then rowFrames[i]:Hide() end
    end
    leftChild:SetHeight(math.max(count * ROW_H + PAD * 2, 100))
end

-------------------------------------------------------------------------------
-- 6b. Plugin / Proc picker popup
-------------------------------------------------------------------------------
local pluginPicker = nil

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
local function CreateCondInputArea(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(RIGHT_W - 10, 95)
    SetBD(f, 0.04, 0.07, 0.13, 0.97, 0.20, 0.40, 0.60)

    local selType           = nil
    local spellSel          = "this"   -- "this" or "other"
    local resolvedOtherID   = nil
    local resolvedOtherName = nil
    local resSel            = "chi"    -- "chi" or "energy"
    local opSel             = ">="     -- ">=", "<=", "=="

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
    typeBtn:SetSize(RIGHT_W - 18, 22)
    typeBtn:SetPoint("TOPLEFT", notCheck, "BOTTOMLEFT", 0, -4)
    typeBtn:SetText("Select condition type...")

    -- ── Spell toggle: This Spell / Other Spell ────────────────────────────
    local spellToggleFrame = CreateFrame("Frame", nil, f)
    spellToggleFrame:SetSize(RIGHT_W - 18, 22)
    spellToggleFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    spellToggleFrame:Hide()

    local halfW = math.floor((RIGHT_W - 22) / 2)
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
    otherFrame:SetSize(RIGHT_W - 18, 38)
    otherFrame:SetPoint("TOPLEFT", spellToggleFrame, "BOTTOMLEFT", 0, -2)
    otherFrame:Hide()

    local otherNameBox = CreateFrame("EditBox", nil, otherFrame, "InputBoxTemplate")
    otherNameBox:SetSize(RIGHT_W - 52, 20)
    otherNameBox:SetPoint("TOPLEFT", otherFrame, "TOPLEFT")
    otherNameBox:SetAutoFocus(false)
    otherNameBox:SetMaxLetters(80)

    local otherIcon = otherFrame:CreateTexture(nil, "ARTWORK")
    otherIcon:SetSize(18, 18)
    otherIcon:SetPoint("LEFT", otherNameBox, "RIGHT", 4, 0)
    otherIcon:Hide()

    local otherResultLbl = otherFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    otherResultLbl:SetPoint("TOPLEFT", otherNameBox, "BOTTOMLEFT", 0, -2)
    otherResultLbl:SetSize(RIGHT_W - 22, 14)
    otherResultLbl:SetJustifyH("LEFT")

    otherNameBox:SetScript("OnTextChanged", function()
        local input = otherNameBox:GetText():match("^%s*(.-)%s*$")
        if input == "" then
            otherResultLbl:SetText("") otherIcon:Hide() resolvedOtherID = nil; return
        end
        local id
        if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
            id = C_Spell.GetSpellIDForSpellIdentifier(input)
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
    resourceFrame:SetSize(RIGHT_W - 18, 22)
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

    -- ── Operator selector: >= / <= / == ──────────────────────────────────
    local operatorFrame = CreateFrame("Frame", nil, f)
    operatorFrame:SetSize(RIGHT_W - 18, 22)
    operatorFrame:SetPoint("TOPLEFT", resourceFrame, "BOTTOMLEFT", 0, -4)
    operatorFrame:Hide()

    local opLabel = operatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opLabel:SetPoint("LEFT", operatorFrame, "LEFT", 0, 0)
    opLabel:SetWidth(60)
    opLabel:SetText("Operator:")
    opLabel:SetTextColor(0.55, 0.72, 0.88, 1)

    local gteBtn = CreateFrame("Button", nil, operatorFrame, "UIPanelButtonTemplate")
    gteBtn:SetSize(56, 22)
    gteBtn:SetPoint("LEFT", opLabel, "RIGHT", 4, 0)
    gteBtn:SetText(">=")

    local lteBtn = CreateFrame("Button", nil, operatorFrame, "UIPanelButtonTemplate")
    lteBtn:SetSize(56, 22)
    lteBtn:SetPoint("LEFT", gteBtn, "RIGHT", 2, 0)
    lteBtn:SetText("<=")

    local eqBtn = CreateFrame("Button", nil, operatorFrame, "UIPanelButtonTemplate")
    eqBtn:SetSize(56, 22)
    eqBtn:SetPoint("LEFT", lteBtn, "RIGHT", 2, 0)
    eqBtn:SetText("==")

    -- ── Plugin / Proc selector ────────────────────────────────────────────
    local pluginFrame = CreateFrame("Frame", nil, f)
    pluginFrame:SetSize(RIGHT_W - 18, 22)
    pluginFrame:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -4)
    pluginFrame:Hide()

    local pluginBtn = CreateFrame("Button", nil, pluginFrame, "UIPanelButtonTemplate")
    pluginBtn:SetSize(RIGHT_W - 18, 22)
    pluginBtn:SetPoint("TOPLEFT", pluginFrame, "TOPLEFT")
    pluginBtn:SetText("Select plugin...")
    pluginBtn:SetScript("OnClick", function()
        ShowPluginPicker(pluginBtn, function(opt)
            selPlugin = opt
            pluginBtn:SetText(opt.label)
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

    local valLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valLbl:SetPoint("TOPLEFT", typeBtn, "BOTTOMLEFT", 0, -6)
    valLbl:SetTextColor(0.55, 0.72, 0.88, 1)
    valLbl:Hide()

    local valBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
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
        HlBtn(gteBtn, mode == ">=")
        HlBtn(lteBtn, mode == "<=")
        HlBtn(eqBtn,  mode == "==")
    end

    chiBtn:SetScript("OnClick",    function() SetResSel("chi")    end)
    energyBtn:SetScript("OnClick", function() SetResSel("energy") end)
    gteBtn:SetScript("OnClick",    function() SetOpSel(">=")      end)
    lteBtn:SetScript("OnClick",    function() SetOpSel("<=")      end)
    eqBtn:SetScript("OnClick",     function() SetOpSel("==")      end)

    -- ── Layout ────────────────────────────────────────────────────────────
    local function UpdateLayout()
        local above = typeBtn
        if selType and selType.needsSpell then
            above = (spellSel == "other") and otherFrame or spellToggleFrame
        elseif selType and selType.needsResource then
            above = operatorFrame
        elseif selType and selType.needsPlugin then
            above = pluginFrame
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
        if condPicker and condPicker:IsShown() then condPicker:Hide(); return end
        ShowCondPicker(typeBtn, function(ct)
            selType = ct
            typeBtn:SetText(ct.label)
            -- Hide all optional sections first
            spellToggleFrame:Hide(); otherFrame:Hide()
            resourceFrame:Hide(); operatorFrame:Hide()
            pluginFrame:Hide()
            valLbl:Hide(); valBox:Hide()
            selPlugin = nil
            if ct.needsSpell then
                spellToggleFrame:Show()
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
    f.GetPlugin       = function() return selPlugin and selPlugin.id or nil end
    f.GetSpell        = function()
        if not selType or not selType.needsSpell then return nil end
        if spellSel == "this" then return "this" end
        return resolvedOtherID  -- number or nil if not yet resolved
    end

    f.Reset = function()
        selType = nil; spellSel = "this"; resSel = "chi"; opSel = ">="
        selPlugin = nil
        resolvedOtherID = nil; resolvedOtherName = nil
        notCheck:SetChecked(false)
        typeBtn:SetText("Select condition type...")
        spellToggleFrame:Hide(); otherFrame:Hide()
        resourceFrame:Hide(); operatorFrame:Hide()
        pluginFrame:Hide(); pluginBtn:SetText("Select plugin...")
        otherNameBox:SetText(""); otherResultLbl:SetText(""); otherIcon:Hide()
        valLbl:Hide(); valBox:SetText(""); valBox:Hide()
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

    return f
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

    local rule = workingRules[selectedIdx]

    if not rule then
        rightPanel.header:SetText("Select a spell to edit conditions")
        rightPanel.addCondBtn:Hide()
        if condInputArea then condInputArea:Hide() end
        return
    end

    rightPanel.header:SetText((rule.name or tostring(rule.spellID or "?"))
                               .. " — Conditions")

    local conds  = rule.conditions or {}
    local yBase  = -28  -- below the header
    local rowIdx = 0

    for i, cond in ipairs(conds) do
        -- AND / OR junction toggle (shown between consecutive conditions)
        if i > 1 then
            local jIdx = i - 1
            if not condJunctionPool[jIdx] then
                local jf = CreateFrame("Button", nil, rightPanel)
                jf:SetSize(44, 14)
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
        row:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 6, yBase)
        row._lbl:SetText(CondSummaryText(cond, rule.spellID))
        row._lbl:SetTextColor(cond.negate and 1 or 0.78, cond.negate and 0.38 or 0.90, cond.negate and 0.38 or 1, 1)
        -- Capture index and condition ref for closures
        local capturedI    = i
        local capturedCond = cond

        local function UpdateLPBtn()
            local n = capturedCond.lparen or 0
            if n == 0 then
                row._lpLbl:SetText("(")
                row._lpLbl:SetTextColor(0.28, 0.36, 0.52, 1)
            else
                row._lpLbl:SetText(string.rep("(", n))
                row._lpLbl:SetTextColor(1.0, 0.88, 0.30, 1)
            end
        end
        local function UpdateRPBtn()
            local n = capturedCond.rparen or 0
            if n == 0 then
                row._rpLbl:SetText(")")
                row._rpLbl:SetTextColor(0.28, 0.36, 0.52, 1)
            else
                row._rpLbl:SetText(string.rep(")", n))
                row._rpLbl:SetTextColor(1.0, 0.88, 0.30, 1)
            end
        end
        UpdateLPBtn()
        UpdateRPBtn()
        row._lpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.lparen = math.max(0, (capturedCond.lparen or 0) - 1)
            else
                capturedCond.lparen = ((capturedCond.lparen or 0) + 1) % 4
            end
            UpdateLPBtn()
            RefreshRuleList()
        end)
        row._rpBtn:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                capturedCond.rparen = math.max(0, (capturedCond.rparen or 0) - 1)
            else
                capturedCond.rparen = ((capturedCond.rparen or 0) + 1) % 4
            end
            UpdateRPBtn()
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

    -- Add Condition button
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
                    newCond.value = condInputArea.GetValue() or 4
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
-- 12. Main GUI frame
-------------------------------------------------------------------------------
local function CreateGUI()
    local f = CreateFrame("Frame", "SBAS_OverrideGUI_Frame", UIParent, "BackdropTemplate")
    f:SetSize(GUI_W, GUI_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    SetBD(f, 0.03, 0.05, 0.09, 0.97, 0.24, 0.44, 0.64)

    table.insert(UISpecialFrames, "SBAS_OverrideGUI_Frame")

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
        if not addSpellPopup then
            addSpellPopup = CreateAddSpellPopup()
        end
        addSpellPopup.onAdd = function(id, name)
            workingRules[#workingRules + 1] = { spellID = id, name = name, conditions = {} }
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
        -- Push into the text editor if it exists, then show it
        local eb = _G["SBAS_OverrideEditBox"]
        local of = _G["SBAS_OverrideFrame"]
        if eb and of then
            eb:SetText(code)
            of:Show()
        else
            print("|cff00ccffSBAS Preview:|r\n" .. code)
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

    guiFrame = f
end

-------------------------------------------------------------------------------
-- 13. Open the GUI
-------------------------------------------------------------------------------
local function OpenGUI(specID)
    if not guiFrame then CreateGUI() end

    editSpecID   = specID or CurrentSpecID()
    local saved  = GetGuiRules(editSpecID)
    workingRules = DeepCopyRules(saved)
    selectedIdx  = (#workingRules > 0) and 1 or 0
    isAddingCond = false

    guiFrame.title:SetText("SBA Override Builder — " .. GetSpecName(editSpecID))
    guiFrame:Show()
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
