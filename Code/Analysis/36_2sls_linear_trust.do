* 36_2sls_linear_trust.do
* IV/2SLS with LINEAR trust only (no trust^2) as the single endogenous
* regressor.  Mirrors the diagnostic battery of 34_2sls_trust_ret.do but
* drops the quadratic, so each scheme has exactly one endogenous variable.
* This lets us test whether estat weakrobust becomes available (it requires
* a single endogenous regressor in Stata's ivregress).
*
* Output:
*   - Log: Notes/Logs/36_2sls_linear_trust.log

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
log using "${LOG_DIR}/36_2sls_linear_trust.log", replace text

capture which ivreg2
if _rc {
    noi di as txt "Installing ivreg2 from SSC..."
    capture noisily ssc install ivreg2, replace
}
capture which ranktest
if _rc {
    noi di as txt "Installing ranktest from SSC..."
    capture noisily ssc install ranktest, replace
}

* ----------------------------------------------------------------------
* Load processed analysis data and CESD history
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

preserve
use "${CLEANED}/all_data_merged.dta", clear
local cesd_vars "hhidpn"
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc local cesd_vars "`cesd_vars' r`w'cesd"
}
keep `cesd_vars'
tempfile cesd
save "`cesd'", replace
restore

merge 1:1 hhidpn using "`cesd'", nogen

display _n "########################################################################"
display "36) 2SLS LINEAR TRUST ON RETURNS"
display "########################################################################"
display "Data: ${PROCESSED}/analysis_ready_processed.dta"
display "Log: ${LOG_DIR}/36_2sls_linear_trust.log"

* ----------------------------------------------------------------------
* Core variables
* ----------------------------------------------------------------------
capture confirm variable trust_others_2020
if _rc {
    display as error "36: trust_others_2020 not found. Exiting."
    log close
    exit 0
}

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

capture confirm variable r3_annual_avg_w5
if _rc {
    capture confirm variable r3_annual_avg
    if !_rc {
        quietly summarize r3_annual_avg, detail
        local r3_p5 = r(p5)
        local r3_p95 = r(p95)
        gen double r3_annual_avg_w5 = r3_annual_avg
        replace r3_annual_avg_w5 = `r3_p5' if r3_annual_avg_w5 < `r3_p5' & !missing(r3_annual_avg_w5)
        replace r3_annual_avg_w5 = `r3_p95' if r3_annual_avg_w5 > `r3_p95' & !missing(r3_annual_avg_w5)
        display "Created r3_annual_avg_w5 on the fly from r3_annual_avg."
    }
}

* ----------------------------------------------------------------------
* Depression instrument variants (match prior IV scripts)
* ----------------------------------------------------------------------
capture confirm variable r15cesd
if !_rc {
    capture drop depression_2020
    gen depression_2020 = r15cesd
}
capture confirm variable r14cesd
if !_rc {
    capture drop depression_2018
    gen depression_2018 = r14cesd
}
capture confirm variable r13cesd
if !_rc {
    capture drop depression_2016
    gen depression_2016 = r13cesd
}

gen byte ever_depressed = 0
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc replace ever_depressed = 1 if r`w'cesd > 0 & !missing(r`w'cesd)
}
local _cesd ""
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc local _cesd "`_cesd' r`w'cesd"
}
if "`_cesd'" != "" {
    egen _n_cesd = rownonmiss(`_cesd')
    replace ever_depressed = . if _n_cesd == 0
    drop _n_cesd
}

capture drop max_cesd
egen double max_cesd = rowmax(r6cesd r7cesd r8cesd r9cesd r10cesd r11cesd r12cesd r13cesd r14cesd r15cesd)
if "`_cesd'" != "" {
    egen _n_cesd = rownonmiss(`_cesd')
    replace max_cesd = . if _n_cesd == 0
    drop _n_cesd
}

* ----------------------------------------------------------------------
* Outcomes and baseline controls
* ----------------------------------------------------------------------
local ret_active "r5_annual_avg_w5"
local has_returns 0
foreach v of local ret_active {
    capture confirm variable `v'
    if !_rc local has_returns 1
}
if `has_returns' == 0 {
    display as error "36: No active 5 percent average return variables found. Exiting."
    log close
    exit 0
}

local corr_gender_vars ""
local corr_age_vars ""
local corr_educ_vars ""
local corr_race_vars ""
local corr_inlbrf_vars ""
local corr_ctrls ""
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
        local corr_ctrls "`corr_ctrls' `dname'"
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
        local corr_ctrls "`corr_ctrls' `dname'"
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
        local corr_ctrls "`corr_ctrls' `dname'"
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
        local corr_ctrls "`corr_ctrls' `dname'"
    }
    if "`race_base'" != "" local corr_factor_note "`corr_factor_note' race_eth(base=`race_base')"
}

