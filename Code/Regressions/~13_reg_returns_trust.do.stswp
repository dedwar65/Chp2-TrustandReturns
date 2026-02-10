* 13_reg_returns_trust.do
* Cross-sectional OLS: 2022 returns (r1, r4, r5) on 2020 trust.
* One table per trust variable; each table has 6 columns: r1, r4, r5 × no controls | with controls.
* Spec1 = linear trust; Spec2 = trust + trust^2. Unwinsorized and winsorized in separate files (filename _win).
* Controls (old repo): age bins, gender, educ, inlbrf, married, born_us, race_eth, scope-appropriate wealth deciles.
* Table: omit wealth from display; indicate "Wealth deciles"; drop base categories. Full regression results in log.
* vce(robust). Log: Notes/Logs/13_reg_returns_trust.log.
* Output: Regressions/Returns/Spec1/returns_trust_<trust_stub>.tex, returns_trust_<trust_stub>_win.tex; same for Spec2.

clear
set more off

* ----------------------------------------------------------------------
* Paths and config
* ----------------------------------------------------------------------
capture confirm global BASE_PATH
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") { cd .. }
    if regexm("`c(pwd)'", "[\/]Raw data$") { cd ..; cd .. }
    if regexm("`c(pwd)'", "[\/]Code$") { cd .. }
    global BASE_PATH "`c(pwd)'"
    do "${BASE_PATH}/Code/Raw data/00_config.do"
}

capture mkdir "${REGRESSIONS}/Returns/Spec1"
capture mkdir "${REGRESSIONS}/Returns/Spec2"

capture log close
log using "${LOG_DIR}/13_reg_returns_trust.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

capture confirm variable age_2020
if !_rc {
    gen int age_bin = floor(age_2020/5)*5
}

* Trust variables: same list as 12 (8 items + PC1, PC2)
local trust_list "trust_others_2020:general trust_social_security_2020:social_security trust_medicare_2020:medicare trust_banks_2020:banks trust_advisors_2020:advisors trust_mutual_funds_2020:mutual_funds trust_insurance_2020:insurance trust_media_2020:media trust_pc1:pc1 trust_pc2:pc2"

* Return variables: 2022 only. Unwinsorized and winsorized (two passes)
local ret_unwin "r1_annual_2022 r4_annual_2022 r5_annual_2022"
local ret_win   "r1_annual_win_2022 r4_annual_win_2022 r5_annual_win_2022"

* Base controls (old repo: no depression/health/medicare etc.)
local demo_core "i.gender educ_yrs married_2020 born_us"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc {
    local demo_core "i.age_bin `demo_core'"
}
capture confirm variable race_eth
if _rc {
    local demo_race ""
}
local ctrl_base "`demo_core' `demo_race' inlbrf_2020"

* Build drop list for esttab: all wealth deciles + base factor levels
local drop_list "1.gender 1.race_eth"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local drop_list "`drop_list' wealth_d`d'_2020"
    capture confirm variable wealth_core_d`d'_2020
    if !_rc local drop_list "`drop_list' wealth_core_d`d'_2020"
    capture confirm variable wealth_coreira_d`d'_2020
    if !_rc local drop_list "`drop_list' wealth_coreira_d`d'_2020"
}

* Indicate row: one wealth var per scope so "With controls" columns show Yes
local indicate_wealth ""
capture confirm variable wealth_d2_2020
if !_rc local indicate_wealth "`indicate_wealth' wealth_d2_2020"
capture confirm variable wealth_core_d2_2020
if !_rc local indicate_wealth "`indicate_wealth' wealth_core_d2_2020"
capture confirm variable wealth_coreira_d2_2020
if !_rc local indicate_wealth "`indicate_wealth' wealth_coreira_d2_2020"

* Variable labels (for coefficient rows)
label variable age_bin "Age (5-yr bin)"
label variable educ_yrs "Years of education"
label variable married_2020 "Married"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable inlbrf_2020 "In labor force"
label variable trust_others_2020 "General trust"
label variable trust_social_security_2020 "Trust Social Security"
label variable trust_medicare_2020 "Trust Medicare"
label variable trust_banks_2020 "Trust banks"
label variable trust_advisors_2020 "Trust financial advisors"
label variable trust_mutual_funds_2020 "Trust mutual funds"
label variable trust_insurance_2020 "Trust insurance"
label variable trust_media_2020 "Trust media"
label variable trust_pc1 "Trust PC1"
label variable trust_pc2 "Trust PC2"

