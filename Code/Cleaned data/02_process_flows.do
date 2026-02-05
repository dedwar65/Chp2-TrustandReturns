* 02_process_flows.do
* Standalone: (1) recode HRS special values to missing for flow/flag vars,
* (2) flag==5 -> flow 0, (3) construct flow_*_YYYY per wave.
* Expects: run after 01_merge_all_data. Input: ${CLEANED}/all_data_merged.dta.
* Output: same file with flow_*_2002 ... flow_*_2022.

clear
set more off

* Paths: set BASE_PATH and run 00_config if CLEANED not set (so script works when run standalone or from any folder)
capture confirm global CLEANED
if _rc {
    while regexm("`c(pwd)'", "[\/]Code[\/]") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]HRS$") {
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]Raw data$") {
        cd ..
        cd ..
    }
    if regexm("`c(pwd)'", "[\/]Code$") {
        cd ..
    }
    global BASE_PATH "`c(pwd)'"
    do "${BASE_PATH}/Code/Raw data/00_config.do"
}
use "${CLEANED}/all_data_merged.dta", clear

local waves "h j k l m n o p q r s"
local years "2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022"
* Ensure flow vars exist from 01_merge_all_data
capture confirm variable hr050
if _rc display as error "02_process_flows: No hr050 found. Run 01_merge_all_data.do first and ensure flow merges ran."

* (1) Recode special values to missing for ALL variables imported from fat files (flow + flag, every wave)
* Use inlist() so -8/-9 are handled reliably (no macro expansion of negative numbers).
local fatvars hr050 hr055 hr063 hr064 hr072 hr073 hr030 hr035 hr045 hq171_1 hq171_2 hq171_3 hr007 hr013 hr024 hr049 hr061 hr062 hr028 hr029 hq170_1 hq170_2 hq170_3 hr002 ///
    jr050 jr055 jr063 jr064 jr072 jr073 jr030 jr035 jr045 jq171_1 jq171_2 jq171_3 jr007 jr013 jr024 jr049 jr061 jr062 jr028 jr029 jq170_1 jq170_2 jq170_3 jr002 ///
    kr050 kr055 kr063 kr064 kr072 kr073 kr030 kr035 kr045 kq171_1 kq171_2 kq171_3 kr007 kr013 kr024 kr049 kr061 kr062 kr028 kr029 kq170_1 kq170_2 kq170_3 kr002 ///
    lr050 lr055 lr063 lr064 lr072 lr073 lr030 lr035 lr045 lq171_1 lq171_2 lq171_3 lr007 lr013 lr024 lr049 lr061 lr062 lr028 lr029 lq170_1 lq170_2 lq170_3 lr002 ///
    mr050 mr055 mr063 mr064 mr072 mr073 mr030 mr035 mr045 mq171_1 mq171_2 mq171_3 mr007 mr013 mr024 mr049 mr061 mr062 mr028 mr029 mq170_1 mq170_2 mq170_3 mr002 ///
    nr050 nr055 nr063 nr064 nr072 nr073 nr030 nr035 nr045 nq171_1 nq171_2 nq171_3 nr007 nr013 nr024 nr049 nr061 nr062 nr028 nr029 nq170_1 nq170_2 nq170_3 nr002 ///
    or050 or055 or063 or064 or072 or073 or030 or035 or045 oq171_1 oq171_2 oq171_3 or007 or013 or024 or049 or061 or062 or028 or029 oq170_1 oq170_2 oq170_3 or002 ///
    pr050 pr055 pr063 pr064 pr072 pr073 pr030 pr035 pr045 pq171_1 pq171_2 pq171_3 pr007 pr013 pr024 pr049 pr061 pr062 pr028 pr029 pq170_1 pq170_2 pq170_3 pr002 ///
    qr050 qr055 qr063 qr064 qr072 qr073 qr030 qr035 qr045 qq171_1 qq171_2 qq171_3 qr007 qr013 qr024 qr049 qr061 qr062 qr028 qr029 qq170_1 qq170_2 qq170_3 qr002 ///
    rr050 rr055 rr063 rr064 rr072 rr073 rr030 rr035 rr045 rq171_1 rq171_2 rq171_3 rr007 rr013 rr024 rr049 rr061 rr062 rr028 rr029 rq170_1 rq170_2 rq170_3 rr002 ///
    sr050 sr055 sr063 sr064 sr072 sr073 sr030 sr035 sr045 sq171_1 sq171_2 sq171_3 sr007 sr013 sr024 sr049 sr061 sr062 sr028 sr029 sq170_1 sq170_2 sq170_3 sr002

