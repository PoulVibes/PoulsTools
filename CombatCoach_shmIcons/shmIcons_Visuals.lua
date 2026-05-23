-- shmIcons_Visuals.lua
-- Text scaling and glow helpers.

function ScaleText(cd, stackLabel, size)
    local coach = math.max(FONT_MIN_PT, math.floor(size * FONT_RATIO))
    for _, region in next, { cd:GetRegions() } do
        if region:GetObjectType() == "FontString" then
            region:SetFont(FONT_PATH, coach, FONT_FLAGS)
        end
    end
    if stackLabel then stackLabel:SetFont(FONT_PATH, coach, FONT_FLAGS) end
end

function BuildGlow(frame, iconSize)
    local g = CreateFrame("Frame", nil, frame)
    g:SetAllPoints(frame)
    g:SetFrameLevel(frame:GetFrameLevel() + 6)
    g.textures = {}

    local off = iconSize * 0.1875
    for i, c in ipairs(CORNER_COORDS) do
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        t:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
        t:SetSize(iconSize * 1.4, iconSize * 1.4)
        t:SetPoint(c.point, frame, c.point, c.x * off, c.y * off)

        local ag = t:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(0.3)
        a:SetToAlpha(1.0)
        a:SetDuration(0.6)
        a:SetOrder(1)
        ag:Play()

        g.textures[i] = t
    end

    g:Hide()
    return g
end

function ResizeGlow(glow, frame, iconSize)
    local off     = iconSize * 0.1875
    local texSize = iconSize * 1.4
    for i, c in ipairs(CORNER_COORDS) do
        local t = glow.textures[i]
        if t then
            t:SetSize(texSize, texSize)
            t:ClearAllPoints()
            t:SetPoint(c.point, frame, c.point, c.x * off, c.y * off)
        end
    end
end
