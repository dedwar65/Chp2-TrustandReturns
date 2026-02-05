## Using the Longitudinal file

# 1. Computing returns for 2006

* F_t net investment flows per asset class (that are available for 2006)
    * private business: KR050 (invest), KR055 (sell)
    * stocks: KR063 (net buyer or net seller), KR064 (magnitude)
        * public stocks: KR072 (sold)
    * real estate: KR030 (buy), KR035 (sold), KR045 (improvement costs)
    * IRA: KQ171_1, KQ171_2, KQ171_3
    * primary/secondary residence(s): KR007 (buy), KR013 (sell), KR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2004 / H7)
   - H7ATOTB   (Total of all assets net of debt, Wave 7 = 2004)
   - alternative (exclude IRAs): H7ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2006 / H8)
   - H8ICAP    (Household capital income, Wave 8 = 2006)

C) Asset values for capital gains (use H8 - H7 by class; compute cg_class = V_2006 - V_2004)
   - Primary residence (net):
       H8ATOTH   (Primary residence net value, 2006)
       H7ATOTH   (Primary residence net value, 2004)
   - Secondary residence (net):
       H8ANETHB  (Secondary residence net value, 2006)
       H7ANETHB  (Secondary residence net value, 2004)
   - Other real estate:
       H8ARLES   (Other real estate, 2006)
       H7ARLES   (Other real estate, 2004)
   - Private business:
       H8ABSNS   (Private business, 2006)
       H7ABSNS   (Private business, 2004)
   - IRA / Keogh:
       H8AIRA    (IRA/Keogh, 2006)
       H7AIRA    (IRA/Keogh, 2004)
   - Stocks / mutual funds:
       H8ASTCK   (Stocks/mutual funds, 2006)
       H7ASTCK   (Stocks/mutual funds, 2004)
   - Bonds:
       H8ABOND   (Bonds, 2006)
       H7ABOND   (Bonds, 2004)
   - Checking / savings / money market:
       H8ACHCK   (Checking/savings, 2006)
       H7ACHCK   (Checking/savings, 2004)
   - CDs / T-bills:
       H8ACD     (CDs/T-bills, 2006)
       H7ACD     (CDs/T-bills, 2004)
   - Vehicles:
       H8ATRAN   (Vehicles, 2006)
       H7ATRAN   (Vehicles, 2004)
   - Other assets:
       H8AOTHR   (Other assets, 2006)
       H7AOTHR   (Other assets, 2004)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H8AMORT   (All mortgages on primary residence, 2006)
       H7AMORT   (All mortgages on primary residence, 2004)
       H8AMRTB   (Mortgage on 2nd home, 2006)
       H7AMRTB   (Mortgage on 2nd home, 2004)
       H8AHMLN   (Other home loans, 2006)
       H7AHMLN   (Other home loans, 2004)
       H8ADEBT   (Total other debt, 2006)
       H7ADEBT   (Total other debt, 2004)

CG formula (per class):
   cg_class = (V_2006_class - V_2004_class)

Overall period numerator and annualization:
   num_period = y^c_2006 + sum_c(cg_class) - F_total_period - debt_payments_2006
   base = A_{2004} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r7agey_b
* education: raedyrs
* employment: r7inlbrf
* marital status: r7mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564