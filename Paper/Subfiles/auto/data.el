(TeX-add-style-hook
 "data"
 (lambda ()
   (TeX-run-style-hooks
    "../../Code/Descriptive/Tables/income_mean_by_year_real_win"
    "../../Code/Descriptive/Tables/income_final_tabstat"
    "../../Code/Descriptive/Tables/income_growth_tabstat"
    "../../Code/Descriptive/Tables/income_mean_by_agegroup_real_win_2022"
    "../../Code/Descriptive/Tables/income_mean_by_educgroup_real_win"
    "../../Code/Descriptive/Tables/trust_corr"
    "../../Code/Descriptive/Tables/trust_pca_loadings"
    "../../Code/Descriptive/Tables/demographics_general"
    "../../Code/Descriptive/Tables/demographics_other"
    "../../Code/Descriptive/Tables/trust_controls_corr"
    "../../Code/Descriptive/Tables/finlit_summary"
    "../../Code/Descriptive/Tables/finlit_trust_corr"
    "../../Code/Descriptive/Tables/iv_trust_corr"
    "../../Code/Descriptive/Tables/region_group_counts_by_year"
    "../../Code/Descriptive/Tables/bin_counts_regionpop_2020"
    "../../Code/Descriptive/Tables/bin_counts_regionpop3_2020"
    "../../Code/Descriptive/Tables/trust_mean_by_region_2020"
    "../../Code/Descriptive/Tables/trust_mean_by_population_2020"
    "../../Code/Descriptive/Tables/trust_mean_by_population3_2020"
    "../../Code/Descriptive/Tables/trust_mean_by_regionpop3_2020")
   (LaTeX-add-labels
    "sec:data"))
 :latex)

