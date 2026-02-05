* 01_12_merge_flow_2020.do — merge 2020 flow vars from h20f1a (prefix R). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn rr050 rr055 rr063 rr064 rr072 rr073 rr030 rr035 rr045 rq171_1 rq171_2 rq171_3 rr007 rr013 rr024 ///
    rr049 rr061 rr062 rr028 rr029 rq170_1 rq170_2 rq170_3 rr002 using "${HRS_DATA}/h20f1a.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_12: Merged 2020 flows. N = " _N
