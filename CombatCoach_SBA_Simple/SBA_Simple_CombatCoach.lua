-- SBA_Simple_CombatCoach.lua
-- CombatCoach integration for SBA_Simple

if not CombatCoach then return end

SBA_SimpleDB = SBA_SimpleDB or {}

-------------------------------------------------------------------------------
-- Override Priority Analyzer window
-------------------------------------------------------------------------------
local analyzerFrame = nil

local function CreateOverrideAnalyzerWindow(specID, specName)
    local PAD         = 10
    local ROW_H       = 24
    local WIN_W_DEF   = 420
    local ICON_SIZE   = 16
    local MAX_VIS_ROWS = 12  -- default visible rows; window is scrollable for more
    -- Fixed pixels consumed by icon + pri number + spell name to the left of condTxt
    -- icon(16) + gap(4) + pri(22) + gap(2) + name(90) + gap(4) = 138
    local COND_OFFSET = 138
    local HEADER_H = 30
    local GRIP_H   = 20   -- reserved at bottom for resize grip

    local f = CreateFrame("Frame", "SBAS_OverrideAnalyzerFrame", UIParent, "BackdropTemplate")
    f:Hide()  -- frames are visible by default; hide until explicitly opened
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(260, 80)
    f:EnableMouse(true)

    -- Backdrop
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left=4, right=4, top=4, bottom=4 },
        })
    end

    -- Title bar — also the drag handle; dragging here moves the window
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(20)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)
    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleTxt:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    titleTxt:SetText("Priority Analyzer — " .. (specName or ""))

    -- Close [X]
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Key handler for Escape; propagate so game hotkeys still work while open
    f:EnableKeyboard(true)
    if not InCombatLockdown() then
        f:SetPropagateKeyboardInput(true)
    end
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)

    -- Resize grip (bottom-right corner)
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    resizeGrip:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)

    -- ScrollFrame fills between header and resize grip; holds ALL rule rows
    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     PAD, -(HEADER_H + PAD))
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, GRIP_H)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetVerticalScroll()
        local m = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.min(math.max(v - delta * ROW_H, 0), m))
    end)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(WIN_W_DEF - PAD * 2)
    sc:SetHeight(100)
    sf:SetScrollChild(sc)

    -- Condition text truncation helper.
    -- Uses GetStringWidth() (measures raw text width with the current font,
    -- independent of any layout pass) so it works even before first render.
    local function TruncateCond(fs, text, maxW)
        fs:SetText(text)
        if fs:GetStringWidth() <= maxW then return end
        -- Binary search for longest prefix that fits with "..."
        local lo, hi = 0, #text
        while lo < hi do
            local mid = math.floor((lo + hi + 1) / 2)
            fs:SetText(text:sub(1, mid) .. "...")
            if fs:GetStringWidth() > maxW then
                hi = mid - 1
            else
                lo = mid
            end
        end
        fs:SetText(lo > 0 and text:sub(1, lo) .. "..." or "...")
    end

    -- Compute the available width for condition text given the current frame width
    local function CondMaxW()
        return math.max(0, f:GetWidth() - PAD * 2 - COND_OFFSET - 4)
    end

    local rows = {}  -- { frame, highlight, spellID, condTxt, condFull }

    local function BuildRows(rules, positionReset)
        for _, r in ipairs(rows) do r.frame:Hide() end
        rows = {}

        local count    = #rules
        local visCount = math.min(count, MAX_VIS_ROWS)
        local winH = HEADER_H + PAD + visCount * ROW_H + PAD + GRIP_H

        if positionReset then
            f:SetSize(WIN_W_DEF, winH)
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
        else
            -- Preserve user-set width; only update height to match visible count
            local curW = f:GetWidth()
            f:SetSize(curW > 0 and curW or WIN_W_DEF, winH)
        end

        -- Scroll child holds ALL rows (enables scrolling past DEF_VIS_ROWS)
        local scW = math.max(1, f:GetWidth() - PAD * 2)
        sc:SetWidth(scW)
        sc:SetHeight(math.max(count * ROW_H, 1))
        sf:SetVerticalScroll(0)

        local maxW = CondMaxW()

        for i, rule in ipairs(rules) do
            -- No break: all rules rendered into scroll child
            local row = CreateFrame("Frame", nil, sc)
            row:SetHeight(ROW_H)
            row:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, -(i - 1) * ROW_H)
            row:SetWidth(scW)

            -- Highlight texture (hidden by default)
            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints(row)
            hl:SetColorTexture(1, 0.85, 0, 0.18)
            hl:Hide()

            -- Spell icon
            local iconFrame = CreateFrame("Frame", nil, row)
            iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
            iconFrame:SetPoint("LEFT", row, "LEFT", 0, 0)
            local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints(iconFrame)
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            if rule.spellID then
                local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(rule.spellID)
                local texID = info and (info.iconID or info.originalIconID)
                if texID then iconTex:SetTexture(texID) end
            end

            -- Priority number
            local priTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            priTxt:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
            priTxt:SetWidth(22)
            priTxt:SetText(i .. ".")
            priTxt:SetTextColor(0.7, 0.7, 0.7)

            -- Spell name
            local spellName = (rule.name and rule.name ~= "") and rule.name
                              or (rule.spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(rule.spellID))
                              or "?"
            local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameTxt:SetPoint("LEFT", priTxt, "RIGHT", 2, 0)
            nameTxt:SetWidth(90)
            nameTxt:SetText(spellName)
            nameTxt:SetJustifyH("LEFT")

            -- Condition summary — same token format as the right panel; joined with spaces
            local condParts = {}
            if rule.conditions then
                local depth = 0
                for ci, cond in ipairs(rule.conditions) do
                    local tok
                    if type(_G.SBAS_BuildCondRowText) == "function" then
                        tok, depth = _G.SBAS_BuildCondRowText(cond, rule.spellID, ci == 1, depth)
                    else
                        -- Fallback if GUI module not loaded yet
                        local s = type(_G.SBAS_CondSummaryText) == "function"
                                  and _G.SBAS_CondSummaryText(cond, rule.spellID, specID)
                                  or (cond.type or "?")
                        if ci > 1 then s = (cond.junction or "AND"):upper() .. " " .. s end
                        tok = s
                    end
                    condParts[#condParts + 1] = tok
                end
            end
            local fullCond = #condParts > 0 and table.concat(condParts, " ") or "(no conditions)"

            local condTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            condTxt:SetPoint("LEFT",  row, "LEFT",  COND_OFFSET, 0)
            condTxt:SetWidth(maxW)   -- explicit width; no RIGHT anchor avoids layout-clamping
            condTxt:SetWordWrap(false)
            condTxt:SetNonSpaceWrap(false)
            condTxt:SetJustifyH("LEFT")
            condTxt:SetTextColor(0.6, 0.8, 1)
            TruncateCond(condTxt, fullCond, maxW)

            rows[i] = { frame=row, highlight=hl, spellID=rule.spellID,
                        condTxt=condTxt, condFull=fullCond }
        end
    end

    -- Re-truncate all condition texts when the frame is resized;
    -- also update scroll-child and row widths
    f:SetScript("OnSizeChanged", function()
        local scW  = math.max(1, f:GetWidth() - PAD * 2)
        sc:SetWidth(scW)
        local maxW = CondMaxW()
        for _, r in ipairs(rows) do
            if r.frame then r.frame:SetWidth(scW) end
            if r.condTxt and r.condFull then
                r.condTxt:SetWidth(maxW)
                TruncateCond(r.condTxt, r.condFull, maxW)
            end
        end
    end)

    -- Active-row highlight ticker
    local ticker = CreateFrame("Frame", nil, f)
    ticker:SetAllPoints(f)
    ticker:SetScript("OnUpdate", function()
        if not f:IsShown() then return end
        local suggested = C_AssistedCombat and C_AssistedCombat.GetNextCastSpell
                          and C_AssistedCombat.GetNextCastSpell()
        for _, r in ipairs(rows) do
            if suggested and r.spellID == suggested then
                r.highlight:Show()
            else
                r.highlight:Hide()
            end
        end
    end)

    -- Populate on show and when spec changes
    f.Refresh = function(sid, sname)
        specID   = sid   or specID
        specName = sname or specName
        titleTxt:SetText("Priority Analyzer — " .. (specName or ""))
        local db    = SBA_SimpleDB
        local rules = db and db.gui and db.gui[specID] or {}
        BuildRows(rules, false)
    end

    f:SetScript("OnShow", function()
        local db    = SBA_SimpleDB
        local rules = db and db.gui and db.gui[specID] or {}
        BuildRows(rules, true)
    end)

    return f
end

-- Public: open or refresh the analyzer window
function SBAS_OpenOrRefreshAnalyzer(specID, specName)
    if not analyzerFrame then
        analyzerFrame = CreateOverrideAnalyzerWindow(specID, specName)
        analyzerFrame:Show()   -- OnShow triggers BuildRows(rules, positionReset=true)
    else
        analyzerFrame.Refresh(specID, specName)
        if not analyzerFrame:IsShown() then
            analyzerFrame:Show()
        end
    end
end

local function OnBuildUI(parent)
    local W = CombatCoach.Widgets
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

    local header, dy = W:SectionHeader(parent, anchor, y, "CombatCoach_SBA_Simple")
    anchor = header
    y = dy

    -- track all spec buttons so we can enable/disable and refresh their colors
    local specButtons = {}
    -- Pending optimized baseline per specID: stored when "Optimized" is clicked.
    -- Save & Apply compares the saved export with this to decide mode.
    local pendingOptimizedBaseline = {}
    local ACTION_BTN_W = 160

    local function GetRecommendedImportTextForSpec(specID)
        if not specID then return nil end
        local getFn = _G.SBAS_GetRecommendedImportForSpec
        if type(getFn) ~= "function" then return nil end
        local rec = getFn(specID)
        if not rec or type(rec.importText) ~= "string" or rec.importText:match("^%s*$") then
            return nil
        end
        return rec.importText
    end

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

    -- ── Override Analyzer button ────────────────────────────────────────────
    local analyzerBtn
    analyzerBtn = W:Button(parent, anchor, y, "Priority Analyzer", function()
        -- Don't open if an editor is currently visible
        local guiEd  = _G["SBAS_OverrideGUI_Frame"]
        local codeEd = _G["SBAS_OverrideFrame"]
        if (guiEd and guiEd:IsShown()) or (codeEd and codeEd:IsShown()) then
            print("|cffFFCC00Priority Analyzer:|r Close the override editor first.")
            return
        end
        -- Determine current spec
        local specIndex = GetSpecialization and GetSpecialization()
        if not specIndex then
            print("|cffFF4444Priority Analyzer:|r Could not detect active spec.")
            return
        end
        local specID = select(1, GetSpecializationInfo(specIndex))
        if not specID then
            print("|cffFF4444Priority Analyzer:|r Could not detect active specID.")
            return
        end
        local db = SBA_SimpleDB
        local source = db and db.specs and db.specs[specID] and db.specs[specID].overrideSource
        local hasCode = db and db.specs and db.specs[specID] and db.specs[specID].overrideCode
                        and not db.specs[specID].overrideCode:match("^%s*$")
        local hasGui  = db and db.gui and db.gui[specID] and #db.gui[specID] > 0

        if source == "code" or (hasCode and not hasGui and source ~= "gui") then
            print("|cffFFCC00Priority Analyzer:|r Not available for coded overrides. Use the Override editor instead.")
            return
        end
        if not hasGui then
            print("|cffFFCC00Priority Analyzer:|r No GUI priority list found for the current spec.")
            return
        end
        -- Show the analyzer for this spec
        local specName = select(2, GetSpecializationInfo(specIndex)) or ("Spec "..specID)
        SBAS_OpenOrRefreshAnalyzer(specID, specName)
    end)
    anchor = analyzerBtn
    y = -8

    -- Debug error toggle button
    local debugToggleBtn
    local function GetDebugToggleLabel()
        local debug = SBA_SimpleDB and SBA_SimpleDB.overrideDebug
        return debug and "Suppress Errors" or "Show Errors"
    end
    debugToggleBtn = W:Button(parent, anchor, y, GetDebugToggleLabel(), function()
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.overrideDebug = not SBA_SimpleDB.overrideDebug
        if debugToggleBtn then debugToggleBtn:SetText(GetDebugToggleLabel()) end
    end)
    parent:HookScript("OnShow", function()
        if debugToggleBtn then debugToggleBtn:SetText(GetDebugToggleLabel()) end
    end)
    anchor = debugToggleBtn
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
            -- refresh spec button highlights
            for _, e in ipairs(specButtons) do
                if e.refreshHighlight then e.refreshHighlight() end
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
                    local specID, specName = GetSpecializationInfoForClassID(classID, si)
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
                        local specID, specName = GetSpecializationInfoForClassID(classID, si)
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
                    local recommendedImportText = GetRecommendedImportTextForSpec(targetID)

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
                        local db = SBA_SimpleDB or {}
                        local spec_db = db.specs and db.specs[targetID]
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
        lbl:SetTextColor(unpack(CombatCoach.Widgets.colors.text))
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
            if e.refreshHighlight then e.refreshHighlight() end
        end
    end

    -- Called by the GUI's Save & Apply with the serialized export of what was saved.
    -- Compares with the pending optimized baseline to determine mode, then refreshes highlights.
    _G.SBAS_OnGuiSaveAndApply = function(specID, savedExport)
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.specs = SBA_SimpleDB.specs or {}
        SBA_SimpleDB.specs[specID] = SBA_SimpleDB.specs[specID] or {}
        local baseline = pendingOptimizedBaseline and pendingOptimizedBaseline[specID]
        if baseline and savedExport == baseline then
            SBA_SimpleDB.specs[specID].overrideMode = "optimized"
        else
            SBA_SimpleDB.specs[specID].overrideMode = "custom"
        end
        if pendingOptimizedBaseline then pendingOptimizedBaseline[specID] = nil end
        refreshSpecButtonColors()
    end

    local function setSpecButtonsEnabled(enabled)
        for _, e in ipairs(specButtons) do
            for _, b in ipairs(e.btns or {}) do
                if enabled then
                    if b._alwaysDisabled then b:Disable() else b:Enable() end
                else
                    b:Disable()
                end
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

    -- Recommended/default imports can open the GUI without going through SBAS_OpenOverrideGUI.
    -- Wrap those helpers too so button disable/enable state always stays in sync.
    if type(_G.SBAS_LoadImportTextIntoOverrideGUI) == "function" then
        local _origLoadImportTextIntoGUI = _G.SBAS_LoadImportTextIntoOverrideGUI
        _G.SBAS_LoadImportTextIntoOverrideGUI = function(specID, displayName, payload)
            setSpecButtonsEnabled(false)
            local ok, err = _origLoadImportTextIntoGUI(specID, displayName, payload)
            ensureGUIFrameHooked()
            if not ok then
                onEditorClose()
            end
            return ok, err
        end
    end

    if type(_G.SBAS_LoadRulesIntoOverrideGUI) == "function" then
        local _origLoadRulesIntoGUI = _G.SBAS_LoadRulesIntoOverrideGUI
        _G.SBAS_LoadRulesIntoOverrideGUI = function(specID, displayName, rules)
            setSpecButtonsEnabled(false)
            local ok, err = _origLoadRulesIntoGUI(specID, displayName, rules)
            ensureGUIFrameHooked()
            if not ok then
                onEditorClose()
            end
            return ok, err
        end
    end

end

CombatCoach.Menu:RegisterAddon({
    name      = "Rotation Assistant",
    id        = "CombatCoach_SBA_Simple",
    order     = 2,
    desc      = "Prioritized Combat Suggestion Display.",
    version   = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("CombatCoach_SBA_Simple", "Version")) or "1.2.0",
    icon      = "Interface\\Icons\\ui_spellbook_onebutton",
    OnBuildUI = OnBuildUI,
})
