* 03_prep_controls.do
* Prepare controls, IVs, wealth deciles, asset shares, and income measures.
* Expects: run after 00_config (CLEANED set). Input: ${CLEANED}/all_data_merged.dta.
* Output: ${PROCESSED}/analysis_ready.dta (trimmed to relevant variables).
* Run order: 00_config, 01_merge_all_data, 02_compute_returns_income, then this script.

clear
set more off

capture log close
log using "${LOG_DIR}/03_prep_controls.log", replace text

use "${CLEANED}/all_data_merged.dta", clear

* ---------------------------------------------------------------------
* Demographics / controls (Notes §2: age, education, employment, marital, immigration)
* ---------------------------------------------------------------------
* Education (time-invariant in RAND)
capture confirm variable raedyrs
if !_rc {
    capture drop educ_yrs
    gen educ_yrs = raedyrs
}

* Gender (time-invariant)
capture confirm variable ragender
if !_rc {
    capture drop gender
    gen byte gender = ragender
}

* Immigration (time-invariant; 1 = born in US)
capture confirm variable rabplace
if !_rc {
    capture drop immigrant
    gen byte immigrant = .
    replace immigrant = 1 if inlist(rabplace,11,13)
    replace immigrant = 0 if inrange(rabplace,1,10) | rabplace == 12
}
* Born in US (rabplace codes 1-10,12)
capture confirm variable rabplace
if !_rc {
    capture drop born_us
    gen byte born_us = .
    replace born_us = 1 if inrange(rabplace,1,10) | rabplace == 12
    replace born_us = 0 if inlist(rabplace,11,13)
}

* Race/ethnicity (raracem + rahispan) if available
capture confirm variable raracem
capture confirm variable rahispan
if !_rc {
    capture drop race_eth
    gen byte race_eth = .
    replace race_eth = 3 if rahispan == 1
    replace race_eth = 1 if rahispan == 0 & raracem == 1
    replace race_eth = 2 if rahispan == 0 & raracem == 2
    replace race_eth = 4 if rahispan == 0 & raracem == 3
}

* Trust and IVs (rename to descriptive names)
capture confirm variable rv568_2020
if !_rc {
    capture drop par_citizen_2020
    gen par_citizen_2020 = rv568_2020
}
capture confirm variable rv569_2020
if !_rc {
    capture drop par_loyalty_2020
    gen par_loyalty_2020 = rv569_2020
}
capture confirm variable rv570_2020
if !_rc {
    capture drop population_2020
    gen population_2020 = rv570_2020
}

* Collapsed population bins (2020): 1-2 small town, 3-4 small city, 5-6 large metro
capture confirm variable population_2020
if !_rc {
    capture drop population_3bin_2020
    gen byte population_3bin_2020 = .
    replace population_3bin_2020 = 1 if inlist(population_2020, 1, 2)
    replace population_3bin_2020 = 2 if inlist(population_2020, 3, 4)
    replace population_3bin_2020 = 3 if inlist(population_2020, 5, 6)
}

* Financial literacy (rename)
capture confirm variable rv565_2020
if !_rc {
    capture drop interest_2020
    gen interest_2020 = rv565_2020
}
capture confirm variable rv566_2020
if !_rc {
    capture drop inflation_2020
    gen inflation_2020 = rv566_2020
}
capture confirm variable rv567_2020
if !_rc {
    capture drop risk_div_2020
    gen risk_div_2020 = rv567_2020
}

