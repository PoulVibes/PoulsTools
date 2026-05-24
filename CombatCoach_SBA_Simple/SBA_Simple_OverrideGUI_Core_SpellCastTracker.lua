-- SBA_Simple_OverrideGUI_Core_SpellCastTracker.lua
-- Tracks seen successful player spell casts by spec.

local M = _G.SBAS_GUI or {}
_G.SBAS_GUI = M

function M.InitSeenCastTracker(state, deps)
    state = state or {}
    if state._initialized then
        return state
    end

    local seenCastSpells = state.seenCastSpells or {}
    state.seenCastSpells = seenCastSpells

    local function CastsDB()
        SBA_SimpleDB = SBA_SimpleDB or {}
        SBA_SimpleDB.castsSeen = SBA_SimpleDB.castsSeen or {}
        return SBA_SimpleDB.castsSeen
    end

    local function LoadCastsForSpec()
        local specID = deps.currentSpecID()
        wipe(seenCastSpells)
        if specID == 0 then return end
        local saved = CastsDB()[specID]
        if saved then
            for spellID, entry in pairs(saved) do
                seenCastSpells[spellID] = entry
            end
        end
    end

    state.resetSeenCastsForCurrentSpec = function()
        local specID = deps.currentSpecID()
        wipe(seenCastSpells)
        if specID ~= 0 then
            CastsDB()[specID] = {}
        end
    end

    local castTrackFrame = CreateFrame("Frame")
    castTrackFrame:RegisterEvent("PLAYER_LOGIN")
    castTrackFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    castTrackFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    castTrackFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            LoadCastsForSpec()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit ~= "player" or not spellID or seenCastSpells[spellID] then return end
            local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            if not info or not info.name then return end

            if not info.name:find("^Call ") then
                local baseID = C_SpellBook.FindBaseSpellByID and C_SpellBook.FindBaseSpellByID(spellID)
                if not baseID or baseID == spellID then
                    return
                end
                if not IsPlayerSpell(baseID) then
                    return
                end
                local isPassive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)
                if isPassive then return end
            end

            local entry = {
                name = info.name,
                spellID = spellID,
                texture = info.originalIconID or "Interface\\Icons\\INV_Misc_QuestionMark",
            }
            seenCastSpells[spellID] = entry
            local curSpec = deps.currentSpecID()
            if curSpec ~= 0 then
                local db = CastsDB()
                db[curSpec] = db[curSpec] or {}
                db[curSpec][spellID] = entry
            end
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            LoadCastsForSpec()
        end
    end)

    state._initialized = true
    return state
end
