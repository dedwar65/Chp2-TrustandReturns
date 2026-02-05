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
    gen byte immigrant = (rabplace ~= 1) if !missing(rabplace)
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

* Region for all waves and hometown_size from region x population
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture confirm variable r`w'cenreg
    if !_rc {
        capture drop region_`y'
        gen byte region_`y' = r`w'cenreg
    }
    capture confirm variable population_2020
    if !_rc {
        capture drop hometown_size_`y'
        gen int hometown_size_`y' = region_`y' * 100 + population_2020 if !missing(region_`y') & !missing(population_2020)
    }
}

* Contextual trust (group avg of trust by region x town population, all waves)
capture confirm variable population_2020
capture confirm variable trust_others_2020
if !_rc {
    forvalues w = 5/16 {
        local y = 1990 + (2*`w')
        capture confirm variable region_`y'
        if !_rc {
            capture drop region_pop_group_`y' townsize_trust_`y'
            gen int region_pop_group_`y' = region_`y' * 100 + population_2020 if !missing(region_`y') & !missing(population_2020)
            egen double townsize_trust_`y' = mean(trust_others_2020), by(region_pop_group_`y')
        }
    }
}

* Regional trust (group avg of trust by region, all waves)
capture confirm variable trust_others_2020
if !_rc {
    forvalues w = 5/16 {
        local y = 1990 + (2*`w')
        capture confirm variable region_`y'
        if !_rc {
            capture drop regional_trust_`y'
            egen double regional_trust_`y' = mean(trust_others_2020), by(region_`y')
        }
    }
}

