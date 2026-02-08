* 06_descriptive_income.do
* Descriptive statistics for income.
* Input: ${PROCESSED}/analysis_ready_processed.dta
* Output: log + figures/tables in Code/Descriptive/Figures and Code/Descriptive/Tables

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

* Ensure output dirs (needed before exports)
capture mkdir "${DESCRIPTIVE}"
capture mkdir "${DESCRIPTIVE}/Figures"
capture mkdir "${DESCRIPTIVE}/Tables"

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Keep needed vars
keep hhidpn educ_yrs age_* ///
    ln_lab_inc_final_* ln_tot_inc_final_* ///
    labor_income_real_win_* total_income_real_win_* ///
    wealth_core_* wealth_ira_* wealth_coreira_* wealth_res_* wealth_total_* gross_wealth_*

* Reshape to long for income descriptives
reshape long ln_lab_inc_final_ ln_tot_inc_final_ labor_income_real_win_ total_income_real_win_ ///
    age_ wealth_core_ wealth_ira_ wealth_coreira_ wealth_res_ wealth_total_ gross_wealth_, i(hhidpn) j(year)
rename age_ age
rename wealth_core_ wealth_core
rename wealth_ira_ wealth_ira
rename wealth_coreira_ wealth_coreira
rename wealth_res_ wealth_res
rename wealth_total_ wealth_total
rename gross_wealth_ gross_wealth

display "=== Income descriptives (final log series) ==="
tabstat ln_lab_inc_final_ ln_tot_inc_final_ `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* Export tabstat-like summary for final income variables (LaTeX)
preserve
tempfile income_stats
postfile handle str32 varname double obs mean sd p1 p5 p50 p95 p99 min max using "`income_stats'", replace

