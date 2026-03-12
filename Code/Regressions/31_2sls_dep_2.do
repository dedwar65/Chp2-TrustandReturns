* 31_2sls_dep_2.do
* Full IV/2SLS: Trust and Trust² endogenous, instrumented by depression variants.
* Both endogenous regressors; use ivregress 2sls (not manual two-step).
* Log: Notes/Logs/31_2sls_dep_2.log
* Output: Code/Regressions/2SLS/Dep/

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
log using "${LOG_DIR}/31_2sls_dep_2.log", replace text

capture mkdir "${REGRESSIONS}/2SLS/Dep"

* ----------------------------------------------------------------------
* Load cross-section data, merge CESD
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

* Depression variants (match 30)
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

* Ever depressed + max_cesd for second instrument
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

* max_cesd = max of r6cesd..r15cesd (second instrument for ever_depressed)
capture drop max_cesd
egen double max_cesd = rowmax(r6cesd r7cesd r8cesd r9cesd r10cesd r11cesd r12cesd r13cesd r14cesd r15cesd)
local _cesd ""
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc local _cesd "`_cesd' r`w'cesd"
}
if "`_cesd'" != "" {
    egen _n_cesd = rownonmiss(`_cesd')
    replace max_cesd = . if _n_cesd == 0
    drop _n_cesd
}

* Depression squares
capture confirm variable depression_2020
if !_rc {
    capture drop depression_2020_sq
    gen double depression_2020_sq = depression_2020^2
}
capture confirm variable depression_2018
if !_rc {
    capture drop depression_2018_sq
    gen double depression_2018_sq = depression_2018^2
}
capture confirm variable depression_2016
if !_rc {
    capture drop depression_2016_sq
    gen double depression_2016_sq = depression_2016^2
}

* Endogenous quadratic
capture confirm variable trust_others_2020
if !_rc {
    capture drop trust_others_2020_sq
    gen double trust_others_2020_sq = trust_others_2020 * trust_others_2020
}

* Age bins
capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* Exogenous X (match 30, no population)
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

* Outcome and sample
local y_cs "r5_annual_w5_2022"
capture confirm variable `y_cs'
if _rc local y_cs "r5_annual_2022_w5"
local y_avg "r5_annual_avg_w5"
capture confirm variable `y_avg'
if _rc local y_avg "r5_annual_avg"

capture confirm variable depression_2016
local has_d2016 = (_rc == 0)
capture confirm variable depression_2018
local has_d2018 = (_rc == 0)

local wlist ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wlist "`wlist' wealth_d`d'_2020"
}

* ----------------------------------------------------------------------
* IV regressions: Cross-section
* ----------------------------------------------------------------------
display _n "########################################################################"
display "IV/2SLS CROSS-SECTION: r5 2022"
display "########################################################################"

capture confirm variable `y_cs'
local has_cs = (_rc == 0)
capture confirm variable trust_others_2020_sq
if _rc local has_cs = 0

if `has_cs' {
    eststo clear
    * No lag
    capture confirm variable depression_2020
    capture confirm variable depression_2020_sq
    if !_rc {
        local samp "!missing(`y_cs') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2020) & !missing(depression_2020_sq)"
        capture ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2020 depression_2020_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_cs_1: ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2020 depression_2020_sq) if `samp', vce(robust)
            * Postestimation
            capture estat firststage
            if !_rc {
                capture estadd scalar firststage_F = r(F)
                if _rc estadd scalar firststage_F = .
            }
            else estadd scalar firststage_F = . : iv_cs_1
            capture estat endogenous
            if !_rc {
                capture estadd scalar endog_p = r(p)
                if _rc estadd scalar endog_p = .
            }
            else estadd scalar endog_p = . : iv_cs_1
            capture estat overid
            if !_rc {
                capture estadd scalar overid_p = r(p)
                if _rc estadd scalar overid_p = .
            }
            else estadd scalar overid_p = . : iv_cs_1
            * Second-stage joint tests
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_cs_1
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_cs_1
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_cs_1
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_cs_1
                else estadd scalar p_joint_censreg = . : iv_cs_1
            }
            else estadd scalar p_joint_censreg = . : iv_cs_1
        }
    }
    * One lag
    capture confirm variable depression_2018
    capture confirm variable depression_2018_sq
    if !_rc {
        local samp "!missing(`y_cs') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2018) & !missing(depression_2018_sq)"
        capture ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2018 depression_2018_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_cs_2: ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2018 depression_2018_sq) if `samp', vce(robust)
            capture estat firststage
            if !_rc capture estadd scalar firststage_F = r(F) : iv_cs_2
            else estadd scalar firststage_F = . : iv_cs_2
            capture estat endogenous
            if !_rc capture estadd scalar endog_p = r(p) : iv_cs_2
            else estadd scalar endog_p = . : iv_cs_2
            capture estat overid
            if !_rc capture estadd scalar overid_p = r(p) : iv_cs_2
            else estadd scalar overid_p = . : iv_cs_2
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_cs_2
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_cs_2
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_cs_2
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_cs_2
                else estadd scalar p_joint_censreg = . : iv_cs_2
            }
            else estadd scalar p_joint_censreg = . : iv_cs_2
        }
    }
    * Two lags
    if `has_d2016' & `has_d2018' {
        local samp "!missing(`y_cs') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2016) & !missing(depression_2018) & !missing(depression_2016_sq) & !missing(depression_2018_sq)"
        capture ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2016 depression_2018 depression_2016_sq depression_2018_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_cs_3: ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2016 depression_2018 depression_2016_sq depression_2018_sq) if `samp', vce(robust)
            capture estat firststage
            if !_rc capture estadd scalar firststage_F = r(F) : iv_cs_3
            else estadd scalar firststage_F = . : iv_cs_3
            capture estat endogenous
            if !_rc capture estadd scalar endog_p = r(p) : iv_cs_3
            else estadd scalar endog_p = . : iv_cs_3
            capture estat overid
            if !_rc capture estadd scalar overid_p = r(p) : iv_cs_3
            else estadd scalar overid_p = . : iv_cs_3
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_cs_3
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_cs_3
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_cs_3
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_cs_3
                else estadd scalar p_joint_censreg = . : iv_cs_3
            }
            else estadd scalar p_joint_censreg = . : iv_cs_3
        }
    }
    * Ever depressed
    local samp "!missing(`y_cs') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(ever_depressed) & !missing(max_cesd)"
    capture ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = ever_depressed max_cesd) if `samp', vce(robust)
    if !_rc {
        eststo iv_cs_4: ivregress 2sls `y_cs' `ctrl_x' (trust_others_2020 trust_others_2020_sq = ever_depressed max_cesd) if `samp', vce(robust)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_cs_4
        else estadd scalar firststage_F = . : iv_cs_4
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_cs_4
        else estadd scalar endog_p = . : iv_cs_4
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_cs_4
        else estadd scalar overid_p = . : iv_cs_4
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : iv_cs_4
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : iv_cs_4
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_cs_4
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_cs_4
            else estadd scalar p_joint_censreg = . : iv_cs_4
        }
        else estadd scalar p_joint_censreg = . : iv_cs_4
    }

    * Export second-stage table (cross-section)
    local iv_cs_list "iv_cs_1"
    local iv_cs_mt `""No lag""'
    capture estimates dir iv_cs_2
    if !_rc {
        local iv_cs_list "`iv_cs_list' iv_cs_2"
        local iv_cs_mt `"`iv_cs_mt' "One lag""'
    }
    capture estimates dir iv_cs_3
    if !_rc {
        local iv_cs_list "`iv_cs_list' iv_cs_3"
        local iv_cs_mt `"`iv_cs_mt' "Two lags""'
    }
    capture estimates dir iv_cs_4
    if !_rc {
        local iv_cs_list "`iv_cs_list' iv_cs_4"
        local iv_cs_mt `"`iv_cs_mt' "Ever depressed""'
    }

    local drop_ss "1.gender 1.race_eth"
    if "`region_var'" != "" local drop_ss "`drop_ss' 1.`region_var'"
    capture confirm variable age_bin
    if !_rc {
        estimates restore iv_cs_1
        local cnames : colnames e(b)
        foreach c of local cnames {
            if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_ss "`drop_ss' `c'"
        }
    }
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local drop_ss "`drop_ss' wealth_d`d'_2020"
    }
    local order_ss "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020"
    if "`region_var'" != "" local order_ss "`order_ss' 2.`region_var' 3.`region_var' 4.`region_var'"
    capture confirm variable born_us
    if !_rc local order_ss "`order_ss' born_us"
    local order_ss "`order_ss' trust_others_2020 trust_others_2020_sq _cons"
    local vl_ss `"2.gender "Female" educ_yrs "Years of education" married_2020 "Married" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" born_us "Born in U.S." trust_others_2020 "Trust" trust_others_2020_sq "Trust\$^2\$" _cons "Constant""'
    if "`region_var'" != "" local vl_ss `"`vl_ss' 2.`region_var' "Midwest" 3.`region_var' "South" 4.`region_var' "West""'

    esttab `iv_cs_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_cs_second_stage.tex", replace ///
        booktabs no gap ///
        title("IV/2SLS second stage: r5 cross-section (2022)") ///
        mtitles(`iv_cs_mt') ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_ss' *.age_bin, relax) ///
        order(`order_ss') ///
        varlabels(`vl_ss') ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a firststage_F endog_p overid_p p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "First-stage F" "Endogeneity p-value" "Overid p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
        addnotes(".") nonumbers nonotes
    display "Second-stage table (cross-section) saved: iv_dep_r5_cs_second_stage.tex"
}

