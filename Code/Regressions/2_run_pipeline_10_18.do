* 2_run_pipeline_10_18.do
* Run build panel and all regression files (10–18) in order.
* Order: 10 build panel -> 11 reg trust -> 12 reg income trust -> 13 reg returns trust -> 14 panel reg ret -> 15 panel reg ret shares -> 16 panel reg fe -> 17 avg income trust -> 18 avg returns trust

clear
set more off

* Resolve BASE_PATH and load config
capture confirm global BASE_PATH
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]HRS$") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]Raw data$") {
        cd ..
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]Code$") {
        cd ..
    }
    global BASE_PATH "`c(pwd)'"
}

do "${BASE_PATH}/Code/Raw data/00_config.do"

* 10: Build long panel (required for 14, 15, 16)
do "${BASE_PATH}/Code/Processing/10_build_panel.do"

* 11: Reg trust (cross-sectional)
do "${BASE_PATH}/Code/Regressions/11_reg_trust.do"

* 12: Reg income on trust
do "${BASE_PATH}/Code/Regressions/12_reg_income_trust.do"

* 13: Reg returns on trust
do "${BASE_PATH}/Code/Regressions/13_reg_returns_trust.do"

* 14: Panel reg ret (baseline pooled OLS)
do "${BASE_PATH}/Code/Regressions/14_panel_reg_ret.do"

* 15: Panel reg ret shares (Spec 2: share×year)
do "${BASE_PATH}/Code/Regressions/15_panel_reg_ret_shares.do"

* 16: Panel reg fe (Spec 3: individual FE)
do "${BASE_PATH}/Code/Regressions/16_panel_reg_fe.do"

* 17: Avg income on trust (defl wins avg + IHS; avg of IHS)
do "${BASE_PATH}/Code/Regressions/17_reg_income_avg_trust.do"

* 18: Avg returns on trust
do "${BASE_PATH}/Code/Regressions/18_reg_returns_avg_trust.do"

display "2_run_pipeline_10_18: Completed 10–18."
