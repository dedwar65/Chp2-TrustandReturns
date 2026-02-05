## Using the Longitudinal file

# 1. Computing returns for 2018

* F_t net investment flows per asset class (that are available for 2022)
    * private business: QR050 (invest), QR055 (sell)
    * stocks: QR063 (net buyer or net seller), QR064 (magnitude)
        * public stocks: QR072 (sold)
    * real estate: QR030 (buy), QR035 (sold), QR045 (improvement costs)
    * IRA: QQ171_1, QQ171_2, QQ171_3
    * primary/secondary residence(s): qR007 (buy), qR013 (sell), qR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2016 / H13)
   - H13ATOTB   (Total of all assets net of debt, Wave 13 = 2016)
   - alternative (exclude IRAs): H13ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2018 / H14)
   - H14ICAP    (Household capital income, Wave 15 = 2018)

C) Asset values for capital gains (use H14 - H13 by class; compute cg_class = V_2018 - V_2016)
   - Primary residence (net):
       H14ATOTH   (Primary residence net value, 2018)
       H13ATOTH   (Primary residence net value, 2016)
   - Secondary residence (net):
       H14ANETHB  (Secondary residence net value, 2018)
       H13ANETHB  (Secondary residence net value, 2016)
   - Other real estate:
       H14ARLES   (Other real estate, 2018)
       H13ARLES   (Other real estate, 2016)
   - Private business:
       H14ABSNS   (Private business, 2018)
       H13ABSNS   (Private business, 2016)
   - IRA / Keogh:
       H14AIRA    (IRA/Keogh, 2018)
       H13AIRA    (IRA/Keogh, 2016)
   - Stocks / mutual funds:
       H14ASTCK   (Stocks/mutual funds, 2018)
       H13ASTCK   (Stocks/mutual funds, 2016)
   - Bonds:
       H14ABOND   (Bonds, 2018)
       H13ABOND   (Bonds, 2016)
   - Checking / savings / money market:
       H14ACHCK   (Checking/savings, 2018)
       H13ACHCK   (Checking/savings, 2016)
   - CDs / T-bills:
       H14ACD     (CDs/T-bills, 2018)
       H13ACD     (CDs/T-bills, 2016)
   - Vehicles:
       H14ATRAN   (Vehicles, 2018)
       H13ATRAN   (Vehicles, 2016)
   - Other assets:
       H14AOTHR   (Other assets, 2018)
       H13AOTHR   (Other assets, 2016)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H14AMORT   (All mortgages on primary residence, 2018)
       H13AMORT   (All mortgages on primary residence, 2016)
       H14AMRTB   (Mortgage on 2nd home, 2018)
       H13AMRTB   (Mortgage on 2nd home, 2016)
       H14AHMLN   (Other home loans, 2018)
       H13AHMLN   (Other home loans, 2016)
       H14ADEBT   (Total other debt, 2018)
       H13ADEBT   (Total other debt, 2016)

CG formula (per class):
   cg_class = (V_2018_class - V_2016_class)

Overall period numerator and annualization:
   num_period = y^c_2018 + sum_c(cg_class) - F_total_period - debt_payments_2018
   base = A_{2016} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r13agey_b
* education: raedyrs
* employment: r13inlbrf
* marital status: r13mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564