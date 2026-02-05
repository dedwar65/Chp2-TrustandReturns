## Using the Longitudinal file

# 1. Computing returns for 2008

* F_t net investment flows per asset class (that are available for 2008)
    * private business: LR050 (invest), LR055 (sell)
    * stocks: LR063 (net buyer or net seller), LR064 (magnitude)
        * public stocks: LR072 (sold)
    * real estate: LR030 (buy), LR035 (sold), LR045 (improvement costs)
    * IRA: LQ171_1, LQ171_2, LQ171_3
    * primary/secondary residence(s): LR007 (buy), LR013 (sell), LR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2006 / H8)
   - H8ATOTB   (Total of all assets net of debt, Wave 8 = 2006)
   - alternative (exclude IRAs): H8ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2008 / H9)
   - H9ICAP    (Household capital income, Wave 9 = 2008)

C) Asset values for capital gains (use H9 - H8 by class; compute cg_class = V_2008 - V_2006)
   - Primary residence (net):
       H9ATOTH   (Primary residence net value, 2008)
       H8ATOTH   (Primary residence net value, 2006)
   - Secondary residence (net):
       H9ANETHB  (Secondary residence net value, 2008)
       H8ANETHB  (Secondary residence net value, 2006)
   - Other real estate:
       H9ARLES   (Other real estate, 2008)
       H8ARLES   (Other real estate, 2006)
   - Private business:
       H9ABSNS   (Private business, 2008)
       H8ABSNS   (Private business, 2006)
   - IRA / Keogh:
       H9AIRA    (IRA/Keogh, 2008)
       H8AIRA    (IRA/Keogh, 2006)
   - Stocks / mutual funds:
       H9ASTCK   (Stocks/mutual funds, 2008)
       H8ASTCK   (Stocks/mutual funds, 2006)
   - Bonds:
       H9ABOND   (Bonds, 2008)
       H8ABOND   (Bonds, 2006)
   - Checking / savings / money market:
       H9ACHCK   (Checking/savings, 2008)
       H8ACHCK   (Checking/savings, 2006)
   - CDs / T-bills:
       H9ACD     (CDs/T-bills, 2008)
       H8ACD     (CDs/T-bills, 2006)
   - Vehicles:
       H9ATRAN   (Vehicles, 2008)
       H8ATRAN   (Vehicles, 2006)
   - Other assets:
       H9AOTHR   (Other assets, 2008)
       H8AOTHR   (Other assets, 2006)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H9AMORT   (All mortgages on primary residence, 2008)
       H8AMORT   (All mortgages on primary residence, 2006)
       H9AMRTB   (Mortgage on 2nd home, 2008)
       H8AMRTB   (Mortgage on 2nd home, 2006)
       H9AHMLN   (Other home loans, 2008)
       H8AHMLN   (Other home loans, 2006)
       H9ADEBT   (Total other debt, 2008)
       H8ADEBT   (Total other debt, 2006)

CG formula (per class):
   cg_class = (V_2008_class - V_2006_class)

Overall period numerator and annualization:
   num_period = y^c_2008 + sum_c(cg_class) - F_total_period - debt_payments_2008
   base = A_{2006} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r8agey_b
* education: raedyrs
* employment: r8inlbrf
* marital status: r8mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564