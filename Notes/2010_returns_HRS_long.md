## Using the Longitudinal file

# 1. Computing returns for 2010

* F_t net investment flows per asset class (that are available for 2010)
    * private business: MR050 (invest), MR055 (sell)
    * stocks: MR063 (net buyer or net seller), MR064 (magnitude)
        * public stocks: MR072 (sold)
    * real estate: MR030 (buy), MR035 (sold), MR045 (improvement costs)
    * IRA: MQ171_1, MQ171_2, MQ171_3
    * primary/secondary residence(s): MR007 (buy), MR013 (sell), MR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2008 / H9)
   - H9ATOTB   (Total of all assets net of debt, Wave 9 = 2008)
   - alternative (exclude IRAs): H9ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2010 / H10)
   - H10ICAP    (Household capital income, Wave 10 = 2010)

C) Asset values for capital gains (use H10 - H9 by class; compute cg_class = V_2010 - V_2008)
   - Primary residence (net):
       H10ATOTH   (Primary residence net value, 2010)
       H9ATOTH   (Primary residence net value, 2008)
   - Secondary residence (net):
       H10ANETHB  (Secondary residence net value, 2010)
       H9ANETHB  (Secondary residence net value, 2008)
   - Other real estate:
       H10ARLES   (Other real estate, 2010)
       H9ARLES   (Other real estate, 2008)
   - Private business:
       H10ABSNS   (Private business, 2010)
       H9ABSNS   (Private business, 2008)
   - IRA / Keogh:
       H10AIRA    (IRA/Keogh, 2010)
       H9AIRA    (IRA/Keogh, 2008)
   - Stocks / mutual funds:
       H10ASTCK   (Stocks/mutual funds, 2010)
       H9ASTCK   (Stocks/mutual funds, 2008)
   - Bonds:
       H10ABOND   (Bonds, 2010)
       H9ABOND   (Bonds, 2008)
   - Checking / savings / money market:
       H10ACHCK   (Checking/savings, 2010)
       H9ACHCK   (Checking/savings, 2008)
   - CDs / T-bills:
       H10ACD     (CDs/T-bills, 2010)
       H9ACD     (CDs/T-bills, 2008)
   - Vehicles:
       H10ATRAN   (Vehicles, 2010)
       H9ATRAN   (Vehicles, 2008)
   - Other assets:
       H10AOTHR   (Other assets, 2010)
       H9AOTHR   (Other assets, 2008)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H10AMORT   (All mortgages on primary residence, 2010)
       H9AMORT   (All mortgages on primary residence, 2008)
       H10AMRTB   (Mortgage on 2nd home, 2010)
       H9AMRTB   (Mortgage on 2nd home, 2008)
       H10AHMLN   (Other home loans, 2010)
       H9AHMLN   (Other home loans, 2008)
       H10ADEBT   (Total other debt, 2010)
       H9ADEBT   (Total other debt, 2008)

CG formula (per class):
   cg_class = (V_2010_class - V_2008_class)

Overall period numerator and annualization:
   num_period = y^c_2010 + sum_c(cg_class) - F_total_period - debt_payments_2010
   base = A_{2008} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r9agey_b
* education: raedyrs
* employment: r9inlbrf
* marital status: r9mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564