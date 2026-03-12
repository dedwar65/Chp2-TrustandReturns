* 37_reduced_form_ext.do
* Extended version of 35_reduced_form.do: full control set = 35 controls
* (wealth, age, inlbrf, educ) + gender, race, region, born_us, married.
* Same listwise-deletion panel as 35 (like 14).
*
* Output:
*   - Log: Notes/Logs/37_reduced_form_ext.log

clear
set more off

capture noisily set maxvar 32767

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
log using "${LOG_DIR}/37_reduced_form_ext.log", replace text

* ----------------------------------------------------------------------
* Load processed analysis data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

display _n "########################################################################"
display "37) REDUCED FORM (EXTENDED: + gender, race, region, born_us, married)"
display "########################################################################"
display "Data: ${PROCESSED}/analysis_ready_processed.dta"
display "Log: ${LOG_DIR}/37_reduced_form_ext.log"

* ----------------------------------------------------------------------
* Core variables
* ----------------------------------------------------------------------
capture confirm variable trust_others_2020
if _rc {
    display as error "37: trust_others_2020 not found. Exiting."
    log close
    exit 0
}

capture confirm variable r5_annual_avg_w5
if _rc {
    display as error "37: r5_annual_avg_w5 not found. Exiting."
    log close
    exit 0
}

capture drop trust_others_2020_sq
gen double trust_others_2020_sq = trust_others_2020 * trust_others_2020

capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

capture drop educ_cat
capture confirm variable educ_yrs
if !_rc {
    gen byte educ_cat = .
    replace educ_cat = 1 if educ_yrs < 12
    replace educ_cat = 2 if educ_yrs == 12
    replace educ_cat = 3 if educ_yrs > 12 & educ_yrs < 16
    replace educ_cat = 4 if educ_yrs == 16
    replace educ_cat = 5 if educ_yrs > 16 & !missing(educ_yrs)
    capture label drop educ_lbl
    label define educ_lbl 1 "Less HS" 2 "HS Grad" 3 "Some College" 4 "College" 5 "Postgrad"
    label values educ_cat educ_lbl
}

* ----------------------------------------------------------------------
* Factor-variable expansions for pwcorr / sample definition
* ----------------------------------------------------------------------
local corr_gender_vars ""
local corr_age_vars ""
local corr_educ_vars ""
local corr_race_vars ""
local corr_inlbrf_vars ""
local corr_factor_note ""

capture confirm variable gender
if !_rc {
    quietly levelsof gender if !missing(gender), local(gender_levels)
    local first_gender = 1
    foreach lvl of local gender_levels {
        if `first_gender' {
            local gender_base "`lvl'"
            local first_gender = 0
            continue
        }
        local dname "corr_gender_`lvl'"
        capture drop `dname'
        gen byte `dname' = gender == `lvl' if !missing(gender)
        local corr_gender_vars "`corr_gender_vars' `dname'"
    }
    if "`gender_base'" != "" local corr_factor_note "`corr_factor_note' gender(base=`gender_base')"
}

capture confirm variable age_bin
if !_rc {
    quietly levelsof age_bin if !missing(age_bin), local(age_levels)
    local first_age = 1
    foreach lvl of local age_levels {
        if `first_age' {
            local age_base "`lvl'"
            local first_age = 0
            continue
        }
        local dname "corr_agebin_`lvl'"
        capture drop `dname'
        gen byte `dname' = age_bin == `lvl' if !missing(age_bin)
        local corr_age_vars "`corr_age_vars' `dname'"
    }
    if "`age_base'" != "" local corr_factor_note "`corr_factor_note' age_bin(base=`age_base')"
}

capture confirm variable educ_cat
if !_rc {
    quietly levelsof educ_cat if !missing(educ_cat), local(educ_levels)
    local first_educ = 1
    foreach lvl of local educ_levels {
        if `first_educ' {
            local educ_base "`lvl'"
            local first_educ = 0
            continue
        }
        local dname "corr_educ_cat_`lvl'"
        capture drop `dname'
        gen byte `dname' = educ_cat == `lvl' if !missing(educ_cat)
        local corr_educ_vars "`corr_educ_vars' `dname'"
    }
    if "`educ_base'" != "" local corr_factor_note "`corr_factor_note' educ_cat(base=`educ_base')"
}

