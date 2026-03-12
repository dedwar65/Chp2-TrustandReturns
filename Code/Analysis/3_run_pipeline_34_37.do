* 3_run_pipeline_34_37.do
* Run analysis scripts 32–38 in order.
* Order: 32–33 returns control build -> 34 2SLS trust-ret -> 35 reduced form -> 36 2SLS linear trust -> 37 reduced form extended -> 38 main analysis

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

* 32: Returns control build (listwise deletion)
do "${BASE_PATH}/Code/Analysis/32_returns_control_build.do"

* 33: Returns control build 2 (listwise deletion)
do "${BASE_PATH}/Code/Analysis/33_returns_control_build_2.do"

* 34: 2SLS trust–returns (depression IV)
do "${BASE_PATH}/Code/Analysis/34_2sls_trust_ret.do"

* 35: Reduced form (r5 on trust; panel FE/RE/CRE)
do "${BASE_PATH}/Code/Analysis/35_reduced_form.do"

* 36: 2SLS linear trust only (no trust²; weak-robust test)
do "${BASE_PATH}/Code/Analysis/36_2sls_linear_trust.do"

* 37: Reduced form extended (full controls: + gender, race, region, born_us, married)
do "${BASE_PATH}/Code/Analysis/37_reduced_form_ext.do"

* 38: Main analysis tables (r5 returns + Trust*; can run independently if 00-05 and 10_build_panel done)
do "${BASE_PATH}/Code/Analysis/38_main_analysis_trust_ret.do"

display "3_run_pipeline_34_37: Completed 32, 33, 34, 35, 36, 37, 38."
