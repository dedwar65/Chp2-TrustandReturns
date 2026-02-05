## Using the Longitudinal file

# 1. Computing returns for 2004

* F_t net investment flows per asset class (that are available for 2004)
    * private business: JR050 (invest), JR055 (sell)
    * stocks: JR063 (net buyer or net seller), JR064 (magnitude)
        * public stocks: JR072 (sold)
    * real estate: JR030 (buy), JR035 (sold), JR045 (improvement costs)
    * IRA: JQ171_1, JQ171_2, JQ171_3
    * primary/secondary residence(s): JR007 (buy), JR013 (sell), JR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2002 / H6)
   - H6ATOTB   (Total of all assets net of debt, Wave 6 = 2002)
   - alternative (exclude IRAs): H6ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2004 / H7)
   - H7ICAP    (Household capital income, Wave 7 = 2004)

C) Asset values for capital gains (use H7 - H6 by class; compute cg_class = V_2004 - V_2002)
   - Primary residence (net):
       H7ATOTH   (Primary residence net value, 2004)
       H6ATOTH   (Primary residence net value, 2002)
   - Secondary residence (net):
       H7ANETHB  (Secondary residence net value, 2004)
       H6ANETHB  (Secondary residence net value, 2002)
   - Other real estate:
       H7ARLES   (Other real estate, 2004)
       H6ARLES   (Other real estate, 2002)
   - Private business:
       H7ABSNS   (Private business, 2004)
       H6ABSNS   (Private business, 2002)
   - IRA / Keogh:
       H7AIRA    (IRA/Keogh, 2004)
       H6AIRA    (IRA/Keogh, 2002)
   - Stocks / mutual funds:
       H7ASTCK   (Stocks/mutual funds, 2004)
       H6ASTCK   (Stocks/mutual funds, 2002)
   - Bonds:
       H7ABOND   (Bonds, 2004)
       H6ABOND   (Bonds, 2002)
   - Checking / savings / money market:
       H7ACHCK   (Checking/savings, 2004)
       H6ACHCK   (Checking/savings, 2002)
   - CDs / T-bills:
       H7ACD     (CDs/T-bills, 2004)
       H6ACD     (CDs/T-bills, 2002)
   - Vehicles:
       H7ATRAN   (Vehicles, 2004)
       H6ATRAN   (Vehicles, 2002)
   - Other assets:
       H7AOTHR   (Other assets, 2004)
       H6AOTHR   (Other assets, 2002)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H7AMORT   (All mortgages on primary residence, 2004)
       H6AMORT   (All mortgages on primary residence, 2002)
       H7AMRTB   (Mortgage on 2nd home, 2004)
       H6AMRTB   (Mortgage on 2nd home, 2002)
       H7AHMLN   (Other home loans, 2004)
       H6AHMLN   (Other home loans, 2002)
       H7ADEBT   (Total other debt, 2004)
       H6ADEBT   (Total other debt, 2002)

CG formula (per class):
   cg_class = (V_2004_class - V_2002_class)

Overall period numerator and annualization:
   num_period = y^c_2004 + sum_c(cg_class) - F_total_period - debt_payments_2004
   base = A_{2002} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r6agey_b
* education: raedyrs
* employment: r6inlbrf
* marital status: r6mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564