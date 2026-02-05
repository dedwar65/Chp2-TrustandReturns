* 06_descriptive_income.do
* Descriptive statistics for income and returns (income focus).
* Input: ${PROCESSED}/analysis_ready_processed.dta
* Output: log + figures/tables in Descriptive/Figures and Descriptive/Tables

clear
set more off

* Ensure paths
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
log using "${LOG_DIR}/06_descriptive_income.log", replace text

* Load processed data
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Keep needed vars
keep hhidpn educ_yrs age_* ///
    ln_lab_inc_final_* ln_tot_inc_final_* ///
    wealth_m1_* wealth_m2_* wealth_total_*

* Reshape to long for income descriptives
reshape long ln_lab_inc_final_ ln_tot_inc_final_ age_ wealth_m1_ wealth_m2_ wealth_total_, i(hhidpn) j(year)
rename age_ age
rename wealth_m1_ wealth_m1
rename wealth_m2_ wealth_m2
rename wealth_total_ wealth_total

display "=== Income descriptives (final log series) ==="
tabstat ln_lab_inc_final_ ln_tot_inc_final_, statistics(n mean sd p1 p5 p50 p95 p99 min max)

* Export tabstat-like summary for final income variables
preserve
clear
tempfile income_stats
postfile handle str32 varname double N mean sd p1 p5 p50 p95 p99 min max using "`income_stats'", replace
foreach v in ln_lab_inc_final_ ln_tot_inc_final_ {
    quietly summarize `v', detail
    post handle ("`v'") (r(N)) (r(mean)) (r(sd)) (r(p1)) (r(p5)) (r(p50)) (r(p95)) (r(p99)) (r(min)) (r(max))
}
postclose handle
use "`income_stats'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/income_final_tabstat.csv", replace
restore

* Mean income by year
display "=== Mean income by year ==="
tabstat ln_lab_inc_final_ ln_tot_inc_final_, by(year) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_ln_lab=ln_lab_inc_final_ mean_ln_tot=ln_tot_inc_final_ (count) n=ln_lab_inc_final_, by(year)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_year.csv", replace
restore

* Income by age group
display "=== Mean income by age group ==="
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat ln_lab_inc_final_ ln_tot_inc_final_, by(age_group) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_ln_lab=ln_lab_inc_final_ mean_ln_tot=ln_tot_inc_final_ (count) n=ln_lab_inc_final_, by(age_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_agegroup.csv", replace
restore

* Income by education group
display "=== Mean income by education group ==="
gen byte educ_group = .
replace educ_group = 1 if educ_yrs < 12
replace educ_group = 2 if educ_yrs == 12
replace educ_group = 3 if inrange(educ_yrs,13,15)
replace educ_group = 4 if educ_yrs == 16
replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
label define educ_group 1 "lt12" 2 "hs" 3 "some_college" 4 "college" 5 "grad"
label values educ_group educ_group
tabstat ln_lab_inc_final_ ln_tot_inc_final_, by(educ_group) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_ln_lab=ln_lab_inc_final_ mean_ln_tot=ln_tot_inc_final_ (count) n=ln_lab_inc_final_, by(educ_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_educgroup.csv", replace
restore

* Income growth summary (all years together)
display "=== Income growth summary (all years) ==="
preserve
keep ln_lab_inc_final_growth_* ln_tot_inc_final_growth_*

* Export tabstat-like summary for income growth variables
clear
tempfile growth_stats
postfile handle str32 varname double N mean sd p1 p5 p50 p95 p99 min max using "`growth_stats'", replace
foreach v of varlist ln_lab_inc_final_growth_* ln_tot_inc_final_growth_* {
    quietly summarize `v', detail
    post handle ("`v'") (r(N)) (r(mean)) (r(sd)) (r(p1)) (r(p5)) (r(p50)) (r(p95)) (r(p99)) (r(min)) (r(max))
}
postclose handle
use "`growth_stats'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/income_growth_tabstat.csv", replace
restore

* Scatterplots: income vs wealth measures (2002 and 2022)
capture mkdir "${BASE_PATH}/Descriptive"
capture mkdir "${BASE_PATH}/Descriptive/Figures"
capture mkdir "${BASE_PATH}/Descriptive/Tables"

display "=== Scatter: income vs wealth (2002) ==="
twoway scatter ln_tot_inc_final_ wealth_m1 if year == 2002 & !missing(ln_tot_inc_final_) & !missing(wealth_m1), ///
    title("Final log total income vs wealth_m1 (2002)") ///
    xtitle("Wealth_m1 (core assets)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_m1_2002.png", replace

twoway scatter ln_tot_inc_final_ wealth_m2 if year == 2002 & !missing(ln_tot_inc_final_) & !missing(wealth_m2), ///
    title("Final log total income vs wealth_m2 (2002)") ///
    xtitle("Wealth_m2 (core + IRA)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_m2_2002.png", replace

twoway scatter ln_tot_inc_final_ wealth_total if year == 2002 & !missing(ln_tot_inc_final_) & !missing(wealth_total), ///
    title("Final log total income vs wealth_total (2002)") ///
    xtitle("Wealth_total (core + IRA + housing)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_total_2002.png", replace

display "=== Scatter: income vs wealth (2022) ==="
twoway scatter ln_tot_inc_final_ wealth_m1 if year == 2022 & !missing(ln_tot_inc_final_) & !missing(wealth_m1), ///
    title("Final log total income vs wealth_m1 (2022)") ///
    xtitle("Wealth_m1 (core assets)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_m1_2022.png", replace

twoway scatter ln_tot_inc_final_ wealth_m2 if year == 2022 & !missing(ln_tot_inc_final_) & !missing(wealth_m2), ///
    title("Final log total income vs wealth_m2 (2022)") ///
    xtitle("Wealth_m2 (core + IRA)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_m2_2022.png", replace

twoway scatter ln_tot_inc_final_ wealth_total if year == 2022 & !missing(ln_tot_inc_final_) & !missing(wealth_total), ///
    title("Final log total income vs wealth_total (2022)") ///
    xtitle("Wealth_total (core + IRA + housing)") ytitle("Log total income (final)")
graph export "${BASE_PATH}/Descriptive/Figures/income_vs_wealth_total_2022.png", replace

log close