capture confirm variable race_eth
if !_rc {
    quietly levelsof race_eth if !missing(race_eth), local(race_levels)
    local first_race = 1
    foreach lvl of local race_levels {
        if `first_race' {
            local race_base "`lvl'"
            local first_race = 0
            continue
        }
        local dname "corr_race_eth_`lvl'"
        capture drop `dname'
        gen byte `dname' = race_eth == `lvl' if !missing(race_eth)
        local corr_race_vars "`corr_race_vars' `dname'"
    }
    if "`race_base'" != "" local corr_factor_note "`corr_factor_note' race_eth(base=`race_base')"
}

capture confirm variable inlbrf_2020
if !_rc local corr_inlbrf_vars "inlbrf_2020"

* Region: censreg or censreg_2020
local region_var ""
capture confirm variable censreg
if !_rc local region_var "censreg"
if "`region_var'" == "" {
    capture confirm variable censreg_2020
    if !_rc local region_var "censreg_2020"
}
local corr_region_vars ""
if "`region_var'" != "" {
    quietly levelsof `region_var' if !missing(`region_var'), local(region_levels)
    local first_region = 1
    foreach lvl of local region_levels {
        if `first_region' {
            local region_base "`lvl'"
            local first_region = 0
            continue
        }
        local dname "corr_`region_var'_`lvl'"
        capture drop `dname'
        gen byte `dname' = `region_var' == `lvl' if !missing(`region_var')
        local corr_region_vars "`corr_region_vars' `dname'"
    }
    if "`region_base'" != "" local corr_factor_note "`corr_factor_note' `region_var'(base=`region_base')"
}
local corr_married_vars ""
capture confirm variable married_2020
if !_rc {
    local corr_married_vars "married_2020"
}

local wealth_r5_vars ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wealth_r5_vars "`wealth_r5_vars' wealth_d`d'_2020"
}

local reg_ctrl_age ""
if trim("`corr_age_vars'") != "" local reg_ctrl_age "i.age_bin"
local reg_ctrl_inlbrf ""
if trim("`corr_inlbrf_vars'") != "" local reg_ctrl_inlbrf "inlbrf_2020"
local reg_ctrl_educ ""
if trim("`corr_educ_vars'") != "" local reg_ctrl_educ "i.educ_cat"
local reg_ctrl_gender ""
if trim("`corr_gender_vars'") != "" local reg_ctrl_gender "i.gender"
local reg_ctrl_race ""
if trim("`corr_race_vars'") != "" local reg_ctrl_race "i.race_eth"
local reg_ctrl_region ""
if trim("`corr_region_vars'") != "" local reg_ctrl_region "i.`region_var'"
local reg_ctrl_married ""
if trim("`corr_married_vars'") != "" local reg_ctrl_married "married_2020"

* Full controls = 35 (wealth, age, inlbrf, educ) + gender, race, region, born_us, married
local r5_ctrls "`wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `reg_ctrl_gender' `reg_ctrl_race'"
capture confirm variable born_us
if !_rc local r5_ctrls "`r5_ctrls' born_us"
if trim("`reg_ctrl_region'") != "" local r5_ctrls "`r5_ctrls' `reg_ctrl_region'"
if trim("`reg_ctrl_married'") != "" local r5_ctrls "`r5_ctrls' `reg_ctrl_married'"

display "Expanded factor controls for pwcorr: `corr_factor_note'"

* ----------------------------------------------------------------------
* 1) Common-sample pwcorr
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) COMMON SAMPLE PWCORR"
display "########################################################################"

