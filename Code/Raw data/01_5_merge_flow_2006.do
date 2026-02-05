* 01_5_merge_flow_2006.do — merge 2006 flow vars from h06f4b (prefix K). Fat files use lowercase + hhidpn.
local scratch "${RAW_DATA}/_merge_scratch.dta"
use "${CLEANED}/all_data_merged.dta", clear
preserve
use hhidpn kr050 kr055 kr063 kr064 kr072 kr073 kr030 kr035 kr045 kq171_1 kq171_2 kq171_3 kr007 kr013 kr024 ///
    kr049 kr061 kr062 kr028 kr029 kq170_1 kq170_2 kq170_3 kr002 using "${HRS_DATA}/h06f4b.dta", clear
save "`scratch'", replace
restore
merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

save "${CLEANED}/all_data_merged.dta", replace
display "01_5: Merged 2006 flows. N = " _N
