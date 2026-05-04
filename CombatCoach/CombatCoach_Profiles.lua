-- CombatCoach_Profiles.lua
-- Profile export / import system for CombatCoach
-- Serializes all known addon SavedVariables into a portable string

CombatCoach          = CombatCoach or {}
CombatCoach.Profiles = CombatCoach.Profiles or {}
local CC       = CombatCoach
local Profiles = CombatCoach.Profiles

-- Profile schema version — bump if the format changes incompatibly
Profiles.VERSION = 1

-- Known addon SavedVariable globals included in a profile.
-- Add new entries here as more CombatCoach addons gain saved variables.
Profiles.knownDBs = {
    { dbName = "ComboTrackerDB",      label = "CombatCoach_ComboTracker"      },
    { dbName = "CooldownTrackerDB",   label = "CombatCoach_CooldownTracker"   },
    { dbName = "ItemTrackerDB",       label = "CombatCoach_ItemTracker"       },
    { dbName = "SpellGlowTrackerDB",  label = "CombatCoach_SpellGlowTracker"  },
    { dbName = "SBA_SimpleDB",        label = "CombatCoach_SBA_Simple"        },
    { dbName = "TrinketTrackerDB",    label = "CombatCoach_TrinketTracker"    },
    { dbName = "VivifyProcTrackerDB", label = "CombatCoach_VivifyProcTracker" },
    { dbName = "OnUseTrackerDB",      label = "On Use Tracker"                },
}

-- Define the reload-after-import static popup once at load time
StaticPopupDialogs["CombatCoach_PROFILE_RELOAD"] = {
    text         = "Profile imported!\n\nUpdated: %s\n\nA UI reload is required to apply the changes. Reload now?",
    button1      = "Reload UI",
    button2      = "Later",
    OnAccept     = function() ReloadUI() end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- ============================================================
-- Serialization
-- Converts a Lua value to a valid Lua-syntax string.
-- Only booleans, numbers, strings, and tables are preserved.
-- ============================================================
local function serializeValue(val, depth)
    depth = depth or 0
    local vt = type(val)

    if vt == "boolean" then
        return tostring(val)
    elseif vt == "number" then
        if val ~= val then return "0" end       -- NaN guard
        return string.format("%.10g", val)
    elseif vt == "string" then
        return string.format("%q", val)
    elseif vt == "table" then
        if depth > 32 then return "{}" end
        local ind  = string.rep("  ", depth + 1)
        local clos = string.rep("  ", depth)
        local parts = {}
        for k, v in pairs(val) do
            local kStr
            if type(k) == "number" then
                kStr = "[" .. k .. "]"
            elseif type(k) == "string" then
                if k:match("^[%a_][%w_]*$") then
                    kStr = k
                else
                    kStr = "[" .. string.format("%q", k) .. "]"
                end
            end
            if kStr then
                parts[#parts + 1] = ind .. kStr .. " = " .. serializeValue(v, depth + 1)
            end
        end
        if #parts == 0 then return "{}" end
        table.sort(parts)   -- deterministic key order across exports
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. clos .. "}"
    end
    return "nil"
end

-- ============================================================
-- Profiles:Serialize()
-- Snapshots all currently-loaded addon DBs.
-- Returns: serializedString, includedLabelList   (success)
--          nil,              errorMessage        (failure)
-- ============================================================
function Profiles:Serialize()
    local profile = {
        _addon   = "CombatCoach",
        _version = self.VERSION,
        _date    = date("%Y-%m-%d"),
    }
    local included = {}
    for _, entry in ipairs(self.knownDBs) do
        local db = _G[entry.dbName]
        if db ~= nil then
            profile[entry.dbName] = CopyTable(db)
            included[#included + 1] = entry.label
        end
    end
    if #included == 0 then
        return nil, "No addon databases are currently loaded."
    end
    return serializeValue(profile), included
end

-- ============================================================
-- Profiles:Deserialize(str)
-- Parses a profile string back into a Lua table.
-- Returns: table, nil   (success)
--          nil,  errMsg (failure)
-- ============================================================
function Profiles:Deserialize(str)
    if type(str) ~= "string" or #str == 0 then
        return nil, "Profile string is empty."
    end
    -- Reject strings that contain executable / dangerous patterns
    local forbidden = {
        "function%s*%(",
        "loadstring%s*%(",
        "dofile%s*%(",
        "require%s*%(",
        "io%.%a",
        "os%.%a",
        "debug%.%a",
        "rawset%s*%(",
        "rawget%s*%(",
        "setfenv%s*%(",
    }
    for _, pat in ipairs(forbidden) do
        if str:find(pat) then
            return nil, "Profile contains disallowed content."
        end
    end

    local fn, parseErr = loadstring("return " .. str)
    if not fn then
        return nil, "Parse error: " .. tostring(parseErr)
    end
    local ok, result = pcall(fn)
    if not ok then
        return nil, "Load error: " .. tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "Profile is not a valid table."
    end
    if result._addon ~= "CombatCoach" then
        return nil, "String does not appear to be a CombatCoach profile."
    end
    return result
end

-- ============================================================
-- Profiles:Apply(profileData)
-- Copies each known DB from the profile into the matching global.
-- Returns: list of updated addon display labels
-- ============================================================
function Profiles:Apply(profileData)
    local applied = {}
    for _, entry in ipairs(self.knownDBs) do
        if type(profileData[entry.dbName]) == "table" then
            _G[entry.dbName] = CopyTable(profileData[entry.dbName])
            applied[#applied + 1] = entry.label
        end
    end
    return applied
end

-- ============================================================
-- Internal helpers
-- ============================================================

-- Shared dialog frame factory (matches CombatCoach dark aesthetic)
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
    title:SetText("|cFF00CCFFExport Profile|r")
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
    local str, payload = self:Serialize()
    if not str then
        print("|cFFFF4444CombatCoach Profiles:|r " .. tostring(payload))
        return
    end
    f.editBox:SetText(str)
    f.editBox:HighlightText()
    if f.infoLabel then
        f.infoLabel:SetText("Contains: " .. table.concat(payload, ", "))
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
    title:SetText("|cFF00CCFFImport Profile|r")
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

-- ============================================================
-- AddButtonsToMainPanel
-- Registers a "Profiles" submenu under the CombatCoach settings menu
-- with Import / Export buttons on its panel page.
-- ============================================================
function Profiles:AddButtonsToMainPanel()
    if not (CC.Menu and CC.Menu.RegisterAddon) then return end

    CC.Menu:RegisterAddon({
        name      = "Profiles",
        id        = "CombatCoach_Profiles",
        order     = 1,
        icon      = "Interface\\Icons\\inv_scroll_03",
        desc      = "Export and import CombatCoach layout.",
        OnBuildUI = function(parent)
            local exportBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            exportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
            exportBtn:SetSize(130, 24)
            exportBtn:SetText("Export Profile")
            exportBtn:SetScript("OnClick", function()
                Profiles:ShowExportFrame()
            end)

            local importBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
            importBtn:SetSize(130, 24)
            importBtn:SetText("Import Profile")
            importBtn:SetScript("OnClick", function()
                Profiles:ShowImportFrame()
            end)
        end,
    })
end
