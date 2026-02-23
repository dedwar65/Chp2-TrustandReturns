* 19_inspect_finlit_r5.do
* Combined inspect: (1) finlit q1|q2|q3|score separately, (2) all three q1+q2+q3, (3) q2 and score with/without trust+trust^2.
* Log only — all results in one log for inspection.
* Log: Notes/Logs/19_inspect_finlit_r5.log

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
capture log close
log using "${LOG_DIR}/19_inspect_finlit_r5.log", replace text

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

label variable finlit_q1 "Fin lit Q1 correct (interest)"
label variable finlit_q2 "Fin lit Q2 correct (inflation)"
label variable finlit_q3 "Fin lit Q3 correct (risk div)"
label variable finlit_score "Fin lit score (0-3)"

capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* ==========================================================================
* PART 1: Descriptives + 4 cols (finlit_q1 | q2 | q3 | score) per block
* ==========================================================================
display _n "########################################################################"
display "PART 1: Descriptives and finlit q1|q2|q3|score (4 cols per block)"
display "########################################################################"

display _n "=== Financial literacy: frequency ==="
tab finlit_score

display _n "=== Financial literacy: by gender ==="
tabstat finlit_score, by(gender) statistics(n mean sd)

display _n "=== Financial literacy: by race_eth ==="
capture confirm variable race_eth
if !_rc tabstat finlit_score, by(race_eth) statistics(n mean sd)

display _n "=== Financial literacy: by age bin ==="
tabstat finlit_score, by(age_bin) statistics(n mean sd)

display _n "=== Financial literacy: by education (quartiles) ==="
capture confirm variable educ_yrs
if !_rc {
    xtile educ_quart = educ_yrs if !missing(educ_yrs), nq(4)
    tabstat finlit_score, by(educ_quart) statistics(n mean sd)
    drop educ_quart
}

capture confirm variable r5_annual_w5_2022
if _rc {
    display as error "r5_annual_w5_2022 not found. Run 02->03->04->05."
    log close
    exit 198
}

local ctrl_r5 "i.age_bin i.gender educ_yrs inlbrf_2020 married_2020 born_us i.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}

* Cross section
gen byte _cs_sample = !missing(r5_annual_w5_2022) & !missing(finlit_score)
quietly regress r5_annual_w5_2022 `ctrl_r5' finlit_score if _cs_sample, vce(robust)
display _n "=== Cross section: r5 (5% wins) on controls + finlit (4 cols) ==="
display "N = " e(N)
regress r5_annual_w5_2022 `ctrl_r5' finlit_q1 if _cs_sample, vce(robust)
regress r5_annual_w5_2022 `ctrl_r5' finlit_q2 if _cs_sample, vce(robust)
regress r5_annual_w5_2022 `ctrl_r5' finlit_q3 if _cs_sample, vce(robust)
regress r5_annual_w5_2022 `ctrl_r5' finlit_score if _cs_sample, vce(robust)
drop _cs_sample

* Average
gen byte _avg_sample = !missing(r5_annual_avg_w5) & !missing(finlit_score)
quietly regress r5_annual_avg_w5 `ctrl_r5' finlit_score if _avg_sample, vce(robust)
display _n "=== Average r5 (5% wins) on controls + finlit (4 cols) ==="
display "N = " e(N)
regress r5_annual_avg_w5 `ctrl_r5' finlit_q1 if _avg_sample, vce(robust)
regress r5_annual_avg_w5 `ctrl_r5' finlit_q2 if _avg_sample, vce(robust)
regress r5_annual_avg_w5 `ctrl_r5' finlit_q3 if _avg_sample, vce(robust)
regress r5_annual_avg_w5 `ctrl_r5' finlit_score if _avg_sample, vce(robust)
drop _avg_sample

* Panel
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

