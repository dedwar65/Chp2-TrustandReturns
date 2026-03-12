* 33_returns_control_build_2.do
* Continue the control-building exercise from 32, starting from a new
* baseline that includes trust, trust squared, wealth deciles, age bins,
* and labor-force status.
*
* Output:
*   - Log: Notes/Logs/33_returns_control_build_2.log

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
log using "${LOG_DIR}/33_returns_control_build_2.log", replace text

* ----------------------------------------------------------------------
* Load processed analysis data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

display _n "########################################################################"
display "33) RETURNS CONTROL BUILD 2"
display "########################################################################"
display "Data: ${PROCESSED}/analysis_ready_processed.dta"
display "Log: ${LOG_DIR}/33_returns_control_build_2.log"

* ----------------------------------------------------------------------
* Core variables
* ----------------------------------------------------------------------
capture confirm variable trust_others_2020
if _rc {
    display as error "33: trust_others_2020 not found. Exiting."
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

local ret_w5_candidates "r1_annual_avg_w5 r3_annual_avg_w5 r4_annual_avg_w5 r5_annual_avg_w5"
local ret_active_win_candidates "`ret_w5_candidates'"
local has_active_returns 0
foreach v of local ret_active_win_candidates {
    capture confirm variable `v'
    if !_rc local has_active_returns 1
}
if `has_active_returns' == 0 {
    display as error "33: No 5 percent winsorized average return variables found. Exiting."
    log close
    exit 0
}

* ----------------------------------------------------------------------
* 1) One-control-at-a-time design around new baseline
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) STEPWISE CONTROL INSPECTION"
display "########################################################################"
display "Baseline here is trust, trust squared, wealth, age, and labor force."
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

local block_label_b5 "Baseline plus wealth, age, labor force, education, gender, and race"
local block_label_b4 "Minimal: wealth, age, labor force, education"
local block_label_gender  "Add one: gender"
local block_label_married  "Add one: married"
local block_label_region   "Add one: region"
local block_label_bornus   "Add one: born in U.S."
local block_label_excl     "Excluding: gender, race, region, born_us, married"
local block_label_incl     "Including: gender, race, region, born_us, married"

* Baseline b5 = wealth, age, labor force, education, race, gender.
* Add-one blocks (in order): region, born_us, married.
* Baseline b4 = wealth, age, labor force, education only. Add-one: gender.
local corr_vars_b5 "`wealth_union_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars' `corr_gender_vars' `corr_race_vars'"
local corr_vars_b4 "`wealth_union_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars'"
local corr_vars_gender  "`corr_gender_vars'"
local corr_vars_married  "`corr_married_vars'"
local corr_vars_region   "`corr_region_vars'"
local corr_vars_bornus   "`corr_bornus_vars'"
* Excl = minimal (wealth, age, inlbrf, educ only). Incl = full (add gender, race, region, born_us, married).
local corr_vars_excl "`wealth_union_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars'"
local corr_vars_incl "`wealth_union_vars' `corr_age_vars' `corr_inlbrf_vars' `corr_educ_vars' `corr_gender_vars' `corr_race_vars' `corr_region_vars' `corr_bornus_vars' `corr_married_vars'"

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

local stage_list "b5 b4 excl incl"
* b5: add one at a time (order: region, born_us, married).
* b4: add one (gender only). Excl and incl are single-block stages.
local block_list_b5 "region bornus married"
local block_list_b4 "gender"
local block_list_excl "excl"
local block_list_incl "incl"
* Stage-specific regression controls (b5 = +gender+race; b4 = minimal; excl = minimal; incl = full).
local stage_reg_add_b5 "`reg_ctrl_gender' `reg_ctrl_race'"
local stage_reg_add_b4 ""
local stage_reg_add_excl ""
local stage_reg_add_incl "`reg_ctrl_gender' `reg_ctrl_race' `reg_ctrl_region' `reg_ctrl_bornus' `reg_ctrl_married'"

