* 11_reg_trust.do
* Cross-sectional OLS: 2020 trust (and trust PCs) as outcome.
* Age: 5-yr bins (omitted from table display).
* Two columns — (1) Demographics (2) Full controls.
* Output: Regressions/Trust/trust_reg_<stub>.tex. Log: Notes/Logs/11_reg_trust.log.

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

capture log close
log using "${LOG_DIR}/11_reg_trust.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load wide processed data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

* Age: 5-yr bins
capture confirm variable age_2020
if !_rc {
    gen int age_bin = floor(age_2020/5)*5
}

* Outcomes: 8 trust variables + 2 trust PCs (var:stub for filename/label)
local outcome_list "trust_others_2020:general trust_social_security_2020:social_security trust_medicare_2020:medicare trust_banks_2020:banks trust_advisors_2020:advisors trust_mutual_funds_2020:mutual_funds trust_insurance_2020:insurance trust_media_2020:media trust_pc1:pc1 trust_pc2:pc2"

* Demographics: age 5-yr bins, gender, educ, married, race (immigrant/born_us omitted)
local demo_core "i.gender educ_yrs married_2020"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"
capture confirm variable race_eth
if _rc {
    local demo_race ""
}

* Full controls: demographics + extended (depression, health, medicare, medicaid, life_ins, divorce, widow)
local extra_ctrl "depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 num_divorce_2020 num_widow_2020"
local full_ctrl "`demo_core' `demo_race' `extra_ctrl'"
local indicate_ctrl "`extra_ctrl'"

* Drop list for esttab: base factor levels + age bins (omit from display; built from coef names per regression)

* Variable labels (table display: match old repo wording)
label variable age_bin "Age (5-yr bin)"
label variable educ_yrs "Years of education"
label variable married_2020 "Married"
label variable immigrant "Immigrant"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable depression_2020 "Depression"
label variable health_cond_2020 "Health conditions"
label variable medicare_2020 "Covered by Medicare"
label variable medicaid_2020 "Covered by Medicaid"
label variable life_ins_2020 "Has life insurance"
label variable num_divorce_2020 "Number of reported divorces"
label variable num_widow_2020 "Number of reported times being widowed"
label variable trust_others_2020 "General trust"
label variable trust_social_security_2020 "Social Security trust"
label variable trust_medicare_2020 "Medicare trust"
label variable trust_banks_2020 "Banks trust"
label variable trust_advisors_2020 "Financial advisors trust"
label variable trust_mutual_funds_2020 "Mutual funds trust"
label variable trust_insurance_2020 "Insurance trust"
label variable trust_media_2020 "Media trust"
capture confirm variable trust_pc1
if !_rc label variable trust_pc1 "Trust PC1"
capture confirm variable trust_pc2
if !_rc label variable trust_pc2 "Trust PC2"

* ----------------------------------------------------------------------
* Loop over outcomes: two specs, one LaTeX table each
* ----------------------------------------------------------------------
foreach pair of local outcome_list {
    * Robust parsing of var:stub pairs so filenames never contain colons
    local pos = strpos("`pair'", ":")
    if `pos' == 0 continue
    local outvar = substr("`pair'", 1, `pos' - 1)
    local stub   = substr("`pair'", `pos' + 1, .)
    local stub   = trim("`stub'")
    capture confirm variable `outvar'
    if _rc {
        di as txt "Skipping (not found): `outvar'"
        continue
    }
    quietly count if !missing(`outvar')
    if r(N) < 50 {
        di as txt "Skipping `outvar': too few obs (N=" r(N) ")."
        continue
    }

    eststo clear
    eststo demog: regress `outvar' `demo_core' `demo_race' if !missing(`outvar'), vce(robust)
    eststo full:  regress `outvar' `full_ctrl' if !missing(`outvar'), vce(robust)

    * Build drop list from coefs in this regression (avoid dropping coefs that don't exist)
    local drop_11 "1.gender 1.race_eth"
    capture confirm variable age_bin
    if !_rc {
        estimates restore full
        local cnames : colnames e(b)
        foreach c of local cnames {
            if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_11 "`drop_11' `c'"
        }
    }

    local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
    local capt_stub = subinstr("`capt_stub'", "_", " ", .)
    if "`stub'" == "pc1" local capt_stub "PC1"
    if "`stub'" == "pc2" local capt_stub "PC2"

    local outfile "${REGRESSIONS}/Trust/trust_reg_`stub'.tex"
    di as txt "Writing: `outfile'"

    esttab demog full using "`outfile'", replace ///
        booktabs no gap ///
        mtitles("Demographics" "Full controls") ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_11' *.age_bin) ///
        varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" married_2020 "Married" depression_2020 "Depression" health_cond_2020 "Health conditions" medicare_2020 "Covered by Medicare" medicaid_2020 "Covered by Medicaid" life_ins_2020 "Has life insurance" num_divorce_2020 "Number of reported divorces" num_widow_2020 "Number of reported times being widowed" _cons "Constant") ///
        title("`capt_stub' trust (2020) on controls") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        addnotes("Robust standard errors in parentheses. Trust and controls from 2020. Age bins (5-yr) included; coefficients omitted.") ///
        nonumbers

    tempfile tmpf
    file open fh using "`outfile'", read text
    file open fout using "`tmpf'", write text replace
    local lab_inserted 0
    file read fh line
    while r(eof) == 0 {
        file write fout "`line'" _n
        if `lab_inserted' == 0 & regexm(`"`line'"', "\\caption") {
            file write fout "\label{tab:trust_reg_`stub'}" _n
            local lab_inserted 1
        }
        file read fh line
    }
    file close fh
    file close fout
    copy "`tmpf'" "`outfile'", replace
}

eststo clear
di as txt "Done. Tables in ${REGRESSIONS}/Trust/"
log close
