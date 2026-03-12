* 32_returns_control_build.do
* Standalone analysis stage for inspecting average return outcomes before
* building a new control-variable strategy.
*
* Output:
*   - Log: Notes/Logs/32_returns_control_build.log
*   - Figures: Code/Analysis/Returns/

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

local analysis_dir "${BASE_PATH}/Code/Analysis"
local analysis_returns_dir "`analysis_dir'/Returns"

capture mkdir "`analysis_dir'"
capture mkdir "`analysis_returns_dir'"

capture log close
log using "${LOG_DIR}/32_returns_control_build.log", replace text

* ----------------------------------------------------------------------
* Load processed analysis data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

display _n "########################################################################"
display "32) RETURNS CONTROL BUILD"
display "########################################################################"
display "Data: ${PROCESSED}/analysis_ready_processed.dta"
display "Figures: `analysis_returns_dir'"
display "Log: ${LOG_DIR}/32_returns_control_build.log"

* ----------------------------------------------------------------------
* Core variables
* ----------------------------------------------------------------------
capture confirm variable trust_others_2020
if _rc {
    display as error "32: trust_others_2020 not found. Exiting."
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

* Education categories: match existing descriptive splits in the pipeline
* (<12, 12, 13-15, 16, 17+), but keep a dedicated variable for this file.
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

* r3 residential average was not included in the original 5 percent average
* winsorization block from 05_processing_returns.do, so create it here if needed.
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

local ret_raw_candidates "r1_annual_avg r3_annual_avg r4_annual_avg r5_annual_avg"
local ret_win_candidates "r1_annual_avg_win r4_annual_avg_win r5_annual_avg_win"
local ret_w5_candidates "r1_annual_avg_w5 r3_annual_avg_w5 r4_annual_avg_w5 r5_annual_avg_w5"
local ret_tabstat_extra_candidates "r3_annual_avg_w5"
* Keep the 1 percent variants in the file/log, but use 5 percent winsorized
* averages for the active scatter/regression/correlation work.
local ret_active_win_candidates "`ret_w5_candidates'"
local ret_raw_present ""
local ret_win_present ""
local ret_w5_present ""
local ret_all_present ""
local ret_tabstat_extra_present ""

foreach v of local ret_raw_candidates {
    capture confirm variable `v'
    if !_rc {
        local ret_raw_present "`ret_raw_present' `v'"
        local ret_all_present "`ret_all_present' `v'"
    }
    else display as txt "Raw average return variable not found: `v'"
}

foreach v of local ret_win_candidates {
    capture confirm variable `v'
    if !_rc {
        local ret_win_present "`ret_win_present' `v'"
        local ret_all_present "`ret_all_present' `v'"
    }
    else display as txt "1 percent winsorized average return variable not found: `v'"
}

foreach v of local ret_w5_candidates {
    capture confirm variable `v'
    if !_rc local ret_w5_present "`ret_w5_present' `v'"
    else display as txt "5 percent winsorized average return variable not found: `v'"
}

foreach v of local ret_tabstat_extra_candidates {
    capture confirm variable `v'
    if !_rc {
        local ret_tabstat_extra_present "`ret_tabstat_extra_present' `v'"
        local ret_all_present "`ret_all_present' `v'"
    }
    else display as txt "Additional tabstat variable not found: `v'"
}

if trim("`ret_all_present'") == "" {
    display as error "32: No average return variables found. Exiting."
    log close
    exit 0
}

* ----------------------------------------------------------------------
* 1) Distribution of raw and 1 percent winsorized average returns
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) DISTRIBUTION OF AVERAGE RETURN VARIABLES"
display "########################################################################"
display "Raw average return vars found: `ret_raw_present'"
display "1 percent winsorized average return vars found: `ret_win_present'"
display "5 percent winsorized average return vars found: `ret_w5_present'"
display "Additional variables shown in tabstat/detail: `ret_tabstat_extra_present'"

display _n "--- tabstat: raw + 1 percent winsorized average return variables ---"
tabstat `ret_all_present', statistics(n mean sd p1 p5 p50 p95 p99 min max)

display _n "--- summarize, detail: each available average return variable ---"
foreach v of local ret_all_present {
    display _n "Variable: `v'"
    quietly count if !missing(`v')
    display "Non-missing observations: " r(N)
    summarize `v', detail
}

* ----------------------------------------------------------------------
* 2) One-control-at-a-time design around baseline trust specification
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2) STEPWISE CONTROL INSPECTION"
display "########################################################################"
display "All post-tabstat analysis uses trust and trust squared as the baseline."
display "Regressions use listwise deletion; N may differ across models."

