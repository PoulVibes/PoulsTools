-- SBA_Simple_OverrideGUI_Core_RuleRows.lua
-- Rule row frame creation/update/refresh helpers.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

local function GetDynBuffWarning(rule)
    local untracked = {}
    for _, cond in ipairs(rule.conditions or {}) do
        if cond.type == "plugin" and type(cond.plugin) == "string"
                and cond.plugin:match("^dynbuff_") then
            if not (_G.SBAS_DynBuffRegistry and _G.SBAS_DynBuffRegistry[cond.plugin]) then
                local spellID = tonumber(cond.plugin:match("^dynbuff_%d+_(%d+)$"))
                local si = spellID and C_Spell and C_Spell.GetSpellInfo
                           and C_Spell.GetSpellInfo(spellID)
                untracked[#untracked + 1] = (si and si.name)
                                            or ("spell " .. tostring(spellID or "?"))
            end
        end
    end
    if #untracked == 0 then return nil end
    local list = table.concat(untracked, ", ")
    return list .. " is not being tracked by Dynamic Buff Tracker."
        .. "\n\nOpen Blizzard's Cooldown Manager with |cffffd700/cdm|r, add the spell to its Tracked Buff Icons, trigger the Buff at least once"
        .. "then run |cffffd700/dbt scan|r to register it."
end

function M.CreateRowFrame(parent, deps)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(deps.getLeftPanelWidth() - deps.PAD * 2, deps.ROW_H - 4)
    deps.SetBD(f, 0.06, 0.10, 0.16, 0.88, 0.14, 0.24, 0.40)
    f:EnableMouse(true)

    f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.badge:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -4)
    f.badge:SetSize(26, 20)
    f.badge:SetJustifyH("CENTER")
    f.badge:SetTextColor(0.4, 0.62, 0.90, 1)

    local iconBg = f:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(36, 36)
    iconBg:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -4)
    iconBg:SetColorTexture(0, 0, 0, 0.5)

    f.iconTex = f:CreateTexture(nil, "ARTWORK")
    f.iconTex:SetSize(34, 34)
    f.iconTex:SetPoint("CENTER", iconBg, "CENTER")
    f.iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.nameLabel:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 6, 0)
    f.nameLabel:SetSize(deps.LEFT_W - 186, 18)
    f.nameLabel:SetJustifyH("LEFT")
    f.nameLabel:SetTextColor(0.9, 0.95, 1, 1)

    f.idLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.idLabel:SetPoint("TOPLEFT", f.nameLabel, "BOTTOMLEFT", 0, -1)
    f.idLabel:SetTextColor(0.48, 0.60, 0.75, 1)

    f.condLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.condLabel:SetPoint("TOPLEFT", f.idLabel, "BOTTOMLEFT", 0, -4)
    f.condLabel:SetWidth(deps.LEFT_W - 130)
    f.condLabel:SetJustifyH("LEFT")
    f.condLabel:SetWordWrap(true)
    f.condLabel:SetTextColor(0.50, 0.72, 0.55, 1)

    f.removeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.removeBtn:SetSize(20, 20)
    f.removeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    f:SetScript("OnMouseDown", function(self, mouseBtn)
        if mouseBtn ~= "LeftButton" or not self._idx then return end
        deps.setSelectedIdx(self._idx)
        deps.setIsAddingCond(false)
        deps.refreshRuleList()
        deps.refreshRightPanel()
        deps.ensureDragIcon()
        deps.ensureDragCatcher()

        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        deps.ruleDrag.pending = true
        deps.ruleDrag.fromIdx = self._idx
        deps.ruleDrag.pendingX = cx / s
        deps.ruleDrag.pendingY = cy / s

        local rule = deps.getWorkingRules()[self._idx]
        local dragIconFrame = deps.getDragIconFrame()
        if rule and dragIconFrame then
            local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                         and C_Spell.GetSpellInfo(rule.spellID)
            local iconID = info and info.originalIconID
            dragIconFrame._tex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local dragCatcher = deps.getDragCatcher()
        if dragCatcher then
            dragCatcher:EnableMouse(false)
            dragCatcher:Show()
        end
    end)

    f:SetScript("OnMouseUp", function(_, mouseBtn)
        if mouseBtn == "LeftButton" and deps.ruleDrag.pending then
            deps.ruleDrag.pending = false
            deps.ruleDrag.fromIdx = nil
            local dragCatcher = deps.getDragCatcher()
            if dragCatcher then dragCatcher:Hide() end
        end
    end)

    f:SetScript("OnEnter", function(self)
        if self._idx ~= deps.getSelectedIdx() then
            f:SetBackdropColor(0.10, 0.16, 0.26, 0.88)
        end
    end)

    f:SetScript("OnLeave", function(self)
        if self._idx ~= deps.getSelectedIdx() then
            f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        end
    end)

    f.warnIcon = CreateFrame("Frame", nil, f)
    f.warnIcon:SetSize(18, 18)
    f.warnIcon:SetPoint("TOPRIGHT", f.removeBtn, "TOPLEFT", -2, 0)
    f.warnIcon:EnableMouse(true)
    local warnTex = f.warnIcon:CreateTexture(nil, "OVERLAY")
    warnTex:SetAllPoints()
    warnTex:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertOther")
    f.warnIcon:SetScript("OnEnter", function(self)
        if not self._tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self._title or "|cffff9900Condition Warning|r", 1, 1, 1, 1, true)
        GameTooltip:AddLine(self._tooltip, 1, 0.85, 0.55, true)
        GameTooltip:Show()
    end)
    f.warnIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.warnIcon:Hide()

    return f
