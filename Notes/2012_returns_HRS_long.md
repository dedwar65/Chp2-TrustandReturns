## Using the Longitudinal file

# 1. Computing returns for 2012

* F_t net investment flows per asset class (that are available for 2012)
    * private business: NR050 (invest), NR055 (sell)
    * stocks: NR063 (net buyer or net seller), NR064 (magnitude)
        * public stocks: NR072 (sold)
    * real estate: NR030 (buy), NR035 (sold), NR045 (improvement costs)
    * IRA: NQ171_1, NQ171_2, NQ171_3
    * primary/secondary residence(s): NR007 (buy), NR013 (sell), NR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2010 / H10)
   - H10ATOTB   (Total of all assets net of debt, Wave 10 = 2010)
   - alternative (exclude IRAs): H10ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2012 / H11)
   - H11ICAP    (Household capital income, Wave 11 = 2012)

C) Asset values for capital gains (use H11 - H10 by class; compute cg_class = V_2012 - V_2010)
   - Primary residence (net):
       H11ATOTH   (Primary residence net value, 2012)
       H10ATOTH   (Primary residence net value, 2010)
   - Secondary residence (net):
       H11ANETHB  (Secondary residence net value, 2012)
       H10ANETHB  (Secondary residence net value, 2010)
   - Other real estate:
       H11ARLES   (Other real estate, 2012)
       H10ARLES   (Other real estate, 2010)
   - Private business:
       H11ABSNS   (Private business, 2012)
       H10ABSNS   (Private business, 2010)
   - IRA / Keogh:
       H11AIRA    (IRA/Keogh, 2012)
       H10AIRA    (IRA/Keogh, 2010)
   - Stocks / mutual funds:
       H11ASTCK   (Stocks/mutual funds, 2012)
       H10ASTCK   (Stocks/mutual funds, 2010)
   - Bonds:
       H11ABOND   (Bonds, 2012)
       H10ABOND   (Bonds, 2010)
   - Checking / savings / money market:
       H11ACHCK   (Checking/savings, 2012)
       H10ACHCK   (Checking/savings, 2010)
   - CDs / T-bills:
       H11ACD     (CDs/T-bills, 2012)
       H10ACD     (CDs/T-bills, 2010)
   - Vehicles:
       H11ATRAN   (Vehicles, 2012)
       H10ATRAN   (Vehicles, 2010)
   - Other assets:
       H11AOTHR   (Other assets, 2012)
       H10AOTHR   (Other assets, 2010)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H11AMORT   (All mortgages on primary residence, 2012)
       H10AMORT   (All mortgages on primary residence, 2010)
       H11AMRTB   (Mortgage on 2nd home, 2012)
       H10AMRTB   (Mortgage on 2nd home, 2010)
       H11AHMLN   (Other home loans, 2012)
       H10AHMLN   (Other home loans, 2010)
       H11ADEBT   (Total other debt, 2012)
       H10ADEBT   (Total other debt, 2010)

CG formula (per class):
   cg_class = (V_2012_class - V_2010_class)

Overall period numerator and annualization:
   num_period = y^c_2012 + sum_c(cg_class) - F_total_period - debt_payments_2012
   base = A_{2010} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r10agey_b
* education: raedyrs
* employment: r10inlbrf
* marital status: r10mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564