* 28_more_descriptive_stats.do
* Pooled descriptive statistics for portfolio shares/leverage (net-wealth focus).
* Output:
*   - ${REGRESSIONS}/Other/summary_portfolios.tex
*   - ${REGRESSIONS}/Other/asset_shares_by_wealth_frac.tex
*   - ${REGRESSIONS}/Other/port_shares_by_wealth_frac.tex
*   - ${REGRESSIONS}/Other/returns_portfolio_moments_pooled.tex

clear
set more off

* Ensure paths
capture confirm global BASE_PATH
if _rc {
    while regexm("`c(pwd)'", "[\\/]Code[\\/]") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\\/]HRS$") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\\/]Raw data$") {
        cd ..
        cd ..
    }
    if regexm("`c(pwd)'", "[\\/]Code$") {
        cd ..
    }
    global BASE_PATH "`c(pwd)'"
    do "${BASE_PATH}/Code/Raw data/00_config.do"
}

capture mkdir "${REGRESSIONS}/Other"
capture log close
log using "${LOG_DIR}/28_more_descriptive_stats.log", replace text

use "${PROCESSED}/analysis_ready_processed.dta", clear

* Keep needed stubs (wide -> long pooled person-year)
keep hhidpn ///
    wealth_total_* gross_wealth_* ///
    share_bus_* share_stk_* share_bond_* share_chck_* share_re_* share_fin_* ///
    share_core_* share_ira_* share_res_* ///
    share_debt_long_* share_debt_other_* share_debt_amort_* share_debt_ahmln_*

reshape long ///
    wealth_total_ gross_wealth_ ///
    share_bus_ share_stk_ share_bond_ share_chck_ share_re_ share_fin_ ///
    share_core_ share_ira_ share_res_ ///
    share_debt_long_ share_debt_other_ share_debt_amort_ share_debt_ahmln_, i(hhidpn) j(year)

rename wealth_total_      wealth_total
rename gross_wealth_      gross_wealth
rename share_bus_         share_bus
rename share_stk_         share_stk
rename share_bond_        share_bond
rename share_chck_        share_chck
rename share_re_          share_re
rename share_fin_         share_fin
rename share_core_        share_core
rename share_ira_         share_ira
rename share_res_         share_res
rename share_debt_long_   share_debt_long
rename share_debt_other_  share_debt_other
rename share_debt_amort_  share_debt_amort
rename share_debt_ahmln_  share_debt_ahmln

* Broad aggregates
gen double share_core_ret = share_core + share_ira if !missing(share_core) & !missing(share_ira)
gen double share_core_ret_res = share_core + share_ira + share_res if !missing(share_core) & !missing(share_ira) & !missing(share_res)
gen double leverage_total = share_debt_long + share_debt_other if !missing(share_debt_long) & !missing(share_debt_other)
gen double share_safe = share_bond + share_chck if !missing(share_bond) | !missing(share_chck)

* Participation indicators (narrow assets first; core last among broad assets)
gen byte part_bus       = share_bus  > 0 if !missing(share_bus)
gen byte part_stk       = share_stk  > 0 if !missing(share_stk)
gen byte part_safe      = share_safe > 0 if !missing(share_safe)
gen byte part_re        = share_re   > 0 if !missing(share_re)
gen byte part_ira       = share_ira  > 0 if !missing(share_ira)
gen byte part_res       = share_res  > 0 if !missing(share_res)
gen byte part_core      = share_core > 0 if !missing(share_core)
gen byte part_debt_long = share_debt_long > 0 if !missing(share_debt_long)
gen byte part_debt_other= share_debt_other > 0 if !missing(share_debt_other)
gen byte part_debt_any  = leverage_total > 0 if !missing(leverage_total)

* Table 1: Pooled Panel-D style stats (means, dispersion, tails)
* ---------------------------------------------------------------------
tempfile pooled_stats
postfile H1 str50 stat double mean sd p1 p50 p99 long N using "`pooled_stats'", replace

