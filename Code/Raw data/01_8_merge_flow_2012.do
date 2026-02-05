* 01_8_merge_flow_2012.do — merge 2012 flow vars from h12f3a (prefix N). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn nr050 nr055 nr063 nr064 nr072 nr073 nr030 nr035 nr045 nq171_1 nq171_2 nq171_3 nr007 nr013 nr024 ///
    nr049 nr061 nr062 nr028 nr029 nq170_1 nq170_2 nq170_3 nr002 using "${HRS_DATA}/h12f3a.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_8: Merged 2012 flows. N = " _N
