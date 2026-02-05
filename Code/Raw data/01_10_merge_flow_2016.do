* 01_10_merge_flow_2016.do — merge 2016 flow vars from h16f2c (prefix P). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn pr050 pr055 pr063 pr064 pr072 pr073 pr030 pr035 pr045 pq171_1 pq171_2 pq171_3 pr007 pr013 pr024 ///
    pr049 pr061 pr062 pr028 pr029 pq170_1 pq170_2 pq170_3 pr002 using "${HRS_DATA}/h16f2c.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_10: Merged 2016 flows. N = " _N
