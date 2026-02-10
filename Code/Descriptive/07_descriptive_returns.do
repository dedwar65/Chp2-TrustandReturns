* 07_descriptive_returns.do
* Descriptive statistics for returns and related components.
* Inputs:
*   - ${CLEANED}/all_data_merged.dta (components, flows, incomes, debt, wealth)
*   - ${PROCESSED}/analysis_ready_processed.dta (returns + wealth measures)
* Output: Code/Descriptive/Figures and Code/Descriptive/Tables

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

capture mkdir "${DESCRIPTIVE}"
capture mkdir "${DESCRIPTIVE}/Figures"
capture mkdir "${DESCRIPTIVE}/Tables"

* ---------------------------------------------------------------------
* Part A: Components, flows, incomes, wealth, debt (from all_data_merged)
* ---------------------------------------------------------------------
use "${CLEANED}/all_data_merged.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Build wealth_total_YYYY (net), gross_wealth_YYYY, wealth_ira_YYYY, wealth_res_YYYY
local years "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture confirm variable h`w'atotb
    if !_rc {
        capture drop wealth_total_`y' gross_wealth_`y'
        capture drop _gross_n_`y' _debt_total_`y' _debt_n_`y'
        egen byte _gross_n_`y' = rownonmiss(h`w'atoth h`w'anethb h`w'arles h`w'atran h`w'absns h`w'aira h`w'astck h`w'achck h`w'acd h`w'abond h`w'aothr)
        egen byte _debt_n_`y' = rownonmiss(h`w'amort h`w'ahmln h`w'adebt h`w'amrtb)
        gen double _debt_total_`y' = ///
            max(h`w'amort,0) + max(h`w'ahmln,0) + max(h`w'adebt,0) + max(h`w'amrtb,0)
        replace _debt_total_`y' = . if _debt_n_`y' == 0
        gen double gross_wealth_`y' = ///
            max(h`w'atoth,0) + max(h`w'anethb,0) + max(h`w'arles,0) + max(h`w'atran,0) + ///
            max(h`w'absns,0) + max(h`w'aira,0) + max(h`w'astck,0) + max(h`w'achck,0) + ///
            max(h`w'acd,0) + max(h`w'abond,0) + max(h`w'aothr,0)
        replace gross_wealth_`y' = . if _gross_n_`y' == 0
        gen double wealth_total_`y' = gross_wealth_`y' - _debt_total_`y'
        replace wealth_total_`y' = . if _gross_n_`y' == 0 & _debt_n_`y' == 0
    }
    capture confirm variable h`w'aira
    if !_rc {
        capture drop wealth_ira_`y'
        gen double wealth_ira_`y' = h`w'aira
    }
    capture confirm variable h`w'atoth h`w'anethb
    if !_rc {
        capture drop wealth_res_`y'
        gen double wealth_res_`y' = h`w'atoth + h`w'anethb if !missing(h`w'atoth) & !missing(h`w'anethb)
    }
    * Core wealth (re+bus+stk+bond+chck+cd) and Core+ret. for mean-by-year graph
    capture confirm variable h`w'arles h`w'absns h`w'astck h`w'abond h`w'achck h`w'acd
    if !_rc {
        capture drop wealth_core_`y'
        gen double wealth_core_`y' = max(h`w'arles,0)+max(h`w'absns,0)+max(h`w'astck,0)+max(h`w'abond,0)+max(h`w'achck,0)+max(h`w'acd,0) if !missing(h`w'arles) & !missing(h`w'absns) & !missing(h`w'astck) & !missing(h`w'abond) & !missing(h`w'achck) & !missing(h`w'acd)
        capture drop wealth_coreira_`y'
        gen double wealth_coreira_`y' = wealth_core_`y' + wealth_ira_`y' if !missing(wealth_core_`y') & !missing(wealth_ira_`y')
    }
}

