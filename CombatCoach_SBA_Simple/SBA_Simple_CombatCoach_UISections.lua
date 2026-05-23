-- SBA_Simple_CombatCoach_UISections.lua
-- Shared UI section builders for SBA_Simple CombatCoach panel.

function SBAS_GetRecommendedImportTextForSpec(specID)
    if not specID then return nil end
    local getFn = _G.SBAS_GetRecommendedImportForSpec
    if type(getFn) ~= "function" then return nil end
    local rec = getFn(specID)
    if not rec or type(rec.importText) ~= "string" or rec.importText:match("^%s*$") then
        return nil
    end
    return rec.importText
end

function SBAS_BuildDynamicIconSections(parent, debugToggleBtn, iconSectionsTailMarker)
    local W = CombatCoach.Widgets
    local dynamicIconFrames = {}

    local function RebuildDynamicIconSections()
        for _, f in ipairs(dynamicIconFrames) do
            if f and f.Hide then f:Hide() end
        end
        dynamicIconFrames = {}

        local tracked = type(SBA_Simple_GetTrackedIconInfo) == "function"
            and SBA_Simple_GetTrackedIconInfo() or {}
        if #tracked == 0 then
            tracked = {{ key = "Suggested_Spell", label = "Rotation", db = SBA_SimpleDB }}
        end

        local a = debugToggleBtn
        local iy = -8

        local modeHdr, modeDy = W:SectionHeader(parent, a, iy, "Icon Display")
        table.insert(dynamicIconFrames, modeHdr)
        a = modeHdr
        iy = modeDy

        local displayModes = {
            { text = "Disabled", value = "disabled" },
            { text = "Movable Icon", value = "movable" },
            { text = "Nameplate Icon", value = "nameplate" },
            { text = "Both", value = "both" },
        }

        for _, info in ipairs(tracked) do
            local capturedDB = info.db
            local dd = W:Dropdown(parent, a, iy,
                info.label or "Icon",
                displayModes,
                function() return capturedDB.display_mode or "movable" end,
                function(val) capturedDB.display_mode = val end
            )
            table.insert(dynamicIconFrames, dd)
            a = dd
            iy = -4
        end

        local npHdr, npDy = W:SectionHeader(parent, a, iy, "Nameplate Settings")
        table.insert(dynamicIconFrames, npHdr)
        a = npHdr
        iy = npDy

        local function getNPS()
            SBA_SimpleDB = SBA_SimpleDB or {}
            return SBA_SimpleDB
        end

        local opRow = W:Slider(parent, a, iy,
            "Opacity", 0, 100, 1,
            function() return math.floor(((getNPS()).np_opacity or 1) * 100) end,
            function(val) (getNPS()).np_opacity = val / 100 end,
            "%d%%"
        )
        table.insert(dynamicIconFrames, opRow)
        a = opRow
        iy = -8

        local scRow = W:Slider(parent, a, iy,
            "Scale", 25, 200, 5,
            function() return math.floor(((getNPS()).np_scale or 1) * 100) end,
            function(val) (getNPS()).np_scale = val / 100 end,
            "%d%%"
        )
        table.insert(dynamicIconFrames, scRow)
        a = scRow
        iy = -8

        local xRow = W:Slider(parent, a, iy,
            "X Offset", -100, 100, 1,
            function() return (getNPS()).np_x or 0 end,
            function(val) (getNPS()).np_x = val end,
            "%d"
        )
        table.insert(dynamicIconFrames, xRow)
        a = xRow
        iy = -8

        local yRow = W:Slider(parent, a, iy,
            "Y Offset", -100, 100, 1,
            function() return (getNPS()).np_y or 0 end,
            function(val) (getNPS()).np_y = val end,
            "%d"
        )
        table.insert(dynamicIconFrames, yRow)
        a = yRow
        iy = -16

        iconSectionsTailMarker:ClearAllPoints()
        iconSectionsTailMarker:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 0, iy)
    end

    return RebuildDynamicIconSections
end
