* 00_run_pipeline_00_05.do
* Run pipeline through processing (00–05).
* Order: config -> merge -> returns -> prep controls -> income processing -> returns processing

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

* 01: Merge all data
do "${BASE_PATH}/Code/Raw data/01_merge_all_data.do"

* 02: Compute returns + income measures
do "${BASE_PATH}/Code/Cleaned data/02_compute_returns_income.do"

* 03: Prep controls + reduce dataset
do "${BASE_PATH}/Code/Processing/03_prep_controls.do"

* 04: Process income
do "${BASE_PATH}/Code/Processing/04_processing_income.do"

* 05: Process returns
do "${BASE_PATH}/Code/Processing/05_processing_returns.do"

display "00_run_pipeline_00_05: Completed 00–05."