* Capital gains components over time (selected assets)
preserve
keep hhidpn cg_res_* cg_res2_* cg_re_* cg_bus_* cg_ira_* cg_stk_* cg_bnd_* cg_chk_* cg_cd_* cg_veh_* cg_oth_*
reshape long cg_res_ cg_res2_ cg_re_ cg_bus_ cg_ira_ cg_stk_ cg_bnd_ cg_chk_ cg_cd_ cg_veh_ cg_oth_, i(hhidpn) j(year)
collapse (mean) cg_res_mean=cg_res_ cg_res2_mean=cg_res2_ cg_re_mean=cg_re_ cg_bus_mean=cg_bus_ cg_stk_mean=cg_stk_ cg_bnd_mean=cg_bnd_ ///
    (p50) cg_res_p50=cg_res_ cg_res2_p50=cg_res2_ cg_re_p50=cg_re_ cg_bus_p50=cg_bus_ cg_stk_p50=cg_stk_ cg_bnd_p50=cg_bnd_ `wopt', by(year)
local cg_assets "res res2 re bus stk bnd"
forvalues i = 1/6 {
    local a : word `i' of `cg_assets'
    local lab = cond("`a'"=="res","Primary residence", ///
        cond("`a'"=="res2","Secondary residence", ///
        cond("`a'"=="re","Real estate", ///
        cond("`a'"=="bus","Business", ///
        cond("`a'"=="stk","Stocks","Bonds")))))
    twoway line cg_`a'_mean year || line cg_`a'_p50 year, ///
        title("`lab' capital gains") ///
        xtitle("Year") ytitle("Capital gains ($)") ylabel(, format(%9.0fc)) ///
        legend(order(1 "Mean" 2 "Median"))
    graph export "${DESCRIPTIVE}/Figures/cg_`a'_mean_median_by_year.png", replace
}
restore

* Zero-share diagnostics for 2022 capital gains (valid asset pairs only)
preserve
local y = 2022
gen double cg_res_`y'_raw  = h16atoth  - h15atoth  if !missing(h16atoth, h15atoth)
gen double cg_res2_`y'_raw = h16anethb - h15anethb if !missing(h16anethb, h15anethb)
gen double cg_re_`y'_raw   = h16arles  - h15arles  if !missing(h16arles, h15arles)
gen double cg_bus_`y'_raw  = h16absns  - h15absns  if !missing(h16absns, h15absns)
gen double cg_stk_`y'_raw  = h16astck  - h15astck  if !missing(h16astck, h15astck)
gen double cg_bnd_`y'_raw  = h16abond  - h15abond  if !missing(h16abond, h15abond)
display "=== 2022 CG zero-share diagnostics (valid pairs only) ==="
foreach v in cg_res_`y'_raw cg_res2_`y'_raw cg_re_`y'_raw cg_bus_`y'_raw cg_stk_`y'_raw cg_bnd_`y'_raw {
    quietly count if !missing(`v')
    local nn = r(N)
    quietly count if `v' == 0
    local n0 = r(N)
    di "`v'  zeros=" `n0' "  N(nonmiss)=" `nn' "  zero share=" %6.3f (`n0'/`nn')
}
restore

* Income components (capital/IRA/total interest) on the same graph
preserve
keep hhidpn y_core_inc_* y_ira_inc_* y_total_int_* 
reshape long y_core_inc_ y_ira_inc_ y_total_int_, i(hhidpn) j(year)
collapse (mean) y_core_inc_=y_core_inc_ y_ira_inc_=y_ira_inc_ y_total_int_=y_total_int_ `wopt', by(year)
twoway line y_core_inc_ year || line y_ira_inc_ year || line y_total_int_ year, ///
    title("Mean interest income by year") ///
    xtitle("Year") ytitle("Mean value ($)") ylabel(, format(%9.0fc)) ///
    legend(order(1 "Capital income (core)" 2 "Retirement income (IRA)" 3 "Total interest income"))
graph export "${DESCRIPTIVE}/Figures/interest_income_mean_by_year.png", replace
restore

* Flow measures by asset class on the same graph
preserve
keep hhidpn flow_bus_* flow_re_* flow_stk_* flow_ira_* flow_res_*
reshape long flow_bus_ flow_re_ flow_stk_ flow_ira_ flow_res_, i(hhidpn) j(year)
collapse (mean) flow_bus_=flow_bus_ flow_re_=flow_re_ flow_stk_=flow_stk_ flow_ira_=flow_ira_ flow_res_=flow_res_ `wopt', by(year)
twoway line flow_bus_ year || line flow_re_ year || line flow_stk_ year || line flow_ira_ year || line flow_res_ year, ///
    title("Mean net investment flows by asset class") ///
    xtitle("Year") ytitle("Mean value ($)") ylabel(, format(%9.0fc)) ///
    legend(order(1 "Business" 2 "Real estate" 3 "Stocks" 4 "IRA" 5 "Residences"))
graph export "${DESCRIPTIVE}/Figures/flows_by_asset_mean_by_year.png", replace
restore

* Wealth measures over time: (1) components = core, IRA, residential; (2) aggregated = core, Core+ret., net wealth
preserve
keep hhidpn wealth_total_* wealth_core_* wealth_ira_* wealth_res_* wealth_coreira_*
reshape long wealth_total_ wealth_core_ wealth_ira_ wealth_res_ wealth_coreira_, i(hhidpn) j(year)
* Means by year (each series uses its own nonmissing sample)
collapse (mean) wealth_total_=wealth_total_ wealth_core_=wealth_core_ wealth_ira_=wealth_ira_ wealth_res_=wealth_res_ wealth_coreira_=wealth_coreira_ `wopt', by(year)
display "=== Wealth mean-by-year (series-specific samples) ==="
list year wealth_total_ wealth_core_ wealth_ira_ wealth_res_ wealth_coreira_, noobs
* Components: core, IRA, residential
twoway line wealth_core_ year || line wealth_ira_ year || line wealth_res_ year, ///
    title("Mean wealth by year (components)") ///
    xtitle("Year") ytitle("Mean wealth ($)") ylabel(, format(%9.0fc)) ///
    legend(order(1 "Core" 2 "Retirement (IRA)" 3 "Residential"))
graph export "${DESCRIPTIVE}/Figures/wealth_mean_by_year_components.png", replace
* Aggregated: core, Core+ret., net wealth
twoway line wealth_core_ year || line wealth_coreira_ year || line wealth_total_ year, ///
    title("Mean wealth by year (aggregated)") ///
    xtitle("Year") ytitle("Mean wealth ($)") ylabel(, format(%9.0fc)) ///
    legend(order(1 "Core" 2 "Core+ret." 3 "Net wealth"))
graph export "${DESCRIPTIVE}/Figures/wealth_mean_by_year_agg.png", replace
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

* Returns list (waves + averages) — r1 core, r2 retirement, r3 residential, r4 Core+ret., r5 net wealth
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local retvars ""
foreach y of local years {
    foreach v in r1_annual_`y' r2_annual_`y' r3_annual_`y' r4_annual_`y' r5_annual_`y' {
        capture confirm variable `v'
        if !_rc {
            local retvars "`retvars' `v'"
        }
    }
}
foreach v in r1_annual_avg r2_annual_avg r3_annual_avg r4_annual_avg r5_annual_avg {
    capture confirm variable `v'
    if !_rc {
        local retvars "`retvars' `v'"
    }
}

