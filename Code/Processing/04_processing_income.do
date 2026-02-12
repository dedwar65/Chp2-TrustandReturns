* 04_processing_income.do
* Process respondent income measures in wide form (deflate/log/trim/winsorize).
* Input: ${PROCESSED}/analysis_ready.dta
* Output: ${PROCESSED}/analysis_ready_processed.dta

clear
set more off

capture log close
log using "${LOG_DIR}/04_processing_income.log", replace text

use "${PROCESSED}/analysis_ready.dta", clear

* Keep all variables; only modify income series below

* Require income series to exist
capture unab _lab_any : labor_income_*
if _rc {
    display as error "04: labor_income_* not found in analysis_ready.dta. Run 02_compute_returns_income.do and 03_prep_controls.do first."
    log close
    exit 0
}
capture unab _tot_any : total_income_*
if _rc {
    display as error "04: total_income_* not found in analysis_ready.dta. Run 02_compute_returns_income.do and 03_prep_controls.do first."
    log close
    exit 0
}

* Year list (even years, 2000–2022)
local years "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"

* Ensure income stubs exist and build varlists
local labvars ""
local totvars ""
foreach y of local years {
    capture confirm variable labor_income_`y'
    if _rc {
        gen double labor_income_`y' = .
    }
    capture confirm variable total_income_`y'
    if _rc {
        gen double total_income_`y' = .
    }
    local labvars "`labvars' labor_income_`y'"
    local totvars "`totvars' total_income_`y'"
}

* ---------------------------------------------------------------------
* Deflate to 2021 dollars using CPI (CPIAUCSL.csv from FRED)
* ---------------------------------------------------------------------
display "=== Deflation to 2021 dollars ==="
tempfile cpi
preserve
import delimited "${FRED_DATA}/CPIAUCSL.csv", clear
capture confirm variable date
if _rc {
    capture confirm variable DATE
    if !_rc rename DATE date
}
capture confirm variable CPIAUCSL
if _rc {
    capture confirm variable cpiaucsl
    if !_rc rename cpiaucsl CPIAUCSL
}
gen year = real(substr(date,1,4))
collapse (mean) CPIAUCSL, by(year)
rename CPIAUCSL cpi
save "`cpi'", replace

quietly summarize cpi if year == 2021
local cpi_2021 = r(mean)
foreach y of local years {
    quietly summarize cpi if year == `y'
    local cpi_`y' = r(mean)
}
restore

