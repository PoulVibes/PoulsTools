-- EnemyCountTracker_DebuffOverlay.lua
-- Shows spellID text and a cooldown swipe per ECT unit frame when a DBT-tracked
-- debuff is present. Nameplate tokens are resolved at query time to handle
-- nameplate reassignment during combat.

local instanceToSpell = {}   -- [instanceID] = spellID

local function IsOverlayEnabled()
    local DBT = _G.DynamicBuffTracker
    if not DBT or DBT.currentSpecID == 0 then return false end
    return DynamicBuffTracker_GetSpecEctOverlay(DBT.currentSpecID)
end

-- ---------------------------------------------------------------------------
-- Snapshot DBT: register new instanceIDs
-- ---------------------------------------------------------------------------

local function SnapshotDBT()
    local DBT = _G.DynamicBuffTracker
    if not DBT or not DBT.cdmSpellToFrame then return end
    for spellID, child in pairs(DBT.cdmSpellToFrame) do
        if child and child.auraInstanceID then
            local id = child.auraInstanceID
            if not instanceToSpell[id] then
                instanceToSpell[id] = spellID
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Scan all visible nameplates for a given instanceID
-- ---------------------------------------------------------------------------

local function FindUnitForInstance(instanceID)
    local tracked = _G.ECT_TrackedUnits
    if tracked then
        for unit in pairs(tracked) do
            local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, instanceID)
            if ok and ad then
                return unit
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Prune: remove any instanceID not found on any visible nameplate
-- ---------------------------------------------------------------------------

local function PruneExpired()
    local dirty = false
    for id in pairs(instanceToSpell) do
        if not FindUnitForInstance(id) then
            instanceToSpell[id] = nil
            dirty = true
        end
    end
    return dirty
end

-- ---------------------------------------------------------------------------
-- Slot system: slot 1 renders on the frame itself; slot 2+ stack below.
-- ---------------------------------------------------------------------------

local SLOT_GAP = 2

local function GetOrCreateSlot(f, idx)
    f.ectSlots = f.ectSlots or {}
    if f.ectSlots[idx] then return f.ectSlots[idx] end

    local container
    if idx == 1 then
        container = f
    else
        local w, h = f:GetWidth(), f:GetHeight()
        container = CreateFrame("Frame", nil, f, "BackdropTemplate")
        container:SetSize(w, h)
        container:SetPoint("TOP", f, "BOTTOM", 0, -(SLOT_GAP + (idx - 2) * (h + SLOT_GAP)))
        container:SetFrameStrata(f:GetFrameStrata())
        container:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
        })
        container:Hide()
    end

    local cd = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
    cd:SetAllPoints(container)
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetReverse(true)
    cd:SetHideCountdownNumbers(false)

    local icon = container:CreateTexture(nil, "BORDER")
    icon:SetAllPoints(container)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local slot = { container = container, cd = cd, icon = icon }
    f.ectSlots[idx] = slot
    return slot
end

local function ActivateSlot(f, slot, spellID, ad, dur)
    slot.icon:SetTexture(C_Spell.GetSpellTexture(spellID))
    if ad and ad.expirationTime and ad.duration then
        slot.cd:SetCooldownFromDurationObject(dur)
    else
        slot.cd:Clear()
    end
    if slot.container ~= f then
        slot.container:SetBackdropColor(0.35, 0.05, 0.45, 0.9)
        slot.container:SetBackdropBorderColor(0.8, 0.3, 1.0, 1)
        slot.container:Show()
    end
end

local function ClearSlot(f, slot)
    slot.icon:SetTexture(nil)
    slot.cd:Clear()
    if slot.container ~= f then
        slot.container:Hide()
    end
end

local GLOW_CORNERS = {
    { point = "TOPLEFT",     x = -1, y =  1 },
    { point = "TOPRIGHT",    x =  1, y =  1 },
    { point = "BOTTOMLEFT",  x = -1, y = -1 },
    { point = "BOTTOMRIGHT", x =  1, y = -1 },
}

local function GetOrCreateTargetGlow(f)
    if f.targetGlow then return f.targetGlow end
    local g = CreateFrame("Frame", nil, f)
    g:SetAllPoints(f)
    g:SetFrameStrata("HIGH")
    local w   = f:GetWidth()
    local off = w * 0.1875
    local sz  = w * 1.4
    g.textures = {}
    for i, c in ipairs(GLOW_CORNERS) do
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        t:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
        t:SetSize(sz, sz)
        t:SetPoint(c.point, f, c.point, c.x * off, c.y * off)
        local ag = t:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(0.3)
        a:SetToAlpha(1.0)
        a:SetDuration(0.6)
        a:SetOrder(1)
        ag:Play()
        g.textures[i] = t
    end
    g:SetAlpha(0.75)
    g:Hide()
    f.targetGlow = g
    return g