* Normalise flow/flag names to lowercase (fat files or merge may leave uppercase, e.g. HR050)
foreach v of local fatvars {
    capture confirm variable `v'
    if _rc {
        local vup = upper("`v'")
        capture confirm variable `vup'
        if !_rc rename `vup' `v'
    }
}

foreach v of local fatvars {
    capture confirm variable `v'
    if !_rc {
        capture confirm numeric variable `v'
        if !_rc {
            replace `v' = . if inlist(`v', -9, -8, 8, 9, 98, 99, 9998, 9999, 999998, 999999, 9999998, 9999999, 99999998, 99999999)
        }
    }
}

forvalues i = 1/11 {
    local w : word `i' of `waves'
    local y : word `i' of `years'

    * (2) If No (5) to flag, set flow to 0 when missing
    capture confirm variable `w'r049
    if !_rc {
        quietly replace `w'r050 = 0 if `w'r049 == 5 & missing(`w'r050)
        quietly replace `w'r055 = 0 if `w'r049 == 5 & missing(`w'r055)
    }
    * Private stock: flags *R061 (buy), *R062 (sell). Set flow to 0 when flow missing and: one flag No (5) and other missing, or both No (skip-pattern interpretation).
    capture confirm variable `w'r061
    if !_rc {
        capture confirm variable `w'r062
        if !_rc {
            quietly replace `w'r064 = 0 if ((`w'r061 == 5 & missing(`w'r062)) | (`w'r062 == 5 & missing(`w'r061)) | (`w'r061 == 5 & `w'r062 == 5)) & missing(`w'r064)
            quietly replace `w'r063 = 3  if ((`w'r061 == 5 & missing(`w'r062)) | (`w'r062 == 5 & missing(`w'r061)) | (`w'r061 == 5 & `w'r062 == 5)) & missing(`w'r063)
        }
    }
    * Public stock: flag *R072; amount *R073 (all waves h-s). When 5, set public amount to 0 when missing.
    if "`w'" == "s" {
        capture confirm variable sr072
        if !_rc quietly replace sr073 = 0 if sr072 == 5 & missing(sr073)
    }
    else {
        * For h-r, *R072 is flag; amount is *R073.
    }
    capture confirm variable `w'r028
    if !_rc {
        capture confirm variable `w'r029
        if !_rc {
            quietly replace `w'r030 = 0 if `w'r028 == 5 & `w'r029 == 5 & missing(`w'r030)
            quietly replace `w'r035 = 0 if `w'r028 == 5 & `w'r029 == 5 & missing(`w'r035)
            quietly replace `w'r045 = 0 if `w'r028 == 5 & `w'r029 == 5 & missing(`w'r045)
        }
    }
    capture confirm variable `w'q170_1
    if !_rc {
        quietly replace `w'q171_1 = 0 if `w'q170_1 == 5 & missing(`w'q171_1)
        quietly replace `w'q171_2 = 0 if `w'q170_2 == 5 & missing(`w'q171_2)
        quietly replace `w'q171_3 = 0 if `w'q170_3 == 5 & missing(`w'q171_3)
    }
    capture confirm variable `w'r002
    if !_rc {
        quietly replace `w'r007 = 0 if `w'r002 == 5 & missing(`w'r007)
        quietly replace `w'r013 = 0 if `w'r002 == 5 & missing(`w'r013)
        quietly replace `w'r024 = 0 if `w'r002 == 5 & missing(`w'r024)
    }

    * (3) Construct flow_*_YYYY (new variable names)
    * flow_bus_YYYY
    capture drop flow_bus_`y'
    gen double flow_bus_`y' = .
    capture confirm variable `w'r050
    if !_rc {
        capture confirm variable `w'r055
        if !_rc {
            replace flow_bus_`y' = `w'r055 - `w'r050 if !missing(`w'r055) & !missing(`w'r050)
            replace flow_bus_`y' = `w'r055 if missing(`w'r050) & !missing(`w'r055)
            replace flow_bus_`y' = -`w'r050 if !missing(`w'r050) & missing(`w'r055)
        }
    }

    * flow_stk_private_YYYY: direction * magnitude (*R063 1=-1, 2=1, 3=0; *R064 magnitude). Flags R061 and R062.
    * flow_stk_public_YYYY: public stock amount (all waves use *R073). Flag *R072.
    * flow_stk_YYYY = flow_stk_private + flow_stk_public (missing when both missing).
    capture drop flow_stk_private_`y' flow_stk_public_`y' flow_stk_`y'
    gen double flow_stk_private_`y' = .
    gen double flow_stk_public_`y' = .
    gen double flow_stk_`y' = .
    capture confirm variable `w'r063
    if !_rc {
        capture confirm variable `w'r064
        if !_rc {
            capture drop _dir_`y'
            gen byte _dir_`y' = .
            replace _dir_`y' = -1 if `w'r063 == 1
            replace _dir_`y' =  1 if `w'r063 == 2
            replace _dir_`y' =  0 if `w'r063 == 3
            replace flow_stk_private_`y' = _dir_`y' * `w'r064 if !missing(_dir_`y') & !missing(`w'r064)
            capture drop _dir_`y'
        }
    }
    * Public: flag *R072. When *R072==5 flow_public=0; else flow_public=*R073 (all waves).
    capture confirm variable `w'r072
    if !_rc {
        capture confirm variable `w'r073
        if !_rc {
            replace flow_stk_public_`y' = 0 if `w'r072 == 5
            replace flow_stk_public_`y' = `w'r073 if `w'r072 != 5 & !missing(`w'r073)
        }
    }
    * Combine: flow_stk = private + public; missing when both missing
    replace flow_stk_`y' = cond(missing(flow_stk_private_`y'),0,flow_stk_private_`y') + cond(missing(flow_stk_public_`y'),0,flow_stk_public_`y') if !missing(flow_stk_private_`y') | !missing(flow_stk_public_`y')
    replace flow_stk_`y' = . if missing(flow_stk_private_`y') & missing(flow_stk_public_`y')

    * flow_re_YYYY
    capture drop flow_re_`y'
    gen double flow_re_`y' = .
    capture confirm variable `w'r035
    if !_rc {
        replace flow_re_`y' = cond(missing(`w'r035),0,`w'r035) - (cond(missing(`w'r030),0,`w'r030) + cond(missing(`w'r045),0,`w'r045)) if !missing(`w'r035) | !missing(`w'r030) | !missing(`w'r045)
    }

    * flow_ira_YYYY
    capture drop flow_ira_`y'
    gen double flow_ira_`y' = .
    capture confirm variable `w'q171_1
    if !_rc {
        egen double _ira_`y' = rowtotal(`w'q171_1 `w'q171_2 `w'q171_3), missing
        replace flow_ira_`y' = _ira_`y'
        replace flow_ira_`y' = . if missing(`w'q171_1) & missing(`w'q171_2) & missing(`w'q171_3)
        drop _ira_`y'
    }

    * flow_residences_YYYY
    capture drop flow_residences_`y'
    gen double flow_residences_`y' = .
    capture confirm variable `w'r013
    if !_rc {
        replace flow_residences_`y' = cond(missing(`w'r013),0,`w'r013) - (cond(missing(`w'r007),0,`w'r007) + cond(missing(`w'r024),0,`w'r024)) if !missing(`w'r013) | !missing(`w'r007) | !missing(`w'r024)
        replace flow_residences_`y' = . if missing(`w'r013) & missing(`w'r007) & missing(`w'r024)
    }

    * Flow aggregates by scope (all waves)
    capture drop flow_core_`y' flow_res_`y' flow_total_`y'
    gen double flow_core_`y' = flow_bus_`y' + flow_re_`y' + flow_stk_`y'
    * flow_ira_`y' is defined above from q171_* (use as IRA-only scope)
    gen double flow_res_`y' = flow_residences_`y'
    gen double flow_total_`y' = flow_core_`y' + flow_ira_`y' + flow_res_`y'
}

save "${CLEANED}/all_data_merged.dta", replace
display "02_process_flows: Saved " _N " obs to ${CLEANED}/all_data_merged.dta"
