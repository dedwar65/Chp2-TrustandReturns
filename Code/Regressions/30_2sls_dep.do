* 30_2sls_dep.do
* Step-by-step checks: whether depression (contemporaneous, lagged, ever) predicts trust.
* Purpose: assess depression as potential instrument for trust (exclusion restriction: depression
*   should not directly affect returns; predictive of trust supports first-stage relevance).
* RAND HRS: r15cesd=2020, r14cesd=2018, r13cesd=2016, r12cesd=2014, ... (wave 6=2002).
* NOTE: r*cesd is treated as the CESD summary score here (not single-item categorical coding).
* Log: Notes/Logs/30_2sls_dep.log
* Table: Code/Regressions/2SLS/PredictTrust/trust_reg_depression_iv.tex
* Table: Code/Regressions/2SLS/PredictTrust/excl_restriction_r5_cs.tex (r5 cross-section)
* Table: Code/Regressions/2SLS/PredictTrust/excl_restriction_r5_avg.tex (r5 average)
* Table: Code/Regressions/2SLS/PredictTrust/excl_restriction_r5_panel.tex (r5 panel spec 1)

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
log using "${LOG_DIR}/30_2sls_dep.log", replace text

* ----------------------------------------------------------------------
* Load analysis sample, merge lagged CESD from all_data_merged
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Merge r*cesd from RAND longitudinal (all_data_merged has full RAND vars)
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

* Create lagged depression (RAND wave 14=2018, 13=2016, 12=2014, ...)
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
capture confirm variable r12cesd
if !_rc {
    capture drop depression_2014
    gen depression_2014 = r12cesd
}

* Ever depressed 2002-2020 (waves 6-15): 1 if CESD score > 0 in any wave
gen byte ever_depressed = 0
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc replace ever_depressed = 1 if r`w'cesd > 0 & !missing(r`w'cesd)
}
* Missing if no CESD response in any wave
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

* Age bins
capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* Controls (match 22 Addl Spec 7b / 29 baseline): demo + wealth + inlbrf + pop + region + born_us
* Exclude depression from controls when testing depression as predictor
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

local ctrl "`demo_core' `demo_race'"
capture confirm variable wealth_d2_2020
if !_rc {
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local ctrl "`ctrl' wealth_d`d'_2020"
    }
}
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
if "`region_var'" != "" local ctrl "`ctrl' i.`region_var'"
capture confirm variable born_us
if !_rc local ctrl "`ctrl' born_us"

* Sample: nonmissing trust
local samp "if !missing(trust_others_2020)"

* ----------------------------------------------------------------------
* STEP 1: Trust on contemporaneous depression (no controls)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 1: Trust on contemporaneous depression (no controls)"
display "########################################################################"
reg trust_others_2020 depression_2020 `samp', vce(robust)

* ----------------------------------------------------------------------
* STEP 2: Trust on contemporaneous depression + controls
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 2: Trust on contemporaneous depression + controls"
display "########################################################################"
eststo step2: reg trust_others_2020 depression_2020 `ctrl' `samp', vce(robust)
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : step2
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : step2
    }
    else estadd scalar p_joint_wealth = . : step2
    capture confirm variable race_eth
    if !_rc {
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : step2
    }
    else estadd scalar p_joint_race = . : step2
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : step2
        else estadd scalar p_joint_censreg = . : step2
    }
    else estadd scalar p_joint_censreg = . : step2

* ----------------------------------------------------------------------
* STEP 3: Trust on lagged depression only (2018)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 3: Trust on lagged depression (2018) only"
display "########################################################################"
capture confirm variable depression_2018
if !_rc {
    reg trust_others_2020 depression_2018 `samp', vce(robust)
}
else {
    display "depression_2018 not found (r14cesd missing). Skipped."
}

* ----------------------------------------------------------------------
* STEP 4: Trust on lagged depression (2018) + controls
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 4: Trust on lagged depression (2018) + controls"
display "########################################################################"
capture confirm variable depression_2018
if !_rc {
    eststo step4: reg trust_others_2020 depression_2018 `ctrl' `samp', vce(robust)
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : step4
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : step4
    }
    else estadd scalar p_joint_wealth = . : step4
    capture confirm variable race_eth
    if !_rc {
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : step4
    }
    else estadd scalar p_joint_race = . : step4
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : step4
        else estadd scalar p_joint_censreg = . : step4
    }
    else estadd scalar p_joint_censreg = . : step4
}
else {
    display "depression_2018 not found. Skipped."
}

