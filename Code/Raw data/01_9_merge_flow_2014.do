* 01_9_merge_flow_2014.do — merge 2014 flow vars from h14f2b (prefix O). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn or050 or055 or063 or064 or072 or073 or030 or035 or045 oq171_1 oq171_2 oq171_3 or007 or013 or024 ///
    or049 or061 or062 or028 or029 oq170_1 oq170_2 oq170_3 or002 using "${HRS_DATA}/h14f2b.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_9: Merged 2014 flows. N = " _N