* ----------------------------------------------------------------------
* IV regressions: Average returns
* ----------------------------------------------------------------------
display _n "########################################################################"
display "IV/2SLS AVERAGE RETURNS"
display "########################################################################"

capture confirm variable `y_avg'
local has_avg = (_rc == 0)
if `has_avg' {
    eststo clear
    * No lag
    capture confirm variable depression_2020
    capture confirm variable depression_2020_sq
    if !_rc {
        local samp "!missing(`y_avg') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2020) & !missing(depression_2020_sq)"
        capture ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2020 depression_2020_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_avg_1: ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2020 depression_2020_sq) if `samp', vce(robust)
            capture estat firststage
            if !_rc capture estadd scalar firststage_F = r(F) : iv_avg_1
            else estadd scalar firststage_F = . : iv_avg_1
            capture estat endogenous
            if !_rc capture estadd scalar endog_p = r(p) : iv_avg_1
            else estadd scalar endog_p = . : iv_avg_1
            capture estat overid
            if !_rc capture estadd scalar overid_p = r(p) : iv_avg_1
            else estadd scalar overid_p = . : iv_avg_1
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_avg_1
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_avg_1
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_avg_1
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_avg_1
                else estadd scalar p_joint_censreg = . : iv_avg_1
            }
            else estadd scalar p_joint_censreg = . : iv_avg_1
        }
    }
    * One lag
    capture confirm variable depression_2018
    capture confirm variable depression_2018_sq
    if !_rc {
        local samp "!missing(`y_avg') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2018) & !missing(depression_2018_sq)"
        capture ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2018 depression_2018_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_avg_2: ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2018 depression_2018_sq) if `samp', vce(robust)
            capture estat firststage
            if !_rc capture estadd scalar firststage_F = r(F) : iv_avg_2
            else estadd scalar firststage_F = . : iv_avg_2
            capture estat endogenous
            if !_rc capture estadd scalar endog_p = r(p) : iv_avg_2
            else estadd scalar endog_p = . : iv_avg_2
            capture estat overid
            if !_rc capture estadd scalar overid_p = r(p) : iv_avg_2
            else estadd scalar overid_p = . : iv_avg_2
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_avg_2
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_avg_2
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_avg_2
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_avg_2
                else estadd scalar p_joint_censreg = . : iv_avg_2
            }
            else estadd scalar p_joint_censreg = . : iv_avg_2
        }
    }
    * Two lags
    if `has_d2016' & `has_d2018' {
        local samp "!missing(`y_avg') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_2016) & !missing(depression_2018) & !missing(depression_2016_sq) & !missing(depression_2018_sq)"
        capture ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2016 depression_2018 depression_2016_sq depression_2018_sq) if `samp', vce(robust)
        if !_rc {
            eststo iv_avg_3: ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = depression_2016 depression_2018 depression_2016_sq depression_2018_sq) if `samp', vce(robust)
            capture estat firststage
            if !_rc capture estadd scalar firststage_F = r(F) : iv_avg_3
            else estadd scalar firststage_F = . : iv_avg_3
            capture estat endogenous
            if !_rc capture estadd scalar endog_p = r(p) : iv_avg_3
            else estadd scalar endog_p = . : iv_avg_3
            capture estat overid
            if !_rc capture estadd scalar overid_p = r(p) : iv_avg_3
            else estadd scalar overid_p = . : iv_avg_3
            quietly testparm i.age_bin
            estadd scalar p_joint_age_bin = r(p) : iv_avg_3
            quietly testparm `wlist'
            estadd scalar p_joint_wealth = r(p) : iv_avg_3
            quietly testparm i.race_eth
            estadd scalar p_joint_race = r(p) : iv_avg_3
            if "`region_var'" != "" {
                capture testparm i.`region_var'
                if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_avg_3
                else estadd scalar p_joint_censreg = . : iv_avg_3
            }
            else estadd scalar p_joint_censreg = . : iv_avg_3
        }
    }
    * Ever depressed
    local samp "!missing(`y_avg') & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(ever_depressed) & !missing(max_cesd)"
    capture ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = ever_depressed max_cesd) if `samp', vce(robust)
    if !_rc {
        eststo iv_avg_4: ivregress 2sls `y_avg' `ctrl_x' (trust_others_2020 trust_others_2020_sq = ever_depressed max_cesd) if `samp', vce(robust)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_avg_4
        else estadd scalar firststage_F = . : iv_avg_4
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_avg_4
        else estadd scalar endog_p = . : iv_avg_4
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_avg_4
        else estadd scalar overid_p = . : iv_avg_4
        quietly testparm i.age_bin
        estadd scalar p_joint_age_bin = r(p) : iv_avg_4
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : iv_avg_4
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_avg_4
        if "`region_var'" != "" {
            capture testparm i.`region_var'
            if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_avg_4
            else estadd scalar p_joint_censreg = . : iv_avg_4
        }
        else estadd scalar p_joint_censreg = . : iv_avg_4
    }

    * Export second-stage table (average)
    local iv_avg_list "iv_avg_1"
    local iv_avg_mt `""No lag""'
    capture estimates dir iv_avg_2
    if !_rc {
        local iv_avg_list "`iv_avg_list' iv_avg_2"
        local iv_avg_mt `"`iv_avg_mt' "One lag""'
    }
    capture estimates dir iv_avg_3
    if !_rc {
        local iv_avg_list "`iv_avg_list' iv_avg_3"
        local iv_avg_mt `"`iv_avg_mt' "Two lags""'
    }
    capture estimates dir iv_avg_4
    if !_rc {
        local iv_avg_list "`iv_avg_list' iv_avg_4"
        local iv_avg_mt `"`iv_avg_mt' "Ever depressed""'
    }

    esttab `iv_avg_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_avg_second_stage.tex", replace ///
        booktabs no gap ///
        title("IV/2SLS second stage: r5 average") ///
        mtitles(`iv_avg_mt') ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_ss' *.age_bin, relax) ///
        order(`order_ss') ///
        varlabels(`vl_ss') ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a firststage_F endog_p overid_p p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "First-stage F" "Endogeneity p-value" "Overid p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
        addnotes(".") nonumbers nonotes
    display "Second-stage table (average) saved: iv_dep_r5_avg_second_stage.tex"
}

