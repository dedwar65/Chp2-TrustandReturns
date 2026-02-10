* 10_build_panel.do
* Build a long, panel-ready dataset for regressions from analysis_ready_processed.dta.
* Input:  ${PROCESSED}/analysis_ready_processed.dta
* Output: ${PROCESSED}/analysis_final_long_unbalanced.dta
* Notes:
*   - Does NOT create a new wide dataset (reuses the existing wide file for descriptives).
*   - Focuses on r1, r4, and r5 returns, deflated+winsorized income, key wealth/shares, and controls.
*   - Treats trust, finlit, and general demographics as time-invariant.
*   - Logs overlap diagnostics by year instead of constructing a balanced panel file.

clear
set more off

* ----------------------------------------------------------------------
* Ensure BASE_PATH and load config (same pattern as other processing scripts)
* ----------------------------------------------------------------------
capture confirm global BASE_PATH
if _rc {
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
}

capture log close
log using "${LOG_DIR}/10_build_panel.log", replace text

* ----------------------------------------------------------------------
* Load processed wide dataset
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

capture confirm variable hhidpn
if _rc {
    display as error "10_build_panel: hhidpn (panel id) not found in analysis_ready_processed.dta."
    log close
    exit 0
}

* Weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local has_wt = (_rc == 0)
local wopt ""
if `has_wt' local wopt "[aw=`wtvar']"

* Year list for returns/income panel (even years where returns exist)
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"

display "=== 10_build_panel: Defining panel variable groups from analysis_ready_processed.dta ==="

* ----------------------------------------------------------------------
* Time-varying groups: stubs for reshape + explicit varlists for keep
* ----------------------------------------------------------------------

* Returns (r1, r4, r5) and winsorized versions
local ret_stubs ""
local ret_vars  ""
foreach s in r1_annual r1_annual_win r4_annual r4_annual_win r5_annual r5_annual_win {
    capture unab tmp : `s'_*
    if !_rc {
        local ret_stubs "`ret_stubs' `s'_"
        local ret_vars  "`ret_vars' `tmp'"
    }
}

* Deflated + winsorized income (levels and any final specs)
local inc_stubs ""
local inc_vars  ""
foreach s in labor_income_real_win total_income_real_win {
    capture unab tmp : `s'_*
    if !_rc {
        local inc_stubs "`inc_stubs' `s'_"
        local inc_vars  "`inc_vars' `tmp'"
    }
}
* Include any final log/residualized income series if present
foreach s in ln_lab_inc_final ln_tot_inc_final ln_lab_inc_final_resid ln_tot_inc_final_resid {
    capture unab tmp : `s'_*
    if !_rc {
        local inc_stubs "`inc_stubs' `s'_"
        local inc_vars  "`inc_vars' `tmp'"
    }
}

* Wealth (levels)
local wealth_stubs ""
local wealth_vars  ""
foreach s in wealth_core wealth_ira wealth_coreira wealth_total {
    capture unab tmp : `s'_*
    if !_rc {
        local wealth_stubs "`wealth_stubs' `s'_"
        local wealth_vars  "`wealth_vars' `tmp'"
    }
}

* Shares: gross-assets/core+IRA pipeline shares only
*   - share_core_: core / gross assets
*   - share_m3_ira_: IRA / gross assets
*   - share_residential_: residential / gross assets
local share_stubs ""
local share_vars  ""
foreach s in share_core share_m3_ira share_residential {
    capture unab tmp : `s'_*
    if !_rc {
        local share_stubs "`share_stubs' `s'_"
        local share_vars  "`share_vars' `tmp'"
    }
}

* Core wave-specific controls
local ctrl_stubs ""
local ctrl_vars  ""
foreach s in age married inlbrf region hometown_size region_pop_group region_pop3_group ///
               townsize_trust pop_trust regional_trust {
    capture unab tmp : `s'_*
    if !_rc {
        local ctrl_stubs "`ctrl_stubs' `s'_"
        local ctrl_vars  "`ctrl_vars' `tmp'"
    }
}

* ----------------------------------------------------------------------
* Time-invariant (or single-wave) controls: trust, finlit, demographics, 2020-only controls
* ----------------------------------------------------------------------
local tinv_vars ""
foreach v in trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 ///
             trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020 ///
             interest_2020 inflation_2020 risk_div_2020 ///
             educ_yrs gender immigrant born_us race_eth ///
             depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 beq_any_2020 ///
             num_divorce_2020 num_widow_2020 population_2020 population_3bin_2020 {
    capture confirm variable `v'
    if !_rc local tinv_vars "`tinv_vars' `v'"
}

display "Returns stubs: `ret_stubs'"
display "Income stubs:  `inc_stubs'"
display "Wealth stubs:  `wealth_stubs'"
display "Share stubs:   `share_stubs'"
display "Control stubs: `ctrl_stubs'"
display "Time-invariant vars: `tinv_vars'"

* ----------------------------------------------------------------------
* Keep only variables needed for the panel reshape
* ----------------------------------------------------------------------
local base_keep "hhidpn"
if `has_wt' local base_keep "`base_keep' `wtvar'"

keep `base_keep' `tinv_vars' `ret_vars' `inc_vars' `wealth_vars' `share_vars' `ctrl_vars'

* ----------------------------------------------------------------------
* Reshape to long: person–year panel
* ----------------------------------------------------------------------
local long_stubs "`ret_stubs' `inc_stubs' `wealth_stubs' `share_stubs' `ctrl_stubs'"

