(TeX-add-style-hook
 "data"
 (lambda ()
   (TeX-run-style-hooks
    "../../Code/Descriptive/Tables/demographics_general_tabular"
    "../../Code/Descriptive/Tables/demographics_other_tabular")
   (LaTeX-add-labels
    "sec:data"
    "fig:income_over_time"
    "tab:income_final_tabstat"
    "fig:income_by_agegroup_2020"
    "tab:income_mean_by_educgroup_real_win"
    "fig:cg_core_assets_panels"
    "fig:cg_ira_by_year"
    "fig:cg_residential_panels"
    "fig:wealth_mean_by_year_panels"
    "fig:lorenz_income_2020"
    "fig:lorenz_wealth_panels_2022"
    "fig:share_holdings_assets_liabilities"
    "fig:share_assets_debt_year"
    "fig:asset_shares_income_panels_2022"
    "fig:debt_shares_income_panels_2022"
    "fig:returns_mean_by_year_panels"
    "total_income_real_win_iqr_by_wealthpct_2020"
    "tab:trust_general_demographics_panels"
    "tab:demographics_panels"))
 :latex)