* Exogenous X (match 31_2sls_dep_2.do, no depression)
local demo_core "i.gender educ_yrs married_2020"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"
capture confirm variable race_eth
if _rc local demo_race ""

local region_var ""
capture confirm variable censreg
if !_rc local region_var "censreg"
if "`region_var'" == "" {
    capture confirm variable censreg_2020
    if !_rc local region_var "censreg_2020"
}

local ctrl_x "`demo_core' `demo_race'"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_x "`ctrl_x' wealth_d`d'_2020"
}
capture confirm variable inlbrf_2020
if !_rc local ctrl_x "`ctrl_x' inlbrf_2020"
if "`region_var'" != "" local ctrl_x "`ctrl_x' i.`region_var'"
capture confirm variable born_us
if !_rc local ctrl_x "`ctrl_x' born_us"

local corr_ctrls ""
local corr_factor_note ""
local corr_gender_vars ""
local corr_age_vars ""
local corr_educ_vars ""
local corr_married_vars ""
local corr_race_vars ""
local corr_inlbrf_vars ""
local corr_region_vars ""
local corr_bornus_vars ""

* For correlation diagnostics, expand factor-style regressors into dummies so
* the log matches the second-stage design matrix more closely.
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
capture confirm variable married_2020
if !_rc {
    local corr_married_vars "married_2020"
    local corr_ctrls "`corr_ctrls' married_2020"
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

forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local corr_ctrls "`corr_ctrls' wealth_d`d'_2020"
}
capture confirm variable inlbrf_2020
if !_rc {
    local corr_inlbrf_vars "inlbrf_2020"
    local corr_ctrls "`corr_ctrls' inlbrf_2020"
}

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
        local corr_ctrls "`corr_ctrls' `dname'"
    }
    if "`region_base'" != "" local corr_factor_note "`corr_factor_note' `region_var'(base=`region_base')"
}

capture confirm variable born_us
if !_rc {
    local corr_bornus_vars "born_us"
    local corr_ctrls "`corr_ctrls' born_us"
}

display "Second-stage control macro (factor notation): `ctrl_x'"
display "Correlation block uses design-matrix variables for factor controls."
display "Expanded factor controls: `corr_factor_note'"
display "Control variables used for correlation diagnostics: `corr_ctrls'"

local block_label_baseline  "Baseline: trust and trust squared only"
local block_label_wealth    "Wealth block: outcome-specific wealth deciles"
local block_label_wealthbase "Baseline plus wealth: trust, trust squared, and outcome-specific wealth deciles"
local block_label_wealthagebase "Baseline plus wealth and age: trust, trust squared, outcome-specific wealth deciles, and age bins"
local block_label_gender   "Gender block"
local block_label_educ     "Education block"
local block_label_married  "Married block"
local block_label_race     "Race block"
local block_label_inlbrf   "Labor-force block"
local block_label_region   "Region block"
local block_label_bornus   "Born in U.S. block"

local corr_vars_baseline  ""
local corr_vars_wealth    "`wealth_union_vars'"
local corr_vars_wealthbase "`wealth_union_vars'"
local corr_vars_wealthagebase "`wealth_union_vars' `corr_age_vars'"
local corr_vars_age      "`corr_age_vars'"
local corr_vars_gender   "`corr_gender_vars'"
local corr_vars_educ     "`corr_educ_vars'"
local corr_vars_married  "`corr_married_vars'"
local corr_vars_race     "`corr_race_vars'"
local corr_vars_inlbrf   "`corr_inlbrf_vars'"
local corr_vars_region   "`corr_region_vars'"
local corr_vars_bornus   "`corr_bornus_vars'"

local reg_ctrl_age       ""
if trim("`corr_age_vars'") != "" local reg_ctrl_age "i.age_bin"
local reg_ctrl_gender    ""
if trim("`corr_gender_vars'") != "" local reg_ctrl_gender "i.gender"
local reg_ctrl_educ      ""
if trim("`corr_educ_vars'") != "" local reg_ctrl_educ "i.educ_cat"
local reg_ctrl_married   ""
if trim("`corr_married_vars'") != "" local reg_ctrl_married "married_2020"
local reg_ctrl_race      ""
if trim("`corr_race_vars'") != "" local reg_ctrl_race "i.race_eth"
local reg_ctrl_inlbrf    ""
if trim("`corr_inlbrf_vars'") != "" local reg_ctrl_inlbrf "inlbrf_2020"
local reg_ctrl_region    ""
if trim("`corr_region_vars'") != "" local reg_ctrl_region "i.`region_var'"
local reg_ctrl_bornus    ""
if trim("`corr_bornus_vars'") != "" local reg_ctrl_bornus "born_us"