* ----------------------------------------------------------------------
* STEP 5: Trust on multiple lags (2016 and 2018) + controls
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 5: Trust on multiple lags (2016, 2018) + controls"
display "########################################################################"
capture confirm variable depression_2016
local has_d2016 = (_rc == 0)
capture confirm variable depression_2018
local has_d2018 = (_rc == 0)
if `has_d2016' & `has_d2018' {
    eststo step5: reg trust_others_2020 depression_2016 depression_2018 `ctrl' `samp', vce(robust)
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : step5
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : step5
    }
    else estadd scalar p_joint_wealth = . : step5
    capture confirm variable race_eth
    if !_rc {
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : step5
    }
    else estadd scalar p_joint_race = . : step5
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : step5
        else estadd scalar p_joint_censreg = . : step5
    }
    else estadd scalar p_joint_censreg = . : step5
}
else {
    display "depression_2016 or depression_2018 not found. Skipped."
}

* ----------------------------------------------------------------------
* STEP 6: Trust on ever depressed (2002-2020)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "STEP 6a: Trust on ever depressed (no controls)"
display "########################################################################"
reg trust_others_2020 ever_depressed `samp', vce(robust)

display _n "########################################################################"
display "STEP 6b: Trust on ever depressed + controls"
display "########################################################################"
eststo step6b: reg trust_others_2020 ever_depressed `ctrl' `samp', vce(robust)
quietly testparm i.age_bin
estadd scalar p_joint_age_bin = r(p) : step6b
local wlist ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wlist "`wlist' wealth_d`d'_2020"
}
if trim("`wlist'") != "" {
    quietly testparm `wlist'
    estadd scalar p_joint_wealth = r(p) : step6b
}
else estadd scalar p_joint_wealth = . : step6b
capture confirm variable race_eth
if !_rc {
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : step6b
}
else estadd scalar p_joint_race = . : step6b
if "`region_var'" != "" {
    capture testparm i.`region_var'
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : step6b
    else estadd scalar p_joint_censreg = . : step6b
}
else estadd scalar p_joint_censreg = . : step6b

* ----------------------------------------------------------------------
* Table export: steps 2, 4, 5, 6b
* ----------------------------------------------------------------------
capture mkdir "${REGRESSIONS}/2SLS/PredictTrust"
local outfile "${REGRESSIONS}/2SLS/PredictTrust/trust_reg_depression_iv.tex"
local estlist "step2"
local mtlist `""No lag""'
capture confirm variable depression_2018
if !_rc local estlist "`estlist' step4"
if !_rc local mtlist `"`mtlist' "One lag""'
capture confirm variable depression_2016
if !_rc {
    capture confirm variable depression_2018
    if !_rc local estlist "`estlist' step5"
    if !_rc local mtlist `"`mtlist' "Two lags""'
}
local estlist "`estlist' step6b"
local mtlist `"`mtlist' "Ever depressed""'
* Drop age bins, wealth deciles, base factor levels (same as exclusion tables); keep controls + depression
local drop_trust_iv "1.gender 1.race_eth"
if "`region_var'" != "" local drop_trust_iv "`drop_trust_iv' 1.`region_var'"
capture confirm variable age_bin
if !_rc {
    estimates restore step2
    local cnames : colnames e(b)
    foreach c of local cnames {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_trust_iv "`drop_trust_iv' `c'"
    }
}
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local drop_trust_iv "`drop_trust_iv' wealth_d`d'_2020"
}
* Build order and varlabels for controls + depression (match trust_reg_general_untrust / exclusion structure)
local order_trust_iv "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020"
if "`region_var'" != "" local order_trust_iv "`order_trust_iv' 2.`region_var' 3.`region_var' 4.`region_var'"
capture confirm variable born_us
if !_rc local order_trust_iv "`order_trust_iv' born_us"
local order_trust_iv "`order_trust_iv' depression_2020 depression_2018 depression_2016 ever_depressed _cons"
local vl_trust_iv `"2.gender "Female" educ_yrs "Years of education" married_2020 "Married" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" born_us "Born in U.S." depression_2020 "Depression (no lag)" depression_2018 "Depression (lag 1)" depression_2016 "Depression (lag 2)" ever_depressed "Ever depressed" _cons "Constant""'
if "`region_var'" != "" local vl_trust_iv `"`vl_trust_iv' 2.`region_var' "Midwest" 3.`region_var' "South" 4.`region_var' "West""'
esttab `estlist' using "`outfile'", replace ///
    booktabs no gap ///
    mtitles(`mtlist') ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    drop(`drop_trust_iv' *.age_bin, relax) ///
    order(`order_trust_iv') ///
    varlabels(`vl_trust_iv') ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
    addnotes(".") nonumbers nonotes
display "Table saved: `outfile'"

* ----------------------------------------------------------------------
* Exclusion restriction: r5 on controls + depression (4 variants)
* Tables: r5 cross-section (2022), r5 average
* ----------------------------------------------------------------------
local y_r5_cs "r5_annual_w5_2022"
capture confirm variable `y_r5_cs'
if _rc local y_r5_cs "r5_annual_2022_w5"
local y_r5_avg "r5_annual_avg_w5"
capture confirm variable `y_r5_avg'
if _rc local y_r5_avg "r5_annual_avg"

* Base controls for exclusion restriction (match 18): demo + inlbrf + wealth + region, no depression
local ctrl_r5 "`demo_core' `demo_race' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}
if "`region_var'" != "" local ctrl_r5 "`ctrl_r5' i.`region_var'"

capture confirm variable `y_r5_cs'
local has_cs = (_rc == 0)
capture confirm variable `y_r5_avg'
local has_avg = (_rc == 0)
capture confirm variable trust_others_2020
local has_trust = (_rc == 0)

local trust_spec "c.trust_others_2020 c.trust_others_2020#c.trust_others_2020"
local samp_cs_trust "!missing(`y_r5_cs') & !missing(trust_others_2020)"
local samp_avg_trust "!missing(`y_r5_avg') & !missing(trust_others_2020)"

* Table 1: r5 cross-section (2022) on controls + depression + Trust + Trust² (No lag, One lag, Two lags, Ever depressed)
if `has_cs' & `has_trust' {
    display _n "########################################################################"
    display "EXCLUSION RESTRICTION: r5 cross-section (2022) on controls + depression + Trust + Trust²"
    display "########################################################################"
    eststo clear
    eststo excl_cs_1: reg `y_r5_cs' `ctrl_r5' depression_2020 `trust_spec' if `samp_cs_trust' & !missing(depression_2020), vce(robust)
    quietly testparm `trust_spec'
    estadd scalar p_joint_trust = r(p) : excl_cs_1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : excl_cs_1
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    quietly testparm `wlist'
    estadd scalar p_joint_wealth = r(p) : excl_cs_1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : excl_cs_1
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_cs_1
        else estadd scalar p_joint_censreg = . : excl_cs_1
    }
    else estadd scalar p_joint_censreg = . : excl_cs_1
    capture confirm variable depression_2018
    if !_rc {
        eststo excl_cs_2: reg `y_r5_cs' `ctrl_r5' depression_2018 `trust_spec' if `samp_cs_trust' & !missing(depression_2018), vce(robust)
        quietly testparm `trust_spec'
        estadd scalar p_joint_trust = r(p) : excl_cs_2
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : excl_cs_2
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : excl_cs_2
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_cs_2
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_cs_2
            else estadd scalar p_joint_censreg = . : excl_cs_2
        }
        else estadd scalar p_joint_censreg = . : excl_cs_2
    }
    if `has_d2016' & `has_d2018' {
        eststo excl_cs_3: reg `y_r5_cs' `ctrl_r5' depression_2016 depression_2018 `trust_spec' if `samp_cs_trust' & !missing(depression_2016) & !missing(depression_2018), vce(robust)
        quietly testparm `trust_spec'
        estadd scalar p_joint_trust = r(p) : excl_cs_3
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : excl_cs_3
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : excl_cs_3
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_cs_3
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_cs_3
            else estadd scalar p_joint_censreg = . : excl_cs_3
        }
        else estadd scalar p_joint_censreg = . : excl_cs_3
    }
    eststo excl_cs_4: reg `y_r5_cs' `ctrl_r5' ever_depressed `trust_spec' if `samp_cs_trust' & !missing(ever_depressed), vce(robust)
    quietly testparm `trust_spec'
    estadd scalar p_joint_trust = r(p) : excl_cs_4
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : excl_cs_4
    quietly testparm `wlist'
    estadd scalar p_joint_wealth = r(p) : excl_cs_4
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : excl_cs_4
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_cs_4
        else estadd scalar p_joint_censreg = . : excl_cs_4
    }
    else estadd scalar p_joint_censreg = . : excl_cs_4

    local excl_cs_list "excl_cs_1"
    local excl_cs_mt `""No lag""'
    capture confirm variable depression_2018
    if !_rc {
        local excl_cs_list "`excl_cs_list' excl_cs_2"
        local excl_cs_mt `"`excl_cs_mt' "One lag""'
    }
    if `has_d2016' & `has_d2018' {
        local excl_cs_list "`excl_cs_list' excl_cs_3"
        local excl_cs_mt `"`excl_cs_mt' "Two lags""'
    }
    local excl_cs_list "`excl_cs_list' excl_cs_4"
    local excl_cs_mt `"`excl_cs_mt' "Ever depressed""'

    local drop_excl "1.gender 1.race_eth"
    if "`region_var'" != "" local drop_excl "`drop_excl' 1.`region_var'"
    capture confirm variable age_bin
    if !_rc {
        estimates restore excl_cs_1
        local cnames : colnames e(b)
        foreach c of local cnames {
            if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_excl "`drop_excl' `c'"
        }
    }
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local drop_excl "`drop_excl' wealth_d`d'_2020"
    }
    local order_cs "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020"
    if "`region_var'" != "" local order_cs "`order_cs' 2.`region_var' 3.`region_var' 4.`region_var'"
    local order_cs "`order_cs' depression_2020 depression_2018 depression_2016 ever_depressed trust_others_2020 c.trust_others_2020#c.trust_others_2020 _cons"
    local vl_cs `"depression_2020 "Depression (no lag)" depression_2018 "Depression (lag 1)" depression_2016 "Depression (lag 2)" ever_depressed "Ever depressed" trust_others_2020 "Trust" c.trust_others_2020#c.trust_others_2020 "Trust\$^2\$" educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant""'
    if "`region_var'" != "" local vl_cs `"`vl_cs' 2.`region_var' "Midwest" 3.`region_var' "South" 4.`region_var' "West""'
    esttab `excl_cs_list' using "${REGRESSIONS}/2SLS/PredictTrust/excl_restriction_r5_cs.tex", replace ///
        booktabs no gap ///
        title("Exclusion restriction: r5 cross-section (2022) on controls + depression + Trust + Trust\$^2\$") ///
        mtitles(`excl_cs_mt') ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_excl' *.age_bin, relax) ///
        order(`order_cs') ///
        varlabels(`vl_cs') ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "Joint test: Trust only p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
        addnotes(".") nonumbers nonotes
    display "Exclusion restriction table (r5 cross-section) saved: excl_restriction_r5_cs.tex"
}

