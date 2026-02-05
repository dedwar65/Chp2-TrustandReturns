* 01_4_merge_flow_2004.do — merge 2004 flow vars from h04f1c (prefix J). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn jr050 jr055 jr063 jr064 jr072 jr073 jr030 jr035 jr045 jq171_1 jq171_2 jq171_3 jr007 jr013 jr024 ///
    jr049 jr061 jr062 jr028 jr029 jq170_1 jq170_2 jq170_3 jr002 using "${HRS_DATA}/h04f1c.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_4: Merged 2004 flows. N = " _N
