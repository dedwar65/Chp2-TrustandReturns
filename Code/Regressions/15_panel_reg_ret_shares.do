* 15_panel_reg_ret_shares.do
* Spec 2: Panel regressions with share×year (risk exposure controls).
* r1=share_core; r4=+share_ira; r5=+share_res + share_debt_long + share_debt_other.
* c.share##i.year expands to c.share + i.year + c.share#i.year (year FE included).
* Output: panel_reg_r1_spec2.tex, panel_reg_r4_spec2.tex, panel_reg_r5_spec2.tex (raw + win).
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
* Load long panel (must include share_core, share_ira, share_res from 10)
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off

xtset hhidpn year

* Require raw returns
foreach v in r1_annual_nw r4_annual_nw r5_annual_nw {
    capture confirm variable `v'
    if _rc {
        display as error "15_panel_reg_ret_shares: `v' not found. Run 02, 03, 04, 05, 10 in order."
        log close
        exit 198
    }
}

* Require share variables for Spec 2 (debt shares for r5 only)
foreach v in share_core share_ira share_res share_debt_long share_debt_other {
    capture confirm variable `v'
    if _rc {
        display as error "15_panel_reg_ret_shares: `v' not found in long panel. Add share vars to 10_build_panel."
        log close
        exit 198
    }
}

local r1_raw "r1_annual_nw"
local r4_raw "r4_annual_nw"
local r5_raw "r5_annual_nw"
local trust_var "trust_others_2020"

