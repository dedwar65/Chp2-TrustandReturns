(TeX-add-style-hook
 "extensions"
 (lambda ()
   (TeX-run-style-hooks
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
    "sec:exts"))
 :latex)

