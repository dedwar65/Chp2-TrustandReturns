* 16_panel_reg_fe.do
* Spec 3: Individual fixed-effects panel regressions with time-varying controls only.
* Extract FEs, distributions, second-stage (FE on time-invariant vars), plots.
* Output: panel_reg_r1_spec3.tex, etc.; fe_dist_*.png; panel_fe_on_tinv.tex; fe_vs_*.png.
* Log: Notes/Logs/16_panel_reg_fe.log.

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

capture mkdir "${REGRESSIONS}/Panel"
capture mkdir "${REGRESSIONS}/Panel/Figures"

capture log close
log using "${LOG_DIR}/16_panel_reg_fe.log", replace text

capture which esttab
if _rc ssc install estout, replace

* ----------------------------------------------------------------------
* Load long panel
* ----------------------------------------------------------------------
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
set showbaselevels off

xtset hhidpn year

* Require raw returns, winsorized returns, and share vars
foreach v in r1_annual_nw r4_annual_nw r5_annual_nw share_core share_ira share_res share_debt_long share_debt_other {
    capture confirm variable `v'
    if _rc {
        display as error "16_panel_reg_fe: `v' not found. Run 02, 03, 04, 05, 10 in order."
        log close
        exit 198
    }
}
foreach v in r1_annual_w5 r4_annual_w5 r5_annual_w5 {
    capture confirm variable `v'
    if _rc {
        display as error "16_panel_reg_fe: `v' (winsorized) not found. Run 05_processing_returns.do and 10_build_panel.do."
        log close
        exit 198
    }
}

local r1_raw "r1_annual_nw"
local r4_raw "r4_annual_nw"
local r5_raw "r5_annual_nw"
local trust_var "trust_others_2020"

* Time-varying controls only (no educ, gender, race, born_us, censreg, trust)
local ctrl_r1 "i.age_bin inlbrf married i.year"
local ctrl_r4 "i.age_bin inlbrf married i.year"
local ctrl_r5 "i.age_bin inlbrf married i.year"
forvalues d = 2/10 {
    capture confirm variable wealth_core_d`d'
    if !_rc local ctrl_r1 "`ctrl_r1' wealth_core_d`d'"
    capture confirm variable wealth_coreira_d`d'
    if !_rc local ctrl_r4 "`ctrl_r4' wealth_coreira_d`d'"
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_r5 "`ctrl_r5' wealth_d`d'"
}
local ctrl_r1 "`ctrl_r1' c.share_core##i.year"
local ctrl_r4 "`ctrl_r4' c.share_core##i.year c.share_ira##i.year"
local ctrl_r5 "`ctrl_r5' c.share_core##i.year c.share_ira##i.year c.share_res##i.year c.share_debt_long##i.year c.share_debt_other##i.year"

* Share conditions
local share_cond_r1 "!missing(share_core)"
local share_cond_r4 "!missing(share_core) & !missing(share_ira)"
local share_cond_r5 "!missing(share_core) & !missing(share_ira) & !missing(share_res) & !missing(share_debt_long) & !missing(share_debt_other)"

* ----------------------------------------------------------------------
* Step A & B: Run FE regressions, save FE, export tables (raw + winsorized)
* Reload data before each regression (like old repo reg_fixed_effects.do) to avoid dataset state issues.
* ----------------------------------------------------------------------
tempfile fe_append
local first_fe 1

