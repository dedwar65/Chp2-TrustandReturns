* 26_results_edu_categorical.do
* Re-run key Results-section regressions using education categories (not linear years).
* Education groups match descriptive scripts:
*   1 no hs (<12), 2 hs (=12), 3 some college (13-15), 4 4yr degree (=16), 5 grad (>=17)
*
* Main outputs (new files; originals unchanged):
* - Trust:   Regressions/Tests/Trust/trust_reg_general_educcat.tex
* - Income:  Regressions/Tests/Income/Total/income_trust_general_ihs_educcat.tex
* - Avg inc: Regressions/Tests/Average/Income/Total/income_trust_general_deflwin_ihs_educcat.tex
* - Return:  Regressions/Tests/Returns/Net wealth/returns_r5_trust_general_win_educcat.tex
* - Avg ret: Regressions/Tests/Average/Returns/Net wealth/returns_r5_trust_general_avg_win_educcat.tex
* - Panel1:  Regressions/Tests/Panel/panel_reg_r5_win_educcat.tex
* - Panel2:  Regressions/Tests/Panel/panel_reg_r5_spec2_win_educcat.tex
* - FE 2nd:  Regressions/Tests/Panel/panel_fe_on_tinv_r5_win_educcat.tex
*
* Diagnostics log:
* - Notes/Logs/26_results_edu_categorical.log

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

capture log close
log using "${LOG_DIR}/26_results_edu_categorical.log", replace text

capture which esttab
if _rc ssc install estout, replace

* Test output directories
capture mkdir "${REGRESSIONS}/Tests"
capture mkdir "${REGRESSIONS}/Tests/Trust"
capture mkdir "${REGRESSIONS}/Tests/Income"
capture mkdir "${REGRESSIONS}/Tests/Income/Total"
capture mkdir "${REGRESSIONS}/Tests/Average"
capture mkdir "${REGRESSIONS}/Tests/Average/Income"
capture mkdir "${REGRESSIONS}/Tests/Average/Income/Total"
capture mkdir "${REGRESSIONS}/Tests/Returns"
capture mkdir "${REGRESSIONS}/Tests/Returns/Net wealth"
capture mkdir "${REGRESSIONS}/Tests/Average/Returns"
capture mkdir "${REGRESSIONS}/Tests/Average/Returns/Net wealth"
capture mkdir "${REGRESSIONS}/Tests/Panel"
capture mkdir "${REGRESSIONS}/Tests/Summaries"

program define _mk_educ_group
    capture drop educ_group
    gen byte educ_group = .
    replace educ_group = 1 if educ_yrs < 12
    replace educ_group = 2 if educ_yrs == 12
    replace educ_group = 3 if inrange(educ_yrs,13,15)
    replace educ_group = 4 if educ_yrs == 16
    replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
    capture label drop educ_group_lbl
    label define educ_group_lbl 1 "No hs" 2 "Hs" 3 "Some college" 4 "4yr degree" 5 "Grad"
    label values educ_group educ_group_lbl
    label variable educ_group "Education group"
end

* ------------------------------------------------------------
* 1) Cross section: trust_reg_general (2020)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group

local demo_core "i.gender i.educ_group married_2020"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"

local demo_race "i.race_eth"
capture confirm variable race_eth
if _rc local demo_race ""

local extra_ctrl "depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 num_divorce_2020 num_widow_2020"
local full_ctrl "`demo_core' `demo_race' `extra_ctrl'"

eststo clear
eststo m1: regress trust_others_2020 `demo_core' `demo_race' if !missing(trust_others_2020), vce(robust)
eststo m2: regress trust_others_2020 `full_ctrl' if !missing(trust_others_2020), vce(robust)

local drop_list "1.gender 1.race_eth 1.educ_group"
capture confirm variable age_bin
if !_rc {
    estimates restore m2
    local cn : colnames e(b)
    foreach c of local cn {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
    }
}

esttab m1 m2 using "${REGRESSIONS}/Tests/Trust/trust_reg_general_educcat.tex", replace ///
    booktabs no gap mtitles("Demographics" "Full controls") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    drop(`drop_list' *.age_bin, relax) ///
    varlabels(2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              married_2020 "Married" ///
              depression_2020 "Depression" health_cond_2020 "Health conditions" ///
              medicare_2020 "Covered by Medicare" medicaid_2020 "Covered by Medicaid" ///
              life_ins_2020 "Has life insurance" num_divorce_2020 "Number of reported divorces" ///
              num_widow_2020 "Number of reported times widowed" _cons "Constant") ///
    title("General trust (2020) on controls, education categories") ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 2) Cross section: income_trust_general_ihs (2020 total income)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group

