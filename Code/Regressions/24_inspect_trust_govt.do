* 24_inspect_trust_govt.do
* Inspect government trust (Medicare, Social Security): cross-corr, PCA, average.
* Two aggregation methods: trust_govt_pc1_2020 (PCA on 2) and trust_govt_avg_2020 (mean of 2).
* Rerun r5 wins at 5%: 2022 cross section, avg returns, panel spec 1–3.
* Log only — inspect before migrating to pipeline.
* Log: Notes/Logs/24_inspect_trust_govt.log

clear
set more off

* ----------------------------------------------------------------------
* Paths and config
* ----------------------------------------------------------------------
capture confirm global BASE_PATH
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") {
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
log using "${LOG_DIR}/24_inspect_trust_govt.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* 1. Cross-correlation: general, Medicare, Social Security
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1. CROSS-CORRELATION: General trust, Medicare, Social Security"
display "########################################################################"
use "${PROCESSED}/analysis_ready_processed.dta", clear

local trust3 "trust_others_2020 trust_medicare_2020 trust_social_security_2020"
local trust2 "trust_medicare_2020 trust_social_security_2020"

display _n "--- pwcorr (with sig, obs) ---"
pwcorr `trust3', sig obs

display _n "--- correlate ---"
correlate `trust3'

* ----------------------------------------------------------------------
* 2. PCA: with general trust first, then without
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2. PCA ON TRUST VARIABLES"
display "########################################################################"

* 2a. PCA with general trust (all 3 vars)
display _n "--- PCA (3 vars: general, Medicare, Social Security) ---"
pca `trust3' if !missing(trust_others_2020) & !missing(trust_medicare_2020) & !missing(trust_social_security_2020)
screeplot, title("Trust PCA (3 vars: general, Medicare, Social Security)")
* Loadings for log
matrix L3 = e(L)
display _n "Loadings (PC1, PC2):"
forvalues i = 1/3 {
    local v : word `i' of `trust3'
    display "  `v': PC1=" L3[`i',1] ", PC2=" L3[`i',2]
}

* 2b. PCA without general trust (2 vars: Medicare, Social Security)
display _n "--- PCA (2 vars: Medicare, Social Security only) ---"
pca `trust2' if !missing(trust_medicare_2020) & !missing(trust_social_security_2020)
screeplot, title("Trust PCA (2 vars: Medicare, Social Security)")

capture drop trust_govt_pc1_2020
predict trust_govt_pc1_2020 if e(sample)

matrix L2 = e(L)
display _n "Loadings (PC1, PC2):"
forvalues i = 1/2 {
    local v : word `i' of `trust2'
    display "  `v': PC1=" L2[`i',1] ", PC2=" L2[`i',2]
}

* ----------------------------------------------------------------------
* 3. Average of two: trust_govt_avg_2020
* ----------------------------------------------------------------------
display _n "########################################################################"
display "3. TRUST_GOVT_AVG_2020 (mean of Medicare, Social Security)"
display "########################################################################"
capture drop trust_govt_avg_2020
egen double trust_govt_avg_2020 = rowmean(trust_medicare_2020 trust_social_security_2020)

display _n "--- summarize trust_govt_avg_2020 ---"
summarize trust_govt_avg_2020, detail

* ----------------------------------------------------------------------
* Save wide with govt trust vars for merge to panel
* ----------------------------------------------------------------------
preserve
keep hhidpn trust_govt_pc1_2020 trust_govt_avg_2020
duplicates drop hhidpn, force
tempfile govt_trust_wide
save `govt_trust_wide'
restore

* ----------------------------------------------------------------------
* Base controls (r5: wealth deciles)
* ----------------------------------------------------------------------
capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

local ctrl_r5 "i.age_bin i.gender educ_yrs inlbrf_2020 married_2020 born_us i.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}

* ----------------------------------------------------------------------
* 4. CROSS SECTION: r5_annual_w5_2022
* (PCA without general trust + average only)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "4. CROSS SECTION: r5 (5% wins) 2022"
display "########################################################################"

foreach trust_agg in trust_govt_pc1_2020 trust_govt_avg_2020 {
    local agg_lab = cond("`trust_agg'"=="trust_govt_pc1_2020", "PCA (no general)", "Avg (Medicare, Social Security)")
    display _n "--- `agg_lab': `trust_agg' ---"
    gen byte _samp = !missing(r5_annual_w5_2022) & !missing(`trust_agg')
    quietly count if _samp
    display "N = " r(N)
    eststo clear
    eststo m1: regress r5_annual_w5_2022 `ctrl_r5' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    eststo m2: regress r5_annual_w5_2022 `ctrl_r5' c.`trust_agg' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    eststo m3: regress r5_annual_w5_2022 `ctrl_r5' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) stats(N r2_a p_joint_trust)
    drop _samp
}