foreach win in raw win {
    local y_suffix "nw"
    local win_label "raw"
    if "`win'" == "win" {
        local y_suffix "w5"
        local win_label "${LATEX_WIN_SHORT}"
    }
    foreach ret in r1 r4 r5 {
        local yvar "r1_annual_`y_suffix'"
        if "`ret'" == "r4" local yvar "r4_annual_`y_suffix'"
        if "`ret'" == "r5" local yvar "r5_annual_`y_suffix'"

        * Reload fresh data before each regression (aligns with old repo reg_fixed_effects.do)
        use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
        xtset hhidpn year

        capture confirm variable `yvar'
        if _rc {
            di as txt "Skipping `win' `ret': `yvar' not found."
            continue
        }

        local ctrl ""
        local share_cond "1"
        local ret_label ""
        if "`ret'" == "r1" {
            local ctrl "`ctrl_r1'"
            local share_cond "`share_cond_r1'"
            local ret_label "returns to core"
        }
        if "`ret'" == "r4" {
            local ctrl "`ctrl_r4'"
            local share_cond "`share_cond_r4'"
            local ret_label "returns to ${LATEX_CORE_IRA}"
        }
        if "`ret'" == "r5" {
            local ctrl "`ctrl_r5'"
            local share_cond "`share_cond_r5'"
            local ret_label "returns to net wealth"
        }

        di as txt _n "--- Spec 3 FE: `ret_label' (`win_label') ---"

        quietly count if !missing(`yvar') & `share_cond'
        if r(N) < 100 {
            di as txt "Skipping `ret' `win': too few obs (N=" r(N) ")."
            continue
        }

        * xtreg, fe (same share×year spec as Spec 2; matches old repo reg_fixed_effects.do)
        capture xtreg `yvar' `ctrl' if !missing(`yvar') & `share_cond', fe vce(cluster hhidpn)
        if _rc {
            di as err "xtreg failed for `ret' `win' (r(" _rc ")). Skipping."
            continue
        }
        predict double __fe_resid, e
        predict double __hdfe1__, u

        * Joint tests: share×year
        if "`ret'" == "r1" {
            quietly testparm c.share_core#i.year
            estadd scalar p_joint_share_core = r(p)
        }
        if "`ret'" == "r4" {
            quietly testparm c.share_core#i.year
            estadd scalar p_joint_share_core = r(p)
            quietly testparm c.share_ira#i.year
            estadd scalar p_joint_share_ira = r(p)
        }
        if "`ret'" == "r5" {
            quietly testparm c.share_core#i.year c.share_ira#i.year c.share_res#i.year
            estadd scalar p_joint_share_asset = r(p)
            quietly testparm c.share_debt_long#i.year c.share_debt_other#i.year
            estadd scalar p_joint_share_debt = r(p)
        }

        * xtreg already stores r2_w, sigma_u, sigma_e, rho — no need to estadd

        if "`ret'" == "r1" local stats_share "p_joint_share_core"
        if "`ret'" == "r1" local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value""'
        if "`ret'" == "r4" local stats_share "p_joint_share_core p_joint_share_ira"
        if "`ret'" == "r4" local labels_share `" "Joint test: Share core${LATEX_X_YEAR} p-value" "Joint test: Share IRA${LATEX_X_YEAR} p-value""'
        if "`ret'" == "r5" local stats_share "p_joint_share_asset p_joint_share_debt"
        if "`ret'" == "r5" local labels_share `" "Joint test: Share (core,IRA,res)${LATEX_X_YEAR} p-value" "Joint test: Share (debt long,other)${LATEX_X_YEAR} p-value""'
        local stats_line "N r2_w rho sigma_u sigma_e `stats_share'"
        local labels_line `" "Observations" "Within R²" "Rho" "Sigma u" "Sigma e" `labels_share'"'

        eststo fe_`ret'_`win'

        * Display full regression in log (all coefficients; no keep) — for history of actual results
        esttab fe_`ret'_`win', se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
            stats(`stats_line', labels(`labels_line')) ///
            nomtitles nonumbers noobs

        * Save FE to tempfile and append
        preserve
        keep if e(sample)
        keep hhidpn __hdfe1__
        collapse (first) __hdfe1__, by(hhidpn)
        rename __hdfe1__ fe
        gen ret_type = "`ret'"
        gen win_type = "`win'"
        tempfile fe_`ret'_`win'
        save `fe_`ret'_`win''
        restore

        if `first_fe' {
            use `fe_`ret'_`win'', clear
            local first_fe 0
        }
        else {
            use `fe_append', clear
            append using `fe_`ret'_`win''
        }
        save `fe_append', replace

        * Export table — uninteracted share terms, inlbrf, married. Age bins, year, wealth, share×year omitted (see note).
        * xtreg stores binary vars as inlbrf_, married_ in e(b).
        quietly estimates restore fe_`ret'_`win'
        local keep_list "inlbrf_ married_ share_core share_ira share_res share_debt_long share_debt_other _cons"
        if "`ret'" == "r1" local keep_list "inlbrf_ married_ share_core _cons"
        if "`ret'" == "r4" local keep_list "inlbrf_ married_ share_core share_ira _cons"
        if "`ret'" == "r5" local keep_list "inlbrf_ married_ share_core share_ira share_res share_debt_long share_debt_other _cons"
        local order_r1 "inlbrf_ married_ share_core _cons"
        local order_r4 "inlbrf_ married_ share_core share_ira _cons"
        local order_r5 "inlbrf_ married_ share_core share_ira share_res share_debt_long share_debt_other _cons"
        local keep_final ""
        capture confirm matrix e(b)
        if !_rc {
            local bnames : colnames e(b)
            foreach c of local keep_list {
                if `: list c in bnames' local keep_final "`keep_final' `c'"
            }
        }
        if "`keep_final'" == "" local keep_final "_cons"

        local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_spec3.tex"
        if "`win'" == "win" local outfile "${REGRESSIONS}/Panel/panel_reg_`ret'_spec3_win.tex"

        local tablabel "tab:panel_spec3_`ret'_`win'"
        local omit_note1 "Age bins, wealth deciles, region dummies, year dummies,"
        local omit_note2 "${LATEX_SHARE_YEAR} interactions included in estimation but omitted from table."
        if `: list inlbrf_ in keep_final' == 0 | `: list married_ in keep_final' == 0 {
            local omit_note2 "`omit_note2' Employed and/or Married omitted (collinear with individual FE)."
        }
        local note1 "\label{`tablabel'} Cluster-robust SE in parentheses. Individual fixed effects."
        local note2 "`omit_note1'"
        local note3 "`omit_note2'"
        local note4 "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)"
        esttab fe_`ret'_`win' using "`outfile'", replace ///
            booktabs ///
            mtitles("(1)") ///
            se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
            keep(`keep_final') order(`order_`ret'') ///
            varlabels(inlbrf_ "Employed" married_ "Married" share_core "Share core" share_ira "Share IRA" share_res "Share residential" share_debt_long "Share long-term debt" share_debt_other "Share other debt" _cons `"\_cons"') ///
            stats(`stats_line', labels(`labels_line')) ///
            title("Panel Spec 3: `ret_label' (`win_label', ${LATEX_SHARE_YEAR})") ///
            addnotes("`note1'" "`note2'" "`note3'" "`note4'") ///
            alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers substitute("\caption{" "\caption[]{")

        di as txt "Wrote: `outfile'"
    }
}