local trust_var "trust_others_2020"
local y_inc "ihs_tot_inc_defl_win_s_2020"
local full_ctrl "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local full_ctrl "i.age_bin `full_ctrl'"
capture confirm variable inlbrf_2020
if !_rc local full_ctrl "`full_ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local full_ctrl "`full_ctrl' i.race_eth"

eststo clear
eststo m1: regress `y_inc' c.`trust_var' if !missing(`y_inc') & !missing(`trust_var'), vce(robust)
eststo m2: regress `y_inc' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`y_inc') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m2
eststo m3: regress `y_inc' c.`trust_var' `full_ctrl' if !missing(`y_inc') & !missing(`trust_var'), vce(robust)
eststo m4: regress `y_inc' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`y_inc') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m4

local drop_list "1.gender 1.race_eth 1.educ_group"
capture confirm variable age_bin
if !_rc {
    estimates restore m4
    local cn : colnames e(b)
    foreach c of local cn {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
    }
}

esttab m1 m2 m3 m4 using "${REGRESSIONS}/Tests/Income/Total/income_trust_general_ihs_educcat.tex", replace ///
    booktabs mtitles("1" "2" "3" "4") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    drop(`drop_list' *.age_bin, relax) ///
    varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" ///
              2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    title("Total income (2020, scaled asinh) on general trust with education categories") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust\$^2\$ p-value")) ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 3) Average income: income_trust_general_deflwin_ihs
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group

local y_inc_avg "ihs_tot_inc_defl_win_avg"
local trust_var "trust_others_2020"
local full_ctrl "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local full_ctrl "i.age_bin `full_ctrl'"
capture confirm variable inlbrf_2020
if !_rc local full_ctrl "`full_ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local full_ctrl "`full_ctrl' i.race_eth"

eststo clear
eststo m1: regress `y_inc_avg' c.`trust_var' if !missing(`y_inc_avg') & !missing(`trust_var'), vce(robust)
eststo m2: regress `y_inc_avg' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`y_inc_avg') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m2
eststo m3: regress `y_inc_avg' c.`trust_var' `full_ctrl' if !missing(`y_inc_avg') & !missing(`trust_var'), vce(robust)
eststo m4: regress `y_inc_avg' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`y_inc_avg') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m4

local drop_list "1.gender 1.race_eth 1.educ_group"
capture confirm variable age_bin
if !_rc {
    estimates restore m4
    local cn : colnames e(b)
    foreach c of local cn {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
    }
}

esttab m1 m2 m3 m4 using "${REGRESSIONS}/Tests/Average/Income/Total/income_trust_general_deflwin_ihs_educcat.tex", replace ///
    booktabs mtitles("1" "2" "3" "4") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    drop(`drop_list' *.age_bin, relax) ///
    varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" ///
              2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    title("Average total income (scaled asinh) on general trust with education categories") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust\$^2\$ p-value")) ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 4) Cross section returns: returns_r5_trust_general_win (2022)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group

local y_r5 "r5_annual_w5_2022"
capture confirm variable `y_r5'
if _rc local y_r5 "r5_annual_2022_w5"

local trust_var "trust_others_2020"
local ctrl_base "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_base "i.age_bin `ctrl_base'"
capture confirm variable race_eth
if !_rc local ctrl_base "`ctrl_base' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl_base "`ctrl_base' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_base "`ctrl_base' wealth_d`d'_2020"
}

eststo clear
eststo m1: regress `y_r5' c.`trust_var' if !missing(`y_r5') & !missing(`trust_var'), vce(robust)
eststo m2: regress `y_r5' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`y_r5') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m2
eststo m3: regress `y_r5' c.`trust_var' `ctrl_base' if !missing(`y_r5') & !missing(`trust_var'), vce(robust)
eststo m4: regress `y_r5' c.`trust_var' c.`trust_var'#c.`trust_var' `ctrl_base' if !missing(`y_r5') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m4

local drop_list "1.gender 1.race_eth 1.educ_group"
capture confirm variable age_bin
if !_rc {
    estimates restore m4
    local cn : colnames e(b)
    foreach c of local cn {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
    }
}
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local drop_list "`drop_list' wealth_d`d'_2020"
}

esttab m1 m2 m3 m4 using "${REGRESSIONS}/Tests/Returns/Net wealth/returns_r5_trust_general_win_educcat.tex", replace ///
    booktabs mtitles("1" "2" "3" "4") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    drop(`drop_list' *.age_bin, relax) ///
    varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" ///
              2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    title("2022 returns to net wealth (5 pct winsorized) on general trust, education categories") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 5) Average returns: returns_r5_trust_general_avg_win
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group

local y_r5_avg "r5_annual_avg_w5"
local trust_var "trust_others_2020"
local ctrl_base "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_base "i.age_bin `ctrl_base'"
capture confirm variable race_eth
if !_rc local ctrl_base "`ctrl_base' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl_base "`ctrl_base' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_base "`ctrl_base' wealth_d`d'_2020"
}

eststo clear
eststo m1: regress `y_r5_avg' c.`trust_var' if !missing(`y_r5_avg') & !missing(`trust_var'), vce(robust)
eststo m2: regress `y_r5_avg' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`y_r5_avg') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m2
eststo m3: regress `y_r5_avg' c.`trust_var' `ctrl_base' if !missing(`y_r5_avg') & !missing(`trust_var'), vce(robust)
eststo m4: regress `y_r5_avg' c.`trust_var' c.`trust_var'#c.`trust_var' `ctrl_base' if !missing(`y_r5_avg') & !missing(`trust_var'), vce(robust)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m4

local drop_list "1.gender 1.race_eth 1.educ_group"
capture confirm variable age_bin
if !_rc {
    estimates restore m4
    local cn : colnames e(b)
    foreach c of local cn {
        if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
    }
}
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local drop_list "`drop_list' wealth_d`d'_2020"
}

esttab m1 m2 m3 m4 using "${REGRESSIONS}/Tests/Average/Returns/Net wealth/returns_r5_trust_general_avg_win_educcat.tex", replace ///
    booktabs mtitles("1" "2" "3" "4") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    drop(`drop_list' *.age_bin, relax) ///
    varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" ///
              2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    title("Average returns to net wealth (5 pct winsorized) on general trust, education categories") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 6) Panel Spec 1 (winsorized): panel_reg_r5_win
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off
xtset hhidpn year
_mk_educ_group

local yvar "r5_annual_w5"
local trust_var "trust_others_2020"
local ctrl "i.age_bin i.educ_group i.gender i.race_eth inlbrf married born_us i.censreg i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}

eststo clear
eststo m1: regress `yvar' `ctrl' if !missing(`yvar'), vce(cluster hhidpn)
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m1
else estadd scalar p_joint_censreg = . : m1
eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m2
else estadd scalar p_joint_censreg = . : m2
eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(cluster hhidpn)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m3
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m3
else estadd scalar p_joint_censreg = . : m3

local keep_list "2.educ_group 3.educ_group 4.educ_group 5.educ_group 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us `trust_var' c.`trust_var'#c.`trust_var' _cons"
esttab m1 m2 m3 using "${REGRESSIONS}/Tests/Panel/panel_reg_r5_win_educcat.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label keep(`keep_list') ///
    varlabels(2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S." ///
              `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$") ///
    stats(N r2_a p_joint_trust p_joint_censreg, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust\$^2\$ p-value" "Joint test: Region p-value")) ///
    title("Panel: returns to net wealth (5 pct winsorized), education categories") ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 7) Panel Spec 2 (winsorized): panel_reg_r5_spec2_win
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off
xtset hhidpn year
_mk_educ_group

local yvar "r5_annual_w5"
local trust_var "trust_others_2020"
local ctrl "i.age_bin i.educ_group i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
local ctrl "`ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

eststo clear
eststo m1: regress `yvar' `ctrl' if !missing(`yvar') & `share_cond', vce(cluster hhidpn)
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
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m1
else estadd scalar p_joint_censreg = . : m1

eststo m2: regress `yvar' `ctrl' c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
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
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m2
else estadd scalar p_joint_censreg = . : m2

eststo m3: regress `yvar' `ctrl' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var') & `share_cond', vce(cluster hhidpn)
quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
estadd scalar p_joint_trust = r(p) : m3
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
capture testparm i.censreg
if _rc == 0 estadd scalar p_joint_censreg = r(p) : m3
else estadd scalar p_joint_censreg = . : m3

local keep_list "2.educ_group 3.educ_group 4.educ_group 5.educ_group 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us share_core share_ira share_res share_debt_long share_debt_other `trust_var' c.`trust_var'#c.`trust_var' _cons"
esttab m1 m2 m3 using "${REGRESSIONS}/Tests/Panel/panel_reg_r5_spec2_win_educcat.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label keep(`keep_list') ///
    varlabels(2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S." ///
              share_core "Share core" share_ira "Share IRA" share_res "Share residential" ///
              share_debt_long "Share long-term debt" share_debt_other "Share other debt" ///
              `trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$") ///
    stats(N r2_a p_joint_trust p_joint_censreg p_joint_share_core p_joint_share_ira p_joint_share_res p_joint_share_debt_long p_joint_share_debt_other, ///
          labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust\$^2\$ p-value" "Joint test: Region p-value" "Joint test: Share core x year p-value" ///
                 "Joint test: Share IRA x year p-value" "Joint test: Share res x year p-value" ///
                 "Joint test: Share debt long x year p-value" "Joint test: Share debt other x year p-value")) ///
    title("Panel Spec 2: returns to net wealth (5 pct winsorized), education categories") ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 8) FE second stage for r5 winsorized with education categories
*    (Spec 3 first stage unchanged; education is time-invariant and not in FE equation)
* ------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year

local yvar "r5_annual_w5"
local ctrl "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
local ctrl "`ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

quietly xtreg `yvar' `ctrl' if !missing(`yvar') & `share_cond', fe vce(cluster hhidpn)
predict double __hdfe1__, u
keep if e(sample)
keep hhidpn __hdfe1__
collapse (first) __hdfe1__, by(hhidpn)
rename __hdfe1__ fe
tempfile fe_r5
save `fe_r5'

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
keep hhidpn educ_yrs gender race_eth born_us trust_others_2020
duplicates drop hhidpn, force
_mk_educ_group
keep hhidpn educ_group gender race_eth born_us trust_others_2020
merge 1:1 hhidpn using `fe_r5', nogen
drop if missing(fe) | missing(educ_group) | missing(gender) | missing(race_eth)

eststo clear
eststo m1: regress fe i.educ_group i.gender i.race_eth born_us, vce(robust)
eststo m2: regress fe i.educ_group i.gender i.race_eth born_us trust_others_2020 if !missing(trust_others_2020), vce(robust)
eststo m3: regress fe i.educ_group i.gender i.race_eth born_us trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(trust_others_2020), vce(robust)
quietly testparm trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3

local keep_list "2.educ_group 3.educ_group 4.educ_group 5.educ_group 2.gender 2.race_eth 3.race_eth 4.race_eth born_us trust_others_2020 c.trust_others_2020#c.trust_others_2020 _cons"
esttab m1 m2 m3 using "${REGRESSIONS}/Tests/Panel/panel_fe_on_tinv_r5_win_educcat.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label keep(`keep_list') ///
    varlabels(2.educ_group "HS" 3.educ_group "Some college" 4.educ_group "4yr degree" 5.educ_group "Grad" ///
              2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" ///
              born_us "Born in U.S." trust_others_2020 "Trust" c.trust_others_2020#c.trust_others_2020 "Trust\$^2\$") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust\$^2\$ p-value")) ///
    title("Second-stage FE (r5 winsorized) on time-invariant vars, education categories") ///
    addnotes(".") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

* ------------------------------------------------------------
* 9) Diagnostics for education sign flip in r5
* ------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group
local y_r5 "r5_annual_w5_2022"
capture confirm variable `y_r5'
if _rc local y_r5 "r5_annual_2022_w5"
local trust_var "trust_others_2020"

di as txt _n "=== Diagnostic A: Debt shares by education group (cross-section sample) ==="
tabstat share_debt_long_2020 share_debt_other_2020 `y_r5' if !missing(`y_r5') & !missing(`trust_var'), by(educ_group) stat(n mean p50 p95)

di as txt _n "=== Diagnostic B: Stepwise r5 models with education categories ==="
regress `y_r5' i.educ_group if !missing(`y_r5'), vce(robust)
regress `y_r5' i.educ_group i.age_bin i.gender i.race_eth married_2020 born_us inlbrf_2020 if !missing(`y_r5'), vce(robust)
local wctrl ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local wctrl "`wctrl' wealth_d`d'_2020"
}
regress `y_r5' i.educ_group i.age_bin i.gender i.race_eth married_2020 born_us inlbrf_2020 `wctrl' if !missing(`y_r5'), vce(robust)
regress `y_r5' i.educ_group c.`trust_var' c.`trust_var'#c.`trust_var' i.age_bin i.gender i.race_eth married_2020 born_us inlbrf_2020 `wctrl' if !missing(`y_r5') & !missing(`trust_var'), vce(robust)