* If there are no stubs, abort gracefully
if "`long_stubs'" == "" {
    display as error "10_build_panel: No time-varying stubs found to reshape."
    log close
    exit 0
}

display "=== 10_build_panel: Reshaping to long person–year panel ==="
reshape long `long_stubs', i(hhidpn) j(year)

* Avoid Stata ambiguous abbreviation (r1_annual vs r1_annual_win): temp-rename _win, then rename _annual -> _annual_nw using varlist so we never type the ambiguous name.
local r1var "r1_annual_nw"
local r4var "r4_annual_nw"
local r5var "r5_annual_nw"
capture confirm variable r1_annual_win
if !_rc {
    rename r1_annual_win __r1win
    rename r4_annual_win __r4win
    rename r5_annual_win __r5win
    foreach v of varlist _all {
        if "`v'" == "r1_annual" {
            rename `v' r1_annual_nw
            continue, break
        }
    }
    foreach v of varlist _all {
        if "`v'" == "r4_annual" {
            rename `v' r4_annual_nw
            continue, break
        }
    }
    foreach v of varlist _all {
        if "`v'" == "r5_annual" {
            rename `v' r5_annual_nw
            continue, break
        }
    }
    rename __r1win r1_annual_win
    rename __r4win r4_annual_win
    rename __r5win r5_annual_win
}
else {
    foreach v of varlist _all {
        if "`v'" == "r1_annual" {
            rename `v' r1_annual_nw
            continue, break
        }
    }
    foreach v of varlist _all {
        if "`v'" == "r4_annual" {
            rename `v' r4_annual_nw
            continue, break
        }
    }
    foreach v of varlist _all {
        if "`v'" == "r5_annual" {
            rename `v' r5_annual_nw
            continue, break
        }
    }
}

* Point to the return variable that exists (_nw if we renamed it, else _win when only winsorized is in data)
capture confirm variable r1_annual_nw
if _rc {
    capture confirm variable r1_annual_win
    if !_rc local r1var "r1_annual_win"
}
capture confirm variable r4_annual_nw
if _rc {
    capture confirm variable r4_annual_win
    if !_rc local r4var "r4_annual_win"
}
capture confirm variable r5_annual_nw
if _rc {
    capture confirm variable r5_annual_win
    if !_rc local r5var "r5_annual_win"
}

* Weight and time-invariant vars are already attached to each row (they were kept pre-reshape).

* ----------------------------------------------------------------------
* Core+IRA composition shares: core/(core+IRA) and IRA/(core+IRA)
* Using wealth variables: wealth_core and wealth_ira (per person–year).
* ----------------------------------------------------------------------
capture confirm variable wealth_core
local has_wcore = (_rc == 0)
capture confirm variable wealth_ira
local has_wira = (_rc == 0)
if `has_wcore' & `has_wira' {
    display "=== 10_build_panel: Creating core/(core+IRA) and IRA/(core+IRA) from wealth_core and wealth_ira ==="
    gen double coreira = wealth_core + wealth_ira
    gen double share_core_coreira = .
    gen double share_ira_coreira  = .
    replace share_core_coreira = wealth_core / coreira if coreira > 0 & !missing(wealth_core) & !missing(wealth_ira)
    replace share_ira_coreira  = wealth_ira  / coreira if coreira > 0 & !missing(wealth_core) & !missing(wealth_ira)
}

* ----------------------------------------------------------------------
* Overlap diagnostics: Ns by year and for key variable sets
* ----------------------------------------------------------------------
display "=== Panel structure: observations by year (unbalanced) ==="
tab year

display "=== Overlap: r1/r4/r5 and basic controls by year ==="
foreach y of local years {
    quietly count if year == `y' & !missing(`r1var') & !missing(`r4var') & !missing(`r5var')
    display "Year `y': r1 & r4 & r5 nonmissing = " %9.0f r(N)

    quietly count if year == `y' & !missing(`r1var') & !missing(`r4var') & !missing(`r5var') ///
        & !missing(labor_income_real_win) & !missing(total_income_real_win) ///
        & !missing(age) & !missing(married) & !missing(inlbrf)
    display "Year `y': r1/r4/r5 + inc (lab+tot) + age/married/inlbrf nonmissing = " %9.0f r(N)
}

display "=== Overlap: trust (2020) + r1/r4/r5 by year ==="
capture confirm variable trust_others_2020
if !_rc {
    foreach y of local years {
        quietly count if year == `y' & !missing(`r1var') & !missing(`r4var') & !missing(`r5var') ///
            & !missing(trust_others_2020)
        display "Year `y': r1/r4/r5 + General trust nonmissing = " %9.0f r(N)
    }
}
else {
    display "General trust (trust_others_2020) not found; skipping trust overlap diagnostics."
}

* Optional: overall waves-per-person counts for returns
display "=== Overlap: number of waves with nonmissing r1 & r4 & r5 per person ==="
preserve
    gen byte has_r = (!missing(`r1var') & !missing(`r4var') & !missing(`r5var'))
    bysort hhidpn: egen byte n_waves_r = total(has_r)
    bysort hhidpn: keep if _n == 1
    tab n_waves_r
restore

* ----------------------------------------------------------------------
* Save long, unbalanced panel dataset for regressions
* ----------------------------------------------------------------------
save "${PROCESSED}/analysis_final_long_unbalanced.dta", replace
display "10_build_panel: Saved ${PROCESSED}/analysis_final_long_unbalanced.dta"

log close

