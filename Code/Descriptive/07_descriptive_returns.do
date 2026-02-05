* 07_descriptive_returns.do
* Descriptive statistics for returns and related components.
* Inputs:
*   - ${CLEANED}/all_data_merged.dta (components, flows, incomes, debt, wealth)
*   - ${PROCESSED}/analysis_ready_processed.dta (returns + wealth measures)
* Output: Descriptive/Figures and Descriptive/Tables

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
log using "${LOG_DIR}/07_descriptive_returns.log", replace text

capture mkdir "${BASE_PATH}/Descriptive"
capture mkdir "${BASE_PATH}/Descriptive/Figures"
capture mkdir "${BASE_PATH}/Descriptive/Tables"

* ---------------------------------------------------------------------
* Part A: Components, flows, incomes, wealth, debt (from all_data_merged)
* ---------------------------------------------------------------------
use "${CLEANED}/all_data_merged.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Build wealth_total_YYYY (net) and gross_wealth_YYYY
local years "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture confirm variable h`w'atotb
    if !_rc {
        capture drop wealth_total_`y' gross_wealth_`y'
        capture drop wealth_total_`y' _gross_assets_`y' _gross_n_`y' _debt_total_`y' _debt_n_`y'
        egen double _gross_assets_`y' = rowtotal(h`w'atoth h`w'anethb h`w'arles h`w'atran h`w'absns h`w'aira h`w'astck h`w'achck h`w'acd h`w'abond h`w'aothr), missing
        egen byte _gross_n_`y' = rownonmiss(h`w'atoth h`w'anethb h`w'arles h`w'atran h`w'absns h`w'aira h`w'astck h`w'achck h`w'acd h`w'abond h`w'aothr)
        egen double _debt_total_`y' = rowtotal(h`w'amort h`w'ahmln h`w'adebt h`w'amrtb), missing
        egen byte _debt_n_`y' = rownonmiss(h`w'amort h`w'ahmln h`w'adebt h`w'amrtb)
        gen double wealth_total_`y' = _gross_assets_`y' - _debt_total_`y'
        replace wealth_total_`y' = . if _gross_n_`y' == 0 & _debt_n_`y' == 0
        gen double gross_wealth_`y' = ///
            max(h`w'atoth,0) + max(h`w'anethb,0) + max(h`w'arles,0) + max(h`w'atran,0) + ///
            max(h`w'absns,0) + max(h`w'aira,0) + max(h`w'astck,0) + max(h`w'achck,0) + ///
            max(h`w'acd,0) + max(h`w'abond,0) + max(h`w'aothr,0)
    }
}

* Capital gains components over time (selected series on one graph)
preserve
keep hhidpn cg_res_* cg_res2_* cg_re_* cg_bus_* cg_ira_* cg_stk_* cg_bnd_* cg_chk_* cg_cd_* cg_veh_* cg_oth_*
reshape long cg_res_ cg_res2_ cg_re_ cg_bus_ cg_ira_ cg_stk_ cg_bnd_ cg_chk_ cg_cd_ cg_veh_ cg_oth_, i(hhidpn) j(year)
collapse (mean) cg_res_=cg_res_ cg_res2_=cg_res2_ cg_re_=cg_re_ cg_bus_=cg_bus_ cg_ira_=cg_ira_ ///
    cg_stk_=cg_stk_ cg_bnd_=cg_bnd_ cg_chk_=cg_chk_ cg_cd_=cg_cd_ cg_veh_=cg_veh_ cg_oth_=cg_oth_ `wopt', by(year)
twoway line cg_res_ year || line cg_res2_ year || line cg_re_ year || line cg_bus_ year || ///
    line cg_stk_ year || line cg_bnd_ year, ///
    title("Mean capital gains by year") ///
    xtitle("Year") ytitle("Mean capital gain") ///
    legend(order(1 "Primary residence" 2 "Secondary residence" 3 "Real estate" 4 "Business" 5 "Stocks" 6 "Bonds"))
graph export "${BASE_PATH}/Descriptive/Figures/cg_components_mean_by_year.png", replace
restore

* Income components (capital/IRA/total interest) on the same graph
preserve
keep hhidpn y_core_inc_* y_ira_inc_* y_total_int_* 
reshape long y_core_inc_ y_ira_inc_ y_total_int_, i(hhidpn) j(year)
collapse (mean) y_core_inc_=y_core_inc_ y_ira_inc_=y_ira_inc_ y_total_int_=y_total_int_ `wopt', by(year)
twoway line y_core_inc_ year || line y_ira_inc_ year || line y_total_int_ year, ///
    title("Mean interest income by year") ///
    xtitle("Year") ytitle("Mean value") ///
    legend(order(1 "Capital income (core)" 2 "Retirement income (IRA)" 3 "Total interest income (excl. labor)"))
graph export "${BASE_PATH}/Descriptive/Figures/interest_income_mean_by_year.png", replace
restore

* Flow measures by asset class on the same graph
preserve
keep hhidpn flow_bus_* flow_re_* flow_stk_* flow_ira_* flow_res_*
reshape long flow_bus_ flow_re_ flow_stk_ flow_ira_ flow_res_, i(hhidpn) j(year)
collapse (mean) flow_bus_=flow_bus_ flow_re_=flow_re_ flow_stk_=flow_stk_ flow_ira_=flow_ira_ flow_res_=flow_res_ `wopt', by(year)
twoway line flow_bus_ year || line flow_re_ year || line flow_stk_ year || line flow_ira_ year || line flow_res_ year, ///
    title("Mean net investment flows by asset class") ///
    xtitle("Year") ytitle("Mean value") ///
    legend(order(1 "Business" 2 "Real estate" 3 "Stocks" 4 "IRA" 5 "Residences"))
graph export "${BASE_PATH}/Descriptive/Figures/flows_by_asset_mean_by_year.png", replace
restore

* Wealth measures over time (total net vs gross)
preserve
keep hhidpn wealth_total_* gross_wealth_*
reshape long wealth_total_ gross_wealth_, i(hhidpn) j(year)
collapse (mean) wealth_total_=wealth_total_ gross_wealth_=gross_wealth_ `wopt', by(year)
twoway line wealth_total_ year || line gross_wealth_ year, ///
    title("Mean wealth by year") ///
    xtitle("Year") ytitle("Mean wealth") ///
    legend(order(1 "Total net wealth" 2 "Gross wealth"))
graph export "${BASE_PATH}/Descriptive/Figures/wealth_mean_by_year.png", replace
restore

* Debt measures over time (same graph)
preserve
keep hhidpn debt_long_* debt_other_*
reshape long debt_long_ debt_other_, i(hhidpn) j(year)
collapse (mean) debt_long_=debt_long_ debt_other_=debt_other_ `wopt', by(year)
twoway line debt_long_ year || line debt_other_ year, ///
    title("Mean debt by year") ///
    xtitle("Year") ytitle("Mean debt") ///
    legend(order(1 "Long-term debt" 2 "Other debt"))
graph export "${BASE_PATH}/Descriptive/Figures/debt_mean_by_year.png", replace
restore

* ---------------------------------------------------------------------
* Part B: Returns (from analysis_ready_processed)
* ---------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Returns list (waves + averages)
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local retvars ""
foreach y of local years {
    foreach v in r1_annual_`y' r2_annual_`y' r3_annual_`y' r4_annual_`y' debt_long_annual_`y' debt_other_annual_`y' {
        capture confirm variable `v'
        if !_rc {
            local retvars "`retvars' `v'"
        }
    }
}
foreach v in r1_annual_avg r2_annual_avg r3_annual_avg r4_annual_avg debt_long_annual_avg debt_other_annual_avg {
    capture confirm variable `v'
    if !_rc {
        local retvars "`retvars' `v'"
    }
}