* ------------------------------------------------------------
* 10) Turning points for every model in this do-file with trust + trust^2
*     T* = -beta1/(2*beta2), from exact e(b), not rounded LaTeX tables
* ------------------------------------------------------------
tempfile tpraw
postfile tpH str40 block str20 spec str24 depvar str24 trustvar ///
    double N b1 b2 tp tp_se tp_p tp_lb tp_ub t_min t_max ///
    using "`tpraw'", replace

local tvar "trust_others_2020"
local sq "c.`tvar'#c.`tvar'"

* Cross-section income (2020, total IHS): quadratic no-ctrl + ctrl
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group
local y_inc "ihs_tot_inc_defl_win_s_2020"
local ctrl_inc "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_inc "i.age_bin `ctrl_inc'"
capture confirm variable inlbrf_2020
if !_rc local ctrl_inc "`ctrl_inc' inlbrf_2020"
capture confirm variable race_eth
if !_rc local ctrl_inc "`ctrl_inc' i.race_eth"

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y_inc' c.`tvar' `sq' if !missing(`y_inc') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y_inc' c.`tvar' `sq' `ctrl_inc' if !missing(`y_inc') & !missing(`tvar'), vce(robust)
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
    post tpH ("income_2020_total_ihs") ("`s'") ("`y_inc'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')
}

* Average income (total IHS): quadratic no-ctrl + ctrl
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group
local y_inc_avg "ihs_tot_inc_defl_win_avg"
local ctrl_inc_avg "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_inc_avg "i.age_bin `ctrl_inc_avg'"
capture confirm variable inlbrf_2020
if !_rc local ctrl_inc_avg "`ctrl_inc_avg' inlbrf_2020"
capture confirm variable race_eth
if !_rc local ctrl_inc_avg "`ctrl_inc_avg' i.race_eth"

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y_inc_avg' c.`tvar' `sq' if !missing(`y_inc_avg') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y_inc_avg' c.`tvar' `sq' `ctrl_inc_avg' if !missing(`y_inc_avg') & !missing(`tvar'), vce(robust)
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
    post tpH ("income_avg_total_ihs") ("`s'") ("`y_inc_avg'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')
}

* Cross-section returns r5 2022 winsorized: quadratic no-ctrl + ctrl
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group
local y_r5 "r5_annual_w5_2022"
capture confirm variable `y_r5'
if _rc local y_r5 "r5_annual_2022_w5"
local ctrl_r5cs "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_r5cs "i.age_bin `ctrl_r5cs'"
capture confirm variable race_eth
if !_rc local ctrl_r5cs "`ctrl_r5cs' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl_r5cs "`ctrl_r5cs' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5cs "`ctrl_r5cs' wealth_d`d'_2020"
}

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y_r5' c.`tvar' `sq' if !missing(`y_r5') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y_r5' c.`tvar' `sq' `ctrl_r5cs' if !missing(`y_r5') & !missing(`tvar'), vce(robust)
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
    post tpH ("returns_2022_r5_win") ("`s'") ("`y_r5'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')
}

* Average returns r5 winsorized: quadratic no-ctrl + ctrl
use "${PROCESSED}/analysis_ready_processed.dta", clear
capture confirm variable age_2020
if !_rc gen int age_bin = floor(age_2020/5)*5
_mk_educ_group
local y_r5avg "r5_annual_avg_w5"
local ctrl_r5avg "i.gender i.educ_group married_2020 born_us"
capture confirm variable age_bin
if !_rc local ctrl_r5avg "i.age_bin `ctrl_r5avg'"
capture confirm variable race_eth
if !_rc local ctrl_r5avg "`ctrl_r5avg' i.race_eth"
capture confirm variable inlbrf_2020
if !_rc local ctrl_r5avg "`ctrl_r5avg' inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5avg "`ctrl_r5avg' wealth_d`d'_2020"
}

foreach s in nocontrol controls {
    if "`s'" == "nocontrol" regress `y_r5avg' c.`tvar' `sq' if !missing(`y_r5avg') & !missing(`tvar'), vce(robust)
    if "`s'" == "controls"  regress `y_r5avg' c.`tvar' `sq' `ctrl_r5avg' if !missing(`y_r5avg') & !missing(`tvar'), vce(robust)
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
    post tpH ("returns_avg_r5_win") ("`s'") ("`y_r5avg'") ("`tvar'") ///
        (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')
}

* Panel spec 1 (winsorized): quadratic controls
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
_mk_educ_group
local y_p1 "r5_annual_w5"
local ctrl_p1 "i.age_bin i.educ_group i.gender i.race_eth inlbrf married born_us i.censreg i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_p1 "`ctrl_p1' wealth_d`d'"
}
regress `y_p1' c.`tvar' `sq' `ctrl_p1' if !missing(`y_p1') & !missing(`tvar'), vce(cluster hhidpn)
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
post tpH ("panel_spec1_r5_win") ("controls") ("`y_p1'") ("`tvar'") ///
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')