* ----------------------------------------------------------------------
* Merge FE with time-invariant vars for downstream
* ----------------------------------------------------------------------
preserve
use "${PROCESSED}/analysis_final_long_unbalanced.dta", clear
keep hhidpn educ_yrs gender race_eth born_us trust_others_2020
duplicates drop hhidpn, force
tempfile tinv
save `tinv'
restore

use `fe_append', clear
merge m:1 hhidpn using `tinv', nogen
save `fe_append', replace

* ----------------------------------------------------------------------
* Step C: Distribution plots (6)
* ----------------------------------------------------------------------
foreach win in raw win {
    local win_label "raw"
    if "`win'" == "win" local win_label "${LATEX_WIN_SHORT}"
    foreach ret in r1 r4 r5 {
        use `fe_append' if ret_type=="`ret'" & win_type=="`win'", clear
        if _N == 0 continue
        local ret_label "returns to core"
        if "`ret'" == "r4" local ret_label "returns to ${LATEX_CORE_IRA}"
        if "`ret'" == "r5" local ret_label "returns to net wealth"
        local fname "fe_dist_`ret'"
        if "`win'" == "win" local fname "fe_dist_`ret'_win"
        histogram fe, percent width(0.01) ///
            title("FE distribution: `ret_label' (`win_label')") ///
            xtitle("Estimated fixed effect") ///
            scheme(s2color)
        graph export "${REGRESSIONS}/Panel/Figures/`fname'.png", replace width(1200)
        di as txt "Wrote: `fname'.png"
    }
}

