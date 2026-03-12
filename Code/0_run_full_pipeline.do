* 0_run_full_pipeline.do
* Run entire pipeline from scratch: 00–05 (data + processing), 06–08 (descriptives),
* 10–18+ (panel + regressions), 34–38 (2SLS + reduced form + main analysis tables).
* Run from repo root or Code/ directory.

clear
set more off

* Resolve BASE_PATH
capture confirm global BASE_PATH
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") {
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

timer clear 1
timer on 1

* 00–05: Data merge + processing (analysis_ready_processed.dta)
do "${BASE_PATH}/Code/Raw data/0_run_pipeline_00_05.do"

* 06–08: Descriptives (income, returns, controls)
do "${BASE_PATH}/Code/Descriptive/1_run_pipeline_06_08.do"

* 10–18, 20, 22, 25, 29, 30, 31: Panel build + regressions
do "${BASE_PATH}/Code/Regressions/2_run_pipeline_10_18.do"

* 34–38: 2SLS trust-ret, reduced form, 2SLS linear, reduced form extended, main analysis tables
do "${BASE_PATH}/Code/Analysis/3_run_pipeline_34_37.do"

timer off 1
quietly timer list 1
local elapsed = r(t1)
local mins = floor(`elapsed' / 60)
local secs = `elapsed' - 60 * `mins'
display _n "0_run_full_pipeline: Completed 00–05, 06–08, 10–18, 20, 22, 25, 29, 30, 31, 34–38."
display "Total time: " `mins' " min " round(`secs', 0.01) " sec"
