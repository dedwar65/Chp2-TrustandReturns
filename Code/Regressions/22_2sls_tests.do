* 22_2sls_tests.do
* First stage test diagnostics.
* Cross-section: general trust (LHS) on controls — mirrors 11_reg_trust.
* Spec 1: Demographics + depression + medicaid. Spec 2: + regional trust. Spec 3: + hometown/pop trust.
* Spec 4: Region + population bins only (categorical RHS).
* Log only — no table export. Inspect results before deciding on export format.
* Log: Notes/Logs/22_2sls_tests.log

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
log using "${LOG_DIR}/22_2sls_tests.log", replace text

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
local ctrl_nomcaid : subinstr local ctrl "medicaid_2020" "", all

* Trust measures (contextual)
capture confirm variable regional_trust_2020
local has_regional = (_rc == 0)
capture confirm variable pop3_trust_2020
local has_pop3 = (_rc == 0)
capture confirm variable population_3bin_2020
local has_pop3_cat = (_rc == 0)

* ----------------------------------------------------------------------
* Regressions: General trust on (1) expanded ctrl, (2) + regional trust,
*              (3) + pop trust, (4) population bins only (categorical)
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

if `has_pop3_cat' {
    display _n "--- Spec 4: Baseline controls + population bins (categorical RHS) ---"
    regress trust_others_2020 `ctrl' i.population_3bin_2020 if !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Spec 4: Skipped (population_3bin_2020 not found) ---"
}

if `has_pop3_cat' {
    display _n "--- Spec 5: Spec 4 but without medicaid_2020 ---"
    regress trust_others_2020 `ctrl_nomcaid' i.population_3bin_2020 if !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Spec 5: Skipped (population_3bin_2020 not found) ---"
}

* ----------------------------------------------------------------------
* Additional contemporaneous specs requested
* 1) baseline + depression + labor income
* 2) baseline + depression + in labor force
* 3) baseline + depression + total income
* 4) baseline + depression + total income + in labor force
* 5) baseline + depression + wealth decile
* ----------------------------------------------------------------------
local base_dep "`demo_core' `demo_race'"
capture confirm variable depression_2020
if !_rc local base_dep "`base_dep' depression_2020"

capture confirm variable labor_income_real_win_2020
local has_labinc = (_rc == 0)
capture confirm variable total_income_real_win_2020
local has_totinc = (_rc == 0)
capture confirm variable inlbrf_2020
local has_inlbrf = (_rc == 0)

local wdec ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wdec "`wdec' wealth_d`d'_2020"
}
local has_wdec = (trim("`wdec'") != "")

if `has_labinc' {
    display _n "--- Addl Spec 1: baseline + depression + labor income (2020) ---"
    regress trust_others_2020 `base_dep' labor_income_real_win_2020 if !missing(trust_others_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 1: Skipped (labor_income_real_win_2020 not found) ---"
}

if `has_inlbrf' {
    display _n "--- Addl Spec 2: baseline + depression + in labor force (2020) ---"
    regress trust_others_2020 `base_dep' inlbrf_2020 if !missing(trust_others_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 2: Skipped (inlbrf_2020 not found) ---"
}

if `has_totinc' {
    display _n "--- Addl Spec 3: baseline + depression + total income (2020) ---"
    regress trust_others_2020 `base_dep' total_income_real_win_2020 if !missing(trust_others_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 3: Skipped (total_income_real_win_2020 not found) ---"
}

if `has_totinc' & `has_inlbrf' {
    display _n "--- Addl Spec 4: baseline + depression + total income + in labor force (2020) ---"
    regress trust_others_2020 `base_dep' total_income_real_win_2020 inlbrf_2020 if !missing(trust_others_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 4: Skipped (total_income_real_win_2020 or inlbrf_2020 not found) ---"
}

if `has_wdec' & `has_inlbrf' & `has_pop3_cat' {
    display _n "--- Addl Spec 5: baseline + depression + wealth deciles + in labor force + population bins (2020) ---"
    regress trust_others_2020 `base_dep' `wdec' inlbrf_2020 i.population_3bin_2020 if !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 5: Skipped (wealth deciles, inlbrf_2020, or population_3bin_2020 not found) ---"
}

capture confirm variable medicaid_2020
local has_medicaid = (_rc == 0)
if `has_wdec' & `has_inlbrf' & `has_pop3_cat' & `has_medicaid' {
    display _n "--- Addl Spec 6: Spec 5 + medicaid_2020 ---"
    regress trust_others_2020 `base_dep' `wdec' inlbrf_2020 i.population_3bin_2020 medicaid_2020 if !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Addl Spec 6: Skipped (wealth deciles, inlbrf_2020, population_3bin_2020, or medicaid_2020 not found) ---"
}

