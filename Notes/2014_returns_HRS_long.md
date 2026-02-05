## Using the Longitudinal file

# 1. Computing returns for 2014

* F_t net investment flows per asset class (that are available for 2014)
    * private business: OR050 (invest), OR055 (sell)
    * stocks: OR063 (net buyer or net seller), OR064 (magnitude)
        * public stocks: OR072 (sold)
    * real estate: OR030 (buy), OR035 (sold), OR045 (improvement costs)
    * IRA: OQ171_1, OQ171_2, OQ171_3
    * primary/secondary residence(s): OR007 (buy), OR013 (sell), OR024 (improvement costs)

A) Denominator — A_{t-1} (total net wealth at start of period, use 2012 / H11)
   - H11ATOTB   (Total of all assets net of debt, Wave 11 = 2012)
   - alternative (exclude IRAs): H11ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2014 / H12)
   - H12ICAP    (Household capital income, Wave 12 = 2014)

C) Asset values for capital gains (use H12 - H11 by class; compute cg_class = V_2014 - V_2012)
   - Primary residence (net):
       H12ATOTH   (Primary residence net value, 2014)
       H11ATOTH   (Primary residence net value, 2012)
   - Secondary residence (net):
       H12ANETHB  (Secondary residence net value, 2014)
       H11ANETHB  (Secondary residence net value, 2012)
   - Other real estate:
       H12ARLES   (Other real estate, 2014)
       H11ARLES   (Other real estate, 2012)
   - Private business:
       H12ABSNS   (Private business, 2014)
       H11ABSNS   (Private business, 2012)
   - IRA / Keogh:
       H12AIRA    (IRA/Keogh, 2014)
       H11AIRA    (IRA/Keogh, 2012)
   - Stocks / mutual funds:
       H12ASTCK   (Stocks/mutual funds, 2014)
       H11ASTCK   (Stocks/mutual funds, 2012)
   - Bonds:
       H12ABOND   (Bonds, 2014)
       H11ABOND   (Bonds, 2012)
   - Checking / savings / money market:
       H12ACHCK   (Checking/savings, 2014)
       H11ACHCK   (Checking/savings, 2012)
   - CDs / T-bills:
       H12ACD     (CDs/T-bills, 2014)
       H11ACD     (CDs/T-bills, 2012)
   - Vehicles:
       H12ATRAN   (Vehicles, 2014)
       H11ATRAN   (Vehicles, 2012)
   - Other assets:
       H12AOTHR   (Other assets, 2014)
       H11AOTHR   (Other assets, 2012)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H12AMORT   (All mortgages on primary residence, 2014)
       H11AMORT   (All mortgages on primary residence, 2012)
       H12AMRTB   (Mortgage on 2nd home, 2014)
       H11AMRTB   (Mortgage on 2nd home, 2012)
       H12AHMLN   (Other home loans, 2014)
       H11AHMLN   (Other home loans, 2012)
       H12ADEBT   (Total other debt, 2014)
       H11ADEBT   (Total other debt, 2012)

CG formula (per class):
   cg_class = (V_2014_class - V_2012_class)

Overall period numerator and annualization:
   num_period = y^c_2014 + sum_c(cg_class) - F_total_period - debt_payments_2014
   base = A_{2012} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r11agey_b
* education: raedyrs
* employment: r11inlbrf
* marital status: r11mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14earn, r14pena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564