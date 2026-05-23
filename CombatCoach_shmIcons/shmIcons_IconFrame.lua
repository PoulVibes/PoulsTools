-- shmIcons_IconFrame.lua
-- BuildIconFrame orchestration.

function BuildIconFrame(globalID, db)
    local frame = CreateFrame("Frame", "shmIconsFrame_" .. globalID, UIParent, "BackdropTemplate")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_SIZE, MIN_SIZE, MAX_SIZE, MAX_SIZE)
    frame:SetClampedToScreen(true)
    frame:SetSize(db.size, db.size)
    frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    frame:SetFrameStrata(db.strata or "MEDIUM")

    local iconTex = frame:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints(frame)
    iconTex:SetTexture(134400)

    local cd = CreateFrame("Cooldown", "shmIconsCD_" .. globalID, frame, "CooldownFrameTemplate")
    cd:SetAllPoints(frame)
    cd:SetFrameLevel(frame:GetFrameLevel() + 2)
    cd:SetReverse(false)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(true)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(false)
    ScaleText(cd, nil, db.size)

    local cd2 = CreateFrame("Cooldown", "shmIconsCD2_" .. globalID, frame, "CooldownFrameTemplate")
    cd2:SetAllPoints(frame)
    cd2:SetFrameLevel(frame:GetFrameLevel() + 3)
    cd2:SetReverse(false)
    cd2:SetDrawSwipe(false)
    cd2:SetDrawEdge(true)
    cd2:SetDrawBling(false)
    cd2:SetHideCountdownNumbers(true)

    local labelFrame = CreateFrame("Frame", nil, frame)
    labelFrame:SetAllPoints(frame)
    labelFrame:SetFrameLevel(cd2:GetFrameLevel() + 1)

    local stackLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stackLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO)), FONT_FLAGS)
    stackLabel:SetTextColor(STACK_TEXT_R, STACK_TEXT_G, STACK_TEXT_B, 1)
    stackLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    stackLabel:SetJustifyH("RIGHT")
    stackLabel:Hide()

    local hotkeyLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hotkeyLabel:SetFont(FONT_PATH, math.max(FONT_MIN_PT, math.floor(db.size * FONT_RATIO * 0.4)), FONT_FLAGS)
    hotkeyLabel:SetTextColor(1, 1, 1, 1)
    hotkeyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    hotkeyLabel:SetJustifyH("LEFT")
    hotkeyLabel:Hide()

    local glow = BuildGlow(frame, db.size)

    local usableOverlay = frame:CreateTexture(nil, "OVERLAY")
    usableOverlay:SetAllPoints(frame)
    usableOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    usableOverlay:SetVertexColor(0, 0, 0, 0)

    local resizeHandle = CreateFrame("Button", nil, frame)
    local initHandleSz = math.max(10, math.floor(db.size * 0.25))
    resizeHandle:SetSize(initHandleSz, initHandleSz)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 10)
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripTex:SetAllPoints(resizeHandle)
    resizeHandle:Hide()

    local icon = {
        globalID = globalID,
        db = db,
        frame = frame,
        iconTex = iconTex,
        cd = cd,
        cd2 = cd2,
        stackLabel = stackLabel,
        hotkeyLabel = hotkeyLabel,
        displayHotkey = false,
        currentTextureID = nil,
        glow = glow,
        usableOverlay = usableOverlay,
        resizeHandle = resizeHandle,
        glowEnabled = db.glow_enabled,
        groupDragFrame = nil,
    }

    shmIcons_AttachIconSizeHandler(icon, db, cd, stackLabel, frame, resizeHandle)
    shmIcons_AttachIconDragHandlers(icon, globalID, db, cd, stackLabel, frame)
    shmIcons_AttachIconResizeHandlers(icon, db, cd, frame, resizeHandle)

    ApplyLockState(icon)
    return icon
end
