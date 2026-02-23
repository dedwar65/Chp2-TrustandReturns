* 1_run_pipeline_06_08.do
* Run all descriptive do-files (06, 07, 08) in order.
* Order: 06 income descriptives -> 07 returns descriptives -> 08 controls descriptives

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

* 06: Descriptive income
do "${BASE_PATH}/Code/Descriptive/06_descriptive_income.do"

* 07: Descriptive returns
do "${BASE_PATH}/Code/Descriptive/07_descriptive_returns.do"

* 08: Descriptive controls
do "${BASE_PATH}/Code/Descriptive/08_descriptive_controls.do"

display "1_run_pipeline_06_08: Completed 06, 07, 08."
