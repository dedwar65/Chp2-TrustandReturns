* 29_2sls_untrust.do
* Diagnostics: trust LHS with untrust variables (potential deception items).
* 1) Cross-correlation: general trust with 6 untrust vars
* 2) PCA on 6 untrust vars: scree + loadings (PC1, PC2)
* 3) Regressions (log only):
*    Spec 1: baseline (match 22 Addl Spec 7b: demo + depression + wealth + inlbrf + pop bins + region + born_us)
*    Spec 2: Spec 1 + all untrust vars
*    Spec 3: Spec 1 + PC1
*    Spec 4: Spec 1 + PC2
*    Spec 5: literal full set — Spec 2 + health_cond, medicare, medicaid, life_ins, num_divorce, num_widow; joint test untrust=0
* 4) Table: Determinants of general trust — (1) Demographics (2) Reduced (Spec 2) (3) Full (Spec 5)
* Log: Notes/Logs/29_2sls_untrust.log

clear
set more off

capture which esttab
if _rc ssc install estout, replace

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
log using "${LOG_DIR}/29_2sls_untrust.log", replace text

use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

capture confirm variable trust_others_2020
if _rc {
    display as error "29: trust_others_2020 not found. Run pipeline 00-05."
    log close
    exit 198
}

local untrust_vars "untrust_social_security_2020 untrust_medicare_medicaid_2020 untrust_banks_2020 untrust_advisors_2020 untrust_mutual_funds_2020 untrust_insurance_2020"
local have_untrust ""
foreach v of local untrust_vars {
    capture confirm variable `v'
    if !_rc local have_untrust "`have_untrust' `v'"
}
local n_untrust : word count `have_untrust'
if `n_untrust' < 2 {
    display as error "29: fewer than 2 untrust variables found. Check 01_2 and 03."
    log close
    exit 198
}

* Age bins
capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* Demographics (match 22 Addl Spec 7b)
local demo_core "i.gender educ_yrs married_2020"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"
capture confirm variable race_eth
if _rc local demo_race ""

* Region fallback in wide data
local region_var ""
capture confirm variable censreg
if !_rc local region_var "censreg"
if "`region_var'" == "" {
    capture confirm variable censreg_2020
    if !_rc local region_var "censreg_2020"
}
local has_region = ("`region_var'" != "")

capture confirm variable inlbrf_2020
local has_inlbrf = (_rc == 0)
capture confirm variable depression_2020
local has_dep = (_rc == 0)
capture confirm variable population_3bin_2020
local has_pop = (_rc == 0)
capture confirm variable born_us
local has_born_us = (_rc == 0)

local wdec ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wdec "`wdec' wealth_d`d'_2020"
}
local has_wdec = (trim("`wdec'") != "")

* ----------------------------------------------------------------------
* 1) Cross-correlation
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) CROSS-CORRELATION: General trust and untrust variables"
display "########################################################################"

local corr_vars "trust_others_2020 `have_untrust'"
display _n "--- pwcorr (sig, obs) ---"
pwcorr `corr_vars', sig obs

display _n "--- correlate ---"
correlate `corr_vars'

* ----------------------------------------------------------------------
* 2) PCA on untrust vars
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2) PCA ON UNTRUST VARIABLES"
display "########################################################################"

local pca_cond ""
foreach v of local have_untrust {
    local pca_cond "`pca_cond' & !missing(`v')"
}
local pca_cond = substr("`pca_cond'", 4, .)

pca `have_untrust' if `pca_cond'
screeplot, title("Untrust PCA (6 variables)")

capture drop untrust_pc1_2020 untrust_pc2_2020
predict untrust_pc1_2020 untrust_pc2_2020 if e(sample), score

matrix L = e(L)
display _n "Loadings (PC1, PC2):"
forvalues i = 1/`n_untrust' {
    local v : word `i' of `have_untrust'
    display "  `v': PC1=" L[`i',1] ", PC2=" L[`i',2]
}