local stage_list "baseline wealthbase wealthagebase"
local block_list_baseline   "baseline wealth age gender educ married race inlbrf region bornus"
local block_list_wealthbase "wealthbase age gender educ married race inlbrf region bornus"
local block_list_wealthagebase "wealthagebase gender educ married race inlbrf region bornus"

foreach stage of local stage_list {
    local stage_base_corr "`corr_vars_`stage''"
    local stage_block_list "`block_list_`stage''"

    display _n "########################################################################"
    display "STAGE: `block_label_`stage''"
    display "########################################################################"

    foreach block of local stage_block_list {
        local block_corr_vars "`corr_vars_`block''"
        local block_title "`block_label_`block''"
        local added_corr_vars ""
        if "`block'" != "`stage'" local added_corr_vars "`block_corr_vars'"
        local corr_full "`ret_active_win_candidates' trust_others_2020 trust_others_2020_sq `stage_base_corr' `added_corr_vars'"
        tempvar block_sample
        gen byte `block_sample' = 1
        markout `block_sample' `corr_full'
        quietly count if `block_sample'
        local block_n = r(N)

        display _n "########################################################################"
        display "`block_title'"
        display "########################################################################"
        display "Variables in pwcorr sample definition: `corr_full'"
        display "Block sample observations: `block_n'"

        if `block_n' == 0 {
            display as txt "Skipping block `block': no observations in complete-case sample."
            continue
        }

        display _n "--- pwcorr (sig, obs) ---"
        pwcorr `corr_full', sig obs
        display _n "--- correlate ---"
        correlate `corr_full'

        foreach y of local ret_active_win_candidates {
            capture confirm variable `y'
            if _rc continue

            local reg_ctrls ""
            local wealth_test_list ""
            if "`stage'" == "wealthbase" | "`stage'" == "wealthagebase" {
                if "`y'" == "r1_annual_avg_w5" {
                    local reg_ctrls "`wealth_r1_vars'"
                    local wealth_test_list "`wealth_r1_vars'"
                }
                if "`y'" == "r3_annual_avg_w5" {
                    local reg_ctrls "`wealth_r3_vars'"
                    local wealth_test_list "`wealth_r3_vars'"
                }
                if "`y'" == "r4_annual_avg_w5" {
                    local reg_ctrls "`wealth_r4_vars'"
                    local wealth_test_list "`wealth_r4_vars'"
                }
                if "`y'" == "r5_annual_avg_w5" {
                    local reg_ctrls "`wealth_r5_vars'"
                    local wealth_test_list "`wealth_r5_vars'"
                }
            }
            if "`stage'" == "wealthagebase" local reg_ctrls "`reg_ctrls' `reg_ctrl_age'"

            if "`block'" == "wealth" {
                if "`y'" == "r1_annual_avg_w5" {
                    local reg_ctrls "`reg_ctrls' `wealth_r1_vars'"
                    local wealth_test_list "`wealth_r1_vars'"
                }
                if "`y'" == "r3_annual_avg_w5" {
                    local reg_ctrls "`reg_ctrls' `wealth_r3_vars'"
                    local wealth_test_list "`wealth_r3_vars'"
                }
                if "`y'" == "r4_annual_avg_w5" {
                    local reg_ctrls "`reg_ctrls' `wealth_r4_vars'"
                    local wealth_test_list "`wealth_r4_vars'"
                }
                if "`y'" == "r5_annual_avg_w5" {
                    local reg_ctrls "`reg_ctrls' `wealth_r5_vars'"
                    local wealth_test_list "`wealth_r5_vars'"
                }
            }
            else if "`block'" == "age" {
                local reg_ctrls "`reg_ctrls' `reg_ctrl_age'"
            }
            else if "`block'" != "`stage'" {
                local reg_ctrls "`reg_ctrls' `reg_ctrl_`block''"
            }

            display _n "-----------------------------------------------------------------------"
            display "Outcome: `y'"
            display "Regression uses listwise deletion on outcome and controls (N may differ across models)"
            display "Controls in regression: `reg_ctrls'"
            display "-----------------------------------------------------------------------"

            display _n "--- Spec 1: linear trust ---"
            regress `y' c.trust_others_2020 `reg_ctrls', vce(robust)
            if trim("`wealth_test_list'") != "" {
                display "--- Joint test: Wealth deciles ---"
                testparm `wealth_test_list'
            }
            if trim("`reg_ctrl_age'") != "" & (strpos("`reg_ctrls'", "i.age_bin") > 0) {
                display "--- Joint test: Age bins ---"
                testparm i.age_bin
            }
            if trim("`reg_ctrl_gender'") != "" & (strpos("`reg_ctrls'", "i.gender") > 0) {
                display "--- Joint test: Gender ---"
                testparm i.gender
            }
            if trim("`reg_ctrl_educ'") != "" & (strpos("`reg_ctrls'", "i.educ_cat") > 0) {
                display "--- Joint test: Education categories ---"
                testparm i.educ_cat
            }
            if trim("`reg_ctrl_race'") != "" & (strpos("`reg_ctrls'", "i.race_eth") > 0) {
                display "--- Joint test: Race ---"
                testparm i.race_eth
            }
            if trim("`reg_ctrl_region'") != "" & (strpos("`reg_ctrls'", "i.`region_var'") > 0) {
                display "--- Joint test: Region ---"
                testparm i.`region_var'
            }

            display _n "--- Spec 2: trust and trust squared ---"
            regress `y' c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 ///
                `reg_ctrls', vce(robust)
            display "--- Joint test: Trust and trust squared ---"
            testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
            if trim("`wealth_test_list'") != "" {
                display "--- Joint test: Wealth deciles ---"
                testparm `wealth_test_list'
            }
            if trim("`reg_ctrl_age'") != "" & (strpos("`reg_ctrls'", "i.age_bin") > 0) {
                display "--- Joint test: Age bins ---"
                testparm i.age_bin
            }
            if trim("`reg_ctrl_gender'") != "" & (strpos("`reg_ctrls'", "i.gender") > 0) {
                display "--- Joint test: Gender ---"
                testparm i.gender
            }
            if trim("`reg_ctrl_educ'") != "" & (strpos("`reg_ctrls'", "i.educ_cat") > 0) {
                display "--- Joint test: Education categories ---"
                testparm i.educ_cat
            }
            if trim("`reg_ctrl_race'") != "" & (strpos("`reg_ctrls'", "i.race_eth") > 0) {
                display "--- Joint test: Race ---"
                testparm i.race_eth
            }
            if trim("`reg_ctrl_region'") != "" & (strpos("`reg_ctrls'", "i.`region_var'") > 0) {
                display "--- Joint test: Region ---"
                testparm i.`region_var'
            }
        }

        if "`block'" != "`stage'" {
            local trust_regressors ""
            if "`stage'" == "wealthbase" | "`stage'" == "wealthagebase" {
                local trust_regressors "`wealth_r5_vars'"
            }
            if "`stage'" == "wealthagebase" {
                local trust_regressors "`trust_regressors' `reg_ctrl_age'"
            }

            if "`block'" == "wealth" local trust_regressors "`trust_regressors' `wealth_r5_vars'"
            else if "`block'" == "age" local trust_regressors "`trust_regressors' `reg_ctrl_age'"
            else local trust_regressors "`trust_regressors' `reg_ctrl_`block''"

            display _n "-----------------------------------------------------------------------"
            display "Outcome: trust_others_2020"
            display "Regression uses listwise deletion on outcome and controls (N may differ across models)"
            display "Controls in regression: `trust_regressors'"
            display "-----------------------------------------------------------------------"

            regress trust_others_2020 `trust_regressors', vce(robust)
            if trim("`wealth_r5_vars'") != "" & (strpos("`trust_regressors'", "wealth_d") > 0) {
                display "--- Joint test: Wealth deciles (net wealth) ---"
                testparm `wealth_r5_vars'
            }
            if trim("`reg_ctrl_age'") != "" & (strpos("`trust_regressors'", "i.age_bin") > 0) {
                display "--- Joint test: Age bins ---"
                testparm i.age_bin
            }
            if trim("`reg_ctrl_gender'") != "" & (strpos("`trust_regressors'", "i.gender") > 0) {
                display "--- Joint test: Gender ---"
                testparm i.gender
            }
            if trim("`reg_ctrl_educ'") != "" & (strpos("`trust_regressors'", "i.educ_cat") > 0) {
                display "--- Joint test: Education categories ---"
                testparm i.educ_cat
            }
            if trim("`reg_ctrl_race'") != "" & (strpos("`trust_regressors'", "i.race_eth") > 0) {
                display "--- Joint test: Race ---"
                testparm i.race_eth
            }
            if trim("`reg_ctrl_region'") != "" & (strpos("`trust_regressors'", "i.`region_var'") > 0) {
                display "--- Joint test: Region ---"
                testparm i.`region_var'
            }
        }
    }
}

* ----------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------
display _n "########################################################################"
display "32_returns_control_build: Completed."
display "Figures saved in: `analysis_returns_dir'"
display "Log saved in: ${LOG_DIR}/32_returns_control_build.log"
display "########################################################################"

log close