* Tabstat for final return measures
display "=== Return measures tabstat ==="
tabstat `retvars' `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* Mean returns by year (single graph with 6 lines)
preserve
keep hhidpn r1_annual_* r2_annual_* r3_annual_* r4_annual_* debt_long_annual_* debt_other_annual_*
reshape long r1_annual_ r2_annual_ r3_annual_ r4_annual_ debt_long_annual_ debt_other_annual_, i(hhidpn) j(year)
collapse (mean) r1=r1_annual_ r2=r2_annual_ r3=r3_annual_ r4=r4_annual_ dlong=debt_long_annual_ doth=debt_other_annual_ `wopt', by(year)
twoway line r1 year || line r2 year || line r3 year || line r4 year || line dlong year || line doth year, ///
    title("Mean returns by year") ///
    xtitle("Year") ytitle("Mean return") ///
    legend(order(1 "r1" 2 "r2" 3 "r3" 4 "r4" 5 "debt_long" 6 "debt_other"))
graph export "${BASE_PATH}/Descriptive/Figures/returns_mean_by_year.png", replace
restore

* Mean returns by age group and education group
preserve
keep hhidpn educ_yrs age_* r1_annual_* r2_annual_* r3_annual_* r4_annual_* debt_long_annual_* debt_other_annual_*
reshape long age_ r1_annual_ r2_annual_ r3_annual_ r4_annual_ debt_long_annual_ debt_other_annual_, i(hhidpn) j(year)
rename age_ age
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat r1_annual_ r2_annual_ r3_annual_ r4_annual_ debt_long_annual_ debt_other_annual_ `wopt', by(age_group) statistics(n mean sd p50 p95)

