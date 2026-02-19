* 08_descriptive_controls.do
* Descriptive statistics for trust, financial literacy, and IV variables.
* Input: ${PROCESSED}/analysis_ready_processed.dta
* Output: logs, tables, figures in Code/Descriptive/; trust PC1/PC2 saved to processed dataset

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
log using "${LOG_DIR}/08_descriptive_controls.log", replace text

capture mkdir "${DESCRIPTIVE}"
capture mkdir "${DESCRIPTIVE}/Figures"
capture mkdir "${DESCRIPTIVE}/Tables"

use "${PROCESSED}/analysis_ready_processed.dta", clear

* Respondent weight (optional)
local wtvar "RwWTRESP"
capture confirm variable `wtvar'
local wopt ""
if !_rc local wopt "[aw=`wtvar']"

* Label definitions for region and population size
capture label define region_lbl 1 "Northeast" 2 "Midwest" 3 "South" 4 "West" 5 "Other", replace
capture label define pop_lbl 1 "Less than 1,000" 2 "1,000 to 10,000" 3 "10,000 to 50,000" ///
    4 "50,000 to 100,000" 5 "100,000 to 1 million" 6 "Greater than 1 million" ///
    8 "DK/NA" 9 "Refused", replace
capture label define pop3_lbl 1 "Small town (<10k)" 2 "Small/med city (10k-100k)" 3 "Large metro (100k+)", replace
capture label define race_eth_lbl 1 "White (NH)" 2 "Black (NH)" 3 "Hispanic" 4 "Other (NH)", replace
foreach v of varlist censreg_* {
    capture label values `v' region_lbl
}
capture label values population_2020 pop_lbl
capture label values race_eth race_eth_lbl

* Program: return display label for variable name (for .tex tables)
program define _vlabel, rclass
    args v
    return local vlabel "`v'"
    if "`v'"=="trust_others_2020" return local vlabel "General trust"
    if "`v'"=="trust_social_security_2020" return local vlabel "Social Security"
    if "`v'"=="trust_medicare_2020" return local vlabel "Medicare"
    if "`v'"=="trust_banks_2020" return local vlabel "Banks"
    if "`v'"=="trust_advisors_2020" return local vlabel "Financial advisors"
    if "`v'"=="trust_mutual_funds_2020" return local vlabel "Mutual funds"
    if "`v'"=="trust_insurance_2020" return local vlabel "Insurance"
    if "`v'"=="trust_media_2020" return local vlabel "Media"
    if "`v'"=="depression_2020" return local vlabel "Depression"
    if "`v'"=="health_cond_2020" return local vlabel "Health conditions"
    if "`v'"=="medicare_2020" return local vlabel "Medicare"
    if "`v'"=="medicaid_2020" return local vlabel "Medicaid"
    if "`v'"=="life_ins_2020" return local vlabel "Life insurance"
    if "`v'"=="num_divorce_2020" return local vlabel "Times divorced"
    if "`v'"=="num_widow_2020" return local vlabel "Times widowed"
    if "`v'"=="age_2020" return local vlabel "Age"
    if "`v'"=="educ_yrs" return local vlabel "Years of education"
    if "`v'"=="gender" return local vlabel "Female"
    if "`v'"=="immigrant" return local vlabel "Immigrant"
    if "`v'"=="born_us" return local vlabel "Born in U.S."
    if "`v'"=="race_eth" return local vlabel "Race/ethnicity"
    if "`v'"=="married_2020" return local vlabel "Married"
    if "`v'"=="inlbrf_2020" return local vlabel "Labor force status"
    if "`v'"=="interest_2020" return local vlabel "Interest"
    if "`v'"=="inflation_2020" return local vlabel "Inflation"
    if "`v'"=="risk_div_2020" return local vlabel "Risk diversification"
    if "`v'"=="par_citizen_2020" return local vlabel "Parent citizenship"
    if "`v'"=="par_loyalty_2020" return local vlabel "Parent loyalty"
    if "`v'"=="population_2020" return local vlabel "Population size"
end

* ---------------------------------------------------------------------
* Demographics: general controls + race + employment (2020) -> demographics_general.tex
* Uses wide analysis_ready_processed.dta: one row per respondent.
* ---------------------------------------------------------------------
preserve
    keep if !missing(age_2020)
    gen byte female = (gender == 2) if !missing(gender)

    file open fh using "${DESCRIPTIVE}/Tables/demographics_general.tex", write replace
    file write fh "\begin{table}[htbp]\centering\small" _n ///
        "\caption{Demographics: general controls (2020)}" _n ///
        "\label{tab:demographics_general}" _n ///
        "\begin{tabular}{lrrr}\toprule" _n ///
        "Variable & N & Mean & SD \\\\ \midrule" _n

    * General controls (2020 sample)
    foreach v in age_2020 female educ_yrs married_2020 immigrant born_us {
        capture confirm variable `v'
        if _rc continue
        quietly summarize `v' `wopt'
        if r(N) == 0 continue
        local vlab "`v'"
        if "`v'"=="age_2020" local vlab "Age"
        if "`v'"=="female" local vlab "Female"
        if "`v'"=="educ_yrs" local vlab "Years of education"
        if "`v'"=="married_2020" local vlab "Married"
        if "`v'"=="immigrant" local vlab "Immigrant"
        if "`v'"=="born_us" local vlab "Born in U.S."
        local n_s = string(r(N), "%9.0f")
        local m_s = string(r(mean), "%9.3f")
        local s_s = string(r(sd), "%9.3f")
        file write fh "`vlab' & `n_s' & `m_s' & `s_s' \\\\" _n
    }

    * Race: one row per category (2020 sample)
    capture confirm variable race_eth
    if !_rc {
        tempfile demog_work
        save "`demog_work'", replace
        if "`wopt'" != "" {
            gen byte _one = 1
            collapse (sum) n=_one `wopt', by(race_eth)
        }
        else {
            contract race_eth, freq(n)
        }
        drop if missing(race_eth)
        egen long total_n = total(n)
        gen double pct = n / total_n
        gen double sd_p = sqrt(pct * (1 - pct))
        label values race_eth race_eth_lbl
        decode race_eth, gen(race_lab)
        forvalues r = 1/`=_N' {
            local rlab = race_lab[`r']
            local n_r = string(n[`r'], "%9.0f")
            local pct_s = string(pct[`r'], "%9.3f")
            local sd_s = string(sd_p[`r'], "%9.3f")
            file write fh "Race: `rlab' & `n_r' & `pct_s' & `sd_s' \\\\" _n
        }
        use "`demog_work'", clear
    }

    * Employment: Working (proportion); verify inlbrf_2020 is dummy (1=working)
    capture confirm variable inlbrf_2020
    if !_rc {
        quietly summarize inlbrf_2020 `wopt'
        local n_s = string(r(N), "%9.0f")
        local m_s = string(r(mean), "%9.3f")
        local s_s = string(r(sd), "%9.3f")
        file write fh "Working (in labor force) & `n_s' & `m_s' & `s_s' \\\\" _n
    }

    file write fh "\bottomrule" _n ///
        "\multicolumn{4}{l}{\footnotesize 2020. Mean and SD; for dummies/categories mean = proportion (pct). Respondent weights used when available.} \\\\" _n ///
        "\end{tabular}\end{table}" _n
    file close fh
restore

* ---------------------------------------------------------------------
* Summaries: trust, fin lit, IVs
* ---------------------------------------------------------------------
display "=== Trust variables summary ==="
summarize trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 ///
    trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020 `wopt'

display "=== Financial literacy + IV variables summary ==="
summarize interest_2020 inflation_2020 risk_div_2020 ///
    par_citizen_2020 par_loyalty_2020 population_2020 `wopt'

display "=== Additional trust regression controls summary ==="
summarize depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 ///
    num_divorce_2020 num_widow_2020 `wopt'

display "=== Contextual trust IVs summary ==="
summarize townsize_trust_* pop_trust_* regional_trust_* `wopt'

display "=== Region + population summaries ==="
summarize population_2020 `wopt'
summarize censreg_* `wopt'
summarize region_pop_group_* `wopt'
summarize hometown_size_* `wopt'

* Export label mappings for region and population
preserve
clear
input byte code str30 label
1 "Northeast"
2 "Midwest"
3 "South"
4 "West"
5 "Other"
end
file open fh using "${DESCRIPTIVE}/Tables/region_labels.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Region code labels}" _n "\label{tab:region_labels}" _n "\begin{tabular}{rl}\toprule" _n "Code & Region \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local c = string(code[`r'], "%9.0f")
    local lab = label[`r']
    file write fh "`c' & `lab' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

preserve
clear
input byte code str30 label
1 "Less than 1,000"
2 "1,000 to 10,000"
3 "10,000 to 50,000"
4 "50,000 to 100,000"
5 "100,000 to 1 million"
6 "Greater than 1 million"
8 "DK/NA"
9 "Refused"
end
file open fh using "${DESCRIPTIVE}/Tables/population_labels.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Population size (hometown) code labels}" _n "\label{tab:population_labels}" _n "\begin{tabular}{rl}\toprule" _n "Code & Population size \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local c = string(code[`r'], "%9.0f")
    local plab = label[`r']
    file write fh "`c' & `plab' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* Demographics: demographics.tex = general (age, gender, educ, marital, immigrant, born US) + race + employment.
* demographics_other.tex = other controls – same style as finlit.
preserve

* -----------------------------------------------------------------------
* demographics.tex: general vars + race + employment, all restricted to 2020 sample
* 2020 sample defined by nonmissing age_2020.
* -----------------------------------------------------------------------
keep if !missing(age_2020)

file open fh using "${DESCRIPTIVE}/Tables/demographics.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Demographics (2020)}" _n "\label{tab:demographics}" _n "\begin{tabular}{lrrr}\toprule" _n "Variable & N & Mean & SD \\\\ \midrule" _n

foreach v in age_2020 gender educ_yrs married_2020 immigrant born_us {
    capture confirm variable `v'
    if _rc continue
    quietly summarize `v' `wopt'
    if r(N) == 0 continue
    _vlabel `v'
    local vlab `r(vlabel)'
    local n_s = string(r(N), "%9.0f")
    local m_s = string(r(mean), "%9.3f")
    local s_s = string(r(sd), "%9.3f")
    file write fh "`vlab' & `n_s' & `m_s' & `s_s' \\\\" _n
}

* Race: one row per category (2020 sample)
capture confirm variable race_eth
if !_rc {
    tempfile demog_work
    save "`demog_work'", replace
    contract race_eth, freq(n)
    drop if missing(race_eth)
    egen long total_n = total(n)
    gen double pct = 100 * n / total_n
    gen double sd_p = 100 * sqrt((pct/100) * (1 - pct/100))
    label values race_eth race_eth_lbl
    decode race_eth, gen(race_lab)
    forvalues r = 1/`=_N' {
        local rlab = race_lab[`r']
        local n_r = string(n[`r'], "%9.0f")
        local pct_s = string(pct[`r'], "%9.1f")
        local sd_s = string(sd_p[`r'], "%9.2f")
        file write fh "Race: `rlab' & `n_r' & `pct_s' & `sd_s' \\\\" _n
    }
    use "`demog_work'", clear
}

* Employment: one row only — Working (proportion); no code labels (2020 sample)
capture confirm variable inlbrf_2020
if !_rc {
    tempfile demog_work
    save "`demog_work'", replace
    contract inlbrf_2020, freq(n)
    drop if missing(inlbrf_2020)
    egen long total_n = total(n)
    gen double pct = 100 * n / total_n
    gen double sd_p = 100 * sqrt((pct/100) * (1 - pct/100))
    forvalues r = 1/`=_N' {
        if inlbrf_2020[`r'] != 1 continue
        local n_r = string(n[`r'], "%9.0f")
        local pct_s = string(pct[`r'], "%9.1f")
        local sd_s = string(sd_p[`r'], "%9.2f")
        file write fh "Working & `n_r' & `pct_s' & `sd_s' \\\\" _n
        break
    }
    use "`demog_work'", clear
}

file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize 2020. Mean and SD; for dummies/categories mean = proportion (pct).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* -----------------------------------------------------------------------
* demographics_other.tex: other controls – same style as finlit (Variable, N, Mean, SD, p50)
* -----------------------------------------------------------------------
file open fh using "${DESCRIPTIVE}/Tables/demographics_other.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Demographics: other controls (2020)}" _n "\label{tab:demographics_other}" _n "\begin{tabular}{lrrrr}\toprule" _n "Variable & N & Mean & SD & p50 \\\\ \midrule" _n

foreach pair in "depression_2020 Depression" "health_cond_2020 Health conditions" "medicare_2020 Medicare" "medicaid_2020 Medicaid" "life_ins_2020 Life insurance" "num_divorce_2020 Times divorced" "num_widow_2020 Times widowed" {
    tokenize `pair'
    local v "`1'"
    local vlab "`2'"
    if "`3'" != "" local vlab "`vlab' `3'"
    capture confirm variable `v'
    if _rc continue
    quietly summarize `v', detail
    if r(N) == 0 continue
    local n_s = string(r(N), "%9.0f")
    local m_s = string(r(mean), "%9.2f")
    local s_s = string(r(sd), "%9.2f")
    local p50_s = string(r(p50), "%9.2f")
    file write fh "`vlab' & `n_s' & `m_s' & `s_s' & `p50_s' \\\\" _n
}

file write fh "\bottomrule" _n "\multicolumn{5}{l}{\footnotesize 2020. Mean, SD, and median.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh

* Financial literacy summary (2020): rv565_2020=Interest, rv566_2020=Inflation, rv567_2020=Risk diversification (HRS 2020)
preserve
capture confirm variable year
if !_rc keep if year == 2020
* Use renamed vars if present, else raw rv* (so table works whether 03 prep ran or not)
foreach v in interest_2020 inflation_2020 risk_div_2020 {
    capture confirm variable `v'
    if _rc {
        if "`v'"=="interest_2020"  capture gen interest_2020  = rv565_2020
        if "`v'"=="inflation_2020" capture gen inflation_2020 = rv566_2020
        if "`v'"=="risk_div_2020"  capture gen risk_div_2020  = rv567_2020
    }
}
file open fh using "${DESCRIPTIVE}/Tables/finlit_summary.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Financial literacy summary (2020)}" _n "\label{tab:finlit_summary}" _n "\begin{tabular}{lrrrr}\toprule" _n "Variable & N & Mean & SD & p50 \\\\ \midrule" _n
* Fixed mapping: rv565_2020=Interest, rv566_2020=Inflation, rv567_2020=Risk diversification (HRS 2020)
foreach pair in "interest_2020 Interest" "inflation_2020 Inflation" "risk_div_2020 Risk diversification" {
    tokenize `pair'
    local v "`1'"
    local vlab "`2'"
    capture confirm variable `v'
    if _rc continue
    quietly summarize `v' `wopt', detail
    if r(N) == 0 continue
    local n_s = string(r(N), "%9.0f")
    local m_s = string(r(mean), "%9.2f")
    local s_s = string(r(sd), "%9.2f")
    local p50_s = string(r(p50), "%9.2f")
    file write fh "`vlab' & `n_s' & `m_s' & `s_s' & `p50_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{5}{l}{\footnotesize HRS 2020: rv565 (interest), rv566 (inflation), rv567 (risk diversification).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Population size summary (2020)
preserve
capture confirm variable population_2020
if !_rc {
    quietly summarize population_2020 `wopt', detail
    file open fh using "${DESCRIPTIVE}/Tables/population_summary.tex", write replace
    file write fh "\begin{table}[htbp]\centering" _n "\caption{Population size (hometown) summary (2020)}" _n "\label{tab:population_summary}" _n "\begin{tabular}{lrrr}\toprule" _n "Variable & N & Mean & SD \\\\ \midrule" _n
    local n_s = string(r(N), "%9.0f")
    local m_s = string(r(mean), "%9.2f")
    local s_s = string(r(sd), "%9.2f")
    file write fh "Population size (code) & `n_s' & `m_s' & `s_s' \\\\" _n
    file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize 2020 sample.} \\\\" _n "\end{tabular}\end{table}" _n
    file close fh
}
restore

* Overlap diagnostics: trust with region/pop groupings
display "=== Overlap: trust x region (2020 only) ==="
preserve
keep hhidpn trust_others_2020 censreg_* 
reshape long censreg_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(censreg_)
decode censreg_, gen(region_label)
contract year censreg_ region_label, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_region_groups_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Trust and region overlap (2020): observations by region}" _n "\label{tab:trust_region_groups_2020}" _n "\begin{tabular}{rrlr}\toprule" _n "Year & Region (code) & Region & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local reg_s = string(censreg_[`r'], "%9.0f")
    local rlab = region_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`yr_s' & `reg_s' & `rlab' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Sample: 2020 wave, nonmissing general trust.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

display "=== Overlap: trust x region_pop_group (2020 only) ==="
preserve
keep hhidpn trust_others_2020 censreg_* population_2020
reshape long censreg_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(censreg_) & !missing(population_2020)
decode censreg_, gen(region_label)
decode population_2020, gen(pop_label)
gen int region_pop_group = censreg_ * 100 + population_2020
contract year censreg_ region_label population_2020 pop_label region_pop_group, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_regionpop_groups_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Trust and region--population overlap (2020)}" _n "\label{tab:trust_regionpop_groups_2020}" _n "\begin{tabular}{rrllrr}\toprule" _n "Year & Region (code) & Region & Pop (code) & Population size & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local reg_s = string(censreg_[`r'], "%9.0f")
    local rlab = region_label[`r']
    local pop_s = string(population_2020[`r'], "%9.0f")
    local plab = pop_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`yr_s' & `reg_s' & `rlab' & `pop_s' & `plab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

display "=== Overlap: trust x region_pop3_group (2020 only) ==="
preserve
keep hhidpn trust_others_2020 censreg_2020 population_3bin_2020
keep if !missing(trust_others_2020) & !missing(censreg_2020) & !missing(population_3bin_2020)
label values censreg_2020 region_lbl
label values population_3bin_2020 pop3_lbl
decode censreg_2020, gen(region_label)
decode population_3bin_2020, gen(pop3_label)
gen int region_pop3_group = censreg_2020 * 10 + population_3bin_2020
contract censreg_2020 region_label population_3bin_2020 pop3_label region_pop3_group, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_regionpop3_groups_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Trust and region--population (3 bins) overlap (2020)}" _n "\label{tab:trust_regionpop3_groups_2020}" _n "\begin{tabular}{rllrr}\toprule" _n "Region (code) & Region & Pop3 (code) & Population & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_2020[`r'], "%9.0f")
    local rlab = region_label[`r']
    local p3_s = string(population_3bin_2020[`r'], "%9.0f")
    local p3lab = pop3_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `p3_s' & `p3lab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

display "=== Bin counts: region, population, townsize3 (2020 only) ==="
preserve
keep if !missing(trust_others_2020)
label values censreg_2020 region_lbl
label values population_2020 pop_lbl
label values population_3bin_2020 pop3_lbl
contract censreg_2020, freq(n)
decode censreg_2020, gen(region_label)
file open fh using "${DESCRIPTIVE}/Tables/bin_counts_censreg_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Bin counts by region (2020)}" _n "\label{tab:bin_counts_censreg_2020}" _n "\begin{tabular}{rlr}\toprule" _n "Region (code) & Region & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_2020[`r'], "%9.0f")
    local rlab = region_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020)
label values population_2020 pop_lbl
contract population_2020, freq(n)
decode population_2020, gen(pop_label)
file open fh using "${DESCRIPTIVE}/Tables/bin_counts_population_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Bin counts by population size (2020)}" _n "\label{tab:bin_counts_population_2020}" _n "\begin{tabular}{rlr}\toprule" _n "Population (code) & Population size & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local p_s = string(population_2020[`r'], "%9.0f")
    local plab = pop_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`p_s' & `plab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020)
label values population_3bin_2020 pop3_lbl
contract population_3bin_2020, freq(n)
decode population_3bin_2020, gen(pop3_label)
file open fh using "${DESCRIPTIVE}/Tables/bin_counts_population3_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Bin counts by population (3 bins, 2020)}" _n "\label{tab:bin_counts_population3_2020}" _n "\begin{tabular}{rlr}\toprule" _n "Pop3 (code) & Population & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local p3_s = string(population_3bin_2020[`r'], "%9.0f")
    local p3lab = pop3_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`p3_s' & `p3lab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020) & !missing(censreg_2020) & !missing(population_2020)
label values censreg_2020 region_lbl
label values population_2020 pop_lbl
gen int region_pop_group = censreg_2020 * 100 + population_2020
decode censreg_2020, gen(region_label)
decode population_2020, gen(pop_label)
contract censreg_2020 region_label population_2020 pop_label region_pop_group, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/bin_counts_regionpop_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Bin counts by region--population (2020)}" _n "\label{tab:bin_counts_regionpop_2020}" _n "\begin{tabular}{llr}\toprule" _n "Region & Population size & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local rlab = region_label[`r']
    local plab = pop_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`rlab' & `plab' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{3}{l}{\footnotesize Sample: 2020, nonmissing general trust, region, and population.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020) & !missing(censreg_2020) & !missing(population_3bin_2020)
label values censreg_2020 region_lbl
label values population_3bin_2020 pop3_lbl
gen int region_pop3_group = censreg_2020 * 10 + population_3bin_2020
decode censreg_2020, gen(region_label)
decode population_3bin_2020, gen(pop3_label)
contract censreg_2020 region_label population_3bin_2020 pop3_label region_pop3_group, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/bin_counts_regionpop3_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Bin counts by region--population (3 bins, 2020)}" _n "\label{tab:bin_counts_regionpop3_2020}" _n "\begin{tabular}{llr}\toprule" _n "Region & Population & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local rlab = region_label[`r']
    local p3lab = pop3_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`rlab' & `p3lab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* Mean trust by race/ethnicity (2020): one table + one bar chart per trust variable (trust module: rv557=general, rv558=Social Security, rv559=Medicare, rv560=banks, rv561=advisors, rv562=mutual funds, rv563=insurance, rv564=media)
* ---------------------------------------------------------------------
display "=== Mean trust by race/ethnicity (2020), each trust variable ==="
capture confirm variable race_eth
if !_rc {
    local ntrust 8
    local tvars "trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020"
    * Display names for titles/captions (match trust module)
    local tname1 "General trust"
    local tname2 "Social Security"
    local tname3 "Medicare"
    local tname4 "Banks"
    local tname5 "Financial advisors"
    local tname6 "Mutual funds"
    local tname7 "Insurance"
    local tname8 "Media"
    forvalues i = 1/`ntrust' {
        local tvar : word `i' of `tvars'
        capture confirm variable `tvar'
        if _rc continue
        local tname `tname`i''
        preserve
        keep if !missing(`tvar') & !missing(race_eth)
        label values race_eth race_eth_lbl
        collapse (mean) trust_mean=`tvar' (count) n=`tvar' `wopt', by(race_eth)
        decode race_eth, gen(race_label)
        local stub = subinstr("`tvar'", "trust_", "", .)
        local stub = subinstr("`stub'", "_2020", "", .)
        * LaTeX table
        file open fh using "${DESCRIPTIVE}/Tables/trust_mean_by_race_eth_`stub'_2020.tex", write replace
        file write fh "\begin{table}[htbp]\centering" _n ///
            "\caption{Mean `tname' by race/ethnicity (2020)}" _n ///
            "\label{tab:trust_mean_by_race_eth_`stub'_2020}" _n ///
            "\begin{tabular}{lrr}\toprule" _n ///
            "Race/ethnicity & Mean trust & Obs \\\\ \midrule" _n
        forvalues r = 1/`=_N' {
            local rlab = race_label[`r']
            local t_s = string(trust_mean[`r'], "%9.3f")
            local n_s = string(n[`r'], "%9.0f")
            file write fh "`rlab' & `t_s' & `n_s' \\\\" _n
        }
        file write fh "\bottomrule" _n "\multicolumn{3}{l}{\footnotesize Trust: `tname' (2020); NH = non-Hispanic.} \\\\" _n "\end{tabular}" _n "\end{table}" _n
        file close fh
        * Bar chart
        graph bar trust_mean, over(race_eth, relabel(1 "White (NH)" 2 "Black (NH)" 3 "Hispanic" 4 "Other (NH)")) ///
            title("Mean `tname' by race/ethnicity (2020)") ///
            ytitle("Mean trust") b1title("Race/ethnicity") ///
            bar(1, color(navy)) ylabel(, format(%3.2f))
        graph export "${DESCRIPTIVE}/Figures/trust_mean_by_race_eth_`stub'_2020.png", replace
        restore
    }
}

display "=== Mean trust by region, population, population3 (2020 only) ==="
preserve
keep if !missing(trust_others_2020) & !missing(censreg_2020)
label values censreg_2020 region_lbl
collapse (mean) trust_mean=trust_others_2020 (count) n=trust_others_2020 `wopt', by(censreg_2020)
decode censreg_2020, gen(region_label)
file open fh using "${DESCRIPTIVE}/Tables/trust_mean_by_censreg_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean trust by region (2020)}" _n "\label{tab:trust_mean_by_censreg_2020}" _n "\begin{tabular}{rlrr}\toprule" _n "Region (code) & Region & Mean trust & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_2020[`r'], "%9.0f")
    local rlab = region_label[`r']
    local tm_s = string(trust_mean[`r'], "%9.4f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `tm_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize General trust (2020), nonmissing region.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Region counts: 4 columns (Northeast, Midwest, South, West), no Other
preserve
keep if !missing(trust_others_2020) & !missing(censreg_2020) & censreg_2020 <= 4
contract censreg_2020, freq(n)
label values censreg_2020 region_lbl
decode censreg_2020, gen(region_label)
* One row: four region counts in order 1..4
local n1 0
local n2 0
local n3 0
local n4 0
forvalues r = 1/`=_N' {
    if censreg_2020[`r'] == 1 local n1 = n[`r']
    if censreg_2020[`r'] == 2 local n2 = n[`r']
    if censreg_2020[`r'] == 3 local n3 = n[`r']
    if censreg_2020[`r'] == 4 local n4 = n[`r']
}
file open fh using "${DESCRIPTIVE}/Tables/region_counts_4col_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Region counts (2020, 4 regions, no Other)}" _n "\label{tab:region_counts_4col_2020}" _n "\begin{tabular}{cccc}\toprule" _n "Northeast & Midwest & South & West \\\\ \midrule" _n
file write fh "`n1' & `n2' & `n3' & `n4' \\\\" _n
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Sample: 2020, nonmissing general trust; region codes 1--4 only.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020) & !missing(population_2020)
label values population_2020 pop_lbl
collapse (mean) trust_mean=trust_others_2020 (count) n=trust_others_2020 `wopt', by(population_2020)
decode population_2020, gen(pop_label)
file open fh using "${DESCRIPTIVE}/Tables/trust_mean_by_population_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean trust by population size (2020)}" _n "\label{tab:trust_mean_by_population_2020}" _n "\begin{tabular}{rlrr}\toprule" _n "Population (code) & Population size & Mean trust & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local p_s = string(population_2020[`r'], "%9.0f")
    local plab = pop_label[`r']
    local tm_s = string(trust_mean[`r'], "%9.4f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`p_s' & `plab' & `tm_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize General trust (2020), nonmissing population size.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

preserve
keep if !missing(trust_others_2020) & !missing(population_3bin_2020)
label values population_3bin_2020 pop3_lbl
collapse (mean) trust_mean=trust_others_2020 (count) n=trust_others_2020 `wopt', by(population_3bin_2020)
decode population_3bin_2020, gen(pop3_label)
file open fh using "${DESCRIPTIVE}/Tables/trust_mean_by_population3_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean trust by population (3 bins, 2020)}" _n "\label{tab:trust_mean_by_population3_2020}" _n "\begin{tabular}{rlrr}\toprule" _n "Pop3 (code) & Population & Mean trust & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local p3_s = string(population_3bin_2020[`r'], "%9.0f")
    local p3lab = pop3_label[`r']
    local tm_s = string(trust_mean[`r'], "%9.4f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`p3_s' & `p3lab' & `tm_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Small/med/large; general trust (2020).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

display "=== Mean trust by townsize3 (region x pop3, 2020 only) ==="
preserve
keep if !missing(trust_others_2020) & !missing(censreg_2020) & !missing(population_3bin_2020)
label values censreg_2020 region_lbl
label values population_3bin_2020 pop3_lbl
gen int region_pop3_group = censreg_2020 * 10 + population_3bin_2020
collapse (mean) trust_mean=trust_others_2020 (count) n=trust_others_2020 `wopt', by(censreg_2020 population_3bin_2020 region_pop3_group)
decode censreg_2020, gen(region_label)
decode population_3bin_2020, gen(pop3_label)
file open fh using "${DESCRIPTIVE}/Tables/trust_mean_by_regionpop3_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Mean trust by region--population (3 bins, 2020)}" _n "\label{tab:trust_mean_by_regionpop3_2020}" _n "\begin{tabular}{rlllrr}\toprule" _n "Region (code) & Region & Pop3 (code) & Population & Mean trust & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_2020[`r'], "%9.0f")
    local rlab = region_label[`r']
    local p3_s = string(population_3bin_2020[`r'], "%9.0f")
    local p3lab = pop3_label[`r']
    local tm_s = string(trust_mean[`r'], "%9.4f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `p3_s' & `p3lab' & `tm_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{6}{l}{\footnotesize General trust (2020) by region $\times$ population (3 bins).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

display "=== Overlap: trust x hometown_size (2020 only) ==="
preserve
keep hhidpn trust_others_2020 hometown_size_* 
reshape long hometown_size_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(hometown_size_)
contract year hometown_size_, freq(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_hometownsize_groups_2020.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Trust and hometown size overlap (2020)}" _n "\label{tab:trust_hometownsize_groups_2020}" _n "\begin{tabular}{rrr}\toprule" _n "Year & Hometown size (code) & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local ht_s = string(hometown_size_[`r'], "%9.0f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`yr_s' & `ht_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* Empty group diagnostics (2020 only)
* ---------------------------------------------------------------------
display "=== Empty group diagnostics (2020 only) ==="

* Region groups: expected 5
preserve
clear
input byte censreg_ str12 region_label
1 "Northeast"
2 "Midwest"
3 "South"
4 "West"
5 "Other"
end
tempfile region_all
save "`region_all'", replace
restore

preserve
keep hhidpn trust_others_2020 censreg_* 
reshape long censreg_, i(hhidpn) j(year)
keep if year == 2020 & !missing(trust_others_2020) & !missing(censreg_)
contract censreg_, freq(n)
merge 1:1 censreg_ using "`region_all'", nogenerate
replace n = 0 if missing(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_region_groups_2020_with_empty.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Region groups with empty cells (2020)}" _n "\label{tab:trust_region_groups_2020_with_empty}" _n "\begin{tabular}{rlr}\toprule" _n "Region (code) & Region & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_[`r'], "%9.0f")
    local rlab = region_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* Region-pop groups: expected 30 (5 regions x 6 pop bins)
preserve
clear
input byte censreg_ str12 region_label
1 "Northeast"
2 "Midwest"
3 "South"
4 "West"
5 "Other"
end
tempfile region_vals
save "`region_vals'", replace
restore

preserve
clear
input byte population_2020 str22 pop_label
1 "Less than 1,000"
2 "1,000 to 10,000"
3 "10,000 to 50,000"
4 "50,000 to 100,000"
5 "100,000 to 1 million"
6 "Greater than 1 million"
end
tempfile pop_vals
save "`pop_vals'", replace
restore

preserve
use "`region_vals'", clear
cross using "`pop_vals'"
gen int region_pop_group = censreg_ * 100 + population_2020
tempfile regionpop_all
save "`regionpop_all'", replace
restore

preserve
keep hhidpn trust_others_2020 censreg_* population_2020
reshape long censreg_, i(hhidpn) j(year)
keep if year == 2020 & !missing(trust_others_2020) & !missing(censreg_) & !missing(population_2020)
contract censreg_ population_2020, freq(n)
merge 1:1 censreg_ population_2020 using "`regionpop_all'", nogenerate
replace n = 0 if missing(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_regionpop_groups_2020_with_empty.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Region--population groups with empty cells (2020)}" _n "\label{tab:trust_regionpop_groups_2020_with_empty}" _n "\begin{tabular}{rllrlr}\toprule" _n "Region (code) & Region & Pop (code) & Population size & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_[`r'], "%9.0f")
    local rlab = region_label[`r']
    local pop_s = string(population_2020[`r'], "%9.0f")
    local plab = pop_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `pop_s' & `plab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* Region-pop3 groups: expected 12 (4 regions x 3 pop bins)
preserve
clear
input byte censreg_ str12 region_label
1 "Northeast"
2 "Midwest"
3 "South"
4 "West"
end
tempfile region_vals3
save "`region_vals3'", replace
restore

preserve
clear
input byte population_3bin_2020 str30 pop3_label
1 "Small town (<10k)"
2 "Small/med city (10k-100k)"
3 "Large metro (100k+)"
end
tempfile pop3_vals
save "`pop3_vals'", replace
restore

preserve
use "`region_vals3'", clear
cross using "`pop3_vals'"
gen int region_pop3_group = censreg_ * 10 + population_3bin_2020
tempfile regionpop3_all
save "`regionpop3_all'", replace
restore

preserve
keep hhidpn trust_others_2020 censreg_2020 population_3bin_2020
keep if !missing(trust_others_2020) & !missing(censreg_2020) & !missing(population_3bin_2020)
gen byte censreg_ = censreg_2020
contract censreg_ population_3bin_2020, freq(n)
merge 1:1 censreg_ population_3bin_2020 using "`regionpop3_all'", nogenerate
replace n = 0 if missing(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_regionpop3_groups_2020_with_empty.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Region--population (3 bins) groups with empty cells (2020)}" _n "\label{tab:trust_regionpop3_groups_2020_with_empty}" _n "\begin{tabular}{rllrr}\toprule" _n "Region (code) & Region & Pop3 (code) & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local r_s = string(censreg_[`r'], "%9.0f")
    local rlab = region_label[`r']
    local p3_s = string(population_3bin_2020[`r'], "%9.0f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`r_s' & `rlab' & `p3_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore

* Population groups only: expected 6
preserve
use "`pop_vals'", clear
tempfile pop_all
save "`pop_all'", replace
restore

preserve
keep hhidpn trust_others_2020 population_2020
keep if !missing(trust_others_2020) & !missing(population_2020)
contract population_2020, freq(n)
merge 1:1 population_2020 using "`pop_all'", nogenerate
replace n = 0 if missing(n)
file open fh using "${DESCRIPTIVE}/Tables/trust_population_groups_2020_with_empty.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Population groups with empty cells (2020)}" _n "\label{tab:trust_population_groups_2020_with_empty}" _n "\begin{tabular}{rlr}\toprule" _n "Population (code) & Population size & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local p_s = string(population_2020[`r'], "%9.0f")
    local plab = pop_label[`r']
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`p_s' & `plab' & `n_s' \\\\" _n
}
file write fh "\bottomrule\end{tabular}\end{table}" _n
file close fh
restore


* Reload full dataset for Trust section (portfolio section reduced it with keep)
use "${PROCESSED}/analysis_ready_processed.dta", clear

* ---------------------------------------------------------------------
* Trust correlations and PCA
* ---------------------------------------------------------------------
local trustvars "trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020"

display "=== Trust correlations (pwcorr) ==="
pwcorr `trustvars', sig obs

display "=== Trust + added controls correlations ==="
* Controls of interest for General trust correlations:
* age, education, gender, immigration, marital, race, plus regression controls
local ctrlvars age_2020 educ_yrs gender immigrant born_us race_eth married_2020 ///
    depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 ///
    num_divorce_2020 num_widow_2020

pwcorr `trustvars' `ctrlvars', sig obs

preserve
tempfile trustctrlcorr
postfile handle str32 var1 str32 var2 double corr using "`trustctrlcorr'", replace
correlate `trustvars' `ctrlvars'
matrix C = r(C)
local allvars "`trustvars' `ctrlvars'"
local n : word count `allvars'
forvalues i = 1/`n' {
    local v1 : word `i' of `allvars'
    forvalues j = 1/`n' {
        local v2 : word `j' of `allvars'
        post handle ("`v1'") ("`v2'") (C[`i',`j'])
    }
}
postclose handle
use "`trustctrlcorr'", clear
* Keep only rows where var1 is General trust (trust_others_2020)
keep if var1 == "trust_others_2020"
* Drop rows where var2 is another trust item; keep only controls
local trustvars "trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020"
foreach t of local trustvars {
    drop if var2 == "`t'"
}

* Combined table (all controls)
file open fh using "${DESCRIPTIVE}/Tables/trust_controls_corr.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Correlations of General trust with controls}" _n "\label{tab:trust_controls_corr}" _n "\begin{tabular}{llr}\toprule" _n "Variable 1 & Variable 2 & Correlation \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local v1 = var1[`r']
    local v2 = var2[`r']
    _vlabel `v1'
    local v1 `r(vlabel)'
    _vlabel `v2'
    local v2 `r(vlabel)'
    local c_s = string(corr[`r'], "%9.4f")
    file write fh "`v1' & `v2' & `c_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{3}{l}{\footnotesize General trust (var1) with each control.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* Export trust correlation matrix as compact matrix (rows = vars, columns = vars)
preserve
correlate `trustvars'
matrix C = r(C)
local n : word count `trustvars'
local nc = `n' + 1
file open fh using "${DESCRIPTIVE}/Tables/trust_corr.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Trust variables correlation matrix}" _n "\label{tab:trust_corr}" _n "\resizebox{\textwidth}{!}{\begin{tabular}{l"
forvalues j = 1/`n' {
    file write fh "r"
}
file write fh "}\toprule" _n " & "
forvalues j = 1/`n' {
    local v : word `j' of `trustvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    if `j' < `n' file write fh "`vlab' & " _n
    else file write fh "`vlab' \\\\ \midrule" _n
}
forvalues i = 1/`n' {
    local v : word `i' of `trustvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    file write fh "`vlab'" _n
    forvalues j = 1/`n' {
        local c_s = string(C[`i',`j'], "%5.2f")
        file write fh " & `c_s'" _n
    }
    file write fh " \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{`nc'}{l}{\footnotesize Pairwise correlations between trust items (2020).} \\\\" _n "\end{tabular}}" _n "\end{table}" _n
file close fh
restore

* PCA on trust variables: export components to dataset
display "=== PCA on trust variables ==="
pca `trustvars' if !missing(trust_others_2020)
capture drop trust_pc1 trust_pc2
predict trust_pc1 trust_pc2 if e(sample)

* Export PCA loadings (first two components)
preserve
tempfile pcload
postfile handle str32 varname double pc1 pc2 using "`pcload'", replace
matrix L = e(L)
local n : word count `trustvars'
forvalues i = 1/`n' {
    local v1 : word `i' of `trustvars'
    post handle ("`v1'") (L[`i',1]) (L[`i',2])
}
postclose handle
use "`pcload'", clear
file open fh using "${DESCRIPTIVE}/Tables/trust_pca_loadings.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\setlength{\tabcolsep}{6pt}" _n "\caption{Trust PCA loadings (first two components)}" _n "\label{tab:trust_pca_loadings}" _n "\begin{tabular}{lrr}\toprule" _n "Trust item & PC1 & PC2 \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local vn = varname[`r']
    _vlabel `vn'
    local vn `r(vlabel)'
    local p1_s = string(pc1[`r'], "%9.4f")
    local p2_s = string(pc2[`r'], "%9.4f")
    file write fh "`vn' & `p1_s' & `p2_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{3}{l}{\footnotesize Principal components on trust variables (2020).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* PCA scree plot
screeplot, title("Trust PCA scree plot")
graph export "${DESCRIPTIVE}/Figures/trust_pca_scree.png", replace

* ---------------------------------------------------------------------
* Fin lit correlations with trust (matrix layout)
* ---------------------------------------------------------------------
display "=== Fin lit + trust correlations ==="
pwcorr interest_2020 inflation_2020 risk_div_2020 trust_others_2020, sig obs

preserve
correlate interest_2020 inflation_2020 risk_div_2020 trust_others_2020
matrix C = r(C)
local finvars "interest_2020 inflation_2020 risk_div_2020 trust_others_2020"
local n : word count `finvars'

file open fh using "${DESCRIPTIVE}/Tables/finlit_trust_corr.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n ///
    "\caption{Financial literacy and trust correlations}" _n ///
    "\label{tab:finlit_trust_corr}" _n ///
    "\resizebox{\textwidth}{!}{\begin{tabular}{l"
forvalues j = 1/`n' {
    file write fh "r"
}
file write fh "}\toprule" _n " & "

* Column headers (variables)
forvalues j = 1/`n' {
    local v : word `j' of `finvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    if `j' < `n' file write fh "`vlab' & "
    else file write fh "`vlab' \\\\ \midrule" _n
}

* Matrix body
forvalues i = 1/`n' {
    local v : word `i' of `finvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    file write fh "`vlab'"
    forvalues j = 1/`n' {
        local c_s = string(C[`i',`j'], "%5.2f")
        file write fh " & `c_s'"
    }
    file write fh " \\\\" _n
}

local nc = `n' + 1
file write fh "\bottomrule" _n "\multicolumn{`nc'}{l}{\footnotesize Interest, inflation, risk diversification, and general trust (2020).} \\\\" _n "\end{tabular}}" _n "\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* IV correlations with trust (matrix layout)
* ---------------------------------------------------------------------
display "=== IV + trust correlations ==="
pwcorr par_citizen_2020 par_loyalty_2020 population_2020 trust_others_2020, sig obs

preserve
tempfile ivcorr
postfile handle str32 var1 str32 var2 double corr using "`ivcorr'", replace
correlate par_citizen_2020 par_loyalty_2020 population_2020 trust_others_2020
matrix C = r(C)
local ivvars "par_citizen_2020 par_loyalty_2020 population_2020 trust_others_2020"
local n : word count `ivvars'
* Export as compact matrix
file open fh using "${DESCRIPTIVE}/Tables/iv_trust_corr.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n ///
    "\caption{IV and trust correlations}" _n ///
    "\label{tab:iv_trust_corr}" _n ///
    "\resizebox{\textwidth}{!}{\begin{tabular}{l"
forvalues j = 1/`n' {
    file write fh "r"
}
file write fh "}\toprule" _n " & "
forvalues j = 1/`n' {
    local v : word `j' of `ivvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    if `j' < `n' file write fh "`vlab' & "
    else file write fh "`vlab' \\\\ \midrule" _n
}
forvalues i = 1/`n' {
    local v : word `i' of `ivvars'
    _vlabel `v'
    local vlab `r(vlabel)'
    file write fh "`vlab'"
    forvalues j = 1/`n' {
        local c_s = string(C[`i',`j'], "%5.2f")
        file write fh " & `c_s'"
    }
    file write fh " \\\\" _n
}
local nc = `n' + 1
file write fh "\bottomrule" _n "\multicolumn{`nc'}{l}{\footnotesize Parent citizenship, loyalty, population size, and general trust (2020).} \\\\" _n "\end{tabular}}" _n "\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* Depression/health by age
* ---------------------------------------------------------------------
display "=== Depression and health conditions by age group ==="
preserve
keep hhidpn age_* depression_2020 health_cond_2020
reshape long age_, i(hhidpn) j(year)
rename age_ age
gen int age_group = floor(age/5)*5 if !missing(age)
tabstat depression_2020 health_cond_2020 `wopt', by(age_group) statistics(n mean sd p50 p95)
collapse (mean) mean_depression=depression_2020 mean_health=health_cond_2020 (count) n=depression_2020 `wopt', by(age_group)
file open fh using "${DESCRIPTIVE}/Tables/depression_health_by_agegroup.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Depression and health conditions by age group}" _n "\label{tab:depression_health_by_agegroup}" _n "\begin{tabular}{lrrr}\toprule" _n "Age (midpoint) & Depression (mean) & Health conditions (mean) & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local ag_s = string(age_group[`r'], "%9.0f")
    local md_s = string(mean_depression[`r'], "%9.4f")
    local mh_s = string(mean_health[`r'], "%9.4f")
    local n_s = string(n[`r'], "%9.0f")
    file write fh "`ag_s' & `md_s' & `mh_s' & `n_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{4}{l}{\footnotesize Five-year age bins; 2020 outcomes.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* ---------------------------------------------------------------------
* Group coverage: N (observations) in each region and each region-pop group by year
* ---------------------------------------------------------------------
display "=== Group coverage: N by region and by year ==="
preserve
keep hhidpn censreg_*
reshape long censreg_, i(hhidpn) j(year)
label values censreg_ region_lbl
drop if missing(censreg_)
contract year censreg_, freq(N)
* Wide table: year x region with N (drop Other)
reshape wide N, i(year) j(censreg_)
rename (N1 N2 N3 N4) (Northeast Midwest South West)
file open fh using "${DESCRIPTIVE}/Tables/region_group_counts_by_year.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Observations by region and year}" _n "\label{tab:region_group_counts_by_year}" _n "\begin{tabular}{lrrrr}\toprule" _n "Year & Northeast & Midwest & South & West \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local ne_s = string(Northeast[`r'], "%9.0f")
    local mw_s = string(Midwest[`r'], "%9.0f")
    local so_s = string(South[`r'], "%9.0f")
    local we_s = string(West[`r'], "%9.0f")
    file write fh "`yr_s' & `ne_s' & `mw_s' & `so_s' & `we_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{5}{l}{\footnotesize Person-year observations by region (region 5 = Other omitted).} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

display "=== Group coverage: N by region-population group and year ==="
preserve
keep hhidpn censreg_* region_pop_group_*
reshape long censreg_ region_pop_group_, i(hhidpn) j(year)
contract year region_pop_group_, freq(N)
drop if missing(region_pop_group_)
rename N obs
file open fh using "${DESCRIPTIVE}/Tables/regionpop_group_counts_by_year.tex", write replace
file write fh "\begin{table}[htbp]\centering" _n "\caption{Observations by region--population group and year}" _n "\label{tab:regionpop_group_counts_by_year}" _n "\begin{tabular}{lrr}\toprule" _n "Year & Group (code) & Obs \\\\ \midrule" _n
forvalues r = 1/`=_N' {
    local yr_s = string(year[`r'], "%9.0f")
    local rpg_s = string(region_pop_group_[`r'], "%9.0f")
    local ob_s = string(obs[`r'], "%9.0f")
    file write fh "`yr_s' & `rpg_s' & `ob_s' \\\\" _n
}
file write fh "\bottomrule" _n "\multicolumn{3}{l}{\footnotesize Region $\times$ population size (6 bins); person-year counts.} \\\\" _n "\end{tabular}\end{table}" _n
file close fh
restore

* For analysis: treat region 5 (Other) as missing in prepped censreg variables before saving
foreach v of varlist censreg_* {
    capture confirm variable `v'
    if !_rc replace `v' = . if `v' == 5
}

* Save dataset with PCA components (region 5 = missing in saved data)
save "${PROCESSED}/analysis_ready_processed.dta", replace
display "08_descriptive_controls: Saved ${PROCESSED}/analysis_ready_processed.dta with trust_pc1/pc2 (region 5 Other set to missing)"

* ---------------------------------------------------------------------
* Tabstat: regression-focus returns (r1 core, r4 Core+ret., r5 net wealth)
* ---------------------------------------------------------------------
display "=== Tabstat: returns r1 (core), r4 (Core+ret.), r5 (net wealth) ==="
local regretvars ""
foreach v in r1_annual_2022 r4_annual_2022 r5_annual_2022 {
    capture confirm variable `v'
    if !_rc local regretvars "`regretvars' `v'"
}
if "`regretvars'" != "" {
    tabstat `regretvars' `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)
}
capture confirm variable r1_annual_2002
if !_rc {
    tabstat r1_annual_2002 r4_annual_2002 r5_annual_2002 `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)
}

* ---------------------------------------------------------------------
* Tabstat: regression-focus wealth (core, Core+ret., net wealth)
* ---------------------------------------------------------------------
display "=== Tabstat: wealth core, Core+ret., net wealth ==="
capture confirm variable wealth_core_2022
if !_rc {
    local wlist22 "wealth_core_2022 wealth_total_2022"
    capture confirm variable wealth_coreira_2022
    if !_rc local wlist22 "wealth_core_2022 wealth_coreira_2022 wealth_total_2022"
    tabstat `wlist22' `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)
}
capture confirm variable wealth_core_2002
if !_rc {
    local wlist02 "wealth_core_2002 wealth_total_2002"
    capture confirm variable wealth_coreira_2002
    if !_rc local wlist02 "wealth_core_2002 wealth_coreira_2002 wealth_total_2002"
    tabstat `wlist02' `wopt', statistics(n mean sd p1 p5 p50 p95 p99 min max)
}

* ---------------------------------------------------------------------
* Trust vs income/returns (2022) scatterplots — regression focus: r1, r4, r5 only
* ---------------------------------------------------------------------
display "=== Scatter: trust vs income/returns (2022) ==="
capture mkdir "${DESCRIPTIVE}/Figures"

* Income vs trust scatter: uses final log series from 04 (deflate -> ln(x), x>0 -> winsorize p1/p99 on log; zero income dropped)
* Variables: ln_lab_inc_final_2022, ln_tot_inc_final_2022 (see 04_processing_income.do "Final toggle" block)
foreach v in ln_lab_inc_final_2022 ln_tot_inc_final_2022 {
    capture confirm variable `v'
    if !_rc {
        local vlabel = cond("`v'"=="ln_lab_inc_final_2022","Final log labor income (2022)","Final log total income (2022)")
        twoway scatter `v' trust_others_2020 if !missing(`v') & !missing(trust_others_2020), ///
            title("`vlabel' vs general trust") ///
            xtitle("General trust (2020)") ytitle("`vlabel'")
        graph export "${DESCRIPTIVE}/Figures/`v'_vs_trust_2022.png", replace
    }
}

* Return measures (regression focus: r1 core, r4 Core+ret., r5 net wealth only)
foreach v in r1_annual_2022 r4_annual_2022 r5_annual_2022 ///
            r1_annual_win_2022 r4_annual_win_2022 r5_annual_win_2022 {
    capture confirm variable `v'
    if !_rc {
        local vlabel "`v'"
        if "`v'"=="r1_annual_2022" local vlabel "Core (2022)"
        if "`v'"=="r4_annual_2022" local vlabel "Core+ret. (2022)"
        if "`v'"=="r5_annual_2022" local vlabel "Net wealth (2022)"
        if "`v'"=="r1_annual_win_2022" local vlabel "Core (2022, winsorized)"
        if "`v'"=="r4_annual_win_2022" local vlabel "Core+ret. (2022, winsorized)"
        if "`v'"=="r5_annual_win_2022" local vlabel "Net wealth (2022, winsorized)"
        twoway scatter `v' trust_others_2020 if !missing(`v') & !missing(trust_others_2020), ///
            title("`vlabel' vs general trust") ///
            xtitle("General trust (2020)") ytitle("`vlabel'")
        graph export "${DESCRIPTIVE}/Figures/`v'_vs_trust_2022.png", replace
    }
}

* ---------------------------------------------------------------------
* Binscatter: trust vs depression (same style as 06/07 binscatters)
* ---------------------------------------------------------------------
display "=== Binscatter: depression vs general trust (2020) ==="
capture which binscatter
if _rc capture ssc install binscatter, replace
capture confirm variable depression_2020
local has_dep = (_rc == 0)
capture confirm variable trust_others_2020
local has_trust = (_rc == 0)
if `has_dep' & `has_trust' {
    capture binscatter depression_2020 trust_others_2020 if !missing(depression_2020) & !missing(trust_others_2020), nquantiles(50) ///
        ytitle("Depression (2020)") xtitle("General trust (2020)") ///
        title("Binscatter: Depression vs general trust")
    if _rc == 0 graph export "${DESCRIPTIVE}/Figures/depression_vs_trust_binscatter.png", replace
}

log close
