* 15_panel_reg_ret_shares.do
* Panel regressions with shares interacted with year dummies, leverage ratios, and full baseline controls.
* Return measures: r1 (core), r4 (core+IRA), r5 (total net).
* Each: 3 specs (controls + leverage + shares#year; + trust; + trust²).
* Output: 6 tables — raw and winsorized (r1, r4, r5), each 3 columns.
* SE: vce(cluster hhidpn). Log: Notes/Logs/15_panel_reg_ret_shares.log.

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
log using "${LOG_DIR}/15_panel_reg_ret_shares.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load long panel
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off

* censreg (census region) created upstream in 10_build_panel
xtset hhidpn year

* Return variable names
capture confirm variable r1_annual_nw
if _rc {
    capture confirm variable r1_annual
    if !_rc local r1_raw "r1_annual"
    else local r1_raw ""
}
else local r1_raw "r1_annual_nw"

capture confirm variable r4_annual_nw
if _rc {
    capture confirm variable r4_annual
    if !_rc local r4_raw "r4_annual"
    else local r4_raw ""
}
else local r4_raw "r4_annual_nw"

capture confirm variable r5_annual_nw
if _rc {
    capture confirm variable r5_annual
    if !_rc local r5_raw "r5_annual"
    else local r5_raw ""
}
else local r5_raw "r5_annual_nw"

* Trust (time-invariant)
local trust_var "trust_others_2020"

* Base controls (same as 14) + leverage
local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year leverage_long leverage_other"

* Scope-specific shares for share#i.year (same shares used in regressions)
* r1: share_core (core/gross)
* r4: share_core_coreira, share_ira_coreira (core/(core+IRA), IRA/(core+IRA)) — omit one as base (they sum to 1)
* r5: share_core, share_m3_ira, share_residential (core/gross, IRA/gross, res/gross)
local shares_r1 "share_core"
local shares_r4 "share_core_coreira"
local shares_r5 "share_core share_m3_ira share_residential"

* Build share#i.year interaction strings per return
local share_year_r1 ""
local share_year_r4 ""
local share_year_r5 ""
foreach v of local shares_r1 {
    capture confirm variable `v'
    if !_rc local share_year_r1 "`share_year_r1' c.`v'#i.year"
}
foreach v of local shares_r4 {
    capture confirm variable `v'
    if !_rc local share_year_r4 "`share_year_r4' c.`v'#i.year"
}
foreach v of local shares_r5 {
    capture confirm variable `v'
    if !_rc local share_year_r5 "`share_year_r5' c.`v'#i.year"
}

* Build full control lists (wealth deciles + share#year)
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
local ctrl_r1 "`ctrl_r1' `share_year_r1'"
local ctrl_r4 "`ctrl_r4' `share_year_r4'"
local ctrl_r5 "`ctrl_r5' `share_year_r5'"

* Drop list for esttab: age bins, wealth deciles, region, year dummies, leverage, share×year interactions
local drop_base "*.age_bin *.year *.censreg leverage_long leverage_other"
forvalues d = 2/10 {
    capture confirm variable wealth_core_d`d'
    if !_rc local drop_base "`drop_base' wealth_core_d`d'"
    capture confirm variable wealth_coreira_d`d'
    if !_rc local drop_base "`drop_base' wealth_coreira_d`d'"
    capture confirm variable wealth_d`d'
    if !_rc local drop_base "`drop_base' wealth_d`d'"
}
* Add share×year interaction coefficients (omit from table like wealth deciles)
local drop_base "`drop_base' *share_core*#* *share_m3_ira*#* *share_residential*#* *share_ira_coreira*#*"

* ----------------------------------------------------------------------
* Raw tables: panel_reg_r1_shares.tex, panel_reg_r4_shares.tex, panel_reg_r5_shares.tex
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

    if "`yvar'" == "" {
        di as txt "Skipping raw `ret' shares: no raw return variable."
        continue
    }

    capture confirm variable `yvar'
    if _rc {
        di as txt "Skipping raw `ret' shares: variable `yvar' not found."
        continue
    }

    eststo clear
    quietly eststo m1: regress `yvar' `ctrl' if !missing(`yvar'), vce(cluster hhidpn)
    quietly eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    quietly eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_shares.tex"
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        drop(`drop_base', relax) ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf "Employed" married "Married" born_us "Born in U.S." c.`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²") ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("Panel: `ret_label' (raw) — shares×year + leverage + full controls") ///
        addnotes("Cluster-robust SE in parentheses. Age bins (5-yr), wealth deciles, region dummies, year dummies, share×year interactions, and leverage ratios omitted from table but included in regressions.") ///
        alignment(D{.}{.}{-1}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

* ----------------------------------------------------------------------
* Winsorized tables: panel_reg_r1_shares_win.tex, etc.
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
        di as txt "Skipping winsorized `ret' shares: variable `yvar' not found."
        continue
    }

    eststo clear
    quietly eststo m1: regress `yvar' `ctrl' if !missing(`yvar'), vce(cluster hhidpn)
    quietly eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
    quietly eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_shares_win.tex"
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        drop(`drop_base', relax) ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf "Employed" married "Married" born_us "Born in U.S." c.`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²") ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("Panel: `ret_label' (5% winsorized) — shares×year + leverage + full controls") ///
        addnotes("Cluster-robust SE in parentheses. Age bins (5-yr), wealth deciles, region dummies, year dummies, share×year interactions, and leverage ratios omitted from table but included in regressions.") ///
        alignment(D{.}{.}{-1}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Panel/"
log close
