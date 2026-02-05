* 01_2_merge_trust_2020.do
* Merge 2020 trust (rv557-rv570) from h20f1a. Uses project scratch file.
* Merge key: hhidpn (per long_merge_in_trust_2020.do in old repo). Input: ${CLEANED}/all_data_merged.dta

* Do not use -clear all-: it wipes globals (RAW_DATA, CLEANED) set by 00_config.
clear
set more off

local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear

preserve
use hhidpn rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564 rv565 rv566 rv567 rv568 rv569 rv570 using "${HRS_DATA}/h20f1a.dta", clear
rename (rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564 rv565 rv566 rv567 rv568 rv569 rv570) ///
       (rv557_2020 rv558_2020 rv559_2020 rv560_2020 rv561_2020 rv562_2020 rv563_2020 rv564_2020 ///
        rv565_2020 rv566_2020 rv567_2020 rv568_2020 rv569_2020 rv570_2020)
save "`scratch'", replace
restore

merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"

* Recode HRS special values to missing for r557-r570 (trust). Per codebook RV570: -8 Web non-response, 8 DK/NA, 9 RF.
* We remove -9 -8 8 9 98 99 (and 9998 ... 99999999) so 99 and all DK/NA/RF are missing for *r557-*r570.
local trustvars rv557_2020 rv558_2020 rv559_2020 rv560_2020 rv561_2020 rv562_2020 rv563_2020 rv564_2020 rv565_2020 rv566_2020 rv567_2020 rv568_2020 rv569_2020 rv570_2020
local miss -9 -8 8 9 98 99 9998 9999 999998 999999 9999998 9999999 99999998 99999999
foreach v of local trustvars {
    foreach m of local miss {
        quietly replace `v' = . if `v' == `m'
    }
}

save "${CLEANED}/all_data_merged.dta", replace
display "01_2: Merged 2020 trust (rv557-rv570). Saved " _N " obs"
