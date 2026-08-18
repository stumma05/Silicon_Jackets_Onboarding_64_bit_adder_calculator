verdiWindowResize -win $_vdCoverage_1 "0" "29" "1920" "991"
gui_set_pref_value -category {coveragesetting} -key {geninfodumping} -value 1
gui_exclusion -set_force true
verdiSetFont  -font  {DejaVu Sans}  -size  11
verdiSetFont -font "DejaVu Sans" -size "11"
gui_assert_mode -mode flat
gui_class_mode -mode hier
gui_excl_mgr_flat_list -on  0
gui_covdetail_select -id  CovDetail.1   -name   Line
verdiWindowWorkMode -win $_vdCoverage_1 -coverageAnalysis
gui_open_cov  -hier simv.vdb -testdir {} -test {simv/test} -merge MergedTest -db_max_tests 10 -sdc_level 1 -fsm transition
verdiSetActWin -dock widgetDock_<CovDetail>
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} calc_tb_top
verdiSetActWin -dock widgetDock_<Summary>
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} calc_tb_top.my_calc
gui_exclusion_file -load -file { /nethome/stumma8/New_DV_Onboarding/sim/behav/exclusions.el }
vdCovExit -noprompt
