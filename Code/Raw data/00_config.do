* 00_config.do
* Set base path and logging. Run from repository root (parent of Code/).
* All paths are relative to BASE_PATH.

clear all
set more off

* Repository root: directory containing Code/, Paper/, Notes/
* Run from repo root, or from Code/Raw data (script will cd to repo root).
global BASE_PATH "`c(pwd)'"
if regexm("`c(pwd)'", "[\/]Raw data$") {
    cd ..
    cd ..
    global BASE_PATH "`c(pwd)'"
}
if regexm("`c(pwd)'", "[\/]Code$") {
    cd ..
    global BASE_PATH "`c(pwd)'"
}

* Paths used by downstream do-files
global RAW_DATA   "${BASE_PATH}/Code/Raw data"
global HRS_DATA   "${RAW_DATA}/HRS"
global FRED_DATA  "${RAW_DATA}/FRED"
global CLEANED      "${BASE_PATH}/Code/Cleaned data"
global PROCESSED    "${BASE_PATH}/Code/Processing"
global DESCRIPTIVE  "${BASE_PATH}/Code/Descriptive"
global REGRESSIONS  "${BASE_PATH}/Code/Regressions"
global LOG_DIR      "${BASE_PATH}/Notes/Logs"

* Create log directory, Cleaned data, Processing, Descriptive, and Regressions output dirs
capture mkdir "${LOG_DIR}"
capture mkdir "${CLEANED}"
capture mkdir "${PROCESSED}"
capture mkdir "${DESCRIPTIVE}"
capture mkdir "${DESCRIPTIVE}/Figures"
capture mkdir "${DESCRIPTIVE}/Tables"
capture mkdir "${REGRESSIONS}"
* Output subdirs: Trust (11), Income/Spec1 & Income/Spec2 (12), Returns/Spec1 & Spec2 (13)
capture mkdir "${REGRESSIONS}/Trust"
capture mkdir "${REGRESSIONS}/Income"
capture mkdir "${REGRESSIONS}/Income/Spec1"
capture mkdir "${REGRESSIONS}/Income/Spec2"
capture mkdir "${REGRESSIONS}/Returns"
capture mkdir "${REGRESSIONS}/Returns/Spec1"
capture mkdir "${REGRESSIONS}/Returns/Spec2"

* Start log for the current do-file (caller should pass log name via -do 01_merge_all_data.do, log- or set log here)
* This script only sets globals; the calling do-file opens its own log.
