* 18_reg_returns_avg_trust.do
* Cross-sectional OLS: average returns (r1, r4, r5 row mean across waves) on 2020 trust.
* Mirrors 13_reg_returns_trust.do but LHS = r*_annual_avg, r*_annual_avg_w5.
* One table per trust variable; each table has 6 columns: r1, r4, r5 x no controls | with controls.
* Four columns per table: (1) trust only, (2) trust+trust², (3) trust+controls, (4) trust+trust²+controls.
* Raw and 5% winsorized in separate tables (6 tables: r1/r4/r5 × raw/win).
* Controls: age 5-yr bins, gender, educ, inlbrf, married, born_us, race_eth, scope-appropriate wealth deciles.
* vce(robust). Log: Notes/Logs/18_reg_returns_avg_trust.log.
* Output: Regressions/Average/Returns/Core/, Core+res/, Net wealth/.

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
capture mkdir "${REGRESSIONS}/Average/Returns"
capture mkdir "${REGRESSIONS}/Average/Returns/Core"
capture mkdir "${REGRESSIONS}/Average/Returns/Core+res"
capture mkdir "${REGRESSIONS}/Average/Returns/Net wealth"

capture log close
log using "${LOG_DIR}/18_reg_returns_avg_trust.log", replace text

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

* Return variables: average (row mean across waves). Raw and 5% winsorized (two passes)
local ret_unwin "r1_annual_avg r4_annual_avg r5_annual_avg"
local ret_win   "r1_annual_avg_w5 r4_annual_avg_w5 r5_annual_avg_w5"

* Base controls
local demo_core "i.gender educ_yrs married_2020 born_us"
local demo_race "i.race_eth"
capture confirm variable age_bin
if !_rc local demo_core "i.age_bin `demo_core'"
capture confirm variable race_eth
if _rc local demo_race ""
local ctrl_base "`demo_core' `demo_race' inlbrf_2020"

local drop_base "1.gender 1.race_eth"

* Variable labels
label variable age_bin "Age (5-yr bin)"
label variable educ_yrs "Years of education"
label variable married_2020 "Married"
label variable born_us "Born in U.S."
label variable gender "Female"
label variable race_eth "Race/ethnicity"
label variable inlbrf_2020 "In labor force"
label variable trust_others_2020 "General trust"

