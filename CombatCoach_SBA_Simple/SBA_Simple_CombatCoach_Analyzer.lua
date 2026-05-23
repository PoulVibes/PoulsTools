-- SBA_Simple_CombatCoach_Analyzer.lua
-- Override Priority Analyzer window.

SBA_SimpleDB = SBA_SimpleDB or {}

local analyzerFrame = nil

local function CreateOverrideAnalyzerWindow(specID, specName)
    local PAD         = 10
    local ROW_H       = 24
    local WIN_W_DEF   = 420
    local ICON_SIZE   = 16
    local MAX_VIS_ROWS = 12
    local COND_OFFSET = 138
    local HEADER_H = 30
    local GRIP_H   = 20

    local f = CreateFrame("Frame", "SBAS_OverrideAnalyzerFrame", UIParent, "BackdropTemplate")
    f:Hide()
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(260, 80)
    f:EnableMouse(true)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
    end

    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(20)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)
    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleTxt:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    titleTxt:SetText("Priority Analyzer - " .. (specName or ""))

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f:EnableKeyboard(true)
    if not InCombatLockdown() then
        f:SetPropagateKeyboardInput(true)
    end
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)

    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    resizeGrip:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)

    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     PAD, -(HEADER_H + PAD))
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, GRIP_H)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - delta * ROW_H, 0), m))
    end)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(WIN_W_DEF - PAD * 2)
    sc:SetHeight(100)
    sf:SetScrollChild(sc)

    local function TruncateCond(fs, text, maxW)
        fs:SetText(text)
        if fs:GetStringWidth() <= maxW then return end
        local lo, hi = 0, #text
        while lo < hi do
            local mid = math.floor((lo + hi + 1) / 2)
            fs:SetText(text:sub(1, mid) .. "...")
            if fs:GetStringWidth() > maxW then
                hi = mid - 1
            else
                lo = mid
            end
        end
        fs:SetText(lo > 0 and text:sub(1, lo) .. "..." or "...")
    end

    local function CondMaxW()
        return math.max(0, f:GetWidth() - PAD * 2 - COND_OFFSET - 4)
    end

    local rows = {}

    local function BuildRows(rules, positionReset)
        for _, r in ipairs(rows) do r.frame:Hide() end
        rows = {}

        local count    = #rules
        local visCount = math.min(count, MAX_VIS_ROWS)
        local winH = HEADER_H + PAD + visCount * ROW_H + PAD + GRIP_H

        if positionReset then
            f:SetSize(WIN_W_DEF, winH)
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
        else
            local curW = f:GetWidth()
            f:SetSize(curW > 0 and curW or WIN_W_DEF, winH)
        end

        local scW = math.max(1, f:GetWidth() - PAD * 2)
        sc:SetWidth(scW)
        sc:SetHeight(math.max(count * ROW_H, 1))
        sf:SetVerticalScroll(0)

        local maxW = CondMaxW()

        for i, rule in ipairs(rules) do
            local row = CreateFrame("Frame", nil, sc)
            row:SetHeight(ROW_H)
            row:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, -(i - 1) * ROW_H)
            row:SetWidth(scW)

            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints(row)
            hl:SetColorTexture(1, 0.85, 0, 0.18)
            hl:Hide()

            local iconFrame = CreateFrame("Frame", nil, row)
            iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
            iconFrame:SetPoint("LEFT", row, "LEFT", 0, 0)
            local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints(iconFrame)
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            if rule.spellID then
                local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(rule.spellID)
                local texID = info and (info.iconID or info.originalIconID)
                if texID then iconTex:SetTexture(texID) end
            end

            local priTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            priTxt:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
            priTxt:SetWidth(22)
            priTxt:SetText(i .. ".")
            priTxt:SetTextColor(0.7, 0.7, 0.7)

            local spellName = (rule.name and rule.name ~= "") and rule.name
                or (rule.spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(rule.spellID))
                or "?"
            local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameTxt:SetPoint("LEFT", priTxt, "RIGHT", 2, 0)
            nameTxt:SetWidth(90)
            nameTxt:SetText(spellName)
            nameTxt:SetJustifyH("LEFT")

            local condParts = {}
            if rule.conditions then
                local depth = 0
                for ci, cond in ipairs(rule.conditions) do
                    local tok
                    if type(_G.SBAS_BuildCondRowText) == "function" then
                        tok, depth = _G.SBAS_BuildCondRowText(cond, rule.spellID, ci == 1, depth)
                    else
                        local s = type(_G.SBAS_CondSummaryText) == "function"
                            and _G.SBAS_CondSummaryText(cond, rule.spellID, specID)
                            or (cond.type or "?")
                        if ci > 1 then s = (cond.junction or "AND"):upper() .. " " .. s end
                        tok = s
                    end
                    condParts[#condParts + 1] = tok
                end
            end
            local fullCond = #condParts > 0 and table.concat(condParts, " ") or "(no conditions)"

            local condTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            condTxt:SetPoint("LEFT", row, "LEFT", COND_OFFSET, 0)
            condTxt:SetWidth(maxW)
            condTxt:SetWordWrap(false)
            condTxt:SetNonSpaceWrap(false)
            condTxt:SetJustifyH("LEFT")
            condTxt:SetTextColor(0.6, 0.8, 1)
            TruncateCond(condTxt, fullCond, maxW)

            rows[i] = { frame = row, highlight = hl, spellID = rule.spellID, condTxt = condTxt, condFull = fullCond }
        end
    end

    f:SetScript("OnSizeChanged", function()
        local scW  = math.max(1, f:GetWidth() - PAD * 2)
        sc:SetWidth(scW)
        local maxW = CondMaxW()
        for _, r in ipairs(rows) do
            if r.frame then r.frame:SetWidth(scW) end
            if r.condTxt and r.condFull then
                r.condTxt:SetWidth(maxW)
                TruncateCond(r.condTxt, r.condFull, maxW)
            end
        end
    end)

    local ticker = CreateFrame("Frame", nil, f)
    ticker:SetAllPoints(f)
    ticker:SetScript("OnUpdate", function()
        if not f:IsShown() then return end
        local activePri = type(SBA_Simple_GetLastOverridePriority) == "function"
            and SBA_Simple_GetLastOverridePriority()
        if activePri then
            for i, r in ipairs(rows) do
                if i == activePri then
                    r.highlight:Show()
                else
                    r.highlight:Hide()
                end
            end
        else
            local suggested = C_AssistedCombat and C_AssistedCombat.GetNextCastSpell
                and C_AssistedCombat.GetNextCastSpell()
            for _, r in ipairs(rows) do
                if suggested and r.spellID == suggested then
                    r.highlight:Show()
                else
                    r.highlight:Hide()
                end
            end
        end
    end)

    f.Refresh = function(sid, sname)
        specID   = sid   or specID
        specName = sname or specName
        titleTxt:SetText("Priority Analyzer - " .. (specName or ""))
        local db    = SBA_SimpleDB
        local rules = db and db.gui and db.gui[specID] or {}
        BuildRows(rules, false)
    end

    f:SetScript("OnShow", function()
        local db    = SBA_SimpleDB
        local rules = db and db.gui and db.gui[specID] or {}
        BuildRows(rules, true)
    end)

    return f
end

function SBAS_OpenOrRefreshAnalyzer(specID, specName)
    if not analyzerFrame then
        analyzerFrame = CreateOverrideAnalyzerWindow(specID, specName)
        analyzerFrame:Show()
    else
        analyzerFrame.Refresh(specID, specName)
        if not analyzerFrame:IsShown() then
            analyzerFrame:Show()
        end
    end
end