* Tabstat for final return measures
display "=== Return measures tabstat ==="
tabstat `retvars' `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* Mean returns by year: (1) components = r1, r2, r3; (2) aggregated = r1, r4, r5
preserve
keep hhidpn r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_*
reshape long r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
collapse (mean) r1=r1_annual_ r2=r2_annual_ r3=r3_annual_ r4=r4_annual_ r5=r5_annual_ `wopt', by(year)
* Components: core, retirement, residential
twoway line r1 year || line r2 year || line r3 year, ///
    title("Mean returns by year (components)") ///
    xtitle("Year") ytitle("Mean return") ///
    legend(order(1 "Core" 2 "Retirement" 3 "Residential"))
graph export "${DESCRIPTIVE}/Figures/returns_mean_by_year_components.png", replace
* Aggregated: core, Core+ret., net wealth
twoway line r1 year || line r4 year || line r5 year, ///
    title("Mean returns by year (aggregated)") ///
    xtitle("Year") ytitle("Mean return") ///
    legend(order(1 "Core" 2 "Core+ret." 3 "Net wealth"))
graph export "${DESCRIPTIVE}/Figures/returns_mean_by_year_agg.png", replace
restore

* Mean returns by age group and education group
preserve
keep hhidpn educ_yrs age_* r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_*
capture drop age_2000
reshape long age_ r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
rename age_ age
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_ `wopt', by(age_group) statistics(n mean sd p50 p95)