local region_var ""
capture confirm variable censreg
if !_rc local region_var "censreg"
if "`region_var'" == "" {
    capture confirm variable censreg_2020
    if !_rc local region_var "censreg_2020"
}
local has_region = ("`region_var'" != "")
if `has_wdec' & `has_inlbrf' & `has_pop3_cat' & `has_region' {
    display _n "--- Addl Spec 7: Spec 6 with region (i.`region_var') instead of medicaid_2020 ---"
    regress trust_others_2020 `base_dep' `wdec' inlbrf_2020 i.population_3bin_2020 i.`region_var' if !missing(trust_others_2020) & !missing(population_3bin_2020) & !missing(`region_var'), vce(robust)
}
else {
    display _n "--- Addl Spec 7: Skipped (wealth deciles, inlbrf_2020, population_3bin_2020, or region variable not found) ---"
}

capture confirm variable born_us
local has_born_us = (_rc == 0)
if `has_wdec' & `has_inlbrf' & `has_pop3_cat' & `has_region' & `has_born_us' {
    display _n "--- Addl Spec 7b: Spec 7 + born_us ---"
    regress trust_others_2020 `base_dep' `wdec' inlbrf_2020 i.population_3bin_2020 i.`region_var' born_us if !missing(trust_others_2020) & !missing(population_3bin_2020) & !missing(`region_var') & !missing(born_us), vce(robust)
}
else {
    display _n "--- Addl Spec 7b: Skipped (wealth deciles, inlbrf_2020, population_3bin_2020, region, or born_us not found) ---"
}

if `has_wdec' & `has_inlbrf' & `has_region' {
    display _n "--- Addl Spec 8: Spec 5 with region (i.`region_var') instead of population bins ---"
    regress trust_others_2020 `base_dep' `wdec' inlbrf_2020 i.`region_var' if !missing(trust_others_2020) & !missing(`region_var'), vce(robust)
}
else {
    display _n "--- Addl Spec 8: Skipped (wealth deciles, inlbrf_2020, or region variable not found) ---"
}

* ----------------------------------------------------------------------
* Test of exclusion restriction
* Cross-correlation diagnostics in log only
*  - 2022 returns (r1..r5) + trust/pop/depression (2020)
*  - average returns (r1..r5 avg) + trust/pop/depression (2020)
* ----------------------------------------------------------------------
local corr_vars_2022 "r1_annual_2022 r2_annual_2022 r3_annual_2022 r4_annual_2022 r5_annual_2022 trust_others_2020 population_3bin_2020 depression_2020"
local corr_vars_avg  "r1_annual_avg r2_annual_avg r3_annual_avg r4_annual_avg r5_annual_avg trust_others_2020 population_3bin_2020 depression_2020"

foreach set in 2022 avg {
    local use_vars ""
    if "`set'" == "2022" local cand "`corr_vars_2022'"
    if "`set'" == "avg"  local cand "`corr_vars_avg'"
    foreach v of local cand {
        capture confirm variable `v'
        if !_rc local use_vars "`use_vars' `v'"
    }
    local nvars : word count `use_vars'
    if `nvars' < 2 {
        di as txt "Correlation table (`set') skipped: fewer than 2 variables found."
        continue
    }

    display _n "------------------------------------------------------------"
    display "Correlation matrix (`set')"
    display "Variables: `use_vars'"
    display "------------------------------------------------------------"
    correlate `use_vars'
}

* ----------------------------------------------------------------------
* Test of exclusion restriction
* Additional r5 diagnostics in log only
*   1) r5 (2022, w5): controls + depression
*   2) r5 (2022, w5): controls + depression + Trust + Trust^2
*   3) r5 (avg, w5):  controls + depression
*   4) r5 (avg, w5):  controls + depression + Trust + Trust^2
* ----------------------------------------------------------------------
local y_r5_cs "r5_annual_w5_2022"
capture confirm variable `y_r5_cs'
if _rc local y_r5_cs "r5_annual_2022_w5"

local y_r5_avg "r5_annual_avg_w5"
capture confirm variable `y_r5_avg'
if _rc local y_r5_avg "r5_annual_avg"

local ctrl_r5_diag "`demo_core' `demo_race' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5_diag "`ctrl_r5_diag' wealth_d`d'_2020"
}
capture confirm variable depression_2020
if !_rc local ctrl_r5_diag "`ctrl_r5_diag' depression_2020"

capture confirm variable `y_r5_cs'
local has_cs = (_rc == 0)
capture confirm variable `y_r5_avg'
local has_avg = (_rc == 0)
capture confirm variable trust_others_2020
local has_trust = (_rc == 0)

if `has_cs' & `has_trust' {
    display _n "--- Excl. Spec 1: r5 (2022, w5) on controls + depression ---"
    regress `y_r5_cs' `ctrl_r5_diag' if !missing(`y_r5_cs'), vce(robust)

    display _n "--- Excl. Spec 2: r5 (2022, w5) on controls + depression + Trust + Trust^2 ---"
    regress `y_r5_cs' `ctrl_r5_diag' c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(`y_r5_cs') & !missing(trust_others_2020), vce(robust)
    quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
    display as txt "Joint test (Trust, Trust^2) p-value = " %6.4f r(p)
}
else {
    display _n "--- Excl. Spec 1-2: Skipped (r5 2022 w5 or trust var not found) ---"
}