display "Tabstat income before deflation"
tabstat `labvars' `totvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local labreal ""
local totreal ""
foreach y of local years {
    local cpi_y = `cpi_`y''
    capture drop labor_income_real_`y' total_income_real_`y'
    if "`cpi_y'" != "" {
        gen double labor_income_real_`y' = labor_income_`y' * (`cpi_2021' / `cpi_y')
        gen double total_income_real_`y' = total_income_`y' * (`cpi_2021' / `cpi_y')
    }
    else {
        gen double labor_income_real_`y' = .
        gen double total_income_real_`y' = .
    }
    local labreal "`labreal' labor_income_real_`y'"
    local totreal "`totreal' total_income_real_`y'"
}

display "Tabstat income after deflation"
tabstat `labreal' `totreal', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Winsorize deflated levels (separate toggle on deflated series)
* ---------------------------------------------------------------------
display "=== 1% winsorization on deflated levels ==="
display "Tabstat deflated income before winsorization"
tabstat `labreal' `totreal', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local labrealwin ""
local totrealwin ""
foreach y of local years {
    quietly summarize labor_income_real_`y', detail
    local p1_lab = r(p1)
    local p99_lab = r(p99)
    capture drop labor_income_real_win_`y'
    gen double labor_income_real_win_`y' = labor_income_real_`y'
    replace labor_income_real_win_`y' = `p1_lab' if labor_income_real_win_`y' < `p1_lab' & !missing(labor_income_real_win_`y')
    replace labor_income_real_win_`y' = `p99_lab' if labor_income_real_win_`y' > `p99_lab' & !missing(labor_income_real_win_`y')

    quietly summarize total_income_real_`y', detail
    local p1_tot = r(p1)
    local p99_tot = r(p99)
    capture drop total_income_real_win_`y'
    gen double total_income_real_win_`y' = total_income_real_`y'
    replace total_income_real_win_`y' = `p1_tot' if total_income_real_win_`y' < `p1_tot' & !missing(total_income_real_win_`y')
    replace total_income_real_win_`y' = `p99_tot' if total_income_real_win_`y' > `p99_tot' & !missing(total_income_real_win_`y')

    * Persist deflated + winsorized income and derived transforms
    capture drop lab_inc_defl_win_`y' tot_inc_defl_win_`y'
    gen double lab_inc_defl_win_`y' = labor_income_real_win_`y'
    gen double tot_inc_defl_win_`y' = total_income_real_win_`y'

    capture drop ln_lab_inc_defl_win_`y' ln_tot_inc_defl_win_`y'
    gen double ln_lab_inc_defl_win_`y' = ln(lab_inc_defl_win_`y') if lab_inc_defl_win_`y' > 0
    gen double ln_tot_inc_defl_win_`y' = ln(tot_inc_defl_win_`y') if tot_inc_defl_win_`y' > 0

    * Scaled asinh: asinh(x / median_positive_x) for deflated + winsorized levels
    quietly summarize lab_inc_defl_win_`y' if lab_inc_defl_win_`y' > 0, detail
    local med_lab_dw = r(p50)
    local N_pos_lab_dw = r(N)
    capture drop ihs_lab_inc_defl_win_s_`y'
    gen double ihs_lab_inc_defl_win_s_`y' = .
    if `N_pos_lab_dw' > 0 & `med_lab_dw' > 0 {
        replace ihs_lab_inc_defl_win_s_`y' = asinh(lab_inc_defl_win_`y' / `med_lab_dw') if !missing(lab_inc_defl_win_`y')
    }

    quietly summarize tot_inc_defl_win_`y' if tot_inc_defl_win_`y' > 0, detail
    local med_tot_dw = r(p50)
    local N_pos_tot_dw = r(N)
    capture drop ihs_tot_inc_defl_win_s_`y'
    gen double ihs_tot_inc_defl_win_s_`y' = .
    if `N_pos_tot_dw' > 0 & `med_tot_dw' > 0 {
        replace ihs_tot_inc_defl_win_s_`y' = asinh(tot_inc_defl_win_`y' / `med_tot_dw') if !missing(tot_inc_defl_win_`y')
    }

    local labrealwin "`labrealwin' labor_income_real_win_`y'"
    local totrealwin "`totrealwin' total_income_real_win_`y'"
}

display "Tabstat deflated income after winsorization"
tabstat `labrealwin' `totrealwin', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Log income (separate toggle on original series)
* ---------------------------------------------------------------------
display "=== Log income (original series) ==="
display "Tabstat income before logs"
tabstat `labvars' `totvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local lablog ""
local totlog ""
foreach y of local years {
    capture drop ln_lab_inc_`y' ln_tot_inc_`y'
    gen double ln_lab_inc_`y' = ln(labor_income_`y') if labor_income_`y' > 0
    gen double ln_tot_inc_`y' = ln(total_income_`y') if total_income_`y' > 0
    local lablog "`lablog' ln_lab_inc_`y'"
    local totlog "`totlog' ln_tot_inc_`y'"
}

display "Tabstat log income after logs"
tabstat `lablog' `totlog', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Trim top/bottom 1% on levels (separate toggle on original series)
* ---------------------------------------------------------------------
display "=== 1% trimming on levels (original series) ==="
display "Tabstat income before trimming"
tabstat `labvars' `totvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local labtrim ""
local tottrim ""
foreach y of local years {
    quietly summarize labor_income_`y', detail
    local p1_lab = r(p1)
    local p99_lab = r(p99)
    capture drop labor_income_trim_`y'
    gen double labor_income_trim_`y' = labor_income_`y'
    replace labor_income_trim_`y' = . if labor_income_trim_`y' < `p1_lab' | labor_income_trim_`y' > `p99_lab'

    quietly summarize total_income_`y', detail
    local p1_tot = r(p1)
    local p99_tot = r(p99)
    capture drop total_income_trim_`y'
    gen double total_income_trim_`y' = total_income_`y'
    replace total_income_trim_`y' = . if total_income_trim_`y' < `p1_tot' | total_income_trim_`y' > `p99_tot'

    local labtrim "`labtrim' labor_income_trim_`y'"
    local tottrim "`tottrim' total_income_trim_`y'"
}

display "Tabstat income after trimming"
tabstat `labtrim' `tottrim', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Winsorize top/bottom 1% on levels (separate toggle on original series)
* ---------------------------------------------------------------------
display "=== 1% winsorization on levels (original series) ==="
display "Tabstat income before winsorization"
tabstat `labvars' `totvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local labwin ""
local totwin ""
foreach y of local years {
    quietly summarize labor_income_`y', detail
    local p1_lab = r(p1)
    local p99_lab = r(p99)
    capture drop labor_income_win_`y'
    gen double labor_income_win_`y' = labor_income_`y'
    replace labor_income_win_`y' = `p1_lab' if labor_income_win_`y' < `p1_lab' & !missing(labor_income_win_`y')
    replace labor_income_win_`y' = `p99_lab' if labor_income_win_`y' > `p99_lab' & !missing(labor_income_win_`y')

    quietly summarize total_income_`y', detail
    local p1_tot = r(p1)
    local p99_tot = r(p99)
    capture drop total_income_win_`y'
    gen double total_income_win_`y' = total_income_`y'
    replace total_income_win_`y' = `p1_tot' if total_income_win_`y' < `p1_tot' & !missing(total_income_win_`y')
    replace total_income_win_`y' = `p99_tot' if total_income_win_`y' > `p99_tot' & !missing(total_income_win_`y')

    local labwin "`labwin' labor_income_win_`y'"
    local totwin "`totwin' total_income_win_`y'"
}

display "Tabstat income after winsorization"
tabstat `labwin' `totwin', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Final toggle (apply all: deflate -> log -> winsorize)
* ---------------------------------------------------------------------
display "=== Final toggle: deflate->log->winsorize ==="
display "Tabstat income before final toggle (original series)"
tabstat `labvars' `totvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local labfinal ""
local totfinal ""
foreach y of local years {
    * Start from deflated series
    capture confirm variable labor_income_real_`y'
    if _rc {
        gen double labor_income_real_`y' = labor_income_`y' * (`cpi_2021' / `cpi_`y'')
    }
    capture confirm variable total_income_real_`y'
    if _rc {
        gen double total_income_real_`y' = total_income_`y' * (`cpi_2021' / `cpi_`y'')
    }

    * Log: use ln(x) for x > 0; zero income set to missing (dropped from log-income sample, N reflects this)
    capture drop ln_lab_inc_final_`y' ln_tot_inc_final_`y'
    gen double ln_lab_inc_final_`y' = ln(labor_income_real_`y') if labor_income_real_`y' > 0
    gen double ln_tot_inc_final_`y' = ln(total_income_real_`y') if total_income_real_`y' > 0

    * Winsorize on log values (p1/p99)
    quietly summarize ln_lab_inc_final_`y', detail
    local p1_lab = r(p1)
    local p99_lab = r(p99)
    replace ln_lab_inc_final_`y' = `p1_lab' if ln_lab_inc_final_`y' < `p1_lab' & !missing(ln_lab_inc_final_`y')
    replace ln_lab_inc_final_`y' = `p99_lab' if ln_lab_inc_final_`y' > `p99_lab' & !missing(ln_lab_inc_final_`y')

    quietly summarize ln_tot_inc_final_`y', detail
    local p1_tot = r(p1)
    local p99_tot = r(p99)
    replace ln_tot_inc_final_`y' = `p1_tot' if ln_tot_inc_final_`y' < `p1_tot' & !missing(ln_tot_inc_final_`y')
    replace ln_tot_inc_final_`y' = `p99_tot' if ln_tot_inc_final_`y' > `p99_tot' & !missing(ln_tot_inc_final_`y')

    local labfinal "`labfinal' ln_lab_inc_final_`y'"
    local totfinal "`totfinal' ln_tot_inc_final_`y'"
}

