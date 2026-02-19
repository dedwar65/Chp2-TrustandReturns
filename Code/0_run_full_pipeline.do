* 0_run_full_pipeline.do
* Run entire pipeline from scratch: 00–05 (data + processing) then 10–18 (panel + regressions).
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

do "${BASE_PATH}/Code/Raw data/0_run_pipeline_00_05.do"
do "${BASE_PATH}/Code/Regressions/2_run_pipeline_10_18.do"

display "0_run_full_pipeline: Completed 00–05 and 10–18."