* Common sample: 35 set (r5, trust, trust², wealth, age, inlbrf, educ) + full-control vars for regressions
local corr_full "r5_annual_avg_w5 trust_others_2020 trust_others_2020_sq `wealth_r5_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars' `corr_gender_vars' `corr_race_vars'"
capture confirm variable born_us
if !_rc local corr_full "`corr_full' born_us"
if trim("`corr_region_vars'") != "" local corr_full "`corr_full' `corr_region_vars'"
if trim("`corr_married_vars'") != "" local corr_full "`corr_full' `corr_married_vars'"
tempvar common_sample
gen byte `common_sample' = 1
markout `common_sample' `corr_full'
quietly count if `common_sample' == 1
local common_n = r(N)

display "Variables in common-sample definition: `corr_full'"
display "Common-sample observations: `common_n'"

if `common_n' == 0 {
    display as error "37: Common sample has zero observations. Exiting."
    log close
    exit 0
}

display _n "--- pwcorr (sig, obs) ---"
pwcorr `corr_full', sig obs

* ----------------------------------------------------------------------
* 2) r5 on trust and trust squared (full control set)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2) r5 ON TRUST AND TRUST SQUARED (FULL CONTROL SET)"
display "########################################################################"
display "Outcome: r5_annual_avg_w5"
display "Regressions use listwise deletion; N may differ across models."
display "Controls: `r5_ctrls'"

regress r5_annual_avg_w5 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 ///
    `r5_ctrls', vce(robust)
display "--- Joint test: Trust and trust squared ---"
testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
if trim("`wealth_r5_vars'") != "" {
    display "--- Joint test: Wealth deciles (net wealth) ---"
    testparm `wealth_r5_vars'
}
if trim("`reg_ctrl_age'") != "" {
    display "--- Joint test: Age bins ---"
    testparm i.age_bin
}
if trim("`reg_ctrl_educ'") != "" {
    display "--- Joint test: Education categories ---"
    testparm i.educ_cat
}
if trim("`reg_ctrl_gender'") != "" {
    display "--- Joint test: Gender ---"
    testparm i.gender
}
if trim("`reg_ctrl_race'") != "" {
    display "--- Joint test: Race ---"
    testparm i.race_eth
}
if trim("`reg_ctrl_region'") != "" {
    display "--- Joint test: Region ---"
    testparm i.`region_var'
}
if trim("`reg_ctrl_married'") != "" {
    display "--- Joint test: Married ---"
    testparm married_2020
}

* ======================================================================
* PANEL MODEL SEQUENCE
* ======================================================================
* Load the long panel; use listwise deletion (like 14). Then run:
*   4) Panel sample construction
*   5a) Pooled OLS
*   5b) FE on shared time-varying specification
*   5c) Second-step regression of FE on time-invariant vars
*   5d) Matching RE + classic Hausman test
*   5e) Substantive RE with trust and trust squared
*   5f) CRE/Mundlak test and substantive CRE model

* ----------------------------------------------------------------------
* 4) Panel sample construction
* ----------------------------------------------------------------------
display _n "########################################################################"
display "4) PANEL SAMPLE CONSTRUCTION"
display "########################################################################"

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off
xtset hhidpn year

capture confirm variable trust_others_2020
if _rc {
    display as error "37 panel: trust_others_2020 not found in long panel. Exiting."
    log close
    exit 0
}

capture drop trust_others_2020_sq
gen double trust_others_2020_sq = trust_others_2020 * trust_others_2020

capture confirm variable r5_annual_w5
if _rc {
    display as error "37 panel: r5_annual_w5 not found in long panel. Exiting."
    log close
    exit 0
}

capture drop panel_educ_cat
capture confirm variable educ_yrs
if !_rc {
    gen byte panel_educ_cat = .
    replace panel_educ_cat = 1 if educ_yrs < 12
    replace panel_educ_cat = 2 if educ_yrs == 12
    replace panel_educ_cat = 3 if educ_yrs > 12 & educ_yrs < 16
    replace panel_educ_cat = 4 if educ_yrs == 16
    replace panel_educ_cat = 5 if educ_yrs > 16 & !missing(educ_yrs)
    capture label drop peduc_lbl
    label define peduc_lbl 1 "Less HS" 2 "HS Grad" 3 "Some College" 4 "College" 5 "Postgrad"
    label values panel_educ_cat peduc_lbl
}

