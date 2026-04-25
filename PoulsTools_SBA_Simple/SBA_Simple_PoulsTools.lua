-- SBA_Simple_PoulsTools.lua
-- PoulsTools integration for SBA_Simple

if not PoulsTools then return end

SBA_SimpleDB = SBA_SimpleDB or {}

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    local anchor = parent
    local y = 0

    -- Static class/spec mapping (authoritative names + IDs from
    -- skills/WoW_Detailed_Reference_Skill.md). Using IDs avoids
    -- localization/name mismatches and lets us detect specs that
    -- aren't present on this client/build.
    local staticClassSpecs = {
        ["Warrior"] = { {name = "Arms", id = 71}, {name = "Fury", id = 72}, {name = "Protection", id = 73} },
        ["Paladin"] = { {name = "Holy", id = 65}, {name = "Protection", id = 66}, {name = "Retribution", id = 70} },
        ["Hunter"] = { {name = "Beast Mastery", id = 253}, {name = "Marksmanship", id = 254}, {name = "Survival", id = 255} },
        ["Rogue"] = { {name = "Assassination", id = 259}, {name = "Outlaw", id = 260}, {name = "Subtlety", id = 261} },
        ["Priest"] = { {name = "Discipline", id = 256}, {name = "Holy", id = 257}, {name = "Shadow", id = 258} },
        ["Shaman"] = { {name = "Elemental", id = 262}, {name = "Enhancement", id = 263}, {name = "Restoration", id = 264} },
        ["Mage"] = { {name = "Arcane", id = 62}, {name = "Fire", id = 63}, {name = "Frost", id = 64} },
        ["Warlock"] = { {name = "Affliction", id = 265}, {name = "Demonology", id = 266}, {name = "Destruction", id = 267} },
        ["Monk"] = { {name = "Brewmaster", id = 268}, {name = "Mistweaver", id = 270}, {name = "Windwalker", id = 269} },
        ["Druid"] = { {name = "Balance", id = 102}, {name = "Feral", id = 103}, {name = "Guardian", id = 104}, {name = "Restoration", id = 105} },
        ["Demon Hunter"] = { {name = "Havoc", id = 577}, {name = "Vengeance", id = 581}, {name = "Devourer", id = 1480} },
        ["Death Knight"] = { {name = "Blood", id = 250}, {name = "Frost", id = 251}, {name = "Unholy", id = 252} },
        ["Evoker"] = { {name = "Devastation", id = 1467}, {name = "Preservation", id = 1468}, {name = "Augmentation", id = 1473} },
    }

    local header, dy = W:SectionHeader(parent, anchor, y, "PoulsTools_SBA_Simple")
    anchor = header
    y = dy

    -- track all spec buttons so we can enable/disable and refresh their colors
    local specButtons = {}
    local ACTION_BTN_W = 160

    anchor = W:Checkbox(parent, anchor, y,
        "Enabled",
        "Enable the SBA Simple icon.",
        function() return (SBA_SimpleDB and SBA_SimpleDB.enabled) ~= false end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.enabled = val; if SBA_Simple_SetEnabled then SBA_Simple_SetEnabled(val) end end
    )
    y = -6

    local sliderRow = W:Slider(parent, anchor, y,
        "Icon Size", 16, 128, 1,
        function() return (SBA_SimpleDB and SBA_SimpleDB.size) or 64 end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.size = val; if SBA_Simple_SetSize then SBA_Simple_SetSize(val) end end,
        "%d"
    )
    anchor = sliderRow
    y = -8
    -- Anchor Point dropdown removed: position is persisted but not editable here
    y = -8

    anchor = W:Checkbox(parent, anchor, y,
        "Glow Enabled",
        "Show glow around the icon.",
        function() return (SBA_SimpleDB and SBA_SimpleDB.glow_enabled) end,
        function(val) SBA_SimpleDB = SBA_SimpleDB or {}; SBA_SimpleDB.glow_enabled = val end
    )
    y = -6

    -- Edit Override Logic button removed; per-spec buttons provide editors now

    anchor = W:Button(parent, anchor, y, "Reset Position", function()
        if SlashCmdList and SlashCmdList["SBASIMPLE"] then
            SlashCmdList["SBASIMPLE"]("reset")
        else
            -- Fallback: perform a minimal reset if slash handler isn't available
            SBA_SimpleDB = SBA_SimpleDB or {}
            SBA_SimpleDB.x = 0
            SBA_SimpleDB.y = 0
            SBA_SimpleDB.point = "CENTER"
            SBA_SimpleDB.size = 64
            print("|cff00ff99SBA_Simple:|r position reset to defaults (partial).")
        end
    end)
    y = -8

    -- Lock / Unlock button for shmIcons
    local lockBtn = nil
    local lockLabel = "Lock Icons"
    if shmIcons and shmIcons.IsLocked and shmIcons:IsLocked() then lockLabel = "Unlock Icons" end
    anchor = W:Button(parent, anchor, y, lockLabel, function()
        if shmIcons and shmIcons.ToggleLock then
            local locked = shmIcons:ToggleLock()
            -- Update label to reflect the next action (clicking will toggle)
            local nextLabel = locked and "Unlock Icons" or "Lock Icons"
            if lockBtn then lockBtn:SetText(nextLabel) end
        else
            print("|cFFFF4444SBA_Simple:|r shmIcons not available.")
        end
    end)
    lockBtn = anchor
    y = -8

    y = -8
    local hdr, dy2 = W:SectionHeader(parent, anchor, y, "Single-Button Suggestion Overrides (by Class / Spec)")
    local listAnchor = hdr
    y = dy2

    -- Keep slider in sync when the settings panel is shown (reflect manual resizes)
    if sliderRow and sliderRow.slider and sliderRow.valText then
        parent:HookScript("OnShow", function()
            local sz = (SBA_SimpleDB and SBA_SimpleDB.size) or 64
            sliderRow.slider:SetValue(sz)
            sliderRow.valText:SetText(string.format("%d", sz))
            -- refresh lock button label
            if lockBtn and shmIcons and shmIcons.IsLocked then
                lockBtn:SetText(shmIcons:IsLocked() and "Unlock Icons" or "Lock Icons")
            end
        end)
    end

    -- Build class/spec data from API (if available)
    local orderedClasses = {}   -- sorted list of { name, classID }
    local classSpecData  = {}   -- cname -> { specs = [{id, displayName, apiKnown}] }

    if type(GetNumSpecializationsForClassID) == "function"
    and type(GetSpecializationInfoForClassID) == "function"
    and type(GetClassInfo) == "function" then
        for classID = 1, 13 do
            local cname = select(1, GetClassInfo(classID))
            if cname then
                orderedClasses[#orderedClasses + 1] = { name = cname, classID = classID }
                classSpecData[cname] = { specs = {} }

                local num = GetNumSpecializationsForClassID(classID) or 0
                local apiSpecByID      = {}
                local apiSpecNameByID  = {}
                local apiSpecByNameLow = {}
                for si = 1, num do
                    local specID, specName = GetSpecializationInfoForClassID(si, classID)
                    if specID and specName then
                        apiSpecByID[specID]               = true
                        apiSpecNameByID[specID]           = specName
                        apiSpecByNameLow[specName:lower()] = specID
                    end
                end

                local expected = staticClassSpecs[cname]
                if expected and type(expected) == "table" then
                    for _, expectedSpec in ipairs(expected) do
                        local expectedName = (type(expectedSpec) == "table" and expectedSpec.name) or expectedSpec
                        local expectedID   = (type(expectedSpec) == "table" and expectedSpec.id)   or nil
                        local matchingID   = nil
                        if expectedID and apiSpecByID[expectedID] then
                            matchingID = expectedID
                        elseif expectedName and apiSpecByNameLow[expectedName:lower()] then
                            matchingID = apiSpecByNameLow[expectedName:lower()]
                        end
                        local targetID   = matchingID or expectedID
                        local dName      = (targetID and apiSpecNameByID[targetID]) or expectedName
                        classSpecData[cname].specs[#classSpecData[cname].specs + 1] = {
                            id = targetID, displayName = dName,
                            apiKnown = targetID and apiSpecByID[targetID] and true or false,
                        }
                    end
                else
                    for si = 1, num do
                        local specID, specName = GetSpecializationInfoForClassID(si, classID)
                        if specID and specName then
                            classSpecData[cname].specs[#classSpecData[cname].specs + 1] = {
                                id = specID, displayName = specName, apiKnown = true,
                            }
                        end
                    end
                end
            end
        end
        table.sort(orderedClasses, function(a, b) return a.name < b.name end)
    end

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

                    local actionDefs = {
                        { "Override", function()
                            for _, se in ipairs(specButtons) do for _, sb in ipairs(se.btns or {}) do sb:Disable() end end
                            if _G.SBAS_OpenOverrideGUI then _G.SBAS_OpenOverrideGUI(targetID, cname .. " — " .. displayName) end
                        end },
                        { "Clear Override", function()
                            SBA_SimpleDB = SBA_SimpleDB or {}
                            SBA_SimpleDB.specs = SBA_SimpleDB.specs or {}
                            SBA_SimpleDB.specs[targetID] = SBA_SimpleDB.specs[targetID] or {}
                            SBA_SimpleDB.specs[targetID].overrideCode = ""
                            specLabel:SetTextColor(unpack(W.colors.textMuted))
                        end },
                    }
                    local actionBtns = {}
                    for i, def in ipairs(actionDefs) do
                        local ab = CreateFrame("Button", nil, group, "UIPanelButtonTemplate")
                        ab:SetSize(ACTION_BTN_W, 22)
                        ab:SetPoint("TOPLEFT", group, "TOPLEFT", 12 + (i - 1) * ACTION_BTN_W, gy)
                        ab:SetText(def[1])
                        ab:SetScript("OnClick", def[2])
                        actionBtns[i] = ab
                    end

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

                    table.insert(specButtons, { btns = actionBtns, label = specLabel, id = targetID })
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
        lbl:SetTextColor(unpack(PoulsTools.Widgets.colors.text))
    end

    -- Manage spec buttons: re-enable and refresh label colors when any editor closes
    local function refreshSpecButtonColors()
        local db = SBA_SimpleDB or {}
        for _, e in ipairs(specButtons) do
            local id = e.id
            local hasText = false
            if id and db.specs and db.specs[id] and db.specs[id].overrideCode and not db.specs[id].overrideCode:match("^%s*$") then
                hasText = true
            end
            if e.label then
                if hasText then e.label:SetTextColor(unpack(W.colors.warning)) else e.label:SetTextColor(unpack(W.colors.textMuted)) end
            end
        end
    end

    local function setSpecButtonsEnabled(enabled)
        for _, e in ipairs(specButtons) do
            for _, b in ipairs(e.btns or {}) do
                if enabled then b:Enable() else b:Disable() end
            end
        end
    end

    local function onEditorClose()
        setSpecButtonsEnabled(true)
        refreshSpecButtonColors()
    end

    -- Hook the text code editor (SBAS_OverrideFrame — always exists at this point)
    local overrideCodeFrame = _G["SBAS_OverrideFrame"]
    if overrideCodeFrame then
        overrideCodeFrame:HookScript("OnShow", function() setSpecButtonsEnabled(false) end)
        overrideCodeFrame:HookScript("OnHide", function() onEditorClose() end)
    end

    -- Hook the graphical GUI editor (SBAS_OverrideGUI_Frame — created lazily; wrap opener)
    local _guiFrameHooked = false
    local function ensureGUIFrameHooked()
        if _guiFrameHooked then return end
        local gf = _G["SBAS_OverrideGUI_Frame"]
        if gf then
            gf:HookScript("OnShow", function() setSpecButtonsEnabled(false) end)
            gf:HookScript("OnHide", function() onEditorClose() end)
            _guiFrameHooked = true
        end
    end

    if type(_G.SBAS_OpenOverrideGUI) == "function" then
        local _origOpenGUI = _G.SBAS_OpenOverrideGUI
        _G.SBAS_OpenOverrideGUI = function(sid, dname)
            setSpecButtonsEnabled(false)
            _origOpenGUI(sid, dname)
            ensureGUIFrameHooked()
        end
    end

end

PoulsTools.Menu:RegisterAddon({
    name      = "PoulsTools_SBA_Simple",
    id        = "PoulsTools_SBA_Simple",
    desc      = "Displays the Assisted Combat spell recommendation and allows for overriding this logic.",
    version   = "1.0.0",
    icon      = "Interface\\Icons\\ui_spellbook_onebutton",
    parentId  = "PoulsTools_shmIcons",
    OnBuildUI = OnBuildUI,
})
