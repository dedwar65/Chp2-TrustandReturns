* 20_finlit_extension.do
* Financial literacy extensions: descriptive tables + r5 regression tables (4 cols each).
* Descriptives: finlit_freq (0/1/2/3 correct), finlit_q2 summary + by gender/race/age/educ,
*   finlit_score by gender/race/age/educ. Focus on q2 (inflation) and score.
* Regressions: 5 specs, 4 cols each: (1) q1+q2+q3+ctrl, (2) score+ctrl, (3) q1+q2+q3+ctrl+trust+trust^2, (4) score+ctrl+trust+trust^2.
* Focus on q2; q1 and q3 included to show they are not significant.
* Output: Code/Regressions/FinLit/Tables/
* Log: Notes/Logs/20_finlit_extension.log

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

capture mkdir "${REGRESSIONS}/FinLit"
capture mkdir "${REGRESSIONS}/FinLit/Tables"
capture log close
log using "${LOG_DIR}/20_finlit_extension.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Create financial literacy variables
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

capture confirm variable rv565_2020
if _rc {
    gen byte _q1 = interest_2020
    gen byte _q2 = inflation_2020
    gen byte _q3 = risk_div_2020
}
else {
    gen byte _q1 = rv565_2020
    gen byte _q2 = rv566_2020
    gen byte _q3 = rv567_2020
}

foreach v in _q1 _q2 _q3 {
    replace `v' = . if inlist(`v', 8, 9, -8)
}

capture drop finlit_q1 finlit_q2 finlit_q3 finlit_score
gen byte finlit_q1 = (_q1 == 3) if !missing(_q1)
gen byte finlit_q2 = (_q2 == 3) if !missing(_q2)
gen byte finlit_q3 = (_q3 == 5) if !missing(_q3)
egen byte finlit_score = rowtotal(finlit_q1 finlit_q2 finlit_q3), missing
replace finlit_score = . if missing(finlit_q1) | missing(finlit_q2) | missing(finlit_q3)
drop _q1 _q2 _q3

capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* ----------------------------------------------------------------------
* Descriptive tables — export to FinLit/Tables/
* Labels: match income tables (06) and trust tables (08)
* ----------------------------------------------------------------------
local FINLIT_TAB "${REGRESSIONS}/FinLit/Tables"

label define gender_lbl 1 "Male" 2 "Female", replace
label define race_eth_lbl 1 "White (NH)" 2 "Black (NH)" 3 "Hispanic" 4 "Other (NH)", replace
label define educ_group_lbl 1 "no hs" 2 "hs" 3 "some college" 4 "4yr degree" 5 "grad", replace
label values gender gender_lbl
capture confirm variable race_eth
if !_rc label values race_eth race_eth_lbl