* ----------------------------------------------------------------------
* First-stage tables: run first-stage regressions separately
* ----------------------------------------------------------------------
display _n "########################################################################"
display "FIRST-STAGE TABLES"
display "########################################################################"

* Cross-section first stage: Trust and Trust² on X + Z
eststo clear
* Trust equation
eststo fs_cs_t1: reg trust_others_2020 `ctrl_x' depression_2020 depression_2020_sq if !missing(trust_others_2020) & !missing(depression_2020) & !missing(depression_2020_sq), vce(robust)
eststo fs_cs_t2: reg trust_others_2020 `ctrl_x' depression_2018 depression_2018_sq if !missing(trust_others_2020) & !missing(depression_2018) & !missing(depression_2018_sq), vce(robust)
if `has_d2016' & `has_d2018' eststo fs_cs_t3: reg trust_others_2020 `ctrl_x' depression_2016 depression_2018 depression_2016_sq depression_2018_sq if !missing(trust_others_2020) & !missing(depression_2016) & !missing(depression_2018), vce(robust)
eststo fs_cs_t4: reg trust_others_2020 `ctrl_x' ever_depressed max_cesd if !missing(trust_others_2020) & !missing(ever_depressed) & !missing(max_cesd), vce(robust)

local drop_fs "1.gender 1.race_eth"
if "`region_var'" != "" local drop_fs "`drop_fs' 1.`region_var'"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local drop_fs "`drop_fs' wealth_d`d'_2020"
}
local order_fs "2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020"
if "`region_var'" != "" local order_fs "`order_fs' 2.`region_var' 3.`region_var' 4.`region_var'"
local order_fs "`order_fs' born_us depression_2020 depression_2020_sq depression_2018 depression_2018_sq depression_2016 depression_2016_sq ever_depressed max_cesd _cons"
local vl_fs `"2.gender "Female" educ_yrs "Years of education" married_2020 "Married" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" born_us "Born in U.S." depression_2020 "Depression (no lag)" depression_2020_sq "Depression (no lag)\$^2\$" depression_2018 "Depression (lag 1)" depression_2018_sq "Depression (lag 1)\$^2\$" depression_2016 "Depression (lag 2)" depression_2016_sq "Depression (lag 2)\$^2\$" ever_depressed "Ever depressed" max_cesd "Max CESD" _cons "Constant""'
if "`region_var'" != "" local vl_fs `"`vl_fs' 2.`region_var' "Midwest" 3.`region_var' "South" 4.`region_var' "West""'