* ----------------------------------------------------------------------
* 3) Regressions (LHS = trust_others_2020)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "3) TRUST LHS REGRESSIONS"
display "########################################################################"

if !`has_inlbrf' | !`has_region' | !`has_wdec' | !`has_dep' | !`has_pop' {
    display as error "29: required baseline controls missing."
    display as error "Required: inlbrf_2020, region, wealth_d2..wealth_d10, depression_2020, population_3bin_2020"
    log close
    exit 198
}

* Baseline = 22 Addl Spec 7b: base_dep + wdec + inlbrf + pop bins + region + born_us
local base_dep "`demo_core' `demo_race'"
capture confirm variable depression_2020
if !_rc local base_dep "`base_dep' depression_2020"
local baseline "`base_dep' `wdec' inlbrf_2020 i.population_3bin_2020 i.`region_var'"
if `has_born_us' local baseline "`baseline' born_us"

local samp_if "!missing(trust_others_2020) & !missing(population_3bin_2020) & !missing(`region_var')"
if `has_born_us' local samp_if "`samp_if' & !missing(born_us)"

display _n "--- Spec 1: baseline (match 22 Addl Spec 7b) ---"
regress trust_others_2020 `baseline' if `samp_if', vce(robust)

display _n "--- Spec 2: Spec 1 + all untrust vars ---"
regress trust_others_2020 `baseline' `have_untrust' if `samp_if', vce(robust)
quietly testparm `have_untrust'
display "Joint test (untrust vars = 0): p-value = " %6.4f r(p)

display _n "--- Spec 3: Spec 1 + untrust PC1 ---"
regress trust_others_2020 `baseline' untrust_pc1_2020 if `samp_if' & !missing(untrust_pc1_2020), vce(robust)

display _n "--- Spec 4: Spec 1 + untrust PC2 ---"
regress trust_others_2020 `baseline' untrust_pc2_2020 if `samp_if' & !missing(untrust_pc2_2020), vce(robust)

* Spec 5: literal full set — Spec 2 + health conditions, Medicare, Medicaid, life insurance, divorce, widow
local full_extra ""
foreach v in health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 num_divorce_2020 num_widow_2020 {
    capture confirm variable `v'
    if !_rc local full_extra "`full_extra' `v'"
}
local full_ctrl "`baseline' `have_untrust' `full_extra'"
local full_samp "`samp_if'"
foreach v in health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 num_divorce_2020 num_widow_2020 {
    capture confirm variable `v'
    if !_rc local full_samp "`full_samp' & !missing(`v')"
}
display _n "--- Spec 5: literal full set (Spec 2 + health, Medicare, Medicaid, life ins, divorce, widow) ---"
regress trust_others_2020 `full_ctrl' if `full_samp', vce(robust)
quietly testparm `have_untrust'
display "Joint test (untrust vars = 0): p-value = " %6.4f r(p)

* ----------------------------------------------------------------------
* 4) Table: Determinants of general trust — (1) Demographics (2) Reduced (3) Full
* ----------------------------------------------------------------------
display _n "########################################################################"
display "4) TABLE: Determinants of general trust"
display "########################################################################"

eststo clear
* (1) Demographics + depression
eststo demog: regress trust_others_2020 `demo_core' `demo_race' depression_2020 if !missing(trust_others_2020) & !missing(depression_2020), vce(robust)
capture confirm variable age_bin
if !_rc {
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : demog
}
else estadd scalar p_joint_age_bin = . : demog
capture confirm variable race_eth
if !_rc {
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : demog
}
else estadd scalar p_joint_race = . : demog
estadd scalar p_joint_untrust = . : demog
estadd scalar p_joint_wealth = . : demog
estadd scalar p_joint_population = . : demog
estadd scalar p_joint_region = . : demog

