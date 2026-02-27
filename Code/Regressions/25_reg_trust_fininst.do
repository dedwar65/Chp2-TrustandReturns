* 25_reg_trust_fininst.do
* Financial-institutional trust PCA with general trust (4 vars): descriptive stats + r5 regressions.
* Trust measures: trust_fin_pc1_wgen_2020, trust_fin_pc2_wgen_2020 (PCA on 4), trust_fin_avg_2020 (mean of 3).
* Regressions: r5 wins, cross section, avg returns, panel spec 1–3.
* Output: Regressions/Trust/FinInst/
* Log: Notes/Logs/25_reg_trust_fininst.log

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

capture mkdir "${REGRESSIONS}/Trust"

capture mkdir "${REGRESSIONS}/Trust/FinInst"

capture log close
log using "${LOG_DIR}/25_reg_trust_fininst.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* 1. PCA with general trust (4 vars) + average of 3
* ----------------------------------------------------------------------
display _n "########################################################################"
display "1. PCA (4 vars) + AGGREGATED TRUST SCORE"
display "########################################################################"

use "${PROCESSED}/analysis_ready_processed.dta", clear

local trust4 "trust_others_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020"

display _n "--- PCA (4 vars: general, banks, advisors, mutual funds) ---"
pca `trust4' if !missing(trust_others_2020) & !missing(trust_banks_2020) & !missing(trust_advisors_2020) & !missing(trust_mutual_funds_2020)
screeplot, title("Financial-institutional trust PCA")
capture mkdir "${REGRESSIONS}/Trust/FinInst/Figures"
graph export "${REGRESSIONS}/Trust/FinInst/Figures/fin_trust_scree.png", replace
matrix L4 = e(L)
display _n "Loadings (PC1, PC2):"
forvalues i = 1/4 {
    local v : word `i' of `trust4'
    display "  `v': PC1=" L4[`i',1] ", PC2=" L4[`i',2]
}
capture drop trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020
predict trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020 if e(sample)

* Aggregated score: mean of banks, advisors, mutual funds (no general)
capture drop trust_fin_avg_2020
egen double trust_fin_avg_2020 = rowmean(trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020)

* ----------------------------------------------------------------------
* 2. Descriptive stats + loadings (before regressions)
* ----------------------------------------------------------------------
display _n "########################################################################"
display "2. DESCRIPTIVE STATS AND PCA LOADINGS"
display "########################################################################"

local FININST_TAB "${REGRESSIONS}/Trust/FinInst"

