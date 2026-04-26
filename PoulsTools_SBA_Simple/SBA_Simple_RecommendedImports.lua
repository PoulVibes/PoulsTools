-- SBA_Simple_RecommendedImports.lua
-- Curated per-spec recommended GUI imports used by the SBA_Simple submenu.

_G.SBAS_RecommendedImports = {
    [269] = {
        name = "Windwalker Monk",
        source = "Working per Spec Overrides/WW Monk Override.txt",
        importText = [[SBASGUI2|1|269;R,152175,Whirling Dragon Punch,(talented~0~num~152175~~~~~,&&reactive_enabled~0~this~~~~~~,&&on_cd~0~this~~~~~~,&&(on_cd~1~num~113656~~~~~,&&on_cd~1~num~107428~~~~~)),|sba_suggests~0~this~~~~~~;R,100780,Tiger Palm,(plugin~1~this~~~~zenith~~,|(plugin~0~this~~~~zenith~~,&&talented~1~num~1249832~~~~~)),&&resource~0~this~~chi~<=~~3~,&&plugin~1~this~~~~bok_proc~~,&&(sba_suggests~1~this~~~~~~,&&resource~0~this~~energy~>=~~100~),&&last_combo_eq~1~this~~~~~~;R,113656,Fists of Fury,(on_cd~0~this~~~~~~,&&usable~0~this~~~~~~),|sba_suggests~0~this~~~~~~;R,467307,Rushing Wind Kick,(usable~0~this~~~~~~,&&plugin~0~this~~~~rwk_proc~~),|sba_suggests~0~this~~~~~~;R,101546,Spinning Crane Kick,plugin~1~this~~~~zenith~~,&&plugin~0~this~~~~docj_proc~~,&&plugin~0~this~~~<~docj_proc~4~,&&plugin~1~this~~~~bok_proc~~,&&last_combo_eq~1~this~~~~~~;R,107428,Rising Sun Kick,(on_cd~0~this~~~~~~,|sba_suggests~0~this~~~~~~),&&usable~0~this~~~~~~;R,1272696,Zenith Stomp,plugin~0~this~~~~zenith~~,&&usable~0~this~~~~~~;R,100784,Blackout Kick,plugin~0~this~~~~zenith~~,&&talented~0~num~1249832~~~~~,&&last_combo_eq~1~this~~~~~~;R,100780,Tiger Palm,last_combo_eq~1~this~~~~~~,&&(on_cd~0~num~113656~~~~~,&&usable~1~num~113656~~~~~),&&(on_cd~0~num~107428~~~~~,|usable~1~num~107428~~~~~);R,100784,Blackout Kick,(plugin~0~this~~~~bok_proc~~,|plugin~0~this~~~~zenith~~),&&last_combo_eq~1~this~~~~~~;R,101546,Spinning Crane Kick,((resource~0~this~~chi~>~~3~,&&plugin~0~this~~~~zenith~~),|plugin~0~this~~~~docj_proc~~),&&last_combo_eq~1~this~~~~~~;R,100784,Blackout Kick,last_combo_eq~1~this~~~~~~,&&(resource~0~this~~chi~>~~1~,|(resource~0~this~~chi~==~~1~,&&last_combo_eq~0~num~100780~~~~~));R,101546,Spinning Crane Kick,target_count~0~this~~~>=~~3~,&&last_combo_eq~1~this~~~~~~,&&on_cd~1~num~113656~~~~~;R,100780,Tiger Palm,last_combo_eq~1~this~~~~~~;R,117952,Crackling Jade Lightning,last_combo_eq~0~num~100780~~~~~;R,1229376,Single-Button Assistant]],
    },
}

_G.SBAS_GetRecommendedImportForSpec = function(specID)
    local all = _G.SBAS_RecommendedImports
    return (all and all[specID]) or nil
end
