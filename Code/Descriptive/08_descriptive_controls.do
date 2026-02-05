* 08_descriptive_controls.do
* Descriptive statistics for trust, financial literacy, and IV variables.
* Input: ${PROCESSED}/analysis_ready_processed.dta
* Output: logs, tables, figures; trust PC1/PC2 saved to processed dataset

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

capture mkdir "${BASE_PATH}/Descriptive"
capture mkdir "${BASE_PATH}/Descriptive/Figures"
capture mkdir "${BASE_PATH}/Descriptive/Tables"

use "${PROCESSED}/analysis_ready_processed.dta", clear

* Label definitions for region and population size
capture label define region_lbl 1 "Northeast" 2 "Midwest" 3 "South" 4 "West" 5 "Other", replace
capture label define pop_lbl 1 "Less than 1,000" 2 "1,000 to 10,000" 3 "10,000 to 50,000" ///
    4 "50,000 to 100,000" 5 "100,000 to 1 million" 6 "Greater than 1 million" ///
    8 "DK/NA" 9 "Refused", replace
foreach v of varlist region_* {
    capture label values `v' region_lbl
}
capture label values population_2020 pop_lbl

* ---------------------------------------------------------------------
* Summaries: trust, fin lit, IVs
* ---------------------------------------------------------------------
display "=== Trust variables summary ==="
summarize trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 ///
    trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020

display "=== Financial literacy + IV variables summary ==="
summarize interest_2020 inflation_2020 risk_div_2020 ///
    par_citizen_2020 par_loyalty_2020 population_2020

display "=== Additional trust regression controls summary ==="
summarize depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 ///
    beq_any_2020 num_divorce_2020 num_widow_2020

display "=== Contextual trust IVs summary ==="
summarize townsize_trust_* pop_trust_* regional_trust_*

display "=== Region + population summaries ==="
summarize population_2020
summarize region_*
summarize region_pop_group_*
summarize hometown_size_*

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
export delimited using "${BASE_PATH}/Descriptive/Tables/region_labels.csv", replace
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
export delimited using "${BASE_PATH}/Descriptive/Tables/population_labels.csv", replace
restore

* Overlap diagnostics: trust with region/pop groupings
display "=== Overlap: trust x region (2020 only) ==="
preserve
keep hhidpn trust_others_2020 region_* 
reshape long region_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(region_)
decode region_, gen(region_label)
contract year region_ region_label, freq(n)
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_region_groups_by_year.csv", replace
restore

display "=== Overlap: trust x region_pop_group (2020 only) ==="
preserve
keep hhidpn trust_others_2020 region_* population_2020
reshape long region_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(region_) & !missing(population_2020)
decode region_, gen(region_label)
decode population_2020, gen(pop_label)
gen int region_pop_group = region_ * 100 + population_2020
contract year region_ region_label population_2020 pop_label region_pop_group, freq(n)
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_regionpop_groups_by_year.csv", replace
restore

display "=== Overlap: trust x hometown_size (2020 only) ==="
preserve
keep hhidpn trust_others_2020 hometown_size_* 
reshape long hometown_size_, i(hhidpn) j(year)
keep if year == 2020
keep if !missing(trust_others_2020) & !missing(hometown_size_)
contract year hometown_size_, freq(n)
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_hometownsize_groups_by_year.csv", replace
restore

* ---------------------------------------------------------------------
* Empty group diagnostics (2020 only)
* ---------------------------------------------------------------------
display "=== Empty group diagnostics (2020 only) ==="

* Region groups: expected 5
preserve
clear
input byte region_ str12 region_label
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
keep hhidpn trust_others_2020 region_* 
reshape long region_, i(hhidpn) j(year)
keep if year == 2020 & !missing(trust_others_2020) & !missing(region_)
contract region_, freq(n)
merge 1:1 region_ using "`region_all'", nogenerate
replace n = 0 if missing(n)
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_region_groups_2020_with_empty.csv", replace
restore

* Region-pop groups: expected 30 (5 regions x 6 pop bins)
preserve
clear
input byte region_ str12 region_label
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
gen int region_pop_group = region_ * 100 + population_2020
tempfile regionpop_all
save "`regionpop_all'", replace
restore

preserve
keep hhidpn trust_others_2020 region_* population_2020
reshape long region_, i(hhidpn) j(year)
keep if year == 2020 & !missing(trust_others_2020) & !missing(region_) & !missing(population_2020)
contract region_ population_2020, freq(n)
merge 1:1 region_ population_2020 using "`regionpop_all'", nogenerate
replace n = 0 if missing(n)
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_regionpop_groups_2020_with_empty.csv", replace
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
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_population_groups_2020_with_empty.csv", replace
restore

* ---------------------------------------------------------------------
* Shares summary (2002 and 2022)
* ---------------------------------------------------------------------
display "=== Shares summary (2002) ==="
local sharevars_2002 ""
foreach v in share_m1_re_2002 share_m1_vehicles_2002 share_m1_bus_2002 share_m1_stk_2002 share_m1_chck_2002 share_m1_cd_2002 share_m1_bond_2002 share_m1_other_2002 ///
            share_m2_re_2002 share_m2_vehicles_2002 share_m2_bus_2002 share_m2_ira_2002 share_m2_stk_2002 share_m2_chck_2002 share_m2_cd_2002 share_m2_bond_2002 share_m2_other_2002 ///
            share_m3_pri_res_2002 share_m3_sec_res_2002 share_m3_re_2002 share_m3_vehicles_2002 share_m3_bus_2002 share_m3_ira_2002 share_m3_stk_2002 share_m3_chck_2002 share_m3_cd_2002 share_m3_bond_2002 share_m3_other_2002 ///
            share_debt_long_2002 share_debt_other_2002 {
    capture confirm variable `v'
    if !_rc local sharevars_2002 "`sharevars_2002' `v'"
}
if "`sharevars_2002'" != "" {
    summarize `sharevars_2002'
}

display "=== Shares summary (2022) ==="
local sharevars_2022 ""
foreach v in share_m1_re_2022 share_m1_vehicles_2022 share_m1_bus_2022 share_m1_stk_2022 share_m1_chck_2022 share_m1_cd_2022 share_m1_bond_2022 share_m1_other_2022 ///
            share_m2_re_2022 share_m2_vehicles_2022 share_m2_bus_2022 share_m2_ira_2022 share_m2_stk_2022 share_m2_chck_2022 share_m2_cd_2022 share_m2_bond_2022 share_m2_other_2022 ///
            share_m3_pri_res_2022 share_m3_sec_res_2022 share_m3_re_2022 share_m3_vehicles_2022 share_m3_bus_2022 share_m3_ira_2022 share_m3_stk_2022 share_m3_chck_2022 share_m3_cd_2022 share_m3_bond_2022 share_m3_other_2022 ///
            share_debt_long_2022 share_debt_other_2022 {
    capture confirm variable `v'
    if !_rc local sharevars_2022 "`sharevars_2022' `v'"
}
if "`sharevars_2022'" != "" {
    summarize `sharevars_2022'
}

* ---------------------------------------------------------------------
* Trust correlations and PCA
* ---------------------------------------------------------------------
local trustvars "trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020"

display "=== Trust correlations (pwcorr) ==="
pwcorr `trustvars', sig obs

display "=== Trust + added controls correlations ==="
pwcorr `trustvars' depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 ///
    beq_any_2020 num_divorce_2020 num_widow_2020, sig obs

preserve
tempfile trustctrlcorr
postfile handle str32 var1 str32 var2 double corr using "`trustctrlcorr'", replace
correlate `trustvars' depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 ///
    beq_any_2020 num_divorce_2020 num_widow_2020
matrix C = r(C)
local allvars "`trustvars' depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 beq_any_2020 num_divorce_2020 num_widow_2020"
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
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_controls_corr.csv", replace
restore

* Export trust correlation matrix (long format)
preserve
tempfile trustcorr
postfile handle str32 var1 str32 var2 double corr using "`trustcorr'", replace
correlate `trustvars'
matrix C = r(C)
local n : word count `trustvars'
forvalues i = 1/`n' {
    local v1 : word `i' of `trustvars'
    forvalues j = 1/`n' {
        local v2 : word `j' of `trustvars'
        post handle ("`v1'") ("`v2'") (C[`i',`j'])
    }
}
postclose handle
use "`trustcorr'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_corr.csv", replace
restore

* PCA on trust variables: export components to dataset
display "=== PCA on trust variables ==="
pca `trustvars' if !missing(trust_others_2020)
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
export delimited using "${BASE_PATH}/Descriptive/Tables/trust_pca_loadings.csv", replace
restore

* PCA scree plot
screeplot, title("Trust PCA scree plot")
graph export "${BASE_PATH}/Descriptive/Figures/trust_pca_scree.png", replace

* ---------------------------------------------------------------------
* Fin lit correlations with trust
* ---------------------------------------------------------------------
display "=== Fin lit + trust correlations ==="
pwcorr interest_2020 inflation_2020 risk_div_2020 trust_others_2020, sig obs

preserve
tempfile finlitcorr
postfile handle str32 var1 str32 var2 double corr using "`finlitcorr'", replace
correlate interest_2020 inflation_2020 risk_div_2020 trust_others_2020
matrix C = r(C)
local finvars "interest_2020 inflation_2020 risk_div_2020 trust_others_2020"
local n : word count `finvars'
forvalues i = 1/`n' {
    local v1 : word `i' of `finvars'
    forvalues j = 1/`n' {
        local v2 : word `j' of `finvars'
        post handle ("`v1'") ("`v2'") (C[`i',`j'])
    }
}
postclose handle
use "`finlitcorr'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/finlit_trust_corr.csv", replace
restore

* ---------------------------------------------------------------------
* IV correlations with trust
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
forvalues i = 1/`n' {
    local v1 : word `i' of `ivvars'
    forvalues j = 1/`n' {
        local v2 : word `j' of `ivvars'
        post handle ("`v1'") ("`v2'") (C[`i',`j'])
    }
}
postclose handle
use "`ivcorr'", clear
export delimited using "${BASE_PATH}/Descriptive/Tables/iv_trust_corr.csv", replace
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
tabstat depression_2020 health_cond_2020, by(age_group) statistics(n mean sd p50 p95)
collapse (mean) mean_depression=depression_2020 mean_health=health_cond_2020 (count) n=depression_2020, by(age_group)
export delimited using "${BASE_PATH}/Descriptive/Tables/depression_health_by_agegroup.csv", replace
restore

* ---------------------------------------------------------------------
* Group coverage diagnostics for region and region_pop_group
* ---------------------------------------------------------------------
display "=== Group coverage diagnostics ==="
preserve
keep hhidpn region_* region_pop_group_*
reshape long region_ region_pop_group_, i(hhidpn) j(year)

* Region counts by year
tempfile region_counts
contract year region_, freq(n)
collapse (count) groups=region_ (min) min_n=n (max) max_n=n, by(year)
export delimited using "${BASE_PATH}/Descriptive/Tables/region_group_counts_by_year.csv", replace
restore

preserve
keep hhidpn region_* region_pop_group_*
reshape long region_ region_pop_group_, i(hhidpn) j(year)

* Region-population group counts by year
contract year region_pop_group_, freq(n)
collapse (count) groups=region_pop_group_ (min) min_n=n (max) max_n=n, by(year)
export delimited using "${BASE_PATH}/Descriptive/Tables/regionpop_group_counts_by_year.csv", replace
restore

* Save dataset with PCA components
save "${PROCESSED}/analysis_ready_processed.dta", replace
display "08_descriptive_controls: Saved ${PROCESSED}/analysis_ready_processed.dta with trust_pc1/pc2"

* ---------------------------------------------------------------------
* Trust vs income/returns (2022) scatterplots
* ---------------------------------------------------------------------
display "=== Scatter: trust vs income/returns (2022) ==="
capture mkdir "${BASE_PATH}/Descriptive/Figures"

* Income measures (final log series)
foreach v in ln_lab_inc_final_2022 ln_tot_inc_final_2022 {
    capture confirm variable `v'
    if !_rc {
        twoway scatter `v' trust_others_2020 if !missing(`v') & !missing(trust_others_2020), ///
            title("`v' vs trust_others_2020 (2022)") ///
            xtitle("General trust (2020)") ytitle("`v'")
        graph export "${BASE_PATH}/Descriptive/Figures/`v'_vs_trust_2022.png", replace
    }
}

* Return measures
foreach v in r1_annual_2022 r2_annual_2022 r3_annual_2022 debt_long_annual_2022 debt_other_annual_2022 ///
            r1_annual_2022_win r2_annual_2022_win r3_annual_2022_win debt_long_annual_2022_win debt_other_annual_2022_win {
    capture confirm variable `v'
    if !_rc {
        twoway scatter `v' trust_others_2020 if !missing(`v') & !missing(trust_others_2020), ///
            title("`v' vs trust_others_2020 (2022)") ///
            xtitle("General trust (2020)") ytitle("`v'")
        graph export "${BASE_PATH}/Descriptive/Figures/`v'_vs_trust_2022.png", replace
    }
}

log close
