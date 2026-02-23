* 21_inspect_panel_r1_r4.do
* Inspection: pooled panel regressions (Spec 1 style) for r1 and r4 returns.
* Same model as Table 15 (panel_reg_r5_win): controls only; + trust; + trust + trust².
* LHS: r1_annual_w5 (core), r4_annual_w5 (core+IRA). Log only.
* Log: Notes/Logs/21_inspect_panel_r1_r4.log

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
log using "${LOG_DIR}/21_inspect_panel_r1_r4.log", replace text

* ----------------------------------------------------------------------
* Load long panel
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off

local trust_var "trust_others_2020"

* Base controls (match 14_panel_reg_ret)
local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year"

* Scope-specific controls (wealth deciles)
local ctrl_r1 "`base_ctrl'"
local ctrl_r4 "`base_ctrl'"
forvalues d = 2/10 {
    capture confirm variable wealth_core_d`d'
    if !_rc local ctrl_r1 "`ctrl_r1' wealth_core_d`d'"
    capture confirm variable wealth_coreira_d`d'
    if !_rc local ctrl_r4 "`ctrl_r4' wealth_coreira_d`d'"
}

* ----------------------------------------------------------------------
* r1 (returns to core) — winsorized
* ----------------------------------------------------------------------
capture confirm variable r1_annual_w5
if _rc {
    display as error "r1_annual_w5 not found. Run pipeline (02, 03, 04, 05, 10)."
    log close
    exit 198
}

display _n "########################################################################"
display "POOLED REGRESSIONS: Returns to core (r1, 5 percent winsorized)"
display "########################################################################"

display _n "--- Spec 1: Controls only ---"
regress r1_annual_w5 `ctrl_r1' if !missing(r1_annual_w5), vce(cluster hhidpn)

display _n "--- Spec 2: + Trust ---"
regress r1_annual_w5 `ctrl_r1' c.`trust_var' if !missing(r1_annual_w5) & !missing(`trust_var'), vce(cluster hhidpn)

display _n "--- Spec 3: + Trust + Trust² ---"
regress r1_annual_w5 `ctrl_r1' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(r1_annual_w5) & !missing(`trust_var'), vce(cluster hhidpn)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
display "Joint test Trust+Trust² p-value: " r(p)

* ----------------------------------------------------------------------
* r4 (returns to core+IRA) — winsorized
* ----------------------------------------------------------------------
capture confirm variable r4_annual_w5
if _rc {
    display as error "r4_annual_w5 not found. Run pipeline (02, 03, 04, 05, 10)."
    log close
    exit 198
}

display _n "########################################################################"
display "POOLED REGRESSIONS: Returns to core+IRA (r4, 5 percent winsorized)"
display "########################################################################"

display _n "--- Spec 1: Controls only ---"
regress r4_annual_w5 `ctrl_r4' if !missing(r4_annual_w5), vce(cluster hhidpn)

display _n "--- Spec 2: + Trust ---"
regress r4_annual_w5 `ctrl_r4' c.`trust_var' if !missing(r4_annual_w5) & !missing(`trust_var'), vce(cluster hhidpn)

display _n "--- Spec 3: + Trust + Trust² ---"
regress r4_annual_w5 `ctrl_r4' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(r4_annual_w5) & !missing(`trust_var'), vce(cluster hhidpn)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
display "Joint test Trust+Trust² p-value: " r(p)

display _n "Done. Log: ${LOG_DIR}/21_inspect_panel_r1_r4.log"
log close
