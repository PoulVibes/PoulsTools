if not PoulsTools then return end

EnemyCountTrackerDB = EnemyCountTrackerDB or {}

local function OnBuildUI(parent)
    local W = PoulsTools.Widgets
    if not W then
        local note = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        note:SetText("PoulsTools.Widgets missing. Install PoulsTools to configure EnemyCountTracker here.")
        note:SetTextColor(1, 0.8, 0.2, 1)
        return
    end

    local anchor = parent
    local y = 0

    local div, dy = W:SectionHeader(parent, anchor, y, "PoulsTools_EnemyCountTracker")
    anchor = div
    y = dy

    anchor = W:Checkbox(parent, anchor, y, "Enable", "Master toggle for this tracker.",
        function() return EnemyCountTrackerDB.enabled ~= false end,
        function(v)
            if EnemyCountTracker_SetEnabled then
                EnemyCountTracker_SetEnabled(v)
            else
                EnemyCountTrackerDB.enabled = v
            end
        end
    )
    y = -6

    anchor = W:Checkbox(parent, anchor, y, "Only Count During Player Combat", "When on, count is forced to 0 while you are out of combat.",
        function() return EnemyCountTrackerDB.onlyInCombat ~= false end,
        function(v)
            if EnemyCountTracker_SetOnlyInCombat then
                EnemyCountTracker_SetOnlyInCombat(v)
            else
                EnemyCountTrackerDB.onlyInCombat = v
            end
        end
    )
    y = -6

    anchor = W:Checkbox(parent, anchor, y, "Require Player/Pet Threat", "When on, enemy must be on your threat table (or your pet's).", 
        function() return EnemyCountTrackerDB.requireThreat ~= false end,
        function(v)
            if EnemyCountTracker_SetRequireThreat then
                EnemyCountTracker_SetRequireThreat(v)
            else
                EnemyCountTrackerDB.requireThreat = v
            end
        end
    )
    y = -6

    anchor = W:Checkbox(parent, anchor, y, "Include Pet Threat", "Counts enemies if your pet has threat even when you do not.",
        function() return EnemyCountTrackerDB.includePetThreat ~= false end,
        function(v)
            if EnemyCountTracker_SetIncludePetThreat then
                EnemyCountTracker_SetIncludePetThreat(v)
            else
                EnemyCountTrackerDB.includePetThreat = v
            end
        end
    )
    y = -6

    anchor = W:Checkbox(parent, anchor, y, "Show Icon At Zero", "Keep icon visible when count is 0.",
        function() return EnemyCountTrackerDB.showWhenZero ~= false end,
        function(v)
            if EnemyCountTracker_SetShowWhenZero then
                EnemyCountTracker_SetShowWhenZero(v)
            else
                EnemyCountTrackerDB.showWhenZero = v
            end
        end
    )
    y = -8

    local countLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    countLabel:SetTextColor(unpack(W.colors.text))
    countLabel:SetText("Tracked enemies: 0")

    local buttonAnchor = countLabel

    local refreshBtn = W:Button(parent, buttonAnchor, -8, "Refresh Now", function()
        if EnemyCountTracker_ForceRefresh then
            EnemyCountTracker_ForceRefresh()
        end
        if EnemyCountTracker_GetCount then
            countLabel:SetText("Tracked enemies: " .. tostring(EnemyCountTracker_GetCount() or 0))
        end
    end)

    local lockBtn = W:Button(parent, refreshBtn, -8, "Toggle Icon Lock", function()
        local locked = shmIcons:ToggleLock()
        print("shmIcons: All icons " .. (locked and "Locked." or "Unlocked."))
    end)

    W:Button(parent, lockBtn, -8, "Print Count", function()
        if EnemyCountTracker_GetCount then
            print("EnemyCountTracker: " .. tostring(EnemyCountTracker_GetCount() or 0) .. " tracked enemy nameplates.")
        end
    end)

    parent:HookScript("OnShow", function()
        if EnemyCountTracker_GetCount then
            countLabel:SetText("Tracked enemies: " .. tostring(EnemyCountTracker_GetCount() or 0))
        end
    end)
end

PoulsTools.Menu:RegisterAddon({
    name = "PoulsTools_EnemyCountTracker",
    id = "PoulsTools_EnemyCountTracker",
    desc = "Nameplate-based hostile enemy count.",
    version = "1.0.0",
    icon = "Interface\\Icons\\ability_hunter_markedshot",
    parentId = "PoulsTools_shmIcons",
    OnBuildUI = OnBuildUI,
})