* ----------------------------------------------------------------------
* Spec1 (linear) then Spec2 (quadratic); then unwinsorized vs winsorized; then each trust var
* ----------------------------------------------------------------------
forvalues spec = 1/2 {
    local spec_dir "Spec1"
    local spec_note "Trust entered linearly."
    if `spec' == 2 {
        local spec_dir "Spec2"
        local spec_note "Trust and trust squared."
    }

    * Unwinsorized then winsorized
    forvalues win = 0/1 {
        local ret_list "`ret_unwin'"
        local file_suffix ""
        if `win' == 1 {
            local ret_list "`ret_win'"
            local file_suffix "_win"
        }

        foreach pair of local trust_list {
            gettoken trust_var stub : pair, parse(":")
            if "`stub'" == ":" local stub : subinstr local pair "`trust_var':" "", all
            local stub = trim("`stub'")

            capture confirm variable `trust_var'
            if _rc {
                di as txt "Skipping trust (not found): `trust_var'"
                continue
            }

            * Check return vars exist
            local skip 0
            foreach y of local ret_list {
                capture confirm variable `y'
                if _rc local skip 1
            }
            if `skip' {
                di as txt "Skipping `stub': return variable(s) not found."
                continue
            }

            * Build full controls for each return (scope-appropriate wealth)
            local full_r1 "`ctrl_base'"
            local full_r4 "`ctrl_base'"
            local full_r5 "`ctrl_base'"
            forvalues d = 2/10 {
                capture confirm variable wealth_core_d`d'_2020
                if !_rc local full_r1 "`full_r1' wealth_core_d`d'_2020"
                capture confirm variable wealth_coreira_d`d'_2020
                if !_rc local full_r4 "`full_r4' wealth_coreira_d`d'_2020"
                capture confirm variable wealth_d`d'_2020
                if !_rc local full_r5 "`full_r5' wealth_d`d'_2020"
            }

            local r1_var : word 1 of `ret_list'
            local r4_var : word 2 of `ret_list'
            local r5_var : word 3 of `ret_list'
            quietly count if !missing(`r1_var') & !missing(`trust_var')
            if r(N) < 50 {
                di as txt "Skipping `stub'`file_suffix': too few obs."
                continue
            }

            eststo clear
            * 6 regressions (noisily so full output in log)
            if `spec' == 1 {
                noisily eststo r1_raw: regress `r1_var' c.`trust_var' if !missing(`r1_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r2_raw: regress `r4_var' c.`trust_var' if !missing(`r4_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r3_raw: regress `r5_var' c.`trust_var' if !missing(`r5_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r1_ctl: regress `r1_var' c.`trust_var' `full_r1' if !missing(`r1_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r2_ctl: regress `r4_var' c.`trust_var' `full_r4' if !missing(`r4_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r3_ctl: regress `r5_var' c.`trust_var' `full_r5' if !missing(`r5_var') & !missing(`trust_var'), vce(robust)
            } else {
                noisily eststo r1_raw: regress `r1_var' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`r1_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r2_raw: regress `r4_var' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`r4_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r3_raw: regress `r5_var' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`r5_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r1_ctl: regress `r1_var' c.`trust_var' c.`trust_var'#c.`trust_var' `full_r1' if !missing(`r1_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r2_ctl: regress `r4_var' c.`trust_var' c.`trust_var'#c.`trust_var' `full_r4' if !missing(`r4_var') & !missing(`trust_var'), vce(robust)
                noisily eststo r3_ctl: regress `r5_var' c.`trust_var' c.`trust_var'#c.`trust_var' `full_r5' if !missing(`r5_var') & !missing(`trust_var'), vce(robust)
            }

            local outfile "${REGRESSIONS}/Returns/`spec_dir'/returns_trust_`stub'`file_suffix'.tex"
            di as txt "Writing: `outfile'"

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"

            * varlabels: trust and trust^2 (use variable label for trust)
            local vlab_trust2 "Trust squared"
            if `spec' == 2 local vlab_trust2 "Trust\$^{2}\$"

            if "`indicate_wealth'" != "" {
                esttab r1_raw r2_raw r3_raw r1_ctl r2_ctl r3_ctl using "`outfile'", replace ///
                    booktabs ///
                    mtitles("r1" "r4" "r5" "r1" "r4" "r5") ///
                    posthead("& \multicolumn{3}{c}{No controls} & \multicolumn{3}{c}{With controls} \\\\ \cmidrule(lr){2-4} \cmidrule(lr){5-7}") ///
                    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
                    drop(`drop_list') ///
                    indicate("Wealth deciles = `indicate_wealth'", labels("No" "Yes")) ///
                    varlabels(c.`trust_var'#c.`trust_var' "`vlab_trust2'" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" age_bin "Age (5-yr bin)" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
                    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                    title("2022 returns (r1, r4, r5) on `capt_stub' trust (2020). `spec_note'") ///
                    addnotes("Robust standard errors in parentheses. Returns 2022, trust and controls 2020." "Wealth deciles (scope-appropriate) included in control columns; full results in log.") ///
                    alignment(D{.}{.}{-1}) width(0.85\hsize) nonumbers
            } else {
                esttab r1_raw r2_raw r3_raw r1_ctl r2_ctl r3_ctl using "`outfile'", replace ///
                    booktabs ///
                    mtitles("r1" "r4" "r5" "r1" "r4" "r5") ///
                    posthead("& \multicolumn{3}{c}{No controls} & \multicolumn{3}{c}{With controls} \\\\ \cmidrule(lr){2-4} \cmidrule(lr){5-7}") ///
                    se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
                    drop(`drop_list') ///
                    varlabels(c.`trust_var'#c.`trust_var' "`vlab_trust2'" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" age_bin "Age (5-yr bin)" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
                    stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                    title("2022 returns (r1, r4, r5) on `capt_stub' trust (2020). `spec_note'") ///
                    addnotes("Robust standard errors in parentheses. Returns 2022, trust and controls 2020." "Full results in log.") ///
                    alignment(D{.}{.}{-1}) width(0.85\hsize) nonumbers
            }

            tempfile tmpf
            file open fh using "`outfile'", read text
            file open fout using "`tmpf'", write text replace
            local lab_inserted 0
            file read fh line
            while r(eof) == 0 {
                file write fout "`line'" _n
                if `lab_inserted' == 0 & regexm(`"`line'"', "\\caption") {
                    file write fout "\label{tab:returns_trust_`stub'`file_suffix'_spec`spec'}" _n
                    local lab_inserted 1
                }
                file read fh line
            }
            file close fh
            file close fout
            copy "`tmpf'" "`outfile'", replace
        }
    }
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Returns/Spec1/ and ${REGRESSIONS}/Returns/Spec2/"
log close