local rows ///
    part_bus part_stk part_safe part_re part_ira part_res part_core ///
    part_debt_long part_debt_other part_debt_any ///
    share_bus share_stk share_safe share_re share_ira share_res share_core ///
    share_core_ret ///
    share_debt_long share_debt_other leverage_total

foreach v of local rows {
    quietly summarize `v', detail
    if r(N) > 0 {
        post H1 ("`v'") (r(mean)) (r(sd)) (r(p1)) (r(p50)) (r(p99)) (r(N))
    }
}
postclose H1

use "`pooled_stats'", clear

replace stat = "Fraction with business assets"               if stat=="part_bus"
replace stat = "Fraction with stocks assets"                 if stat=="part_stk"
replace stat = "Fraction with safe assets"                   if stat=="part_safe"
replace stat = "Fraction with other real estate assets"      if stat=="part_re"
replace stat = "Fraction with retirement assets"             if stat=="part_ira"
replace stat = "Fraction with residential assets"            if stat=="part_res"
replace stat = "Fraction with core assets"                   if stat=="part_core"
replace stat = "Fraction with long-term debt"                if stat=="part_debt_long"
replace stat = "Fraction with other debt"                    if stat=="part_debt_other"
replace stat = "Fraction with some debt"                     if stat=="part_debt_any"
replace stat = "Share in private business"                   if stat=="share_bus"
replace stat = "Share in stocks/mutual funds"               if stat=="share_stk"
replace stat = "Share in safe assets"                        if stat=="share_safe"
replace stat = "Share in other real estate"                  if stat=="share_re"
replace stat = "Share in retirement assets"                  if stat=="share_ira"
replace stat = "Share in residential assets"                 if stat=="share_res"
replace stat = "Share in core assets"                        if stat=="share_core"
replace stat = "Share in core and retirement assets"         if stat=="share_core_ret"
replace stat = "Leverage, Long-term debt"                    if stat=="share_debt_long"
replace stat = "Leverage, Other debt"                        if stat=="share_debt_other"
replace stat = "Leverage, Total debt"                        if stat=="leverage_total"

file open fh1 using "${REGRESSIONS}/Other/summary_portfolios.tex", write replace
file write fh1 "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Participation and portfolio composition}" _n ///
    "\label{tab:summary_portfolios}" _n ///
    "\begin{tabular}{lrrrrrr}\toprule" _n ///
    "Statistic & Mean & SD & P1 & P50 & P99 & Obs \\\\ \midrule" _n