gen byte _p1_sample = !missing(r5_annual_w5) & !missing(finlit_score)
quietly regress r5_annual_w5 `base_ctrl' finlit_score if _p1_sample, vce(cluster hhidpn)
display _n "=== Panel Spec 1 (pooled): r5 on controls + finlit (4 cols) ==="
display "N (person-years) = " e(N)
regress r5_annual_w5 `base_ctrl' finlit_q1 if _p1_sample, vce(cluster hhidpn)
regress r5_annual_w5 `base_ctrl' finlit_q2 if _p1_sample, vce(cluster hhidpn)
regress r5_annual_w5 `base_ctrl' finlit_q3 if _p1_sample, vce(cluster hhidpn)
regress r5_annual_w5 `base_ctrl' finlit_score if _p1_sample, vce(cluster hhidpn)

local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
gen byte _p2_sample = _p1_sample & !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)
quietly regress r5_annual_w5 `ctrl_s2' finlit_score if _p2_sample, vce(cluster hhidpn)
display _n "=== Panel Spec 2 (share×year): r5 on controls + finlit (4 cols) ==="
display "N (person-years) = " e(N)
regress r5_annual_w5 `ctrl_s2' finlit_q1 if _p2_sample, vce(cluster hhidpn)
regress r5_annual_w5 `ctrl_s2' finlit_q2 if _p2_sample, vce(cluster hhidpn)
regress r5_annual_w5 `ctrl_s2' finlit_q3 if _p2_sample, vce(cluster hhidpn)
regress r5_annual_w5 `ctrl_s2' finlit_score if _p2_sample, vce(cluster hhidpn)
drop _p1_sample _p2_sample

local ctrl_fe "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_fe "`ctrl_fe' wealth_d`d'"
}
local ctrl_fe "`ctrl_fe' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

xtreg r5_annual_w5 `ctrl_fe' if !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other) & !missing(finlit_score), fe vce(cluster hhidpn)
predict _fe_r5 if e(sample)
bysort hhidpn: egen fe_r5 = mean(_fe_r5)
drop _fe_r5
collapse (first) fe_r5 educ_yrs gender race_eth born_us finlit_q1 finlit_q2 finlit_q3 finlit_score, by(hhidpn)

gen byte _fe_sample = !missing(fe_r5) & !missing(finlit_score)
quietly regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score if _fe_sample, vce(robust)
display _n "=== Panel Spec 3: FE + 2nd stage on tinv + finlit (4 cols) ==="
display "N (persons) = " e(N)
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q1 if _fe_sample, vce(robust)
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q2 if _fe_sample, vce(robust)
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q3 if _fe_sample, vce(robust)
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score if _fe_sample, vce(robust)

* ==========================================================================
* PART 2: All three finlit vars (q1+q2+q3) on RHS, one reg per block
* ==========================================================================
display _n "########################################################################"
display "PART 2: finlit_q1 + finlit_q2 + finlit_q3 on RHS (one reg per block)"
display "########################################################################"

* Reload wide for cross section and average
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

local ctrl_r5 "i.age_bin i.gender educ_yrs inlbrf_2020 married_2020 born_us i.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}

gen byte _cs_sample = !missing(r5_annual_w5_2022) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3)
display _n "=== Cross section: r5 on controls + finlit_q1 finlit_q2 finlit_q3 ==="
regress r5_annual_w5_2022 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 if _cs_sample, vce(robust)
display "N = " e(N)
drop _cs_sample

gen byte _avg_sample = !missing(r5_annual_avg_w5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3)
display _n "=== Average r5 on controls + finlit_q1 finlit_q2 finlit_q3 ==="
regress r5_annual_avg_w5 `ctrl_r5' finlit_q1 finlit_q2 finlit_q3 if _avg_sample, vce(robust)
display "N = " e(N)
drop _avg_sample

preserve
keep hhidpn finlit_q1 finlit_q2 finlit_q3 finlit_score
duplicates drop hhidpn, force
tempfile finlit_wide2
save `finlit_wide2'
restore

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
merge m:1 hhidpn using `finlit_wide2', nogen
xtset hhidpn year

local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local base_ctrl "`base_ctrl' wealth_d`d'"
}

