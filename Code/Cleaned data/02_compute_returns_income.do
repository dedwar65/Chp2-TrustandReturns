* 02_compute_returns_income.do
* Load 01 output; build flow_* in 02_process_flows; then compute returns for all waves.
* Expects: 01_merge_all_data run first. Input: ${CLEANED}/all_data_merged.dta.
* Output: r1-r5_annual_YYYY + averages (r4 = core+IRA, r5 = net wealth; flows are built in 02_process_flows).

clear
set more off

* Paths
capture confirm global CLEANED
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]HRS$") {
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
use "${CLEANED}/all_data_merged.dta", clear

* ---------------------------------------------------------------------
* Build flow_*_YYYY in 02_process_flows.do
* ---------------------------------------------------------------------
do "${BASE_PATH}/Code/Cleaned data/02_process_flows.do"
* ---------------------------------------------------------------------
* Compute returns for all waves (2002–2022) using four measures
* ---------------------------------------------------------------------
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local curr_waves "6 7 8 9 10 11 12 13 14 15 16"
local prev_waves "5 6 7 8 9 10 11 12 13 14 15"
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99

forvalues i = 1/11 {
    local y : word `i' of `years'
    local wcur : word `i' of `curr_waves'
    local wprev : word `i' of `prev_waves'

    * Resolve income variable names (some waves use r*ipena/etc.)
    local penavar ""
    capture confirm variable r`wcur'ipena
    if !_rc local penavar "r`wcur'ipena"
    local ssdivar ""
    capture confirm variable r`wcur'issdi
    if !_rc local ssdivar "r`wcur'issdi"
    local isretvar ""
    capture confirm variable r`wcur'isret
    if !_rc local isretvar "r`wcur'isret"

    * Required variables (skip wave if any key vars missing)
    local req_vars h`wcur'icap ///
        h`wcur'atoth h`wprev'atoth h`wcur'anethb h`wprev'anethb h`wcur'arles h`wprev'arles ///
        h`wcur'absns h`wprev'absns h`wcur'aira h`wprev'aira h`wcur'astck h`wprev'astck ///
        h`wcur'abond h`wprev'abond h`wcur'achck h`wprev'achck h`wcur'acd h`wprev'acd ///
        h`wcur'atran h`wprev'atran h`wcur'aothr h`wprev'aothr ///
        h`wprev'amort h`wprev'ahmln h`wprev'adebt ///
        flow_core_`y' flow_ira_`y' flow_res_`y' flow_total_`y'
    capture confirm variable h`wprev'amrtb
    if !_rc local req_vars "`req_vars' h`wprev'amrtb"

    local missing_any 0
    foreach v of local req_vars {
        capture confirm variable `v'
        if _rc local missing_any 1
    }
    if "`penavar'" == "" & "`ssdivar'" == "" & "`isretvar'" == "" local missing_any 1
    local totvars ""
    foreach v in `penavar' `ssdivar' `isretvar' h`wcur'icap h`wcur'iothr {
        capture confirm variable `v'
        if !_rc local totvars "`totvars' `v'"
    }
    if "`totvars'" == "" local missing_any 1
    if `missing_any' {
        display as error "02: Missing required variables for `y' (wave `wcur'). r1/r2/r3/r4 skipped for this wave."
    }

    * Clean missing codes on inputs for this wave only
    foreach v of local req_vars {
        capture confirm numeric variable `v'
        if !_rc {
            foreach mc of local misscodes {
                quietly replace `v' = . if `v' == `mc'
            }
        }
    }
    * Clean missing codes on debt inputs (if present)
    foreach v in h`wcur'amort h`wprev'amort h`wcur'ahmln h`wprev'ahmln h`wcur'adebt h`wprev'adebt h`wcur'amrtb h`wprev'amrtb {
        capture confirm numeric variable `v'
        if !_rc {
            foreach mc of local misscodes {
                quietly replace `v' = . if `v' == `mc'
            }
        }
    }

    if !`missing_any' {
        * Capital gains components
        capture drop cg_res_`y' cg_res2_`y' cg_re_`y' cg_bus_`y' cg_ira_`y' cg_stk_`y' cg_bnd_`y' cg_chk_`y' cg_cd_`y' cg_veh_`y' cg_oth_`y'
        gen double cg_res_`y'  = . 
        gen double cg_res2_`y' = .
        gen double cg_re_`y'   = .
        gen double cg_bus_`y'  = .
        gen double cg_ira_`y'  = .
        gen double cg_stk_`y'  = .
        gen double cg_bnd_`y'  = .
        gen double cg_chk_`y'  = .
        gen double cg_cd_`y'   = .
        gen double cg_veh_`y'  = .
        gen double cg_oth_`y'  = .
        replace cg_res_`y'  = h`wcur'atoth  - h`wprev'atoth  if !missing(h`wcur'atoth)  & !missing(h`wprev'atoth)
        replace cg_res2_`y' = h`wcur'anethb - h`wprev'anethb if !missing(h`wcur'anethb) & !missing(h`wprev'anethb)
        replace cg_re_`y'   = h`wcur'arles  - h`wprev'arles  if !missing(h`wcur'arles)  & !missing(h`wprev'arles)
        replace cg_bus_`y'  = h`wcur'absns  - h`wprev'absns  if !missing(h`wcur'absns)  & !missing(h`wprev'absns)
        replace cg_ira_`y'  = h`wcur'aira   - h`wprev'aira   if !missing(h`wcur'aira)   & !missing(h`wprev'aira)
        replace cg_stk_`y'  = h`wcur'astck  - h`wprev'astck  if !missing(h`wcur'astck)  & !missing(h`wprev'astck)
        replace cg_bnd_`y'  = h`wcur'abond  - h`wprev'abond  if !missing(h`wcur'abond)  & !missing(h`wprev'abond)
        replace cg_chk_`y'  = h`wcur'achck  - h`wprev'achck  if !missing(h`wcur'achck)  & !missing(h`wprev'achck)
        replace cg_cd_`y'   = h`wcur'acd    - h`wprev'acd    if !missing(h`wcur'acd)    & !missing(h`wprev'acd)
        replace cg_veh_`y'  = h`wcur'atran  - h`wprev'atran  if !missing(h`wcur'atran)  & !missing(h`wprev'atran)
        replace cg_oth_`y'  = h`wcur'aothr  - h`wprev'aothr  if !missing(h`wcur'aothr)  & !missing(h`wprev'aothr)

        * Incomes by scope
        capture drop y_core_inc_`y' y_ira_inc_`y' y_res_inc_`y' y_total_inc_`y' y_total_int_`y'
        capture confirm variable h`wcur'icap
        if !_rc gen double y_core_inc_`y' = h`wcur'icap
        else gen double y_core_inc_`y' = .

        local iravars ""
        foreach v in `penavar' `ssdivar' `isretvar' {
            capture confirm variable `v'
            if !_rc local iravars "`iravars' `v'"
        }
        if "`iravars'" != "" {
            egen double y_ira_inc_`y' = rowtotal(`iravars')
            local iramiss "1"
            foreach v of local iravars {
                local iramiss "`iramiss' & missing(`v')"
            }
            replace y_ira_inc_`y' = . if `iramiss'
        }
        else {
            gen double y_ira_inc_`y' = .
        }

        gen double y_res_inc_`y' = 0

        if "`totvars'" != "" {
            egen double y_total_inc_`y' = rowtotal(`totvars')
            local totmiss "1"
            foreach v of local totvars {
                local totmiss "`totmiss' & missing(`v')"
            }
            replace y_total_inc_`y' = . if `totmiss'
        }
        else {
            gen double y_total_inc_`y' = .
        }

        local totintvars ""
        foreach v in `penavar' `ssdivar' `isretvar' r`wcur'iunwc r`wcur'igxfr h`wcur'icap h`wcur'iothr {
            capture confirm variable `v'
            if !_rc local totintvars "`totintvars' `v'"
        }
        if "`totintvars'" != "" {
            egen double y_total_int_`y' = rowtotal(`totintvars')
            local totintmiss "1"
            foreach v of local totintvars {
                local totintmiss "`totintmiss' & missing(`v')"
            }
            replace y_total_int_`y' = . if `totintmiss'
        }
        else {
            gen double y_total_int_`y' = .
        }

        * Capital gains by scope
        capture drop cg_core_`y' cg_ira_only_`y' cg_res_total_`y' cg_total_`y'
        gen double cg_core_`y' = cg_re_`y' + cg_bus_`y' + cg_stk_`y' + cg_bnd_`y' + cg_chk_`y' + cg_cd_`y'
        gen double cg_ira_only_`y' = cg_ira_`y'
        gen double cg_res_total_`y' = cg_res_`y' + cg_res2_`y'
        gen double cg_total_`y' = cg_core_`y' + cg_ira_only_`y' + cg_res_total_`y' + cg_veh_`y' + cg_oth_`y'

        * Flow adjustments: treat missing flows as 0 for return construction
        gen double flow_core_adj_`y' = cond(missing(flow_core_`y'), 0, flow_core_`y')
        gen double flow_ira_adj_`y' = cond(missing(flow_ira_`y'), 0, flow_ira_`y')
        gen double flow_res_adj_`y' = cond(missing(flow_res_`y'), 0, flow_res_`y')
        gen double flow_total_adj_`y' = cond(missing(flow_total_`y'), 0, flow_total_`y')

        * Minimal overlap: require all components nonmissing per measure
        egen byte _ok_core_`y' = rownonmiss(h`wprev'arles h`wprev'absns h`wprev'astck h`wprev'abond h`wprev'achck h`wprev'acd ///
            y_core_inc_`y' cg_re_`y' cg_bus_`y' cg_stk_`y' cg_bnd_`y' cg_chk_`y' cg_cd_`y')
        replace _ok_core_`y' = (_ok_core_`y' == 13)
        egen byte _ok_ira_`y' = rownonmiss(h`wprev'aira y_ira_inc_`y' cg_ira_`y')
        replace _ok_ira_`y' = (_ok_ira_`y' == 3)
        egen byte _ok_res_`y' = rownonmiss(h`wprev'atoth h`wprev'anethb y_res_inc_`y' cg_res_`y' cg_res2_`y')
        replace _ok_res_`y' = (_ok_res_`y' == 5)
        * r4 rule: denom (base) nonmissing and y_total nonmissing only (like r1/r2/r3)
        gen byte _ok_total_`y' = 0

        * Base and returns (scope-specific wealth)
        capture drop net_total_`y' base_core_`y' base_ira_`y' base_res_`y' base_total_`y'
        * Net total: constructed wealth (treat missing components as 0 so base is defined whenever we have any data)
        local secmort_term ""
        capture confirm variable h`wprev'amrtb
        if !_rc local secmort_term " - cond(missing(h`wprev'amrtb), 0, max(h`wprev'amrtb,0))"
        gen double net_total_`y' = cond(missing(h`wprev'atoth), 0, max(h`wprev'atoth,0)) + cond(missing(h`wprev'anethb), 0, max(h`wprev'anethb,0)) + ///
            cond(missing(h`wprev'arles), 0, max(h`wprev'arles,0)) + cond(missing(h`wprev'atran), 0, max(h`wprev'atran,0)) + ///
            cond(missing(h`wprev'absns), 0, max(h`wprev'absns,0)) + cond(missing(h`wprev'aira), 0, max(h`wprev'aira,0)) + ///
            cond(missing(h`wprev'astck), 0, max(h`wprev'astck,0)) + cond(missing(h`wprev'achck), 0, max(h`wprev'achck,0)) + ///
            cond(missing(h`wprev'acd), 0, max(h`wprev'acd,0)) + cond(missing(h`wprev'abond), 0, max(h`wprev'abond,0)) + ///
            cond(missing(h`wprev'aothr), 0, max(h`wprev'aothr,0)) - cond(missing(h`wprev'amort), 0, max(h`wprev'amort,0)) - cond(missing(h`wprev'ahmln), 0, max(h`wprev'ahmln,0)) - cond(missing(h`wprev'adebt), 0, max(h`wprev'adebt,0)) `secmort_term'
        gen double base_total_`y' = net_total_`y' + 0.5 * flow_total_adj_`y'
        replace _ok_total_`y' = 1 if !missing(base_total_`y') & base_total_`y' > 0 & !missing(y_total_inc_`y')

        gen double base_core_`y' = (h`wprev'arles + h`wprev'absns + h`wprev'astck + h`wprev'abond + h`wprev'achck + h`wprev'acd) + 0.5 * flow_core_adj_`y' if _ok_core_`y'
        gen double base_ira_`y' = h`wprev'aira + 0.5 * flow_ira_adj_`y' if _ok_ira_`y'
        gen double base_res_`y' = (h`wprev'atoth + h`wprev'anethb) + 0.5 * flow_res_adj_`y' if _ok_res_`y'

        * Base diagnostics (minimal overlap sample, before dropping base thresholds)
        quietly count if _ok_core_`y' & base_core_`y' <= 0
        display "r1 base<=0 (`y'): " r(N)
        quietly count if _ok_core_`y' & base_core_`y' < 1000
        display "r1 base<1k (`y'): " r(N)
        quietly count if _ok_core_`y' & base_core_`y' < 2000
        display "r1 base<2k (`y'): " r(N)
        quietly count if _ok_core_`y' & base_core_`y' < 5000
        display "r1 base<5k (`y'): " r(N)

        quietly count if _ok_ira_`y' & base_ira_`y' <= 0
        display "r2 base<=0 (`y'): " r(N)
        quietly count if _ok_ira_`y' & base_ira_`y' < 1000
        display "r2 base<1k (`y'): " r(N)
        quietly count if _ok_ira_`y' & base_ira_`y' < 2000
        display "r2 base<2k (`y'): " r(N)
        quietly count if _ok_ira_`y' & base_ira_`y' < 5000
        display "r2 base<5k (`y'): " r(N)

        quietly count if _ok_res_`y' & base_res_`y' <= 0
        display "r3 base<=0 (`y'): " r(N)
        quietly count if _ok_res_`y' & base_res_`y' < 1000
        display "r3 base<1k (`y'): " r(N)
        quietly count if _ok_res_`y' & base_res_`y' < 2000
        display "r3 base<2k (`y'): " r(N)
        quietly count if _ok_res_`y' & base_res_`y' < 5000
        display "r3 base<5k (`y'): " r(N)

        * Apply minimum base thresholds by return type
        local base_core_min = 500
        local base_ira_min = 1000
        local base_res_min = 1000
        local base_total_min = 2500
        replace base_core_`y' = . if base_core_`y' < `base_core_min'
        replace base_ira_`y' = . if base_ira_`y' < `base_ira_min'
        replace base_res_`y' = . if base_res_`y' < `base_res_min'
        replace base_total_`y' = . if base_total_`y' < `base_total_min'

        capture drop num_core_`y' num_ira_`y' num_res_`y' num_total_`y' num_coreira_`y'
        gen double num_core_`y' = y_core_inc_`y' + cg_core_`y' - flow_core_adj_`y' if _ok_core_`y'
        gen double num_ira_`y' = y_ira_inc_`y' + cg_ira_only_`y' - flow_ira_adj_`y' if _ok_ira_`y'
        gen double num_res_`y' = y_res_inc_`y' + cg_res_total_`y' - flow_res_adj_`y' if _ok_res_`y'
        gen double num_total_`y' = y_total_inc_`y' + cg_total_`y' - flow_total_adj_`y' if _ok_total_`y'
        * r4 = core+IRA: return nonmissing when either core OR IRA has nonmissing (same rule as r1/r2/r3)
        gen byte _ok_coreira_`y' = (_ok_core_`y' | _ok_ira_`y')
        gen double num_coreira_`y' = .
        gen double base_coreira_`y' = .
        replace num_coreira_`y' = num_core_`y' + num_ira_`y' if _ok_core_`y' & _ok_ira_`y'
        replace base_coreira_`y' = base_core_`y' + base_ira_`y' if _ok_core_`y' & _ok_ira_`y'
        replace num_coreira_`y' = num_core_`y' if _ok_core_`y' & !_ok_ira_`y'
        replace base_coreira_`y' = base_core_`y' if _ok_core_`y' & !_ok_ira_`y'
        replace num_coreira_`y' = num_ira_`y' if !_ok_core_`y' & _ok_ira_`y'
        replace base_coreira_`y' = base_ira_`y' if !_ok_core_`y' & _ok_ira_`y'
        local base_coreira_min = 1500
        replace base_coreira_`y' = . if base_coreira_`y' != . & base_coreira_`y' < `base_coreira_min'
        quietly count if _ok_coreira_`y' & base_coreira_`y' != . & base_coreira_`y' <= 0
        display "r4 base<=0 (`y'): " r(N)
        quietly count if _ok_coreira_`y' & base_coreira_`y' != . & base_coreira_`y' < 1000
        display "r4 base<1k (`y'): " r(N)
        quietly count if _ok_coreira_`y' & base_coreira_`y' != . & base_coreira_`y' < 2000
        display "r4 base<2k (`y'): " r(N)
        quietly count if _ok_coreira_`y' & base_coreira_`y' != . & base_coreira_`y' < 5000
        display "r4 base<5k (`y'): " r(N)

        capture drop r1_period_`y' r2_period_`y' r3_period_`y' r4_period_`y' r5_period_`y'
        gen double r1_period_`y' = num_core_`y' / base_core_`y'
        gen double r2_period_`y' = num_ira_`y' / base_ira_`y'
        gen double r3_period_`y' = num_res_`y' / base_res_`y'
        gen double r4_period_`y' = num_coreira_`y' / base_coreira_`y'
        gen double r5_period_`y' = num_total_`y' / base_total_`y'

        replace r1_period_`y' = . if base_core_`y' <= 0
        replace r2_period_`y' = . if base_ira_`y' <= 0
        replace r3_period_`y' = . if base_res_`y' <= 0
        replace r4_period_`y' = . if base_coreira_`y' <= 0
        replace r5_period_`y' = . if base_total_`y' <= 0

        capture drop r1_annual_`y' r2_annual_`y' r3_annual_`y' r4_annual_`y' r5_annual_`y'
        gen double r1_annual_`y' = (1 + r1_period_`y')^(1/2) - 1
        gen double r2_annual_`y' = (1 + r2_period_`y')^(1/2) - 1
        gen double r3_annual_`y' = (1 + r3_period_`y')^(1/2) - 1
        gen double r4_annual_`y' = (1 + r4_period_`y')^(1/2) - 1
        gen double r5_annual_`y' = (1 + r5_period_`y')^(1/2) - 1
        replace r1_annual_`y' = . if missing(r1_period_`y')
        replace r2_annual_`y' = . if missing(r2_period_`y')
        replace r3_annual_`y' = . if missing(r3_period_`y')
        replace r4_annual_`y' = . if missing(r4_period_`y')
        replace r5_annual_`y' = . if missing(r5_period_`y')

        capture drop flow_core_adj_`y' flow_ira_adj_`y' flow_res_adj_`y' flow_total_adj_`y'

    }
    capture drop _ok_core_`y' _ok_ira_`y' _ok_res_`y' _ok_total_`y' _ok_coreira_`y'
}

* Average returns across waves (row mean of nonmissing)
capture drop r1_annual_avg
capture drop r2_annual_avg
capture drop r3_annual_avg
capture drop r4_annual_avg
capture drop r5_annual_avg
egen double r1_annual_avg = rowmean(r1_annual_2002 r1_annual_2004 r1_annual_2006 r1_annual_2008 r1_annual_2010 r1_annual_2012 r1_annual_2014 r1_annual_2016 r1_annual_2018 r1_annual_2020 r1_annual_2022)
egen double r2_annual_avg = rowmean(r2_annual_2002 r2_annual_2004 r2_annual_2006 r2_annual_2008 r2_annual_2010 r2_annual_2012 r2_annual_2014 r2_annual_2016 r2_annual_2018 r2_annual_2020 r2_annual_2022)
egen double r3_annual_avg = rowmean(r3_annual_2002 r3_annual_2004 r3_annual_2006 r3_annual_2008 r3_annual_2010 r3_annual_2012 r3_annual_2014 r3_annual_2016 r3_annual_2018 r3_annual_2020 r3_annual_2022)
egen double r4_annual_avg = rowmean(r4_annual_2002 r4_annual_2004 r4_annual_2006 r4_annual_2008 r4_annual_2010 r4_annual_2012 r4_annual_2014 r4_annual_2016 r4_annual_2018 r4_annual_2020 r4_annual_2022)
egen double r5_annual_avg = rowmean(r5_annual_2002 r5_annual_2004 r5_annual_2006 r5_annual_2008 r5_annual_2010 r5_annual_2012 r5_annual_2014 r5_annual_2016 r5_annual_2018 r5_annual_2020 r5_annual_2022)

* Income measures per wave (labor + total) for downstream processing
forvalues j = 6/16 {
    local y = 1990 + (2*`j')  // wave 6=2002, 16=2022
    capture drop labor_income_`y' total_income_`y'
    local inc_vars "r`j'iearn r`j'ipena r`j'issdi r`j'isret r`j'iunwc r`j'igxfr"
    capture confirm variable r`j'iearn r`j'ipena r`j'issdi r`j'isret r`j'iunwc r`j'igxfr
    if !_rc {
        egen double labor_income_`y' = rowtotal(`inc_vars')
        replace labor_income_`y' = . if missing(r`j'iearn) & missing(r`j'ipena) & missing(r`j'issdi) & ///
            missing(r`j'isret) & missing(r`j'iunwc) & missing(r`j'igxfr)
    }
    capture confirm variable h`j'icap h`j'iothr
    if !_rc {
        gen double total_income_`y' = labor_income_`y' ///
            + cond(missing(h`j'icap), 0, h`j'icap) ///
            + cond(missing(h`j'iothr), 0, h`j'iothr)
        replace total_income_`y' = . if missing(labor_income_`y') & missing(h`j'icap) & missing(h`j'iothr)
    }

    * Diagnostics: confirm income variables created
    capture confirm variable labor_income_`y'
    if !_rc {
        quietly count if !missing(labor_income_`y')
        display "labor_income_`y' nonmissing: " r(N)
    }
    capture confirm variable total_income_`y'
    if !_rc {
        quietly count if !missing(total_income_`y')
        display "total_income_`y' nonmissing: " r(N)
    }
}

* Average income across waves (row mean of nonmissing)
capture drop labor_income_avg total_income_avg
egen double labor_income_avg = rowmean(labor_income_2002 labor_income_2004 labor_income_2006 labor_income_2008 labor_income_2010 labor_income_2012 labor_income_2014 labor_income_2016 labor_income_2018 labor_income_2020 labor_income_2022)
egen double total_income_avg = rowmean(total_income_2002 total_income_2004 total_income_2006 total_income_2008 total_income_2010 total_income_2012 total_income_2014 total_income_2016 total_income_2018 total_income_2020 total_income_2022)

* Wealth totals by wave (net and gross), for downstream tracking
forvalues w = 5/16 {
    local y = 1990 + (2*`w')
    capture drop wealth_total_`y' gross_wealth_`y' _gross_n_`y' _debt_total_`y' _debt_n_`y'
    egen byte _gross_n_`y' = rownonmiss(h`w'atoth h`w'anethb h`w'arles h`w'atran h`w'absns h`w'aira h`w'astck h`w'achck h`w'acd h`w'abond h`w'aothr)
    egen double _debt_total_`y' = rowtotal(h`w'amort h`w'ahmln h`w'adebt h`w'amrtb), missing
    egen byte _debt_n_`y' = rownonmiss(h`w'amort h`w'ahmln h`w'adebt h`w'amrtb)
    gen double gross_wealth_`y' = ///
        cond(missing(h`w'atoth), 0, max(h`w'atoth, 0)) + cond(missing(h`w'anethb), 0, max(h`w'anethb, 0)) + ///
        cond(missing(h`w'arles), 0, max(h`w'arles, 0)) + cond(missing(h`w'atran), 0, max(h`w'atran, 0)) + ///
        cond(missing(h`w'absns), 0, max(h`w'absns, 0)) + cond(missing(h`w'aira), 0, max(h`w'aira, 0)) + ///
        cond(missing(h`w'astck), 0, max(h`w'astck, 0)) + cond(missing(h`w'achck), 0, max(h`w'achck, 0)) + ///
        cond(missing(h`w'acd), 0, max(h`w'acd, 0)) + cond(missing(h`w'abond), 0, max(h`w'abond, 0)) + ///
        cond(missing(h`w'aothr), 0, max(h`w'aothr, 0))
    replace gross_wealth_`y' = . if _gross_n_`y' == 0
    gen double wealth_total_`y' = gross_wealth_`y' - _debt_total_`y'
    replace wealth_total_`y' = . if _gross_n_`y' == 0 & _debt_n_`y' == 0
    drop _gross_n_`y' _debt_total_`y' _debt_n_`y'
}

* Save
save "${CLEANED}/all_data_merged.dta", replace
display "02: Saved ${CLEANED}/all_data_merged.dta with flow_*_YYYY and r1-r5_annual_YYYY (N = " _N ")"