end

-- ---------------------------------------------------------------------------
-- Refresh: find the best instanceID for each unit and apply state
-- ---------------------------------------------------------------------------

local function RefreshDebuffStates()
    -- Build single-target spell set from current spec's buffDB
    local stSpells = {}
    local DBTmod = _G.DynamicBuffTracker
    if DBTmod and DBTmod.currentSpecID ~= 0 and DynamicBuffTracker_GetSpecBuffDB then
        for k, entry in pairs(DynamicBuffTracker_GetSpecBuffDB(DBTmod.currentSpecID)) do
            if entry.singleTarget then stSpells[tonumber(k)] = true end
        end
    end
    local assignedST = {}  -- single-target spellIDs already shown on an earlier frame

    for i = 1, 80 do
        local f = _G["ECT_UnitFrame" .. i]
        if f and f:IsShown() and f.unit then
            local matches = {}
            local seenSpell = {}  -- spellID -> index in matches

            for id, spellID in pairs(instanceToSpell) do
                if not assignedST[spellID] then
                    local ok, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, f.unit, id)
                    if ok and ad then
                        local existingIdx = seenSpell[spellID]
                        if existingIdx then
                            -- Duplicate spellID on this frame: rescan to find where the
                            -- existing instanceID actually lives now.
                            local existingID = matches[existingIdx].id
                            local realUnit = FindUnitForInstance(existingID)
                            if realUnit == nil or realUnit == f.unit then
                                -- Existing is expired or a stale copy: remove it.
                                instanceToSpell[existingID] = nil
                            end
                            -- Current 'id' is the live one for this unit; replace the slot.
                            matches[existingIdx] = { id = id, spellID = spellID, ad = ad }
                        else
                            matches[#matches + 1] = { id = id, spellID = spellID, ad = ad }
                            seenSpell[spellID] = #matches
                        end
                    end
                end
            end

            table.sort(matches, function(a, b) return a.spellID < b.spellID end)

            -- Claim single-target spells so no subsequent frame can show them
            for _, m in ipairs(matches) do
                if stSpells[m.spellID] then assignedST[m.spellID] = true end
            end

            if #matches > 0 then
                local glow = GetOrCreateTargetGlow(f)
                if UnitIsUnit("target", f.unit) then glow:Show() else glow:Hide() end
                f:SetBackdropBorderColor(0.8, 0.3, 1.0, 1)
                f:SetBackdropColor(0.35, 0.05, 0.45, 0.9)
                for idx, m in ipairs(matches) do
                    local slot = GetOrCreateSlot(f, idx)
                    local dur = C_UnitAuras.GetAuraDuration(f.unit, m.id)
                    ActivateSlot(f, slot, m.spellID, m.ad, dur)
                end
                if f.ectSlots then
                    for idx = #matches + 1, #f.ectSlots do
                        ClearSlot(f, f.ectSlots[idx])
                    end
                end
            else
                local glow = GetOrCreateTargetGlow(f)
                if UnitIsUnit("target", f.unit) then glow:Show() else glow:Hide() end
                f:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
                f:SetBackdropColor(0.6, 0.1, 0.1, 0.85)
                if f.ectSlots then
                    for _, slot in ipairs(f.ectSlots) do
                        ClearSlot(f, slot)
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Enable / disable the overlay from outside (e.g. CombatCoach checkbox)
-- ---------------------------------------------------------------------------

function ECT_SetOverlayEnabled(enabled)
    if not enabled then
        wipe(instanceToSpell)
        for i = 1, 40 do
            local f = _G["ECT_UnitFrame" .. i]
            if f then
                if f.ectSlots then
                    for _, slot in ipairs(f.ectSlots) do ClearSlot(f, slot) end
                end
                if f.targetGlow then f.targetGlow:Hide() end
                f:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
                f:SetBackdropColor(0.6, 0.1, 0.1, 0.85)
            end
        end
        local anch = _G["ECT_UnitFramesAnchor"]
        if anch then anch:Hide() end
    else
        local anch = _G["ECT_UnitFramesAnchor"]
        if anch then anch:Show() end
    end
end

-- ---------------------------------------------------------------------------
-- Slash dump
-- ---------------------------------------------------------------------------

SLASH_ECTOVERLAY1 = "/ectd"
SlashCmdList["ECTOVERLAY"] = function()
    print("=== ECT Overlay Dump ===")
    local n = 0
    for id, spellID in pairs(instanceToSpell) do
        local unit = FindUnitForInstance(id)
        print("  instanceID:", id, "spellID:", spellID, "unit:", unit or "not found")
        n = n + 1
    end
    print("  total tracked:", n)
end

-- ---------------------------------------------------------------------------
-- UNIT_AURA on target
-- ---------------------------------------------------------------------------

local auraFrame = CreateFrame("Frame")
auraFrame:RegisterUnitEvent("UNIT_AURA", "target")
auraFrame:SetScript("OnEvent", function(_, _, unit)
    if unit ~= "target" or not IsOverlayEnabled() then return end
    SnapshotDBT()
    RefreshDebuffStates()
end)

-- ---------------------------------------------------------------------------
-- PLAYER_TARGET_CHANGED: snapshot DBT and refresh on every target change
-- ---------------------------------------------------------------------------

local targetFrame = CreateFrame("Frame")
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:SetScript("OnEvent", function()
    if not IsOverlayEnabled() then return end
    SnapshotDBT()
    RefreshDebuffStates()
end)

-- ---------------------------------------------------------------------------
-- UNIT_SPELLCAST_SUCCEEDED: prune stale instances and resync DBT after each cast
-- ---------------------------------------------------------------------------

local castFrame = CreateFrame("Frame")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castFrame:SetScript("OnEvent", function()
    if not IsOverlayEnabled() then return end
    PruneExpired()
    SnapshotDBT()
    RefreshDebuffStates()
end)

-- ---------------------------------------------------------------------------
-- PLAYER_LOGIN: apply saved enable/disable state after SavedVariables load
-- ---------------------------------------------------------------------------

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    local DBT = _G.DynamicBuffTracker
    local specID = DBT and DBT.currentSpecID or 0
    ECT_SetOverlayEnabled(IsOverlayEnabled())
    if ECT_SetOverlayScale and specID ~= 0 then
        ECT_SetOverlayScale(DynamicBuffTracker_GetSpecEctScale(specID))
    end
end)

