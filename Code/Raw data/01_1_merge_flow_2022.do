* 01_1_merge_flow_2022.do
* Merge 2022 flow variables from h22e3a into RAND longitudinal.
* Variable names from old repo (Chp2-BeliefsandTrust_Old): h22e3a uses lowercase (hhidpn, sr050, sr073, etc.).
* Scratch file in RAW_DATA. Final output to CLEANED.

* Do not use -clear all-: it wipes globals (RAW_DATA, CLEANED) set by 00_config.
clear
set more off
local scratch "${RAW_DATA}/_merge_scratch.dta"
capture mkdir "${CLEANED}"

* Load longitudinal
use "${HRS_DATA}/_randhrs1992_2022v1.dta", clear

* Load 2022 fat file: h22e3a uses lowercase. Flow vars + flag vars. Public stock: SR072 (flag), SR073 (amount).
preserve
use hhidpn sr050 sr055 sr063 sr064 sr072 sr073 sr030 sr035 sr045 sq171_1 sq171_2 sq171_3 sr007 sr013 sr024 ///
    sr049 sr061 sr062 sr028 sr029 sq170_1 sq170_2 sq170_3 sr002 using "${HRS_DATA}/h22e3a.dta", clear
save "`scratch'", replace
restore

merge 1:1 hhidpn using "`scratch'", nogen
capture erase "`scratch'"
* Special-value recode and flag-based 0 fill done in 02_process_flows.do (processing step).

capture mkdir "${CLEANED}"
save "${CLEANED}/all_data_merged.dta", replace
display "01_1: Merged 2022 flows. Saved " _N " obs to all_data_merged.dta"