* Frequency
preserve
keep if !missing(finlit_score)
contract finlit_score, freq(n)
quietly egen _tot = total(n)
file open fh using "`FINLIT_TAB'/finlit_freq.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Literacy score (0--3) frequency}" _n "\label{tab:finlit_freq}" _n "\begin{tabular}{lrr}\toprule" _n "Literacy score & N & Pct \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local sc = string(finlit_score[`r'], "%9.0f")
    local n_s = string(n[`r'], "%9.0f")
    local pct = string(100*n[`r']/_tot[1], "%5.1f")
    file write fh "`sc' & `n_s' & `pct' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Q2 (inflation) summary — proportion correct
quietly summarize finlit_q2 if !missing(finlit_q2), detail
file open fh using "`FINLIT_TAB'/finlit_q2_summary.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Inflation question summary}" _n "\label{tab:finlit_q2_summary}" _n "\begin{tabular}{lrr}\toprule" _n "Variable & N & Mean (prop. correct) \\\\ \midrule" _n
local n_s = string(r(N), "%9.0f")
local m_s = string(r(mean), "%9.2f")
file write fh "Inflation & `n_s' & `m_s' \\\\" _n
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh

* Q2 by gender
preserve
collapse (mean) m=finlit_q2 (sd) s=finlit_q2 (count) n=finlit_q2, by(gender)
drop if n < 2
decode gender, gen(gender_label)
file open fh using "`FINLIT_TAB'/finlit_q2_by_gender.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Inflation by gender}" _n "\label{tab:finlit_q2_by_gender}" _n "\begin{tabular}{lrr}\toprule" _n "Gender & N & Mean \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local glab = gender_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    local m_s = string(m[`r'], "%5.2f")
    file write fh "`glab' & `n_s' & `m_s' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Q2 by race_eth
capture confirm variable race_eth
if !_rc {
    preserve
    collapse (mean) m=finlit_q2 (sd) s=finlit_q2 (count) n=finlit_q2, by(race_eth)
    drop if n < 2
    decode race_eth, gen(race_label)
    file open fh using "`FINLIT_TAB'/finlit_q2_by_race_eth.tex", write replace
    file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Inflation by race/ethnicity}" _n "\label{tab:finlit_q2_by_race_eth}" _n "\begin{tabular}{lrr}\toprule" _n "Race/ethnicity & N & Mean \\\\ \midrule" _n
    forvalues r = 1/`=_N' {
        local rlab = race_label[`r']
        local n_s = string(n[`r'], "%9.0f")
        local m_s = string(m[`r'], "%5.2f")
        file write fh "`rlab' & `n_s' & `m_s' \\\\" _n
    }
    file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
    file close fh
    restore
}

* Q2 by age bin (5-yr bins, e.g., 50 = 50--54)
preserve
collapse (mean) m=finlit_q2 (sd) s=finlit_q2 (count) n=finlit_q2, by(age_bin)
drop if missing(age_bin) | n < 2
gen str age_label = string(age_bin, "%9.0f") + "--" + string(age_bin+4, "%9.0f")
file open fh using "`FINLIT_TAB'/finlit_q2_by_age.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Inflation by age}" _n "\label{tab:finlit_q2_by_age}" _n "\begin{tabular}{lrr}\toprule" _n "Age & N & Mean \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local alab = age_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    local m_s = string(m[`r'], "%5.2f")
    file write fh "`alab' & `n_s' & `m_s' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Q2 by education group (match income: no hs, hs, some college, 4yr degree, grad)
capture confirm variable educ_yrs
if !_rc {
    preserve
    gen byte educ_group = .
    replace educ_group = 1 if educ_yrs < 12
    replace educ_group = 2 if educ_yrs == 12
    replace educ_group = 3 if inrange(educ_yrs, 13, 15)
    replace educ_group = 4 if educ_yrs == 16
    replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
    label values educ_group educ_group_lbl
    collapse (mean) m=finlit_q2 (sd) s=finlit_q2 (count) n=finlit_q2, by(educ_group)
    drop if missing(educ_group) | n < 2
    decode educ_group, gen(educ_label)
    file open fh using "`FINLIT_TAB'/finlit_q2_by_educ.tex", write replace
    file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Inflation by education}" _n "\label{tab:finlit_q2_by_educ}" _n "\begin{tabular}{lrr}\toprule" _n "Education & N & Mean \\\\ \midrule" _n
    forvalues r = 1/`=_N' {
        local elab = educ_label[`r']
        local n_s = string(n[`r'], "%9.0f")
        local m_s = string(m[`r'], "%5.2f")
        file write fh "`elab' & `n_s' & `m_s' \\\\" _n
    }
    file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
    file close fh
    restore
}

* Score (0-3) by gender
preserve
collapse (mean) m=finlit_score (sd) s=finlit_score (count) n=finlit_score, by(gender)
drop if n < 2
decode gender, gen(gender_label)
file open fh using "`FINLIT_TAB'/finlit_score_by_gender.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Literacy score by gender}" _n "\label{tab:finlit_score_by_gender}" _n "\begin{tabular}{lrr}\toprule" _n "Gender & N & Mean \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local glab = gender_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    local m_s = string(m[`r'], "%5.2f")
    file write fh "`glab' & `n_s' & `m_s' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Score by race_eth
capture confirm variable race_eth
if !_rc {
    preserve
    collapse (mean) m=finlit_score (sd) s=finlit_score (count) n=finlit_score, by(race_eth)
    drop if n < 2
    decode race_eth, gen(race_label)
    file open fh using "`FINLIT_TAB'/finlit_score_by_race_eth.tex", write replace
    file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Literacy score by race/ethnicity}" _n "\label{tab:finlit_score_by_race_eth}" _n "\begin{tabular}{lrr}\toprule" _n "Race/ethnicity & N & Mean \\\\ \midrule" _n
    forvalues r = 1/`=_N' {
        local rlab = race_label[`r']
        local n_s = string(n[`r'], "%9.0f")
        local m_s = string(m[`r'], "%5.2f")
        file write fh "`rlab' & `n_s' & `m_s' \\\\" _n
    }
    file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
    file close fh
    restore
}

* Score by age bin (5-yr bins)
preserve
collapse (mean) m=finlit_score (sd) s=finlit_score (count) n=finlit_score, by(age_bin)
drop if missing(age_bin) | n < 2
gen str age_label = string(age_bin, "%9.0f") + "--" + string(age_bin+4, "%9.0f")
file open fh using "`FINLIT_TAB'/finlit_score_by_age.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Literacy score by age}" _n "\label{tab:finlit_score_by_age}" _n "\begin{tabular}{lrr}\toprule" _n "Age & N & Mean \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local alab = age_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    local m_s = string(m[`r'], "%5.2f")
    file write fh "`alab' & `n_s' & `m_s' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Score by education group (match income)
capture confirm variable educ_yrs
if !_rc {
    preserve
    gen byte educ_group = .
    replace educ_group = 1 if educ_yrs < 12
    replace educ_group = 2 if educ_yrs == 12
    replace educ_group = 3 if inrange(educ_yrs, 13, 15)
    replace educ_group = 4 if educ_yrs == 16
    replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
    label values educ_group educ_group_lbl
    collapse (mean) m=finlit_score (sd) s=finlit_score (count) n=finlit_score, by(educ_group)
    drop if missing(educ_group) | n < 2
    decode educ_group, gen(educ_label)
    file open fh using "`FINLIT_TAB'/finlit_score_by_educ.tex", write replace
    file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial literacy: Literacy score by education}" _n "\label{tab:finlit_score_by_educ}" _n "\begin{tabular}{lrr}\toprule" _n "Education & N & Mean \\\\ \midrule" _n
    forvalues r = 1/`=_N' {
        local elab = educ_label[`r']
        local n_s = string(n[`r'], "%9.0f")
        local m_s = string(m[`r'], "%5.2f")
        file write fh "`elab' & `n_s' & `m_s' \\\\" _n
    }
    file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
    file close fh
    restore
}

display "Descriptive tables saved to `FINLIT_TAB'"

* ----------------------------------------------------------------------
* Regression tables — 5 specs, 4 cols each
* ----------------------------------------------------------------------
capture confirm variable r5_annual_w5_2022
if _rc {
    display as error "r5_annual_w5_2022 not found. Run 02->03->04->05."
    log close
    exit 198
}

capture confirm variable trust_others_2020
if _rc {
    display as error "trust_others_2020 not found."
    log close
    exit 198
}

local ctrl_r5 "i.age_bin i.gender educ_yrs inlbrf_2020 married_2020 born_us i.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}

local trust_spec "c.trust_others_2020 c.trust_others_2020#c.trust_others_2020"
* Keep only main coefficients (age bins, wealth deciles omitted from table)
local keep_cs "finlit_q1 finlit_q2 finlit_q3 finlit_score trust_others_2020 c.trust_others_2020#c.trust_others_2020 educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_2020 married_2020 born_us _cons"

* Cross section
gen byte _samp = !missing(r5_annual_w5_2022) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3) & !missing(finlit_score) & !missing(trust_others_2020)

eststo clear
eststo m1: quietly regress r5_annual_w5_2022 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 if _samp, vce(robust)
estadd scalar p_joint_trust = . : m1

eststo m2: quietly regress r5_annual_w5_2022 `ctrl_r5' finlit_score if _samp, vce(robust)
estadd scalar p_joint_trust = . : m2

eststo m3: quietly regress r5_annual_w5_2022 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 `trust_spec' if _samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3

eststo m4: quietly regress r5_annual_w5_2022 `ctrl_r5' finlit_score `trust_spec' if _samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m4

esttab m1 m2 m3 m4 using "`FINLIT_TAB'/finlit_r5_cross_section.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)" "(4)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    keep(`keep_cs') ///
    varlabels(finlit_q1 "Interest" finlit_q2 "Inflation" finlit_q3 "Risk div" finlit_score "Literacy score" ///
        trust_others_2020 "General trust" c.trust_others_2020#c.trust_others_2020 "(General trust)\$^2\$" ///
        2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    title("Cross section: r5 returns (${LATEX_PCT} wins) on financial literacy and trust") ///
    addnotes("Robust SE. Age bins (5-yr) and wealth deciles" "omitted from table but included in regressions.") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

* Insert \label
tempfile tmpf
file open fh using "`FINLIT_TAB'/finlit_r5_cross_section.tex", read text
file open fout using "`tmpf'", write text replace
local lab_ins 0
file read fh line
while r(eof) == 0 {
    file write fout "`line'" _n
    if `lab_ins' == 0 & regexm(`"`line'"', "\\caption") {
        file write fout "\label{tab:finlit_r5_cross_section}" _n
        local lab_ins 1
    }
    file read fh line
}
file close fh
file close fout
copy "`tmpf'" "`FINLIT_TAB'/finlit_r5_cross_section.tex", replace

drop _samp

* Average
gen byte _samp = !missing(r5_annual_avg_w5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3) & !missing(finlit_score) & !missing(trust_others_2020)

eststo clear
eststo m1: quietly regress r5_annual_avg_w5 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 if _samp, vce(robust)
estadd scalar p_joint_trust = . : m1
eststo m2: quietly regress r5_annual_avg_w5 `ctrl_r5' finlit_score if _samp, vce(robust)
estadd scalar p_joint_trust = . : m2
eststo m3: quietly regress r5_annual_avg_w5 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 `trust_spec' if _samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3
eststo m4: quietly regress r5_annual_avg_w5 `ctrl_r5' finlit_score `trust_spec' if _samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m4

esttab m1 m2 m3 m4 using "`FINLIT_TAB'/finlit_r5_average.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)" "(4)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    keep(`keep_cs') ///
    varlabels(finlit_q1 "Interest" finlit_q2 "Inflation" finlit_q3 "Risk div" finlit_score "Literacy score" ///
        trust_others_2020 "General trust" c.trust_others_2020#c.trust_others_2020 "(General trust)\$^2\$" ///
        2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    title("Average r5 returns (${LATEX_PCT} wins) on financial literacy and trust") ///
    addnotes("Robust SE. Age bins (5-yr) and wealth deciles" "omitted from table but included in regressions.") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

tempfile tmpf
file open fh using "`FINLIT_TAB'/finlit_r5_average.tex", read text
file open fout using "`tmpf'", write text replace
local lab_ins 0
file read fh line
while r(eof) == 0 {
    file write fout "`line'" _n
    if `lab_ins' == 0 & regexm(`"`line'"', "\\caption") {
        file write fout "\label{tab:finlit_r5_average}" _n
        local lab_ins 1
    }
    file read fh line
}
file close fh
file close fout
copy "`tmpf'" "`FINLIT_TAB'/finlit_r5_average.tex", replace

drop _samp

* Panel: save finlit, load panel
preserve
keep hhidpn finlit_q1 finlit_q2 finlit_q3 finlit_score
duplicates drop hhidpn, force
tempfile finlit_wide
save `finlit_wide'
restore

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
merge m:1 hhidpn using `finlit_wide', nogen
xtset hhidpn year

local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local base_ctrl "`base_ctrl' wealth_d`d'"
}
local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

