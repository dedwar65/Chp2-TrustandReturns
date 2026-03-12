* 31_2sls_spdep.do
* Same structure as 30, but using spouse depression (s*cesd) instead of own depression (r*cesd).
* RAND HRS: s15cesd=spouse CESD 2020, s14cesd=2018, s13cesd=2016, ... (wave 6=2002).
* RwCESD = sum of depression items (higher = more negative feelings). SwCESD = spouse counterpart.
* Log: Notes/Logs/31_2sls_spdep.log
* Graph: Code/Regressions/2SLS/PredictTrust/depression_spouse_depression_over_time.png
* Table: Code/Regressions/2SLS/PredictTrust/trust_reg_spouse_depression_iv.tex

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
log using "${LOG_DIR}/31_2sls_spdep.log", replace text

* ----------------------------------------------------------------------
* Load analysis sample, merge r*cesd and s*cesd from all_data_merged
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Merge r*cesd and s*cesd (respondent and spouse CESD) from RAND longitudinal
preserve
use "${CLEANED}/all_data_merged.dta", clear
local cesd_vars "hhidpn"
forvalues w = 6/15 {
    capture confirm variable r`w'cesd
    if !_rc local cesd_vars "`cesd_vars' r`w'cesd"
    capture confirm variable s`w'cesd
    if !_rc local cesd_vars "`cesd_vars' s`w'cesd"
}
keep `cesd_vars'
tempfile cesd
save "`cesd'", replace
restore

merge 1:1 hhidpn using "`cesd'", nogen

* Spouse depression: contemporaneous and lagged (s15=2020, s14=2018, s13=2016)
capture confirm variable s15cesd
if !_rc {
    capture drop spouse_depression_2020
    gen spouse_depression_2020 = s15cesd
}
capture confirm variable s14cesd
if !_rc {
    capture drop spouse_depression_2018
    gen spouse_depression_2018 = s14cesd
}
capture confirm variable s13cesd
if !_rc {
    capture drop spouse_depression_2016
    gen spouse_depression_2016 = s13cesd
}

* Ever spouse depressed (waves 6-15): 1 if spouse CESD > 0 in any wave
gen byte ever_spouse_depressed = 0
forvalues w = 6/15 {
    capture confirm variable s`w'cesd
    if !_rc replace ever_spouse_depressed = 1 if s`w'cesd > 0 & !missing(s`w'cesd)
}
local _scesd ""
forvalues w = 6/15 {
    capture confirm variable s`w'cesd
    if !_rc local _scesd "`_scesd' s`w'cesd"
}
if "`_scesd'" != "" {
    egen _n_scesd = rownonmiss(`_scesd')
    replace ever_spouse_depressed = . if _n_scesd == 0
    drop _n_scesd
}

* Age bins
capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

* Controls (match 22 Addl Spec 7b / 29 baseline)
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

local ctrl "`demo_core' `demo_race'"
capture confirm variable wealth_d2_2020
if !_rc {
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local ctrl "`ctrl' wealth_d`d'_2020"
    }
}
capture confirm variable inlbrf_2020
if !_rc local ctrl "`ctrl' inlbrf_2020"
capture confirm variable population_3bin_2020
if !_rc local ctrl "`ctrl' i.population_3bin_2020"
if "`region_var'" != "" local ctrl "`ctrl' i.`region_var'"
capture confirm variable born_us
if !_rc local ctrl "`ctrl' born_us"

local samp "if !missing(trust_others_2020)"

* ----------------------------------------------------------------------
* 1) Cross-correlation: general trust, own depression, spouse depression
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1) CROSS-CORRELATION: General trust, own depression, spouse depression"
display "########################################################################"
local corr_vars "trust_others_2020 depression_2020"
capture confirm variable spouse_depression_2020
if !_rc local corr_vars "`corr_vars' spouse_depression_2020"
display _n "--- pwcorr (sig, obs) ---"
pwcorr `corr_vars' `samp', sig obs
display _n "--- correlate ---"
correlate `corr_vars' `samp'

* ----------------------------------------------------------------------
* 2) Graph: Average depression and spouse depression over time (2002-2020)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2) GRAPH: Average depression and spouse depression by wave"
display "########################################################################"
preserve
* Postfile: compute mean depression and spouse depression by wave
tempfile graphdata
tempname memhold
postfile `memhold' wave year mean_dep mean_spdep using `graphdata', replace
forvalues w = 6/15 {
    quietly summarize r`w'cesd
    local md = r(mean)
    capture quietly summarize s`w'cesd
    local ms = cond(_rc==0, r(mean), .)
    local y = 1990 + 2 * `w'
    post `memhold' (`w') (`y') (`md') (`ms')
}
postclose `memhold'

use `graphdata', clear
twoway (line mean_dep year, lcolor(blue)) (line mean_spdep year, lcolor(red)), ///
    xlabel(2002(4)2020) xtitle("Year") ytitle("Mean CESD score") ///
    legend(order(1 "Respondent depression" 2 "Spouse depression") ring(0) pos(5)) ///
    title("Average depression and spouse depression over time")