* Time-varying controls for the reduced control set
local panel_wealth_vars ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local panel_wealth_vars "`panel_wealth_vars' wealth_d`d'"
}
local panel_tv_ctrls "`panel_wealth_vars' i.age_bin inlbrf i.year"

* Time-invariant controls (absorbed by FE, estimable in RE/CRE/second-step)
* Full set = educ + gender + race + region + born_us + married
local panel_tinv_ctrls ""
capture confirm variable educ_yrs
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' educ_yrs"
capture confirm variable gender
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' i.gender"
capture confirm variable race_eth
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' i.race_eth"
capture confirm variable censreg
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' i.censreg"
capture confirm variable born_us
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' born_us"
capture confirm variable married
if !_rc local panel_tinv_ctrls "`panel_tinv_ctrls' married"

display "Panel uses listwise deletion on outcome and controls; N may vary across models."

* ----------------------------------------------------------------------
* 5a) Pooled OLS
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5a) POOLED OLS: r5 ON TRUST + TRUST^2 + ALL CONTROLS + YEAR"
display "########################################################################"

display "Outcome: r5_annual_w5"
display "Sample: listwise deletion on outcome and controls"
display "Controls (time-varying): `panel_tv_ctrls'"
display "Controls (time-invariant): `panel_tinv_ctrls'"
display "Trust terms: trust_others_2020 trust_others_2020_sq"

regress r5_annual_w5 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 ///
    `panel_tv_ctrls' `panel_tinv_ctrls', vce(cluster hhidpn)
estimates store pooled_ols

display "--- Joint test: Trust and trust squared ---"
testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
if trim("`panel_wealth_vars'") != "" {
    display "--- Joint test: Wealth deciles ---"
    testparm `panel_wealth_vars'
}
display "--- Joint test: Age bins ---"
testparm i.age_bin
display "--- Joint test: Year ---"
testparm i.year
capture noisily {
    display "--- Joint test: Gender ---"
    testparm i.gender
}
capture noisily {
    display "--- Joint test: Race ---"
    testparm i.race_eth
}

* ----------------------------------------------------------------------
* 5b) FE on shared time-varying specification
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5b) FE: r5 ON TIME-VARYING REDUCED CONTROLS"
display "########################################################################"
display "Time-varying controls: `panel_tv_ctrls'"
display "(trust, trust^2, educ, gender, race, region, born_us, married are time-invariant; absorbed by FE)"

xtreg r5_annual_w5 `panel_tv_ctrls', fe vce(cluster hhidpn)
estimates store fe_r5

if trim("`panel_wealth_vars'") != "" {
    display "--- Joint test: Wealth deciles ---"
    testparm `panel_wealth_vars'
}
display "--- Joint test: Age bins ---"
testparm i.age_bin
display "--- Joint test: Year ---"
testparm i.year

display _n "--- FE model summary ---"
display "sigma_u = " e(sigma_u)
display "sigma_e = " e(sigma_e)
display "rho     = " e(rho)
display "R2_w    = " e(r2_w)
display "R2_b    = " e(r2_b)
display "R2_o    = " e(r2_o)

* Extract individual fixed effects
predict double __fe_hat if e(sample), u

* ----------------------------------------------------------------------
* 5c) Second-step regression of FE on time-invariant vars
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5c) SECOND-STEP: FE ON TIME-INVARIANT VARIABLES"
display "########################################################################"
display "LHS: estimated FE. RHS: educ, gender, race, region, born_us, married (Spec 1);"
display "+ trust (Spec 2); + trust^2 (Spec 3)."
display "Reduce to one row per hhidpn (collapse) so we can run cross-sectional regression."

preserve
keep if !missing(__fe_hat)
local collapse_vars "__fe_hat trust_others_2020 trust_others_2020_sq"
capture confirm variable educ_yrs
if !_rc local collapse_vars "`collapse_vars' educ_yrs"
capture confirm variable gender
if !_rc local collapse_vars "`collapse_vars' gender"
capture confirm variable race_eth
if !_rc local collapse_vars "`collapse_vars' race_eth"
capture confirm variable born_us
if !_rc local collapse_vars "`collapse_vars' born_us"
capture confirm variable censreg
if !_rc local collapse_vars "`collapse_vars' censreg"
capture confirm variable married
if !_rc local collapse_vars "`collapse_vars' married"
collapse (first) `collapse_vars', by(hhidpn)

display _n "--- Spec 1: FE on time-invariant controls (no trust) ---"
regress __fe_hat `panel_tinv_ctrls', vce(robust)
capture noisily testparm i.race_eth

display _n "--- Spec 2: FE on time-invariant controls + linear trust ---"
regress __fe_hat trust_others_2020 `panel_tinv_ctrls' ///
    if !missing(trust_others_2020), vce(robust)
capture noisily testparm i.race_eth

display _n "--- Spec 3: FE on time-invariant controls + trust + trust^2 ---"
regress __fe_hat trust_others_2020 trust_others_2020_sq `panel_tinv_ctrls' ///
    if !missing(trust_others_2020), vce(robust)
display "--- Joint test: Trust and trust squared ---"
testparm trust_others_2020 trust_others_2020_sq
capture noisily testparm i.race_eth

restore

* ----------------------------------------------------------------------
* 5d) Matching RE + Hausman test
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5d) MATCHING RE + HAUSMAN TEST"
display "########################################################################"
display "RE uses the same time-varying specification as FE."
display "Hausman test compares FE and RE on shared time-varying coefficients."

