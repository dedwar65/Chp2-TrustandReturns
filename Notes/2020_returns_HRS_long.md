## Using the Longitudinal file

# 1. Computing returns for 2020 

* F_t net investment flows per asset class (that are available for 2020)
    * private business: RR050 (invest), RR055 (sell)
    * stocks: RR063 (net buyer or net seller), RR064 (magnitude)
        * public stocks: RR072 (sold)
    * real estate: RR030 (buy), QR035 (sold), RR045 (improvement costs)
    * IRA: RQ171_1, RQ171_2, QR171_3
    * primary/secondary residence(s): RR007 (buy), RR013 (sell), RR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2018 / H14)
   - H14ATOTB   (Total of all assets net of debt, Wave 14 = 2018)
   - alternative (exclude IRAs): H14ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2020 / H15)
   - H15ICAP    (Household capital income, Wave 15 = 2020)

C) Asset values for capital gains (use H15 - H14 by class; compute cg_class = V_2020 - V_2018)
   - Primary residence (net):
       H15ATOTH   (Primary residence net value, 2020)
       H14ATOTH   (Primary residence net value, 2018)
   - Secondary residence (net):
       H15ANETHB  (Secondary residence net value, 2020)
       H14ANETHB  (Secondary residence net value, 2018)
   - Other real estate:
       H15ARLES   (Other real estate, 2020)
       H14ARLES   (Other real estate, 2018)
   - Private business:
       H15ABSNS   (Private business, 2020)
       H14ABSNS   (Private business, 2018)
   - IRA / Keogh:
       H15AIRA    (IRA/Keogh, 2020)
       H14AIRA    (IRA/Keogh, 2018)
   - Stocks / mutual funds:
       H15ASTCK   (Stocks/mutual funds, 2020)
       H14ASTCK   (Stocks/mutual funds, 2018)
   - Bonds:
       H15ABOND   (Bonds, 2020)
       H14ABOND   (Bonds, 2018)
   - Checking / savings / money market:
       H15ACHCK   (Checking/savings, 2020)
       H14ACHCK   (Checking/savings, 2018)
   - CDs / T-bills:
       H15ACD     (CDs/T-bills, 2020)
       H14ACD     (CDs/T-bills, 2018)
   - Vehicles:
       H15ATRAN   (Vehicles, 2020)
       H14ATRAN   (Vehicles, 2018)
   - Other assets:
       H15AOTHR   (Other assets, 2020)
       H14AOTHR   (Other assets, 2018)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H15AMORT   (All mortgages on primary residence, 2020)
       H14AMORT   (All mortgages on primary residence, 2018)
       H15AMRTB   (Mortgage on 2nd home, 2020)
       H14AMRTB   (Mortgage on 2nd home, 2018)
       H15AHMLN   (Other home loans, 2020)
       H14AHMLN   (Other home loans, 2018)
       H15ADEBT   (Total other debt, 2020)
       H14ADEBT   (Total other debt, 2018)

CG formula (per class):
   cg_class = (V_2020_class - V_2018_class)

Overall period numerator and annualization:
   num_period = y^c_2020 + sum_c(cg_class) - F_total_period - debt_payments_2020
   base = A_{2018} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r14agey_b
* education: raedyrs
* employment: r14inlbrf
* marital status: r14mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r15earn, r15pena, r15issdi, r15isret, r15iunwc, r15igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564
