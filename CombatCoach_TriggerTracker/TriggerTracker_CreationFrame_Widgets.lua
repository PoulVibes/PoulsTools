-- TriggerTracker_CreationFrame_Widgets.lua
-- Inline dropdown and spell drop-panel widgets for the creation frame.

local TT = TriggerTracker
local CF = TT.CF
local SetBD = CF.SetBD

local ROW_H = 28

-- Simple inline dropdown.
-- opts = { {l="label", v=value}, ... }
CF.CreateMinidropdown = function(parent, opts, defaultIdx, onChange, w)
    w = w or 100
    local dd = CreateFrame("Frame", nil, parent)
    dd:SetSize(w, 22)
    local btn = CreateFrame("Button", nil, dd, "UIPanelButtonTemplate")
    btn:SetAllPoints(dd)
    local cur = defaultIdx or 1
    dd.value = opts[cur].v
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(w, #opts * 20 + 4)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetToplevel(true)
    popup:Hide()
    SetBD(popup, 0.04, 0.06, 0.12, 0.97, 0.28, 0.48, 0.68)
    local function SetIdx(i)
        cur = i; dd.value = opts[i].v
        btn:SetText(opts[i].l .. " \226\150\190")
        if onChange then onChange(opts[i].v) end
    end
    for i, opt in ipairs(opts) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(w - 4, 20)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2 - (i-1)*20)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0,0,0,0)
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetText(opt.l)
        local ci = i
        row:SetScript("OnEnter", function() bg:SetColorTexture(0.2, 0.4, 0.7, 0.8) end)
        row:SetScript("OnLeave", function() bg:SetColorTexture(0, 0, 0, 0) end)
        row:SetScript("OnClick", function() SetIdx(ci); popup:Hide() end)
    end
    btn:SetScript("OnClick", function(self)
        if popup:IsShown() then popup:Hide() return end
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        popup:Show()
    end)
    SetIdx(cur)
    function dd:SetValue(v)
        for i, opt in ipairs(opts) do
            if opt.v == v then SetIdx(i) return end
        end
    end
    return dd
end

-- Spell drop-target panel (generators / spenders).
-- onDrop(spellID, name, iconID) called when a drag is released over the panel.
-- amountOpts: optional {l,v}[] — each row shows a ×N click-to-cycle button.
CF.CreateDropPanel = function(parent, label, w, h, tooltipText, onDrop, amountOpts)
    local dt = CF.dropTargets
    local EndDrag = CF.EndDrag

    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(w, h)
    SetBD(panel, 0.04, 0.07, 0.14, 0.92, 0.22, 0.38, 0.58)
    panel:EnableMouse(true)

    panel:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" and CF.dragSpellID and onDrop then
            onDrop(CF.dragSpellID, CF.dragSpellName, CF.dragSpellIcon)
            EndDrag()
        end
    end)

    local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -6)
    hdr:SetText(label:upper())
    hdr:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hdr:SetTextColor(0.4, 0.65, 0.85, 1)

    local sf = CreateFrame("ScrollFrame", nil, panel)
    sf:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -4)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * ROW_H, 0), m))
    end)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(w - 8, h - 30)
    sf:SetScrollChild(content)

    local entries = {}
    local entryRows = {}

    local function Refresh()
        for _, r in ipairs(entryRows) do r:Hide() end
        entryRows = {}
        local y = 0
        for i, e in ipairs(entries) do
            local r = CreateFrame("Frame", nil, content)
            r:SetSize(w - 12, ROW_H - 2)
            r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)

            local bg = r:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.08, 0.12, 0.20, 0.4)

            local iconTex = r:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(ROW_H - 4, ROW_H - 4)
            iconTex:SetPoint("LEFT", r, "LEFT", 2, 0)
            iconTex:SetTexture(e.iconID or 134400)
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT", iconTex, "RIGHT", 4, 0)
            lbl:SetPoint("RIGHT", r, "RIGHT", amountOpts and -48 or -24, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetText(e.name)

            local xBtn = CreateFrame("Button", nil, r, "UIPanelCloseButton")
            xBtn:SetSize(16, 16)
            xBtn:SetPoint("RIGHT", r, "RIGHT", -2, 0)
            local idx = i
            xBtn:SetScript("OnClick", function()
                table.remove(entries, idx)
                Refresh()
            end)
            if amountOpts then
                local amtBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
                amtBtn:SetSize(28, 16)
                amtBtn:SetPoint("RIGHT", xBtn, "LEFT", -2, 0)
                local maxAmt = #amountOpts
                amtBtn:SetText("\195\151" .. tostring(e.amount or 1))
                local ei = i
                amtBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                amtBtn:SetScript("OnClick", function(self, btn)
                    local cur = tonumber(entries[ei].amount) or 1
                    if btn == "LeftButton" then
                        cur = (cur % maxAmt) + 1
                    else
                        cur = ((cur - 2 + maxAmt) % maxAmt) + 1
                    end
                    entries[ei].amount = cur
                    self:SetText("\195\151" .. cur)
                end)
                amtBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Stacks per cast", 0.7, 0.9, 1)
                    GameTooltip:AddLine("Left-click: +1   Right-click: -1", 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end)
                amtBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            table.insert(entryRows, r)
            y = y + ROW_H
        end
        content:SetHeight(math.max(h - 30, y))
    end

    function panel:AddSpell(spellID, name, iconID, defaultAmt)
        for _, e in ipairs(entries) do
            if e.spellID == spellID then return end
        end
        table.insert(entries, { spellID = spellID, name = name or "Unknown", iconID = iconID or 134400, amount = defaultAmt or 1 })
        Refresh()
    end

    function panel:GetEntries()
        return entries
    end

    function panel:Clear()
        entries = {}
        Refresh()
    end

    function panel:LoadFromSet(spellSet)
        entries = {}
        if not spellSet then Refresh() return end
        for spellID, amt in pairs(spellSet) do
            local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            if si then
                table.insert(entries, {
                    spellID = spellID,
                    name    = si.name or tostring(spellID),
                    iconID  = si.iconID or 134400,
                    amount  = (amt == true) and 1 or (tonumber(amt) or 1),
                })
            end
        end
        table.sort(entries, function(a, b) return a.name < b.name end)
        Refresh()
    end

    if tooltipText then
        panel:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 0.7, 0.9, 1)
            GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        panel:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return panel
end
