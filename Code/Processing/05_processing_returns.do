* 05_processing_returns.do
* Process return measures: trim and winsorize.
* Input: ${PROCESSED}/analysis_ready_processed.dta (preferred) or ${PROCESSED}/analysis_ready.dta
* Output: ${PROCESSED}/analysis_ready_processed.dta

clear
set more off

capture log close
log using "${LOG_DIR}/05_processing_returns.log", replace text

* Prefer processed dataset (to keep income processing), fallback to analysis_ready
capture confirm file "${PROCESSED}/analysis_ready_processed.dta"
if _rc {
    use "${PROCESSED}/analysis_ready.dta", clear
}
else {
    use "${PROCESSED}/analysis_ready_processed.dta", clear
}

* Returns list (waves + averages) - only keep variables that exist
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

* Stop if no return variables found
if "`retvars'" == "" {
    display as error "05: No return variables found in dataset. Run 02_compute_returns_income.do and 03_prep_controls.do first."
    log close
    exit 0
}

* ---------------------------------------------------------------------
* Trim top/bottom 1% (per return variable)
* ---------------------------------------------------------------------
display "=== 1% trimming on returns ==="
display "Tabstat returns before trimming"
tabstat `retvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local rettrim ""
foreach v of local retvars {
    capture confirm numeric variable `v'
    if !_rc {
        quietly summarize `v', detail
        local p1 = r(p1)
        local p99 = r(p99)
        capture drop `v'_trim
        gen double `v'_trim = `v'
        replace `v'_trim = . if `v'_trim < `p1' | `v'_trim > `p99'
        local rettrim "`rettrim' `v'_trim"
    }
}

display "Tabstat returns after trimming"
tabstat `rettrim', statistics(n mean sd p1 p5 p50 p95 p99 min max)

* ---------------------------------------------------------------------
* Winsorize top/bottom 1% (per return variable)
* ---------------------------------------------------------------------
display "=== 1% winsorization on returns ==="
display "Tabstat returns before winsorization"
tabstat `retvars', statistics(n mean sd p1 p5 p50 p95 p99 min max)

local retwin ""
foreach v of local retvars {
    capture confirm numeric variable `v'
    if !_rc {
        quietly summarize `v', detail
        local p1 = r(p1)
        local p99 = r(p99)
        capture drop `v'_win
        gen double `v'_win = `v'
        replace `v'_win = `p1' if `v'_win < `p1' & !missing(`v'_win)
        replace `v'_win = `p99' if `v'_win > `p99' & !missing(`v'_win)
        local retwin "`retwin' `v'_win"
    }
}

display "Tabstat returns after winsorization"
tabstat `retwin', statistics(n mean sd p1 p5 p50 p95 p99 min max)

save "${PROCESSED}/analysis_ready_processed.dta", replace
display "05_processing_returns: Saved ${PROCESSED}/analysis_ready_processed.dta"

log close
