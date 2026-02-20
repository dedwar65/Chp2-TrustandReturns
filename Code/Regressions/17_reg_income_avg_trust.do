* 17_reg_income_avg_trust.do
* Cross-sectional OLS: average income (avg over waves) on 2020 general trust.
* Four tables: (1) labor defl+log+wins, (2) total defl+log+wins, (3) labor defl+ihs+wins, (4) total defl+ihs+wins.
* Four columns: (1) trust only, (2) trust+trust², (3) trust+controls, (4) trust+trust²+controls.
* General trust only. vce(robust). Log: Notes/Logs/17_reg_income_avg_trust.log.
* Output: Regressions/Average/Income/Labor/, Average/Income/Total/.

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

capture mkdir "${REGRESSIONS}/Average"
capture mkdir "${REGRESSIONS}/Average/Income"
capture mkdir "${REGRESSIONS}/Average/Income/Labor"
capture mkdir "${REGRESSIONS}/Average/Income/Total"

capture log close
log using "${LOG_DIR}/17_reg_income_avg_trust.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load data
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_ready_processed.dta", clear
set showbaselevels off

* Age: 5-yr bins
capture confirm variable age_2020
if !_rc {
    gen int age_bin = floor(age_2020/5)*5
}

* Trust: general only (for now)
local trust_list "trust_others_2020:general"

* Full controls = age 5-yr bins, gender, educ, inlbrf, married, born_us, race_eth
local full_ctrl "i.gender educ_yrs married_2020 born_us"
capture confirm variable age_bin
if !_rc local full_ctrl "i.age_bin `full_ctrl'"
capture confirm variable inlbrf_2020
if !_rc local full_ctrl "`full_ctrl' inlbrf_2020"
capture confirm variable race_eth
if !_rc local full_ctrl "`full_ctrl' i.race_eth"

* Variable labels
label variable age_bin "Age (5-yr bin)"
label variable educ_yrs "Years of education"
label variable inlbrf_2020 "In labor force"
label variable married_2020 "Married"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable trust_others_2020 "General trust"
label variable ln_lab_inc_defl_win_avg "Labor income (avg defl wins, log)"
label variable ln_tot_inc_defl_win_avg "Total income (avg defl wins, log)"
label variable ihs_lab_inc_defl_win_avg "Labor income (avg defl wins, IHS)"
label variable ihs_tot_inc_defl_win_avg "Total income (avg defl wins, IHS)"

* ----------------------------------------------------------------------
* Regressions: average income on trust (2020). Four tables: labor/total × deflwin_log, deflwin_ihs
* ----------------------------------------------------------------------
forvalues meas = 1/4 {
    if `meas' == 1 {
        local yvar "ln_lab_inc_defl_win_avg"
        local outdir "Labor"
        local label_outdir "labor"
        local file_suffix "deflwin_log"
        local title_suffix "labor income (avg defl wins, log)"
    }
    if `meas' == 2 {
        local yvar "ln_tot_inc_defl_win_avg"
        local outdir "Total"
        local label_outdir "total"
        local file_suffix "deflwin_log"
        local title_suffix "total income (avg defl wins, log)"
    }
    if `meas' == 3 {
        local yvar "ihs_lab_inc_defl_win_avg"
        local outdir "Labor"
        local label_outdir "labor"
        local file_suffix "deflwin_ihs"
        local title_suffix "labor income (avg defl wins, IHS)"
    }
    if `meas' == 4 {
        local yvar "ihs_tot_inc_defl_win_avg"
        local outdir "Total"
        local label_outdir "total"
        local file_suffix "deflwin_ihs"
        local title_suffix "total income (avg defl wins, IHS)"
    }

foreach pair of local trust_list {
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

    capture confirm variable `yvar'
    if _rc {
        di as txt "Skipping `stub' `title_suffix': `yvar' not found. Run 04_processing_income.do."
        continue
    }
    quietly count if !missing(`yvar') & !missing(`trust_var')
    if r(N) < 50 {
        di as txt "Skipping `stub' `title_suffix': too few obs (N=" r(N) ")."
        continue
    }
    eststo clear
    eststo m1: regress `yvar' c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(robust)
    eststo m2: regress `yvar' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`yvar') & !missing(`trust_var'), vce(robust)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m2
    eststo m3: regress `yvar' c.`trust_var' `full_ctrl' if !missing(`yvar') & !missing(`trust_var'), vce(robust)
    eststo m4: regress `yvar' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ctrl' if !missing(`yvar') & !missing(`trust_var'), vce(robust)
    quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
    estadd scalar p_joint_trust = r(p) : m4

    local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
    local capt_stub = subinstr("`capt_stub'", "_", " ", .)
    if "`stub'" == "pc1" local capt_stub "PC1"
    if "`stub'" == "pc2" local capt_stub "PC2"

    local outfile "${REGRESSIONS}/Average/Income/`outdir'/income_trust_`stub'_`file_suffix'.tex"
    di as txt "Writing (`outdir', `file_suffix'): `outfile'"

    local drop_12 "1.gender 1.race_eth"
    capture confirm variable age_bin
    if !_rc {
        estimates restore m4
        local cnames : colnames e(b)
        foreach c of local cnames {
            if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_12 "`drop_12' `c'"
        }
    }

    esttab m1 m2 m3 m4 using "`outfile'", replace ///
        booktabs ///
        mtitles("1" "2" "3" "4") ///
        se star(* 0.10 ** 0.05 *** 0.01) ///
        b(2) se(2) label ///
        drop(`drop_12' *.age_bin) ///
        varlabels(c.`trust_var'#c.`trust_var' "(`capt_stub')\$^2\$" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S." _cons "Constant") ///
        title("Average `title_suffix' on `capt_stub' trust (2020)") ///
        addnotes("Age bins (5-yr) included in columns 3–4.") ///
        alignment(${LATEX_ALIGN}) width(0.85\hsize) ///
        stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value")) ///
        nonumbers

    tempfile tmpf
    file open fh using "`outfile'", read text
    file open fout using "`tmpf'", write text replace
    local lab_inserted 0
    file read fh line
    while r(eof) == 0 {
        file write fout "`line'" _n
        if `lab_inserted' == 0 & regexm(`"`line'"', "\\caption") {
            file write fout "\label{tab:income_trust_`stub'_`label_outdir'_`file_suffix'}" _n
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
di as txt "Done. Tables in ${REGRESSIONS}/Average/Income/Labor/ and Average/Income/Total/."
log close
