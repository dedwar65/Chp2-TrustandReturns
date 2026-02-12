* 09_robustness_returns_trust.do
* Robustness scatterplots: trust vs returns (r1, r4, r5) under different outlier treatments.
* - Uses ${PROCESSED}/analysis_ready_processed.dta
* - Does NOT save new variables to disk; all transformations are within preserve/restore.
* - Outputs graphs to ${DESCRIPTIVE}/Figures/Robustness/.

clear
set more off

* Ensure base path and config (same pattern as other descriptive scripts)
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
log using "${LOG_DIR}/09_robustness_returns_trust.log", replace text

use "${PROCESSED}/analysis_ready_processed.dta", clear

* Check required variables
capture confirm variable trust_others_2020
if _rc {
    display as error "trust_others_2020 not found; cannot build trust-return robustness plots."
    log close
    exit 0
}

capture mkdir "${DESCRIPTIVE}"
capture mkdir "${DESCRIPTIVE}/Figures"
capture mkdir "${DESCRIPTIVE}/Figures/Robustness"
capture mkdir "${DESCRIPTIVE}/Tables"
capture mkdir "${DESCRIPTIVE}/Tables/Robustness"

* ---------------------------------------------------------------------
* Trust vs age (5-year bins): mean general trust by age bin
* ---------------------------------------------------------------------
display "=== Robustness: mean general trust by 5-year age bins ==="
preserve
keep hhidpn age_2020 trust_others_2020
drop if missing(age_2020) | missing(trust_others_2020)
gen int age_bin = floor(age_2020/5)*5
collapse (mean) trust_mean=trust_others_2020 (count) n=trust_others_2020, by(age_bin)
twoway connected trust_mean age_bin, mcolor(navy) lcolor(navy) msymbol(o) ///
    title("Mean trust by age (5-year bins)") xtitle("Age bin") ytitle("Mean general trust") ylabel(, angle(0))
graph export "${DESCRIPTIVE}/Figures/Robustness/trust_mean_by_age_bin.png", replace
restore

display "=== Robustness: trust vs returns (r1, r4, r5; 5% winsor, 1%/5% trims) ==="

* List of base returns (2022) to analyze
local retlist "r1_annual_2022 r4_annual_2022 r5_annual_2022"