forvalues r = 1/`=_N' {
    local s   = stat[`r']
    local m   = string(mean[`r'], "%6.3f")
    local sdv = string(sd[`r'], "%6.3f")
    local p1v = string(p1[`r'], "%6.3f")
    local p50v= string(p50[`r'], "%6.3f")
    local p99v= string(p99[`r'], "%6.3f")
    local nv  = string(N[`r'], "%12.0fc")
    file write fh1 "`s' & `m' & `sdv' & `p1v' & `p50v' & `p99v' & `nv' \\\\" _n
}

file write fh1 "\bottomrule" _n ///
    "\end{tabular}" _n ///
    "\end{table}" _n
file close fh1

* ---------------------------------------------------------------------
* Table 2A: Within-core composition by pooled core-wealth fractiles
* ---------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
keep hhidpn wealth_core_* share_bus_* share_stk_* share_bond_* share_chck_* share_re_* share_debt_amort_* share_debt_ahmln_* share_debt_other_*

reshape long wealth_core_ share_bus_ share_stk_ share_bond_ share_chck_ share_re_ share_debt_amort_ share_debt_ahmln_ share_debt_other_, i(hhidpn) j(year)

rename wealth_core_      wealth_core
rename share_bus_        share_bus
rename share_stk_        share_stk
rename share_bond_       share_bond
rename share_chck_       share_chck
rename share_re_         share_re
gen double share_safe = share_bond + share_chck if !missing(share_bond) | !missing(share_chck)

rename share_debt_amort_ share_debt_amort
rename share_debt_ahmln_ share_debt_ahmln
rename share_debt_other_ share_debt_other

keep if !missing(wealth_core)

* Percentile rank over pooled person-year sample
egen long rk = rank(wealth_core)
quietly count
local Nall = r(N)
gen double pct = 100 * (rk - 0.5) / `Nall'

gen byte fract = .
replace fract = 1 if pct < 10
replace fract = 2 if pct >= 10    & pct < 20
replace fract = 3 if pct >= 20    & pct < 50
replace fract = 4 if pct >= 50    & pct < 90
replace fract = 5 if pct >= 90    & pct < 95
replace fract = 6 if pct >= 95    & pct < 99
replace fract = 7 if pct >= 99    & pct < 99.9
replace fract = 8 if pct >= 99.9  & pct < 99.99
replace fract = 9 if pct >= 99.99

gen str20 fract_lab = ""
replace fract_lab = "Bottom 10%"      if fract==1
replace fract_lab = "10--20%"         if fract==2
replace fract_lab = "20--50%"         if fract==3
replace fract_lab = "50--90%"         if fract==4
replace fract_lab = "90--95%"         if fract==5
replace fract_lab = "95--99%"         if fract==6
replace fract_lab = "99--99.9%"       if fract==7
replace fract_lab = "99.9--99.99%"    if fract==8
replace fract_lab = "Top 0.01%"       if fract==9

collapse (mean) share_re share_bus share_stk share_safe share_debt_amort share_debt_ahmln share_debt_other (count) N=wealth_core, by(fract fract_lab)
sort fract

file open fh2a using "${REGRESSIONS}/Other/asset_shares_by_wealth_frac.tex", write replace
file write fh2a "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Asset composition by wealth}" _n ///
    "\label{tab:portfolio_comp_core_fractiles_pooled}" _n ///
    "\begin{tabular}{lrrrrrrr}\toprule" _n ///
    "Fractile & Real est. & Business & Stocks & Safe assets & Mortgage debt & Other home loans & Other debt \\\\ \midrule" _n

forvalues r = 1/`=_N' {
    local g   = fract_lab[`r']
    local g   = subinstr("`g'", "%", "\%", .)
    local re  = string(share_re[`r'], "%6.3f")
    local bus = string(share_bus[`r'], "%6.3f")
    local stk = string(share_stk[`r'], "%6.3f")
    local bnd = string(share_safe[`r'], "%6.3f")
    local am  = string(share_debt_amort[`r'], "%6.3f")
    local ah  = string(share_debt_ahmln[`r'], "%6.3f")
    local od  = string(share_debt_other[`r'], "%6.3f")
    file write fh2a "`g' & `re' & `bus' & `stk' & `bnd' & `am' & `ah' & `od' \\\\" _n
}

file write fh2a "\bottomrule" _n ///
    "\end{tabular}" _n ///
    "\end{table}" _n
file close fh2a

* ---------------------------------------------------------------------
* Table 2B: Standard asset classes by pooled net-wealth fractiles
* ---------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
keep hhidpn wealth_total_* share_core_* share_res_* share_ira_* share_debt_long_* share_debt_other_*

reshape long wealth_total_ share_core_ share_res_ share_ira_ share_debt_long_ share_debt_other_, i(hhidpn) j(year)

rename wealth_total_     wealth_total
rename share_core_       share_core
rename share_res_        share_res
rename share_ira_        share_ira
rename share_debt_long_  share_debt_long
rename share_debt_other_ share_debt_other

gen double leverage_total = share_debt_long + share_debt_other if !missing(share_debt_long) & !missing(share_debt_other)
keep if !missing(wealth_total)

egen long rk = rank(wealth_total)
quietly count
local Nall2 = r(N)
gen double pct = 100 * (rk - 0.5) / `Nall2'

gen byte fract = .
replace fract = 1 if pct < 10
replace fract = 2 if pct >= 10    & pct < 20
replace fract = 3 if pct >= 20    & pct < 50
replace fract = 4 if pct >= 50    & pct < 90
replace fract = 5 if pct >= 90    & pct < 95
replace fract = 6 if pct >= 95    & pct < 99
replace fract = 7 if pct >= 99    & pct < 99.9
replace fract = 8 if pct >= 99.9  & pct < 99.99
replace fract = 9 if pct >= 99.99

gen str20 fract_lab = ""
replace fract_lab = "Bottom 10%"      if fract==1
replace fract_lab = "10--20%"         if fract==2
replace fract_lab = "20--50%"         if fract==3
replace fract_lab = "50--90%"         if fract==4
replace fract_lab = "90--95%"         if fract==5
replace fract_lab = "95--99%"         if fract==6
replace fract_lab = "99--99.9%"       if fract==7
replace fract_lab = "99.9--99.99%"    if fract==8
replace fract_lab = "Top 0.01%"       if fract==9

collapse (mean) share_core share_res share_ira share_debt_long share_debt_other leverage_total (count) N=wealth_total, by(fract fract_lab)
sort fract

file open fh2b using "${REGRESSIONS}/Other/port_shares_by_wealth_frac.tex", write replace
file write fh2b "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Portfolio composition by wealth}" _n ///
    "\label{tab:portfolio_comp_standard_fractiles_pooled}" _n ///
    "\begin{tabular}{lrrrrrr}\toprule" _n ///
    "Fractile & Core & Residential & Retirement & Long debt & Other debt & Total debt \\\\ \midrule" _n

forvalues r = 1/`=_N' {
    local g  = fract_lab[`r']
    local g  = subinstr("`g'", "%", "\%", .)
    local c  = string(share_core[`r'], "%6.3f")
    local rs = string(share_res[`r'], "%6.3f")
    local ir = string(share_ira[`r'], "%6.3f")
    local dl = string(share_debt_long[`r'], "%6.3f")
    local do = string(share_debt_other[`r'], "%6.3f")
    local dt = string(leverage_total[`r'], "%6.3f")
    file write fh2b "`g' & `c' & `rs' & `ir' & `dl' & `do' & `dt' \\\\" _n
}

file write fh2b "\bottomrule" _n ///
    "\end{tabular}" _n ///
    "\end{table}" _n
file close fh2b

* ---------------------------------------------------------------------
* Table 4: Pooled return moments by portfolio (paper-style columns)
* ---------------------------------------------------------------------
* Raw returns table (used in manuscript)
use "${PROCESSED}/analysis_ready_processed.dta", clear
keep hhidpn r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_*
reshape long r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
rename r1_annual_ r1_annual
rename r2_annual_ r2_annual
rename r3_annual_ r3_annual
rename r4_annual_ r4_annual
rename r5_annual_ r5_annual

tempfile retmom_raw
postfile HR str30 stat double mean sd skew kurt p1 p50 p99 using "`retmom_raw'", replace
foreach r in r1_annual r3_annual r2_annual r4_annual r5_annual {
    quietly summarize `r', detail
    if r(N) > 0 post HR ("`r'") (r(mean)) (r(sd)) (r(skewness)) (r(kurtosis)) (r(p1)) (r(p50)) (r(p99))
}
postclose HR

use "`retmom_raw'", clear
replace stat = "Core assets"                    if stat=="r1_annual"
replace stat = "Residential assets"             if stat=="r3_annual"
replace stat = "Retirement assets"              if stat=="r2_annual"
replace stat = "Core and retirement assets"     if stat=="r4_annual"
replace stat = "Net wealth"                     if stat=="r5_annual"

file open fh4 using "${REGRESSIONS}/Other/returns_portfolio_moments_pooled.tex", write replace
file write fh4 "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Returns to assets/portfolios}" _n ///
    "\label{tab:returns_portfolio_moments_pooled}" _n ///
    "\begin{tabular}{lrrrrrrr}\toprule" _n ///
    "Portfolio & Mean & SD & Skewness & Kurtosis & P1 & P50 & P99 \\\\ \midrule" _n
forvalues i = 1/`=_N' {
    local s  = stat[`i']
    local m  = string(mean[`i'], "%7.4f")
    local sd = string(sd[`i'], "%7.4f")
    local sk = string(skew[`i'], "%7.2f")
    local ku = string(kurt[`i'], "%7.2f")
    local p1v = string(p1[`i'], "%7.4f")
    local p50v= string(p50[`i'], "%7.4f")
    local p99v= string(p99[`i'], "%7.4f")
    file write fh4 "`s' & `m' & `sd' & `sk' & `ku' & `p1v' & `p50v' & `p99v' \\\\" _n
    if `i'==3 file write fh4 "\addlinespace" _n
}
file write fh4 "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close fh4

* 5% winsorized companion table (for comparison only)
use "${PROCESSED}/analysis_ready_processed.dta", clear
keep hhidpn r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_*
reshape long r1_annual_ r2_annual_ r3_annual_ r4_annual_ r5_annual_, i(hhidpn) j(year)
rename r1_annual_ r1_annual
rename r2_annual_ r2_annual
rename r3_annual_ r3_annual
rename r4_annual_ r4_annual
rename r5_annual_ r5_annual

* Build 5% winsorized series inside this file (by year) so r2/r3 are included
foreach v in r1_annual r2_annual r3_annual r4_annual r5_annual {
    gen double `v'_w5 = `v'
    quietly levelsof year if !missing(`v'), local(yrs)
    foreach y of local yrs {
        quietly summarize `v' if year==`y', detail
        if r(N) > 0 {
            local p5 = r(p5)
            local p95 = r(p95)
            replace `v'_w5 = `p5'  if year==`y' & `v'_w5 < `p5'  & !missing(`v'_w5)
            replace `v'_w5 = `p95' if year==`y' & `v'_w5 > `p95' & !missing(`v'_w5)
        }
    }
}

tempfile retmom_w5
postfile HW str30 stat double mean sd skew kurt p1 p50 p99 using "`retmom_w5'", replace
foreach r in r1_annual_w5 r3_annual_w5 r2_annual_w5 r4_annual_w5 r5_annual_w5 {
    quietly summarize `r', detail
    if r(N) > 0 post HW ("`r'") (r(mean)) (r(sd)) (r(skewness)) (r(kurtosis)) (r(p1)) (r(p50)) (r(p99))
}
postclose HW

use "`retmom_w5'", clear
replace stat = "Core assets"                    if stat=="r1_annual_w5"
replace stat = "Residential assets"             if stat=="r3_annual_w5"
replace stat = "Retirement assets"              if stat=="r2_annual_w5"
replace stat = "Core and retirement assets"     if stat=="r4_annual_w5"
replace stat = "Net wealth"                     if stat=="r5_annual_w5"

file open fh4w5 using "${REGRESSIONS}/Other/returns_portfolio_moments_pooled_w5.tex", write replace
file write fh4w5 "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Returns to assets/portfolios (winsorized at 5\%)}" _n ///
    "\label{tab:returns_portfolio_moments_pooled_w5}" _n ///
    "\begin{tabular}{lrrrrrrr}\toprule" _n ///
    "Portfolio & Mean & SD & Skewness & Kurtosis & P1 & P50 & P99 \\\\ \midrule" _n
forvalues i = 1/`=_N' {
    local s  = stat[`i']
    local m  = string(mean[`i'], "%7.4f")
    local sd = string(sd[`i'], "%7.4f")
    local sk = string(skew[`i'], "%7.2f")
    local ku = string(kurt[`i'], "%7.2f")
    local p1v = string(p1[`i'], "%7.4f")
    local p50v= string(p50[`i'], "%7.4f")
    local p99v= string(p99[`i'], "%7.4f")
    file write fh4w5 "`s' & `m' & `sd' & `sk' & `ku' & `p1v' & `p50v' & `p99v' \\\\" _n
    if `i'==3 file write fh4w5 "\addlinespace" _n
}
file write fh4w5 "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close fh4w5

display "Wrote: ${REGRESSIONS}/Other/summary_portfolios.tex"
display "Wrote: ${REGRESSIONS}/Other/asset_shares_by_wealth_frac.tex"
display "Wrote: ${REGRESSIONS}/Other/port_shares_by_wealth_frac.tex"
display "Wrote: ${REGRESSIONS}/Other/returns_portfolio_moments_pooled.tex"
display "Wrote: ${REGRESSIONS}/Other/returns_portfolio_moments_pooled_w5.tex"

log close