* (2) Reduced — Spec 2: baseline + untrust
eststo reduced: regress trust_others_2020 `baseline' `have_untrust' if `samp_if', vce(robust)
capture confirm variable age_bin
if !_rc {
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : reduced
}
else estadd scalar p_joint_age_bin = . : reduced
capture confirm variable race_eth
if !_rc {
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : reduced
}
else estadd scalar p_joint_race = . : reduced
quietly testparm `have_untrust'
estadd scalar p_joint_untrust = r(p) : reduced
if trim("`wdec'") != "" {
    quietly testparm `wdec'
    estadd scalar p_joint_wealth = r(p) : reduced
}
else estadd scalar p_joint_wealth = . : reduced
quietly testparm i.population_3bin_2020
estadd scalar p_joint_population = r(p) : reduced
quietly testparm i.`region_var'
estadd scalar p_joint_region = r(p) : reduced

* (3) Full — Spec 5: literal full set
eststo full: regress trust_others_2020 `full_ctrl' if `full_samp', vce(robust)
capture confirm variable age_bin
if !_rc {
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : full
}
else estadd scalar p_joint_age_bin = . : full
capture confirm variable race_eth
if !_rc {
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : full
}
else estadd scalar p_joint_race = . : full
quietly testparm `have_untrust'
estadd scalar p_joint_untrust = r(p) : full
if trim("`wdec'") != "" {
    quietly testparm `wdec'
    estadd scalar p_joint_wealth = r(p) : full
}
else estadd scalar p_joint_wealth = . : full
quietly testparm i.population_3bin_2020
estadd scalar p_joint_population = r(p) : full
quietly testparm i.`region_var'
estadd scalar p_joint_region = r(p) : full

* Keep main coefficients + population bins + deception (untrust) vars for table
local keep_29 "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth depression_2020 2.population_3bin_2020 3.population_3bin_2020"
foreach v of local have_untrust {
    local keep_29 "`keep_29' `v'"
}
local keep_29 "`keep_29' health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 num_divorce_2020 num_widow_2020 _cons"

label variable educ_yrs "Years of education"
label variable married_2020 "Married"
label variable depression_2020 "Depression"
label variable health_cond_2020 "Health conditions"
label variable medicare_2020 "Covered by Medicare"
label variable medicaid_2020 "Covered by Medicaid"
label variable life_ins_2020 "Has life insurance"
label variable num_divorce_2020 "Number of reported divorces"
label variable num_widow_2020 "Number of reported times being widowed"

capture mkdir "${REGRESSIONS}/2SLS/PredictTrust"
local outfile "${REGRESSIONS}/2SLS/PredictTrust/trust_reg_general_untrust.tex"
di as txt "Writing: `outfile'"

esttab demog reduced full using "`outfile'", replace ///
    booktabs no gap ///
    mtitles("(1)" "(2)" "(3)") ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    keep(`keep_29') ///
    varlabels(2.gender "Female" educ_yrs "Years of education" married_2020 "Married" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" depression_2020 "Depression" 2.population_3bin_2020 "Small/med city (10k-100k)" 3.population_3bin_2020 "Large metro (100k+)" untrust_social_security_2020 "Deception: Social Security" untrust_medicare_medicaid_2020 "Deception: Medicare/Medicaid" untrust_banks_2020 "Deception: Banks" untrust_advisors_2020 "Deception: Financial advisors" untrust_mutual_funds_2020 "Deception: Mutual funds" untrust_insurance_2020 "Deception: Insurance companies" health_cond_2020 "Health conditions" medicare_2020 "Covered by Medicare" medicaid_2020 "Covered by Medicaid" life_ins_2020 "Has life insurance" num_divorce_2020 "Number of reported divorces" num_widow_2020 "Number of reported times being widowed" _cons "Constant") ///
    title("Determinants of general trust") ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a p_joint_untrust, labels("Observations" "Adj. R-squared" "Joint test: Deception vars p-value")) ///
    nonumbers nonotes

display _n "Done. Log: ${LOG_DIR}/29_2sls_untrust.log"
log close
