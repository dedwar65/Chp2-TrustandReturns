* 27_turning_points_original_results.do
* Turning points for original Results-section models (continuous education: educ_yrs).
* Computes T* = -beta_trust / (2*beta_trust2) for every model with trust + trust^2.
* Uses exact coefficients from e(b), not rounded LaTeX tables.
*
* Output:
*   ${REGRESSIONS}/Other/trust_turning_points_original_results.csv
*   ${REGRESSIONS}/Other/trust_turning_points_original_results.tex
* Log:
*   ${LOG_DIR}/27_turning_points_original_results.log

clear
set more off

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

capture mkdir "${REGRESSIONS}/Tests"
capture mkdir "${REGRESSIONS}/Tests/Summaries"
capture mkdir "${REGRESSIONS}/Other"

capture log close
log using "${LOG_DIR}/27_turning_points_original_results.log", replace text

tempfile tpraw
postfile tpH str40 block str18 spec str24 depvar str24 trustvar ///
    double N b1 b2 tp tp_se tp_p tp_lb tp_ub t_min t_max both_sig p_joint ///
    using "`tpraw'", replace

local tvar "trust_others_2020"
local sq "c.`tvar'#c.`tvar'"
local both_alpha 0.10

* ------------------------------------------------------------
* 1) Cross-section income, total IHS (from 12_reg_income_trust.do)
*    m2 (no controls), m4 (controls)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5

local y "ihs_tot_inc_defl_win_s_2020"
local ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl "i.age_bin `ctrl'"
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local ctrl "`ctrl' i.race_eth"

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y' c.`tvar' `sq' if !missing(`y') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar'), vce(robust)
    quietly test c.`tvar' = 0
    local p_b1 = r(p)
    quietly test `sq' = 0
    local p_b2 = r(p)
    local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
    quietly testparm c.`tvar' `sq'
    local p_joint = r(p)
    local b1 = _b[c.`tvar']
    local b2 = _b[`sq']
    qui sum `tvar' if e(sample), meanonly
    local tmin = r(min)
    local tmax = r(max)
    capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
    if _rc {
        local tp = .
        local tp_se = .
        local tp_p = .
        local tp_lb = .
        local tp_ub = .
    }
    else {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
    post tpH ("income_2020_total_ihs") ("`s'") ("`y'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')
}

* ------------------------------------------------------------
* 2) Average income, total IHS (from 17_reg_income_avg_trust.do)
*    m2 (no controls), m4 (controls)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5

local y "ihs_tot_inc_defl_win_avg"
local ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl "i.age_bin `ctrl'"
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local ctrl "`ctrl' i.race_eth"

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y' c.`tvar' `sq' if !missing(`y') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar'), vce(robust)
    quietly test c.`tvar' = 0
    local p_b1 = r(p)
    quietly test `sq' = 0
    local p_b2 = r(p)
    local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
    quietly testparm c.`tvar' `sq'
    local p_joint = r(p)
    local b1 = _b[c.`tvar']
    local b2 = _b[`sq']
    qui sum `tvar' if e(sample), meanonly
    local tmin = r(min)
    local tmax = r(max)
    capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
    if _rc {
        local tp = .
        local tp_se = .
        local tp_p = .
        local tp_lb = .
        local tp_ub = .
    }
    else {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
    post tpH ("income_avg_total_ihs") ("`s'") ("`y'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')
}

* ------------------------------------------------------------
* 3) Cross-section returns r5 2022 winsorized (from 13_reg_returns_trust.do)
*    m2 (no controls), m4 (controls)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5

local y "r5_annual_w5_2022"
capture confirm variable `y'
if _rc local y "r5_annual_2022_w5"

local ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl "i.age_bin `ctrl'"
capture confirm variable race_eth
if !_rc local ctrl "`ctrl' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl "`ctrl' wealth_d`d'_2020"
}

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y' c.`tvar' `sq' if !missing(`y') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar'), vce(robust)
    quietly test c.`tvar' = 0
    local p_b1 = r(p)
    quietly test `sq' = 0
    local p_b2 = r(p)
    local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
    quietly testparm c.`tvar' `sq'
    local p_joint = r(p)
    local b1 = _b[c.`tvar']
    local b2 = _b[`sq']
    qui sum `tvar' if e(sample), meanonly
    local tmin = r(min)
    local tmax = r(max)
    capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
    if _rc {
        local tp = .
        local tp_se = .
        local tp_p = .
        local tp_lb = .
        local tp_ub = .
    }
    else {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
    post tpH ("returns_2022_r5_win") ("`s'") ("`y'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')
}

* ------------------------------------------------------------
* 4) Average returns r5 winsorized (from 18_reg_returns_avg_trust.do)
*    m2 (no controls), m4 (controls)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5

