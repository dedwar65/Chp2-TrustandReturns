* 12_reg_income_trust.do
* Cross-sectional OLS: 2020 income (final) on 2020 trust — one table per trust variable per spec.
* Spec1 = linear trust; Spec2 = quadratic trust (trust + trust^2).
* For each (trust var, spec): four columns — ln_lab no ctrl | ln_tot no ctrl | ln_lab with ctrl | ln_tot with ctrl.
* Age: 5-yr bins (omitted from table display in columns 3–4).
* Standard errors: vce(robust). Log: Notes/Logs/12_reg_income_trust.log.
* Output: Regressions/Income/Labor/, Income/Total/ — income_trust_<stub>_log.tex, income_trust_<stub>_ihs.tex.

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

capture mkdir "${REGRESSIONS}/Income"

capture log close
log using "${LOG_DIR}/12_reg_income_trust.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load data; controls match old repo reg_inc_trust_2020: age quad, gender, educ, inlbrf, married, born_us, race (no depression/health/medicare/medicaid/life_ins/bequest/divorce/widow, no wealth)
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

* Age: 5-yr bins
capture confirm variable age_2020
if !_rc {
    gen int age_bin = floor(age_2020/5)*5
}

* Trust variables: 8 items + 2 PCs (var:stub for filename)
local trust_list "trust_others_2020:general trust_social_security_2020:social_security trust_medicare_2020:medicare trust_banks_2020:banks trust_advisors_2020:advisors trust_mutual_funds_2020:mutual_funds trust_insurance_2020:insurance trust_media_2020:media trust_pc1:pc1 trust_pc2:pc2"

* Income LHS (2020 final)
local inc_lab "ln_lab_inc_final_2020"
local inc_tot "ln_tot_inc_final_2020"