end

function M.UpdateRowFrame(f, idx, rule, deps)
    local leftW = deps.getLeftPanelWidth()
    f._idx = idx
    f.badge:SetText(tostring(idx))

    local info = rule.spellID and C_Spell and C_Spell.GetSpellInfo
                 and C_Spell.GetSpellInfo(rule.spellID)
    local iconID = info and info.originalIconID
    if rule.itemID then
        local itemIcon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(rule.itemID)
        if itemIcon then iconID = itemIcon end
    end
    local dispName = (info and info.name) or rule.name or "Unknown"
    if rule.itemID and rule.name then
        dispName = rule.name
    end
    f.iconTex:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    f.nameLabel:SetText(dispName)
    f.nameLabel:SetWidth(math.max(120, leftW - 186))
    f.idLabel:SetText("ID: " .. tostring(rule.spellID or 0))

    local condCount = #(rule.conditions or {})
    if condCount == 0 then
        f.condLabel:SetWidth(math.max(120, leftW - 130))
        f.condLabel:SetText("|cffff9944No conditions - unconditional return|r")
    else
        local tokens = {}
        local depth = 0
        for i = 1, condCount do
            local cond = rule.conditions[i] or {}
            local def = deps.COND_BY_ID[cond.type]
            if def then
                local junction = ""
                if i > 1 then
                    local j = cond.junction or "and"
                    junction = "|cff8899cc" .. j:upper() .. "|r "
                end
                local lp, rp = "", ""
                local depthBefore = depth
                for k = 1, (cond.lparen or 0) do
                    local d = depthBefore + k
                    lp = lp .. deps.ParenColorCode(d) .. "(" .. "|r"
                end
                depth = depth + (cond.lparen or 0)
                for k = 1, (cond.rparen or 0) do
                    local d = depth - (k - 1)
                    rp = rp .. deps.ParenColorCode(d) .. ")" .. "|r"
                end
                depth = depth - (cond.rparen or 0)

                local label = def.shortLabel or def.label
                if def.needsSpell then
                    if cond.type == "sba_suggests" then
                        if not cond.spell or cond.spell == "this" then
                            label = "SBA =" .. (iconID and (" |T" .. iconID .. ":14:14|t") or " [this]")
                        else
                            local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                            local sInfo = sid and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                            local sIcon = sInfo and sInfo.iconID
                            label = sIcon and ("SBA = |T" .. sIcon .. ":14:14|t") or ("SBA = [" .. tostring(sid or "?") .. "]")
                        end
                    elseif not cond.spell or cond.spell == "this" then
                        if iconID then label = label .. " |T" .. iconID .. ":14:14|t" end
                    else
                        local sid = type(cond.spell) == "number" and cond.spell or cond.targetID
                        if sid then
                            local sInfo = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
                            local sIcon = sInfo and sInfo.iconID
                            label = sIcon and (label .. " |T" .. sIcon .. ":14:14|t") or (label .. " [" .. tostring(sid) .. "]")
                        end
                    end
                elseif def.needsPlugin then
                    label = deps.BuildPluginSummary(cond)
                elseif def.needsLua then
                    local expr = (cond.luaCode and cond.luaCode:gsub("%s+", " "):match("^%s*(.-)%s*$")) or ""
                    if expr == "" then expr = "(empty)" end
                    if #expr > 30 then expr = expr:sub(1, 27) .. "..." end
                    label = "Lua: " .. expr
                elseif def.needsResource then
                    local sec = deps.SPEC_SECONDARY[deps.getEditSpecID()] or deps.SPEC_SECONDARY_DEFAULT
                    local resName = (cond.resource == "energy") and "Energy" or sec.label
                    label = resName .. " " .. (cond.operator or ">=") .. " " .. tostring(cond.value or 0)
                elseif def.needsCompareValue then
                    label = (def.shortLabel or def.label) .. " " .. (cond.operator or ">=") .. " " .. tostring(cond.value or 0)
                end

                if def.needsStacksValue then
                    local v = cond.value
                    local vStr = (v == "max") and "Max" or tostring(v or "?")
                    label = vStr .. " " .. label
                end

                local labelText = cond.negate and ("|cffff4444NOT " .. label .. "|r") or label
                tokens[#tokens + 1] = junction .. lp .. labelText .. rp
            end
        end

        f.condLabel:SetWidth(math.max(120, leftW - 130))
        f.condLabel:SetText(table.concat(tokens, " "))
    end

    local textH = f.condLabel:GetStringHeight()
    local rowFrameH = math.max(deps.ROW_H - 4, 44 + textH + 10)
    f._rowH = rowFrameH + 4
    f:SetSize(leftW - deps.PAD * 2, rowFrameH)
    f:Show()

    local hasMismatch = deps.HasParenMismatch(rule.conditions)
    local dynBuffWarn = GetDynBuffWarning(rule)
    local anyWarn = dynBuffWarn ~= nil

    if f.warnIcon then
        if anyWarn then
            f.warnIcon._title = "|cffff9900Dynamic Buff Tracker Warning|r"
            f.warnIcon._tooltip = dynBuffWarn
            f.warnIcon:Show()
        else
            f.warnIcon._title = nil
            f.warnIcon._tooltip = nil
            f.warnIcon:Hide()
        end
    end

    if hasMismatch then
        f:SetBackdropColor(0.30, 0.04, 0.04, 0.95)
        f:SetBackdropBorderColor(0.90, 0.18, 0.18, 1)
    elseif anyWarn then
        if idx == deps.getSelectedIdx() then
            f:SetBackdropColor(0.28, 0.12, 0.00, 0.95)
            f:SetBackdropBorderColor(0.90, 0.50, 0.10, 1)
        else
            f:SetBackdropColor(0.22, 0.09, 0.00, 0.90)
            f:SetBackdropBorderColor(0.75, 0.38, 0.08, 1)
        end
    elseif idx == deps.getSelectedIdx() then
        f:SetBackdropColor(0.08, 0.20, 0.36, 0.95)
        f:SetBackdropBorderColor(0.28, 0.58, 0.90, 1)
    else
        f:SetBackdropColor(0.06, 0.10, 0.16, 0.88)
        f:SetBackdropBorderColor(0.14, 0.24, 0.40, 1)
    end

    f.removeBtn:SetScript("OnClick", function()
        local rules = deps.getWorkingRules()
        table.remove(rules, idx)
        if deps.getSelectedIdx() == idx then
            deps.setSelectedIdx(math.min(idx, #rules))
        elseif deps.getSelectedIdx() > idx then
            deps.setSelectedIdx(deps.getSelectedIdx() - 1)
        end
        deps.setIsAddingCond(false)
        deps.refreshRuleList()
        deps.refreshRightPanel()
    end)
end

