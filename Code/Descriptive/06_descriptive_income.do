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
    labor_income_real_win_* total_income_real_win_* ///
    wealth_m1_* wealth_m2_* wealth_total_* gross_wealth_*

* Reshape to long for income descriptives
reshape long ln_lab_inc_final_ ln_tot_inc_final_ labor_income_real_win_ total_income_real_win_ ///
    age_ wealth_m1_ wealth_m2_ wealth_total_ gross_wealth_, i(hhidpn) j(year)
rename age_ age
rename wealth_m1_ wealth_m1
rename wealth_m2_ wealth_m2
rename wealth_total_ wealth_total
rename gross_wealth_ gross_wealth

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

* Mean income by year (deflated + winsorized levels)
display "=== Mean income by year ==="
tabstat labor_income_real_win_ total_income_real_win_, by(year) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_, by(year)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_year_real_win.csv", replace
restore

* Income by age group (year-specific; deflated + winsorized levels)
display "=== Mean income by age group (2002) ==="
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat labor_income_real_win_ total_income_real_win_ if year == 2002, by(age_group) statistics(n mean sd p50 p95)
preserve
keep if year == 2002
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_, by(age_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_agegroup_real_win_2002.csv", replace
restore

display "=== Mean income by age group (2022) ==="
tabstat labor_income_real_win_ total_income_real_win_ if year == 2022, by(age_group) statistics(n mean sd p50 p95)
preserve
keep if year == 2022
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_, by(age_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_agegroup_real_win_2022.csv", replace
restore

* Income by education group (deflated + winsorized levels)
display "=== Mean income by education group ==="
gen byte educ_group = .
replace educ_group = 1 if educ_yrs < 12
replace educ_group = 2 if educ_yrs == 12
replace educ_group = 3 if inrange(educ_yrs,13,15)
replace educ_group = 4 if educ_yrs == 16
replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
label define educ_group 1 "lt12" 2 "hs" 3 "some_college" 4 "college" 5 "grad"
label values educ_group educ_group
tabstat labor_income_real_win_ total_income_real_win_, by(educ_group) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_, by(educ_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/income_mean_by_educgroup_real_win.csv", replace
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

* Scatterplots: income vs wealth percentiles (2002 and 2022)
capture mkdir "${BASE_PATH}/Descriptive"
capture mkdir "${BASE_PATH}/Descriptive/Figures"
capture mkdir "${BASE_PATH}/Descriptive/Tables"

* Wealth percentiles by year (1-100)
egen wealth_m1_pct = xtile(wealth_m1), by(year) nq(100)
egen wealth_m2_pct = xtile(wealth_m2), by(year) nq(100)
egen wealth_total_pct = xtile(wealth_total), by(year) nq(100)
egen gross_wealth_pct = xtile(gross_wealth), by(year) nq(100)

display "=== Scatter: income vs wealth (2002) ==="
foreach incvar in ln_lab_inc_final_ ln_tot_inc_final_ {
    local incname = cond("`incvar'"=="ln_lab_inc_final_", "labor_income", "total_income")

    twoway scatter `incvar' wealth_m1_pct if year == 2002 & !missing(`incvar') & !missing(wealth_m1_pct), ///
        title("Final log `incname' vs wealth_m1 percentile (2002)") ///
        xtitle("Wealth_m1 percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_m1pct_2002.png", replace

    twoway scatter `incvar' wealth_m2_pct if year == 2002 & !missing(`incvar') & !missing(wealth_m2_pct), ///
        title("Final log `incname' vs wealth_m2 percentile (2002)") ///
        xtitle("Wealth_m2 percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_m2pct_2002.png", replace

    twoway scatter `incvar' wealth_total_pct if year == 2002 & !missing(`incvar') & !missing(wealth_total_pct), ///
        title("Final log `incname' vs wealth_total percentile (2002)") ///
        xtitle("Wealth_total percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_totalpct_2002.png", replace

    twoway scatter `incvar' gross_wealth_pct if year == 2002 & !missing(`incvar') & !missing(gross_wealth_pct), ///
        title("Final log `incname' vs gross wealth percentile (2002)") ///
        xtitle("Gross wealth percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_gross_wealth_pct_2002.png", replace
}

display "=== Scatter: income vs wealth (2022) ==="
foreach incvar in ln_lab_inc_final_ ln_tot_inc_final_ {
    local incname = cond("`incvar'"=="ln_lab_inc_final_", "labor_income", "total_income")

    twoway scatter `incvar' wealth_m1_pct if year == 2022 & !missing(`incvar') & !missing(wealth_m1_pct), ///
        title("Final log `incname' vs wealth_m1 percentile (2022)") ///
        xtitle("Wealth_m1 percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_m1pct_2022.png", replace

    twoway scatter `incvar' wealth_m2_pct if year == 2022 & !missing(`incvar') & !missing(wealth_m2_pct), ///
        title("Final log `incname' vs wealth_m2 percentile (2022)") ///
        xtitle("Wealth_m2 percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_m2pct_2022.png", replace

    twoway scatter `incvar' wealth_total_pct if year == 2022 & !missing(`incvar') & !missing(wealth_total_pct), ///
        title("Final log `incname' vs wealth_total percentile (2022)") ///
        xtitle("Wealth_total percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_wealth_totalpct_2022.png", replace

    twoway scatter `incvar' gross_wealth_pct if year == 2022 & !missing(`incvar') & !missing(gross_wealth_pct), ///
        title("Final log `incname' vs gross wealth percentile (2022)") ///
        xtitle("Gross wealth percentile") ytitle("Log `incname' (final)")
    graph export "${BASE_PATH}/Descriptive/Figures/`incname'_vs_gross_wealth_pct_2022.png", replace
}

log close
