# Average-Measure Cross-Section Regressions

Cross-sectional OLS regressions with **average** income and **average** returns as LHS (instead of 2020 income and 2022 returns). **General trust only** for now.

## Do Files

| Script | Description |
|--------|-------------|
| **17_reg_income_avg_trust.do** | Average income (IHS, row mean across waves) on 2020 general trust + controls |
| **18_reg_returns_avg_trust.do** | Average returns (r1, r4, r5 row mean) on 2020 general trust + controls |

## Upstream Dependencies

- **04_processing_income.do**: Creates `lab_inc_defl_win_avg`, `tot_inc_defl_win_avg` (row mean of deflated winsorized levels); `ihs_lab_inc_defl_win_avg`, `ihs_tot_inc_defl_win_avg` (IHS of that average)
- **05_processing_returns.do**: Creates `r*_annual_avg`, `r*_annual_avg_w5` (row mean of returns, raw and 5% winsorized)

Run `0_run_pipeline_00_05.do` before 17 and 18.

## Regressions (17: Average Income)

**LHS:** (1) `lab_inc_defl_win_avg`, `tot_inc_defl_win_avg` (avg defl wins, levels); (2) `ihs_lab_inc_defl_win_avg`, `ihs_tot_inc_defl_win_avg` (avg defl wins, IHS)  
**RHS:** 2020 general trust (`trust_others_2020`)  
**Specs:** 3 columns — (1) trust only, (2) trust+trust², (3) trust+trust²+controls. Joint test for Trust+Trust² in columns 2 and 3.  
**Controls:** Age 5-yr bins, gender, educ, inlbrf, married, born_us, race_eth  
**SE:** vce(robust)

### Exported Tables (17)

| Path | Content |
|------|---------|
| `Average/Income/Labor/income_trust_general_deflwin.tex` | Labor income (avg defl wins, levels) on general trust |
| `Average/Income/Total/income_trust_general_deflwin.tex` | Total income (avg defl wins, levels) on general trust |
| `Average/Income/Labor/income_trust_general_deflwin_ihs.tex` | Labor income (avg defl wins, IHS) on general trust |
| `Average/Income/Total/income_trust_general_deflwin_ihs.tex` | Total income (avg defl wins, IHS) on general trust |

## Regressions (18: Average Returns)

**LHS:** `r1_annual_avg`, `r4_annual_avg`, `r5_annual_avg` (raw) and `r*_annual_avg_w5` (5% winsorized)  
**RHS:** 2020 general trust (`trust_others_2020`)  
**Specs:** 3 columns — (1) trust only, (2) trust+trust², (3) trust+trust²+controls. Joint test for Trust+Trust² in columns 2 and 3.  
**Controls:** Demographics + scope-specific wealth deciles (core for r1, core+IRA for r4, net wealth for r5)  
**SE:** vce(robust)

### Exported Tables (18)

| Path | Content |
|------|---------|
| `Average/Returns/Core/returns_r1_trust_general_avg.tex` | Returns to core (avg), raw |
| `Average/Returns/Core/returns_r1_trust_general_avg_win.tex` | Returns to core (avg), 5% winsorized |
| `Average/Returns/Core+res/returns_r4_trust_general_avg.tex` | Returns to core+IRA (avg), raw |
| `Average/Returns/Core+res/returns_r4_trust_general_avg_win.tex` | Returns to core+IRA (avg), 5% winsorized |
| `Average/Returns/Net wealth/returns_r5_trust_general_avg.tex` | Returns to net wealth (avg), raw |
| `Average/Returns/Net wealth/returns_r5_trust_general_avg_win.tex` | Returns to net wealth (avg), 5% winsorized |

## Summary: Total Tables

| Do file | Tables |
|---------|--------|
| 17 | 4 (labor + total × avg_ihs + deflwin_ihs) |
| 18 | 6 (3 returns × 2 raw/win) |
| **Total** | **8** |

## Pipeline Integration

Add to `2_run_pipeline_10_18.do` (or a new master script) after 13:

```
do "${BASE_PATH}/Code/Regressions/17_reg_income_avg_trust.do"
do "${BASE_PATH}/Code/Regressions/18_reg_returns_avg_trust.do"
```