local fs_cs_list "fs_cs_t1"
local fs_cs_mt `""No lag""'
capture estimates dir fs_cs_t2
if !_rc {
    local fs_cs_list "`fs_cs_list' fs_cs_t2"
    local fs_cs_mt `"`fs_cs_mt' "One lag""'
}
capture estimates dir fs_cs_t3
if !_rc {
    local fs_cs_list "`fs_cs_list' fs_cs_t3"
    local fs_cs_mt `"`fs_cs_mt' "Two lags""'
}
local fs_cs_list "`fs_cs_list' fs_cs_t4"
local fs_cs_mt `"`fs_cs_mt' "Ever depressed""'

esttab `fs_cs_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_cs_first_stage.tex", replace ///
    booktabs no gap ///
    title("IV first stage: Trust on X + Z (cross-section)") ///
    mtitles(`fs_cs_mt') ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    drop(`drop_fs' *.age_bin, relax) ///
    order(`order_fs') ///
    varlabels(`vl_fs') ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    addnotes(".") nonumbers nonotes
display "First-stage table (Trust, cross-section) saved: iv_dep_r5_cs_first_stage.tex"

* Trust² first stage
eststo clear
eststo fs_cs_sq1: reg trust_others_2020_sq `ctrl_x' depression_2020 depression_2020_sq if !missing(trust_others_2020_sq) & !missing(depression_2020) & !missing(depression_2020_sq), vce(robust)
eststo fs_cs_sq2: reg trust_others_2020_sq `ctrl_x' depression_2018 depression_2018_sq if !missing(trust_others_2020_sq) & !missing(depression_2018) & !missing(depression_2018_sq), vce(robust)
if `has_d2016' & `has_d2018' eststo fs_cs_sq3: reg trust_others_2020_sq `ctrl_x' depression_2016 depression_2018 depression_2016_sq depression_2018_sq if !missing(trust_others_2020_sq) & !missing(depression_2016) & !missing(depression_2018), vce(robust)
eststo fs_cs_sq4: reg trust_others_2020_sq `ctrl_x' ever_depressed max_cesd if !missing(trust_others_2020_sq) & !missing(ever_depressed) & !missing(max_cesd), vce(robust)

local fs_cs_sq_list "fs_cs_sq1"
local fs_cs_sq_mt `""No lag""'
capture estimates dir fs_cs_sq2
if !_rc {
    local fs_cs_sq_list "`fs_cs_sq_list' fs_cs_sq2"
    local fs_cs_sq_mt `"`fs_cs_sq_mt' "One lag""'
}
capture estimates dir fs_cs_sq3
if !_rc {
    local fs_cs_sq_list "`fs_cs_sq_list' fs_cs_sq3"
    local fs_cs_sq_mt `"`fs_cs_sq_mt' "Two lags""'
}
local fs_cs_sq_list "`fs_cs_sq_list' fs_cs_sq4"
local fs_cs_sq_mt `"`fs_cs_sq_mt' "Ever depressed""'

esttab `fs_cs_sq_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_cs_first_stage_sq.tex", replace ///
    booktabs no gap ///
    title("IV first stage: Trust\$^2\$ on X + Z (cross-section)") ///
    mtitles(`fs_cs_sq_mt') ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    drop(`drop_fs' *.age_bin, relax) ///
    order(`order_fs') ///
    varlabels(`vl_fs') ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    addnotes(".") nonumbers nonotes
display "First-stage table (Trust², cross-section) saved: iv_dep_r5_cs_first_stage_sq.tex"

* ----------------------------------------------------------------------
* Panel IV (load panel data)
* ----------------------------------------------------------------------
capture confirm file "${PROCESSED}/analysis_final_long_unbalanced.dta"
if !_rc {
    display _n "########################################################################"
    display "IV/2SLS PANEL"
    display "########################################################################"
    use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
    set showbaselevels off
    xtset hhidpn year

    * Merge CESD for panel
    preserve
    use "${CLEANED}/all_data_merged.dta", clear
    local pcesd "hhidpn"
    forvalues w = 6/16 {
        capture confirm variable r`w'cesd
        if !_rc local pcesd "`pcesd' r`w'cesd"
    }
    keep `pcesd'
    tempfile pcesd
    save "`pcesd'", replace
    restore
    merge m:1 hhidpn using "`pcesd'", nogen

    * Panel depression vars
    gen double depression = .
    forvalues w = 6/16 {
        local y = 1990 + 2 * `w'
        capture confirm variable r`w'cesd
        if !_rc replace depression = r`w'cesd if year == `y'
    }
    gen double depression_lag1 = .
    forvalues w = 7/16 {
        local y = 1990 + 2 * `w'
        local wlag = `w' - 1
        capture confirm variable r`wlag'cesd
        if !_rc replace depression_lag1 = r`wlag'cesd if year == `y'
    }
    gen double depression_lag2 = .
    forvalues w = 8/16 {
        local y = 1990 + 2 * `w'
        local wlag = `w' - 2
        capture confirm variable r`wlag'cesd
        if !_rc replace depression_lag2 = r`wlag'cesd if year == `y'
    }
    gen byte ever_depressed_p = 0
    forvalues w = 6/16 {
        capture confirm variable r`w'cesd
        if !_rc replace ever_depressed_p = 1 if r`w'cesd > 0 & !missing(r`w'cesd)
    }
    egen _npcesd = rownonmiss(r6cesd-r16cesd)
    replace ever_depressed_p = . if _npcesd == 0
    drop _npcesd
    capture drop max_cesd
    egen double max_cesd = rowmax(r6cesd r7cesd r8cesd r9cesd r10cesd r11cesd r12cesd r13cesd r14cesd r15cesd r16cesd)
    capture drop depression_sq depression_lag1_sq depression_lag2_sq
    gen double depression_sq = depression^2
    gen double depression_lag1_sq = depression_lag1^2
    gen double depression_lag2_sq = depression_lag2^2
    capture drop trust_others_2020_sq
    gen double trust_others_2020_sq = trust_others_2020^2

    local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year"
    local ctrl_p "`base_ctrl'"
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local ctrl_p "`ctrl_p' wealth_d`d'"
    }
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
    * No lag
    local samp "!missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression) & !missing(depression_sq)"
    capture ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression depression_sq) if `samp', vce(cluster hhidpn)
    if !_rc {
        eststo iv_p1: ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression depression_sq) if `samp', vce(cluster hhidpn)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_p1
        else estadd scalar firststage_F = . : iv_p1
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_p1
        else estadd scalar endog_p = . : iv_p1
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_p1
        else estadd scalar overid_p = . : iv_p1
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : iv_p1
        else estadd scalar p_joint_age_bin = . : iv_p1
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : iv_p1
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_p1
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_p1
        else estadd scalar p_joint_censreg = . : iv_p1
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : iv_p1
    }
    * One lag
    local samp "!missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_lag1) & !missing(depression_lag1_sq)"
    capture ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression_lag1 depression_lag1_sq) if `samp', vce(cluster hhidpn)
    if !_rc {
        eststo iv_p2: ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression_lag1 depression_lag1_sq) if `samp', vce(cluster hhidpn)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_p2
        else estadd scalar firststage_F = . : iv_p2
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_p2
        else estadd scalar endog_p = . : iv_p2
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_p2
        else estadd scalar overid_p = . : iv_p2
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : iv_p2
        else estadd scalar p_joint_age_bin = . : iv_p2
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : iv_p2
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_p2
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_p2
        else estadd scalar p_joint_censreg = . : iv_p2
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : iv_p2
    }
    * Two lags
    local samp "!missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(depression_lag1) & !missing(depression_lag2) & !missing(depression_lag1_sq) & !missing(depression_lag2_sq)"
    capture ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression_lag1 depression_lag2 depression_lag1_sq depression_lag2_sq) if `samp', vce(cluster hhidpn)
    if !_rc {
        eststo iv_p3: ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = depression_lag1 depression_lag2 depression_lag1_sq depression_lag2_sq) if `samp', vce(cluster hhidpn)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_p3
        else estadd scalar firststage_F = . : iv_p3
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_p3
        else estadd scalar endog_p = . : iv_p3
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_p3
        else estadd scalar overid_p = . : iv_p3
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : iv_p3
        else estadd scalar p_joint_age_bin = . : iv_p3
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : iv_p3
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_p3
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_p3
        else estadd scalar p_joint_censreg = . : iv_p3
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : iv_p3
    }
    * Ever depressed
    local samp "!missing(r5_annual_w5) & !missing(trust_others_2020) & !missing(trust_others_2020_sq) & !missing(ever_depressed_p) & !missing(max_cesd)"
    capture ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = ever_depressed_p max_cesd) if `samp', vce(cluster hhidpn)
    if !_rc {
        eststo iv_p4: ivregress 2sls r5_annual_w5 `ctrl_p' (trust_others_2020 trust_others_2020_sq = ever_depressed_p max_cesd) if `samp', vce(cluster hhidpn)
        capture estat firststage
        if !_rc capture estadd scalar firststage_F = r(F) : iv_p4
        else estadd scalar firststage_F = . : iv_p4
        capture estat endogenous
        if !_rc capture estadd scalar endog_p = r(p) : iv_p4
        else estadd scalar endog_p = . : iv_p4
        capture estat overid
        if !_rc capture estadd scalar overid_p = r(p) : iv_p4
        else estadd scalar overid_p = . : iv_p4
        capture testparm i.`age_var'
        if _rc == 0 estadd scalar p_joint_age_bin = r(p) : iv_p4
        else estadd scalar p_joint_age_bin = . : iv_p4
        quietly testparm `wlist_p'
        estadd scalar p_joint_wealth = r(p) : iv_p4
        quietly testparm i.race_eth
        estadd scalar p_joint_race = r(p) : iv_p4
        capture testparm i.`cens_var'
        if _rc == 0 estadd scalar p_joint_censreg = r(p) : iv_p4
        else estadd scalar p_joint_censreg = . : iv_p4
        quietly testparm i.year
        estadd scalar p_joint_year = r(p) : iv_p4
    }

    * Export panel second-stage
    local iv_p_list "iv_p1"
    local iv_p_mt `""No lag""'
    capture estimates dir iv_p2
    if !_rc {
        local iv_p_list "`iv_p_list' iv_p2"
        local iv_p_mt `"`iv_p_mt' "One lag""'
    }
    capture estimates dir iv_p3
    if !_rc {
        local iv_p_list "`iv_p_list' iv_p3"
        local iv_p_mt `"`iv_p_mt' "Two lags""'
    }
    capture estimates dir iv_p4
    if !_rc {
        local iv_p_list "`iv_p_list' iv_p4"
        local iv_p_mt `"`iv_p_mt' "Ever depressed""'
    }

    local drop_p "1.gender 1.race_eth"
    if "`cens_var'" != "" local drop_p "`drop_p' 1.`cens_var'"
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local drop_p "`drop_p' wealth_d`d'"
    }
    local order_p "2.gender educ_yrs 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us"
    if "`cens_var'" != "" local order_p "`order_p' 2.`cens_var' 3.`cens_var' 4.`cens_var'"
    local order_p "`order_p' trust_others_2020 trust_others_2020_sq _cons"
    local vl_p `"2.gender "Female" educ_yrs "Years of education" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S." trust_others_2020 "Trust" trust_others_2020_sq "Trust\$^2\$" _cons "Constant""'
    if "`cens_var'" != "" local vl_p `"`vl_p' 2.`cens_var' "Midwest" 3.`cens_var' "South" 4.`cens_var' "West""'

    esttab `iv_p_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_panel_second_stage.tex", replace ///
        booktabs no gap ///
        title("IV/2SLS second stage: r5 panel (spec 1)") ///
        mtitles(`iv_p_mt') ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_p' *.age_bin *.age_bin_ *.year, relax) ///
        order(`order_p') ///
        varlabels(`vl_p') ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a firststage_F endog_p overid_p p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg p_joint_year, labels("Observations" "Adj. R-squared" "First-stage F" "Endogeneity p-value" "Overid p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value" "Joint test: Year p-value")) ///
        addnotes(".") nonumbers nonotes
    display "Second-stage table (panel) saved: iv_dep_r5_panel_second_stage.tex"

    * Panel first-stage tables (Trust and Trust²)
    eststo clear
    eststo fs_p_t1: reg trust_others_2020 `ctrl_p' depression depression_sq if !missing(trust_others_2020) & !missing(depression) & !missing(depression_sq), vce(cluster hhidpn)
    eststo fs_p_t2: reg trust_others_2020 `ctrl_p' depression_lag1 depression_lag1_sq if !missing(trust_others_2020) & !missing(depression_lag1) & !missing(depression_lag1_sq), vce(cluster hhidpn)
    eststo fs_p_t3: reg trust_others_2020 `ctrl_p' depression_lag1 depression_lag2 depression_lag1_sq depression_lag2_sq if !missing(trust_others_2020) & !missing(depression_lag1) & !missing(depression_lag2), vce(cluster hhidpn)
    eststo fs_p_t4: reg trust_others_2020 `ctrl_p' ever_depressed_p max_cesd if !missing(trust_others_2020) & !missing(ever_depressed_p) & !missing(max_cesd), vce(cluster hhidpn)

    local drop_fs_p "1.gender 1.race_eth"
    if "`cens_var'" != "" local drop_fs_p "`drop_fs_p' 1.`cens_var'"
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local drop_fs_p "`drop_fs_p' wealth_d`d'"
    }

    esttab fs_p_t1 fs_p_t2 fs_p_t3 fs_p_t4 using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_panel_first_stage.tex", replace ///
        booktabs no gap ///
        title("IV first stage: Trust on X + Z (panel)") ///
        mtitles("No lag" "One lag" "Two lags" "Ever depressed") ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_fs_p' *.age_bin *.age_bin_ *.year, relax) ///
        order(2.gender educ_yrs 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us 2.`cens_var' 3.`cens_var' 4.`cens_var' depression depression_sq depression_lag1 depression_lag1_sq depression_lag2 depression_lag2_sq ever_depressed_p max_cesd _cons) ///
        varlabels(depression "Depression (no lag)" depression_sq "Depression (no lag)\$^2\$" depression_lag1 "Depression (lag 1)" depression_lag1_sq "Depression (lag 1)\$^2\$" depression_lag2 "Depression (lag 2)" depression_lag2_sq "Depression (lag 2)\$^2\$" ever_depressed_p "Ever depressed" max_cesd "Max CESD" 2.gender "Female" educ_yrs "Years of education" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S." _cons "Constant") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        addnotes(".") nonumbers nonotes
    display "First-stage table (Trust, panel) saved: iv_dep_r5_panel_first_stage.tex"
}
else {
    display "Panel IV skipped: analysis_final_long_unbalanced.dta not found."
}