* RE with same time-varying controls (no trust, which is time-invariant)
xtreg r5_annual_w5 `panel_tv_ctrls', re vce(cluster hhidpn)
estimates store re_match

display _n "--- RE matching model summary ---"
display "sigma_u = " e(sigma_u)
display "sigma_e = " e(sigma_e)
display "rho     = " e(rho)

* Classic Hausman test requires non-robust SEs.
* Re-estimate FE and RE without vce(cluster) for this test only.
display _n "--- Re-estimating FE and RE without cluster-robust SE for Hausman ---"

quietly xtreg r5_annual_w5 `panel_tv_ctrls', fe
estimates store fe_haus

quietly xtreg r5_annual_w5 `panel_tv_ctrls', re
estimates store re_haus

display _n "--- Classic Hausman test (FE vs RE on shared time-varying spec) ---"
hausman fe_haus re_haus, sigmamore
display "Interpretation: reject H0 (p < 0.05) => FE preferred over RE."

* ----------------------------------------------------------------------
* 5e) Substantive RE with all time-invariant regressors
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5e) SUBSTANTIVE RE: r5 WITH TRUST + TRUST^2 + ALL TIME-INVARIANT"
display "########################################################################"
display "Adds time-invariant regressors (educ, gender, race, region, born_us, married, trust, trust^2) to RE."

xtreg r5_annual_w5 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 ///
    `panel_tv_ctrls' `panel_tinv_ctrls', re vce(cluster hhidpn)
estimates store re_trust

display "--- Joint test: Trust and trust squared ---"
testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
if trim("`panel_wealth_vars'") != "" {
    display "--- Joint test: Wealth deciles ---"
    testparm `panel_wealth_vars'
}
display "--- Joint test: Age bins ---"
testparm i.age_bin
display "--- Joint test: Year ---"
testparm i.year
capture noisily {
    display "--- Joint test: Gender ---"
    testparm i.gender
}
capture noisily {
    display "--- Joint test: Race ---"
    testparm i.race_eth
}

display _n "--- Substantive RE summary ---"
display "sigma_u = " e(sigma_u)
display "sigma_e = " e(sigma_e)
display "rho     = " e(rho)

* ----------------------------------------------------------------------
* 5f) CRE/Mundlak test and substantive CRE model
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5f) CRE/MUNDLAK TEST AND SUBSTANTIVE CRE MODEL"
display "########################################################################"
display "Add within-group means of time-varying regressors to RE."
display "Joint significance of means = Mundlak test of FE vs RE."

* Compute within-group means of time-varying regressors
foreach v of local panel_wealth_vars {
    capture drop m_`v'
    bysort hhidpn: egen double m_`v' = mean(`v')
}
capture drop m_inlbrf
bysort hhidpn: egen double m_inlbrf = mean(inlbrf)