gen byte educ_group = .
replace educ_group = 1 if educ_yrs < 12
replace educ_group = 2 if educ_yrs == 12
replace educ_group = 3 if inrange(educ_yrs,13,15)
replace educ_group = 4 if educ_yrs == 16
replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
label define educ_group 1 "lt12" 2 "hs" 3 "some_college" 4 "college" 5 "grad"
label values educ_group educ_group
tabstat r1_annual_ r2_annual_ r3_annual_ r4_annual_ debt_long_annual_ debt_other_annual_ `wopt', by(educ_group) statistics(n mean sd p50 p95)
restore

* ---------------------------------------------------------------------
* Asset share concentration table (top share thresholds)
* ---------------------------------------------------------------------
preserve
keep hhidpn gross_wealth_* ///
    share_m3_pri_res_* share_m3_sec_res_* share_m3_re_* share_m3_bus_* share_m3_ira_* ///
    share_m3_stk_* share_m3_bond_* share_m3_chck_* share_m3_cd_* share_m3_vehicles_* share_m3_other_*

local years "2002 2022"
tempfile share_conc
postfile handle str10 asset int year int threshold double pct_of_asset using "`share_conc'", replace

foreach y of local years {
    foreach asset in pri_res sec_res re bus ira stk bond chck cd vehicles other {
        capture confirm variable share_m3_`asset'_`y'
        capture confirm variable gross_wealth_`y'
        if !_rc {
            gen double asset_value = share_m3_`asset'_`y' * gross_wealth_`y'
            if "`wopt'" != "" {
                gen double asset_value_w = asset_value * `wtvar'
                quietly summarize asset_value_w if !missing(asset_value_w)
                local total = r(sum)
                foreach t in 25 50 75 90 95 {
                    quietly summarize asset_value_w if share_m3_`asset'_`y' >= `t'/100 & !missing(asset_value_w)
                    local part = r(sum)
                    local pct = .
                    if `total' > 0 local pct = 100 * (`part' / `total')
                    post handle ("`asset'") (`y') (`t') (`pct')
                }
                drop asset_value_w
            }
            else {
                quietly summarize asset_value if !missing(asset_value)
                local total = r(sum)
                foreach t in 25 50 75 90 95 {
                    quietly summarize asset_value if share_m3_`asset'_`y' >= `t'/100 & !missing(asset_value)
                    local part = r(sum)
                    local pct = .
                    if `total' > 0 local pct = 100 * (`part' / `total')
                    post handle ("`asset'") (`y') (`t') (`pct')
                }
            }
            drop asset_value
        }
    }
}
postclose handle
use "`share_conc'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/share_concentration_by_asset.csv", replace
restore

