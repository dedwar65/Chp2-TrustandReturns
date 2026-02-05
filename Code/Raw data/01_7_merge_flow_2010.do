* 01_7_merge_flow_2010.do — merge 2010 flow vars from hd10f6b (prefix M). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn mr050 mr055 mr063 mr064 mr072 mr073 mr030 mr035 mr045 mq171_1 mq171_2 mq171_3 mr007 mr013 mr024 ///
    mr049 mr061 mr062 mr028 mr029 mq170_1 mq170_2 mq170_3 mr002 using "${HRS_DATA}/hd10f6b.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_7: Merged 2010 flows. N = " _N
