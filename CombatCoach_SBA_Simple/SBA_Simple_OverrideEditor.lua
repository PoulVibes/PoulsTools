-- SBA_Simple_OverrideEditor.lua
-- Raw override editor window for SBA_Simple.

local function GetOverrideEditorState()
    _G.SBAS_OverrideEditorState = _G.SBAS_OverrideEditorState or {
        targetSpec = nil,
        targetName = nil,
        previewCode = nil,
        previewMode = false,
    }
    return _G.SBAS_OverrideEditorState
end

local function CreateOverrideFrame()
    local f = CreateFrame("Frame", "SBAS_OverrideFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    local db = SBA_Simple_GetDB()
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
    title:SetText("SBA Simple - Override Logic")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    function f:SavePosition()
        local dbLocal = SBA_Simple_GetDB()
        local left = self:GetLeft()
        local bottom = self:GetBottom()
        if left and bottom then
            dbLocal.x = left
            dbLocal.y = bottom
        end
        dbLocal.width = self:GetWidth()
        dbLocal.height = self:GetHeight()
    end

    f:SetScript("OnMouseDown", function(self)
        self:StartMoving()
        self.isMoving = true
    end)
    f:SetScript("OnMouseUp", function(self)
        if self.isMoving then
            self:StopMovingOrSizing()
            self:SavePosition()
            self.isMoving = false
        end
    end)

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
        local parent = self:GetParent()
        if parent.isSizing then
            parent:StopMovingOrSizing()
            parent:SavePosition()
            parent.isSizing = false
        end
    end)

    table.insert(UISpecialFrames, "SBAS_OverrideFrame")

    local scroll = CreateFrame("ScrollFrame", "SBAS_OverrideScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -44)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 48)
    scroll:EnableMouseWheel(true)

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
    editBox:EnableMouseWheel(true)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self)
        local needed = self:GetNumLines() * 14 + 16
        self:SetHeight(math.max(needed, scroll:GetHeight()))
    end)
    editBox:SetAllPoints()

    scroll:SetScript("OnSizeChanged", function(_, w) editBox:SetWidth(w) end)

    local function ScrollByWheel(delta)
        local v = scroll:GetVerticalScroll()
        local m = scroll:GetVerticalScrollRange()
        scroll:SetVerticalScroll(math.min(math.max(v - delta * 24, 0), m))
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        ScrollByWheel(delta)
    end)
    editBox:SetScript("OnMouseWheel", function(_, delta)
        ScrollByWheel(delta)
    end)

    scroll:HookScript("OnVerticalScroll", function(self, offset)
        local editH = editBox:GetHeight()
        editBox:SetHitRectInsets(0, 0, offset, editH - offset - self:GetHeight())
    end)
    scroll:HookScript("OnScrollRangeChanged", function(self, _, yrange)
        if yrange == 0 then
            editBox:SetHitRectInsets(0, 0, 0, 0)
            return
        end
        local offset = self:GetVerticalScroll()
        local editH = editBox:GetHeight()
        editBox:SetHitRectInsets(0, 0, offset, editH - offset - self:GetHeight())
    end)

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

    f:SetScript("OnShow", function()
        local state = GetOverrideEditorState()
        local dbLocal = SBA_Simple_GetDB()
        if dbLocal.x and dbLocal.y then
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", dbLocal.x, dbLocal.y)
        elseif dbLocal.point then
            f:ClearAllPoints()
            f:SetPoint(dbLocal.point)
        end
        if dbLocal.width and dbLocal.height then
            f:SetSize(dbLocal.width, dbLocal.height)
        end

        local specID = state.targetSpec or SBA_Simple_GetCurrentSpecID()
        local specDB = SBA_Simple_GetSpecDB(specID)
        if state.previewMode and state.previewCode ~= nil then
            editBox:SetText(state.previewCode)
        else
            editBox:SetText(specDB.overrideCode or "")
        end
        scroll:SetVerticalScroll(0)
        editBox:ClearFocus()
        if state.targetName then
            local suffix = state.previewMode and " (Preview)" or ""
            title:SetText("SBA Simple - Override Logic: " .. state.targetName .. suffix)
        else
            local suffix = state.previewMode and " (Preview)" or ""
            title:SetText("SBA Simple - Override Logic" .. suffix)
        end
    end)

    f:SetScript("OnHide", function()
        local state = GetOverrideEditorState()
        state.previewCode = nil
        state.previewMode = false
    end)

    local cursorLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorLabel:SetPoint("BOTTOMLEFT", scroll, "BOTTOMLEFT", 4, -18)
    cursorLabel:SetText("Ln 1, Col 1")

    local function UpdateCursorPos()
        local pos = editBox:GetCursorPosition()
        local text = editBox:GetText()
        local line, col = 1, 1
        for i = 1, pos do
            local c = text:sub(i, i)
            if c == "\n" then
                line = line + 1
                col = 1
            else
                col = col + 1
            end
        end
        cursorLabel:SetText("Ln " .. line .. ", Col " .. col)
    end

    editBox:SetScript("OnCursorChanged", function(self, _, y, _, h)
        UpdateCursorPos()
    end)
    editBox:HookScript("OnTextChanged", UpdateCursorPos)

    local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    btn:SetSize(140, 28)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    btn:SetText("Override Logic")
    btn:SetScript("OnClick", function()
        local state = GetOverrideEditorState()
        local code = editBox:GetText()
        local specID = state.targetSpec or SBA_Simple_GetCurrentSpecID()
        local specDB = SBA_Simple_GetSpecDB(specID)
        specDB.overrideCode = code
        specDB.overrideSource = "code"
        SBA_Simple_GetDB().overrideCode = code

        if code:match("^%s*$") then
            if specID == SBA_Simple_GetCurrentSpecID() then
                SBA_Simple_CompileMainOverride(code)
            end
            print("|cff00ff99SBA_Simple:|r Override cleared for spec " .. tostring(specID))
        else
            local chunk, err = loadstring(code)
            if not chunk then
                print("|cffff4444SBAS compile error:|r " .. tostring(err))
                return
            end
            if specID == SBA_Simple_GetCurrentSpecID() then
                SBA_Simple_CompileMainOverride(code)
            end
            print("|cff00ff99SBA_Simple:|r Override logic saved for spec " .. tostring(specID))
        end

        state.targetSpec = nil
        state.targetName = nil
        state.previewCode = nil
        state.previewMode = false
        f:Hide()
        local analyzerFrame = _G["SBAS_OverrideAnalyzerFrame"]
        if analyzerFrame and analyzerFrame:IsShown() then analyzerFrame:Hide() end
    end)

    return f
end

local overrideFrame = CreateOverrideFrame()

function SBA_Simple_ShowOverrideForSpec(specID, displayName)
    local state = GetOverrideEditorState()
    state.targetSpec = specID
    state.targetName = displayName
    state.previewCode = nil
    state.previewMode = false
    if overrideFrame then overrideFrame:Show() end
end

function SBA_Simple_ShowOverridePreview(code, specID, displayName)
    local state = GetOverrideEditorState()
    state.targetSpec = specID
    state.targetName = displayName
    state.previewCode = code or ""
    state.previewMode = true
    if overrideFrame then overrideFrame:Show() end
end

function SBA_Simple_ToggleOverrideEditor()
    if overrideFrame and overrideFrame:IsShown() then
        overrideFrame:Hide()
    else
        SBA_Simple_ShowOverrideForSpec(nil)
    end
end