* ----------------------------------------------------------------------
* Step D: Second-stage regressions (FE on time-invariant vars)
* One table per return measure (r1, r4, r5) × raw/winsorized
* ----------------------------------------------------------------------
foreach win in raw win {
    local win_label "raw"
    if "`win'" == "win" local win_label "${LATEX_WIN_SHORT}"
    foreach ret in r1 r4 r5 {
        use `fe_append', clear
        keep if ret_type=="`ret'" & win_type=="`win'"
        drop if missing(educ_yrs) | missing(gender) | missing(race_eth)

        local ret_label "returns to core"
        if "`ret'" == "r4" local ret_label "returns to ${LATEX_CORE_IRA}"
        if "`ret'" == "r5" local ret_label "returns to net wealth"

        eststo clear
        eststo m1: regress fe educ_yrs i.gender i.race_eth born_us, vce(robust)
        eststo m2: regress fe educ_yrs i.gender i.race_eth born_us trust_others_2020 if !missing(trust_others_2020), vce(robust)
        eststo m3: regress fe educ_yrs i.gender i.race_eth born_us trust_others_2020 c.trust_others_2020#c.trust_others_2020 if !missing(trust_others_2020), vce(robust)
        quietly testparm trust_others_2020 c.trust_others_2020#c.trust_others_2020
        estadd scalar p_joint_trust = r(p) : m3

        * Display full second-stage in log (all coefficients) — for history of actual results
        esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
            mtitles("(1)" "(2)" "(3)") ///
            stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value")) ///
            title("Second-stage: FE from `ret_label' (`win_label') — full results")

        local keep_list "educ_yrs 2.gender 2.race_eth 3.race_eth 4.race_eth born_us trust_others_2020 c.trust_others_2020#c.trust_others_2020 _cons"
        local outfile "${REGRESSIONS}/Panel/panel_fe_on_tinv_`ret'_`win'.tex"
        local tablabel "tab:panel_fe_on_tinv_`ret'_`win'"
        esttab m1 m2 m3 using "`outfile'", replace ///
            booktabs ///
            mtitles("(1)" "(2)" "(3)") ///
            se star(* 0.10 ** 0.05 *** 0.01) b(2) se(2) label ///
            keep(`keep_list') ///
            varlabels(educ_yrs "Years of education" 2.gender "Female" 2.race_eth "NH Black" 3.race_eth "Hispanic" 4.race_eth "NH Other" born_us "Born in U.S." trust_others_2020 "Trust" c.trust_others_2020#c.trust_others_2020 "Trust²" _cons `"\_cons"') ///
            stats(N r2_a p_joint_trust, labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value")) ///
            title("Second-stage: FE from `ret_label' (`win_label') on time-invariant vars") ///
            addnotes("\label{`tablabel'} Robust SE. FE from Panel Spec 3 `ret_label' regression (`win_label').") ///
            alignment(${LATEX_ALIGN}) width(0.85\hsize) nonumbers substitute("\caption{" "\caption[]{")

        di as txt "Wrote: panel_fe_on_tinv_`ret'_`win'.tex"
    }
}

* ----------------------------------------------------------------------
* Step E: Scatter and box plots
* ----------------------------------------------------------------------
use `fe_append', clear

* FE vs trust (raw and winsorized) — use r1 for one point per person
foreach win in raw win {
    local win_label "raw"
    if "`win'" == "win" local win_label "${LATEX_WIN_SHORT}"
    use `fe_append' if ret_type=="r1" & win_type=="`win'", clear
    drop if missing(fe) | missing(trust_others_2020)
    if _N < 10 continue
    twoway scatter fe trust_others_2020, msize(tiny) msymbol(circle) ///
        title("FE vs Trust (`win_label')") xtitle("Trust") ytitle("Estimated FE") ///
        scheme(s2color)
    graph export "${REGRESSIONS}/Panel/Figures/fe_vs_trust_`win'.png", replace width(1200)
    di as txt "Wrote: fe_vs_trust_`win'.png"
}

* FE vs educ (raw and winsorized) — use r1 for one point per person
foreach win in raw win {
    local win_label "raw"
    if "`win'" == "win" local win_label "${LATEX_WIN_SHORT}"
    use `fe_append' if ret_type=="r1" & win_type=="`win'", clear
    drop if missing(fe) | missing(educ_yrs)
    if _N < 10 continue
    twoway scatter fe educ_yrs, msize(tiny) msymbol(circle) ///
        title("FE vs Education (`win_label')") xtitle("Years of education") ytitle("Estimated FE") ///
        scheme(s2color)
    graph export "${REGRESSIONS}/Panel/Figures/fe_vs_educ_`win'.png", replace width(1200)
    di as txt "Wrote: fe_vs_educ_`win'.png"
}

* FE by race and gender (raw and winsorized) — bar graph: x = category, y = mean FE
foreach win in raw win {
    local win_label "raw"
    if "`win'" == "win" local win_label "${LATEX_WIN_SHORT}"
    use `fe_append' if ret_type=="r1" & win_type=="`win'", clear
    drop if missing(fe)
    if _N < 5 {
        di as txt "Skipping fe_by_race/gender for win=`win': no observations."
        continue
    }
    local winsuf ""
    if "`win'" == "win" local winsuf "_win"

    capture confirm variable race_eth
    if !_rc {
        preserve
        collapse (mean) fe_mean=fe (count) n=fe, by(race_eth)
        graph bar fe_mean, over(race_eth, relabel(1 "White (NH)" 2 "Black (NH)" 3 "Hispanic" 4 "Other (NH)")) ///
            title("Mean FE by race/ethnicity (`win_label')") ytitle("Mean estimated FE") ///
            blabel(total, format(%4.2f)) scheme(s2color)
        graph export "${REGRESSIONS}/Panel/Figures/fe_by_race`winsuf'.png", replace width(1200)
        di as txt "Wrote: fe_by_race`winsuf'.png"
        restore
    }

    capture confirm variable gender
    if !_rc {
        preserve
        collapse (mean) fe_mean=fe (count) n=fe, by(gender)
        graph bar fe_mean, over(gender, relabel(1 "Male" 2 "Female")) ///
            title("Mean FE by gender (`win_label')") ytitle("Mean estimated FE") ///
            blabel(total, format(%4.2f)) scheme(s2color)
        graph export "${REGRESSIONS}/Panel/Figures/fe_by_gender`winsuf'.png", replace width(1200)
        di as txt "Wrote: fe_by_gender`winsuf'.png"
        restore
    }
}

eststo clear
di as txt "Done. Spec 3 tables and figures in ${REGRESSIONS}/Panel/"
log close