* Full controls = age 5-yr bins, gender, educ, inlbrf, married, born_us, race_eth
local full_ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local full_ctrl "i.age_bin `full_ctrl'"
capture confirm variable inlbrf_2020
if !_rc local full_ctrl "`full_ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local full_ctrl "`full_ctrl' i.race_eth"

* Drop list for esttab: base factor levels + age bins (omit from display; built from coef names per block)

* Variable labels (match old repo table: Age (5-yr bin), Female, NH Black, Hispanic, NH Other, Years of education, In labor force, Married, Born in U.S.)
label variable age_bin "Age (5-yr bin)"
label variable educ_yrs "Years of education"
label variable inlbrf_2020 "In labor force"
label variable married_2020 "Married"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable trust_others_2020 "General trust"
label variable trust_social_security_2020 "Trust Social Security"
label variable trust_medicare_2020 "Trust Medicare"
label variable trust_banks_2020 "Trust banks"
label variable trust_advisors_2020 "Trust financial advisors"
label variable trust_mutual_funds_2020 "Trust mutual funds"
label variable trust_insurance_2020 "Trust insurance"
label variable trust_media_2020 "Trust media"
capture confirm variable trust_pc1
if !_rc label variable trust_pc1 "Trust PC1"
capture confirm variable trust_pc2
if !_rc label variable trust_pc2 "Trust PC2"
label variable ln_lab_inc_final_2020 "Log labor income (final, 2020)"
label variable ln_tot_inc_final_2020 "Log total income (final, 2020)"
capture confirm variable ihs_lab_inc_defl_win_s_2020
if !_rc label variable ihs_lab_inc_defl_win_s_2020 "Scaled asinh labor income (deflated, winsorized, 2020)"
capture confirm variable ihs_tot_inc_defl_win_s_2020
if !_rc label variable ihs_tot_inc_defl_win_s_2020 "Scaled asinh total income (deflated, winsorized, 2020)"

* ----------------------------------------------------------------------
* Regressions: income on trust (2020), by outcome (labor vs total)
* ----------------------------------------------------------------------
capture mkdir "${REGRESSIONS}/Income/Labor"
capture mkdir "${REGRESSIONS}/Income/Total"

foreach pair of local trust_list {
    * Robustly split var:stub so filenames never contain colons
    local pos = strpos("`pair'", ":")
    if `pos' == 0 continue
    local trust_var = substr("`pair'", 1, `pos' - 1)
    local stub      = substr("`pair'", `pos' + 1, .)
    local stub      = trim("`stub'")

    capture confirm variable `trust_var'
    if _rc {
        di as txt "Skipping trust (not found): `trust_var'"
        continue
    }

    * ------------------------------------------------------------------
    * Labor income (log): ln_lab_inc_final_2020
    * ------------------------------------------------------------------
    capture confirm variable `inc_lab'
    if _rc {
        di as txt "Skipping `stub' labor log: ln_lab_inc_final_2020 not found."
    }
    else {
        quietly count if !missing(`inc_lab') & !missing(`trust_var')
        if r(N) < 50 {
            di as txt "Skipping `stub' labor log: too few obs (N=" r(N) ")."
        }
        else {
            eststo clear
            * 1. Trust only
            eststo lab_lin_raw: regress `inc_lab' c.`trust_var' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : lab_lin_raw
            estadd scalar p_joint_age_bin = . : lab_lin_raw
            estadd scalar p_joint_race = . : lab_lin_raw
            * 2. Trust + trust^2
            eststo lab_quad_raw: regress `inc_lab' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : lab_quad_raw
            estadd scalar p_joint_age_bin = . : lab_quad_raw
            estadd scalar p_joint_race = . : lab_quad_raw
            * 3. Trust + controls
            eststo lab_lin_ctl: regress `inc_lab' c.`trust_var' `full_ctrl' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : lab_lin_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : lab_lin_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : lab_lin_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : lab_lin_ctl
            }
            else {
                estadd scalar p_joint_race = . : lab_lin_ctl
            }
            * 4. Trust + trust^2 + controls
            eststo lab_quad_ctl: regress `inc_lab' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_lab') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : lab_quad_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : lab_quad_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : lab_quad_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : lab_quad_ctl
            }
            else {
                estadd scalar p_joint_race = . : lab_quad_ctl
            }

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"
            local trust_part "`capt_stub'"
            if "`stub'" == "general" local trust_part "general"

            local outfile_lab "${REGRESSIONS}/Income/Labor/income_trust_`stub'_log.tex"
            di as txt "Writing (labor, log): `outfile_lab'"

            local drop_12 "1.gender 1.race_eth"
            capture confirm variable age_bin
            if !_rc {
                estimates restore lab_lin_ctl
                local cnames : colnames e(b)
                foreach c of local cnames {
                    if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_12 "`drop_12' `c'"
                }
            }

            esttab lab_lin_raw lab_quad_raw lab_lin_ctl lab_quad_ctl using "`outfile_lab'", replace ///
                booktabs ///
                mtitles("1" "2" "3" "4") ///
                se star(* 0.10 ** 0.05 *** 0.01) ///
                b(2) se(2) label ///
                drop(`drop_12' *.age_bin) ///
                varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant") ///
                title("Labor income (2020) on `trust_part' trust") ///
                addnotes(".") ///
                alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
                stats(N r2_a p_joint_trust p_joint_age_bin p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Race p-value")) ///
                nonumbers nonotes
        }
    }

    * ------------------------------------------------------------------
    * Total income (log): ln_tot_inc_final_2020
    * ------------------------------------------------------------------
    capture confirm variable `inc_tot'
    if _rc {
        di as txt "Skipping `stub' total log: ln_tot_inc_final_2020 not found."
    }
    else {
        quietly count if !missing(`inc_tot') & !missing(`trust_var')
        if r(N) < 50 {
            di as txt "Skipping `stub' total log: too few obs (N=" r(N) ")."
        }
        else {
            eststo clear
            * 1. Trust only
            eststo tot_lin_raw: regress `inc_tot' c.`trust_var' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : tot_lin_raw
            estadd scalar p_joint_age_bin = . : tot_lin_raw
            estadd scalar p_joint_race = . : tot_lin_raw
            * 2. Trust + trust^2
            eststo tot_quad_raw: regress `inc_tot' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : tot_quad_raw
            estadd scalar p_joint_age_bin = . : tot_quad_raw
            estadd scalar p_joint_race = . : tot_quad_raw
            * 3. Trust + controls
            eststo tot_lin_ctl: regress `inc_tot' c.`trust_var' `full_ctrl' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : tot_lin_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : tot_lin_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : tot_lin_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : tot_lin_ctl
            }
            else {
                estadd scalar p_joint_race = . : tot_lin_ctl
            }
            * 4. Trust + trust^2 + controls
            eststo tot_quad_ctl: regress `inc_tot' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_tot') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : tot_quad_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : tot_quad_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : tot_quad_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : tot_quad_ctl
            }
            else {
                estadd scalar p_joint_race = . : tot_quad_ctl
            }

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"
            local trust_part "`capt_stub'"
            if "`stub'" == "general" local trust_part "general"

            local outfile_tot "${REGRESSIONS}/Income/Total/income_trust_`stub'_log.tex"
            di as txt "Writing (total, log): `outfile_tot'"

            local drop_12 "1.gender 1.race_eth"
            capture confirm variable age_bin
            if !_rc {
                estimates restore tot_lin_ctl
                local cnames : colnames e(b)
                foreach c of local cnames {
                    if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_12 "`drop_12' `c'"
                }
            }

            esttab tot_lin_raw tot_quad_raw tot_lin_ctl tot_quad_ctl using "`outfile_tot'", replace ///
                booktabs ///
                mtitles("1" "2" "3" "4") ///
                se star(* 0.10 ** 0.05 *** 0.01) ///
                b(2) se(2) label ///
                drop(`drop_12' *.age_bin) ///
                varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant") ///
                title("Total income (2020) on `trust_part' trust") ///
                addnotes(".") ///
                alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
                stats(N r2_a p_joint_trust p_joint_age_bin p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Race p-value")) ///
                nonumbers nonotes
        }
    }

    * ------------------------------------------------------------------
    * Labor income (IHS): ihs_lab_inc_defl_win_s_2020
    * ------------------------------------------------------------------
    local inc_lab_ihs "ihs_lab_inc_defl_win_s_2020"
    capture confirm variable `inc_lab_ihs'
    if _rc {
        di as txt "Skipping `stub' labor ihs: ihs_lab_inc_defl_win_s_2020 not found."
    }
    else {
        quietly count if !missing(`inc_lab_ihs') & !missing(`trust_var')
        if r(N) < 50 {
            di as txt "Skipping `stub' labor ihs: too few obs (N=" r(N) ")."
        }
        else {
            eststo clear
            eststo lab_lin_raw: regress `inc_lab_ihs' c.`trust_var' if !missing(`inc_lab_ihs') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : lab_lin_raw
            estadd scalar p_joint_age_bin = . : lab_lin_raw
            estadd scalar p_joint_race = . : lab_lin_raw
            eststo lab_quad_raw: regress `inc_lab_ihs' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_lab_ihs') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : lab_quad_raw
            estadd scalar p_joint_age_bin = . : lab_quad_raw
            estadd scalar p_joint_race = . : lab_quad_raw
            eststo lab_lin_ctl: regress `inc_lab_ihs' c.`trust_var' `full_ctrl' if !missing(`inc_lab_ihs') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : lab_lin_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : lab_lin_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : lab_lin_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : lab_lin_ctl
            }
            else {
                estadd scalar p_joint_race = . : lab_lin_ctl
            }
            eststo lab_quad_ctl: regress `inc_lab_ihs' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_lab_ihs') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : lab_quad_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : lab_quad_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : lab_quad_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : lab_quad_ctl
            }
            else {
                estadd scalar p_joint_race = . : lab_quad_ctl
            }

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"
            local trust_part "`capt_stub'"
            if "`stub'" == "general" local trust_part "general"

            local outfile_lab_ihs "${REGRESSIONS}/Income/Labor/income_trust_`stub'_ihs.tex"
            di as txt "Writing (labor, ihs): `outfile_lab_ihs'"

            local drop_12 "1.gender 1.race_eth"
            capture confirm variable age_bin
            if !_rc {
                estimates restore lab_lin_ctl
                local cnames : colnames e(b)
                foreach c of local cnames {
                    if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_12 "`drop_12' `c'"
                }
            }

            esttab lab_lin_raw lab_quad_raw lab_lin_ctl lab_quad_ctl using "`outfile_lab_ihs'", replace ///
                booktabs ///
                mtitles("1" "2" "3" "4") ///
                se star(* 0.10 ** 0.05 *** 0.01) ///
                b(2) se(2) label ///
                drop(`drop_12' *.age_bin) ///
                varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant") ///
                title("Labor income (2020) on `trust_part' trust") ///
                addnotes(".") ///
                alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
                stats(N r2_a p_joint_trust p_joint_age_bin p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Race p-value")) ///
                nonumbers nonotes
        }
    }

    * ------------------------------------------------------------------
    * Total income (IHS): ihs_tot_inc_defl_win_s_2020
    * ------------------------------------------------------------------
    local inc_tot_ihs "ihs_tot_inc_defl_win_s_2020"
    capture confirm variable `inc_tot_ihs'
    if _rc {
        di as txt "Skipping `stub' total ihs: ihs_tot_inc_defl_win_s_2020 not found."
    }
    else {
        quietly count if !missing(`inc_tot_ihs') & !missing(`trust_var')
        if r(N) < 50 {
            di as txt "Skipping `stub' total ihs: too few obs (N=" r(N) ")."
        }
        else {
            eststo clear
            eststo tot_lin_raw: regress `inc_tot_ihs' c.`trust_var' if !missing(`inc_tot_ihs') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : tot_lin_raw
            estadd scalar p_joint_age_bin = . : tot_lin_raw
            estadd scalar p_joint_race = . : tot_lin_raw
            eststo tot_quad_raw: regress `inc_tot_ihs' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`inc_tot_ihs') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : tot_quad_raw
            estadd scalar p_joint_age_bin = . : tot_quad_raw
            estadd scalar p_joint_race = . : tot_quad_raw
            eststo tot_lin_ctl: regress `inc_tot_ihs' c.`trust_var' `full_ctrl' if !missing(`inc_tot_ihs') & !missing(`trust_var'), vce(robust)
            estadd scalar p_joint_trust = . : tot_lin_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : tot_lin_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : tot_lin_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : tot_lin_ctl
            }
            else {
                estadd scalar p_joint_race = . : tot_lin_ctl
            }
            eststo tot_quad_ctl: regress `inc_tot_ihs' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`inc_tot_ihs') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : tot_quad_ctl
            capture confirm variable age_bin
            if !_rc {
                quietly testparm i.age_bin
                estadd scalar p_joint_age_bin = r(p) : tot_quad_ctl
            }
            else {
                estadd scalar p_joint_age_bin = . : tot_quad_ctl
            }
            capture confirm variable race_eth
            if !_rc {
                quietly testparm i.race_eth
                estadd scalar p_joint_race = r(p) : tot_quad_ctl
            }
            else {
                estadd scalar p_joint_race = . : tot_quad_ctl
            }

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"
            local trust_part "`capt_stub'"
            if "`stub'" == "general" local trust_part "general"

            local outfile_tot_ihs "${REGRESSIONS}/Income/Total/income_trust_`stub'_ihs.tex"
            di as txt "Writing (total, ihs): `outfile_tot_ihs'"

            local drop_12 "1.gender 1.race_eth"
            capture confirm variable age_bin
            if !_rc {
                estimates restore tot_lin_ctl
                local cnames : colnames e(b)
                foreach c of local cnames {
                    if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_12 "`drop_12' `c'"
                }
            }

            esttab tot_lin_raw tot_quad_raw tot_lin_ctl tot_quad_ctl using "`outfile_tot_ihs'", replace ///
                booktabs ///
                mtitles("1" "2" "3" "4") ///
                se star(* 0.10 ** 0.05 *** 0.01) ///
                b(2) se(2) label ///
                drop(`drop_12' *.age_bin) ///
                varlabels(`trust_var' "Trust" c.`trust_var'#c.`trust_var' "Trust\$^2\$" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant") ///
                title("Total income (2020) on `trust_part' trust") ///
                addnotes(".") ///
                alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
                stats(N r2_a p_joint_trust p_joint_age_bin p_joint_race, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value" "Joint test: Age bins p-value" "Joint test: Race p-value")) ///
                nonumbers nonotes
        }
    }
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Income/Labor/ and ${REGRESSIONS}/Income/Total/."
log close