capture mkdir "${REGRESSIONS}/2SLS/PredictTrust"
graph export "${REGRESSIONS}/2SLS/PredictTrust/depression_spouse_depression_over_time.png", replace
restore

* ----------------------------------------------------------------------
* 3) Regressions: Trust on spouse depression (mirror 30 steps 1-6b)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "3) REGRESSIONS: Trust on spouse depression"
display "########################################################################"

* 1: Trust on contemporaneous spouse depression (no controls)
display _n "--- 1: Trust on contemporaneous spouse depression (no controls) ---"
capture confirm variable spouse_depression_2020
if !_rc {
    reg trust_others_2020 spouse_depression_2020 `samp', vce(robust)
}
else display "spouse_depression_2020 not found. Skipped."

* 2: Trust on contemporaneous spouse depression + controls
display _n "--- 2: Trust on contemporaneous spouse depression + controls ---"
capture confirm variable spouse_depression_2020
if !_rc {
    eststo step2: reg trust_others_2020 spouse_depression_2020 `ctrl' `samp', vce(robust)
}
else display "spouse_depression_2020 not found. Skipped."

* 3: Trust on lagged spouse depression (2018) only
display _n "--- 3: Trust on lagged spouse depression (2018) only ---"
capture confirm variable spouse_depression_2018
if !_rc {
    reg trust_others_2020 spouse_depression_2018 `samp', vce(robust)
}
else display "spouse_depression_2018 not found. Skipped."

* 4: Trust on lagged spouse depression (2018) + controls
display _n "--- 4: Trust on lagged spouse depression (2018) + controls ---"
capture confirm variable spouse_depression_2018
if !_rc {
    eststo step4: reg trust_others_2020 spouse_depression_2018 `ctrl' `samp', vce(robust)
}
else display "spouse_depression_2018 not found. Skipped."

* 5: Trust on multiple lags (2016, 2018) of spouse depression + controls
display _n "--- 5: Trust on multiple lags (2016, 2018) spouse depression + controls ---"
capture confirm variable spouse_depression_2016
local has_s2016 = (_rc == 0)
capture confirm variable spouse_depression_2018
local has_s2018 = (_rc == 0)
if `has_s2016' & `has_s2018' {
    eststo step5: reg trust_others_2020 spouse_depression_2016 spouse_depression_2018 `ctrl' `samp', vce(robust)
}
else display "spouse_depression_2016 or spouse_depression_2018 not found. Skipped."

* 6a: Trust on ever spouse depressed (no controls)
display _n "--- 6a: Trust on ever spouse depressed (no controls) ---"
reg trust_others_2020 ever_spouse_depressed `samp', vce(robust)

* 6b: Trust on ever spouse depressed + controls
display _n "--- 6b: Trust on ever spouse depressed + controls ---"
eststo step6b: reg trust_others_2020 ever_spouse_depressed `ctrl' `samp', vce(robust)

* ----------------------------------------------------------------------
* Table export: steps 2, 4, 5, 6b
* ----------------------------------------------------------------------
local estlist ""
local mtlist ""
capture confirm variable spouse_depression_2020
if !_rc {
    local estlist "step2"
    local mtlist `""No lag""'
}
capture confirm variable spouse_depression_2018
if !_rc local estlist "`estlist' step4"
if !_rc local mtlist `"`mtlist' "One lag""'
capture confirm variable spouse_depression_2016
if !_rc {
    capture confirm variable spouse_depression_2018
    if !_rc local estlist "`estlist' step5"
    if !_rc local mtlist `"`mtlist' "Two lags""'
}
local estlist "`estlist' step6b"
local mtlist `"`mtlist' "Ever depressed""'
local outfile "${REGRESSIONS}/2SLS/PredictTrust/trust_reg_spouse_depression_iv.tex"
if trim("`estlist'") != "" {
    esttab `estlist' using "`outfile'", replace ///
    booktabs no gap ///
    mtitles(`mtlist') ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    b(2) se(2) label ///
    order(spouse_depression_2020 spouse_depression_2018 spouse_depression_2016 ever_spouse_depressed _cons) ///
    varlabels(spouse_depression_2020 "Spouse depression (2020)" spouse_depression_2018 "Spouse depression (2018)" spouse_depression_2016 "Spouse depression (2016)" ever_spouse_depressed "Ever spouse depressed" _cons "Constant") ///
    alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
    nonumbers nonotes
    display "Table saved: `outfile'"
}
else display "No spouse depression models to export. Table skipped."

log close