* ----------------------------------------------------------------------
* Average first-stage tables
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
merge 1:1 hhidpn using "`cesd'", nogen
* Rebuild vars (already in memory from before panel load - need to reload)
capture confirm variable depression_2020
if _rc {
    capture confirm variable r15cesd
    if !_rc gen depression_2020 = r15cesd
}
capture confirm variable depression_2020_sq
if _rc gen double depression_2020_sq = depression_2020^2
capture confirm variable depression_2018
if _rc {
    capture confirm variable r14cesd
    if !_rc gen depression_2018 = r14cesd
}
capture confirm variable depression_2018_sq
if _rc gen double depression_2018_sq = depression_2018^2
capture confirm variable depression_2016
if _rc {
    capture confirm variable r13cesd
    if !_rc gen depression_2016 = r13cesd
}
capture confirm variable depression_2016_sq
if _rc gen double depression_2016_sq = depression_2016^2
capture confirm variable ever_depressed
if _rc {
    gen byte ever_depressed = 0
    forvalues w = 6/15 {
        capture confirm variable r`w'cesd
        if !_rc replace ever_depressed = 1 if r`w'cesd > 0 & !missing(r`w'cesd)
    }
}
capture confirm variable max_cesd
if _rc egen double max_cesd = rowmax(r6cesd r7cesd r8cesd r9cesd r10cesd r11cesd r12cesd r13cesd r14cesd r15cesd)
capture confirm variable trust_others_2020_sq
if _rc gen double trust_others_2020_sq = trust_others_2020^2