capture confirm variable inlbrf_2020
if !_rc {
    local corr_inlbrf_vars "inlbrf_2020"
    local corr_ctrls "`corr_ctrls' inlbrf_2020"
}

local wealth_union_vars ""
local wealth_r1_vars ""
local wealth_r3_vars ""
local wealth_r4_vars ""
local wealth_r5_vars ""
forvalues d = 2/10 {
    capture confirm variable wealth_core_d`d'_2020
    if !_rc {
        local wealth_r1_vars "`wealth_r1_vars' wealth_core_d`d'_2020"
        local wealth_union_vars "`wealth_union_vars' wealth_core_d`d'_2020"
    }
    capture confirm variable wealth_res_d`d'_2020
    if !_rc {
        local wealth_r3_vars "`wealth_r3_vars' wealth_res_d`d'_2020"
        local wealth_union_vars "`wealth_union_vars' wealth_res_d`d'_2020"
    }
    capture confirm variable wealth_coreira_d`d'_2020
    if !_rc {
        local wealth_r4_vars "`wealth_r4_vars' wealth_coreira_d`d'_2020"
        local wealth_union_vars "`wealth_union_vars' wealth_coreira_d`d'_2020"
    }
    capture confirm variable wealth_d`d'_2020
    if !_rc {
        local wealth_r5_vars "`wealth_r5_vars' wealth_d`d'_2020"
        local wealth_union_vars "`wealth_union_vars' wealth_d`d'_2020"
    }
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
local iv_black_instr ""
capture confirm variable corr_race_eth_2
if !_rc local iv_black_instr "corr_race_eth_2"

local iv_base_ctrls_core "`wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ'"
local iv_base_ctrls_wgender "`iv_base_ctrls_core' `reg_ctrl_gender'"
local iv_base_ctrls_full "`iv_base_ctrls_wgender' `reg_ctrl_race'"

display "Baseline controls: wealth deciles, age bins, labor force, education, gender, race"
display "Expanded factor controls for pwcorr: `corr_factor_note'"

* ----------------------------------------------------------------------
* Instrument schemes
* ----------------------------------------------------------------------
* Just-identified: 1 instrument for 1 endogenous
* Overidentified ("overfit"): 2 instruments for 1 endogenous
local scheme_list "dep0 dep1 depEver dep0b dep1b depEverb"
local scheme_label_dep0      "Contemporaneous depression (just-identified)"
local scheme_label_dep1      "One lag depression (just-identified)"
local scheme_label_depEver   "Ever depressed (just-identified)"
local scheme_label_dep0b     "Contemporaneous depression + Black (overidentified)"
local scheme_label_dep1b     "One lag depression + Black (overidentified)"
local scheme_label_depEverb  "Ever depressed + Black (overidentified)"

local scheme_main_dep0      "depression_2020"
local scheme_main_dep1      "depression_2018"
local scheme_main_depEver   "ever_depressed"
local scheme_main_dep0b     "depression_2020"
local scheme_main_dep1b     "depression_2018"
local scheme_main_depEverb  "ever_depressed"

local scheme_instr_dep0      "depression_2020"
local scheme_instr_dep1      "depression_2018"
local scheme_instr_depEver   "ever_depressed"
local scheme_instr_dep0b     "depression_2020 `iv_black_instr'"
local scheme_instr_dep1b     "depression_2018 `iv_black_instr'"
local scheme_instr_depEverb  "ever_depressed `iv_black_instr'"

* Just-identified schemes: Black not used as IV, so full controls
local scheme_ctrls_dep0      "`iv_base_ctrls_full'"
local scheme_ctrls_dep1      "`iv_base_ctrls_full'"
local scheme_ctrls_depEver   "`iv_base_ctrls_full'"
* Overidentified schemes: Black used as IV, exclude race from controls
local scheme_ctrls_dep0b     "`iv_base_ctrls_wgender'"
local scheme_ctrls_dep1b     "`iv_base_ctrls_wgender'"
local scheme_ctrls_depEverb  "`iv_base_ctrls_wgender'"

