-- SBA_Simple_CombatCoach_SpecUI.lua
-- Builds class/spec override action groups for the CombatCoach panel.

function SBAS_BuildClassSpecUI(parent, listAnchor, y, orderedClasses, classSpecData, GetRecommendedImportTextForSpec, pendingOptimizedBaseline, ACTION_BTN_W, W)
    local specButtons = {}

    if #orderedClasses > 0 then
        -- Detect player's current class as the default dropdown selection
        local defaultClass = orderedClasses[1].name
        if UnitClass then
            local localizedClass = select(1, UnitClass("player"))
            if localizedClass and classSpecData[localizedClass] then
                defaultClass = localizedClass
            end
        end
        local selectedClass = defaultClass

        -- class group frames, keyed by class name
        local classGroupFrames = {}

        -- Show only the selected class group, hide all others
        local function showClassGroup(cname)
            for c, gf in pairs(classGroupFrames) do
                if c == cname then gf:Show() else gf:Hide() end
            end
        end

        -- Build class dropdown
        local dropdownItems = {}
        for _, cd in ipairs(orderedClasses) do
            dropdownItems[#dropdownItems + 1] = { text = cd.name, value = cd.name }
        end
        local classDropRow = W:Dropdown(parent, listAnchor, y,
            "Class",
            dropdownItems,
            function() return selectedClass end,
            function(val)
                selectedClass = val
                showClassGroup(val)
            end
        )
        y = -8

        -- Build a per-class group frame; all anchored to same point below the dropdown
        for _, cd in ipairs(orderedClasses) do
            local cname = cd.name
            local data  = classSpecData[cname]
            if data and #data.specs > 0 then
                local group = CreateFrame("Frame", nil, parent)
                group:SetPoint("TOPLEFT", classDropRow, "BOTTOMLEFT", 0, y)
                group:SetSize(540, 1)
                classGroupFrames[cname] = group

                local gy = 0
                for _, spec in ipairs(data.specs) do
                    local targetID   = spec.id
                    local displayName = spec.displayName
                    local recommendedImportText = GetRecommendedImportTextForSpec and GetRecommendedImportTextForSpec(targetID)

                    local db = SBA_SimpleDB or {}
                    local hasText = false
                    if targetID and db.specs and db.specs[targetID]
                    and db.specs[targetID].overrideCode
                    and not db.specs[targetID].overrideCode:match("^%s*$") then
                        hasText = true
                    end

                    local specLabel = group:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    specLabel:SetPoint("TOPLEFT", group, "TOPLEFT", 14, gy)
                    specLabel:SetText(displayName)
                    if hasText then specLabel:SetTextColor(unpack(W.colors.warning))
                    else             specLabel:SetTextColor(unpack(W.colors.textMuted)) end
                    gy = gy - 18

                    -- Per-spec highlight state (closures capture targetID)
                    local highlightFrames = {}

                    local function GetSpecMode()
                        local dbLocal = SBA_SimpleDB or {}
                        local spec_db = dbLocal.specs and dbLocal.specs[targetID]
                        local code = spec_db and spec_db.overrideCode
                        if not code or code:match("^%s*$") then return "blizzard" end
                        local mode = spec_db and spec_db.overrideMode
                        if mode then return mode end
                        return "custom"
                    end

                    local function RefreshHighlight()
                        local mode = GetSpecMode()
                        -- button indices: 1=Custom, 2=Optimized, 3=Blizzard SBA
                        local activeIdx = (mode == "blizzard") and 3
                                       or (mode == "optimized") and 2
                                       or 1
                        for i, hf in ipairs(highlightFrames) do
                            if i == activeIdx then hf:Show() else hf:Hide() end
                        end
                    end

                    local actionDefs = {
                        { "Custom", function()
                            -- Open the GUI; mode will be committed to "custom" when
                            -- Save & Apply is clicked (no immediate highlight change).
                            pendingOptimizedBaseline[targetID] = nil
                            if _G.SBAS_OpenOverrideGUI then
                                _G.SBAS_OpenOverrideGUI(targetID, cname .. " — " .. displayName)
                            end
                        end },
                        { "Optimized", function()
                            if type(_G.SBAS_LoadImportTextIntoOverrideGUI) ~= "function" then
                                print("|cffff4444SBA_Simple:|r Recommended import helper is unavailable.")
                                return
                            end

                            local ok, err = _G.SBAS_LoadImportTextIntoOverrideGUI(targetID, cname .. " - " .. displayName, recommendedImportText)
                            if not ok then
                                print("|cffff4444SBA_Simple:|r Failed to load recommended override: " .. tostring(err or "unknown error"))
                                return
                            end

                            -- Store the baseline; Save & Apply will compare saved rules
                            -- against it to determine "optimized" vs "custom".
                            -- Normalize through the same pipeline as SerializeRulesForExportV2
                            -- so the strings are directly comparable.
                            if type(_G.SBAS_NormalizeImportText) == "function" then
                                local normalized = _G.SBAS_NormalizeImportText(recommendedImportText, targetID)
                                pendingOptimizedBaseline[targetID] = normalized or recommendedImportText
                            else
                                pendingOptimizedBaseline[targetID] = recommendedImportText
                            end
                            print("|cff00ff99SBA_Simple:|r Loaded recommended GUI priorities for " .. displayName .. ".")
                        end, recommendedImportText ~= nil },
                        { "Blizzard SBA", function()
                            SBA_SimpleDB = SBA_SimpleDB or {}
                            SBA_SimpleDB.specs = SBA_SimpleDB.specs or {}
                            SBA_SimpleDB.specs[targetID] = SBA_SimpleDB.specs[targetID] or {}
                            SBA_SimpleDB.specs[targetID].overrideCode = ""
                            SBA_SimpleDB.specs[targetID].overrideMode = "blizzard"
                            pendingOptimizedBaseline[targetID] = nil
                            -- Reset the GUI priority list for tab-1 to the SBA default
                            if type(_G.SBAS_ResetToBlizzardSBA) == "function" then
                                _G.SBAS_ResetToBlizzardSBA(targetID)
                            end
                            specLabel:SetTextColor(unpack(W.colors.textMuted))
                            RefreshHighlight()
                        end },
                    }
                    local actionBtns = {}
                    for i, def in ipairs(actionDefs) do
                        local ab = CreateFrame("Button", nil, group, "UIPanelButtonTemplate")
                        ab:SetSize(ACTION_BTN_W, 22)
                        ab:SetPoint("TOPLEFT", group, "TOPLEFT", 12 + (i - 1) * ACTION_BTN_W, gy)
                        ab:SetText(def[1])
                        ab:SetScript("OnClick", def[2])
                        if def[3] == false then
                            ab._alwaysDisabled = true
                            ab:Disable()
                        end
                        actionBtns[i] = ab

                        -- Light-blue border overlay to indicate the active choice
                        local hf = CreateFrame("Frame", nil, ab, "BackdropTemplate")
                        hf:SetAllPoints(ab)
                        hf:SetFrameLevel(ab:GetFrameLevel() + 5)
                        hf:SetBackdrop({
                            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                            edgeSize = 8,
                            insets = { left = 1, right = 1, top = 1, bottom = 1 },
                        })
                        hf:SetBackdropBorderColor(0.4, 0.8, 1, 1)
                        hf:Hide()
                        highlightFrames[i] = hf
                    end

                    RefreshHighlight()

                    if not spec.apiKnown then
                        for _, ab in ipairs(actionBtns) do
                            ab:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetText("Spec not reported by this client API; id: " .. tostring(targetID), 1, 1, 1)
                                GameTooltip:Show()
                            end)
                            ab:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        end
                    end

                    table.insert(specButtons, { btns = actionBtns, label = specLabel, id = targetID, refreshHighlight = RefreshHighlight })
                    gy = gy - 26
                end
                group:SetHeight(-gy + 4)
                group:Hide()  -- showClassGroup will reveal the correct one
            end
        end

        showClassGroup(selectedClass)
    else
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", listAnchor, "BOTTOMLEFT", 0, y)
        lbl:SetText("Class/spec enumeration not available on this client.")
        lbl:SetTextColor(unpack(W.colors.text))
    end

    return specButtons
end
