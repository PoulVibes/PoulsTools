-- SBA_Simple_RuntimeTicker.lua
-- Per-frame runtime updates for SBA_Simple icons.

function SBAS_StartRuntimeTicker(context)
    local ticker = _G.SBAS_RuntimeTickerFrame
    if not ticker then
        ticker = CreateFrame("Frame")
        _G.SBAS_RuntimeTickerFrame = ticker
    end
    local npFrames = {}
    local elapsedAccum = 0
    local updateInterval = 0.05
    ticker:SetScript("OnUpdate", function(_, elapsed)
        elapsedAccum = elapsedAccum + (elapsed or 0)
        if elapsedAccum < updateInterval then return end
        elapsedAccum = 0

        local mainDB = context.getMainDB()
        local mainMode = mainDB.display_mode or "movable"
        local spellID, overridePri
        if mainMode ~= "disabled" then
            spellID, overridePri = context.runOverride()
        end
        context.setLastOverridePriority(overridePri)

        local currentDisplayedSpellID = context.getCurrentDisplayedSpellID()
        if mainMode == "movable" or mainMode == "both" then
            currentDisplayedSpellID = context.updateIcon(context.iconKey, spellID, currentDisplayedSpellID)
        else
            context.updateIcon(context.iconKey, nil, currentDisplayedSpellID)
            currentDisplayedSpellID = spellID
        end
        context.setCurrentDisplayedSpellID(currentDisplayedSpellID)

        if mainMode == "nameplate" or mainMode == "both" then
            context.updateIcon(context.iconKey .. context.npKeySuffix, spellID, nil)
        end
        shmIcons:SetVisible(context.addonName, context.iconKey .. context.npKeySuffix, false)

        for tabIdx = 2, context.getActiveExtraTabCount() + 1 do
            local tabDB = context.getExtraIconDB(tabIdx)
            local mode = tabDB.display_mode or "movable"
            local extraSpell = (mode ~= "disabled") and context.runExtraOverride(tabIdx) or nil
            local key = context.iconKey .. "_" .. tabIdx
            local npKey = key .. context.npKeySuffix

            if mode == "movable" or mode == "both" then
                context.extraDisplayedSpell[tabIdx] = context.updateIcon(key, extraSpell, context.extraDisplayedSpell[tabIdx])
            else
                context.updateIcon(key, nil, context.extraDisplayedSpell[tabIdx])
                context.extraDisplayedSpell[tabIdx] = extraSpell
            end
            if mode == "nameplate" or mode == "both" then
                context.updateIcon(npKey, extraSpell, nil)
            end
            shmIcons:SetVisible(context.addonName, npKey, false)
        end

        local nameplate = C_NamePlate.GetNamePlateForUnit("target")
        local reaction = UnitReaction("player", "target")
        local npVisible = nameplate and nameplate:IsShown() and reaction and reaction <= 4
        local npSettings = context.getNPSettings()
        for i = #npFrames, 1, -1 do
            npFrames[i] = nil
        end
        currentDisplayedSpellID = context.getCurrentDisplayedSpellID()

        if (mainMode == "nameplate" or mainMode == "both") and currentDisplayedSpellID then
            local obj = context.registeredIconObjects[context.iconKey .. context.npKeySuffix]
            if obj and obj.frame then
                npFrames[#npFrames + 1] = obj.frame
            end
        end

        for tabIdx = 2, context.getActiveExtraTabCount() + 1 do
            local tabDB = context.getExtraIconDB(tabIdx)
            local mode = tabDB.display_mode or "movable"
            if (mode == "nameplate" or mode == "both") and context.extraDisplayedSpell[tabIdx] then
                local obj = context.registeredIconObjects[context.iconKey .. "_" .. tabIdx .. context.npKeySuffix]
                if obj and obj.frame then
                    npFrames[#npFrames + 1] = obj.frame
                end
            end
        end

        if not npVisible then
            for _, frame in ipairs(npFrames) do
                frame:Hide()
            end
            return
        end

        if #npFrames == 0 then return end

        local BASE_NP_SIZE = 64
        local GAP = 4
        local sc = npSettings.np_scale or 1
        local visW = math.floor(BASE_NP_SIZE * sc + 0.5)
        local totalW = #npFrames * visW + (#npFrames - 1) * GAP
        local curX = -totalW / 2

        for _, frame in ipairs(npFrames) do
            frame:SetSize(visW, visW)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", nameplate, "BOTTOM",
                curX + visW / 2 + (npSettings.np_x or 0),
                -4 - (npSettings.np_y or 0))
            frame:SetAlpha(npSettings.np_opacity or 1)
            frame:Show()
            curX = curX + visW + GAP
        end
    end)
end

SBAS_StartRuntimeTicker(SBA_Simple_GetRuntimeContext())
