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

log close