* Loadings: variable loadings on each component used in analysis
file open fh using "`FININST_TAB'/fin_trust_loadings.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial-institutional trust PCA: loadings by variable (4 vars: general, banks, advisors, mutual funds)}" _n "\label{tab:fin_trust_loadings}" _n "\begin{tabular}{lrr}\toprule" _n "Variable & PC1 & PC2 \\\\ \midrule" _n
local vlab1 "General trust"
local vlab2 "Banks"
local vlab3 "Financial advisors"
local vlab4 "Mutual funds"
forvalues i = 1/4 {
    local v : word `i' of `trust4'
    local vlab `vlab`i''
    local l1 = string(L4[`i',1], "%9.3f")
    local l2 = string(L4[`i',2], "%9.3f")
    file write fh "`vlab' & `l1' & `l2' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
display "Loadings table saved to `FININST_TAB'/fin_trust_loadings.tex"

capture confirm variable age_bin
if _rc {
    capture confirm variable age_2020
    if !_rc gen int age_bin = floor(age_2020/5)*5
}

file open fh using "`FININST_TAB'/fin_trust_summary.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n "\caption{Financial-institutional trust: summary (2020)}" _n "\label{tab:fin_trust_summary}" _n "\begin{tabular}{lrr}\toprule" _n "Variable & N & Mean \\\\ \midrule" _n

* Three component vars + aggregate (N and Mean only)
foreach v in trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020 {
    capture confirm variable `v'
    if !_rc {
        quietly summarize `v' if !missing(`v'), detail
        if r(N) > 0 {
            local n_s = string(r(N), "%9.0f")
            local m_s = string(r(mean), "%9.2f")
            local vlab = cond("`v'"=="trust_banks_2020", "Banks", cond("`v'"=="trust_advisors_2020", "Financial advisors", "Mutual funds"))
            file write fh "`vlab' & `n_s' & `m_s' \\\\" _n
        }
    }
}
capture confirm variable trust_fin_avg_2020
if !_rc {
    quietly summarize trust_fin_avg_2020 if !missing(trust_fin_avg_2020), detail
    if r(N) > 0 {
        local n_s = string(r(N), "%9.0f")
        local m_s = string(r(mean), "%9.2f")
        file write fh "Trust in Fin. Institutions & `n_s' & `m_s' \\\\" _n
    }
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh

display "Descriptive table saved to `FININST_TAB'/fin_trust_summary.tex"

* Correlation table: general trust + 3 fin-institution trust components
preserve
keep trust_others_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020
keep if !missing(trust_others_2020, trust_banks_2020, trust_advisors_2020, trust_mutual_funds_2020)
quietly correlate trust_others_2020 trust_banks_2020 trust_advisors_2020 trust_mutual_funds_2020
matrix C = r(C)
file open fh using "`FININST_TAB'/fin_trust_components_corr.tex", write replace
file write fh "\begin{table}[htbp]\centering\small" _n ///
    "\caption{.}" _n ///
    "\label{tab:fin_trust_components_corr}" _n ///
    "\begin{tabular}{lrrrr}\toprule" _n ///
    " & General trust & Banks & Financial advisors & Mutual funds \\\\ \midrule" _n
forvalues i = 1/4 {
    local rowlab = cond(`i'==1,"General trust",cond(`i'==2,"Banks",cond(`i'==3,"Financial advisors","Mutual funds")))
    local line "`rowlab'"
    forvalues j = 1/4 {
        local cij = string(C[`i',`j'], "%6.3f")
        local line "`line' & `cij'"
    }
    file write fh "`line' \\\\" _n
}
file write fh "\bottomrule" _n "\end{tabular}\end{table}" _n
file close fh
restore
display "Correlation table saved to `FININST_TAB'/fin_trust_components_corr.tex"

* ----------------------------------------------------------------------
* Save wide with fin trust vars for merge to panel
* ----------------------------------------------------------------------
preserve
keep hhidpn trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020 trust_fin_avg_2020
duplicates drop hhidpn, force
tempfile fin_trust_wide
save `fin_trust_wide'
restore

* ----------------------------------------------------------------------
* Base controls (r5: wealth deciles)
* ----------------------------------------------------------------------
local ctrl_r5 "i.age_bin i.gender educ_yrs inlbrf_2020 married_2020 born_us i.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'_2020"
}

* ----------------------------------------------------------------------
* 3. CROSS SECTION: r5_annual_w5_2022
* ----------------------------------------------------------------------
display _n "########################################################################"
display "3. CROSS SECTION: r5 (5% wins) 2022"
display "########################################################################"

foreach trust_agg in trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020 trust_fin_avg_2020 {
    local stub = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "pc1_wgen", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "pc2_wgen", "avg"))
    local tlab = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "Fin. Inst. PC1", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "Fin. Inst. PC2", "Fin. Institutions"))
    local ttag = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", " (PC1)", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", " (PC2)", ""))
    local keep_cs "`trust_agg' c.`trust_agg'#c.`trust_agg' educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_2020 married_2020 born_us _cons"
    gen byte _samp = !missing(r5_annual_w5_2022) & !missing(`trust_agg')
    quietly count if _samp
    display "  `trust_agg': N = " r(N)
    eststo clear
    eststo m1: regress r5_annual_w5_2022 `ctrl_r5' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m1
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m1
    }
    else estadd scalar p_joint_wealth = . : m1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m1
    eststo m2: regress r5_annual_w5_2022 `ctrl_r5' c.`trust_agg' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m2
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m2
    }
    else estadd scalar p_joint_wealth = . : m2
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m2
    eststo m3: regress r5_annual_w5_2022 `ctrl_r5' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m3
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m3
    }
    else estadd scalar p_joint_wealth = . : m3
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m3
    esttab m1 m2 m3 using "`FININST_TAB'/fin_trust_`stub'_cross_section.tex", replace ///
        booktabs mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_cs') ///
        varlabels(`trust_agg' "Trust" c.`trust_agg'#c.`trust_agg' "Trust\$^2\$" ///
            2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value")) ///
        title("Cross section: r5 returns (${LATEX_PCT} wins) on financial-institutional trust`ttag'") ///
        addnotes(".") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes
    drop _samp
}

* ----------------------------------------------------------------------
* 4. AVERAGE RETURNS: r5_annual_avg_w5
* ----------------------------------------------------------------------
display _n "########################################################################"
display "4. AVERAGE RETURNS: r5 (5% wins) avg"
display "########################################################################"

foreach trust_agg in trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020 trust_fin_avg_2020 {
    local stub = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "pc1_wgen", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "pc2_wgen", "avg"))
    local tlab = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "Fin. Inst. PC1", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "Fin. Inst. PC2", "Fin. Institutions"))
    local ttag = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", " (PC1)", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", " (PC2)", ""))
    local keep_cs "`trust_agg' c.`trust_agg'#c.`trust_agg' educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_2020 married_2020 born_us _cons"
    gen byte _samp = !missing(r5_annual_avg_w5) & !missing(`trust_agg')
    quietly count if _samp
    display "  `trust_agg': N = " r(N)
    eststo clear
    eststo m1: regress r5_annual_avg_w5 `ctrl_r5' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m1
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m1
    }
    else estadd scalar p_joint_wealth = . : m1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m1
    eststo m2: regress r5_annual_avg_w5 `ctrl_r5' c.`trust_agg' if _samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m2
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m2
    }
    else estadd scalar p_joint_wealth = . : m2
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m2
    eststo m3: regress r5_annual_avg_w5 `ctrl_r5' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m3
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'_2020
        if !_rc local wlist "`wlist' wealth_d`d'_2020"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m3
    }
    else estadd scalar p_joint_wealth = . : m3
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m3
    esttab m1 m2 m3 using "`FININST_TAB'/fin_trust_`stub'_avg.tex", replace ///
        booktabs mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_cs') ///
        varlabels(`trust_agg' "Trust" c.`trust_agg'#c.`trust_agg' "Trust\$^2\$" ///
            2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value")) ///
        title("Average r5 returns (${LATEX_PCT} wins) on financial-institutional trust`ttag'") ///
        addnotes(".") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes
    drop _samp
}