* Keep only main coefficients (age bins, wealth deciles, share×year omitted from table)
local keep_p "finlit_q1 finlit_q2 finlit_q3 finlit_score trust_others_2020 c.trust_others_2020#c.trust_others_2020 educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us _cons"

local trust_spec_p "c.trust_others_2020 c.trust_others_2020#c.trust_others_2020"

* Panel Spec 1
gen byte _samp = !missing(r5_annual_w5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3) & !missing(finlit_score) & !missing(trust_others_2020)

eststo clear
eststo m1: quietly regress r5_annual_w5 `base_ctrl' finlit_q1 finlit_q2 finlit_q3 if _samp, vce(cluster hhidpn)
estadd scalar p_joint_trust = . : m1
eststo m2: quietly regress r5_annual_w5 `base_ctrl' finlit_score if _samp, vce(cluster hhidpn)
estadd scalar p_joint_trust = . : m2
eststo m3: quietly regress r5_annual_w5 `base_ctrl' finlit_q1 finlit_q2 finlit_q3 `trust_spec_p' if _samp, vce(cluster hhidpn)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3
eststo m4: quietly regress r5_annual_w5 `base_ctrl' finlit_score `trust_spec_p' if _samp, vce(cluster hhidpn)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m4

esttab m1 m2 m3 m4 using "`FINLIT_TAB'/finlit_r5_panel1.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)" "(4)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    keep(`keep_p') ///
    varlabels(finlit_q1 "Interest" finlit_q2 "Inflation" finlit_q3 "Risk div" finlit_score "Literacy score" ///
        trust_others_2020 "General trust" c.trust_others_2020#c.trust_others_2020 "(General trust)\$^2\$" ///
        2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S.") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    title("Panel Spec 1 (pooled): r5 returns on financial literacy and trust") ///
    addnotes("Cluster-robust SE. Age bins (5-yr), wealth deciles, and region dummies" "omitted from table but included in regressions.") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

tempfile tmpf
file open fh using "`FINLIT_TAB'/finlit_r5_panel1.tex", read text
file open fout using "`tmpf'", write text replace
local lab_ins 0
file read fh line
while r(eof) == 0 {
    file write fout "`line'" _n
    if `lab_ins' == 0 & regexm(`"`line'"', "\\caption") {
        file write fout "\label{tab:finlit_r5_panel1}" _n
        local lab_ins 1
    }
    file read fh line
}
file close fh
file close fout
copy "`tmpf'" "`FINLIT_TAB'/finlit_r5_panel1.tex", replace

