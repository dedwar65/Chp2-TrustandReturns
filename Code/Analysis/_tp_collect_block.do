* _tp_collect_block.do
* Collect turning-point from last regression. Args: file_id (35|37), model_name.
* Call: do _tp_collect_block.do 35 avg_returns
* Requires: postfile tpH open with vars (str2 file_id str12 model_name double N b1 b2 tp tp_se tp_p tp_lb tp_ub t_min t_max byte both_sig)

local file_id "`1'"
local model_name "`2'"
capture confirm matrix e(b)
if _rc exit 0
local b1 .
local b2 .
capture local b1 = _b[c.trust_others_2020]
if _rc capture local b1 = _b[trust_others_2020]
capture local b2 = _b[c.trust_others_2020#c.trust_others_2020]
if _rc capture local b2 = _b[trust_others_2020_sq]
if (`b1' >= . | `b2' >= .) exit 0
quietly test c.trust_others_2020 = 0
if _rc quietly test trust_others_2020 = 0
local p1 = r(p)
quietly test c.trust_others_2020#c.trust_others_2020 = 0
if _rc quietly test trust_others_2020_sq = 0
local p2 = r(p)
local both_sig = (`p1' < 0.10 & `p2' < 0.10)
quietly summarize trust_others_2020 if e(sample), meanonly
local tmin = r(min)
local tmax = r(max)
local tp .
local tp_se .
local tp_p .
local tp_lb .
local tp_ub .
capture {
    nlcom (tp: -_b[c.trust_others_2020]/(2*_b[c.trust_others_2020#c.trust_others_2020]))
    if _rc == 0 {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
}
if `tp' >= . {
    capture nlcom (tp: -_b[trust_others_2020]/(2*_b[trust_others_2020_sq]))
    if _rc == 0 {
        matrix T = r(table)
        local tp    = T[1,1]
        local tp_se = T[2,1]
        local tp_p  = T[4,1]
        local tp_lb = T[5,1]
        local tp_ub = T[6,1]
    }
}
post tpH ("`file_id'") ("`model_name'") (e(N)) (`b1') (`b2') (`tp') (`tp_se') (`tp_p') (`tp_lb') (`tp_ub') (`tmin') (`tmax') (`both_sig')
