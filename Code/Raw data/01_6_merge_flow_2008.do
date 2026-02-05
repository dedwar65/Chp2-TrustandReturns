* 01_6_merge_flow_2008.do — merge 2008 flow vars from h08f3b (prefix L). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn lr050 lr055 lr063 lr064 lr072 lr073 lr030 lr035 lr045 lq171_1 lq171_2 lq171_3 lr007 lr013 lr024 ///
    lr049 lr061 lr062 lr028 lr029 lq170_1 lq170_2 lq170_3 lr002 using "${HRS_DATA}/h08f3b.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_6: Merged 2008 flows. N = " _N
