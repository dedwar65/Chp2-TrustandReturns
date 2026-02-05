* 02_compute_returns_income.do
* Load 01 output; build flow_* and flow_m1/m2/total_YYYY in 02_process_flows; then compute returns for all waves.
* Expects: 01_merge_all_data run first. Input: ${CLEANED}/all_data_merged.dta.
* Output: r1/r2/r3_annual_YYYY + averages (flows are built in 02_process_flows).

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
* Build flow_* and flow_m1/m2/total_YYYY in 02_process_flows.do
* ---------------------------------------------------------------------
do "${BASE_PATH}/Code/Cleaned data/02_process_flows.do"
* ---------------------------------------------------------------------
* Compute returns for all waves (2002–2022) using three measures
* ---------------------------------------------------------------------
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
local curr_waves "6 7 8 9 10 11 12 13 14 15 16"
local prev_waves "5 6 7 8 9 10 11 12 13 14 15"
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99

forvalues i = 1/11 {
    local y : word `i' of `years'
    local wcur : word `i' of `curr_waves'
    local wprev : word `i' of `prev_waves'

    * Resolve income variable names (some waves use r*iearn/ipena/etc.)
    local earnvar ""
    capture confirm variable r`wcur'iearn
    if !_rc local earnvar "r`wcur'iearn"
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
    local req_vars h`wprev'atotb h`wcur'itot ///
        h`wcur'atoth h`wprev'atoth h`wcur'anethb h`wprev'anethb h`wcur'arles h`wprev'arles ///
        h`wcur'absns h`wprev'absns h`wcur'aira h`wprev'aira h`wcur'astck h`wprev'astck ///
        h`wcur'abond h`wprev'abond h`wcur'achck h`wprev'achck h`wcur'acd h`wprev'acd ///
        h`wcur'atran h`wprev'atran h`wcur'aothr h`wprev'aothr ///
        flow_m1_`y' flow_m2_`y' flow_total_`y'

    local missing_any 0
    foreach v of local req_vars {
        capture confirm variable `v'
        if _rc local missing_any 1
    }
    if "`earnvar'" == "" local missing_any 1
    if "`penavar'" == "" local missing_any 1
    if "`ssdivar'" == "" local missing_any 1
    if "`isretvar'" == "" local missing_any 1
    if `missing_any' {
        display as error "02: Missing required variables for `y' (wave `wcur'). r1/r2/r3 skipped for this wave."
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
    foreach v in h`wcur'amort h`wprev'amort h`wcur'ahmln h`wprev'ahmln h`wcur'adebt h`wprev'adebt {
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

        * Incomes
        capture drop y1_inc_`y' y2_inc_`y' y3_inc_`y'
        gen double y1_inc_`y' = `earnvar'
        gen double y2_inc_`y' = `earnvar' + `penavar' + `ssdivar' + `isretvar'
        replace y2_inc_`y' = . if missing(`earnvar') & missing(`penavar') & missing(`ssdivar') & missing(`isretvar')
        gen double y3_inc_`y' = h`wcur'itot

        * Flows by scope (already built in 02_process_flows)
        capture drop flow_m3_`y'
        gen double flow_m3_`y' = flow_total_`y'

        * Capital gains by scope
        capture drop cg_m1_`y' cg_m2_`y' cg_m3_`y'
        gen double cg_m1_`y' = cg_re_`y' + cg_bus_`y' + cg_stk_`y' + cg_bnd_`y' + cg_chk_`y' + cg_cd_`y' + cg_veh_`y' + cg_oth_`y'
        gen double cg_m2_`y' = cg_m1_`y' + cg_ira_`y'
        gen double cg_m3_`y' = cg_m2_`y' + cg_res_`y' + cg_res2_`y'

        * Minimal overlap: require all components nonmissing per measure
        egen byte _ok_m1_`y' = rownonmiss(h`wprev'atotb y1_inc_`y' flow_m1_`y' ///
            cg_re_`y' cg_bus_`y' cg_stk_`y' cg_bnd_`y' cg_chk_`y' cg_cd_`y' cg_veh_`y' cg_oth_`y')
        replace _ok_m1_`y' = (_ok_m1_`y' == 11)
        egen byte _ok_m2_`y' = rownonmiss(h`wprev'atotb y2_inc_`y' flow_m2_`y' ///
            cg_re_`y' cg_bus_`y' cg_stk_`y' cg_bnd_`y' cg_chk_`y' cg_cd_`y' cg_veh_`y' cg_oth_`y' cg_ira_`y')
        replace _ok_m2_`y' = (_ok_m2_`y' == 12)
        egen byte _ok_m3_`y' = rownonmiss(h`wprev'atotb y3_inc_`y' flow_m3_`y' ///
            cg_re_`y' cg_bus_`y' cg_stk_`y' cg_bnd_`y' cg_chk_`y' cg_cd_`y' cg_veh_`y' cg_oth_`y' cg_ira_`y' cg_res_`y' cg_res2_`y')
        replace _ok_m3_`y' = (_ok_m3_`y' == 14)

        * Base and returns
        capture drop base_m1_`y' base_m2_`y' base_m3_`y'
        gen double base_m1_`y' = h`wprev'atotb + 0.5 * flow_m1_`y' if _ok_m1_`y'
        gen double base_m2_`y' = h`wprev'atotb + 0.5 * flow_m2_`y' if _ok_m2_`y'
        gen double base_m3_`y' = h`wprev'atotb + 0.5 * flow_m3_`y' if _ok_m3_`y'

        * Base diagnostics (minimal overlap sample, before dropping base<=0)
        quietly count if _ok_m1_`y' & base_m1_`y' <= 0
        display "r1 base<=0 (`y'): " r(N)
        quietly count if _ok_m1_`y' & base_m1_`y' < 1000
        display "r1 base<1k (`y'): " r(N)
        quietly count if _ok_m1_`y' & base_m1_`y' < 2000
        display "r1 base<2k (`y'): " r(N)
        quietly count if _ok_m1_`y' & base_m1_`y' < 5000
        display "r1 base<5k (`y'): " r(N)

        quietly count if _ok_m2_`y' & base_m2_`y' <= 0
        display "r2 base<=0 (`y'): " r(N)
        quietly count if _ok_m2_`y' & base_m2_`y' < 1000
        display "r2 base<1k (`y'): " r(N)
        quietly count if _ok_m2_`y' & base_m2_`y' < 2000
        display "r2 base<2k (`y'): " r(N)
        quietly count if _ok_m2_`y' & base_m2_`y' < 5000
        display "r2 base<5k (`y'): " r(N)

        quietly count if _ok_m3_`y' & base_m3_`y' <= 0
        display "r3 base<=0 (`y'): " r(N)
        quietly count if _ok_m3_`y' & base_m3_`y' < 1000
        display "r3 base<1k (`y'): " r(N)
        quietly count if _ok_m3_`y' & base_m3_`y' < 2000
        display "r3 base<2k (`y'): " r(N)
        quietly count if _ok_m3_`y' & base_m3_`y' < 5000
        display "r3 base<5k (`y'): " r(N)

        capture drop num_m1_`y' num_m2_`y' num_m3_`y'
        gen double num_m1_`y' = y1_inc_`y' + cg_m1_`y' - flow_m1_`y' if _ok_m1_`y'
        gen double num_m2_`y' = y2_inc_`y' + cg_m2_`y' - flow_m2_`y' if _ok_m2_`y'
        gen double num_m3_`y' = y3_inc_`y' + cg_m3_`y' - flow_m3_`y' if _ok_m3_`y'

        capture drop r1_period_`y' r2_period_`y' r3_period_`y'
        gen double r1_period_`y' = num_m1_`y' / base_m1_`y'
        gen double r2_period_`y' = num_m2_`y' / base_m2_`y'
        gen double r3_period_`y' = num_m3_`y' / base_m3_`y'

        replace r1_period_`y' = . if base_m1_`y' <= 0
        replace r2_period_`y' = . if base_m2_`y' <= 0
        replace r3_period_`y' = . if base_m3_`y' <= 0

        capture drop r1_annual_`y' r2_annual_`y' r3_annual_`y'
        gen double r1_annual_`y' = (1 + r1_period_`y')^(1/2) - 1
        gen double r2_annual_`y' = (1 + r2_period_`y')^(1/2) - 1
        gen double r3_annual_`y' = (1 + r3_period_`y')^(1/2) - 1
        replace r1_annual_`y' = . if missing(r1_period_`y')
        replace r2_annual_`y' = . if missing(r2_period_`y')
        replace r3_annual_`y' = . if missing(r3_period_`y')

        * Debt return measures (mirror r1-r3 pipeline; numerator only uses debt term)
        local has_debt_long 1
        local has_debt_other 1
        capture confirm variable h`wcur'amort h`wprev'amort h`wcur'ahmln h`wprev'ahmln
        if _rc local has_debt_long 0
        capture confirm variable h`wcur'adebt h`wprev'adebt
        if _rc local has_debt_other 0

        if `has_debt_long' {
            capture drop debt_long_`y'
            gen double debt_long_`y' = cond(missing(h`wcur'amort) & missing(h`wcur'ahmln), ., ///
                cond(missing(h`wcur'amort), 0, h`wcur'amort) + cond(missing(h`wcur'ahmln), 0, h`wcur'ahmln))

            capture drop _ok_debt_long_`y'
            capture drop base_debt_long_`y'
            egen byte _ok_debt_long_`y' = rownonmiss(h`wprev'atotb flow_total_`y' debt_long_`y')
            replace _ok_debt_long_`y' = (_ok_debt_long_`y' == 3)
            gen double base_debt_long_`y' = h`wprev'atotb + 0.5 * flow_total_`y' if _ok_debt_long_`y'

            quietly count if _ok_debt_long_`y' & base_debt_long_`y' <= 0
            display "debt_long base<=0 (`y'): " r(N)
            quietly count if _ok_debt_long_`y' & base_debt_long_`y' < 1000
            display "debt_long base<1k (`y'): " r(N)
            quietly count if _ok_debt_long_`y' & base_debt_long_`y' < 2000
            display "debt_long base<2k (`y'): " r(N)
            quietly count if _ok_debt_long_`y' & base_debt_long_`y' < 5000
            display "debt_long base<5k (`y'): " r(N)

            capture drop num_debt_long_`y' debt_long_period_`y' debt_long_annual_`y'
            gen double num_debt_long_`y' = debt_long_`y' if _ok_debt_long_`y'
            gen double debt_long_period_`y' = num_debt_long_`y' / base_debt_long_`y'
            replace debt_long_period_`y' = . if base_debt_long_`y' <= 0
            gen double debt_long_annual_`y' = (1 + debt_long_period_`y')^(1/2) - 1
            replace debt_long_annual_`y' = . if missing(debt_long_period_`y')
        }

        if `has_debt_other' {
            capture drop debt_other_`y'
            gen double debt_other_`y' = h`wcur'adebt

            capture drop _ok_debt_other_`y'
            capture drop base_debt_other_`y'
            egen byte _ok_debt_other_`y' = rownonmiss(h`wprev'atotb flow_total_`y' debt_other_`y')
            replace _ok_debt_other_`y' = (_ok_debt_other_`y' == 3)
            gen double base_debt_other_`y' = h`wprev'atotb + 0.5 * flow_total_`y' if _ok_debt_other_`y'

            quietly count if _ok_debt_other_`y' & base_debt_other_`y' <= 0
            display "debt_other base<=0 (`y'): " r(N)
            quietly count if _ok_debt_other_`y' & base_debt_other_`y' < 1000
            display "debt_other base<1k (`y'): " r(N)
            quietly count if _ok_debt_other_`y' & base_debt_other_`y' < 2000
            display "debt_other base<2k (`y'): " r(N)
            quietly count if _ok_debt_other_`y' & base_debt_other_`y' < 5000
            display "debt_other base<5k (`y'): " r(N)

            capture drop num_debt_other_`y' debt_other_period_`y' debt_other_annual_`y'
            gen double num_debt_other_`y' = debt_other_`y' if _ok_debt_other_`y'
            gen double debt_other_period_`y' = num_debt_other_`y' / base_debt_other_`y'
            replace debt_other_period_`y' = . if base_debt_other_`y' <= 0
            gen double debt_other_annual_`y' = (1 + debt_other_period_`y')^(1/2) - 1
            replace debt_other_annual_`y' = . if missing(debt_other_period_`y')
        }
    }
    capture drop _ok_m1_`y' _ok_m2_`y' _ok_m3_`y' _ok_debt_long_`y' _ok_debt_other_`y'
}