* Additional trust regression controls (2020 wave)
capture confirm variable r15cesd
if !_rc {
    capture drop depression_2020
    gen depression_2020 = r15cesd
}
capture confirm variable r15conde
if !_rc {
    capture drop health_cond_2020
    gen health_cond_2020 = r15conde
}
capture confirm variable r15govmr
if !_rc {
    capture drop medicare_2020
    gen medicare_2020 = r15govmr
}
capture confirm variable r15govmd
if !_rc {
    capture drop medicaid_2020
    gen medicaid_2020 = r15govmd
}
capture confirm variable r15lifein
if !_rc {
    capture drop life_ins_2020
    gen life_ins_2020 = r15lifein
}
capture confirm variable r15beqany
if !_rc {
    capture drop beq_any_2020
    gen beq_any_2020 = r15beqany
}
capture confirm variable r15mdiv
if !_rc {
    capture drop num_divorce_2020
    gen num_divorce_2020 = r15mdiv
}
capture confirm variable r15mwid
if !_rc {
    capture drop num_widow_2020
    gen num_widow_2020 = r15mwid
}

* Trust variables (rename to descriptive names)
capture confirm variable rv557_2020
if !_rc {
    capture drop trust_others_2020
    gen trust_others_2020 = rv557_2020
}
capture confirm variable rv558_2020
if !_rc {
    capture drop trust_social_security_2020
    gen trust_social_security_2020 = rv558_2020
}
capture confirm variable rv559_2020
if !_rc {
    capture drop trust_medicare_2020
    gen trust_medicare_2020 = rv559_2020
}
capture confirm variable rv560_2020
if !_rc {
    capture drop trust_banks_2020
    gen trust_banks_2020 = rv560_2020
}
capture confirm variable rv561_2020
if !_rc {
    capture drop trust_advisors_2020
    gen trust_advisors_2020 = rv561_2020
}
capture confirm variable rv562_2020
if !_rc {
    capture drop trust_mutual_funds_2020
    gen trust_mutual_funds_2020 = rv562_2020
}
capture confirm variable rv563_2020
if !_rc {
    capture drop trust_insurance_2020
    gen trust_insurance_2020 = rv563_2020
}
capture confirm variable rv564_2020
if !_rc {
    capture drop trust_media_2020
    gen trust_media_2020 = rv564_2020
}

* Controls for all waves (one-wave-ahead for returns)
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture confirm variable r`w'agey_b
    if !_rc {
        capture drop age_`y'
        gen double age_`y' = r`w'agey_b
        capture drop age_bin_`y'
        gen int age_bin_`y' = floor(age_`y'/5)*5 if !missing(age_`y')
    }
    capture confirm variable r`w'inlbrf
    if !_rc {
        capture drop inlbrf_`y'
        gen byte inlbrf_`y' = r`w'inlbrf
    }
    capture confirm variable r`w'mstat
    if !_rc {
        capture drop married_`y'
        gen byte married_`y' = (r`w'mstat == 1) if !missing(r`w'mstat)
    }
}

* Census region for all waves (censreg_*)
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture confirm variable r`w'cenreg
    if !_rc {
        capture drop censreg_`y'
        gen byte censreg_`y' = r`w'cenreg
        * Region 5 (Other) left as-is here; recoded to missing in 08 before saving analysis_ready_processed.dta
    }
}