foreach v of local retlist {
    capture confirm variable `v'
    if _rc {
        display as txt "Skipping `v' (not found)."
        continue
    }

    preserve
    * Work only on observations with both trust and this return
    keep if !missing(`v') & !missing(trust_others_2020)

    quietly summarize `v', detail
    local p1  = r(p1)
    local p5  = r(p5)
    local p95 = r(p95)
    local p99 = r(p99)

    * 5% winsorized version
    capture drop `v'_w5
    gen double `v'_w5 = `v'
    replace `v'_w5 = `p5'  if `v'_w5 < `p5'  & !missing(`v'_w5)
    replace `v'_w5 = `p95' if `v'_w5 > `p95' & !missing(`v'_w5)

    * 1% trimmed version
    capture drop `v'_t1
    gen double `v'_t1 = `v'
    replace `v'_t1 = . if (`v'_t1 < `p1' | `v'_t1 > `p99') & !missing(`v'_t1)

    * 5% trimmed version
    capture drop `v'_t5
    gen double `v'_t5 = `v'
    replace `v'_t5 = . if (`v'_t5 < `p5' | `v'_t5 > `p95') & !missing(`v'_t5)

    * Short label for the base return (for titles)
    local vlabel "`v'"
    if "`v'" == "r1_annual_2022" local vlabel "Core return (2022)"
    if "`v'" == "r4_annual_2022" local vlabel "Core+ret. return (2022)"
    if "`v'" == "r5_annual_2022" local vlabel "Net wealth return (2022)"

    * -----------------------------------------------------------------
    * Tabstat-style summary for raw and transformed versions
    * -----------------------------------------------------------------
    file open fh using "${DESCRIPTIVE}/Tables/Robustness/robust_tabstat_`v'.tex", write replace
    file write fh "\begin{table}[htbp]\centering" _n ///
        "\caption{Return robustness summary: `vlabel'}" _n ///
        "\label{tab:robust_tabstat_`v'}" _n ///
        "\begin{tabular}{lrrrrrrrrrr}\toprule" _n ///
        "Series & N & Mean & SD & P1 & P5 & P50 & P95 & P99 & Min & Max \\\\ \midrule" _n

    foreach s in raw w5 t1 t5 {
        local svar ""
        local slabel ""
        if "`s'"=="raw" {
            local svar "`v'"
            local slabel "Raw"
        }
        if "`s'"=="w5" {
            local svar "`v'_w5"
            local slabel "5\% winsor"
        }
        if "`s'"=="t1" {
            local svar "`v'_t1"
            local slabel "1\% trim"
        }
        if "`s'"=="t5" {
            local svar "`v'_t5"
            local slabel "5\% trim"
        }
        capture confirm variable `svar'
        if _rc continue
        quietly summarize `svar', detail
        if r(N) == 0 continue
        local n_s   = string(r(N),   "%9.0f")
        local m_s   = string(r(mean),"%9.3f")
        local sd_s  = string(r(sd),  "%9.3f")
        local p1_s  = string(r(p1),  "%9.3f")
        local p5_s  = string(r(p5),  "%9.3f")
        local p50_s = string(r(p50), "%9.3f")
        local p95_s = string(r(p95), "%9.3f")
        local p99_s = string(r(p99), "%9.3f")
        local min_s = string(r(min), "%9.3f")
        local max_s = string(r(max), "%9.3f")
        file write fh "`slabel' & `n_s' & `m_s' & `sd_s' & `p1_s' & `p5_s' & `p50_s' & `p95_s' & `p99_s' & `min_s' & `max_s' \\\\" _n
    }

    file write fh "\bottomrule" _n "\multicolumn{11}{l}{\footnotesize Based on 2022 observations with nonmissing trust and returns.} \\\\" _n "\end{tabular}\end{table}" _n
    file close fh

    * 5% winsorized scatter
    twoway scatter `v'_w5 trust_others_2020, ///
        title("`vlabel' vs trust (5% winsorized)") ///
        xtitle("General trust (2020)") ///
        ytitle("`vlabel' (5% winsorized)")
    graph export "${DESCRIPTIVE}/Figures/Robustness/`v'_w5_vs_trust_2022.png", replace

    * 1% trimmed scatter
    twoway scatter `v'_t1 trust_others_2020, ///
        title("`vlabel' vs trust (1% trimmed)") ///
        xtitle("General trust (2020)") ///
        ytitle("`vlabel' (1% trimmed)")
    graph export "${DESCRIPTIVE}/Figures/Robustness/`v'_t1_vs_trust_2022.png", replace

    * 5% trimmed scatter
    twoway scatter `v'_t5 trust_others_2020, ///
        title("`vlabel' vs trust (5% trimmed)") ///
        xtitle("General trust (2020)") ///
        ytitle("`vlabel' (5% trimmed)")
    graph export "${DESCRIPTIVE}/Figures/Robustness/`v'_t5_vs_trust_2022.png", replace

    * -----------------------------------------------------------------
    * Histograms for raw and transformed versions (aggregated returns)
    * -----------------------------------------------------------------
    foreach s in raw w5 t1 t5 {
        local svar ""
        local slabel ""
        if "`s'"=="raw" {
            local svar "`v'"
            local slabel "`vlabel' (raw)"
        }
        if "`s'"=="w5" {
            local svar "`v'_w5"
            local slabel "`vlabel' (5\% winsorized)"
        }
        if "`s'"=="t1" {
            local svar "`v'_t1"
            local slabel "`vlabel' (1\% trimmed)"
        }
        if "`s'"=="t5" {
            local svar "`v'_t5"
            local slabel "`vlabel' (5\% trimmed)"
        }
        capture confirm variable `svar'
        if _rc continue
        histogram `svar', ///
            title("Histogram: `slabel'") ///
            xtitle("`slabel'") ///
            ytitle("Frequency")
        graph export "${DESCRIPTIVE}/Figures/Robustness/`svar'_hist_2022.png", replace
    }

    restore
}

* ---------------------------------------------------------------------
* Labor income vs trust (2022): robustness transforms (7 panels)
* ---------------------------------------------------------------------
display "=== Robustness: labor income vs trust (2022) ==="

preserve

* Load raw data with income components
use "${CLEANED}/all_data_merged.dta", clear

* Compute CPI 2021 and 2022 from CPIAUCSL (same source as main pipeline)
tempfile adata
save "`adata'", replace
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
quietly summarize cpi if year == 2021
local cpi_2021 = r(mean)
quietly summarize cpi if year == 2022
local cpi_2022 = r(mean)
use "`adata'", clear

* Keep 2022 observations only (if year variable exists)
capture confirm variable year
if !_rc keep if year == 2022

* Labor income (2022): earnings + unemployment, missing only if both missing
capture drop labor_income_2022
capture confirm variable r16iearn r16iunwc
if _rc {
    display as error "r16iearn or r16iunwc not found; cannot build labor-income robustness plots."
    restore
}
gen double labor_income_2022 = r16iearn + cond(missing(r16iunwc), 0, r16iunwc)
replace labor_income_2022 = . if missing(r16iearn) & missing(r16iunwc)