* Table 2: r5 average on controls + depression + Trust + Trust² (No lag, One lag, Two lags, Ever depressed)
if `has_avg' & `has_trust' {
    display _n "########################################################################"
    display "EXCLUSION RESTRICTION: r5 average on controls + depression + Trust + Trust²"
    display "########################################################################"
    eststo clear
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    eststo excl_avg_1: reg `y_r5_avg' `ctrl_r5' depression_2020 `trust_spec' if `samp_avg_trust' & !missing(depression_2020), vce(robust)
    quietly testparm `trust_spec'
    estadd scalar p_joint_trust = r(p) : excl_avg_1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : excl_avg_1
    quietly testparm `wlist'
    estadd scalar p_joint_wealth = r(p) : excl_avg_1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : excl_avg_1
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_avg_1
        else estadd scalar p_joint_censreg = . : excl_avg_1
    }
    else estadd scalar p_joint_censreg = . : excl_avg_1
    capture confirm variable depression_2018
    if !_rc {
        eststo excl_avg_2: reg `y_r5_avg' `ctrl_r5' depression_2018 `trust_spec' if `samp_avg_trust' & !missing(depression_2018), vce(robust)
        quietly testparm `trust_spec'
        estadd scalar p_joint_trust = r(p) : excl_avg_2
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : excl_avg_2
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : excl_avg_2
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_avg_2
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_avg_2
            else estadd scalar p_joint_censreg = . : excl_avg_2
        }
        else estadd scalar p_joint_censreg = . : excl_avg_2
    }
    if `has_d2016' & `has_d2018' {
        eststo excl_avg_3: reg `y_r5_avg' `ctrl_r5' depression_2016 depression_2018 `trust_spec' if `samp_avg_trust' & !missing(depression_2016) & !missing(depression_2018), vce(robust)
        quietly testparm `trust_spec'
        estadd scalar p_joint_trust = r(p) : excl_avg_3
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : excl_avg_3
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : excl_avg_3
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_avg_3
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_avg_3
            else estadd scalar p_joint_censreg = . : excl_avg_3
        }
        else estadd scalar p_joint_censreg = . : excl_avg_3
    }
    eststo excl_avg_4: reg `y_r5_avg' `ctrl_r5' ever_depressed `trust_spec' if `samp_avg_trust' & !missing(ever_depressed), vce(robust)
    quietly testparm `trust_spec'
    estadd scalar p_joint_trust = r(p) : excl_avg_4
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : excl_avg_4
    quietly testparm `wlist'
    estadd scalar p_joint_wealth = r(p) : excl_avg_4
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : excl_avg_4
    if "`region_var'" != "" {
        capture testparm i.`region_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_avg_4
        else estadd scalar p_joint_censreg = . : excl_avg_4
    }
    else estadd scalar p_joint_censreg = . : excl_avg_4

    local excl_avg_list "excl_avg_1"
    local excl_avg_mt `""No lag""'
    capture confirm variable depression_2018
    if !_rc {
        local excl_avg_list "`excl_avg_list' excl_avg_2"
        local excl_avg_mt `"`excl_avg_mt' "One lag""'
    }
    if `has_d2016' & `has_d2018' {
        local excl_avg_list "`excl_avg_list' excl_avg_3"
        local excl_avg_mt `"`excl_avg_mt' "Two lags""'
    }
    local excl_avg_list "`excl_avg_list' excl_avg_4"
    local excl_avg_mt `"`excl_avg_mt' "Ever depressed""'

    local drop_excl_avg "1.gender 1.race_eth"
    if "`region_var'" != "" local drop_excl_avg "`drop_excl_avg' 1.`region_var'"
    capture confirm variable age_bin
    if !_rc {
        estimates restore excl_avg_1
        local cnames : colnames e(b)
        foreach c of local cnames {
            if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_excl_avg "`drop_excl_avg' `c'"
        }
    }
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local drop_excl_avg "`drop_excl_avg' wealth_d`d'_2020"
    }
    local order_avg "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020"
    if "`region_var'" != "" local order_avg "`order_avg' 2.`region_var' 3.`region_var' 4.`region_var'"
    local order_avg "`order_avg' depression_2020 depression_2018 depression_2016 ever_depressed trust_others_2020 c.trust_others_2020#c.trust_others_2020 _cons"
    local vl_avg `"depression_2020 "Depression (no lag)" depression_2018 "Depression (lag 1)" depression_2016 "Depression (lag 2)" ever_depressed "Ever depressed" trust_others_2020 "Trust" c.trust_others_2020#c.trust_others_2020 "Trust\$^2\$" educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant""'
    if "`region_var'" != "" local vl_avg `"`vl_avg' 2.`region_var' "Midwest" 3.`region_var' "South" 4.`region_var' "West""'
    esttab `excl_avg_list' using "${REGRESSIONS}/2SLS/PredictTrust/excl_restriction_r5_avg.tex", replace ///
        booktabs no gap ///
        title("Exclusion restriction: r5 average on controls + depression + Trust + Trust\$^2\$") ///
        mtitles(`excl_avg_mt') ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_excl_avg' *.age_bin, relax) ///
        order(`order_avg') ///
        varlabels(`vl_avg') ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "Joint test: Trust only p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
        addnotes(".") nonumbers nonotes
    display "Exclusion restriction table (r5 average) saved: excl_restriction_r5_avg.tex"
}

