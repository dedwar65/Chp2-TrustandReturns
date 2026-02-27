(TeX-add-style-hook
 "appendix2"
 (lambda ()
   (LaTeX-add-labels
    "tab:income_mean_by_year_real_win"
    "tab:income_mean_by_agegroup_real_win_2022"
    "tab:trust_corr"
    "tab:trust_pca_loadings"
    "tab:finlit_r5_panel1"
    "tab:finlit_r5_panel2"
    "tab:fin_trust_avg_cross_section"
    "tab:fin_trust_avg_avg"
    "tab:fin_trust_pc1_wgen_cross_section"
    "tab:fin_trust_pc1_wgen_panel1"
    "tab:fin_trust_pc1_wgen_panel2"
    "tab:fin_trust_pc2_wgen_cross_section"
    "tab:fin_trust_pc2_wgen_panel2")
   (LaTeX-add-environments
    '("table" LaTeX-env-args ["argument"] 0)))
 :latex)