gen byte educ_group = .
replace educ_group = 1 if educ_yrs < 12
replace educ_group = 2 if educ_yrs == 12
replace educ_group = 3 if inrange(educ_yrs,13,15)
replace educ_group = 4 if educ_yrs == 16
replace educ_group = 5 if educ_yrs >= 17 & !missing(educ_yrs)
label define educ_group 1 "no hs" 2 "hs" 3 "some college" 4 "4yr degree" 5 "grad"
label values educ_group educ_group
tabstat r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_ `wopt', by(educ_group) statistics(n mean sd p50 p95)
restore

* ---------------------------------------------------------------------
* Asset share concentration table (top share thresholds)
* Core assets = bonds + stocks + real estate + business (mutually exclusive).
* ---------------------------------------------------------------------
preserve
keep hhidpn gross_wealth_* ///
    share_m3_pri_res_* share_m3_sec_res_* share_m3_re_* share_m3_bus_* share_m3_ira_* ///
    share_m3_stk_* share_m3_bond_* share_m3_chck_* share_m3_cd_* share_m3_vehicles_* share_m3_other_*
capture confirm variable share_residential_2002
if _rc {
    foreach y in 2002 2022 {
        capture confirm variable share_m3_pri_res_`y' share_m3_sec_res_`y'
        if !_rc egen double share_residential_`y' = rowtotal(share_m3_pri_res_`y' share_m3_sec_res_`y'), missing
    }
}
local years "2002 2022"
foreach y of local years {
    capture confirm variable share_m3_bond_`y'
    if !_rc {
        egen double share_core_`y' = rowtotal(share_m3_bond_`y' share_m3_stk_`y' share_m3_re_`y' share_m3_bus_`y'), missing
    }
}

tempfile share_conc
postfile handle str12 asset int year int threshold double pct_of_asset using "`share_conc'", replace

