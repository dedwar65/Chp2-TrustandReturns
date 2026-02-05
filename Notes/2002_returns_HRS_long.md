## Using the Longitudinal file

# 1. Computing returns for 2002

* F_t net investment flows per asset class (that are available for 2002)
    * private business: HR050 (invest), HR055 (sell)
    * stocks: HR063 (net buyer or net seller), HR064 (magnitude)
        * public stocks: HR073 (sold)
    * real estate: HR030 (buy), HR035 (sold), HR045 (improvement costs)
    * IRA: HQ171_1, HQ171_2, HQ171_3
    * primary/secondary residence(s): HR007 (buy), HR013 (sell), HR024 (improvement costs)

    * private business: HR049
    * stocks: HR061 (buy) HR062 (sell)
    * real estate: HR029 (bought) HR028 (sell)
    * IRA: HQ170_1, HQ170_2, HQ170_3
    * primary/secondary residence: HR002 

A) Denominator — A_{t-1} (total net wealth at start of period, use 2000 / H5)
   - H5ATOTB   (Total of all assets net of debt, Wave 5 = 2000)
   - alternative (exclude IRAs): H5ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2002 / H6)
   - H6ICAP    (Household capital income, Wave 6 = 2002)

C) Asset values for capital gains (use H6 - H5 by class; compute cg_class = V_2002 - V_2000)
   - Primary residence (net):
       H6ATOTH   (Primary residence net value, 2002)
       H5ATOTH   (Primary residence net value, 2000)
   - Secondary residence (net):
       H6ANETHB  (Secondary residence net value, 2002)
       H5ANETHB  (Secondary residence net value, 2000)
   - Other real estate:
       H6ARLES   (Other real estate, 2002)
       H5ARLES   (Other real estate, 2000)
   - Private business:
       H6ABSNS   (Private business, 2002)
       H5ABSNS   (Private business, 2000)
   - IRA / Keogh:
       H6AIRA    (IRA/Keogh, 2002)
       H5AIRA    (IRA/Keogh, 2000)
   - Stocks / mutual funds:
       H6ASTCK   (Stocks/mutual funds, 2002)
       H5ASTCK   (Stocks/mutual funds, 2000)
   - Bonds:
       H6ABOND   (Bonds, 2002)
       H5ABOND   (Bonds, 2000)
   - Checking / savings / money market:
       H6ACHCK   (Checking/savings, 2002)
       H5ACHCK   (Checking/savings, 2000)
   - CDs / T-bills:
       H6ACD     (CDs/T-bills, 2002)
       H5ACD     (CDs/T-bills, 2000)
   - Vehicles:
       H6ATRAN   (Vehicles, 2002)
       H5ATRAN   (Vehicles, 2000)
   - Other assets:
       H6AOTHR   (Other assets, 2002)
       H5AOTHR   (Other assets, 2000)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H6AMORT   (All mortgages on primary residence, 2002)
       H5AMORT   (All mortgages on primary residence, 2000)
       H6AMRTB   (Mortgage on 2nd home, 2002)
       H5AMRTB   (Mortgage on 2nd home, 2000)
       H6AHMLN   (Other home loans, 2002)
       H5AHMLN   (Other home loans, 2000)
       H6ADEBT   (Total other debt, 2002)
       H5ADEBT   (Total other debt, 2000)

CG formula (per class):
   cg_class = (V_2002_class - V_2000_class)

Overall period numerator and annualization:
   num_period = y^c_2002 + sum_c(cg_class) - F_total_period - debt_payments_2002
   base = A_{2000} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1


# 2. Collecting demographic variables

* age: r5agey_b
* education: raedyrs
* employment: r5inlbrf
* marital status: r5mstat
* immigration status: rabplace

# 3. Income variable (respondent only)
* r14iearn, r14ipena, r14issdi, r14isret, r14iunwc, r14igxfr,
* hwicap, hwiother

# 4. Trust variables
* rv557, rv558, rv559, rv560. rv561. rv562, rv563, rv564