local y "r5_annual_avg_w5"
local ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl "i.age_bin `ctrl'"
capture confirm variable race_eth
if !_rc local ctrl "`ctrl' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl "`ctrl' wealth_d`d'_2020"
}

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y' c.`tvar' `sq' if !missing(`y') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar'), vce(robust)
    quietly test c.`tvar' = 0
    local p_b1 = r(p)
    quietly test `sq' = 0
    local p_b2 = r(p)
    local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
    quietly testparm c.`tvar' `sq'
    local p_joint = r(p)
    local b1 = _b[c.`tvar']
    local b2 = _b[`sq']
    qui sum `tvar' if e(sample), meanonly
    local tmin = r(min)
    local tmax = r(max)
    capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
    if _rc {
        local tp = .
        local tp_se = .
        local tp_p = .
        local tp_lb = .
        local tp_ub = .
    }
    else {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
    post tpH ("returns_avg_r5_win") ("`s'") ("`y'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')
}

* ------------------------------------------------------------
* 5) Panel spec 1 r5 winsorized (from 14_panel_reg_ret.do) m3
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
local y "r5_annual_w5"
local ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar'), vce(cluster hhidpn)
quietly test c.`tvar' = 0
local p_b1 = r(p)
quietly test `sq' = 0
local p_b2 = r(p)
local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
quietly testparm c.`tvar' `sq'
local p_joint = r(p)
local b1 = _b[c.`tvar']
local b2 = _b[`sq']
qui sum `tvar' if e(sample), meanonly
local tmin = r(min)
local tmax = r(max)
capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
if _rc {
    local tp = .
    local tp_se = .
    local tp_p = .
    local tp_lb = .
    local tp_ub = .
}
else {
    matrix T = r(table)
    local tp    = T[1,1]
    local tp_se = T[2,1]
    local tp_p  = T[4,1]
    local tp_lb = T[5,1]
    local tp_ub = T[6,1]
}
post tpH ("panel_spec1_r5_win") ("controls") ("`y'") ("`tvar'") ///
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')

* ------------------------------------------------------------
* 6) Panel spec 2 r5 winsorized (from 15_panel_reg_ret_shares.do) m3
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
local y "r5_annual_w5"
local ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
local ctrl "`ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

regress `y' c.`tvar' `sq' `ctrl' if !missing(`y') & !missing(`tvar') & `share_cond', vce(cluster hhidpn)
quietly test c.`tvar' = 0
local p_b1 = r(p)
quietly test `sq' = 0
local p_b2 = r(p)
local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
quietly testparm c.`tvar' `sq'
local p_joint = r(p)
local b1 = _b[c.`tvar']
local b2 = _b[`sq']
qui sum `tvar' if e(sample), meanonly
local tmin = r(min)
local tmax = r(max)
capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
if _rc {
    local tp = .
    local tp_se = .
    local tp_p = .
    local tp_lb = .
    local tp_ub = .
}
else {
    matrix T = r(table)
    local tp    = T[1,1]
    local tp_se = T[2,1]
    local tp_p  = T[4,1]
    local tp_lb = T[5,1]
    local tp_ub = T[6,1]
}
post tpH ("panel_spec2_r5_win") ("controls") ("`y'") ("`tvar'") ///
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')

* ------------------------------------------------------------
* 7) FE second-stage r5 winsorized (from 16_panel_reg_fe.do) m3
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
local y "r5_annual_w5"
local ctrl "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
local ctrl "`ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

quietly xtreg `y' `ctrl' if !missing(`y') & `share_cond', fe vce(cluster hhidpn)
predict double __hdfe3__, u
keep if e(sample)
keep hhidpn __hdfe3__
collapse (first) __hdfe3__, by(hhidpn)
rename __hdfe3__ fe
tempfile fe3
save `fe3'

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
keep hhidpn educ_yrs gender race_eth born_us trust_others_2020
duplicates drop hhidpn, force
merge 1:1 hhidpn using `fe3', nogen

regress fe educ_yrs i.gender i.race_eth born_us c.`tvar' `sq' if !missing(`tvar'), vce(robust)
quietly test c.`tvar' = 0
local p_b1 = r(p)
quietly test `sq' = 0
local p_b2 = r(p)
local both_sig = (`p_b1' < `both_alpha' & `p_b2' < `both_alpha')
quietly testparm c.`tvar' `sq'
local p_joint = r(p)
local b1 = _b[c.`tvar']
local b2 = _b[`sq']
qui sum `tvar' if e(sample), meanonly
local tmin = r(min)
local tmax = r(max)
capture noisily nlcom (tp: -_b[c.`tvar']/(2*_b[`sq']))
if _rc {
    local tp = .
    local tp_se = .
    local tp_p = .
    local tp_lb = .
    local tp_ub = .
}
else {
    matrix T = r(table)
    local tp    = T[1,1]
    local tp_se = T[2,1]
    local tp_p  = T[4,1]
    local tp_lb = T[5,1]
    local tp_ub = T[6,1]
}
post tpH ("panel_fe_2nd_r5_win") ("controls") ("fe") ("`tvar'") ///
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig') (`p_joint')

postclose tpH
use "`tpraw'", clear

drop if spec != "controls"
drop if block == "panel_fe_2nd_r5_win"
gen str14 shape = cond(b2<0, "concave_max", cond(b2>0, "convex_min", "linear"))
gen byte tp_in_support = (tp>=t_min & tp<=t_max) if !missing(tp,t_min,t_max)
order block spec depvar N b1 b2 both_sig p_joint tp tp_se tp_p tp_lb tp_ub t_min t_max tp_in_support shape