* Average returns across waves (row mean of nonmissing)
capture drop r1_annual_avg
capture drop r2_annual_avg
capture drop r3_annual_avg
capture drop debt_long_annual_avg
capture drop debt_other_annual_avg
egen double r1_annual_avg = rowmean(r1_annual_2002 r1_annual_2004 r1_annual_2006 r1_annual_2008 r1_annual_2010 r1_annual_2012 r1_annual_2014 r1_annual_2016 r1_annual_2018 r1_annual_2020 r1_annual_2022)
egen double r2_annual_avg = rowmean(r2_annual_2002 r2_annual_2004 r2_annual_2006 r2_annual_2008 r2_annual_2010 r2_annual_2012 r2_annual_2014 r2_annual_2016 r2_annual_2018 r2_annual_2020 r2_annual_2022)
egen double r3_annual_avg = rowmean(r3_annual_2002 r3_annual_2004 r3_annual_2006 r3_annual_2008 r3_annual_2010 r3_annual_2012 r3_annual_2014 r3_annual_2016 r3_annual_2018 r3_annual_2020 r3_annual_2022)
egen double debt_long_annual_avg = rowmean(debt_long_annual_2002 debt_long_annual_2004 debt_long_annual_2006 debt_long_annual_2008 debt_long_annual_2010 debt_long_annual_2012 debt_long_annual_2014 debt_long_annual_2016 debt_long_annual_2018 debt_long_annual_2020 debt_long_annual_2022)
egen double debt_other_annual_avg = rowmean(debt_other_annual_2002 debt_other_annual_2004 debt_other_annual_2006 debt_other_annual_2008 debt_other_annual_2010 debt_other_annual_2012 debt_other_annual_2014 debt_other_annual_2016 debt_other_annual_2018 debt_other_annual_2020 debt_other_annual_2022)

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

* Save
save "${CLEANED}/all_data_merged.dta", replace
display "02: Saved ${CLEANED}/all_data_merged.dta with flow_*_YYYY, r1/r2/r3_annual_YYYY, and debt_*_annual_YYYY (N = " _N ")"