* Scatterplots: returns vs wealth measures (2002 and 2022)
capture confirm variable wealth_core_2002
if !_rc {
    * Bring wealth measures into long format
    keep hhidpn wealth_core_* wealth_ira_* wealth_res_* wealth_total_* gross_wealth_* ///
        r1_annual_* r2_annual_* r3_annual_* r4_annual_* debt_long_annual_* debt_other_annual_*
    reshape long wealth_core_ wealth_ira_ wealth_res_ wealth_total_ gross_wealth_ ///
        r1_annual_ r2_annual_ r3_annual_ r4_annual_ debt_long_annual_ debt_other_annual_, i(hhidpn) j(year)
    rename wealth_core_ wealth_core
    rename wealth_ira_ wealth_ira
    rename wealth_res_ wealth_res
    rename wealth_total_ wealth_total
    rename gross_wealth_ gross_wealth

    local pctvars "wealth_core wealth_ira wealth_res wealth_total gross_wealth"
    foreach v of local pctvars {
        sort year `v'
        by year: gen long _rank_`v' = sum(!missing(`v'))
        by year: gen long _N_`v' = _rank_`v'[_N]
        gen int `v'_pct = .
        replace `v'_pct = ceil(100 * _rank_`v' / _N_`v') if !missing(`v')
        drop _rank_`v' _N_`v'
    }

    foreach yr in 2002 2022 {
        * r1 vs wealth_core, r2 vs wealth_ira, r3 vs wealth_res, r4 vs wealth_total
        foreach pair in "r1_annual_ wealth_core_pct r1 Wealth core percentile" ///
                         "r2_annual_ wealth_ira_pct r2 Wealth IRA percentile" ///
                         "r3_annual_ wealth_res_pct r3 Wealth residential percentile" ///
                         "r4_annual_ wealth_total_pct r4 Wealth total percentile" {
            tokenize `pair'
            local retvar "``1''"
            local wvar "``2''"
            local retlabel "``3'' return"
            local wlabel "``4''"
            quietly summarize `retvar' if year == `yr' & !missing(`retvar')
            local ymin = r(min)
            local ymax = r(max)
            local ypad = cond(`ymax'==`ymin', 1, (`ymax'-`ymin')*0.05)
            local ymin2 = `ymin' - `ypad'
            local ymax2 = `ymax' + `ypad'
            twoway scatter `retvar' `wvar' if year == `yr' & !missing(`retvar') & !missing(`wvar'), ///
                title("`retlabel' vs `wlabel' (`yr')") ///
                xtitle("`wlabel'") ytitle("`retlabel'") ///
                xscale(range(0 100)) yscale(range(`ymin2' `ymax2')) xlabel(0(20)100)
            graph export "${BASE_PATH}/Descriptive/Figures/``3''_vs_``2''_`yr'.png", replace
        }

        * Debt returns vs gross wealth percentile
        quietly summarize debt_long_annual_ if year == `yr' & !missing(debt_long_annual_)
        local ymin_dl = r(min)
        local ymax_dl = r(max)
        local ypad_dl = cond(`ymax_dl'==`ymin_dl', 1, (`ymax_dl'-`ymin_dl')*0.05)
        local ymin2_dl = `ymin_dl' - `ypad_dl'
        local ymax2_dl = `ymax_dl' + `ypad_dl'
        twoway scatter debt_long_annual_ gross_wealth_pct if year == `yr' & !missing(debt_long_annual_) & !missing(gross_wealth_pct), ///
            title("Debt long return vs gross wealth percentile (`yr')") ///
            xtitle("Gross wealth percentile") ytitle("Debt long return") ///
            xscale(range(0 100)) yscale(range(`ymin2_dl' `ymax2_dl')) xlabel(0(20)100)
        graph export "${BASE_PATH}/Descriptive/Figures/debt_long_vs_gross_wealth_pct_`yr'.png", replace

        quietly summarize debt_other_annual_ if year == `yr' & !missing(debt_other_annual_)
        local ymin_do = r(min)
        local ymax_do = r(max)
        local ypad_do = cond(`ymax_do'==`ymin_do', 1, (`ymax_do'-`ymin_do')*0.05)
        local ymin2_do = `ymin_do' - `ypad_do'
        local ymax2_do = `ymax_do' + `ypad_do'
        twoway scatter debt_other_annual_ gross_wealth_pct if year == `yr' & !missing(debt_other_annual_) & !missing(gross_wealth_pct), ///
            title("Debt other return vs gross wealth percentile (`yr')") ///
            xtitle("Gross wealth percentile") ytitle("Debt other return") ///
            xscale(range(0 100)) yscale(range(`ymin2_do' `ymax2_do')) xlabel(0(20)100)
        graph export "${BASE_PATH}/Descriptive/Figures/debt_other_vs_gross_wealth_pct_`yr'.png", replace
    }
}

log close

* ---------------------------------------------------------------------
* Lorenz curves + Gini table (income + wealth)
* ---------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Measures for Lorenz (income, wealth incl. gross, debt)
local lorenz_measures "labor_income_real_win total_income_real_win wealth_core wealth_ira wealth_res wealth_total gross_wealth debt_long debt_other"
local lorenz_years "2002 2022"

* Measures for Gini table (income 2 + wealth/debt 6)
local gini_measures "labor_income_real_win total_income_real_win wealth_core wealth_ira wealth_res wealth_total gross_wealth debt_long debt_other"
local gini_years "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"

* Prepare empty Lorenz dataset
tempfile lorenz_all
clear
set obs 0
gen str32 measure = ""
gen int year = .
gen double cum_pop = .
gen double cum_share = .
save "`lorenz_all'", replace

* Gini table output
tempfile gini_out
postfile gini_handle str32 measure int year double gini N total_sum using "`gini_out'", replace

foreach y of local gini_years {
    foreach m of local gini_measures {
        local v = "`m'_`y'"
        capture confirm variable `v'
        if _rc continue
        preserve
        keep `v' `wtvar'
        keep if !missing(`v')
        keep if `v' >= 0
        if "`wopt'" != "" {
            keep if !missing(`wtvar') & `wtvar' > 0
        }
        gen double _w = 1
        if "`wopt'" != "" replace _w = `wtvar'
        gen double _wy = _w * `v'
        quietly summarize _w, meanonly
        local totalw = r(sum)
        quietly summarize _wy, meanonly
        local totaly = r(sum)
        if (`totalw' <= 0 | `totaly' <= 0) {
            post gini_handle ("`m'") (`y') (.) (r(N)) (`totaly')
            restore
            continue
        }
        sort `v'
        gen double cum_w = sum(_w)/`totalw'
        gen double cum_y = sum(_wy)/`totaly'
        gen double cum_w_l = cum_w[_n-1]
        gen double cum_y_l = cum_y[_n-1]
        replace cum_w_l = 0 in 1
        replace cum_y_l = 0 in 1
        gen double area = (cum_y + cum_y_l) * (cum_w - cum_w_l)
        quietly summarize area, meanonly
        local g = 1 - r(sum)
        post gini_handle ("`m'") (`y') (`g') (r(N)) (`totaly')

        * Save Lorenz points for 2002/2022 (selected measures)
        local is_lorenz : list m in lorenz_measures
        if inlist(`y',2002,2022) & `is_lorenz' {
            keep cum_w cum_y
            rename cum_w cum_pop
            rename cum_y cum_share
            gen str32 measure = "`m'"
            gen int year = `y'
            keep measure year cum_pop cum_share
            append using "`lorenz_all'"
            save "`lorenz_all'", replace
        }
        restore
    }
}
postclose gini_handle

use "`gini_out'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/gini_by_year.csv", replace

* Lorenz plots
use "`lorenz_all'", clear

* Labels for measures
gen str40 mlabel = ""
replace mlabel = "Labor income (real, win)" if measure == "labor_income_real_win"
replace mlabel = "Total income (real, win)" if measure == "total_income_real_win"
replace mlabel = "Wealth core" if measure == "wealth_core"
replace mlabel = "Wealth IRA" if measure == "wealth_ira"
replace mlabel = "Wealth residential" if measure == "wealth_res"
replace mlabel = "Wealth total" if measure == "wealth_total"
replace mlabel = "Gross wealth" if measure == "gross_wealth"
replace mlabel = "Debt long" if measure == "debt_long"
replace mlabel = "Debt other" if measure == "debt_other"

* Income Lorenz (2002 vs 2022 on one graph)
twoway line cum_share cum_pop if year==2002 & measure=="labor_income_real_win", lcolor(navy) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="labor_income_real_win", lcolor(navy) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="total_income_real_win", lcolor(blue) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="total_income_real_win", lcolor(blue) lpattern(dash), ///
       title("Lorenz curves: income (2002 vs 2022)") ///
       xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Labor income 2002" 2 "Labor income 2022" 3 "Total income 2002" 4 "Total income 2022"))
graph export "${BASE_PATH}/Descriptive/Figures/lorenz_income_2002_2022.png", replace

* Wealth Lorenz (2002 vs 2022 on one graph, incl. gross)
twoway line cum_share cum_pop if year==2002 & measure=="wealth_core", lcolor(maroon) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_core", lcolor(maroon) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_ira", lcolor(red) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_ira", lcolor(red) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_res", lcolor(orange) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_res", lcolor(orange) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_total", lcolor(green) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_total", lcolor(green) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="gross_wealth", lcolor(teal) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="gross_wealth", lcolor(teal) lpattern(dash), ///
       title("Lorenz curves: wealth (2002 vs 2022)") ///
       xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Wealth core 2002" 2 "Wealth core 2022" 3 "Wealth IRA 2002" 4 "Wealth IRA 2022" 5 "Wealth residential 2002" 6 "Wealth residential 2022" 7 "Wealth total 2002" 8 "Wealth total 2022" 9 "Gross wealth 2002" 10 "Gross wealth 2022"))
graph export "${BASE_PATH}/Descriptive/Figures/lorenz_wealth_2002_2022.png", replace

* Debt Lorenz (2002 vs 2022 on one graph)
twoway line cum_share cum_pop if year==2002 & measure=="debt_long", lcolor(purple) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="debt_long", lcolor(purple) lpattern(dash) || ///
       line cum_share cum_pop if year==2002 & measure=="debt_other", lcolor(teal) lpattern(solid) || ///
       line cum_share cum_pop if year==2022 & measure=="debt_other", lcolor(teal) lpattern(dash), ///
       title("Lorenz curves: debt (2002 vs 2022)") ///
       xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Debt long 2002" 2 "Debt long 2022" 3 "Debt other 2002" 4 "Debt other 2022"))
graph export "${BASE_PATH}/Descriptive/Figures/lorenz_debt_2002_2022.png", replace