* Contextual trust by population only (all waves)
capture confirm variable population_2020
capture confirm variable trust_others_2020
if !_rc {
    forvalues w = 5/16 {
        local y = 1990 + (2*`w')
        capture drop pop_trust_`y'
        egen double pop_trust_`y' = mean(trust_others_2020), by(population_2020)
    }
}

capture confirm variable population_3bin_2020
capture confirm variable trust_others_2020
if !_rc {
    forvalues w = 5/16 {
        local y = 1990 + (2*`w')
        capture drop pop3_trust_`y'
        egen double pop3_trust_`y' = mean(trust_others_2020), by(population_3bin_2020)
    }
}

* Regional trust (group avg of trust by census region, all waves)
capture confirm variable trust_others_2020
if !_rc {
    forvalues w = 5/16 {
        local y = 1990 + (2*`w')
        capture confirm variable censreg_`y'
        if !_rc {
            capture drop regional_trust_`y'
            egen double regional_trust_`y' = mean(trust_others_2020), by(censreg_`y')
        }
    }
}

* ---------------------------------------------------------------------
* Wealth deciles by year (four concepts: core, ira-only, residential-only, total net wealth)
* RAND: h5atotb (2000), h6atotb (2002), ... h16atotb (2022). Lowercase.
* ---------------------------------------------------------------------
local wyears "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local watotb "h5atotb h6atotb h7atotb h8atotb h9atotb h10atotb h11atotb h12atotb h13atotb h14atotb h15atotb h16atotb"
local watoth "h5atoth h6atoth h7atoth h8atoth h9atoth h10atoth h11atoth h12atoth h13atoth h14atoth h15atoth h16atoth"
local wanethb "h5anethb h6anethb h7anethb h8anethb h9anethb h10anethb h11anethb h12anethb h13anethb h14anethb h15anethb h16anethb"
local waira "h5aira h6aira h7aira h8aira h9aira h10aira h11aira h12aira h13aira h14aira h15aira h16aira"
local warles "h5arles h6arles h7arles h8arles h9arles h10arles h11arles h12arles h13arles h14arles h15arles h16arles"
local wabsns "h5absns h6absns h7absns h8absns h9absns h10absns h11absns h12absns h13absns h14absns h15absns h16absns"
local wastck "h5astck h6astck h7astck h8astck h9astck h10astck h11astck h12astck h13astck h14astck h15astck h16astck"
local wabond "h5abond h6abond h7abond h8abond h9abond h10abond h11abond h12abond h13abond h14abond h15abond h16abond"
local wachck "h5achck h6achck h7achck h8achck h9achck h10achck h11achck h12achck h13achck h14achck h15achck h16achck"
local wacd "h5acd h6acd h7acd h8acd h9acd h10acd h11acd h12acd h13acd h14acd h15acd h16acd"
local watran "h5atran h6atran h7atran h8atran h9atran h10atran h11atran h12atran h13atran h14atran h15atran h16atran"
local waothr "h5aothr h6aothr h7aothr h8aothr h9aothr h10aothr h11aothr h12aothr h13aothr h14aothr h15aothr h16aothr"
forvalues j = 1/12 {
    local y : word `j' of `wyears'
    local w : word `j' of `watotb'
    local wpri : word `j' of `watoth'
    local wsec : word `j' of `wanethb'
    local wira : word `j' of `waira'
    local wre : word `j' of `warles'
    local wbus : word `j' of `wabsns'
    local wstk : word `j' of `wastck'
    local wbond : word `j' of `wabond'
    local wchck : word `j' of `wachck'
    local wcd : word `j' of `wacd'
    local wtran : word `j' of `watran'
    local woth : word `j' of `waothr'
    capture confirm variable `w'
    capture confirm variable `wpri'
    capture confirm variable `wsec'
    capture confirm variable `wira'
    if !_rc {
        local has_core 1
        foreach v in `wre' `wbus' `wstk' `wbond' `wchck' `wcd' {
            capture confirm variable `v'
            if _rc local has_core 0
        }
        * Total net wealth (constructed from components, allow partial nonmissing)
        capture drop wealth_total_`y'
        capture drop gross_wealth_`y'
        capture drop _gross_n_`y'
        capture drop _debt_total_`y'
        capture drop _debt_n_`y'
        capture drop wealth_decile_`y'
        egen byte _gross_n_`y' = rownonmiss(`wre' `wbus' `wstk' `wbond' `wchck' `wcd' `wpri' `wsec' `wira' `wtran' `woth')
        egen double _debt_total_`y' = rowtotal(h`j'amort h`j'ahmln h`j'adebt), missing
        egen byte _debt_n_`y' = rownonmiss(h`j'amort h`j'ahmln h`j'adebt)
        gen double gross_wealth_`y' = ///
            cond(missing(`wre'), 0, max(`wre', 0)) + cond(missing(`wbus'), 0, max(`wbus', 0)) + ///
            cond(missing(`wstk'), 0, max(`wstk', 0)) + cond(missing(`wbond'), 0, max(`wbond', 0)) + ///
            cond(missing(`wchck'), 0, max(`wchck', 0)) + cond(missing(`wcd'), 0, max(`wcd', 0)) + ///
            cond(missing(`wpri'), 0, max(`wpri', 0)) + cond(missing(`wsec'), 0, max(`wsec', 0)) + ///
            cond(missing(`wira'), 0, max(`wira', 0)) + cond(missing(`wtran'), 0, max(`wtran', 0)) + ///
            cond(missing(`woth'), 0, max(`woth', 0))
        replace gross_wealth_`y' = . if _gross_n_`y' == 0
        gen double wealth_total_`y' = gross_wealth_`y' - _debt_total_`y'
        replace wealth_total_`y' = . if _gross_n_`y' == 0 & _debt_n_`y' == 0

        capture drop wealth_decile_`y'
        xtile wealth_decile_`y' = wealth_total_`y', nq(10)
        replace wealth_decile_`y' = . if missing(wealth_total_`y')
        forvalues d = 1/10 {
            capture drop wealth_d`d'_`y'
            gen byte wealth_d`d'_`y' = wealth_decile_`y' == `d' if !missing(wealth_decile_`y')
        }

        * Core wealth (exclude residences and IRA)
        if `has_core' {
            capture drop wealth_core_`y'
            capture drop wealth_core_decile_`y'
            gen double wealth_core_`y' = `wre' + `wbus' + `wstk' + `wbond' + `wchck' + `wcd' if !missing(`wre') & !missing(`wbus') & !missing(`wstk') & !missing(`wbond') & !missing(`wchck') & !missing(`wcd')
            capture drop wealth_core_decile_`y'
            xtile wealth_core_decile_`y' = wealth_core_`y', nq(10)
            replace wealth_core_decile_`y' = . if missing(wealth_core_`y')
            forvalues d = 1/10 {
                capture drop wealth_core_d`d'_`y'
                gen byte wealth_core_d`d'_`y' = wealth_core_decile_`y' == `d' if !missing(wealth_core_decile_`y')
            }
        }

        * IRA-only wealth
        capture drop wealth_ira_`y'
        capture drop wealth_ira_decile_`y'
        gen double wealth_ira_`y' = `wira' if !missing(`wira')
        capture drop wealth_ira_decile_`y'
        xtile wealth_ira_decile_`y' = wealth_ira_`y', nq(10)
        replace wealth_ira_decile_`y' = . if missing(wealth_ira_`y')
        forvalues d = 1/10 {
            capture drop wealth_ira_d`d'_`y'
            gen byte wealth_ira_d`d'_`y' = wealth_ira_decile_`y' == `d' if !missing(wealth_ira_decile_`y')
        }

        * Core+ret. wealth (core + IRA; same scope as r4)
        if `has_core' {
            capture drop wealth_coreira_`y'
            capture drop wealth_coreira_decile_`y'
            gen double wealth_coreira_`y' = wealth_core_`y' + wealth_ira_`y' if !missing(wealth_core_`y') & !missing(wealth_ira_`y')
            capture drop wealth_coreira_decile_`y'
            xtile wealth_coreira_decile_`y' = wealth_coreira_`y', nq(10)
            replace wealth_coreira_decile_`y' = . if missing(wealth_coreira_`y')
            forvalues d = 1/10 {
                capture drop wealth_coreira_d`d'_`y'
                gen byte wealth_coreira_d`d'_`y' = wealth_coreira_decile_`y' == `d' if !missing(wealth_coreira_decile_`y')
            }
        }

        * Residential-only wealth (primary + secondary)
        capture drop wealth_res_`y'
        capture drop wealth_res_decile_`y'
        gen double wealth_res_`y' = `wpri' + `wsec' if !missing(`wpri') & !missing(`wsec')
        capture drop wealth_res_decile_`y'
        xtile wealth_res_decile_`y' = wealth_res_`y', nq(10)
        replace wealth_res_decile_`y' = . if missing(wealth_res_`y')
        forvalues d = 1/10 {
            capture drop wealth_res_d`d'_`y'
            gen byte wealth_res_d`d'_`y' = wealth_res_decile_`y' == `d' if !missing(wealth_res_decile_`y')
        }
    }
}

* Asset shares: component / gross_assets (decoupled from m1-m5)
* r1-r5: returns to core, retirement, residential, core+IRA, net wealth
* m1-m5: wealth_core, wealth_res, wealth_ira, wealth_coreira, wealth_total (portfolios)
* gross_min = 500: avoid tiny denominators (debt/gross explodes when gross=1 etc.)
local gross_min 500
forvalues j = 5/16 {
    local y = 1990 + (2*`j')  // wave 5=2000, 16=2022
    capture drop share_pri_res_`y' share_sec_res_`y' share_res_`y' share_re_`y' share_bus_`y' share_ira_`y' share_stk_`y' share_bond_`y' share_chck_`y' share_other_`y' share_core_`y' share_fin_`y' share_debt_long_`y' share_debt_other_`y' share_debt_amort_`y' share_debt_ahmln_`y'
    capture drop gross_wealth_`y'
    capture drop h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos
    capture confirm variable h`j'atotb
    if !_rc {
        * Nonnegative components for gross assets
        gen double h`j'atoth_pos = cond(missing(h`j'atoth), ., max(h`j'atoth, 0))
        gen double h`j'anethb_pos = cond(missing(h`j'anethb), ., max(h`j'anethb, 0))
        gen double h`j'arles_pos = cond(missing(h`j'arles), ., max(h`j'arles, 0))
        gen double h`j'atran_pos = cond(missing(h`j'atran), ., max(h`j'atran, 0))
        gen double h`j'absns_pos = cond(missing(h`j'absns), ., max(h`j'absns, 0))
        gen double h`j'aira_pos = cond(missing(h`j'aira), ., max(h`j'aira, 0))
        gen double h`j'astck_pos = cond(missing(h`j'astck), ., max(h`j'astck, 0))
        gen double h`j'achck_pos = cond(missing(h`j'achck), ., max(h`j'achck, 0))
        gen double h`j'acd_pos = cond(missing(h`j'acd), ., max(h`j'acd, 0))
        gen double h`j'abond_pos = cond(missing(h`j'abond), ., max(h`j'abond, 0))
        gen double h`j'aothr_pos = cond(missing(h`j'aothr), ., max(h`j'aothr, 0))

        egen double gross_wealth_`y' = rowtotal(h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        replace gross_wealth_`y' = . if gross_wealth_`y' == 0

        * Component shares (all / gross_assets; gross >= gross_min to avoid tiny denominators)
        gen double share_pri_res_`y' = h`j'atoth_pos / gross_wealth_`y' if !missing(h`j'atoth_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_sec_res_`y' = h`j'anethb_pos / gross_wealth_`y' if !missing(h`j'anethb_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_res_`y' = (h`j'atoth_pos + h`j'anethb_pos) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_re_`y' = h`j'arles_pos / gross_wealth_`y' if !missing(h`j'arles_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_bus_`y' = h`j'absns_pos / gross_wealth_`y' if !missing(h`j'absns_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_ira_`y' = h`j'aira_pos / gross_wealth_`y' if !missing(h`j'aira_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_stk_`y' = h`j'astck_pos / gross_wealth_`y' if !missing(h`j'astck_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_bond_`y' = h`j'abond_pos / gross_wealth_`y' if !missing(h`j'abond_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_chck_`y' = h`j'achck_pos / gross_wealth_`y' if !missing(h`j'achck_pos) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_other_`y' = (h`j'acd_pos + h`j'atran_pos + h`j'aothr_pos) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        gen double share_core_`y' = (h`j'arles_pos + h`j'absns_pos + h`j'astck_pos + h`j'abond_pos + h`j'achck_pos + h`j'acd_pos) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        * share_fin = stk+bond+chck+cd; missing only if all four missing (amrtb excluded from debt)
        gen double _fin_sum_`y' = cond(missing(h`j'astck_pos),0,max(h`j'astck_pos,0)) + cond(missing(h`j'abond_pos),0,max(h`j'abond_pos,0)) + cond(missing(h`j'achck_pos),0,max(h`j'achck_pos,0)) + cond(missing(h`j'acd_pos),0,max(h`j'acd_pos,0))
        gen byte _fin_allmiss_`y' = missing(h`j'astck_pos) & missing(h`j'abond_pos) & missing(h`j'achck_pos) & missing(h`j'acd_pos)
        gen double share_fin_`y' = _fin_sum_`y' / gross_wealth_`y' if !_fin_allmiss_`y' & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        drop _fin_sum_`y' _fin_allmiss_`y'

        * Debt shares (gross assets base; long = amort+ahmln only, no amrtb; gross >= gross_min)
        gen double share_debt_amort_`y' = cond(missing(h`j'amort), 0, max(h`j'amort, 0)) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        replace share_debt_amort_`y' = . if missing(h`j'amort)
        gen double share_debt_ahmln_`y' = cond(missing(h`j'ahmln), 0, max(h`j'ahmln, 0)) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        replace share_debt_ahmln_`y' = . if missing(h`j'ahmln)
        gen double share_debt_long_`y' = (cond(missing(h`j'amort), 0, max(h`j'amort, 0)) + cond(missing(h`j'ahmln), 0, max(h`j'ahmln, 0))) / gross_wealth_`y' if !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'
        replace share_debt_long_`y' = . if missing(h`j'amort) & missing(h`j'ahmln)
        gen double share_debt_other_`y' = max(h`j'adebt, 0) / gross_wealth_`y' if !missing(h`j'adebt) & !missing(gross_wealth_`y') & gross_wealth_`y' >= `gross_min'

        drop h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos
    }
}

* Reduce dataset to relevant variables
capture unab _retvars : r1_annual_* r2_annual_* r3_annual_* r4_annual_* r5_annual_* r1_annual_avg r2_annual_avg r3_annual_avg r4_annual_avg r5_annual_avg
capture unab _wealthvars : wealth_total_* gross_wealth_* wealth_decile_* wealth_d*_* wealth_core_* wealth_ira_* wealth_coreira_* wealth_res_*
capture unab _sharevars : share_pri_res_* share_sec_res_* share_res_* share_re_* share_bus_* share_ira_* share_stk_* share_bond_* share_chck_* share_other_* share_core_* share_fin_* share_debt_long_* share_debt_other_* share_debt_amort_* share_debt_ahmln_*
capture unab _incvars : labor_income_* total_income_*
capture unab _ctrlvars : age_* inlbrf_* married_* censreg_* pop_trust_* regional_trust_* ///
    population_3bin_2020 pop3_trust_*
local keepvars hhidpn gender educ_yrs immigrant born_us race_eth ///
    trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 ///
    trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020 ///
    interest_2020 inflation_2020 risk_div_2020 par_citizen_2020 par_loyalty_2020 population_2020 population_3bin_2020 ///
    depression_2020 health_cond_2020 medicare_2020 medicaid_2020 life_ins_2020 beq_any_2020 ///
    num_divorce_2020 num_widow_2020 ///
    `_ctrlvars' `_agebinvars' `_retvars' `_wealthvars' `_sharevars' `_incvars'
keep `keepvars'

save "${PROCESSED}/analysis_ready.dta", replace
display "03_prep_controls: Saved ${PROCESSED}/analysis_ready.dta (N = " _N ")"
log close
