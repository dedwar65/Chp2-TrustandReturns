(TeX-add-style-hook
 "data"
 (lambda ()
   (TeX-run-style-hooks
    "../../Code/Descriptive/Tables/income_mean_by_year_real_win"
    "../../Code/Descriptive/Tables/income_final_tabstat"
    "../../Code/Descriptive/Tables/income_mean_by_agegroup_real_win_2022"
    "../../Code/Descriptive/Tables/income_mean_by_educgroup_real_win"
    "../../Code/Descriptive/Tables/trust_corr"
    "../../Code/Descriptive/Tables/trust_pca_loadings"
    "../../Code/Descriptive/Tables/demographics_general"
    "../../Code/Descriptive/Tables/demographics_other"
    "../../Code/Descriptive/Tables/trust_controls_corr")
   (LaTeX-add-labels
    "sec:data"))
 :latex)