display "Tabstat income after final toggle (final log series)"
tabstat `labfinal' `totfinal', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Income growth from final log series (two-year differences)
* ---------------------------------------------------------------------
display "=== Income growth from final log series ==="
local labgrowth ""
local totgrowth ""
foreach y of local years {
    if `y' > 2000 {
        local yprev = `y' - 2
        capture drop ln_lab_inc_final_growth_`y' ln_tot_inc_final_growth_`y'
        gen double ln_lab_inc_final_growth_`y' = ln_lab_inc_final_`y' - ln_lab_inc_final_`yprev' ///
            if !missing(ln_lab_inc_final_`y') & !missing(ln_lab_inc_final_`yprev')
        gen double ln_tot_inc_final_growth_`y' = ln_tot_inc_final_`y' - ln_tot_inc_final_`yprev' ///
            if !missing(ln_tot_inc_final_`y') & !missing(ln_tot_inc_final_`yprev')
        local labgrowth "`labgrowth' ln_lab_inc_final_growth_`y'"
        local totgrowth "`totgrowth' ln_tot_inc_final_growth_`y'"
    }
}
display "Tabstat income growth (final log series)"
tabstat `labgrowth' `totgrowth', statistics(n mean sd p1 p5 p50 p95 p99 min max)

save "${PROCESSED}/analysis_ready_processed.dta", replace
display "04_processing_income: Saved ${PROCESSED}/analysis_ready_processed.dta"

log close
