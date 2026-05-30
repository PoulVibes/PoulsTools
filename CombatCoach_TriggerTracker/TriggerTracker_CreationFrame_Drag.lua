-- TriggerTracker_CreationFrame_Drag.lua
-- Drag-and-drop state, helpers, and the spell scroll list widget.

local TT = TriggerTracker
local CF = TT.CF

local ROW_H = 28

-- Drag state (shared with widgets and main frame via CF).
CF.dropTargets = {}

local BORDER_NORMAL = { 0.22, 0.38, 0.58, 0.85 }
local BORDER_GEN    = { 0.3,  1.0,  0.4,  1.0  }
local BORDER_SPEND  = { 1.0,  0.5,  0.1,  1.0  }
local BORDER_BUFF   = { 1.0,  0.85, 0.0,  1.0  }

local dragIcon = nil
CF.dragSpellID   = nil
CF.dragSpellName = nil
CF.dragSpellIcon = nil

local function SetPanelBorder(panel, t)
    if panel and panel.SetBackdropBorderColor then
        panel:SetBackdropBorderColor(t[1], t[2], t[3], t[4])
    end
end

local function EnsureDragIcon()
    if dragIcon then return end
    dragIcon = CreateFrame("Frame", "TT_DragIcon", UIParent)
    dragIcon:SetSize(36, 36)
    dragIcon:SetFrameStrata("TOOLTIP")
    dragIcon:Hide()
    local tex = dragIcon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dragIcon._tex = tex
    local dt = CF.dropTargets
    dragIcon:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
        SetPanelBorder(dt.genPanel,
            dt.genPanel and dt.genPanel:IsMouseOver() and BORDER_GEN or BORDER_NORMAL)
        SetPanelBorder(dt.spendPanel,
            dt.spendPanel and dt.spendPanel:IsMouseOver() and BORDER_SPEND or BORDER_NORMAL)
        SetPanelBorder(dt.buffSlot,
            dt.buffSlot and dt.buffSlot:IsMouseOver() and BORDER_BUFF or BORDER_NORMAL)
    end)
end

local function StartDrag(spellID, name, iconID)
    EnsureDragIcon()
    CF.dragSpellID   = spellID
    CF.dragSpellName = name
    CF.dragSpellIcon = iconID
    dragIcon._tex:SetTexture(iconID)
    dragIcon:Show()
end

local function EndDrag()
    if dragIcon then dragIcon:Hide() end
    local dt = CF.dropTargets
    SetPanelBorder(dt.genPanel,   BORDER_NORMAL)
    SetPanelBorder(dt.spendPanel, BORDER_NORMAL)
    SetPanelBorder(dt.buffSlot,   BORDER_NORMAL)
    CF.dragSpellID   = nil
    CF.dragSpellName = nil
    CF.dragSpellIcon = nil
end

-- Store on CF so widgets/main frame can call them.
CF.StartDrag = StartDrag
CF.EndDrag   = EndDrag

-- Creates a scroll list. onDispatch(spellID, name, iconID) called on click or drop.
CF.CreateScrollList = function(parent, w, h, onDispatch)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetSize(w, h)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - d * ROW_H, 0), m))
    end)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(w, h)
    sf:SetScrollChild(content)

    local rows = {}

    local function Rebuild(spellList, filterText)
        for _, r in ipairs(rows) do r:Hide() end
        rows = {}
        local y = 0
        local lowerFilter = filterText and filterText:match("^%s*(.-)%s*$"):lower() or ""
        for _, entry in ipairs(spellList) do
            local show = lowerFilter == "" or entry.name:lower():find(lowerFilter, 1, true)
            if show then
                local r = CreateFrame("Button", nil, content)
                r:SetSize(w - 4, ROW_H - 2)
                r:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -y)
                r._spellID = entry.spellID
                r._iconID  = entry.iconID
                r._name    = entry.name
                r:RegisterForDrag("LeftButton")

                local bg = r:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0, 0, 0, 0)
                r._bg = bg

                local iconTex = r:CreateTexture(nil, "ARTWORK")
                iconTex:SetSize(ROW_H - 4, ROW_H - 4)
                iconTex:SetPoint("LEFT", r, "LEFT", 2, 0)
                iconTex:SetTexture(entry.iconID)
                iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                lbl:SetPoint("LEFT", iconTex, "RIGHT", 4, 0)
                lbl:SetPoint("RIGHT", r, "RIGHT", -2, 0)
                lbl:SetJustifyH("LEFT")
                lbl:SetText(entry.name)

                r:SetScript("OnEnter", function(self)
                    self._bg:SetColorTexture(0.16, 0.28, 0.48, 0.70)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(self._spellID)
                    GameTooltip:Show()
                end)
                r:SetScript("OnLeave", function(self)
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    GameTooltip:Hide()
                end)
                r:SetScript("OnClick", function(self)
                    if onDispatch then onDispatch(self._spellID, self._name, self._iconID) end
                end)
                r:SetScript("OnDragStart", function(self)
                    StartDrag(self._spellID, self._name, self._iconID)
                end)
                r:SetScript("OnDragStop", function()
                    if CF.dragSpellID then
                        local sid, sn, si = CF.dragSpellID, CF.dragSpellName, CF.dragSpellIcon
                        EndDrag()
                        local dt = CF.dropTargets
                        if dt.genPanel and dt.genPanel:IsMouseOver() then
                            dt.genPanel:AddSpell(sid, sn, si)
                        elseif dt.spendPanel and dt.spendPanel:IsMouseOver() then
                            dt.spendPanel:AddSpell(sid, sn, si)
                        elseif dt.buffSlot and dt.buffSlot:IsMouseOver() then
                            if dt.onBuffDrop then dt.onBuffDrop(sid, sn, si) end
                        end
                    else
                        EndDrag()
                    end
                end)
                table.insert(rows, r)
                y = y + ROW_H
            end
        end
        content:SetHeight(math.max(h, y))
    end

    sf._content = content
    sf.Rebuild  = Rebuild
    return sf
end