eststo clear
eststo fs_avg_t1: reg trust_others_2020 `ctrl_x' depression_2020 depression_2020_sq if !missing(trust_others_2020) & !missing(`y_avg') & !missing(depression_2020) & !missing(depression_2020_sq), vce(robust)
eststo fs_avg_t2: reg trust_others_2020 `ctrl_x' depression_2018 depression_2018_sq if !missing(trust_others_2020) & !missing(`y_avg') & !missing(depression_2018) & !missing(depression_2018_sq), vce(robust)
if `has_d2016' & `has_d2018' eststo fs_avg_t3: reg trust_others_2020 `ctrl_x' depression_2016 depression_2018 depression_2016_sq depression_2018_sq if !missing(trust_others_2020) & !missing(`y_avg') & !missing(depression_2016) & !missing(depression_2018), vce(robust)
eststo fs_avg_t4: reg trust_others_2020 `ctrl_x' ever_depressed max_cesd if !missing(trust_others_2020) & !missing(`y_avg') & !missing(ever_depressed) & !missing(max_cesd), vce(robust)

local fs_avg_list "fs_avg_t1"
local fs_avg_mt `""No lag""'
capture estimates dir fs_avg_t2
if !_rc {
    local fs_avg_list "`fs_avg_list' fs_avg_t2"
    local fs_avg_mt `"`fs_avg_mt' "One lag""'
}
capture estimates dir fs_avg_t3
if !_rc {
    local fs_avg_list "`fs_avg_list' fs_avg_t3"
    local fs_avg_mt `"`fs_avg_mt' "Two lags""'
}
local fs_avg_list "`fs_avg_list' fs_avg_t4"
local fs_avg_mt `"`fs_avg_mt' "Ever depressed""'

