* 14_panel_reg_ret.do
* Baseline pooled OLS regressions on the long panel dataset.
* Return measures: r1 (core), r4 (core+IRA), r5 (total net).
* Each: 3 specs (controls only; + linear trust; + trust²).
* Output: 6 tables — raw (r1, r4, r5) and winsorized (r1_win, r4_win, r5_win), each 3 columns.
* SE: vce(cluster hhidpn). Log: Notes/Logs/14_panel_reg_ret.log.

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

capture mkdir "${REGRESSIONS}/Panel"

capture log close
log using "${LOG_DIR}/14_panel_reg_ret.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load long panel
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off

* censreg (census region) created upstream in 10_build_panel
xtset hhidpn year

* Return variables: raw (r*_annual_nw) required for 14; winsorized (r*_annual_w5) for _win tables
* Fail fast if raw vars missing — indicates upstream pipeline failure (10 should have exited 198).
foreach v in r1_annual_nw r4_annual_nw r5_annual_nw {
    capture confirm variable `v'
    if _rc {
        display as error "14_panel_reg_ret: `v' not found in long panel. Run 02, 03, 04, 05, 10 in order."
        log close
        exit 198
    }
    quietly count if !missing(`v')
    display "14_panel_reg_ret: `v' nonmissing N = " %9.0f r(N)
}

capture confirm variable r1_annual_win
local has_r1_win = (_rc == 0)
capture confirm variable r4_annual_win
local has_r4_win = (_rc == 0)
capture confirm variable r5_annual_win
local has_r5_win = (_rc == 0)
capture confirm variable r1_annual_w5
local has_r1_w5 = (_rc == 0)
capture confirm variable r4_annual_w5
local has_r4_w5 = (_rc == 0)
capture confirm variable r5_annual_w5
local has_r5_w5 = (_rc == 0)

local r1_raw "r1_annual_nw"
local r4_raw "r4_annual_nw"
local r5_raw "r5_annual_nw"

* Trust (time-invariant)
local trust_var "trust_others_2020"

* Base controls (all specs): age bins, region dummies, year dummies
local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year"

* Build scope-specific control lists (wealth deciles)
local ctrl_r1 "`base_ctrl'"
local ctrl_r4 "`base_ctrl'"
local ctrl_r5 "`base_ctrl'"
forvalues d = 2/10 {
    capture confirm variable wealth_core_d`d'
    if !_rc local ctrl_r1 "`ctrl_r1' wealth_core_d`d'"
    capture confirm variable wealth_coreira_d`d'
    if !_rc local ctrl_r4 "`ctrl_r4' wealth_coreira_d`d'"
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'"
}

* ----------------------------------------------------------------------
* Raw tables: panel_reg_r1.tex, panel_reg_r4.tex, panel_reg_r5.tex
* ----------------------------------------------------------------------
foreach ret in r1 r4 r5 {
    local yvar ""
    local ctrl ""
    local ret_label ""
    if "`ret'" == "r1" {
        local yvar "`r1_raw'"
        local ctrl "`ctrl_r1'"
        local ret_label "returns to core"
    }
    if "`ret'" == "r4" {
        local yvar "`r4_raw'"
        local ctrl "`ctrl_r4'"
        local ret_label "returns to core+IRA"
    }
    if "`ret'" == "r5" {
        local yvar "`r5_raw'"
        local ctrl "`ctrl_r5'"
        local ret_label "returns to net wealth"
    }
    * raw vars guaranteed by 10; fail-fast above if missing
    eststo clear
    di as txt _n "--- Raw `ret_label' ---"
    eststo m1: regress `yvar' `ctrl' if !missing(`yvar'), vce(cluster hhidpn)
    * Keep only main coefficients (explicit list; age, year, censreg, wealth omitted)
    local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us `trust_var' c.`trust_var'#c.`trust_var' _cons"
    eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m3

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'.tex"
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_list') ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S." `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²") ///
        stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value")) ///
        title("Panel: `ret_label' (raw)") ///
        addnotes("Cluster-robust SE in parentheses. Age bins (5-yr), wealth deciles, region dummies, and year dummies omitted from table but included in regressions.") ///
        alignment(D{{.}}{{.}}{{-1}}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

* ----------------------------------------------------------------------
* Winsorized tables: panel_reg_r1_win.tex, panel_reg_r4_win.tex, panel_reg_r5_win.tex
* ----------------------------------------------------------------------
foreach ret in r1 r4 r5 {
    local yvar ""
    local ctrl ""
    local ret_label ""
    if "`ret'" == "r1" {
        local yvar "r1_annual_w5"
        local ctrl "`ctrl_r1'"
        local ret_label "returns to core"
    }
    if "`ret'" == "r4" {
        local yvar "r4_annual_w5"
        local ctrl "`ctrl_r4'"
        local ret_label "returns to core+IRA"
    }
    if "`ret'" == "r5" {
        local yvar "r5_annual_w5"
        local ctrl "`ctrl_r5'"
        local ret_label "returns to net wealth"
    }

    capture confirm variable `yvar'
    if _rc {
        di as txt "Skipping winsorized `ret': variable `yvar' not found."
        continue
    }

    eststo clear
    di as txt _n "--- Winsorized `ret_label' ---"
    eststo m1: regress `yvar' `ctrl' if !missing(`yvar'), vce(cluster hhidpn)
    local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us `trust_var' c.`trust_var'#c.`trust_var' _cons"
    eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m3

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_win.tex"
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_list') ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S." `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²") ///
        stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value")) ///
        title("Panel: `ret_label' (5% winsorized)") ///
        addnotes("Cluster-robust SE in parentheses. Age bins (5-yr), wealth deciles, region dummies, and year dummies omitted from table but included in regressions.") ///
        alignment(D{{.}}{{.}}{{-1}}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Panel/"
log close