* ----------------------------------------------------------------------
* 5. AVERAGE RETURNS: r5_annual_avg_w5
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5. AVERAGE RETURNS: r5 (5% wins) avg"
display "########################################################################"

foreach trust_agg in trust_govt_pc1_2020 trust_govt_avg_2020 {
    local agg_lab = cond("`trust_agg'"=="trust_govt_pc1_2020", "PCA (no general)", "Avg (Medicare, Social Security)")
    display _n "--- `agg_lab': `trust_agg' ---"
    gen byte _samp = !missing(r5_annual_avg_w5) & !missing(`trust_agg')
    quietly count if _samp
    display "N = " r(N)
    eststo clear
    eststo m1: regress r5_annual_avg_w5 `ctrl_r5' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    eststo m2: regress r5_annual_avg_w5 `ctrl_r5' c.`trust_agg' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    eststo m3: regress r5_annual_avg_w5 `ctrl_r5' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) stats(N r2_a p_joint_trust)
    drop _samp
}

* ----------------------------------------------------------------------
* 6. PANEL: spec 1, 2, 3 for r5 wins
* ----------------------------------------------------------------------
display _n "########################################################################"
display "6. PANEL: r5 (5% wins) spec 1–3"
display "########################################################################"

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
merge m:1 hhidpn using `govt_trust_wide', nogen
xtset hhidpn year

* Base controls
local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local base_ctrl "`base_ctrl' wealth_d`d'"
}
local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

foreach trust_agg in trust_govt_pc1_2020 trust_govt_avg_2020 {
    local agg_lab = cond("`trust_agg'"=="trust_govt_pc1_2020", "PCA (no general)", "Avg (Medicare, Social Security)")
    display _n "--- `agg_lab': `trust_agg' ---"
    gen byte _samp = !missing(r5_annual_w5) & `share_cond' & !missing(`trust_agg')
    quietly count if _samp
    display "N (obs) = " r(N)

    * Spec 1 (pooled, no share×year)
    display _n "  Spec 1 (pooled):"
    eststo clear
    eststo m1: regress r5_annual_w5 `base_ctrl' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m1
    eststo m2: regress r5_annual_w5 `base_ctrl' c.`trust_agg' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m2
    eststo m3: regress r5_annual_w5 `base_ctrl' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(cluster hhidpn)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) stats(N r2_a p_joint_trust)

    * Spec 2 (share×year)
    display _n "  Spec 2 (share×year):"
    eststo clear
    eststo m1: regress r5_annual_w5 `ctrl_s2' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m1
    eststo m2: regress r5_annual_w5 `ctrl_s2' c.`trust_agg' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m2
    eststo m3: regress r5_annual_w5 `ctrl_s2' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(cluster hhidpn)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) stats(N r2_a p_joint_trust)

    * Spec 3 (FE + second stage)
    display _n "  Spec 3 (FE, 2nd stage):"
    local ctrl_fe "i.age_bin inlbrf married i.year"
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local ctrl_fe "`ctrl_fe' wealth_d`d'"
    }
    local ctrl_fe "`ctrl_fe' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

    gen byte _fe_cond = `share_cond' & !missing(`trust_agg')
    capture drop _fe_r5 fe_r5
    quietly xtreg r5_annual_w5 `ctrl_fe' if _fe_cond, fe vce(cluster hhidpn)
    if _rc {
        display "  xtreg failed for `trust_agg'"
        drop _samp _fe_cond
        continue
    }
    predict _fe_r5 if e(sample)
    bysort hhidpn: egen fe_r5 = mean(_fe_r5)
    preserve
    keep if !missing(fe_r5)
    keep hhidpn fe_r5 educ_yrs gender race_eth born_us `trust_agg'
    collapse (first) fe_r5 educ_yrs gender race_eth born_us `trust_agg', by(hhidpn)
    gen byte _fe_samp = !missing(fe_r5) & !missing(`trust_agg')
    quietly count if _fe_samp
    display "  N (persons) = " r(N)
    eststo clear
    eststo m1: regress fe_r5 educ_yrs i.gender i.race_eth born_us if _fe_samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    eststo m2: regress fe_r5 educ_yrs i.gender i.race_eth born_us c.`trust_agg' if _fe_samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    eststo m3: regress fe_r5 educ_yrs i.gender i.race_eth born_us c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _fe_samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) stats(N r2_a p_joint_trust)
    restore
    drop _fe_r5 fe_r5 _samp _fe_cond
}

display _n "Done. Log: ${LOG_DIR}/24_inspect_trust_govt.log"
log close