foreach v in ln_lab_inc_final_ ln_tot_inc_final_ {
    if "`wopt'" != "" {
        quietly summarize `v' `wopt'
        local N = r(N)
        local mean = r(mean)
        local sd = r(sd)
        local min = r(min)
        local max = r(max)
        quietly centile `v' `wopt', centile(1 5 50 95 99)
        local p1 = r(c_1)
        local p5 = r(c_2)
        local p50 = r(c_3)
        local p95 = r(c_4)
        local p99 = r(c_5)
        post handle ("`v'") (`N') (`mean') (`sd') (`p1') (`p5') (`p50') (`p95') (`p99') (`min') (`max')
    }
    else {
        quietly summarize `v', detail
        post handle ("`v'") (r(N)) (r(mean)) (r(sd)) (r(p1)) (r(p5)) (r(p50)) (r(p95)) (r(p99)) (r(min)) (r(max))
    }
}
postclose handle

use "`income_stats'", clear

file open fh using "${DESCRIPTIVE}/Tables/income_final_tabstat.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n ///
    "\caption{Income final series: summary statistics}" _n ///
    "\label{tab:income_final_tabstat}" _n ///
    "\begin{tabular}{lrrrrrrrrrrr}\toprule" _n ///
    "Variable & Obs & Mean & SD & P1 & P5 & P50 & P95 & P99 & Min & Max \\\\ \midrule" _n

forvalues r = 1/`=_N' {
    local vname = varname[`r']
    if "`vname'" == "ln_lab_inc_final_" local vname "Log labor income"
    if "`vname'" == "ln_tot_inc_final_" local vname "Log total income"
    local obs_s = string(obs[`r'], "%9.0fc")
    local mean_s = string(mean[`r'], "%9.4f")
    local sd_s = string(sd[`r'], "%9.4f")
    local p1_s = string(p1[`r'], "%9.4f")
    local p5_s = string(p5[`r'], "%9.4f")
    local p50_s = string(p50[`r'], "%9.4f")
    local p95_s = string(p95[`r'], "%9.4f")
    local p99_s = string(p99[`r'], "%9.4f")
    local min_s = string(min[`r'], "%9.4f")
    local max_s = string(max[`r'], "%9.4f")

    file write fh "`vname' & `obs_s' & `mean_s' & `sd_s' & `p1_s' & `p5_s' & `p50_s' & `p95_s' & `p99_s' & `min_s' & `max_s' \\\\" _n
}

file write fh "\bottomrule" _n "\multicolumn{12}{l}{\footnotesize Log income series; summary over person-years.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

* Mean income by year (deflated + winsorized levels)
display "=== Mean income by year ==="
tabstat labor_income_real_win_ total_income_real_win_ `wopt', by(year) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_ `wopt', by(year)
local dl = char(92) + char(36)
file open fh using "${DESCRIPTIVE}/Tables/income_mean_by_year_real_win.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean income by year (real, winsorized)}" _n "\label{tab:income_mean_by_year_real_win}" _n "\begin{tabular}{lrrr}\toprule" _n "Year & Labor income (mean `dl') & Total income (mean `dl') & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local lab_s = string(mean_lab[`r'], "%9.0fc")
    local tot_s = string(mean_tot[`r'], "%9.0fc")
    local n_s = string(n[`r'], "%9.0fc")
    file write fh "`yr_s' & `lab_s' & `tot_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Real USD; winsorized at 1st and 99th percentile.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

* Income by age group (year-specific; deflated + winsorized levels)
display "=== Mean income by age group (2002) ==="
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat labor_income_real_win_ total_income_real_win_ `wopt' if year == 2002, by(age_group) statistics(n mean sd p50 p95)
preserve
keep if year == 2002
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_ `wopt', by(age_group)
local dl = char(92) + char(36)
file open fh using "${DESCRIPTIVE}/Tables/income_mean_by_agegroup_real_win_2002.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean income by age group (2002)}" _n "\label{tab:income_mean_by_agegroup_2002}" _n "\begin{tabular}{lrrr}\toprule" _n "Age (midpoint) & Labor income (mean `dl') & Total income (mean `dl') & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local age_s = string(age_group[`r'], "%9.0f")
    local lab_s = string(mean_lab[`r'], "%9.0fc")
    local tot_s = string(mean_tot[`r'], "%9.0fc")
    local n_s = string(n[`r'], "%9.0fc")
    file write fh "`age_s' & `lab_s' & `tot_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Five-year age bins (e.g., 50 = 50--54). Real USD, winsorized.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

display "=== Mean income by age group (2022) ==="
tabstat labor_income_real_win_ total_income_real_win_ `wopt' if year == 2022, by(age_group) statistics(n mean sd p50 p95)
preserve
keep if year == 2022
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_ `wopt', by(age_group)
local dl = char(92) + char(36)
file open fh using "${DESCRIPTIVE}/Tables/income_mean_by_agegroup_real_win_2022.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean income by age group (2022)}" _n "\label{tab:income_mean_by_agegroup_2022}" _n "\begin{tabular}{lrrr}\toprule" _n "Age (midpoint) & Labor income (mean `dl') & Total income (mean `dl') & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local age_s = string(age_group[`r'], "%9.0f")
    local lab_s = string(mean_lab[`r'], "%9.0fc")
    local tot_s = string(mean_tot[`r'], "%9.0fc")
    local n_s = string(n[`r'], "%9.0fc")
    file write fh "`age_s' & `lab_s' & `tot_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Five-year age bins (e.g., 50 = 50--54). Real USD, winsorized.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

* Income by education group (deflated + winsorized levels)
display "=== Mean income by education group ==="
gen byte educ_group = .
replace educ_group = 1 if educ_yrs < 12
replace educ_group = 2 if educ_yrs == 12
replace educ_group = 3 if inrange(educ_yrs,13,15)
replace educ_group = 4 if educ_yrs == 16
replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
label define educ_group 1 "no hs" 2 "hs" 3 "some college" 4 "4yr degree" 5 "grad"
label values educ_group educ_group
tabstat labor_income_real_win_ total_income_real_win_ `wopt', by(educ_group) statistics(n mean sd p50 p95)
preserve
collapse (mean) mean_lab=labor_income_real_win_ mean_tot=total_income_real_win_ (count) n=labor_income_real_win_ `wopt', by(educ_group)
decode educ_group, gen(educ_label)
local dl = char(92) + char(36)
file open fh using "${DESCRIPTIVE}/Tables/income_mean_by_educgroup_real_win.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean income by education group (real, winsorized)}" _n "\label{tab:income_mean_by_educgroup_real_win}" _n "\begin{tabular}{lrrr}\toprule" _n "Education & Labor income (mean `dl') & Total income (mean `dl') & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local edlab = educ_label[`r']
    local lab_s = string(mean_lab[`r'], "%9.0fc")
    local tot_s = string(mean_tot[`r'], "%9.0fc")
    local n_s = string(n[`r'], "%9.0fc")
    file write fh "`edlab' & `lab_s' & `tot_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Real USD, winsorized. no hs = $<$12y; hs = 12y; some college = 13--15y; 4yr = 16y; grad = 17+y.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* Figure 1A, 2A, 3: Income by age, income by age and education, income over time
* ---------------------------------------------------------------------

* Figure 1A — Mean labor and total income by age group (2 lines per graph, 2002 and 2022)
foreach yr in 2002 2022 {
    preserve
    keep if year == `yr'
    collapse (mean) mean_lab=labor_income_real_win_ (mean) mean_tot=total_income_real_win_ `wopt', by(age_group)
    sort age_group
    twoway (line mean_lab age_group, lwidth(medthick) lcolor(navy)) (line mean_tot age_group, lpattern(dash) lcolor(maroon)), ///
        xtitle("Age group") ytitle("Income (winsorized)") ylabel(, format(%9.0fc)) ///
        title("Income by age group (`yr')") ///
        legend(order(1 "Labor income" 2 "Total income") cols(1) size(small) position(3) ring(0) region(lstyle(none)))
    graph export "${DESCRIPTIVE}/Figures/income_by_agegroup_`yr'.png", replace
    restore
}

* Figure 2A — Income by age group with lines by education (labor and total separately, 2002 and 2022)
foreach yr in 2002 2022 {
    * Labor income by age and education (5 lines = 5 educ groups)
    preserve
    keep if year == `yr'
    collapse (mean) mean_inc=labor_income_real_win_ `wopt', by(age_group educ_group)
    sort age_group educ_group
    twoway (line mean_inc age_group if educ_group==1, lcolor(navy)) ///
           (line mean_inc age_group if educ_group==2, lcolor(maroon)) ///
           (line mean_inc age_group if educ_group==3, lcolor(forest_green)) ///
           (line mean_inc age_group if educ_group==4, lcolor(orange)) ///
           (line mean_inc age_group if educ_group==5, lcolor(teal)), ///
        xtitle("Age group") ytitle("Income (winsorized)") ylabel(, format(%9.0fc)) ///
        title("Labor income by age and education (`yr')") ///
        legend(order(1 "no hs" 2 "hs" 3 "some college" 4 "4yr degree" 5 "grad") cols(1) size(small) position(3) ring(0) region(lstyle(none)))
    graph export "${DESCRIPTIVE}/Figures/labinc_by_age_educ_`yr'.png", replace
    restore
    * Total income by age and education (5 lines = 5 educ groups)
    preserve
    keep if year == `yr'
    collapse (mean) mean_inc=total_income_real_win_ `wopt', by(age_group educ_group)
    sort age_group educ_group
    twoway (line mean_inc age_group if educ_group==1, lcolor(navy)) ///
           (line mean_inc age_group if educ_group==2, lcolor(maroon)) ///
           (line mean_inc age_group if educ_group==3, lcolor(forest_green)) ///
           (line mean_inc age_group if educ_group==4, lcolor(orange)) ///
           (line mean_inc age_group if educ_group==5, lcolor(teal)), ///
        xtitle("Age group") ytitle("Income (winsorized)") ylabel(, format(%9.0fc)) ///
        title("Total income by age and education (`yr')") ///
        legend(order(1 "no hs" 2 "hs" 3 "some college" 4 "4yr degree" 5 "grad") cols(1) size(small) position(3) ring(0) region(lstyle(none)))
    graph export "${DESCRIPTIVE}/Figures/totinc_by_age_educ_`yr'.png", replace
    restore
}

* Figure 3 — Mean labor and total income over time (one graph, 2 lines)
preserve
collapse (mean) mean_lab=labor_income_real_win_ (mean) mean_tot=total_income_real_win_ `wopt', by(year)
twoway (line mean_lab year, lwidth(medthick) lcolor(navy)) (line mean_tot year, lpattern(dash) lcolor(maroon)), ///
    xtitle("Year") ytitle("Income (winsorized)") ylabel(, format(%9.0fc)) ///
    title("Income over time") ///
    legend(order(1 "Labor income" 2 "Total income") cols(1) size(small) position(3) ring(0) region(lstyle(none)))
graph export "${DESCRIPTIVE}/Figures/income_over_time.png", replace
restore

* Income growth summary (all years together)
display "=== Income growth summary (all years) ==="
preserve
keep ln_lab_inc_final_growth_* ln_tot_inc_final_growth_*

* Export tabstat-like summary for income growth variables
tempfile growth_stats
postfile handle str32 varname double obs mean sd p1 p5 p50 p95 p99 min max using "`growth_stats'", replace
foreach v of varlist ln_lab_inc_final_growth_* ln_tot_inc_final_growth_* {
    if "`wopt'" != "" {
        quietly summarize `v' `wopt'
        local N = r(N)
        local mean = r(mean)
        local sd = r(sd)
        local min = r(min)
        local max = r(max)
        quietly centile `v' `wopt', centile(1 5 50 95 99)
        local p1 = r(c_1)
        local p5 = r(c_2)
        local p50 = r(c_3)
        local p95 = r(c_4)
        local p99 = r(c_5)
        post handle ("`v'") (`N') (`mean') (`sd') (`p1') (`p5') (`p50') (`p95') (`p99') (`min') (`max')
    }
    else {
        quietly summarize `v', detail
        post handle ("`v'") (r(N)) (r(mean)) (r(sd)) (r(p1)) (r(p5)) (r(p50)) (r(p95)) (r(p99)) (r(min)) (r(max))
    }
}
postclose handle
use "`growth_stats'", clear
file open fh using "${DESCRIPTIVE}/Tables/income_growth_tabstat.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Income growth: summary statistics}" _n "\label{tab:income_growth_tabstat}" _n "\begin{tabular}{lrrrrrrrrrrr}\toprule" _n "Variable & Obs & Mean & SD & P1 & P5 & P50 & P95 & P99 & Min & Max \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local vname = varname[`r']
    if strpos("`vname'", "ln_lab_inc_final_growth") > 0 local vname "Log labor income growth"
    if strpos("`vname'", "ln_tot_inc_final_growth") > 0 local vname "Log total income growth"
    local obs_s = string(obs[`r'], "%9.0fc")
    local mean_s = string(mean[`r'], "%9.4f")
    local sd_s = string(sd[`r'], "%9.4f")
    local p1_s = string(p1[`r'], "%9.4f")
    local p5_s = string(p5[`r'], "%9.4f")
    local p50_s = string(p50[`r'], "%9.4f")
    local p95_s = string(p95[`r'], "%9.4f")
    local p99_s = string(p99[`r'], "%9.4f")
    local min_s = string(min[`r'], "%9.4f")
    local max_s = string(max[`r'], "%9.4f")
    file write fh "`vname' & `obs_s' & `mean_s' & `sd_s' & `p1_s' & `p5_s' & `p50_s' & `p95_s' & `p99_s' & `min_s' & `max_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{12}{l}{\footnotesize Log income growth (two-year); summary over person-years.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
restore

* Income vs wealth percentile: mean+IQR ribbon and binscatter (titles/labels aligned with 07 returns)
* Wealth percentiles by year (1-100)
local pctvars "wealth_core wealth_ira wealth_res wealth_total gross_wealth"
foreach v of local pctvars {
    sort year `v'
    by year: gen long _rank_`v' = sum(!missing(`v'))
    by year: gen long _N_`v' = _rank_`v'[_N]
    gen int `v'_pct = .
    replace `v'_pct = ceil(100 * _rank_`v' / _N_`v') if !missing(`v')
    drop _rank_`v' _N_`v'
}

capture which binscatter
if _rc capture ssc install binscatter, replace

display "=== Log income vs wealth percentile: mean+IQR and binscatter ==="
local years "2002 2022"
foreach y of local years {
    quietly count if year == `y' & !missing(wealth_total_pct)
    if r(N) < 10 continue

    * --- Labor income: mean+IQR uses real winsorized (level); binscatter uses log ---
    quietly count if year == `y' & !missing(labor_income_real_win_) & !missing(wealth_total_pct)
    if r(N) >= 10 {
        preserve
        keep if year == `y'
        collapse (mean) mean_inc = labor_income_real_win_ (p25) p25_inc = labor_income_real_win_ (p75) p75_inc = labor_income_real_win_, by(wealth_total_pct)
        twoway (rarea p75_inc p25_inc wealth_total_pct, color(gs12)) (line mean_inc wealth_total_pct, lcolor(navy) lwidth(medthick)), ///
            xtitle("Wealth total (pct.)") ytitle("Labor income (real, win, $)") ylabel(, format(%9.0fc)) ///
            title("Mean/IQR: Labor income by wealth (pct.) (`y')") legend(off)
        graph export "${DESCRIPTIVE}/Figures/labor_income_real_win_iqr_by_wealthpct_`y'.png", replace
        restore
    }
    quietly count if year == `y' & !missing(ln_lab_inc_final_) & !missing(wealth_total_pct)
    if r(N) >= 10 {
        capture binscatter ln_lab_inc_final_ wealth_total_pct if year == `y', nquantiles(50) ///
            ytitle("Log labor income") xtitle("Wealth total (pct.)") ///
            title("Binscatter: Labor income by wealth (pct.) (`y')")
        if _rc == 0 graph export "${DESCRIPTIVE}/Figures/log_labor_income_binscatter_`y'.png", replace
    }

    * --- Total income: mean+IQR uses real winsorized (level); binscatter uses log ---
    quietly count if year == `y' & !missing(total_income_real_win_) & !missing(wealth_total_pct)
    if r(N) >= 10 {
        preserve
        keep if year == `y'
        collapse (mean) mean_inc = total_income_real_win_ (p25) p25_inc = total_income_real_win_ (p75) p75_inc = total_income_real_win_, by(wealth_total_pct)
        twoway (rarea p75_inc p25_inc wealth_total_pct, color(gs12)) (line mean_inc wealth_total_pct, lcolor(maroon) lwidth(medthick)), ///
            xtitle("Wealth total (pct.)") ytitle("Total income (real, win, $)") ylabel(, format(%9.0fc)) ///
            title("Mean/IQR: Total income by wealth (pct.) (`y')") legend(off)
        graph export "${DESCRIPTIVE}/Figures/total_income_real_win_iqr_by_wealthpct_`y'.png", replace
        restore
    }
    quietly count if year == `y' & !missing(ln_tot_inc_final_) & !missing(wealth_total_pct)
    if r(N) >= 10 {
        capture binscatter ln_tot_inc_final_ wealth_total_pct if year == `y', nquantiles(50) ///
            ytitle("Log total income") xtitle("Wealth total (pct.)") ///
            title("Binscatter: Total income by wealth (pct.) (`y')")
        if _rc == 0 graph export "${DESCRIPTIVE}/Figures/log_total_income_binscatter_`y'.png", replace
    }
}

log close