* Panel spec 2 (winsorized): quadratic controls
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
_mk_educ_group
local y_p2 "r5_annual_w5"
local ctrl_p2 "i.age_bin i.educ_group i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_p2 "`ctrl_p2' wealth_d`d'"
}
local ctrl_p2 "`ctrl_p2' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"
regress `y_p2' c.`tvar' `sq' `ctrl_p2' if !missing(`y_p2') & !missing(`tvar') & `share_cond', vce(cluster hhidpn)
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
post tpH ("panel_spec2_r5_win") ("controls") ("`y_p2'") ("`tvar'") ///
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')

* FE second-stage (r5 winsorized): quadratic controls
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
xtset hhidpn year
local yvar "r5_annual_w5"
local ctrl "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl "`ctrl' wealth_d`d'"
}
local ctrl "`ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"
quietly xtreg `yvar' `ctrl' if !missing(`yvar') & `share_cond', fe vce(cluster hhidpn)
predict double __hdfe2__, u
keep if e(sample)
keep hhidpn __hdfe2__
collapse (first) __hdfe2__, by(hhidpn)
rename __hdfe2__ fe
tempfile fe2
save `fe2'

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
keep hhidpn educ_yrs gender race_eth born_us trust_others_2020
duplicates drop hhidpn, force
_mk_educ_group
keep hhidpn educ_group gender race_eth born_us trust_others_2020
merge 1:1 hhidpn using `fe2', nogen
regress fe i.educ_group i.gender i.race_eth born_us c.`tvar' `sq' if !missing(`tvar'), vce(robust)
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
    (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax')

postclose tpH
use "`tpraw'", clear

gen str14 shape = cond(b2<0, "concave_max", cond(b2>0, "convex_min", "linear"))
gen byte tp_in_support = (tp>=t_min & tp<=t_max) if !missing(tp,t_min,t_max)
order block spec depvar N b1 b2 tp tp_se tp_p tp_lb tp_ub t_min t_max tp_in_support shape

export delimited using "${REGRESSIONS}/Tests/Summaries/trust_turning_points_educcat.csv", replace

di as txt _n "=== Turning-point summary (exact coefficients) ==="
list block spec depvar N b1 b2 tp tp_se tp_p t_min t_max tp_in_support shape, noobs abbrev(24)

di as txt _n "Done. Wrote education-category versions, diagnostics, and turning-point summaries in ${REGRESSIONS}/Tests/."
log close
