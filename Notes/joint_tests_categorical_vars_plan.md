# Joint Tests for Excluded Categorical Variables — Plan

**Goal:** Add joint F-tests for categorical variables that are included in regressions but omitted from table display (age bins, wealth deciles, race, etc.). Report these alongside the existing trust joint test in the stats row of each table.

**Context:** Like the joint test for trust+trust² and for share×year interactions, we run `testparm` on the omitted categorical groups and add the p-values to the table.

**Note:** The table presentation revamp plan ([table_presentation_revamp_plan.md](table_presentation_revamp_plan.md)) remains separate and unchanged.

---

## Categorical variables to test by table type

| Table type | Omitted categorical vars | Joint tests to add |
|------------|--------------------------|--------------------|
| **Trust on controls** (11) | age bins | `p_joint_age_bin` |
| **Income on trust** (12, 17) | age bins | `p_joint_age_bin` |
| **Returns on trust** (13, 18) | age bins, wealth deciles | `p_joint_age_bin`, `p_joint_wealth` |
| **Panel regressions** (14, 15, 16) | age bins, wealth deciles, race, region (censreg), year | `p_joint_age_bin`, `p_joint_wealth`, `p_joint_race`, `p_joint_censreg`, `p_joint_year` (as applicable) |
| **Fin inst trust** (25) | age bins, wealth deciles, race | same as returns |

**Race:** Even when race dummies (NH Black, Hispanic, NH Other) are shown in the table, run a joint test on `i.race_eth` and report it for consistency.

---

## Implementation pattern

For each regression that has controls with omitted categoricals:

1. After the regression, run:
   ```stata
   quietly testparm i.age_bin
   estadd scalar p_joint_age_bin = r(p) : model_name
   quietly testparm i.race_eth
   estadd scalar p_joint_race = r(p) : model_name
   quietly testparm wealth_d2_2020 wealth_d3_2020 ... wealth_d10_2020  // or wealth_d2 wealth_d3 ... for panel
   estadd scalar p_joint_wealth = r(p) : model_name
   ```
   (Adjust variable names for cross-section vs panel: `wealth_d*_2020` vs `wealth_d*`.)

2. Add to `stats()` in esttab:
   ```stata
   stats(N r2_a p_joint_trust p_joint_age_bin p_joint_wealth p_joint_race, labels(...))
   ```

3. For models without a given control (e.g., columns 1–2 without controls), set `estadd scalar p_joint_* = .` or omit from that column.

---

## Files to modify

| File | Tables produced | Joint tests to add |
|------|-----------------|--------------------|
| `11_reg_trust.do` | trust_reg_*.tex | p_joint_age_bin, p_joint_race |
| `12_reg_income_trust.do` | income_trust_*_ihs.tex, etc. | p_joint_age_bin, p_joint_race (cols 3–4 only) |
| `17_reg_income_avg_trust.do` | income_trust_general_deflwin_*.tex | p_joint_age_bin, p_joint_race (cols 3–4 only) |
| `13_reg_returns_trust.do` | returns_r*_trust_*.tex | p_joint_age_bin, p_joint_wealth, p_joint_race (cols 3–4 only; wealth for r5) |
| `18_reg_returns_avg_trust.do` | returns_r*_trust_*_avg_win.tex | same as 13 |
| `14_panel_reg_ret.do` | panel_reg_r5_win.tex | p_joint_age_bin, p_joint_wealth, p_joint_race, p_joint_censreg, p_joint_year |
| `15_panel_reg_ret_shares.do` | panel_reg_r5_spec2_win.tex | same + share×year (already present) |
| `16_panel_reg_fe.do` | panel_reg_r5_spec3_win.tex, panel_fe_on_tinv_r5_win.tex | first stage: age, wealth, year; second stage: race |
| `25_reg_trust_fininst.do` | fin_trust_*.tex | p_joint_age_bin, p_joint_wealth, p_joint_race |

---

## Edge cases

- **Columns without controls (1–2):** No age/wealth/race in the model → use `.` or omit the joint test for those columns.
- **Panel Spec 3 first stage:** Time-invariant vars (race, educ, etc.) are absorbed by FE; only time-varying controls (age_bin, wealth_d, year, share×year) remain. Test age_bin, wealth_d, year.
- **Panel second stage (FE on time-invariant):** Regress FE on educ, gender, race, trust. Test i.race_eth.
- **Trust table (11):** Demographics spec has race; full controls has race + extra. Test age_bin and race in the full model.

---

## Execution order

1. Implement joint tests in each .do file.
2. Ensure esttab `stats()` includes the new scalars with clear labels.
3. Rerun pipeline to regenerate all tables.
4. Then execute the table presentation revamp plan.