capture confirm variable age_bin
if !_rc {
    capture drop m_age_bin
    bysort hhidpn: egen double m_age_bin = mean(age_bin)
}

local mundlak_means ""
foreach v of local panel_wealth_vars {
    local mundlak_means "`mundlak_means' m_`v'"
}
local mundlak_means "`mundlak_means' m_inlbrf"
capture confirm variable m_age_bin
if !_rc local mundlak_means "`mundlak_means' m_age_bin"

display "Mundlak means: `mundlak_means'"

* CRE model: RE with trust + trust^2 + time-varying + time-invariant + means
display _n "--- CRE/Mundlak model ---"
xtreg r5_annual_w5 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 ///
    `panel_tv_ctrls' `panel_tinv_ctrls' `mundlak_means', re vce(cluster hhidpn)
estimates store cre_trust

display "--- Joint test: Trust and trust squared ---"
testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
if trim("`panel_wealth_vars'") != "" {
    display "--- Joint test: Wealth deciles ---"
    testparm `panel_wealth_vars'
}
display "--- Joint test: Age bins ---"
testparm i.age_bin
display "--- Joint test: Year ---"
testparm i.year
capture noisily {
    display "--- Joint test: Gender ---"
    testparm i.gender
}
capture noisily {
    display "--- Joint test: Race ---"
    testparm i.race_eth
}

display _n "--- Mundlak test: joint significance of within-group means ---"
testparm `mundlak_means'
display "Interpretation: reject H0 (p < 0.05) => unit effects correlated with regressors;"
display "CRE preferred over standard RE."

display _n "--- CRE model summary ---"
display "sigma_u = " e(sigma_u)
display "sigma_e = " e(sigma_e)
display "rho     = " e(rho)

* ----------------------------------------------------------------------
* Histograms of estimated individual effects (FE vs CRE)
* ----------------------------------------------------------------------
* CRE individual effect = u_i + x̄_i*γ (same structure as FE alpha_i).
display _n "########################################################################"
display "HISTOGRAMS: FE vs CRE individual effects"
display "########################################################################"

predict double __u_cre if e(sample), u
gen double __alpha_cre = __u_cre if e(sample)
foreach v of local mundlak_means {
    capture replace __alpha_cre = __alpha_cre + _b[`v']*`v' if e(sample)
}

capture mkdir "${BASE_PATH}/Code/Analysis/Figures"

preserve
keep if !missing(__fe_hat)
collapse (first) __fe_hat, by(hhidpn)
quietly summarize __fe_hat, meanonly
gen double __fe_dm = __fe_hat - r(mean)
histogram __fe_dm, fraction bin(80) ///
    title("Distribution of FE (demeaned): r5 returns") ///
    xtitle("Estimated fixed effect") ytitle("Fraction") ///
    scheme(s1mono)
graph export "${BASE_PATH}/Code/Analysis/Figures/37_fe_hist.png", replace width(1200)
display "Wrote: Code/Analysis/Figures/37_fe_hist.png"
restore

preserve
keep if !missing(__alpha_cre)
collapse (first) __alpha_cre, by(hhidpn)
quietly summarize __alpha_cre, meanonly
gen double __alpha_cre_dm = __alpha_cre - r(mean)
histogram __alpha_cre_dm, fraction bin(80) ///
    title("Distribution of CRE individual effect (demeaned): r5 returns") ///
    xtitle("Estimated individual effect") ytitle("Fraction") ///
    scheme(s1mono)
graph export "${BASE_PATH}/Code/Analysis/Figures/37_cre_hist.png", replace width(1200)
display "Wrote: Code/Analysis/Figures/37_cre_hist.png"
restore

* Clean up
capture drop __fe_hat __u_cre __alpha_cre
capture drop m_inlbrf m_age_bin
foreach v of local panel_wealth_vars {
    capture drop m_`v'
}

* ----------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------
display _n "########################################################################"
display "37_reduced_form_ext: Completed."
display "Cross-sectional sections 1-3 and panel sections 4-5f."
display "Log saved in: ${LOG_DIR}/37_reduced_form_ext.log"
display "########################################################################"

log close