* ----------------------------------------------------------------------
* Exclusion restriction: r5 panel (baseline spec 1) on controls + depression + Trust + Trust²
* Panel: analysis_final_long_unbalanced.dta; vce(cluster hhidpn)
* ----------------------------------------------------------------------
capture confirm file "${PROCESSED}/analysis_final_long_unbalanced.dta"
if !_rc {
    display _n "########################################################################"
    display "EXCLUSION RESTRICTION: r5 panel (spec 1) on controls + depression + Trust + Trust\$^2\$"
    display "########################################################################"
    use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
    set showbaselevels off
    xtset hhidpn year

    * Merge r*cesd for panel (waves 6-16 for years 2002-2022)
    preserve
    use "${CLEANED}/all_data_merged.dta", clear
    local pcesd_vars "hhidpn"
    forvalues w = 6/16 {
        capture confirm variable r`w'cesd
        if !_rc local pcesd_vars "`pcesd_vars' r`w'cesd"
    }
    keep `pcesd_vars'
    tempfile pcesd
    save "`pcesd'", replace
    restore
    merge m:1 hhidpn using "`pcesd'", nogen

    * Depression by year (contemporaneous): r6cesd=2002, r7cesd=2004, ... r16cesd=2022
    gen double depression = .
    forvalues w = 6/16 {
        local y = 1990 + 2 * `w'
        capture confirm variable r`w'cesd
        if !_rc replace depression = r`w'cesd if year == `y'
    }
    * Depression lag 1 (2 years ago): year 2020 -> r14cesd, year 2018 -> r13cesd, etc.
    gen double depression_lag1 = .
    forvalues w = 7/16 {
        local y = 1990 + 2 * `w'
        local wlag = `w' - 1
        capture confirm variable r`wlag'cesd
        if !_rc replace depression_lag1 = r`wlag'cesd if year == `y'
    }
    * Depression lag 2 (4 years ago)
    gen double depression_lag2 = .
    forvalues w = 8/16 {
        local y = 1990 + 2 * `w'
        local wlag = `w' - 2
        capture confirm variable r`wlag'cesd
        if !_rc replace depression_lag2 = r`wlag'cesd if year == `y'
    }
    * Ever depressed (time-invariant)
    gen byte ever_depressed_p = 0
    forvalues w = 6/16 {
        capture confirm variable r`w'cesd
        if !_rc replace ever_depressed_p = 1 if r`w'cesd > 0 & !missing(r`w'cesd)
    }
    local _pcesd ""
    forvalues w = 6/16 {
        capture confirm variable r`w'cesd
        if !_rc local _pcesd "`_pcesd' r`w'cesd"
    }
    if "`_pcesd'" != "" {
        egen _npcesd = rownonmiss(`_pcesd')
        replace ever_depressed_p = . if _npcesd == 0
        drop _npcesd
    }

    * Panel controls (match 14 spec 1 for r5)
    local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year"
    local ctrl_r5_p "`base_ctrl'"
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local ctrl_r5_p "`ctrl_r5_p' wealth_d`d'"
    }
    local trust_spec_p "c.trust_others_2020 c.trust_others_2020#c.trust_others_2020"

    capture confirm variable r5_annual_w5
    local has_r5w5 = (_rc == 0)
    capture confirm variable trust_others_2020
    local has_trust_p = (_rc == 0)

    if `has_r5w5' & `has_trust_p' {
        local wlist_p ""
        forvalues d = 2/10 {
            capture confirm variable wealth_d`d'
            if !_rc local wlist_p "`wlist_p' wealth_d`d'"
        }
        local age_var "age_bin"
        capture confirm variable age_bin_
        if !_rc local age_var "age_bin_"
        local cens_var "censreg"
        capture confirm variable censreg_
        if !_rc local cens_var "censreg_"

        eststo clear
        eststo excl_p1: reg r5_annual_w5 `ctrl_r5_p' depression `trust_spec_p' if !missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(depression), vce(cluster hhidpn)
        quietly testparm `trust_spec_p'
        estadd scalar p_joint_trust = r(p) : excl_p1
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : excl_p1
        else estadd scalar p_joint_age_bin = . : excl_p1
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : excl_p1
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_p1
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_p1
        else estadd scalar p_joint_censreg = . : excl_p1
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : excl_p1

        eststo excl_p2: reg r5_annual_w5 `ctrl_r5_p' depression_lag1 `trust_spec_p' if !missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(depression_lag1), vce(cluster hhidpn)
        quietly testparm `trust_spec_p'
        estadd scalar p_joint_trust = r(p) : excl_p2
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : excl_p2
        else estadd scalar p_joint_age_bin = . : excl_p2
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : excl_p2
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_p2
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_p2
        else estadd scalar p_joint_censreg = . : excl_p2
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : excl_p2

        eststo excl_p3: reg r5_annual_w5 `ctrl_r5_p' depression_lag1 depression_lag2 `trust_spec_p' if !missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(depression_lag1) & !missing(depression_lag2), vce(cluster hhidpn)
        quietly testparm `trust_spec_p'
        estadd scalar p_joint_trust = r(p) : excl_p3
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : excl_p3
        else estadd scalar p_joint_age_bin = . : excl_p3
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : excl_p3
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_p3
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_p3
        else estadd scalar p_joint_censreg = . : excl_p3
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : excl_p3

        eststo excl_p4: reg r5_annual_w5 `ctrl_r5_p' ever_depressed_p `trust_spec_p' if !missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(ever_depressed_p), vce(cluster hhidpn)
        quietly testparm `trust_spec_p'
        estadd scalar p_joint_trust = r(p) : excl_p4
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : excl_p4
        else estadd scalar p_joint_age_bin = . : excl_p4
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : excl_p4
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : excl_p4
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : excl_p4
        else estadd scalar p_joint_censreg = . : excl_p4
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : excl_p4

        * Drop age_bin, wealth, year, base levels (match 14/18)
        local drop_p "1.gender 1.race_eth"
        if "`cens_var'" != "" local drop_p "`drop_p' 1.`cens_var'"
        forvalues d = 2/10 {
            capture confirm variable wealth_d`d'
            if !_rc local drop_p "`drop_p' wealth_d`d'"
        }
        local order_p "2.gender educ_yrs 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us"
        if "`cens_var'" != "" local order_p "`order_p' 2.`cens_var' 3.`cens_var' 4.`cens_var'"
        local order_p "`order_p' depression depression_lag1 depression_lag2 ever_depressed_p trust_others_2020 c.trust_others_2020#c.trust_others_2020 _cons"
        local vl_p `"depression "Depression (no lag)" depression_lag1 "Depression (lag 1)" depression_lag2 "Depression (lag 2)" ever_depressed_p "Ever depressed" trust_others_2020 "Trust" c.trust_others_2020#c.trust_others_2020 "Trust\$^2\$" educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S." _cons "Constant""'
        if "`cens_var'" != "" local vl_p `"`vl_p' 2.`cens_var' "Midwest" 3.`cens_var' "South" 4.`cens_var' "West""'
        esttab excl_p1 excl_p2 excl_p3 excl_p4 using "${REGRESSIONS}/2SLS/PredictTrust/excl_restriction_r5_panel.tex", replace ///
            booktabs no gap ///
            title("Exclusion restriction: r5 panel (spec 1) on controls + depression + Trust + Trust\$^2\$") ///
            mtitles("No lag" "One lag" "Two lags" "Ever depressed") ///
            se star(* 0.10 ** 0.05 *** 0.01) ///
            b(2) se(2) label ///
            drop(`drop_p' *.age_bin *.age_bin_ *.year, relax) ///
            order(`order_p') ///
            varlabels(`vl_p') ///
            alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
            stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg p_joint_year, labels("Observations" "Adj. R-squared" "Joint test: Trust only p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value" "Joint test: Year p-value")) ///
            addnotes(".") nonumbers nonotes
        display "Exclusion restriction table (r5 panel) saved: excl_restriction_r5_panel.tex"
    }
    else {
        display "Panel exclusion restriction skipped: r5_annual_w5 or trust_others_2020 not found."
    }
}
else {
    display "Panel exclusion restriction skipped: analysis_final_long_unbalanced.dta not found. Run pipeline 00-10."
}

* ----------------------------------------------------------------------
* Summary: compare R², coefficient magnitude, significance across specs
* ----------------------------------------------------------------------
display _n "########################################################################"
display "Compare R², coefficient magnitude, and significance across steps."
display "Stronger first-stage (depression predicts trust) supports IV relevance."
display "########################################################################"

log close
