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

    local header, dy = W:SectionHeader(parent, anchor, y, "SBA Simple")
    anchor = header
    y = dy

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

    anchor = W:Button(parent, anchor, y, "Edit Override Logic", function()
        if SBA_Simple_ShowOverrideForSpec then
            SBA_Simple_ShowOverrideForSpec(nil)
        else
            print("|cFFFF4444SBA_Simple:|r Override editor not available.")
        end
    end)
    y = -8

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

    -- Try preferred API: GetNumSpecializationsForClassID / GetSpecializationInfoForClassID
    if type(GetNumSpecializationsForClassID) == "function" and type(GetSpecializationInfoForClassID) == "function" and type(GetClassInfo) == "function" then
        for classID = 1, 13 do
            local cname = select(1, GetClassInfo(classID))
            if cname then
                local classLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                classLabel:SetPoint("TOPLEFT", listAnchor, "BOTTOMLEFT", 0, y)
                classLabel:SetText(cname .. ":")
                classLabel:SetTextColor(unpack(PoulsTools.Widgets.colors.text))
                y = y - 18

                local num = GetNumSpecializationsForClassID(classID) or 0
                -- Build mappings: specID -> name and name(lower) -> specID (fallback)
                local apiSpecByID = {}
                local apiSpecNameByID = {}
                local apiSpecByNameLower = {}
                for si = 1, num do
                    local specID, specName = GetSpecializationInfoForClassID(si, classID)
                    if specID and specName then
                        apiSpecByID[specID] = true
                        apiSpecNameByID[specID] = specName
                        apiSpecByNameLower[specName:lower()] = specID
                    end
                end

                -- Prefer authoritative static list from the detailed reference when available
                local expected = staticClassSpecs[cname]
                if expected and type(expected) == "table" then
                        for _, expectedSpec in ipairs(expected) do
                            local expectedName = (type(expectedSpec) == "table" and expectedSpec.name) or expectedSpec
                            local expectedID = (type(expectedSpec) == "table" and expectedSpec.id) or nil
                            local matchingID = nil

                            -- Prefer authoritative ID matching (avoids localization issues)
                            if expectedID and apiSpecByID[expectedID] then
                                matchingID = expectedID
                            else
                                -- Fallback to name (case-insensitive)
                                if expectedName and apiSpecByNameLower[expectedName:lower()] then
                                    matchingID = apiSpecByNameLower[expectedName:lower()]
                                end
                            end

                            -- Always enable button: choose target ID (prefer matching, else expected)
                            local targetID = matchingID or expectedID
                            local displayName = (targetID and apiSpecNameByID[targetID]) or expectedName

                            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
                            btn:SetSize(520, 22)
                            btn:SetPoint("TOPLEFT", listAnchor, "BOTTOMLEFT", 12, y)
                            btn:SetText(displayName)
                            local f = btn:GetFontString()
                            if f then
                                f:SetJustifyH("LEFT")
                                f:ClearAllPoints()
                                f:SetPoint("LEFT", btn, "LEFT", 8, 0)
                                f:SetWidth(480)
                            end

                            -- Clicking will open the override editor for targetID (creates DB entry if missing)
                            btn:SetScript("OnClick", function()
                                SBA_Simple_ShowOverrideForSpec(targetID, cname .. " — " .. displayName)
                            end)

                            -- If the client API doesn't report this spec ID, show an explanatory tooltip
                            if targetID and not apiSpecByID[targetID] then
                                btn:SetScript("OnEnter", function(self)
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    local tip = "Spec not reported by this client API; clicking will create per-spec data for id: " .. tostring(targetID)
                                    GameTooltip:SetText(tip, 1,1,1)
                                    GameTooltip:Show()
                                end)
                                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                            end

                            y = y - 26
                        end
                else
                    -- Fallback: enumerate API-provided specs if no static list
                    for si = 1, num do
                        local specID, specName = GetSpecializationInfoForClassID(si, classID)
                        if specName then
                            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
                            btn:SetSize(520, 22)
                            btn:SetPoint("TOPLEFT", listAnchor, "BOTTOMLEFT", 12, y)
                            btn:SetText(specName)
                            local f = btn:GetFontString()
                            if f then
                                f:SetJustifyH("LEFT")
                                f:ClearAllPoints()
                                f:SetPoint("LEFT", btn, "LEFT", 8, 0)
                                f:SetWidth(480)
                            end
                            btn:SetScript("OnClick", function()
                                SBA_Simple_ShowOverrideForSpec(specID, cname .. " — " .. specName)
                            end)
                            y = y - 26
                        end
                    end
                end
            end
        end
    else
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", listAnchor, "BOTTOMLEFT", 0, y)
        lbl:SetText("Class/spec enumeration not available on this client.")
        lbl:SetTextColor(unpack(PoulsTools.Widgets.colors.text))
        y = y - 18
    end
end

PoulsTools.Menu:RegisterAddon({
    name    = "SBA Simple",
    id      = "SBA_Simple",
    desc    = "Displays the Assited Combat spell reccomendation and allows for overriding this logic.",
    version = "1.0.0",
    icon    = "Interface\\Icons\\INV_Misc_Gear_01",
    OnBuildUI = OnBuildUI,
})
