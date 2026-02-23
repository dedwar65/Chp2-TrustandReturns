* 22_region_home_trust.do
* Cross-section: general trust (LHS) on controls — mirrors 11_reg_trust.
* Spec 1: Demographics + depression + medicaid. Spec 2: + regional trust. Spec 3: + hometown/pop trust.
* Log only — no table export. Inspect results before deciding on export format.
* Log: Notes/Logs/22_region_home_trust.log

clear
set more off

* ----------------------------------------------------------------------
* Paths and config
* ----------------------------------------------------------------------
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
    do "${BASE_PATH}/Code/Raw data/00_config.do"
}

capture log close
log using "${LOG_DIR}/22_region_home_trust.log", replace text

* ----------------------------------------------------------------------
* Load data (wide, 2020 cross-section)
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* LHS: General trust (2020)
capture confirm variable trust_others_2020
if _rc {
    display as error "22: trust_others_2020 not found. Run pipeline 00-05."
    log close
    exit 198
}

* Demographics (match 11): age bins, gender, educ, married, race (no inlbrf, born_us)
local demo_core "i.gender educ_yrs married_2020"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"
capture confirm variable race_eth
if _rc local demo_race ""

* Expanded: + depression, medicaid (from 11 full controls)
local expanded ""
capture confirm variable depression_2020
if !_rc local expanded "`expanded' depression_2020"
capture confirm variable medicaid_2020
if !_rc local expanded "`expanded' medicaid_2020"

local ctrl "`demo_core' `demo_race' `expanded'"

* Trust measures (contextual)
capture confirm variable regional_trust_2020
local has_regional = (_rc == 0)
capture confirm variable pop3_trust_2020
local has_pop3 = (_rc == 0)

* ----------------------------------------------------------------------
* Regressions: General trust on (1) expanded ctrl, (2) + regional trust, (3) + pop trust
* ----------------------------------------------------------------------
display _n "########################################################################"
display "CROSS-SECTION: General trust (LHS)"
display "########################################################################"

display _n "--- Spec 1: Baseline + depression + medicaid ---"
regress trust_others_2020 `ctrl' if !missing(trust_others_2020), vce(robust)

if `has_regional' {
    display _n "--- Spec 2: + Regional trust (mean trust by census region) ---"
    regress trust_others_2020 `ctrl' c.regional_trust_2020 if !missing(trust_others_2020) & !missing(regional_trust_2020), vce(robust)
}
else {
    display _n "--- Spec 2: Skipped (regional_trust_2020 not found) ---"
}

if `has_pop3' {
    display _n "--- Spec 3: + Hometown/population trust (mean trust by pop 3 bins) ---"
    regress trust_others_2020 `ctrl' c.pop3_trust_2020 if !missing(trust_others_2020) & !missing(pop3_trust_2020), vce(robust)
}
else {
    display _n "--- Spec 3: Skipped (pop3_trust_2020 not found) ---"
}

display _n "Done. Log: ${LOG_DIR}/22_region_home_trust.log"
log close
