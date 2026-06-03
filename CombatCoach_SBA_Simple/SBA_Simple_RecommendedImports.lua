-- SBA_Simple_RecommendedImports.lua
-- Curated per-spec recommended GUI imports used by the SBA_Simple submenu.

_G.SBAS_RecommendedImports = {
    [253] = {
        name = "Beast Mastery Hunter",
        source = "Working per Spec Overrides/BM Hunter Override.txt",
        importText = [[SBASGUI_MULTI;1;1;Rotation
SBASGUI2|1|253;R,883,Call Pet 1,has_pet~1~this~~~~~~;R,982,Revive Pet,pet_alive~1~this~~~~~~;R,217200,Barbed Shot,(on_cd~1~num~19574~~~~~,&&plugin~0~this~~~<=~tt_253_2~3~),&&has_stacks~0~this~~~~~>=1~;R,19574,Bestial Wrath,on_cd~0~this~~~~~~;R,1264359,Wild Thrash,on_cd~0~this~~~~~~,&&target_count~0~this~~~>=~~2~;R,34026,Kill Command,((has_stacks~0~this~~~~~>=1~,|plugin~0~this~~~>~tt_253_2~2~),&&(plugin~0~this~~~~tt_253_3~~,&&plugin~0~this~~~~dynact_253_34026~~)),&&last_ability_eq~1~this~~~~~~,&&usable~0~this~~~~~~;R,466930,Black Arrow,plugin~0~this~~~~tt_253_4~~,&&on_cd~0~this~~~~~~,&&plugin~0~this~~~~dynact_253_466930~~,&&talented~0~this~~~~~~;R,392060,Wailing Arrow,plugin~0~this~~~<~tt_253_4~4~,&&plugin~0~this~~~~dynact_253_392060~~,&&on_cd~0~this~~~~~~,&&talented~0~this~~~~~~;R,34026,Kill Command,on_cd~0~this~~~~~~,&&last_ability_eq~1~this~~~~~~,&&usable~0~this~~~~~~;R,217200,Barbed Shot,has_stacks~0~this~~~~~>=1~,&&resource~0~this~~chi~<~~75~;R,466930,Black Arrow,on_cd~0~this~~~~~~,&&reactive_enabled~0~this~~~~~~,&&talented~0~this~~~~~~;R,193455,Cobra Shot,usable~0~this~~~~~~,&&(plugin~0~this~~~~dynact_253_193455~~,|last_ability_eq~0~num~34026~~~~~,|has_stacks~0~num~34026~~~~0~);R,1229376,Single-Button Assistant]],
    },
    [255] = {
        name = "Survival Hunter",
        source = "Working per Spec Overrides/Survival Hunter Override.txt",
        importText = [[SBASGUI_MULTI;1;3;Rotation;Cooldowns;Interrupt
SBASGUI2|1|255;R,259495,Wildfire Bomb,(has_stacks~0~this~~~~~max~,|sba_suggests~0~this~~~~~~,|plugin~0~this~~~~dynbuff_255_1253599~~),&&plugin~0~this~~~~tt_255_1~~,&&has_stacks~0~this~~~~~>=1~;R,1261193,Boomstick,plugin~0~this~~~~tt_255_1~~,&&on_cd~0~this~~~~~~,&&usable~0~this~~~~~~;R,259489,Kill Command,plugin~0~this~~~<=~tt_stacks_255_1~1~,&&on_cd~0~this~~~~~~;R,1264949,Moonlight Chakram,plugin~0~this~~~~dynact_255_1264949~~;R,1251592,Flamefang Pitch,talented~0~this~~~~~~;R,1262343,Raptor Swipe,plugin~0~this~~~~dynbuff_255_1259003~~,&&plugin~0~this~~~~tt_255_1~~,&&usable~0~this~~~~~~;R,186270,Raptor Strike,plugin~1~this~~~~dynbuff_255_1259003~~,&&usable~0~this~~~~~~;R,259489,Kill Command
SBASGUI2|1|255;R,1250646,Takedown
SBASGUI2|1|255;R,187707,Muzzle,on_cd~0~this~~~~~~,&&talented~0~this~~~~~~,&&usable~0~this~~~~~~;R,19577,Intimidation,usable~0~this~~~~~~,&&on_cd~0~this~~~~~~,&&usable~0~this~~~~~~;R,187707,Muzzle,talented~0~this~~~~~~;R,19577,Intimidation,talented~0~this~~~~~~]],
    },
    [269] = {
        name = "Windwalker Monk",
        source = "Working per Spec Overrides/WW Monk Override.txt",
        importText = [[SBASGUI_MULTI;1;2;Rotation;Cooldowns
SBASGUI2|1|269;R,113656,Fists of Fury,plugin~0~this~~~<~tt_269_1~2~,&&talented~0~num~443294~~~~~,&&on_cd~0~this~~~~~~,&&usable~0~this~~~~~~;R,152175,Whirling Dragon Punch,(talented~0~num~152175~~~~~,&&reactive_enabled~0~this~~~~~~,&&on_cd~0~this~~~~~~,&&(on_cd~1~num~113656~~~~~,&&on_cd~1~num~107428~~~~~)),|sba_suggests~0~this~~~~~~;R,100780,Tiger Palm,(plugin~1~this~~~~tt_269_2~~,|(plugin~0~this~~~~tt_269_2~~,&&talented~1~num~1249832~~~~~)),&&resource~0~this~~chi~<=~~3~,&&plugin~1~this~~~~dynact_269_100784~~,&&(sba_suggests~1~this~~~~~~,&&resource~0~this~~energy~>=~~100~),&&last_combo_eq~1~this~~~~~~,&&(plugin~1~this~~~~tt_269_2~~,|usable~1~num~1272694~~~~~);R,113656,Fists of Fury,(on_cd~0~this~~~~~~,&&usable~0~this~~~~~~),|sba_suggests~0~this~~~~~~;R,467307,Rushing Wind Kick,(usable~0~this~~~~~~,&&plugin~0~this~~~~dynact_269_467307~~),|sba_suggests~0~this~~~~~~;R,101546,Spinning Crane Kick,plugin~1~this~~~~tt_269_2~~,&&plugin~0~this~~~~dynact_269_101546~~,&&plugin~0~this~~~<=~dynact_269_101546~4~,&&plugin~1~this~~~~dynact_269_100784~~,&&last_combo_eq~1~this~~~~~~;R,107428,Rising Sun Kick,on_cd~0~this~~~~~~,&&usable~0~this~~~~~~;R,1272696,Zenith Stomp,plugin~0~this~~~~tt_269_2~~,&&usable~0~this~~~~~~;R,100784,Blackout Kick,plugin~0~this~~~~tt_269_2~~,&&talented~0~num~1249832~~~~~,&&last_combo_eq~1~this~~~~~~;R,100780,Tiger Palm,last_combo_eq~1~this~~~~~~,&&(on_cd~0~num~113656~~~~~,&&usable~1~num~113656~~~~~),&&(on_cd~0~num~107428~~~~~,|usable~1~num~107428~~~~~);R,100784,Blackout Kick,(plugin~0~this~~~~dynact_269_100784~~,|plugin~0~this~~~~tt_269_2~~),&&last_combo_eq~1~this~~~~~~;R,101546,Spinning Crane Kick,((resource~0~this~~chi~>~~3~,&&plugin~0~this~~~~tt_269_2~~),|plugin~0~this~~~~dynact_269_101546~~),&&last_combo_eq~1~this~~~~~~,&&usable~0~this~~~~~~;R,100784,Blackout Kick,last_combo_eq~1~this~~~~~~,&&(resource~0~this~~chi~>~~1~,|(resource~0~this~~chi~==~~1~,&&last_combo_eq~0~num~100780~~~~~));R,101546,Spinning Crane Kick,target_count~0~this~~~>=~~3~,&&last_combo_eq~1~this~~~~~~,&&on_cd~1~num~113656~~~~~,&&usable~0~this~~~~~~;R,100780,Tiger Palm,last_combo_eq~1~this~~~~~~;R,117952,Crackling Jade Lightning,last_combo_eq~0~num~100780~~~~~;R,1229376,Single-Button Assistant
SBASGUI2|1|269;R,1249625,Zenith,(talented~0~num~123904~~~~~,&&on_cd~0~this~~~~~~,&&on_cd~0~num~123904~~~~~),|on_cd~0~this~~~~~~;R,123904,Invoke Xuen%2C the White Tiger,talented~0~this~~~~~~,&&on_cd~0~this~~~~~~;R,443028,Celestial Conduit,talented~0~this~~~~~~,&&on_cd~0~this~~~~~~;R,1249625,Zenith]],
    },
}

_G.SBAS_GetRecommendedImportForSpec = function(specID)
    local all = _G.SBAS_RecommendedImports
    return (all and all[specID]) or nil
end