* Panel Spec 2
gen byte _samp2 = _samp & !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)

eststo clear
eststo m1: quietly regress r5_annual_w5 `ctrl_s2' finlit_q1 finlit_q2 finlit_q3 if _samp2, vce(cluster hhidpn)
estadd scalar p_joint_trust = . : m1
eststo m2: quietly regress r5_annual_w5 `ctrl_s2' finlit_score if _samp2, vce(cluster hhidpn)
estadd scalar p_joint_trust = . : m2
eststo m3: quietly regress r5_annual_w5 `ctrl_s2' finlit_q1 finlit_q2 finlit_q3 `trust_spec_p' if _samp2, vce(cluster hhidpn)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3
eststo m4: quietly regress r5_annual_w5 `ctrl_s2' finlit_score `trust_spec_p' if _samp2, vce(cluster hhidpn)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m4

esttab m1 m2 m3 m4 using "`FINLIT_TAB'/finlit_r5_panel2.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)" "(4)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    keep(`keep_p') ///
    varlabels(finlit_q1 "Interest" finlit_q2 "Inflation" finlit_q3 "Risk div" finlit_score "Literacy score" ///
        trust_others_2020 "General trust" c.trust_others_2020#c.trust_others_2020 "(General trust)\$^2\$" ///
        2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_ "Employed" married_ "Married" born_us "Born in U.S.") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    title("Panel Spec 2 (${LATEX_SHARE_YEAR}): r5 returns on financial literacy and trust") ///
    addnotes("Cluster-robust SE. Age bins (5-yr), wealth deciles, region dummies," "and share x year interactions omitted from table but included in regressions.") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

