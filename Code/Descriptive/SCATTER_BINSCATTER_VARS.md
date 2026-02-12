# Scatterplots and binscatters in descriptive files — variables and toggles

**Data source:** All scatter/binscatter graphs use **`${PROCESSED}/analysis_ready_processed.dta`** unless noted.

---

## 06_descriptive_income.do

**Input:** `analysis_ready_processed.dta` (line 34).  
**Wealth percentiles:** `wealth_core`, `wealth_ira`, `wealth_res`, `wealth_total`, `gross_wealth` — **no** `wealth_coreira` in the percentile list (line 399: `pctvars`).  
Percentiles: `by year`, rank then `ceil(100 * rank/N)` → vars `wealth_*_pct`.

### Binscatter (and IQR/ribbon)

| Graph type | Y variable | X variable | Toggle / condition |
|------------|------------|------------|--------------------|
| Labor income by wealth | `ln_lab_inc_final_` | `wealth_total_pct` | `if year == y`; run only if `count(ln_lab_inc_final_, wealth_total_pct) >= 10` |
| Total income by wealth | `ln_tot_inc_final_` | `wealth_total_pct` | `if year == y`; run only if `count(ln_tot_inc_final_, wealth_total_pct) >= 10` |

**Years:** `2002`, `2022` (local `years`).  
**Binscatter option:** `nquantiles(50)`.  
**No weights** in the binscatter calls.

---

## 07_descriptive_returns.do

**Returns vs wealth block:** After `use "${PROCESSED}/analysis_ready_processed.dta", clear` (line 180).  
**Wealth percentiles:** Built from reshaped long data; vars: `wealth_core`, `wealth_ira`, `wealth_res`, `wealth_total`, `gross_wealth`; **and** `wealth_coreira` **if** variable `wealth_coreira_2002` exists (lines 428–456).  
Percentiles: `by year`, then `*_pct = ceil(100 * rank/N)`.

### Return vs wealth percentile (mean+IQR + binscatter)

**Toggle:** Entire block runs only if `wealth_core_2002` exists (`capture confirm variable wealth_core_2002`, line 425).

| Return (Y) | Wealth percentile (X) | Years | Toggle / condition |
|------------|------------------------|--------|--------------------|
| `r1_annual_` | `wealth_core_pct` | 2002, 2022 | Skip if `count(retvar, wvar) < 10` for that year |
| `r2_annual_` | `wealth_ira_pct` | 2002, 2022 | same |
| `r3_annual_` | `wealth_res_pct` | 2002, 2022 | same |
| `r4_annual_` | `wealth_coreira_pct` | 2002, 2022 | same |
| `r5_annual_` | `wealth_total_pct` | 2002, 2022 | same |

**Binscatter:** `binscatter retvar wvar if year == yr`, `nquantiles(50)`.  
**No weights** in binscatter.  
**IQR graph:** `keep if year == yr` then `collapse (mean) (p25) (p75) by(wvar)`.

---

## 08_descriptive_controls.do

**Input:** `analysis_ready_processed.dta` (line 36; again at 1053 before trust/income/returns section).

### Trust vs income scatter (twoway scatter)

| Y variable | X variable | Toggle / condition |
|------------|------------|--------------------|
| `ln_lab_inc_final_2022` | `trust_others_2020` | `capture confirm variable`; plot only if var exists |
| `ln_tot_inc_final_2022` | `trust_others_2020` | same |
| **Condition:** | | `if !missing(yvar) & !missing(trust_others_2020)` |

### Trust vs returns scatter (twoway scatter)

**Variables (in order):**  
`r1_annual_2022`, `r4_annual_2022`, `r5_annual_2022`,  
`r1_annual_win_2022`, `r4_annual_win_2022`, `r5_annual_win_2022`.

| Y variable | X variable | Toggle / condition |
|------------|------------|--------------------|
| Each of the 6 return vars above | `trust_others_2020` | `capture confirm variable`; plot only if var exists |
| **Condition:** | | `if !missing(return_var) & !missing(trust_others_2020)` |

**Winsorized:** Used only if `r*_annual_win_2022` exist (no separate toggle; confirm then plot).

### Binscatter: depression vs trust

| Y variable | X variable | Toggle / condition |
|------------|------------|--------------------|
| `depression_2020` | `trust_others_2020` | Run only if **both** `depression_2020` and `trust_others_2020` exist (`has_dep` & `has_trust`) |
| **Condition:** | | `if !missing(depression_2020) & !missing(trust_others_2020)` |
| **Option:** | | `nquantiles(50)` |

---

## 09_robustness_returns_trust.do

**Input:** `analysis_ready_processed.dta` (line 33).

### Trust vs age (twoway connected)

| Y variable | X variable | Toggle / condition |
|------------|------------|--------------------|
| `trust_mean` (collapse mean of `trust_others_2020`) | `age_bin` (floor(age_2020/5)*5) | `drop if missing(age_2020) \| missing(trust_others_2020)` before collapse |

### Trust vs returns — robustness scatters

**Base return list:** `r1_annual_2022`, `r4_annual_2022`, `r5_annual_2022`.

For **each** of these:

| Plot | Y variable | X variable | Toggle / condition |
|------|------------|------------|--------------------|
| 5% winsorized | `v'_w5` (winsor at p5/p95) | `trust_others_2020` | `keep if !missing(v) & !missing(trust_others_2020)` in preserve block |
| 1% trimmed | `v'_t1` (trim outside p1–p99) | `trust_others_2020` | same keep |
| 5% trimmed | `v'_t5` (trim outside p5–p95) | `trust_others_2020` | same keep |

**Skip:** If `capture confirm variable v` fails, skip that return.  
**No** `if` on the twoway scatter itself (sample already restricted by preserve/keep).

---

## Summary table

| File | Graph type | Y vars | X var | Main toggles / conditions |
|------|------------|--------|-------|---------------------------|
| 06 | Binscatter | ln_lab_inc_final_, ln_tot_inc_final_ | wealth_total_pct | year in {2002,2022}; N≥10 |
| 07 | Binscatter + IQR | r1,r2,r3,r4,r5_annual_ (by scope) | wealth_*_pct (scope-specific) | wealth_core_2002 exists; year in {2002,2022}; N≥10 per (ret,wvar,year) |
| 08 | Scatter | ln_lab/tot_inc_final_2022, r1/r4/r5_annual_2022, r1/r4/r5_annual_win_2022 | trust_others_2020 | confirm variable; !missing(y) & !missing(trust) |
| 08 | Binscatter | depression_2020 | trust_others_2020 | both vars exist; !missing both; nquantiles(50) |
| 09 | Connected | mean trust by age_bin | age_bin | drop missing age/trust |
| 09 | Scatter | r1/r4/r5_annual_2022 (raw, w5, t1, t5) | trust_others_2020 | keep !missing(return) & !missing(trust) |

All scatter/binscatter use **complete cases** on the (Y, X) pair; no weights in the scatter/binscatter commands themselves.
