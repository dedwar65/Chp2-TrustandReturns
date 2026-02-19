(TeX-add-style-hook
 "results"
 (lambda ()
   (TeX-run-style-hooks
    "../../Code/Regressions/Trust/trust_reg_general"
    "../../Code/Regressions/Income/Labor/income_trust_general_ihs"
    "../../Code/Regressions/Average/Income/Labor/income_trust_general_deflwin_ihs"
    "../../Code/Regressions/Income/Total/income_trust_general_ihs"
    "../../Code/Regressions/Average/Income/Total/income_trust_general_deflwin_ihs"
    "../../Code/Regressions/Returns/Net wealth/returns_r5_trust_general_win"
    "../../Code/Regressions/Panel/panel_reg_r5_win"
    "../../Code/Regressions/Panel/panel_reg_r5_spec2_win"
    "../../Code/Regressions/Panel/panel_reg_r5_spec3_win"
    "../../Code/Regressions/Average/Returns/Net wealth/returns_r5_trust_general_avg_win"
    "../../Code/Regressions/Panel/panel_fe_on_tinv_r5_win")
   (LaTeX-add-labels
    "sec:results"))
 :latex)

