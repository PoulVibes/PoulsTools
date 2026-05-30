-- CombatCoach_Profiles_Menu.lua
-- Menu integration: registers the Profiles submenu under CombatCoach.

local CC       = CombatCoach
local Profiles = CombatCoach.Profiles

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
        desc      = "Export and import CombatCoach layout for the current spec.",
        OnBuildUI = function(parent)
            local exportBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            exportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
            exportBtn:SetSize(130, 24)
            exportBtn:SetText("Export Spec")
            exportBtn:SetScript("OnClick", function()
                Profiles:ShowExportFrame()
            end)

            local importBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
            importBtn:SetSize(130, 24)
            importBtn:SetText("Import Spec")
            importBtn:SetScript("OnClick", function()
                Profiles:ShowImportFrame()
            end)
        end,
    })
end