esttab `fs_avg_list' using "${REGRESSIONS}/2SLS/Dep/iv_dep_r5_avg_first_stage.tex", replace ///
    booktabs no gap ///
    title("IV first stage: Trust on X + Z (average)") ///
    mtitles(`fs_avg_mt') ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    drop(`drop_fs' *.age_bin, relax) ///
    order(2.gender educ_yrs married_2020 2.race_eth 3.race_eth 4.race_eth inlbrf_2020 2.`region_var' 3.`region_var' 4.`region_var' born_us depression_2020 depression_2020_sq depression_2018 depression_2018_sq ever_depressed max_cesd _cons) ///
    varlabels(depression_2020 "Depression (no lag)" depression_2020_sq "Depression (no lag)\$^2\$" depression_2018 "Depression (lag 1)" depression_2018_sq "Depression (lag 1)\$^2\$" depression_2016 "Depression (lag 2)" depression_2016_sq "Depression (lag 2)\$^2\$" ever_depressed "Ever depressed" max_cesd "Max CESD" 2.gender "Female" educ_yrs "Years of education" married_2020 "Married" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_2020 "In labor force" born_us "Born in U.S." _cons "Constant") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    addnotes(".") nonumbers nonotes
display "First-stage table (Trust, average) saved: iv_dep_r5_avg_first_stage.tex"

* ----------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------
display _n "########################################################################"
display "31_2sls_dep_2: Completed."
display "Output: ${REGRESSIONS}/2SLS/Dep/"
display "  - iv_dep_r5_cs_second_stage.tex"
display "  - iv_dep_r5_avg_second_stage.tex"
display "  - iv_dep_r5_panel_second_stage.tex"
display "  - iv_dep_r5_cs_first_stage.tex, iv_dep_r5_cs_first_stage_sq.tex"
display "  - iv_dep_r5_avg_first_stage.tex"
display "  - iv_dep_r5_panel_first_stage.tex"
display "########################################################################"

log close