foreach stage of local stage_list {
    local stage_base_corr "`corr_vars_`stage''"
    local stage_block_list "`block_list_`stage''"

    display _n "########################################################################"
    display "STAGE: `block_label_`stage''"
    display "########################################################################"

    local baseline_only_corr "`ret_active_win_candidates' trust_others_2020 trust_others_2020_sq `stage_base_corr'"
    tempvar baseline_only_sample
    gen byte `baseline_only_sample' = 1
    markout `baseline_only_sample' `baseline_only_corr'
    quietly count if `baseline_only_sample'
    local baseline_only_n = r(N)

    display _n "########################################################################"
    display "CURRENT BASELINE ONLY"
    display "########################################################################"
    display "Variables in pwcorr sample definition: `baseline_only_corr'"
    display "Block sample observations: `baseline_only_n'"

    if `baseline_only_n' > 0 {
        display _n "--- pwcorr (sig, obs) ---"
        pwcorr `baseline_only_corr', sig obs

        foreach y of local ret_active_win_candidates {
            capture confirm variable `y'
            if _rc continue

            local reg_ctrls ""
            local wealth_test_list ""
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
            local reg_ctrls "`reg_ctrls' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `stage_reg_add_`stage''"

            display _n "-----------------------------------------------------------------------"
            display "Outcome: `y'"
            display "Regression uses listwise deletion (N may differ across models)"
            display "Controls in regression: `reg_ctrls'"
            display "-----------------------------------------------------------------------"

            display _n "--- Spec 1: linear trust ---"
            regress `y' c.trust_others_2020 `reg_ctrls', vce(robust)
            if trim("`wealth_test_list'") != "" {
                display "--- Joint test: Wealth deciles ---"
                testparm `wealth_test_list'
            }
            if trim("`reg_ctrl_age'") != "" {
                display "--- Joint test: Age bins ---"
                testparm i.age_bin
            }
            if trim("`reg_ctrl_gender'") != "" & (strpos("`reg_ctrls'", "i.gender") > 0) {
                display "--- Joint test: Gender ---"
                testparm i.gender
            }
            if trim("`reg_ctrl_educ'") != "" {
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
            if trim("`reg_ctrl_bornus'") != "" & (strpos("`reg_ctrls'", "born_us") > 0) {
                display "--- Joint test: Born in U.S. ---"
                testparm born_us
            }
            if trim("`reg_ctrl_married'") != "" & (strpos("`reg_ctrls'", "married") > 0) {
                display "--- Joint test: Married ---"
                testparm married_2020
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
            if trim("`reg_ctrl_age'") != "" {
                display "--- Joint test: Age bins ---"
                testparm i.age_bin
            }
            if trim("`reg_ctrl_gender'") != "" & (strpos("`reg_ctrls'", "i.gender") > 0) {
                display "--- Joint test: Gender ---"
                testparm i.gender
            }
            if trim("`reg_ctrl_educ'") != "" {
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
            if trim("`reg_ctrl_bornus'") != "" & (strpos("`reg_ctrls'", "born_us") > 0) {
                display "--- Joint test: Born in U.S. ---"
                testparm born_us
            }
            if trim("`reg_ctrl_married'") != "" & (strpos("`reg_ctrls'", "married") > 0) {
                display "--- Joint test: Married ---"
                testparm married_2020
            }
        }

        display _n "-----------------------------------------------------------------------"
        display "Outcome: trust_others_2020"
        display "Regression uses listwise deletion (N may differ across models)"
        display "Controls in regression: `wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `stage_reg_add_`stage''"
        display "-----------------------------------------------------------------------"

        regress trust_others_2020 `wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `stage_reg_add_`stage'' ///
            , vce(robust)
        if trim("`wealth_r5_vars'") != "" {
            display "--- Joint test: Wealth deciles (net wealth) ---"
            testparm `wealth_r5_vars'
        }
        if trim("`reg_ctrl_age'") != "" {
            display "--- Joint test: Age bins ---"
            testparm i.age_bin
        }
        if trim("`reg_ctrl_gender'") != "" & (strpos("`stage_reg_add_`stage''", "i.gender") > 0) {
            display "--- Joint test: Gender ---"
            testparm i.gender
        }
        if trim("`reg_ctrl_educ'") != "" {
            display "--- Joint test: Education categories ---"
            testparm i.educ_cat
        }
        if trim("`reg_ctrl_race'") != "" & (strpos("`stage_reg_add_`stage''", "i.race_eth") > 0) {
            display "--- Joint test: Race ---"
            testparm i.race_eth
        }
        if trim("`reg_ctrl_region'") != "" & (strpos("`stage_reg_add_`stage''", "i.`region_var'") > 0) {
            display "--- Joint test: Region ---"
            testparm i.`region_var'
        }
        if trim("`reg_ctrl_bornus'") != "" & (strpos("`stage_reg_add_`stage''", "born_us") > 0) {
            display "--- Joint test: Born in U.S. ---"
            testparm born_us
        }
        if trim("`reg_ctrl_married'") != "" & (strpos("`stage_reg_add_`stage''", "married") > 0) {
            display "--- Joint test: Married ---"
            testparm married_2020
        }
    }

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

        foreach y of local ret_active_win_candidates {
            capture confirm variable `y'
            if _rc continue

            local reg_ctrls ""
            local wealth_test_list ""
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
            local reg_ctrls "`reg_ctrls' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `stage_reg_add_`stage''"

            if "`block'" != "`stage'" {
                local reg_ctrls "`reg_ctrls' `reg_ctrl_`block''"
            }

            display _n "-----------------------------------------------------------------------"
            display "Outcome: `y'"
            display "Regression uses listwise deletion (N may differ across models)"
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
            if trim("`reg_ctrl_bornus'") != "" & (strpos("`reg_ctrls'", "born_us") > 0) {
                display "--- Joint test: Born in U.S. ---"
                testparm born_us
            }
            if trim("`reg_ctrl_married'") != "" & (strpos("`reg_ctrls'", "married") > 0) {
                display "--- Joint test: Married ---"
                testparm married_2020
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
            if trim("`reg_ctrl_bornus'") != "" & (strpos("`reg_ctrls'", "born_us") > 0) {
                display "--- Joint test: Born in U.S. ---"
                testparm born_us
            }
            if trim("`reg_ctrl_married'") != "" & (strpos("`reg_ctrls'", "married") > 0) {
                display "--- Joint test: Married ---"
                testparm married_2020
            }
        }

        if "`block'" != "`stage'" {
            local trust_regressors "`wealth_r5_vars' `reg_ctrl_age' `reg_ctrl_inlbrf' `reg_ctrl_educ' `stage_reg_add_`stage'' `reg_ctrl_`block''"

            display _n "-----------------------------------------------------------------------"
            display "Outcome: trust_others_2020"
            display "Regression uses listwise deletion (N may differ across models)"
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
            if trim("`reg_ctrl_bornus'") != "" & (strpos("`trust_regressors'", "born_us") > 0) {
                display "--- Joint test: Born in U.S. ---"
                testparm born_us
            }
            if trim("`reg_ctrl_married'") != "" & (strpos("`trust_regressors'", "married") > 0) {
                display "--- Joint test: Married ---"
                testparm married_2020
            }
        }
    }
}

* ----------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------
display _n "########################################################################"
display "33_returns_control_build_2: Completed."
display "Log saved in: ${LOG_DIR}/33_returns_control_build_2.log"
display "########################################################################"

log close
