-- TriggerTracker_Export.lua
-- /tt export: opens a window showing all saved triggers as pasteable Lua.

local TT = TriggerTracker
local exportFrame = nil

-- Fields that are per-user layout and should not be exported.
local SKIP = { x = true, y = true, point = true, size = true }

local function SerializeValue(v, depth)
    local t = type(v)
    if t == "string"  then return string.format("%q", v) end
    if t == "boolean" then return tostring(v) end
    if t == "number"  then return tostring(v) end
    if t ~= "table"   then return "nil" end
    local ind  = string.rep("    ", depth)
    local ind1 = string.rep("    ", depth + 1)
    local nums, strs = {}, {}
    for k in pairs(v) do
        if type(k) == "number" then nums[#nums+1] = k else strs[#strs+1] = k end
    end
    table.sort(nums); table.sort(strs)
    local parts = {}
    for _, k in ipairs(nums) do
        parts[#parts+1] = ind1 .. "[" .. k .. "] = " .. SerializeValue(v[k], depth+1) .. ","
    end
    for _, k in ipairs(strs) do
        parts[#parts+1] = ind1 .. k .. " = " .. SerializeValue(v[k], depth+1) .. ","
    end
    return "{\n" .. table.concat(parts, "\n") .. "\n" .. ind .. "}"
end

local function BuildExportText()
    local db = TriggerTrackerDB
    if not db or not db.specs then return "-- No saved triggers found." end
    local lines = { "TriggerTracker_Defaults = TriggerTracker_Defaults or {}\n" }
    local specIDs = {}
    for id in pairs(db.specs) do specIDs[#specIDs+1] = id end
    table.sort(specIDs)
    for _, specID in ipairs(specIDs) do
        local triggers = db.specs[specID] and db.specs[specID].triggers
        if triggers and next(triggers) then
            lines[#lines+1] = "TriggerTracker_Defaults[" .. specID .. "] = {"
            local idxList = {}
            for idx in pairs(triggers) do idxList[#idxList+1] = idx end
            table.sort(idxList)
            for _, idx in ipairs(idxList) do
                local clean = {}
                for k, v in pairs(triggers[idx]) do
                    if not SKIP[k] then clean[k] = v end
                end
                lines[#lines+1] = "    [" .. idx .. "] = " .. SerializeValue(clean, 1) .. ","
            end
            lines[#lines+1] = "}\n"
        end
    end
    if #lines == 1 then return "-- No saved triggers found." end
    return table.concat(lines, "\n")
end

local function EnsureExportFrame()
    if exportFrame then return exportFrame end
    local f = CreateFrame("Frame", "TT_ExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(600, 480)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    local CF = TT.CF
    if CF and CF.SetBD then CF.SetBD(f, 0.04, 0.06, 0.12, 0.97, 0.28, 0.48, 0.68) end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Trigger Tracker \226\128\148 Export All Triggers")
    title:SetTextColor(0.55, 0.82, 1, 1)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -30)
    hint:SetText("Copy and paste into TriggerTracker_Defaults.lua to preload for all users.")
    hint:SetTextColor(0.6, 0.75, 0.9, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local selectBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selectBtn:SetSize(110, 24)
    selectBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 10)
    selectBtn:SetText("Select All")

    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     10, -50)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 44)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetWidth(sf:GetWidth() - 10)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    selectBtn:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText() end)

    f._eb = eb
    exportFrame = f
    return f
end

function TriggerTracker_OpenExportWindow()
    local f = EnsureExportFrame()
    f._eb:SetText(BuildExportText())
    f:Show()
    f._eb:HighlightText()
end