* ----------------------------------------------------------------------
* 5. PANEL: spec 1, 2, 3 for r5 wins
* ----------------------------------------------------------------------
display _n "########################################################################"
display "5. PANEL: r5 (5% wins) spec 1–3"
display "########################################################################"

use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
merge m:1 hhidpn using `fin_trust_wide', nogen
xtset hhidpn year

local base_ctrl "i.age_bin educ_yrs i.gender i.race_eth inlbrf married born_us i.censreg"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local base_ctrl "`base_ctrl' wealth_d`d'"
}
local ctrl_s2 "`base_ctrl' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"
local share_cond "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

foreach trust_agg in trust_fin_pc1_wgen_2020 trust_fin_pc2_wgen_2020 trust_fin_avg_2020 {
    local stub = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "pc1_wgen", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "pc2_wgen", "avg"))
    local tlab = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", "Fin. Inst. PC1", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", "Fin. Inst. PC2", "Fin. Institutions"))
    local ttag = cond("`trust_agg'"=="trust_fin_pc1_wgen_2020", " (PC1)", cond("`trust_agg'"=="trust_fin_pc2_wgen_2020", " (PC2)", ""))
    local keep_p "`trust_agg' c.`trust_agg'#c.`trust_agg' educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth inlbrf_ married_ born_us _cons"

    gen byte _samp = !missing(r5_annual_w5) & `share_cond' & !missing(`trust_agg')
    quietly count if _samp
    display "  `trust_agg': N (obs) = " r(N)

    * Spec 1 (pooled)
    eststo clear
    eststo m1: regress r5_annual_w5 `base_ctrl' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m1
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m1
    }
    else estadd scalar p_joint_wealth = . : m1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m1
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m1
    else estadd scalar p_joint_censreg = . : m1
    eststo m2: regress r5_annual_w5 `base_ctrl' c.`trust_agg' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m2
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m2
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m2
    }
    else estadd scalar p_joint_wealth = . : m2
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m2
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m2
    else estadd scalar p_joint_censreg = . : m2
    eststo m3: regress r5_annual_w5 `base_ctrl' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(cluster hhidpn)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m3
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m3
    }
    else estadd scalar p_joint_wealth = . : m3
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m3
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m3
    else estadd scalar p_joint_censreg = . : m3
    esttab m1 m2 m3 using "`FININST_TAB'/fin_trust_`stub'_panel1.tex", replace ///
        booktabs mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_p') ///
        varlabels(`trust_agg' "Trust" c.`trust_agg'#c.`trust_agg' "Trust\$^2\$" ///
            2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S.") ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value")) ///
        title("Panel Spec 1 (pooled): r5 returns on financial-institutional trust`ttag'") ///
        addnotes(".") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

    * Spec 2 (share×year)
    eststo clear
    eststo m1: regress r5_annual_w5 `ctrl_s2' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m1
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m1
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m1
    }
    else estadd scalar p_joint_wealth = . : m1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m1
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m1
    else estadd scalar p_joint_censreg = . : m1
    quietly testparm i.year
    estadd scalar p_joint_year = r(p) : m1
    eststo m2: regress r5_annual_w5 `ctrl_s2' c.`trust_agg' if _samp, vce(cluster hhidpn)
    estadd scalar p_joint_trust = . : m2
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m2
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m2
    }
    else estadd scalar p_joint_wealth = . : m2
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m2
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m2
    else estadd scalar p_joint_censreg = . : m2
    quietly testparm i.year
    estadd scalar p_joint_year = r(p) : m2
    eststo m3: regress r5_annual_w5 `ctrl_s2' c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _samp, vce(cluster hhidpn)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    quietly testparm i.age_bin
    estadd scalar p_joint_age_bin = r(p) : m3
    local wlist ""
    forvalues d = 2/10 {
        capture confirm variable wealth_d`d'
        if !_rc local wlist "`wlist' wealth_d`d'"
    }
    if trim("`wlist'") != "" {
        quietly testparm `wlist'
        estadd scalar p_joint_wealth = r(p) : m3
    }
    else estadd scalar p_joint_wealth = . : m3
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m3
    capture testparm i.censreg
    if _rc == 0 estadd scalar p_joint_censreg = r(p) : m3
    else estadd scalar p_joint_censreg = . : m3
    quietly testparm i.year
    estadd scalar p_joint_year = r(p) : m3
    esttab m1 m2 m3 using "`FININST_TAB'/fin_trust_`stub'_panel2.tex", replace ///
        booktabs mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_p') ///
        varlabels(`trust_agg' "Trust" c.`trust_agg'#c.`trust_agg' "Trust\$^2\$" ///
            2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years education" inlbrf_ "In labor force" married_ "Married" born_us "Born in U.S.") ///
        stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race p_joint_censreg p_joint_year, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Wealth deciles p-value" "Joint test: Race p-value" "Joint test: Region p-value" "Joint test: Year p-value")) ///
        title("Panel Spec 2 (${LATEX_SHARE_YEAR}): r5 returns on financial-institutional trust`ttag'") ///
        addnotes(".") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes

    * Spec 3 (FE + second stage)
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
    if "`trust_agg'" == "trust_fin_avg_2020" {
        quietly summarize fe_r5 if _fe_samp, detail
        local p1 = r(p1)
        local p99 = r(p99)
        gen double fe_r5_w1 = fe_r5
        replace fe_r5_w1 = `p1' if fe_r5_w1 < `p1' & _fe_samp
        replace fe_r5_w1 = `p99' if fe_r5_w1 > `p99' & _fe_samp
        twoway scatter fe_r5_w1 `trust_agg' if _fe_samp, msize(tiny) msymbol(circle) ///
            title("FE vs Trust in Fin. Institutions (${LATEX_WIN_SHORT})") ///
            xtitle("Trust in Fin. Institutions") ytitle("Estimated FE") ///
            scheme(s2color)
        graph export "${REGRESSIONS}/Trust/FinInst/Figures/fe_vs_trust_fininst_avg.png", replace width(1200)
        di as txt "Wrote: fe_vs_trust_fininst_avg.png"
        drop fe_r5_w1
    }
    local keep_p3 "`trust_agg' c.`trust_agg'#c.`trust_agg' educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth born_us _cons"
    eststo clear
    eststo m1: regress fe_r5 educ_yrs i.gender i.race_eth born_us if _fe_samp, vce(robust)
    estadd scalar p_joint_trust = . : m1
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m1
    eststo m2: regress fe_r5 educ_yrs i.gender i.race_eth born_us c.`trust_agg' if _fe_samp, vce(robust)
    estadd scalar p_joint_trust = . : m2
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m2
    eststo m3: regress fe_r5 educ_yrs i.gender i.race_eth born_us c.`trust_agg' c.`trust_agg'#c.`trust_agg' if _fe_samp, vce(robust)
    quietly testparm c.`trust_agg' c.`trust_agg'#c.`trust_agg'
    estadd scalar p_joint_trust = r(p) : m3
    quietly testparm i.race_eth
    estadd scalar p_joint_race = r(p) : m3
    esttab m1 m2 m3 using "`FININST_TAB'/fin_trust_`stub'_panel3.tex", replace ///
        booktabs mtitles("(1)" "(2)" "(3)") ///
        se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
        keep(`keep_p3') ///
        varlabels(`trust_agg' "Trust" c.`trust_agg'#c.`trust_agg' "Trust\$^2\$" ///
            educ_yrs "Years education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" born_us "Born in U.S.") ///
        stats(N r2_a p_joint_trust p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Race p-value")) ///
        title("Panel Spec 3 (FE, 2nd stage): r5 returns on financial-institutional trust`ttag'") ///
        addnotes(".") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers nonotes
    restore
    drop _fe_r5 fe_r5 _samp _fe_cond
}

display _n "Done. Tables saved to `FININST_TAB'"
display "Log: ${LOG_DIR}/25_reg_trust_fininst.log"
log close