foreach y of local years {
    foreach asset in pri_res sec_res re bus ira stk bond chck cd vehicles other core residential {
        local sharevar = cond("`asset'" == "core", "share_core", cond("`asset'" == "residential", "share_residential", "share_m3_`asset'"))
        capture confirm variable `sharevar'_`y'
        capture confirm variable gross_wealth_`y'
        if !_rc {
            gen double asset_value = `sharevar'_`y' * gross_wealth_`y'
            if "`wopt'" != "" {
                gen double asset_value_w = asset_value * `wtvar'
                quietly summarize asset_value_w if !missing(asset_value_w)
                local total = r(sum)
                foreach t in 25 50 75 90 95 {
                    quietly summarize asset_value_w if `sharevar'_`y' >= `t'/100 & !missing(asset_value_w)
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
                    quietly summarize asset_value if `sharevar'_`y' >= `t'/100 & !missing(asset_value)
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
file open fh using "${DESCRIPTIVE}/Tables/share_concentration_by_asset.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\setlength{\tabcolsep}{4pt}" _n "\caption{Share concentration by asset class}" _n "\label{tab:share_concentration_by_asset}" _n "\begin{tabular}{@{}@{\extracolsep{0pt}}lrrr@{}}\toprule" _n "Asset & Year & Threshold (\%) & Pct.\ of asset \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local a = asset[`r']
    if "`a'" == "pri_res" local a "Primary residence"
    if "`a'" == "sec_res" local a "Secondary residence"
    if "`a'" == "re" local a "Real estate"
    if "`a'" == "bus" local a "Business"
    if "`a'" == "ira" local a "IRA"
    if "`a'" == "stk" local a "Stocks"
    if "`a'" == "bond" local a "Bonds"
    if "`a'" == "chck" local a "Checking"
    if "`a'" == "cd" local a "CD"
    if "`a'" == "vehicles" local a "Vehicles"
    if "`a'" == "other" local a "Other"
    if "`a'" == "core" local a "Core"
    if "`a'" == "residential" local a "Residential"
    local yr_s = string(year[`r'], "%9.0f")
    local th_s = string(threshold[`r'], "%9.0f")
    local pct_s = string(pct_of_asset[`r'], "%5.2f")
    file write fh "`a' & `yr_s' & `th_s' & `pct_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Share of total asset held by households with portfolio share in that class $\ge$ threshold.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
display "=== Share concentration by asset (pct of asset held by households with share >= threshold) ==="
list, noobs sep(0)

* Share concentration: bar graph. Three groups: Core assets, Residential (primary + secondary), Retirement.
replace asset = "residential" if asset == "residentia"
keep if inlist(asset, "core", "residential", "ira")
reshape wide pct_of_asset, i(year threshold) j(asset) string

local ylab "Percent of total asset held"

* 2002 panel. Bar order = Core assets, Residential, Retirement.
graph bar pct_of_assetcore pct_of_assetresidential pct_of_assetira if year == 2002, ///
    over(threshold, relabel(25 "25%" 50 "50%" 75 "75%" 90 "90%" 95 "95%")) ///
    bar(1, color(navy)) bar(2, color(maroon)) bar(3, color(green)) ///
    title("Wealth concentration by asset class (2002)") ///
    b1title("Percent invested in asset class") ytitle("`ylab'", margin(small)) ///
    ylabel(0(20)100, format(%4.0f)) ///
    graphregion(margin(l=12)) ///
    plotregion(margin(r+14)) ///
    legend(label(1 "Core assets") label(2 "Residential") label(3 "Retirement") ///
           cols(1) size(small) position(3) ring(0) region(lstyle(none)))
graph export "${DESCRIPTIVE}/Figures/share_concentration_2002.png", replace

* 2022 panel
graph bar pct_of_assetcore pct_of_assetresidential pct_of_assetira if year == 2022, ///
    over(threshold, relabel(25 "25%" 50 "50%" 75 "75%" 90 "90%" 95 "95%")) ///
    bar(1, color(navy)) bar(2, color(maroon)) bar(3, color(green)) ///
    title("Wealth concentration by asset class (2022)") ///
    b1title("Percent invested in asset class") ytitle("`ylab'", margin(small)) ///
    ylabel(0(20)100, format(%4.0f)) ///
    graphregion(margin(l=12)) ///
    plotregion(margin(r+14)) ///
    legend(label(1 "Core assets") label(2 "Residential") label(3 "Retirement") ///
           cols(1) size(small) position(3) ring(0) region(lstyle(none)))
graph export "${DESCRIPTIVE}/Figures/share_concentration_2022.png", replace

restore

* ---------------------------------------------------------------------
* Mean portfolio share by year: Core assets, Residential (primary+secondary), Retirement.
* Share in core = (bonds+stocks+real estate+business)/gross assets; residential = pri+sec res; ret = IRA.
* ---------------------------------------------------------------------
preserve
capture confirm variable share_residential_2002
if _rc {
    foreach y in 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022 {
        capture confirm variable share_m3_pri_res_`y' share_m3_sec_res_`y'
        if !_rc egen double share_residential_`y' = rowtotal(share_m3_pri_res_`y' share_m3_sec_res_`y'), missing
    }
}
tempfile mean_shares
postfile mhandle int year double mean_core double mean_residential double mean_ira using "`mean_shares'", replace
foreach y in 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022 {
    capture confirm variable share_residential_`y'
    if _rc continue
    capture drop share_core_`y'
    egen double share_core_`y' = rowtotal(share_m3_bond_`y' share_m3_stk_`y' share_m3_re_`y' share_m3_bus_`y'), missing
    summarize share_core_`y' `wopt'
    local mc = r(mean)
    summarize share_residential_`y' `wopt'
    local mr = r(mean)
    summarize share_m3_ira_`y' `wopt'
    local mi = r(mean)
    post mhandle (`y') (`mc') (`mr') (`mi')
    drop share_core_`y'
}
postclose mhandle
use "`mean_shares'", clear
file open fh using "${DESCRIPTIVE}/Tables/mean_share_by_asset_class_year.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\setlength{\tabcolsep}{4pt}" _n "\caption{Mean portfolio share by asset class and year}" _n "\label{tab:mean_share_by_asset_class_year}" _n "\begin{tabular}{@{}@{\extracolsep{0pt}}lrrr@{}}\toprule" _n "Year & Core & Residential & Retirement \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local mc_s = string(mean_core[`r'], "%5.3f")
    local mr_s = string(mean_residential[`r'], "%5.3f")
    local mi_s = string(mean_ira[`r'], "%5.3f")
    file write fh "`yr_s' & `mc_s' & `mr_s' & `mi_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Core = bonds, stocks, real estate, business; Residential = primary + secondary; Retirement = IRA.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh
graph bar mean_core mean_residential mean_ira, over(year) ///
    bar(1, color(navy)) bar(2, color(maroon)) bar(3, color(green)) ///
    title("Mean portfolio share by asset class") ///
    ytitle("Mean share") ylabel(0(0.1)0.6, format(%3.2f)) yscale(range(0 0.6)) ///
    legend(label(1 "Core assets") label(2 "Residential") label(3 "Retirement") ///
           cols(1) size(small) position(3) ring(0) region(lstyle(none)))
graph export "${DESCRIPTIVE}/Figures/mean_share_by_asset_class_year.png", replace
restore

* Returns vs wealth percentile: mean+IQR ribbon and binscatter (2002 and 2022)
capture confirm variable wealth_core_2002
if !_rc {
    local wkeep "wealth_core_* wealth_ira_* wealth_res_* wealth_total_* gross_wealth_*"
    capture confirm variable wealth_coreira_2002
    if !_rc local wkeep "wealth_core_* wealth_ira_* wealth_coreira_* wealth_res_* wealth_total_* gross_wealth_*"
    keep hhidpn `wkeep' r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_*
    * Returns exist only 2002-2022; drop wealth_*_2000 so reshape j = 2002 2004 ... 2022
    foreach stub in wealth_core_ wealth_ira_ wealth_res_ wealth_total_ gross_wealth_ {
        capture drop `stub'2000
    }
    capture drop wealth_coreira_2000
    capture confirm variable wealth_coreira_2002
    if !_rc {
        reshape long wealth_core_ wealth_ira_ wealth_coreira_ wealth_res_ wealth_total_ gross_wealth_ ///
            r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
        rename (wealth_core_ wealth_ira_ wealth_coreira_ wealth_res_ wealth_total_ gross_wealth_) (wealth_core wealth_ira wealth_coreira wealth_res wealth_total gross_wealth)
    }
    else {
        reshape long wealth_core_ wealth_ira_ wealth_res_ wealth_total_ gross_wealth_ ///
            r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
        rename (wealth_core_ wealth_ira_ wealth_res_ wealth_total_ gross_wealth_) (wealth_core wealth_ira wealth_res wealth_total gross_wealth)
        gen double wealth_coreira = wealth_core + wealth_ira if !missing(wealth_core) & !missing(wealth_ira)
    }

    local pctvars "wealth_core wealth_ira wealth_res wealth_coreira wealth_total gross_wealth"
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

    foreach yr in 2002 2022 {
        * r1 core, r2 ret, r3 res, r4 Core+ret., r5 net wealth
        foreach pair in "r1_annual_ wealth_core_pct core Core" "r2_annual_ wealth_ira_pct ret Retirement" "r3_annual_ wealth_res_pct res Residential" "r4_annual_ wealth_coreira_pct coreira Core+ret." "r5_annual_ wealth_total_pct netwealth Net wealth" {
            tokenize `pair'
            local retvar "`1'"
            local wvar "`2'"
            local rlab_short "`3'"
            local rlab_abbrev "`4' `5'"
            local rlab_portfolio = cond("`rlab_short'"=="core","core assets",cond("`rlab_short'"=="ret","retirement assets",cond("`rlab_short'"=="res","residential assets",cond("`rlab_short'"=="coreira","Core+ret.","net wealth"))))
            local wlab = cond("`wvar'"=="wealth_core_pct","core",cond("`wvar'"=="wealth_ira_pct","retirement",cond("`wvar'"=="wealth_res_pct","residential",cond("`wvar'"=="wealth_coreira_pct","core+ret.","total"))))
            quietly count if year == `yr' & !missing(`retvar') & !missing(`wvar')
            if r(N) < 10 continue

            * Mean + IQR ribbon
            preserve
            keep if year == `yr'
            collapse (mean) mean_r = `retvar' (p25) p25_r = `retvar' (p75) p75_r = `retvar', by(`wvar')
            twoway (rarea p75_r p25_r `wvar', color(gs12)) (line mean_r `wvar', lcolor(navy) lwidth(medthick)), ///
                xtitle("Wealth `wlab' (pct.)") ytitle("`rlab_abbrev' return") ///
                title("Mean/IQR: Returns to `rlab_portfolio' and wealth (`yr')") legend(off)
            graph export "${DESCRIPTIVE}/Figures/`rlab_short'_return_iqr_by_wealthpct_`yr'.png", replace
            restore

            * Binscatter
            capture binscatter `retvar' `wvar' if year == `yr', nquantiles(50) ///
                ytitle("`rlab_abbrev' return") xtitle("Wealth `wlab' (pct.)") ///
                title("Binscatter: Returns to `rlab_portfolio' and wealth (`yr')")
            if _rc == 0 graph export "${DESCRIPTIVE}/Figures/`rlab_short'_return_binscatter_`yr'.png", replace
        }
    }
}

* ---------------------------------------------------------------------
* Distribution of returns (histogram): (1) components r1,r2,r3; (2) aggregated r1,r4,r5 (2002 and 2022; winsorized when available)
* ---------------------------------------------------------------------
clear
use "${PROCESSED}/analysis_ready_processed.dta", clear
display "=== Return distributions (2002 and 2022) ==="
local _tdir `c(tmpdir)'
foreach yr in 2002 2022 {
    capture confirm variable r1_annual_`yr'
    if _rc continue
    * Build one .gph per return (r1–r5)
    foreach r in 1 2 3 4 5 {
        local v "r`r'_annual_`yr'"
        local use_win 0
        capture confirm variable r`r'_annual_win_`yr'
        if !_rc {
            local v "r`r'_annual_win_`yr'"
            local use_win 1
        }
        capture confirm variable `v'
        if _rc continue
        local rname_sub = cond(`r'==1,"Core",cond(`r'==2,"Retirement",cond(`r'==3,"Residential",cond(`r'==4,"Core+ret.","Net wealth"))))
        local xtit = cond(`use_win', "Annual return (winsorized 1%)", "Annual return")
        histogram `v' if !missing(`v'), ///
            bin(80) fraction ///
            xtitle("`xtit'") ytitle("Fraction of households") ///
            xlabel(, format(%3.2f)) ///
            title("`rname_sub'") ///
            saving("`_tdir'_r`r'_hist_`yr'.gph", replace)
    }
    * Components: r1, r2, r3
    local gph_comp ""
    foreach r in 1 2 3 {
        capture confirm file "`_tdir'_r`r'_hist_`yr'.gph"
        if !_rc {
            if "`gph_comp'" == "" local gph_comp "`_tdir'_r`r'_hist_`yr'.gph"
            else local gph_comp "`gph_comp' `_tdir'_r`r'_hist_`yr'.gph"
        }
    }
    if "`gph_comp'" != "" {
        graph combine `gph_comp', cols(2) title("Returns by portfolio (`yr'): components")
        graph export "${DESCRIPTIVE}/Figures/returns_histogram_components_`yr'.png", replace
    }
    * Aggregated: r1, r4, r5
    local gph_agg ""
    foreach r in 1 4 5 {
        capture confirm file "`_tdir'_r`r'_hist_`yr'.gph"
        if !_rc {
            if "`gph_agg'" == "" local gph_agg "`_tdir'_r`r'_hist_`yr'.gph"
            else local gph_agg "`gph_agg' `_tdir'_r`r'_hist_`yr'.gph"
        }
    }
    if "`gph_agg'" != "" {
        graph combine `gph_agg', cols(2) title("Returns by portfolio (`yr'): aggregated")
        graph export "${DESCRIPTIVE}/Figures/returns_histogram_agg_`yr'.png", replace
    }
}

log close

* ---------------------------------------------------------------------
* Lorenz curves + Gini table (income + wealth)
* ---------------------------------------------------------------------
clear
use "${PROCESSED}/analysis_ready_processed.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Measures for Lorenz (income, wealth incl. gross, Core+ret.)
local lorenz_measures "labor_income_real_win total_income_real_win wealth_core wealth_ira wealth_coreira wealth_res wealth_total gross_wealth"
local lorenz_years "2002 2022"

* Measures for Gini table (income 2 + wealth 6)
local gini_measures "labor_income_real_win total_income_real_win wealth_core wealth_ira wealth_coreira wealth_res wealth_total gross_wealth"
local gini_years "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"

* Prepare Lorenz output (use postfile to avoid append issues)
tempfile lorenz_all
postfile lor_handle str32 measure int year double cum_pop cum_share using "`lorenz_all'", replace

* Gini table output
tempfile gini_out
postfile gini_handle str32 measure int year double gini obs total_sum using "`gini_out'", replace

foreach y of local gini_years {
    foreach m of local gini_measures {
        local v = "`m'_`y'"
        capture confirm variable `v'
        if _rc continue
        preserve
        capture confirm variable `wtvar'
        if !_rc keep `v' `wtvar'
        else keep `v'
        keep if !missing(`v')
        keep if `v' >= 0
        if "`wopt'" != "" {
            keep if !missing(`wtvar') & `wtvar' > 0
        }
        gen double _w = 1
        capture confirm variable `wtvar'
        if !_rc & "`wopt'" != "" replace _w = `wtvar'
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
        if inlist(`y',2002,2022) & inlist("`m'", "labor_income_real_win", "total_income_real_win", ///
            "wealth_core", "wealth_ira", "wealth_coreira", "wealth_res", "wealth_total", "gross_wealth") {
            keep cum_w cum_y
            rename cum_w cum_pop
            rename cum_y cum_share
            forvalues i = 1/`=_N' {
                post lor_handle ("`m'") (`y') (cum_pop[`i']) (cum_share[`i'])
            }
        }
        restore
    }
}
postclose gini_handle
postclose lor_handle

use "`gini_out'", clear
local dl = char(92) + char(36)
file open fh using "${DESCRIPTIVE}/Tables/gini_by_year.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Gini coefficient by measure and year}" _n "\label{tab:gini_by_year}" _n "\begin{tabular}{llrrr}\toprule" _n "Measure & Year & Gini & Obs & Total (sum `dl') \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local m = measure[`r']
    if "`m'" == "labor_income_real_win" local m "Labor income (real, win)"
    if "`m'" == "total_income_real_win" local m "Total income (real, win)"
    if "`m'" == "wealth_core" local m "Wealth core"
    if "`m'" == "wealth_ira" local m "Wealth IRA"
    if "`m'" == "wealth_coreira" local m "Wealth Core+ret."
    if "`m'" == "wealth_res" local m "Wealth residential"
    if "`m'" == "wealth_total" local m "Wealth total"
    if "`m'" == "gross_wealth" local m "Gross wealth"
    local yr_s = string(year[`r'], "%9.0f")
    local g_s = string(gini[`r'], "%5.3f")
    local o_s = string(obs[`r'], "%9.0fc")
    local t_s = string(total_sum[`r'], "%12.0fc")
    file write fh "`m' & `yr_s' & `g_s' & `o_s' & `t_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{5}{l}{\footnotesize Total = sum of variable in wave. Income in real USD, winsorized.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
file close fh

* Lorenz plots
use "`lorenz_all'", clear

* Labels for measures
gen str40 mlabel = ""
replace mlabel = "Labor income (real, win)" if measure == "labor_income_real_win"
replace mlabel = "Total income (real, win)" if measure == "total_income_real_win"
replace mlabel = "Wealth core" if measure == "wealth_core"
replace mlabel = "Wealth IRA" if measure == "wealth_ira"
replace mlabel = "Wealth Core+ret." if measure == "wealth_coreira"
replace mlabel = "Wealth residential" if measure == "wealth_res"
replace mlabel = "Wealth total" if measure == "wealth_total"
replace mlabel = "Gross wealth" if measure == "gross_wealth"

* Income Lorenz: one graph per year (2002 and 2022 separately)
twoway line cum_share cum_pop if year==2002 & measure=="labor_income_real_win", lcolor(navy) || ///
       line cum_share cum_pop if year==2002 & measure=="total_income_real_win", lcolor(blue) ///
       , title("Lorenz curves: income (2002)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Labor income" 2 "Total income"))
graph export "${DESCRIPTIVE}/Figures/lorenz_income_2002.png", replace

twoway line cum_share cum_pop if year==2022 & measure=="labor_income_real_win", lcolor(navy) || ///
       line cum_share cum_pop if year==2022 & measure=="total_income_real_win", lcolor(blue) ///
       , title("Lorenz curves: income (2022)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Labor income" 2 "Total income"))
graph export "${DESCRIPTIVE}/Figures/lorenz_income_2022.png", replace

* Wealth Lorenz: (1) components = core, IRA, residential; (2) aggregated = core, Core+ret., net wealth
* Components (core, IRA, residential)
twoway line cum_share cum_pop if year==2002 & measure=="wealth_core", lcolor(maroon) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_ira", lcolor(red) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_res", lcolor(orange) ///
       , title("Lorenz curves: wealth components (2002)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Core" 2 "Retirement (IRA)" 3 "Residential"))
graph export "${DESCRIPTIVE}/Figures/lorenz_wealth_components_2002.png", replace

twoway line cum_share cum_pop if year==2022 & measure=="wealth_core", lcolor(maroon) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_ira", lcolor(red) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_res", lcolor(orange) ///
       , title("Lorenz curves: wealth components (2022)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Core" 2 "Retirement (IRA)" 3 "Residential"))
graph export "${DESCRIPTIVE}/Figures/lorenz_wealth_components_2022.png", replace

* Aggregated (core, Core+ret., net wealth)
twoway line cum_share cum_pop if year==2002 & measure=="wealth_core", lcolor(maroon) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_coreira", lcolor(magenta) || ///
       line cum_share cum_pop if year==2002 & measure=="wealth_total", lcolor(green) ///
       , title("Lorenz curves: wealth aggregated (2002)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Core" 2 "Core+ret." 3 "Net wealth"))
graph export "${DESCRIPTIVE}/Figures/lorenz_wealth_agg_2002.png", replace

twoway line cum_share cum_pop if year==2022 & measure=="wealth_core", lcolor(maroon) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_coreira", lcolor(magenta) || ///
       line cum_share cum_pop if year==2022 & measure=="wealth_total", lcolor(green) ///
       , title("Lorenz curves: wealth aggregated (2022)") xtitle("Cumulative population share") ytitle("Cumulative share") ///
       legend(order(1 "Core" 2 "Core+ret." 3 "Net wealth"))
graph export "${DESCRIPTIVE}/Figures/lorenz_wealth_agg_2022.png", replace