gen byte _p1_sample = !missing(r5_annual_w5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3)
display _n "=== Panel Spec 1: r5 on controls + finlit_q1 finlit_q2 finlit_q3 ==="
regress r5_annual_w5 `base_ctrl' finlit_q1 finlit_q2 finlit_q3 if _p1_sample, vce(cluster hhidpn)
display "N (person-years) = " e(N)

local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
gen byte _p2_sample = _p1_sample & !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)
display _n "=== Panel Spec 2: r5 on controls + finlit_q1 finlit_q2 finlit_q3 ==="
regress r5_annual_w5 `ctrl_s2' finlit_q1 finlit_q2 finlit_q3 if _p2_sample, vce(cluster hhidpn)
display "N (person-years) = " e(N)
drop _p1_sample _p2_sample

local ctrl_fe "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_fe "`ctrl_fe' wealth_d`d'"
}
local ctrl_fe "`ctrl_fe' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

xtreg r5_annual_w5 `ctrl_fe' if !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3), fe vce(cluster hhidpn)
predict _fe_r5 if e(sample)
bysort hhidpn: egen fe_r5 = mean(_fe_r5)
drop _fe_r5
collapse (first) fe_r5 educ_yrs gender race_eth born_us finlit_q1 finlit_q2 finlit_q3 finlit_score, by(hhidpn)

gen byte _fe_sample = !missing(fe_r5) & !missing(finlit_q1) & !missing(finlit_q2) & !missing(finlit_q3)
display _n "=== Panel Spec 3: 2nd stage FE on tinv + finlit_q1 finlit_q2 finlit_q3 ==="
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q1 finlit_q2 finlit_q3 if _fe_sample, vce(robust)
display "N (persons) = " e(N)

* ==========================================================================
* PART 3: finlit_q2 and finlit_score, with and without trust + trust^2
* ==========================================================================
display _n "########################################################################"
display "PART 3: finlit_q2 and finlit_score, with/without trust + trust^2 + joint test"
display "########################################################################"

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

display _n "========== CROSS SECTION =========="
gen byte _cs = !missing(r5_annual_w5_2022) & !missing(finlit_q2) & !missing(trust_others_2020)
display _n "--- finlit_q2: without trust ---"
regress r5_annual_w5_2022 `ctrl_r5' finlit_q2 if _cs, vce(robust)
display _n "--- finlit_q2: with trust + trust^2 ---"
regress r5_annual_w5_2022 `ctrl_r5' finlit_q2 `trust_spec' if _cs, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

replace _cs = !missing(r5_annual_w5_2022) & !missing(finlit_score) & !missing(trust_others_2020)
display _n "--- finlit_score: without trust ---"
regress r5_annual_w5_2022 `ctrl_r5' finlit_score if _cs, vce(robust)
display _n "--- finlit_score: with trust + trust^2 ---"
regress r5_annual_w5_2022 `ctrl_r5' finlit_score `trust_spec' if _cs, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
drop _cs

display _n "========== AVERAGE =========="
gen byte _avg = !missing(r5_annual_avg_w5) & !missing(finlit_q2) & !missing(trust_others_2020)
display _n "--- finlit_q2: without trust ---"
regress r5_annual_avg_w5 `ctrl_r5' finlit_q2 if _avg, vce(robust)
display _n "--- finlit_q2: with trust + trust^2 ---"
regress r5_annual_avg_w5 `ctrl_r5' finlit_q2 `trust_spec' if _avg, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

replace _avg = !missing(r5_annual_avg_w5) & !missing(finlit_score) & !missing(trust_others_2020)
display _n "--- finlit_score: without trust ---"
regress r5_annual_avg_w5 `ctrl_r5' finlit_score if _avg, vce(robust)
display _n "--- finlit_score: with trust + trust^2 ---"
regress r5_annual_avg_w5 `ctrl_r5' finlit_score `trust_spec' if _avg, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
drop _avg

preserve
keep hhidpn finlit_q1 finlit_q2 finlit_q3 finlit_score
duplicates drop hhidpn, force
tempfile finlit_wide3
save `finlit_wide3'
restore

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
merge m:1 hhidpn using `finlit_wide3', nogen
xtset hhidpn year

