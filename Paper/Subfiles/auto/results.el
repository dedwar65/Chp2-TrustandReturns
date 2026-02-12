(TeX-add-style-hook
 "results"
 (lambda ()
   (TeX-run-style-hooks
    "../../Code/Regressions/Trust/trust_reg_general"
    "../../Code/Regressions/Income/Labor/income_trust_general_log"
    "../../Code/Regressions/Income/Labor/income_trust_general_ihs"
    "../../Code/Regressions/Income/Total/income_trust_general_log"
    "../../Code/Regressions/Income/Total/income_trust_general_ihs"
    "../../Code/Regressions/Returns/Core/returns_r1_trust_general_win"
    "../../Code/Regressions/Returns/Core/returns_r1_trust_general"
    "../../Code/Regressions/Returns/Core+res/returns_r4_trust_general_win"
    "../../Code/Regressions/Returns/Core+res/returns_r4_trust_general"
    "../../Code/Regressions/Returns/Net wealth/returns_r5_trust_general_win"
    "../../Code/Regressions/Returns/Net wealth/returns_r5_trust_general")
   (LaTeX-add-labels
    "sec:results"))
 :latex)