-- ---------------------------------------------------------------------------
-- PLAYER_SPECIALIZATION_CHANGED: reapply per-spec enable state
-- ---------------------------------------------------------------------------

local specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specFrame:SetScript("OnEvent", function()
    local DBT = _G.DynamicBuffTracker
    local specID = DBT and DBT.currentSpecID or 0
    ECT_SetOverlayEnabled(IsOverlayEnabled())
    if ECT_SetOverlayScale and specID ~= 0 then
        ECT_SetOverlayScale(DynamicBuffTracker_GetSpecEctScale(specID))
    end
end)

-- ---------------------------------------------------------------------------
-- PLAYER_ENTERING_WORLD: full reset
-- ---------------------------------------------------------------------------

local lastTargetNP = 0  -- nameplate index last confirmed as target; 0 = none

local worldFrame = CreateFrame("Frame")
worldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
worldFrame:SetScript("OnEvent", function()
    wipe(instanceToSpell)
    lastTargetNP = 0
end)

-- ---------------------------------------------------------------------------
-- Ticker: snapshot + prune at 4 Hz, refresh at 10 Hz for smooth swipe
-- ---------------------------------------------------------------------------

local function FindTargetNameplateIndex()
    for i = 1, 40 do
        if UnitIsUnit("target", "nameplate" .. i) then
            return i
        end
    end
    return 0
end

local ticker = CreateFrame("Frame")
local tSlow, tFast = 0, 0
ticker:SetScript("OnUpdate", function(_, dt)
    if not IsOverlayEnabled() then return end
    tFast = tFast + dt
    if tFast >= 0.1 then
        tFast = 0
        RefreshDebuffStates()
    end

    tSlow = tSlow + dt
    if tSlow >= 0.25 then
        tSlow = 0
        local currentNP = FindTargetNameplateIndex()
        local npChanged = currentNP ~= lastTargetNP
        lastTargetNP = currentNP
        SnapshotDBT()
        if npChanged or PruneExpired() then RefreshDebuffStates() end
    end
end)