local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local base_ctrl "`base_ctrl' wealth_d`d'"
}
local trust_spec_p "c.trust_others_2020 c.trust_others_2020#c.trust_others_2020"

display _n "========== PANEL SPEC 1 =========="
gen byte _p1 = !missing(r5_annual_w5) & !missing(finlit_q2) & !missing(trust_others_2020)
display _n "--- finlit_q2: without trust ---"
regress r5_annual_w5 `base_ctrl' finlit_q2 if _p1, vce(cluster hhidpn)
display _n "--- finlit_q2: with trust + trust^2 ---"
regress r5_annual_w5 `base_ctrl' finlit_q2 `trust_spec_p' if _p1, vce(cluster hhidpn)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

replace _p1 = !missing(r5_annual_w5) & !missing(finlit_score) & !missing(trust_others_2020)
display _n "--- finlit_score: without trust ---"
regress r5_annual_w5 `base_ctrl' finlit_score if _p1, vce(cluster hhidpn)
display _n "--- finlit_score: with trust + trust^2 ---"
regress r5_annual_w5 `base_ctrl' finlit_score `trust_spec_p' if _p1, vce(cluster hhidpn)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
drop _p1

display _n "========== PANEL SPEC 2 =========="
local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
gen byte _p2 = !missing(r5_annual_w5) & !missing(finlit_q2) & !missing(trust_others_2020) & !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)
display _n "--- finlit_q2: without trust ---"
regress r5_annual_w5 `ctrl_s2' finlit_q2 if _p2, vce(cluster hhidpn)
display _n "--- finlit_q2: with trust + trust^2 ---"
regress r5_annual_w5 `ctrl_s2' finlit_q2 `trust_spec_p' if _p2, vce(cluster hhidpn)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

replace _p2 = !missing(r5_annual_w5) & !missing(finlit_score) & !missing(trust_others_2020) & !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)
display _n "--- finlit_score: without trust ---"
regress r5_annual_w5 `ctrl_s2' finlit_score if _p2, vce(cluster hhidpn)
display _n "--- finlit_score: with trust + trust^2 ---"
regress r5_annual_w5 `ctrl_s2' finlit_score `trust_spec_p' if _p2, vce(cluster hhidpn)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020
drop _p2

display _n "========== PANEL SPEC 3 (FE + 2nd stage) =========="
local ctrl_fe "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_fe "`ctrl_fe' wealth_d`d'"
}
local ctrl_fe "`ctrl_fe' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

gen byte _fe_cond = !missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other) & !missing(finlit_q2) & !missing(trust_others_2020)
xtreg r5_annual_w5 `ctrl_fe' if _fe_cond, fe vce(cluster hhidpn)
predict _fe_r5 if e(sample)
bysort hhidpn: egen fe_r5 = mean(_fe_r5)
drop _fe_r5
collapse (first) fe_r5 educ_yrs gender race_eth born_us finlit_q1 finlit_q2 finlit_q3 finlit_score trust_others_2020, by(hhidpn)

gen byte _fe = !missing(fe_r5) & !missing(finlit_q2) & !missing(trust_others_2020)
display _n "--- finlit_q2: without trust ---"
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q2 if _fe, vce(robust)
display _n "--- finlit_q2: with trust + trust^2 ---"
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_q2 c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if _fe, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

replace _fe = !missing(fe_r5) & !missing(finlit_score) & !missing(trust_others_2020)
display _n "--- finlit_score: without trust ---"
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score if _fe, vce(robust)
display _n "--- finlit_score: with trust + trust^2 ---"
regress fe_r5 educ_yrs i.gender i.race_eth born_us finlit_score c.trust_others_2020 c.trust_others_2020#c.trust_others_2020 if _fe, vce(robust)
display "Joint test: trust + trust^2"
test c.trust_others_2020 c.trust_others_2020#c.trust_others_2020

display _n "########################################################################"
display "Done. Inspect log: ${LOG_DIR}/19_inspect_finlit_r5.log"
display "########################################################################"
log close
