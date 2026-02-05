## Using the Longitudinal file

# 1. Computing returns for 2016

* F_t net investment flows per asset class (that are available for 2022)
    * private business: PR050 (invest), PR055 (sell)
    * stocks: PR063 (net buyer or net seller), PR064 (magnitude)
        * public stocks: PR072 (sold)
    * real estate: PR030 (buy), PR035 (sold), PR045 (improvement costs)
    * IRA: PQ171_1, PQ171_2, PQ171_3
    * primary/secondary residence(s): PR007 (buy), PR013 (sell), PR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2014 / H12)
   - H12ATOTB   (Total of all assets net of debt, Wave 12 = 2014)
   - alternative (exclude IRAs): H12ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2016 / H13)
   - H13ICAP    (Household capital income, Wave 15 = 2016)

C) Asset values for capital gains (use H13 - H12 by class; compute cg_class = V_2016 - V_2014)
   - Primary residence (net):
       H13ATOTH   (Primary residence net value, 2016)
       H12ATOTH   (Primary residence net value, 2014)
   - Secondary residence (net):
       H13ANETHB  (Secondary residence net value, 2016)
       H12ANETHB  (Secondary residence net value, 2014)
   - Other real estate:
       H13ARLES   (Other real estate, 2016)
       H12ARLES   (Other real estate, 2014)
   - Private business:
       H13ABSNS   (Private business, 2016)
       H12ABSNS   (Private business, 2014)
   - IRA / Keogh:
       H13AIRA    (IRA/Keogh, 2016)
       H12AIRA    (IRA/Keogh, 2014)
   - Stocks / mutual funds:
       H13ASTCK   (Stocks/mutual funds, 2016)
       H12ASTCK   (Stocks/mutual funds, 2014)
   - Bonds:
       H13ABOND   (Bonds, 2016)
       H12ABOND   (Bonds, 2014)
   - Checking / savings / money market:
       H13ACHCK   (Checking/savings, 2016)
       H12ACHCK   (Checking/savings, 2014)
   - CDs / T-bills:
       H13ACD     (CDs/T-bills, 2016)
       H12ACD     (CDs/T-bills, 2014)
   - Vehicles:
       H13ATRAN   (Vehicles, 2016)
       H12ATRAN   (Vehicles, 2014)
   - Other assets:
       H13AOTHR   (Other assets, 2016)
       H12AOTHR   (Other assets, 2014)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H13AMORT   (All mortgages on primary residence, 2016)
       H12AMORT   (All mortgages on primary residence, 2014)
       H13AMRTB   (Mortgage on 2nd home, 2016)
       H12AMRTB   (Mortgage on 2nd home, 2014)
       H13AHMLN   (Other home loans, 2016)
       H12AHMLN   (Other home loans, 2014)
       H13ADEBT   (Total other debt, 2016)
       H12ADEBT   (Total other debt, 2014)

CG formula (per class):
   cg_class = (V_2016_class - V_2014_class)

Overall period numerator and annualization:
   num_period = y^c_2016 + sum_c(cg_class) - F_total_period - debt_payments_2016
   base = A_{2014} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r12agey_b
* education: raedyrs
* employment: r12inlbrf
* marital status: r12mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564