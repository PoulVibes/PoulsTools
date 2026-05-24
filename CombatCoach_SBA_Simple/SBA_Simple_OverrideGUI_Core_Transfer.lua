-- SBA_Simple_OverrideGUI_Core_Transfer.lua
-- Shared import/export helpers for override GUI rules.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

M._getCurrentSpecID = M._getCurrentSpecID or function() return 0 end

function M.SetCurrentSpecIDAccessor(fn)
    if type(fn) == "function" then M._getCurrentSpecID = fn end
end

function M.GetCurrentSpecID()
    return tonumber(M._getCurrentSpecID and M._getCurrentSpecID() or 0) or 0
end

function M.EncodeField(v)
    if v == nil then return "" end
    local s = tostring(v)
    s = s:gsub("%%", "%%25")
    s = s:gsub("\r", "%%0D")
    s = s:gsub("\n", "%%0A")
    s = s:gsub("|", "%%7C")
    s = s:gsub(",", "%%2C")
    s = s:gsub(";", "%%3B")
    s = s:gsub("~", "%%7E")
    s = s:gsub("%(", "%%28")
    s = s:gsub("%)", "%%29")
    return s
end

function M.DecodeField(v)
    if not v or v == "" then return "" end
    return (v:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

function M.SplitPipe(line)
    local out, start = {}, 1
    while true do
        local idx = line:find("|", start, true)
        if not idx then
            out[#out + 1] = line:sub(start)
            break
        end
        out[#out + 1] = line:sub(start, idx - 1)
        start = idx + 1
    end
    return out
end

function M.SplitByChar(s, sep)
    local out, start = {}, 1
    while true do
        local idx = s:find(sep, start, true)
        if not idx then
            out[#out + 1] = s:sub(start)
            break
        end
        out[#out + 1] = s:sub(start, idx - 1)
        start = idx + 1
    end
    return out
end

function M.NormalizeExportSpecID(specID)
    local sid = tonumber(specID) or 0
    if sid > 4 then return sid end

    local editSpecID = M.GetEditSpecID and M.GetEditSpecID() or 0
    if editSpecID > 4 then return editSpecID end

    if sid > 0 and sid <= 4 and type(GetSpecializationInfo) == "function" then
        local byIndex = select(1, GetSpecializationInfo(sid))
        if byIndex and byIndex > 0 then return byIndex end
    end

    local cur = M.GetCurrentSpecID()
    if cur and cur > 0 then return cur end
    return sid
end

function M.SerializeRulesForExportV2(specID, rules)
    local chunks = {}
    local exportSpecID = M.NormalizeExportSpecID(specID)
    chunks[#chunks + 1] = ("SBASGUI2|1|%d"):format(exportSpecID or 0)

    for _, rule in ipairs(rules or {}) do
        local ruleParts = {
            "R",
            M.EncodeField(rule.spellID or 0),
            M.EncodeField(rule.name or ""),
        }

        for idx, cond in ipairs(rule.conditions or {}) do
            local spellMode, spellID = "", ""
            if cond.spell == "this" or cond.spell == nil then
                spellMode = "this"
            elseif type(cond.spell) == "number" then
                spellMode = "num"; spellID = cond.spell
            elseif cond.targetID then
                spellMode = "num"; spellID = cond.targetID
            end

            local body = table.concat({
                M.EncodeField(cond.type or ""),
                M.EncodeField(cond.negate and "1" or "0"),
                M.EncodeField(spellMode),
                M.EncodeField(spellID),
                M.EncodeField(cond.resource),
                M.EncodeField(cond.operator),
                M.EncodeField(cond.plugin),
                M.EncodeField(cond.value),
                M.EncodeField(cond.luaCode),
            }, "~")

            local j = ""
            if idx > 1 then j = (cond.junction == "or") and "||" or "&&" end
            local lp = (cond.lparen and cond.lparen > 0) and string.rep("(", cond.lparen) or ""
            local rp = (cond.rparen and cond.rparen > 0) and string.rep(")", cond.rparen) or ""
            ruleParts[#ruleParts + 1] = j .. lp .. body .. rp
        end

        chunks[#chunks + 1] = table.concat(ruleParts, ",")
    end

    return table.concat(chunks, ";")
end

function M.NormalizeRuleParens(conds)
    local depth = 0
    for _, cond in ipairs(conds or {}) do
        local lp = math.max(0, tonumber(cond.lparen) or 0)
        local rp = math.max(0, tonumber(cond.rparen) or 0)
        local maxClosable = depth + lp
        if rp > maxClosable then rp = maxClosable end
        cond.lparen = (lp > 0) and lp or nil
        cond.rparen = (rp > 0) and rp or nil
        depth = maxClosable - rp
    end
    if depth > 0 and conds and #conds > 0 then
        local last = conds[#conds]
        last.rparen = (tonumber(last.rparen) or 0) + depth
    end
end

function M.DeserializeRulesFromExportV2(text, expectedSpecID)
    local payload = (text or ""):match("^%s*(.-)%s*$") or ""
    local chunks = M.SplitByChar(payload, ";")
    if #chunks == 0 or not chunks[1] or chunks[1] == "" then return nil, "Import text is empty." end

    local header = M.SplitPipe(chunks[1])
    if header[1] ~= "SBASGUI2" then return nil, "Missing v2 export header (expected SBASGUI2)." end

    local rawVersion = tostring(header[2] or ""):match("^%s*(.-)%s*$") or ""
    local version = tonumber(rawVersion) or tonumber(rawVersion:match("(%d+)"))
    local rawSpec = tostring(header[3] or "")
    local sourceSpecID = tonumber(rawSpec:match("^(%d+)$")) or tonumber(rawSpec:match("^(%d+)")) or 0

    if not version and rawVersion == "" then version = 1 end
    if rawVersion == "" and sourceSpecID > 0 and (sourceSpecID == 1 or sourceSpecID == 2) and #header >= 4 then
        local shiftedSpec = tonumber(tostring(header[4] or ""):match("^(%d+)")) or 0
        if shiftedSpec > 0 then version = sourceSpecID; sourceSpecID = shiftedSpec end
    end

    if not version and #header >= 3 then
        for i = 2, #header do
            local token = tostring(header[i] or "")
            local n = tonumber(token) or tonumber(token:match("(%d+)"))
            if not version and (n == 1 or n == 2) then version = n end
        end
    end
    if version ~= 1 and version ~= 2 then return nil, "Unsupported v2 export version: " .. rawVersion end

    if sourceSpecID > 0 and sourceSpecID <= 4 then sourceSpecID = 0 end
    if expectedSpecID and expectedSpecID ~= 0 and sourceSpecID ~= 0 and sourceSpecID ~= expectedSpecID then
        return nil, ("Spec mismatch: import is for spec %d, current GUI is spec %d."):format(sourceSpecID, expectedSpecID)
    end

    local out = {}
    for i = 2, #chunks do
        local line = chunks[i]
        if line and line ~= "" then
            local parts = M.SplitByChar(line, ",")
            if parts[1] ~= "R" then return nil, "Invalid v2 record tag: " .. tostring(parts[1]) end

            local spellID = tonumber(M.DecodeField(parts[2] or "")) or 0
            local name = M.DecodeField(parts[3] or "")
            if name == "" then name = tostring(spellID) end

            local rule = { spellID = spellID, name = name, conditions = {} }
            for ci = 4, #parts do
                local tok = parts[ci] or ""
                if tok ~= "" then
                    local junction
                    if tok:sub(1, 2) == "&&" then junction = "and"; tok = tok:sub(3)
                    elseif tok:sub(1, 2) == "||" then junction = "or"; tok = tok:sub(3)
                    elseif tok:sub(1, 1) == "&" then junction = "and"; tok = tok:sub(2)
                    elseif tok:sub(1, 1) == "|" then junction = "or"; tok = tok:sub(2)
                    end

                    local lp, rp = 0, 0
                    while tok:sub(1, 1) == "(" do lp = lp + 1; tok = tok:sub(2) end
                    while tok:sub(-1) == ")" do rp = rp + 1; tok = tok:sub(1, -2) end

                    local cols = M.SplitByChar(tok, "~")
                    local function col(idx) return M.DecodeField(cols[idx] or "") end
                    local cond = { type = col(1), negate = col(2) == "1" }

                    local spellMode = col(3)
                    local cSpellID = tonumber(col(4))
                    if spellMode == "this" then
                        cond.spell = "this"
                    elseif spellMode == "num" and cSpellID then
                        cond.spell = cSpellID
                        cond.targetID = cSpellID
                    end

                    local resource, operator, plugin = col(5), col(6), col(7)
                    local value, luaCode = tonumber(col(8)), col(9)
                    if resource ~= "" then cond.resource = resource end
                    if operator ~= "" then cond.operator = operator end
                    if plugin ~= "" then cond.plugin = plugin end
                    if value ~= nil then cond.value = value end
                    if luaCode ~= "" then cond.luaCode = luaCode end
                    if junction ~= nil then cond.junction = junction end
                    if lp > 0 then cond.lparen = lp end
                    if rp > 0 then cond.rparen = rp end

                    rule.conditions[#rule.conditions + 1] = cond
                end
            end
            M.NormalizeRuleParens(rule.conditions)
            out[#out + 1] = rule
        end
    end

    return out
end

function M.SerializeAllTabsForExport(specID, tabsRules, count)
    local headerParts = { "SBASGUI_MULTI", "1", tostring(count) }
    for t = 1, count do
        headerParts[#headerParts + 1] = M.EncodeField(M.GetTabName(specID, t))
    end
    local lines = { table.concat(headerParts, ";") }
    for t = 1, count do
        lines[#lines + 1] = M.SerializeRulesForExportV2(specID, tabsRules[t] or {})
    end
    return table.concat(lines, "\n")
end

function M.DeserializeAllTabsFromExport(text, expectedSpecID)
    local trimmed = (text or ""):match("^%s*(.-)%s*$") or ""
    if not trimmed:match("^SBASGUI_MULTI") then return nil end

    local lines = {}
    for ln in (trimmed .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = ln end

    local headerLine = lines[1] or ""
    local headerParts = (headerLine:sub(14, 14) == ";") and M.SplitByChar(headerLine, ";") or M.SplitPipe(headerLine)
    local exportTabCount = tonumber(headerParts[3]) or 1

    local names = {}
    for t = 1, exportTabCount do
        local raw = M.DecodeField(headerParts[3 + t] or "")
        names[t] = (raw ~= "") and raw or ((t == 1) and "Rotation" or ("Tab " .. t))
    end

    local tabs = {}
    for t = 1, exportTabCount do
        local line = lines[1 + t] or ""
        local rules, err = M.DeserializeRulesFromExportV2(line, expectedSpecID)
        if not rules then return nil, ("Tab " .. t .. ": " .. tostring(err)) end
        tabs[t] = { rules = rules, name = names[t] }
    end
    return tabs
end

function M.DeserializeRulesFromExport(text, expectedSpecID)
    return M.DeserializeRulesFromExportV2((text or ""):match("^%s*(.-)%s*$") or "", expectedSpecID)
end