* ----------------------------------------------------------------------
* Regressions: per return (r1, r4, r5), per trust var, per winsor-status
* ----------------------------------------------------------------------
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

    foreach ret in r1 r4 r5 {
        local outdir ""
        local y_un ""
        local y_win ""
        local full_ret "`ctrl_base'"
        local ret_label ""
        local drop_list "`drop_base'"
        if "`ret'" == "r1" {
            local y_un  "r1_annual_avg"
            local y_win "r1_annual_avg_w5"
            local ret_label "Returns to core (avg)"
            local outdir    "${REGRESSIONS}/Average/Returns/Core"
            forvalues d = 2/10 {
                capture confirm variable wealth_core_d`d'_2020
                if !_rc {
                    local full_ret "`full_ret' wealth_core_d`d'_2020"
                    local drop_list "`drop_list' wealth_core_d`d'_2020"
                }
            }
        }
        if "`ret'" == "r4" {
            local y_un  "r4_annual_avg"
            local y_win "r4_annual_avg_w5"
            local ret_label "Returns to ${LATEX_CORE_IRA} (avg)"
            local outdir    "${REGRESSIONS}/Average/Returns/Core+res"
            forvalues d = 2/10 {
                capture confirm variable wealth_coreira_d`d'_2020
                if !_rc {
                    local full_ret "`full_ret' wealth_coreira_d`d'_2020"
                    local drop_list "`drop_list' wealth_coreira_d`d'_2020"
                }
            }
        }
        if "`ret'" == "r5" {
            local y_un  "r5_annual_avg"
            local y_win "r5_annual_avg_w5"
            local ret_label "Returns to net wealth (avg)"
            local outdir    "${REGRESSIONS}/Average/Returns/Net wealth"
            forvalues d = 2/10 {
                capture confirm variable wealth_d`d'_2020
                if !_rc {
                    local full_ret "`full_ret' wealth_d`d'_2020"
                    local drop_list "`drop_list' wealth_d`d'_2020"
                }
            }
        }

        if "`y_un'" == "" | "`outdir'" == "" continue

        forvalues win = 0/1 {
            local y ""
            local file_suffix ""
            local win_label ""
            if `win' == 0 {
                local y "`y_un'"
                local file_suffix ""
                local win_label " (raw)"
            }
            else {
                local y "`y_win'"
                local file_suffix "_win"
                local win_label "${LATEX_WIN}"
            }

            capture confirm variable `y'
            if _rc {
                di as txt "Skipping `ret'`file_suffix' for `stub': return var `y' not found. Run 05_processing_returns.do."
                continue
            }

            quietly count if !missing(`y') & !missing(`trust_var')
            if r(N) < 50 {
                di as txt "Skipping `ret'`file_suffix' for `stub': too few obs (N=" r(N) ")."
                continue
            }

            eststo clear
            eststo lin_raw: regress `y' c.`trust_var' if !missing(`y') & !missing(`trust_var'), vce(robust)
            eststo quad_raw: regress `y' c.`trust_var' c.`trust_var'#c.`trust_var' if !missing(`y') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : quad_raw
            eststo lin_ctl: regress `y' c.`trust_var' `full_ret' if !missing(`y') & !missing(`trust_var'), vce(robust)
            eststo quad_ctl: regress `y' c.`trust_var' c.`trust_var'#c.`trust_var' `full_ret' if !missing(`y') & !missing(`trust_var'), vce(robust)
            quietly testparm c.`trust_var' c.`trust_var'#c.`trust_var'
            estadd scalar p_joint_trust = r(p) : quad_ctl

            local capt_stub = proper(substr("`stub'", 1, 1)) + substr("`stub'", 2, .)
            local capt_stub = subinstr("`capt_stub'", "_", " ", .)
            if "`stub'" == "pc1" local capt_stub "PC1"
            if "`stub'" == "pc2" local capt_stub "PC2"

            local outfile "`outdir'/returns_`ret'_trust_`stub'_avg`file_suffix'.tex"
            di as txt "Writing: `outfile'"

            local vlab_trust2 "(`capt_stub')\$^2\$"

            local drop_list "1.gender 1.race_eth"
            capture confirm variable age_bin
            if !_rc {
                estimates restore lin_ctl
                local cnames : colnames e(b)
                foreach c of local cnames {
                    if regexm("`c'", "\.age_bin$") & !regexm("`c'", "b\.age_bin$") local drop_list "`drop_list' `c'"
                }
            }
            if "`ret'" == "r1" {
                forvalues d = 2/10 {
                    capture confirm variable wealth_core_d`d'_2020
                    if !_rc local drop_list "`drop_list' wealth_core_d`d'_2020"
                }
            }
            if "`ret'" == "r4" {
                forvalues d = 2/10 {
                    capture confirm variable wealth_coreira_d`d'_2020
                    if !_rc local drop_list "`drop_list' wealth_coreira_d`d'_2020"
                }
            }
            if "`ret'" == "r5" {
                forvalues d = 2/10 {
                    capture confirm variable wealth_d`d'_2020
                    if !_rc local drop_list "`drop_list' wealth_d`d'_2020"
                }
            }

            esttab lin_raw quad_raw lin_ctl quad_ctl using "`outfile'", replace ///
                booktabs ///
                mtitles("1" "2" "3" "4") ///
                se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
                drop(`drop_list' *.age_bin, relax) ///
                varlabels(c.`trust_var'#c.`trust_var' "`vlab_trust2'" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" educ_yrs "Years of education" inlbrf_2020 "In labor force" married_2020 "Married" born_us "Born in U.S.") ///
                stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust p-value")) ///
                title("Average `ret_label' on `capt_stub' trust (2020)`win_label'") ///
                addnotes("Robust standard errors in parentheses. Age bins (5-yr) and wealth deciles included in columns 3–4.") ///
                alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers

            tempfile tmpf
            file open fh using "`outfile'", read text
            file open fout using "`tmpf'", write text replace
            local lab_inserted 0
            file read fh line
            while r(eof) == 0 {
                file write fout "`line'" _n
                if `lab_inserted' == 0 & regexm(`"`line'"', "\\caption") {
                    file write fout "\label{tab:returns_`ret'_trust_`stub'_avg`file_suffix'}" _n
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
di as txt "Done. Tables in ${REGRESSIONS}/Average/Returns/Core/, Core+res/, and Net wealth/."
log close