if `has_avg' & `has_trust' {
    display _n "--- Excl. Spec 3: r5 (average, w5) on controls + depression ---"
    regress `y_r5_avg' `ctrl_r5_diag' if !missing(`y_r5_avg'), vce(robust)

    display _n "--- Excl. Spec 4: r5 (average, w5) on controls + depression + Trust + Trust^2 ---"
    regress `y_r5_avg' `ctrl_r5_diag' c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(`y_r5_avg') & !missing(trust_others_2020), vce(robust)
    quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
    display as txt "Joint test (Trust, Trust^2) p-value = " %6.4f r(p)
}
else {
    display _n "--- Excl. Spec 3-4: Skipped (r5 average or trust var not found) ---"
}

* ----------------------------------------------------------------------
* Test of exclusion restriction (population in place of depression)
*   5) r5 (2022, w5): controls + population bins
*   6) r5 (2022, w5): controls + population bins + Trust + Trust^2
*   7) r5 (avg, w5):  controls + population bins
*   8) r5 (avg, w5):  controls + population bins + Trust + Trust^2
* ----------------------------------------------------------------------
local ctrl_r5_pop "`demo_core' `demo_race' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5_pop "`ctrl_r5_pop' wealth_d`d'_2020"
}

if `has_pop3_cat' {
    local ctrl_r5_pop "`ctrl_r5_pop' i.population_3bin_2020"
}

if `has_cs' & `has_pop3_cat' {
    display _n "--- Excl. Spec 5: r5 (2022, w5) on controls + population bins ---"
    regress `y_r5_cs' `ctrl_r5_pop' if !missing(`y_r5_cs') & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Excl. Spec 5: Skipped (r5 2022 w5 or population_3bin_2020 not found) ---"
}

if `has_cs' & `has_trust' & `has_pop3_cat' {
    display _n "--- Excl. Spec 6: r5 (2022, w5) on controls + population bins + Trust + Trust^2 ---"
    regress `y_r5_cs' `ctrl_r5_pop' c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(`y_r5_cs') & !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
    quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
    display as txt "Joint test (Trust, Trust^2) p-value = " %6.4f r(p)
}
else {
    display _n "--- Excl. Spec 6: Skipped (r5 2022 w5, trust, or population_3bin_2020 not found) ---"
}

if `has_avg' & `has_pop3_cat' {
    display _n "--- Excl. Spec 7: r5 (average, w5) on controls + population bins ---"
    regress `y_r5_avg' `ctrl_r5_pop' if !missing(`y_r5_avg') & !missing(population_3bin_2020), vce(robust)
}
else {
    display _n "--- Excl. Spec 7: Skipped (r5 average or population_3bin_2020 not found) ---"
}

if `has_avg' & `has_trust' & `has_pop3_cat' {
    display _n "--- Excl. Spec 8: r5 (average, w5) on controls + population bins + Trust + Trust^2 ---"
    regress `y_r5_avg' `ctrl_r5_pop' c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(`y_r5_avg') & !missing(trust_others_2020) & !missing(population_3bin_2020), vce(robust)
    quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
    display as txt "Joint test (Trust, Trust^2) p-value = " %6.4f r(p)
}
else {
    display _n "--- Excl. Spec 8: Skipped (r5 average, trust, or population_3bin_2020 not found) ---"
}

display _n "Done. Log: ${LOG_DIR}/22_2sls_tests.log"
log close
