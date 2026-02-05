* 01_11_merge_flow_2018.do — merge 2018 flow vars from h18f2c (prefix Q). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn qr050 qr055 qr063 qr064 qr072 qr073 qr030 qr035 qr045 qq171_1 qq171_2 qq171_3 qr007 qr013 qr024 ///
    qr049 qr061 qr062 qr028 qr029 qq170_1 qq170_2 qq170_3 qr002 using "${HRS_DATA}/h18f2c.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_11: Merged 2018 flows. N = " _N
