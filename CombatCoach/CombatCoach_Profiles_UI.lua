-- CombatCoach_Profiles_UI.lua
-- Dialog frame builders for profile export and import.

local CC       = CombatCoach
local Profiles = CombatCoach.Profiles

-- Shared dialog frame factory.
local function makeDialogFrame(globalName, w, h)
    local f = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    f:SetBackdropColor(0.04, 0.08, 0.15, 0.98)

    -- Header bar
    local hdr = f:CreateTexture(nil, "ARTWORK")
    hdr:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -10)
    hdr:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    hdr:SetHeight(36)
    hdr:SetColorTexture(0.06, 0.12, 0.22, 1.0)

    -- Cyan accent line under header
    local accent = f:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("BOTTOMLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    accent:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetColorTexture(0.0, 0.8, 1.0, 1.0)

    -- X close button (top-right)
    local xBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    xBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    xBtn:SetScript("OnClick", function() f:Hide() end)

    return f, hdr
end

-- Shared scroll-frame + multiline edit box
local function makeScrollEditBox(parent, l, t, r, b)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     parent, "TOPLEFT",     l,  t)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", r,  b)

    local edit = CreateFrame("EditBox", nil, scroll)
    -- width: frame(520) - left(10) - right(26) - scrollbar(~18) ≈ 462
    edit:SetWidth(462)
    edit:SetHeight(1200)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetMaxLetters(0)   -- unlimited characters
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)

    return scroll, edit
end

-- ============================================================
-- Export Frame (lazy-created on first use)
-- ============================================================
function Profiles:GetExportFrame()
    if self._exportFrame then return self._exportFrame end

    local f, hdr = makeDialogFrame("CombatCoachExportFrame", 520, 420)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hdr, "LEFT", 10, 0)
    title:SetText("|cFF00CCFFExport Spec Profile|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- Instructions
    local instr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instr:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 2, -8)
    instr:SetText("Click |cFFFFFF44Select All|r then press |cFFFFFF44Ctrl+C|r to copy.")
    instr:SetTextColor(0.75, 0.85, 0.95, 1.0)

    -- "Contains:" info line
    local infoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoLabel:SetPoint("TOPLEFT", instr, "BOTTOMLEFT", 0, -2)
    infoLabel:SetWidth(460)
    infoLabel:SetJustifyH("LEFT")
    infoLabel:SetTextColor(0.5, 0.65, 0.8, 1.0)
    f.infoLabel = infoLabel

    -- Scroll + edit box  (top offset -88 leaves room for header + instructions)
    local _, edit = makeScrollEditBox(f, 10, -88, -26, 44)
    f.editBox = edit

    -- "Select All" button
    local selBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
    selBtn:SetSize(120, 24)
    selBtn:SetText("Select All")
    selBtn:SetScript("OnClick", function()
        edit:SetFocus()
        edit:HighlightText()
    end)

    -- "Close" button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
    closeBtn:SetSize(80, 24)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    self._exportFrame = f
    return f
end

function Profiles:ShowExportFrame()
    local f = self:GetExportFrame()
    local str, payload, specID, specName = self:SerializeSpec()
    if not str then
        print("|cFFFF4444CombatCoach Profiles:|r " .. tostring(payload))
        return
    end
    f.editBox:SetText(str)
    f.editBox:HighlightText()
    if f.infoLabel then
        local specLabel = specName and (specName .. " (" .. specID .. ")") or tostring(specID)
        f.infoLabel:SetText("Spec: " .. specLabel .. "  |  " .. table.concat(payload, ", "))
    end
    f:Show()
    f.editBox:SetFocus()
end

-- ============================================================
-- Import Frame (lazy-created on first use)
-- ============================================================
function Profiles:GetImportFrame()
    if self._importFrame then return self._importFrame end

    local f, hdr = makeDialogFrame("CombatCoachImportFrame", 520, 420)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", hdr, "LEFT", 10, 0)
    title:SetText("|cFF00CCFFImport Spec Profile|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- Instructions
    local instr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instr:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 2, -8)
    instr:SetText("Paste an exported profile string below, then click |cFFFFFF44Import|r.")
    instr:SetTextColor(0.75, 0.85, 0.95, 1.0)

    -- Status / error line
    local statusLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("TOPLEFT", instr, "BOTTOMLEFT", 0, -2)
    statusLabel:SetWidth(460)
    statusLabel:SetJustifyH("LEFT")
    f.statusLabel = statusLabel

    -- Scroll + edit box
    local _, edit = makeScrollEditBox(f, 10, -88, -26, 44)
    f.editBox = edit

    -- "Import" button
    local impBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    impBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
    impBtn:SetSize(100, 24)
    impBtn:SetText("Import")
    impBtn:SetScript("OnClick", function()
        local raw = edit:GetText()
        if not raw or raw:find("^%s*$") then
            f.statusLabel:SetText("|cFFFF4444Please paste a profile string first.|r")
            return
        end
        local data, err = Profiles:Deserialize(raw)
        if not data then
            f.statusLabel:SetText("|cFFFF4444" .. tostring(err) .. "|r")
            return
        end
        local applied = Profiles:Apply(data)
        if #applied == 0 then
            f.statusLabel:SetText("|cFFFF4444No matching addon data found in the profile.|r")
            return
        end
        f:Hide()
        StaticPopup_Show("CombatCoach_PROFILE_RELOAD", table.concat(applied, ", "))
    end)

    -- "Cancel" button
    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
    cancelBtn:SetSize(80, 24)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    self._importFrame = f
    return f
end

function Profiles:ShowImportFrame()
    local f = self:GetImportFrame()
    f.editBox:SetText("")
    f.statusLabel:SetText("")
    f:Show()
    f.editBox:SetFocus()
end
