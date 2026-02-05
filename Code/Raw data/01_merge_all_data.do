* 01_merge_all_data.do
* Master script: FRED CPI, then merge flows and trust one wave per sub-script (like old repo create_wide_RAND_long).
* Each sub-script uses one tempfile per run to avoid r(693) I/O errors.
* Output: Code/Cleaned data/all_data_merged.dta
* Run from repository root or from Code/Raw data; BASE_PATH is set here so 00_config is always found.

* Set BASE_PATH to repo root (directory containing Code/, Paper/, Notes/)
* If run from Code/Cleaned data, Code/Raw data, or other Code subdir, cd up to repo root first
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
do "${BASE_PATH}/Code/Raw data/00_config.do"

capture log close
log using "${LOG_DIR}/01_merge_all_data.log", replace text

* ------------------------------------------------------------------------------
* 1. FRED CPI
* ------------------------------------------------------------------------------
capture mkdir "${FRED_DATA}"
freduse CPIAUCSL, clear
export delimited using "${FRED_DATA}/CPIAUCSL.csv", replace
display "Saved FRED CPIAUCSL to ${FRED_DATA}/CPIAUCSL.csv"
clear

* ------------------------------------------------------------------------------
* 2. Merge 2022 flows (01_1), then 2020 trust (01_2), then 2002–2020 flows (01_3–01_12)
* ------------------------------------------------------------------------------
* Run sub-scripts without capture so the first real error surfaces (which script/command failed)
display "=== 01_1: Merging 2022 flows ==="
do "${RAW_DATA}/01_1_merge_flow_2022.do"

display "=== 01_2: Merging 2020 trust (rv557-rv570) ==="
do "${RAW_DATA}/01_2_merge_trust_2020.do"

display "=== 01_3–01_12: Merging 2002–2020 flows ==="
do "${RAW_DATA}/01_3_merge_flow_2002.do"
do "${RAW_DATA}/01_4_merge_flow_2004.do"
do "${RAW_DATA}/01_5_merge_flow_2006.do"
do "${RAW_DATA}/01_6_merge_flow_2008.do"
do "${RAW_DATA}/01_7_merge_flow_2010.do"
do "${RAW_DATA}/01_8_merge_flow_2012.do"
do "${RAW_DATA}/01_9_merge_flow_2014.do"
do "${RAW_DATA}/01_10_merge_flow_2016.do"
do "${RAW_DATA}/01_11_merge_flow_2018.do"
do "${RAW_DATA}/01_12_merge_flow_2020.do"

* ------------------------------------------------------------------------------
* 5. Clean missing value codes for rv557-rv570: -9 and -8 only
* ------------------------------------------------------------------------------
use "${CLEANED}/all_data_merged.dta", clear
capture unab allrv : rv*_*
if _rc == 0 {
    foreach v of local allrv {
        quietly replace `v' = . if inlist(`v', -9, -8)
    }
}
save "${CLEANED}/all_data_merged.dta", replace
display "Saved ${CLEANED}/all_data_merged.dta  (N = " _N ")"

log close