local scheme_has_gender_dep0 1
local scheme_has_gender_dep1 1
local scheme_has_gender_depEver 1
local scheme_has_gender_dep0b 1
local scheme_has_gender_dep1b 1
local scheme_has_gender_depEverb 1

local scheme_has_race_dep0 1
local scheme_has_race_dep1 1
local scheme_has_race_depEver 1
local scheme_has_race_dep0b 0
local scheme_has_race_dep1b 0
local scheme_has_race_depEverb 0

foreach s of local scheme_list {
    local scheme_has_`s' 1
    foreach v in `scheme_main_`s'' {
        capture confirm variable `v'
        if _rc local scheme_has_`s' 0
    }
}
* Overidentified schemes require the Black instrument
if trim("`iv_black_instr'") == "" {
    local scheme_has_dep0b 0
    local scheme_has_dep1b 0
    local scheme_has_depEverb 0
    display as error "36: NH Black instrument dummy not available. Skipping overidentified IV schemes."
}

* ----------------------------------------------------------------------
* 1) Common-sample pwcorr
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) COMMON SAMPLE PWCORR (r5 ONLY ON RETURN SIDE)"
display "########################################################################"

local common_instr_vars "`iv_black_instr'"
foreach s of local scheme_list {
    if `scheme_has_`s'' {
        local common_instr_vars "`common_instr_vars' `scheme_main_`s''"
    }
    else {
        display as txt "Skipping instrument scheme `scheme_label_`s'': required variables not found."
    }
}

local corr_full "`ret_active' trust_others_2020 `wealth_union_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars' `corr_gender_vars' `corr_race_vars' `common_instr_vars'"
tempvar common_sample
gen byte `common_sample' = 1
markout `common_sample' `corr_full'
quietly count if `common_sample' == 1
local common_n = r(N)

display "Variables in common-sample definition: `corr_full'"
display "Common-sample observations: `common_n'"

if `common_n' == 0 {
    display as error "36: Common sample has zero observations. Exiting."
    log close
    exit 0
}

display _n "--- pwcorr (sig, obs) ---"
pwcorr `corr_full', sig obs

* ----------------------------------------------------------------------
* 2) Baseline OLS r5 regression on common sample
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2) BASELINE OLS: r5 ON LINEAR TRUST + BASELINE CONTROLS"
display "########################################################################"

local y "r5_annual_avg_w5"
capture confirm variable `y'
if _rc {
    display as error "36: r5_annual_avg_w5 not found. Exiting."
    log close
    exit 0
}

local reg_ctrls "`wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `reg_ctrl_gender' `reg_ctrl_race'"
local wealth_test_list "`wealth_r5_vars'"

display _n "-----------------------------------------------------------------------"
display "Outcome: `y'"
display "Regressions use listwise deletion; N may differ across models."
display "Controls in regression: `reg_ctrls'"
display "-----------------------------------------------------------------------"

display _n "--- Linear trust only ---"
regress `y' c.trust_others_2020 `reg_ctrls', vce(robust)
if trim("`wealth_test_list'") != "" {
    display "--- Joint test: Wealth deciles ---"
    testparm `wealth_test_list'
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

* ----------------------------------------------------------------------
* 3) Baseline trust equation (no instruments added)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "3) BASELINE TRUST EQUATION"
display "########################################################################"

local trust_base_ctrls "`wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `reg_ctrl_gender' `reg_ctrl_race'"

display _n "--- Trust on baseline controls ---"
regress trust_others_2020 `trust_base_ctrls', vce(robust)
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

* ----------------------------------------------------------------------
* 4) First-stage trust diagnostics by instrument scheme
* ----------------------------------------------------------------------
display _n "########################################################################"
display "4) FIRST-STAGE TRUST DIAGNOSTICS BY INSTRUMENT SCHEME"
display "########################################################################"

foreach s of local scheme_list {
    if !`scheme_has_`s'' continue

    local scheme_label "`scheme_label_`s''"
    local instrs "`scheme_instr_`s''"
    local stage_ctrls "`scheme_ctrls_`s''"
    local has_gender_ctrl `scheme_has_gender_`s''
    local has_race_ctrl `scheme_has_race_`s''

    display _n "########################################################################"
    display "`scheme_label'"
    display "########################################################################"
    display "Instrument set: `instrs'"

    display _n "--- Trust on IV baseline controls + instruments ---"
    regress trust_others_2020 `stage_ctrls' `instrs', vce(robust)
    display "--- Joint test: Instruments ---"
    testparm `instrs'
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
    if `has_gender_ctrl' & trim("`reg_ctrl_gender'") != "" {
        display "--- Joint test: Gender ---"
        testparm i.gender
    }
    if `has_race_ctrl' & trim("`reg_ctrl_race'") != "" {
        display "--- Joint test: Race ---"
        testparm i.race_eth
    }
}