export delimited using "${REGRESSIONS}/Other/trust_turning_points_original_results.csv", replace

file open fh using "${REGRESSIONS}/Other/trust_turning_points_original_results.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Estimated trust \(\textit{Trust}^*\) associated with maximal economic performance}" _n ///
    "\label{tab:trust_turning_points_original_results}" _n ///
    "\begin{tabular}{llrrrrrr}\toprule" _n ///
    "Model & Spec & N & \(\hat\beta_1\) & \(\hat\beta_2\) & Both sig.? & Joint test & \((\textit{Trust})^*\) \\\\ \midrule" _n

forvalues i = 1/`=_N' {
    local b = block[`i']
    if "`b'" == "income_2020_total_ihs" local b "Total Income (2022)"
    if "`b'" == "income_avg_total_ihs"  local b "Total Income (Avg.)"
    if "`b'" == "returns_2022_r5_win"   local b "Returns to net wealth (2022)"
    if "`b'" == "returns_avg_r5_win"    local b "Returns to net wealth (Avg.)"
    if "`b'" == "panel_spec1_r5_win"    local b "Panel specification 1"
    if "`b'" == "panel_spec2_r5_win"    local b "Panel specification 2"
    if "`b'" == "panel_fe_2nd_r5_win"   local b "Panel spec. 3 (f.e.)"
    local s = spec[`i']
    if "`s'" == "controls" local s "Controls"
    local N_s  = string(N[`i'], "%9.0fc")
    local b1_s = string(b1[`i'], "%9.4f")
    local b2_s = string(b2[`i'], "%9.4f")
    local bs_s "No"
    if both_sig[`i'] == 1 local bs_s "Yes"
    local pj_s = string(p_joint[`i'], "%9.4f")
    local tp_s = string(tp[`i'], "%9.4f")
    file write fh "`b' & `s' & `N_s' & `b1_s' & `b2_s' & `bs_s' & `pj_s' & `tp_s' \\\\" _n
}
file write fh "\bottomrule" _n ///
    "\end{tabular}" _n ///
    "\end{table}" _n
file close fh

* Delta-method focused table (reprints T* plus its uncertainty)
preserve
keep block spec depvar N tp tp_se tp_p tp_lb tp_ub tp_in_support shape
order block spec depvar N tp tp_se tp_p tp_lb tp_ub tp_in_support shape
export delimited using "${REGRESSIONS}/Other/trust_turning_points_original_results_delta.csv", replace

file open fd using "${REGRESSIONS}/Other/trust_turning_points_original_results_delta.tex", write replace
file write fd "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Delta-method results for trust turning points}" _n ///
    "\label{tab:trust_turning_points_original_results_delta}" _n ///
    "\begin{tabular}{lrrrrrr}\toprule" _n ///
    "Model & N & \((\textit{Trust})^*\) & SE\((\textit{Trust})^*\) & p\((\textit{Trust})^*\) & \(\underline{CI}\) & \(\overline{CI}\) \\\\ \midrule" _n
forvalues i = 1/`=_N' {
    local b   = block[`i']
    if "`b'" == "income_2020_total_ihs" local b "Total Income (2022)"
    if "`b'" == "income_avg_total_ihs"  local b "Total Income (Avg.)"
    if "`b'" == "returns_2022_r5_win"   local b "Returns to net wealth (2022)"
    if "`b'" == "returns_avg_r5_win"    local b "Returns to net wealth (Avg.)"
    if "`b'" == "panel_spec1_r5_win"    local b "Panel spec. 1"
    if "`b'" == "panel_spec2_r5_win"    local b "Panel spec. 2"
    if "`b'" == "panel_fe_2nd_r5_win"   local b "Panel spec. 3 (f.e.)"
    local N_s = string(N[`i'], "%9.0fc")
    local tp_s = string(tp[`i'], "%9.4f")
    local se_s = string(tp_se[`i'], "%9.4f")
    local p_s  = string(tp_p[`i'], "%9.4f")
    local lb_s = string(tp_lb[`i'], "%9.4f")
    local ub_s = string(tp_ub[`i'], "%9.4f")
    file write fd "`b' & `N_s' & `tp_s' & `se_s' & `p_s' & `lb_s' & `ub_s' \\\\" _n
}
file write fd "\bottomrule" _n ///
    "\end{tabular}" _n ///
    "\end{table}" _n
file close fd
restore

di as txt _n "=== Turning points: original continuous-education results ==="
list block spec depvar N b1 b2 both_sig p_joint tp tp_se tp_p t_min t_max tp_in_support shape, noobs abbrev(24)
di as txt _n "Wrote: ${REGRESSIONS}/Other/trust_turning_points_original_results.csv"
di as txt "Wrote: ${REGRESSIONS}/Other/trust_turning_points_original_results.tex"
di as txt "Wrote: ${REGRESSIONS}/Other/trust_turning_points_original_results_delta.csv"
di as txt "Wrote: ${REGRESSIONS}/Other/trust_turning_points_original_results_delta.tex"
log close
