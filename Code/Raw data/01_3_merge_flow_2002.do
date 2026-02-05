* 01_3_merge_flow_2002.do — merge 2002 flow vars from h02f2c (prefix H). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn hr050 hr055 hr063 hr064 hr072 hr073 hr030 hr035 hr045 hq171_1 hq171_2 hq171_3 hr007 hr013 hr024 ///
    hr049 hr061 hr062 hr028 hr029 hq170_1 hq170_2 hq170_3 hr002 using "${HRS_DATA}/h02f2c.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_3: Merged 2002 flows. N = " _N