* ----------------------------------------------------------------------
* 5) 2SLS second stage by instrument scheme (r5 only)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5) 2SLS SECOND STAGE BY INSTRUMENT SCHEME (r5 ONLY)"
display "########################################################################"

foreach s of local scheme_list {
    if !`scheme_has_`s'' continue

    local scheme_label "`scheme_label_`s''"
    local instrs "`scheme_instr_`s''"
    local reg_ctrls "`scheme_ctrls_`s''"
    local has_gender_ctrl `scheme_has_gender_`s''
    local has_race_ctrl `scheme_has_race_`s''

    display _n "########################################################################"
    display "`scheme_label'"
    display "########################################################################"
    display "Excluded instruments: `instrs'"

    local wealth_test_list "`wealth_r5_vars'"

    display _n "-----------------------------------------------------------------------"
    display "Outcome: r5_annual_avg_w5"
    display "Regressions use listwise deletion; N may differ across models."
    display "Included exogenous controls: `reg_ctrls'"
    display "Excluded instruments: `instrs'"
    display "-----------------------------------------------------------------------"

    local y "r5_annual_avg_w5"

    ivregress 2sls `y' `reg_ctrls' ///
        (trust_others_2020 = `instrs'), vce(robust)
    estimates store iv_`s'

    display _n "--- IV diagnostics: built-in (ivregress) ---"
    capture noisily estat firststage
    if _rc display as txt "estat firststage unavailable for this specification."
    capture noisily estat endogenous
    if _rc display as txt "estat endogenous unavailable for this specification."
    capture noisily estat overid
    if _rc display as txt "estat overid unavailable for this specification."

    display _n "--- IV diagnostics: weakrobust (single endogenous) ---"
    capture noisily estat weakrobust
    if _rc display as txt "estat weakrobust unavailable for this specification."
    capture noisily estat weakrobust, ar
    if _rc display as txt "estat weakrobust AR unavailable for this specification."
    capture noisily estat weakrobust, clr
    if _rc display as txt "estat weakrobust CLR unavailable for this specification."

    display _n "--- IV diagnostics: ivreg2 weak-ID suite ---"
    capture noisily ivreg2 `y' `reg_ctrls' ///
        (trust_others_2020 = `instrs'), ///
        robust first
    if _rc display as txt "ivreg2 diagnostics unavailable for this specification."

    estimates restore iv_`s'
    display "--- Test: trust_others_2020 ---"
    test trust_others_2020
    if trim("`wealth_test_list'") != "" {
        display "--- Joint test: Wealth deciles ---"
        testparm `wealth_test_list'
    }
    if trim("`reg_ctrl_age'") != "" {
        display "--- Joint test: Age bins ---"
        testparm i.age_bin
    }
    if trim("`reg_ctrl_educ'") != "" {
        display "--- Joint test: Education categories ---"
        testparm i.educ_cat
    }
    if `has_gender_ctrl' & trim("`reg_ctrl_gender'") != "" {
        display "--- Joint test: Gender ---"
        testparm i.gender
    }
    if `has_race_ctrl' & trim("`reg_ctrl_race'") != "" {
        display "--- Joint test: Race ---"
        testparm i.race_eth
    }
}

* ----------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------
display _n "########################################################################"
display "36_2sls_linear_trust: Completed."
display "Log saved in: ${LOG_DIR}/36_2sls_linear_trust.log"
display "########################################################################"

log close