* Deflated labor income (2021 dollars)
gen double labor_defl_2022 = .
if "`cpi_2021'" != "" & "`cpi_2022'" != "" {
    replace labor_defl_2022 = labor_income_2022 * (`cpi_2021' / `cpi_2022')
}

* Winsorize deflated labor income (p1/p99)
capture drop labor_defl_win_2022
gen double labor_defl_win_2022 = labor_defl_2022
quietly summarize labor_defl_2022, detail
local p1_lab = r(p1)
local p99_lab = r(p99)
replace labor_defl_win_2022 = `p1_lab' if labor_defl_win_2022 < `p1_lab' & !missing(labor_defl_win_2022)
replace labor_defl_win_2022 = `p99_lab' if labor_defl_win_2022 > `p99_lab' & !missing(labor_defl_win_2022)

* Income transforms for 2022
capture drop labor_raw_2022 labor_defl_win_ln_2022 labor_defl_win_ln1p_2022 ///
    labor_defl_win_asinh_2022 labor_defl_win_asinh_s_2022
gen double labor_raw_2022 = labor_income_2022
gen double labor_defl_win_ln_2022 = .
replace labor_defl_win_ln_2022 = ln(labor_defl_win_2022) if labor_defl_win_2022 > 0
gen double labor_defl_win_ln1p_2022 = ln(1 + labor_defl_win_2022) if !missing(labor_defl_win_2022)
gen double labor_defl_win_asinh_2022 = asinh(labor_defl_win_2022) if !missing(labor_defl_win_2022)

* Scaled asinh: asinh(x / median_positive_x)
quietly summarize labor_defl_win_2022 if labor_defl_win_2022 > 0, detail
local med_lab = r(p50)
local N_pos = r(N)
gen double labor_defl_win_asinh_s_2022 = .
if `N_pos' > 0 & `med_lab' > 0 {
    replace labor_defl_win_asinh_s_2022 = asinh(labor_defl_win_2022 / `med_lab') if !missing(labor_defl_win_2022)
}

* Reduce to one row per person and save to tempfile
keep hhidpn labor_raw_2022 labor_defl_2022 labor_defl_win_2022 ///
    labor_defl_win_ln_2022 labor_defl_win_ln1p_2022 ///
    labor_defl_win_asinh_2022 labor_defl_win_asinh_s_2022
drop if missing(hhidpn)
duplicates drop hhidpn, force
tempfile li2022
save "`li2022'", replace

* Merge trust from processed dataset
use "${PROCESSED}/analysis_ready_processed.dta", clear
keep hhidpn trust_others_2020
drop if missing(hhidpn)
duplicates drop hhidpn, force
merge 1:1 hhidpn using "`li2022'", nogen keep(match)

* Overlap counts for each transform with trust
local tvars "labor_raw_2022 labor_defl_2022 labor_defl_win_2022 labor_defl_win_ln_2022 labor_defl_win_ln1p_2022 labor_defl_win_asinh_2022 labor_defl_win_asinh_s_2022"
local tnames "Raw Deflated Deflated+Winsor Deflated+Winsor+ln(x) Deflated+Winsor+ln(1+x) Deflated+Winsor+asinh(x) Deflated+Winsor+asinh(x/median+)"

display "=== Overlap N (income transform, trust nonmissing, 2022) ==="
local i = 1
foreach v of local tvars {
    local tname : word `i' of `tnames'
    quietly count if !missing(`v') & !missing(trust_others_2020)
    display "`tname': N = " r(N)
    local ++i
}

* Build 7 scatter panels and combine
forvalues i = 1/7 {
    local v : word `i' of `tvars'
    local stitle ""
    if `i' == 1 local stitle "Raw"
    if `i' == 2 local stitle "Deflated"
    if `i' == 3 local stitle "Deflated + Winsor"
    if `i' == 4 local stitle "Deflated + Winsor + ln(x)"
    if `i' == 5 local stitle "Deflated + Winsor + ln(1+x)"
    if `i' == 6 local stitle "Deflated + Winsor + asinh(x)"
    if `i' == 7 local stitle "Deflated + Winsor + asinh(x/median+)"
    local gname "g`i'"
    twoway scatter `v' trust_others_2020 if !missing(`v') & !missing(trust_others_2020), ///
        msize(vsmall) mcolor(navy%40) ///
        xtitle("General trust (2020)") ///
        ytitle("Income transform value") ///
        title("`stitle'") ///
        name(`gname', replace)
}

graph combine g1 g2 g3 g4 g5 g6 g7, cols(3) ///
    title("Labor income vs trust (2022)")
graph export "${DESCRIPTIVE}/Figures/Robustness/labor_income_trust_all_toggles_2022.png", replace

restore

log close

