* 12_reg_income_trust.do
* Cross-sectional OLS: 2020 income (final) on 2020 trust — one table per trust variable per spec.
* Spec1 = linear trust; Spec2 = quadratic trust (trust + trust^2).
* For each (trust var, spec): four columns — ln_lab no ctrl | ln_tot no ctrl | ln_lab with ctrl | ln_tot with ctrl.
* Standard errors: vce(robust). Log: Notes/Logs/12_reg_income_trust.log.
* Output: Regressions/Income/Spec1/income_trust_<stub>.tex, Regressions/Income/Spec2/income_trust_<stub>.tex.

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

capture mkdir "${REGRESSIONS}/Income"
capture mkdir "${REGRESSIONS}/Income/Spec1"
capture mkdir "${REGRESSIONS}/Income/Spec2"

capture log close
log using "${LOG_DIR}/12_reg_income_trust.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load data and create age bins
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear

capture confirm variable age_2020
if !_rc {
    gen int age_bin = floor(age_2020/5)*5
}

* Trust variables: 8 items + 2 PCs (var:stub for filename)
local trust_list "trust_others_2020:general trust_social_security_2020:social_security trust_medicare_2020:medicare trust_banks_2020:banks trust_advisors_2020:advisors trust_mutual_funds_2020:mutual_funds trust_insurance_2020:insurance trust_media_2020:media trust_pc1:pc1 trust_pc2:pc2"

* Income LHS (2020 final)
local inc_lab "ln_lab_inc_final_2020"
local inc_tot "ln_tot_inc_final_2020"

* Full controls
local demo_core "i.gender educ_yrs married_2020 immigrant born_us"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc {
    local demo_core "i.age_bin `demo_core'"
}
capture confirm variable race_eth
if _rc {
    local demo_race ""
}
local extra_ctrl "depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 beq_any_2020 num_divorce_2020 num_widow_2020"
local extra_opt "inlbrf_2020"
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'_2020
    if !_rc local extra_opt "`extra_opt' wealth_d`d'_2020"
}
local full_ctrl "`demo_core' `demo_race' `extra_ctrl'"
foreach v of local extra_opt {
    capture confirm variable `v'
    if !_rc local full_ctrl "`full_ctrl' `v'"
}

* Variable labels
label variable age_bin "Age (5-yr bin)"
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
label variable ln_lab_inc_final_2020 "Log labor income (final, 2020)"
label variable ln_tot_inc_final_2020 "Log total income (final, 2020)"
label variable educ_yrs "Years of education"
label variable married_2020 "Married"
label variable immigrant "Immigrant"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable depression_2020 "Depression"
label variable health_cond_2020 "Health conditions"
label variable medicare_2020 "Medicare"
label variable medicaid_2020 "Medicaid"
label variable life_ins_2020 "Life insurance"
label variable beq_any_2020 "Bequest"
label variable num_divorce_2020 "Times divorced"
label variable num_widow_2020 "Times widowed"
label variable inlbrf_2020 "Labor force status"

* ----------------------------------------------------------------------
* Spec1 (linear trust) then Spec2 (quadratic trust); for each: all trust vars, 4 cols per table
* ----------------------------------------------------------------------
forvalues spec = 1/2 {
    local spec_dir "Spec1"
    local spec_title "linear"
    local spec_note "Trust entered linearly."
    if `spec' == 2 {
        local spec_dir "Spec2"
        local spec_title "quadratic"
        local spec_note "Trust and trust squared."
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

        local skip 0
        foreach y in inc_lab inc_tot {
            capture confirm variable ``y''
            if _rc local skip 1
        }
        if `skip' {
            di as txt "Skipping `stub': income variable(s) not found."
            continue
        }
        quietly count if !missing(`inc_lab') & !missing(`inc_tot') & !missing(`trust_var')
        if r(N) < 50 {
            di as txt "Skipping `stub': too few obs (N=" r(N) ")."
            continue
        }

        eststo clear
        if `spec' == 1 {
            * Linear: trust only
            eststo lab_raw: regress `inc_lab' c.`trust_var' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            eststo tot_raw: regress `inc_tot' c.`trust_var' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            eststo lab_ctl: regress `inc_lab' c.`trust_var' `full_ctrl' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            eststo tot_ctl: regress `inc_tot' c.`trust_var' `full_ctrl' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
        } else {
            * Quadratic: trust + trust^2
            eststo lab_raw: regress `inc_lab' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            eststo tot_raw: regress `inc_tot' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            eststo lab_ctl: regress `inc_lab' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            eststo tot_ctl: regress `inc_tot' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
        }

        local outfile "${REGRESSIONS}/Income/`spec_dir'/income_trust_`stub'.tex"
        di as txt "Writing: `outfile'"

        local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
        local capt_stub = subinstr("`capt_stub'", "_", " ", .)
        if "`stub'" == "pc1" local capt_stub "PC1"
        if "`stub'" == "pc2" local capt_stub "PC2"

        esttab lab_raw tot_raw lab_ctl tot_ctl using "`outfile'", replace ///
            booktabs ///
            mtitles("Labor income" "Total income" "Labor income" "Total income") ///
            posthead("& \multicolumn{2}{c}{No controls} & \multicolumn{2}{c}{With controls} \\\\ \cmidrule(lr){2-3} \cmidrule(lr){4-5}") ///
            se star(* 0.10 ** 0.05 *** 0.01) ///
            b(2) se(2) label ///
            title("Log income (2020) on `capt_stub' trust (2020), `spec_title'") ///
            alignment(D{.}{.}{-1}) width(0.85\hsize) ///
            addnotes("Robust standard errors in parentheses. Income and trust from 2020. `spec_note'") ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            nonumbers

        * Insert \label after \caption
        tempfile tmpf
        file open fh using "`outfile'", read text
        file open fout using "`tmpf'", write text replace
        local lab_inserted 0
        file read fh line
        while r(eof) == 0 {
            file write fout "`line'" _n
            if `lab_inserted' == 0 & regexm(`"`line'"', "\\caption") {
                file write fout "\label{tab:income_trust_`stub'_spec`spec'}" _n
                local lab_inserted 1
            }
            file read fh line
        }
        file close fh
        file close fout
        copy "`tmpf'" "`outfile'", replace
    }
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Income/Spec1/ and ${REGRESSIONS}/Income/Spec2/"
log close