tempfile tmpf
file open fh using "`FINLIT_TAB'/finlit_r5_panel2.tex", read text
file open fout using "`tmpf'", write text replace
local lab_ins 0
file read fh line
while r(eof) == 0 {
    file write fout "`line'" _n
    if `lab_ins' == 0 & regexm(`"`line'"', "\\caption") {
        file write fout "\label{tab:finlit_r5_panel2}" _n
        local lab_ins 1
    }
    file read fh line
}
file close fh
file close fout
copy "`tmpf'" "`FINLIT_TAB'/finlit_r5_panel2.tex", replace

* Panel Spec 3: FE + 2nd stage
local ctrl_fe "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_fe "`ctrl_fe' wealth_d`d'"
}
local ctrl_fe "`ctrl_fe' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

gen byte _fe_cond = !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3) & !missing(trust_others_2020)
xtreg r5_annual_w5 `ctrl_fe' if _fe_cond, fe vce(cluster hhidpn)
predict _fe_r5 if e(sample)
bysort hhidpn: egen fe_r5 = mean(_fe_r5)
drop _fe_r5
collapse (first) fe_r5 educ_yrs gender race_eth born_us finlit_q1 finlit_q2 finlit_q3 finlit_score trust_others_2020, by(hhidpn)

gen byte _fe_samp = !missing(fe_r5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3) & !missing(finlit_score) & !missing(trust_others_2020)

eststo clear
eststo m1: quietly regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q1 finlit_q2 finlit_q3 if _fe_samp, vce(robust)
estadd scalar p_joint_trust = . : m1
eststo m2: quietly regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score if _fe_samp, vce(robust)
estadd scalar p_joint_trust = . : m2
eststo m3: quietly regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q1 finlit_q2 finlit_q3 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if _fe_samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m3
eststo m4: quietly regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if _fe_samp, vce(robust)
quietly testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
estadd scalar p_joint_trust = r(p) : m4

* Panel 3: FE 2nd stage — no inlbrf/married (time-varying)
local keep_p3 "finlit_q1 finlit_q2 finlit_q3 finlit_score trust_others_2020 c.trust_others_2020#c.trust_others_2020 educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth born_us _cons"
esttab m1 m2 m3 m4 using "`FINLIT_TAB'/finlit_r5_panel3.tex", replace ///
    booktabs mtitles("(1)" "(2)" "(3)" "(4)") ///
    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
    keep(`keep_p3') ///
    varlabels(finlit_q1 "Interest" finlit_q2 "Inflation" finlit_q3 "Risk div" finlit_score "Literacy score" ///
        trust_others_2020 "General trust" c.trust_others_2020#c.trust_others_2020 "(General trust)\$^2\$" ///
        educ_yrs "Years education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" born_us "Born in U.S.") ///
    stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
    title("Panel Spec 3 (FE, 2nd stage): r5 returns on financial literacy and trust") ///
    addnotes("Second-stage: FE from within regression on time-invariant + finlit. Robust SE.") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

tempfile tmpf
file open fh using "`FINLIT_TAB'/finlit_r5_panel3.tex", read text
file open fout using "`tmpf'", write text replace
local lab_ins 0
file read fh line
while r(eof) == 0 {
    file write fout "`line'" _n
    if `lab_ins' == 0 & regexm(`"`line'"', "\\caption") {
        file write fout "\label{tab:finlit_r5_panel3}" _n
        local lab_ins 1
    }
    file read fh line
}
file close fh
file close fout
copy "`tmpf'" "`FINLIT_TAB'/finlit_r5_panel3.tex", replace

display "Regression tables saved to `FINLIT_TAB'"
display "Done. Log: ${LOG_DIR}/20_finlit_extension.log"
log close