* ---------------------------------------------------------------------
* Wealth deciles by year (three concepts: m1, m2, total net wealth)
* RAND: h5atotb (2000), h6atotb (2002), ... h16atotb (2022). Lowercase.
* m1: non-residential, non-IRA (total - primary - secondary - IRA)
* m2: non-residential (total - primary - secondary), includes IRA
* total: h*atotb
* ---------------------------------------------------------------------
local wyears "2000 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local watotb "h5atotb h6atotb h7atotb h8atotb h9atotb h10atotb h11atotb h12atotb h13atotb h14atotb h15atotb h16atotb"
local watoth "h5atoth h6atoth h7atoth h8atoth h9atoth h10atoth h11atoth h12atoth h13atoth h14atoth h15atoth h16atoth"
local wanethb "h5anethb h6anethb h7anethb h8anethb h9anethb h10anethb h11anethb h12anethb h13anethb h14anethb h15anethb h16anethb"
local waira "h5aira h6aira h7aira h8aira h9aira h10aira h11aira h12aira h13aira h14aira h15aira h16aira"
forvalues j = 1/12 {
    local y : word `j' of `wyears'
    local w : word `j' of `watotb'
    local wpri : word `j' of `watoth'
    local wsec : word `j' of `wanethb'
    local wira : word `j' of `waira'
    capture confirm variable `w'
    capture confirm variable `wpri'
    capture confirm variable `wsec'
    capture confirm variable `wira'
    if !_rc {
        * Total net wealth (level) and deciles
        capture drop wealth_total_`y'
        gen double wealth_total_`y' = `w'
        capture drop wealth_decile_`y'
        xtile wealth_decile_`y' = `w', nq(10)
        replace wealth_decile_`y' = . if missing(`w')
        forvalues d = 1/10 {
            capture drop wealth_d`d'_`y'
            gen byte wealth_d`d'_`y' = wealth_decile_`y' == `d' if !missing(wealth_decile_`y')
        }

        * m2 wealth (exclude residences, include IRA)
        capture drop wealth_m2_`y'
        gen double wealth_m2_`y' = `w' - `wpri' - `wsec' if !missing(`w') & !missing(`wpri') & !missing(`wsec')
        capture drop wealth_m2_decile_`y'
        xtile wealth_m2_decile_`y' = wealth_m2_`y', nq(10)
        replace wealth_m2_decile_`y' = . if missing(wealth_m2_`y')
        forvalues d = 1/10 {
            capture drop wealth_m2_d`d'_`y'
            gen byte wealth_m2_d`d'_`y' = wealth_m2_decile_`y' == `d' if !missing(wealth_m2_decile_`y')
        }

        * m1 wealth (exclude residences and IRA)
        capture drop wealth_m1_`y'
        gen double wealth_m1_`y' = `w' - `wpri' - `wsec' - `wira' if !missing(`w') & !missing(`wpri') & !missing(`wsec') & !missing(`wira')
        capture drop wealth_m1_decile_`y'
        xtile wealth_m1_decile_`y' = wealth_m1_`y', nq(10)
        replace wealth_m1_decile_`y' = . if missing(wealth_m1_`y')
        forvalues d = 1/10 {
            capture drop wealth_m1_d`d'_`y'
            gen byte wealth_m1_d`d'_`y' = wealth_m1_decile_`y' == `d' if !missing(wealth_m1_decile_`y')
        }
    }
}

* Asset shares by return-scope per wave (m1, m2, m3)
forvalues j = 5/16 {
    local y = 1990 + (2*`j')  // wave 5=2000, 16=2022
    capture drop share_pri_res_`y' share_sec_res_`y' share_re_`y' share_vehicles_`y' share_bus_`y' share_ira_`y' share_stk_`y' share_chck_`y' share_cd_`y' share_bond_`y' share_other_`y'
    capture drop share_m1_re_`y' share_m1_vehicles_`y' share_m1_bus_`y' share_m1_stk_`y' share_m1_chck_`y' share_m1_cd_`y' share_m1_bond_`y' share_m1_other_`y'
    capture drop share_m2_re_`y' share_m2_vehicles_`y' share_m2_bus_`y' share_m2_ira_`y' share_m2_stk_`y' share_m2_chck_`y' share_m2_cd_`y' share_m2_bond_`y' share_m2_other_`y'
    capture drop share_m3_pri_res_`y' share_m3_sec_res_`y' share_m3_re_`y' share_m3_vehicles_`y' share_m3_bus_`y' share_m3_ira_`y' share_m3_stk_`y' share_m3_chck_`y' share_m3_cd_`y' share_m3_bond_`y' share_m3_other_`y'
    capture drop share_debt_long_`y' share_debt_other_`y'
    capture drop base_m3_assets_`y' base_m3_n_`y' base_m2_assets_`y' base_m2_n_`y' base_m1_assets_`y' base_m1_n_`y'
    capture drop h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos
    capture confirm variable h`j'atotb
    if !_rc {
        * Asset-base denominators (gross total assets, not net wealth)
        * Use nonnegative components for gross assets and shares
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

        egen double base_m3_assets_`y' = rowtotal(h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        egen byte base_m3_n_`y' = rownonmiss(h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        replace base_m3_assets_`y' = . if base_m3_n_`y' == 0

        egen double base_m2_assets_`y' = rowtotal(h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        egen byte base_m2_n_`y' = rownonmiss(h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        replace base_m2_assets_`y' = . if base_m2_n_`y' == 0

        egen double base_m1_assets_`y' = rowtotal(h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        egen byte base_m1_n_`y' = rownonmiss(h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos)
        replace base_m1_assets_`y' = . if base_m1_n_`y' == 0

        * m3 shares (gross total assets base)
        gen double share_m3_pri_res_`y' = h`j'atoth_pos / base_m3_assets_`y' if !missing(h`j'atoth_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_sec_res_`y' = h`j'anethb_pos / base_m3_assets_`y' if !missing(h`j'anethb_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_re_`y' = h`j'arles_pos / base_m3_assets_`y' if !missing(h`j'arles_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_vehicles_`y' = h`j'atran_pos / base_m3_assets_`y' if !missing(h`j'atran_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_bus_`y' = h`j'absns_pos / base_m3_assets_`y' if !missing(h`j'absns_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_ira_`y' = h`j'aira_pos / base_m3_assets_`y' if !missing(h`j'aira_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_stk_`y' = h`j'astck_pos / base_m3_assets_`y' if !missing(h`j'astck_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_chck_`y' = h`j'achck_pos / base_m3_assets_`y' if !missing(h`j'achck_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_cd_`y' = h`j'acd_pos / base_m3_assets_`y' if !missing(h`j'acd_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_bond_`y' = h`j'abond_pos / base_m3_assets_`y' if !missing(h`j'abond_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        gen double share_m3_other_`y' = h`j'aothr_pos / base_m3_assets_`y' if !missing(h`j'aothr_pos) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0

        * Debt shares (gross assets base)
        gen double share_debt_long_`y' = ///
            (cond(missing(h`j'amort), 0, max(h`j'amort, 0)) + cond(missing(h`j'ahmln), 0, max(h`j'ahmln, 0))) ///
            / base_m3_assets_`y' if !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0
        replace share_debt_long_`y' = . if missing(h`j'amort) & missing(h`j'ahmln)
        gen double share_debt_other_`y' = max(h`j'adebt, 0) / base_m3_assets_`y' if !missing(h`j'adebt) & !missing(base_m3_assets_`y') & base_m3_assets_`y' != 0

        * m2 shares (exclude residences; gross assets base)
        gen double share_m2_re_`y' = h`j'arles_pos / base_m2_assets_`y' if !missing(h`j'arles_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_vehicles_`y' = h`j'atran_pos / base_m2_assets_`y' if !missing(h`j'atran_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_bus_`y' = h`j'absns_pos / base_m2_assets_`y' if !missing(h`j'absns_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_ira_`y' = h`j'aira_pos / base_m2_assets_`y' if !missing(h`j'aira_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_stk_`y' = h`j'astck_pos / base_m2_assets_`y' if !missing(h`j'astck_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_chck_`y' = h`j'achck_pos / base_m2_assets_`y' if !missing(h`j'achck_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_cd_`y' = h`j'acd_pos / base_m2_assets_`y' if !missing(h`j'acd_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_bond_`y' = h`j'abond_pos / base_m2_assets_`y' if !missing(h`j'abond_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0
        gen double share_m2_other_`y' = h`j'aothr_pos / base_m2_assets_`y' if !missing(h`j'aothr_pos) & !missing(base_m2_assets_`y') & base_m2_assets_`y' != 0

        * m1 shares (exclude residences and IRA; gross assets base)
        gen double share_m1_re_`y' = h`j'arles_pos / base_m1_assets_`y' if !missing(h`j'arles_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_vehicles_`y' = h`j'atran_pos / base_m1_assets_`y' if !missing(h`j'atran_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_bus_`y' = h`j'absns_pos / base_m1_assets_`y' if !missing(h`j'absns_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_stk_`y' = h`j'astck_pos / base_m1_assets_`y' if !missing(h`j'astck_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_chck_`y' = h`j'achck_pos / base_m1_assets_`y' if !missing(h`j'achck_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_cd_`y' = h`j'acd_pos / base_m1_assets_`y' if !missing(h`j'acd_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_bond_`y' = h`j'abond_pos / base_m1_assets_`y' if !missing(h`j'abond_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0
        gen double share_m1_other_`y' = h`j'aothr_pos / base_m1_assets_`y' if !missing(h`j'aothr_pos) & !missing(base_m1_assets_`y') & base_m1_assets_`y' != 0

        drop base_m3_assets_`y' base_m3_n_`y' base_m2_assets_`y' base_m2_n_`y' base_m1_assets_`y' base_m1_n_`y' ///
            h`j'atoth_pos h`j'anethb_pos h`j'arles_pos h`j'atran_pos h`j'absns_pos h`j'aira_pos h`j'astck_pos h`j'achck_pos h`j'acd_pos h`j'abond_pos h`j'aothr_pos
    }
}

* Reduce dataset to relevant variables
capture unab _retvars : r1_annual_* r2_annual_* r3_annual_* debt_long_annual_* debt_other_annual_* r1_annual_avg r2_annual_avg r3_annual_avg debt_long_annual_avg debt_other_annual_avg
capture unab _wealthvars : wealth_total_* wealth_decile_* wealth_d*_* wealth_m1_* wealth_m2_*
capture unab _sharevars : share_m1_* share_m2_* share_m3_* share_debt_*
capture unab _incvars : labor_income_* total_income_*
capture unab _ctrlvars : age_* inlbrf_* married_* region_* hometown_size_* townsize_trust_* regional_trust_* region_pop_group_*
local keepvars hhidpn gender educ_yrs immigrant born_us race_eth ///
    trust_others_2020 trust_social_security_2020 trust_medicare_2020 trust_banks_2020 ///
    trust_advisors_2020 trust_mutual_funds_2020 trust_insurance_2020 trust_media_2020 ///
    interest_2020 inflation_2020 risk_div_2020 par_citizen_2020 par_loyalty_2020 population_2020 ///
    `_ctrlvars' `_retvars' `_wealthvars' `_sharevars' `_incvars'
keep `keepvars'

save "${PROCESSED}/analysis_ready.dta", replace
display "03_prep_controls: Saved ${PROCESSED}/analysis_ready.dta (N = " _N ")"
log close