* Base controls WITHOUT i.year (## brings year in)
local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"

* Scope-specific: wealth deciles + share##i.year
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
* Add share×year (## includes i.year); debt shares only for r5 (net wealth)
local ctrl_r1 "`ctrl_r1' c.share_core##i.year"
local ctrl_r4 "`ctrl_r4' c.share_core##i.year c.share_ira##i.year"
local ctrl_r5 "`ctrl_r5' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

* Share×year joint tests: one per asset class (share_X × year dummies, one year may be omitted)
* r1: core only. r4: core + IRA (both in; don't sum to 1). r5: core, IRA, res (and debt)

* ----------------------------------------------------------------------
* Raw tables: panel_reg_r1_spec2.tex, panel_reg_r4_spec2.tex, panel_reg_r5_spec2.tex
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
        local ret_label "returns to ${LATEX_CORE_IRA}"
    }
    if "`ret'" == "r5" {
        local yvar "`r5_raw'"
        local ctrl "`ctrl_r5'"
        local ret_label "returns to net wealth"
    }
    * Restrict to nonmissing share terms for this return (r5 also needs debt shares)
    local share_cond "1"
    if "`ret'" == "r1" local share_cond "!missing(share_core)"
    if "`ret'" == "r4" local share_cond "!missing(share_core) & !missing(share_ira)"
    if "`ret'" == "r5" local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

    eststo clear
    di as txt _n "--- Raw `ret_label' ---"
    eststo m1: regress `yvar' `ctrl' if !missing(`yvar') & `share_cond', vce(cluster hhidpn)
    * Joint tests: share×year per asset class (share_X × year dummies)
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m1
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m1
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m1
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m1
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m1
    }
    * Keep only main coefficients (age, year, censreg, wealth, share×year omitted)
    if "`ret'" == "r1" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core `trust_var' c.`trust_var'#c.`trust_var' _cons"
    if "`ret'" == "r4" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core share_ira `trust_var' c.`trust_var'#c.`trust_var' _cons"
    if "`ret'" == "r5" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core share_ira share_res share_debt_long share_debt_other `trust_var' c.`trust_var'#c.`trust_var' _cons"
    eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m2
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m2
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m2
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m2
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m2
    }
    eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m3
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m3
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m3
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m3
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m3
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m3
    }

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_spec2.tex"
    * Stats: scope-specific share joint tests (one per asset class)
    if "`ret'" == "r1" {
        local stats_share "p_joint_share_core"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value""'
    }
    if "`ret'" == "r4" {
        local stats_share "p_joint_share_core p_joint_share_ira"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value" "Joint test: Share IRA${LATEX_X_YEAR} p-value""'
    }
    if "`ret'" == "r5" {
        local stats_share "p_joint_share_core p_joint_share_ira p_joint_share_res p_joint_share_debt_long p_joint_share_debt_other"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value" "Joint test: Share IRA${LATEX_X_YEAR} p-value" "Joint test: Share res${LATEX_X_YEAR} p-value" "Joint test: Share debt long${LATEX_X_YEAR} p-value" "Joint test: Share debt other${LATEX_X_YEAR} p-value""'
    }
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_list') ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S." `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²" share_core "Share core" share_ira "Share IRA" share_res "Share residential" share_debt_long "Share long-term debt" share_debt_other "Share other debt") ///
        stats(N r2_a p_joint_trust `stats_share', labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value" `labels_share')) ///
        title("Panel Spec 2: `ret_label' (raw, ${LATEX_SHARE_YEAR})") ///
        addnotes("Cluster-robust SE in parentheses. Spec 2: ${LATEX_SHARE_YEAR} controls for risk exposure." "Age bins, wealth deciles, region dummies, year dummies," "and ${LATEX_SHARE_YEAR} omitted from table but included in regressions.") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

* ----------------------------------------------------------------------
* Winsorized tables: panel_reg_r1_spec2_win.tex, etc.
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
        local ret_label "returns to ${LATEX_CORE_IRA}"
    }
    if "`ret'" == "r5" {
        local yvar "r5_annual_w5"
        local ctrl "`ctrl_r5'"
        local ret_label "returns to net wealth"
    }

    capture confirm variable `yvar'
    if _rc {
        di as txt "Skipping winsorized `ret': `yvar' not found."
        continue
    }

    local share_cond "1"
    if "`ret'" == "r1" local share_cond "!missing(share_core)"
    if "`ret'" == "r4" local share_cond "!missing(share_core) & !missing(share_ira)"
    if "`ret'" == "r5" local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

    eststo clear
    di as txt _n "--- Winsorized `ret_label' ---"
    eststo m1: regress `yvar' `ctrl' if !missing(`yvar') & `share_cond', vce(cluster hhidpn)
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m1
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m1
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m1
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m1
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m1
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m1
    }
    if "`ret'" == "r1" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core `trust_var' c.`trust_var'#c.`trust_var' _cons"
    if "`ret'" == "r4" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core share_ira `trust_var' c.`trust_var'#c.`trust_var' _cons"
    if "`ret'" == "r5" local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core share_ira share_res share_debt_long share_debt_other `trust_var' c.`trust_var'#c.`trust_var' _cons"
    eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m2
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m2
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m2
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m2
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m2
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m2
    }
    eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m3
    if "`ret'" == "r1" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
    }
    if "`ret'" == "r4" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m3
    }
    if "`ret'" == "r5" {
        quietly testparm c.share_core#i.year
        estadd scalar p_joint_share_core = r(p) : m3
        quietly testparm c.share_ira#i.year
        estadd scalar p_joint_share_ira = r(p) : m3
        quietly testparm c.share_res#i.year
        estadd scalar p_joint_share_res = r(p) : m3
        quietly testparm c.share_debt_long#i.year
        estadd scalar p_joint_share_debt_long = r(p) : m3
        quietly testparm c.share_debt_other#i.year
        estadd scalar p_joint_share_debt_other = r(p) : m3
    }

    local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_spec2_win.tex"
    if "`ret'" == "r1" {
        local stats_share "p_joint_share_core"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value""'
    }
    if "`ret'" == "r4" {
        local stats_share "p_joint_share_core p_joint_share_ira"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value" "Joint test: Share IRA${LATEX_X_YEAR} p-value""'
    }
    if "`ret'" == "r5" {
        local stats_share "p_joint_share_core p_joint_share_ira p_joint_share_res p_joint_share_debt_long p_joint_share_debt_other"
        local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value" "Joint test: Share IRA${LATEX_X_YEAR} p-value" "Joint test: Share res${LATEX_X_YEAR} p-value" "Joint test: Share debt long${LATEX_X_YEAR} p-value" "Joint test: Share debt other${LATEX_X_YEAR} p-value""'
    }
    esttab m1 m2 m3 using "`outfile'", replace ///
        booktabs ///
        mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_list') ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S." `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust²" share_core "Share core" share_ira "Share IRA" share_res "Share residential" share_debt_long "Share long-term debt" share_debt_other "Share other debt") ///
        stats(N r2_a p_joint_trust `stats_share', labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value" `labels_share')) ///
        title("Panel Spec 2: `ret_label' (${LATEX_WIN_SHORT}, ${LATEX_SHARE_YEAR})") ///
        addnotes("Cluster-robust SE in parentheses. Spec 2: ${LATEX_SHARE_YEAR} controls for risk exposure." "Age bins, wealth deciles, region dummies, year dummies," "and ${LATEX_SHARE_YEAR} omitted from table but included in regressions.") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

    di as txt "Wrote: `outfile'"
}

eststo clear
di as txt "Done. Spec 2 tables in ${REGRESSIONS}/Panel/"
log close
