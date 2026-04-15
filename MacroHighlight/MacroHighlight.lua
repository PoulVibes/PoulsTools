-- Configuration
local ZENITH_ICON = C_Spell.GetSpellTexture(1249625)
local BARS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", 
    "MultiBar6Button", "MultiBar7Button"
}




local function UpdateMacroView()
    local _, instanceType = GetInstanceInfo()
    local isInRaid = (instanceType == "raid")
    local shouldShowWarning = false

    for _, barName in ipairs(BARS) do
        for i = 1, 12 do
            local btn = _G[barName..i]
            if btn and btn.action then
                local actionType = GetActionInfo(btn.action)
                local currentTexture = GetActionTexture(btn.action)
                local isZenith = (actionType == "macro" and currentTexture == ZENITH_ICON)

                -- 1. Manage the Light Blue Outline
                if not btn.macroViewBorder then
                    btn.macroViewBorder = btn:CreateTexture(nil, "OVERLAY", nil, 7)
                    btn.macroViewBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                    btn.macroViewBorder:SetBlendMode("DISABLE")
                    btn.macroViewBorder:SetAllPoints(btn)
                    btn.macroViewBorder:SetVertexColor(1.0, 0.5, 0.5)
					
					local ag = btn.macroViewBorder:CreateAnimationGroup()
					ag:SetLooping("BOUNCE")
					local a = ag:CreateAnimation("Alpha")
					a:SetFromAlpha(0.3)
					a:SetToAlpha(1.0)
					a:SetDuration(0.6)
					a:SetOrder(1)
					ag:Play()
					
                end

                if isZenith then
                    btn.macroViewBorder:Show()
                else
                    btn.macroViewBorder:Hide()
                end
            end
        end
    end

    
end

-- Event Listener
local f = CreateFrame("Frame")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ACTIONBAR_UPDATE_STATE")
f:RegisterEvent("UPDATE_BINDINGS") -- Triggers if you change hotkeys
f:SetScript("OnEvent", UpdateMacroView)
