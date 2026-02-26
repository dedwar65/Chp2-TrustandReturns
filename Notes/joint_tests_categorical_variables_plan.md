# Joint Tests for Excluded Categorical Variables — Plan

**Goal:** Add joint F-tests for categorical variables that are included in regressions but omitted from table display (age bins, wealth deciles, race). Report these alongside the existing trust joint test in the same table row.

**Context:** All main regression tables already report `p_joint_trust` (joint test: trust + trust²). We need analogous tests for:
- **Age bins** (`i.age_bin`) — when included
- **Wealth deciles** (`wealth_d2`–`wealth_d10`) — when included (returns regressions)
- **Race/ethnicity** (`i.race_eth`) — when included

**Reference:** Same pattern as trust/shares (e.g. `testparm c.trust_var c.trust_var#c.trust_var`; `estadd scalar p_joint_trust = r(p)`; include in `stats()`).

---

## Files and Excluded Variables

| File | Tables | Excluded from display | Joint tests to add |
|------|--------|------------------------|--------------------|
| `11_reg_trust.do` | Trust reg (Table 9) | age bins | `p_joint_age_bin`, `p_joint_race` |
| `12_reg_income_trust.do` | Income 2020 (Table 10) | age bins | `p_joint_age_bin`, `p_joint_race` |
| `17_reg_income_avg_trust.do` | Avg income (Table 11) | age bins | `p_joint_age_bin`, `p_joint_race` |
| `13_reg_returns_trust.do` | Returns 2022 (Table 12) | age bins, wealth deciles | `p_joint_age_bin`, `p_joint_race`, `p_joint_wealth` (when wealth in model) |
| `18_reg_returns_avg_trust.do` | Avg returns | age bins, wealth deciles | same |
| `14_panel_reg_ret.do` | Panel spec 1 | age bins, wealth, region, year | `p_joint_age_bin`, `p_joint_race`, `p_joint_wealth`, etc. |
| `15_panel_reg_ret_shares.do` | Panel spec 2 | age bins, wealth, region, year, share×year | same + already has share joint tests |
| `16_panel_reg_fe.do` | Panel spec 3, FE 2nd stage | varies | same logic |
| `25_reg_trust_fininst.do` | Fin Inst trust | age bins, wealth deciles | same |

---

## Implementation Pattern

For each regression that includes the controls:

```stata
* After regression (e.g. m4 or tot_quad_ctl):

* Age bins
quietly testparm i.age_bin
estadd scalar p_joint_age_bin = r(p) : m4

* Race/ethnicity (exclude base)
quietly testparm i.race_eth
estadd scalar p_joint_race = r(p) : m4

* Wealth deciles (when in model)
quietly testparm wealth_d2_2020-wealth_d10_2020
estadd scalar p_joint_wealth = r(p) : m4
```

Then in `esttab`:

```stata
stats(N r2_a p_joint_trust p_joint_age_bin p_joint_race p_joint_wealth, ///
    labels("Observations" "Adj. R-squared" "Joint test: Trust+Trust² p-value" ///
           "Joint test: Age bins p-value" "Joint test: Race p-value" "Joint test: Wealth deciles p-value"))
```

**Note:** Use `.` or omit for models that don't include a given control (e.g. no wealth in income regs). Use `estadd scalar p_joint_X = .` for models without that control.

---

## Per-File Checklist

### 1. `11_reg_trust.do`
- [ ] After `eststo full`: add `testparm i.age_bin`, `testparm i.race_eth`
- [ ] Add `p_joint_age_bin`, `p_joint_race` to stats (or single row "Joint tests: Age bins, Race p-values")

### 2. `12_reg_income_trust.do`
- [ ] After each spec with controls (lab_quad_ctl, tot_quad_ctl, etc.): add `testparm i.age_bin`, `testparm i.race_eth`
- [ ] Add to stats in esttab for Labor IHS, Total IHS (and log if applicable)

### 3. `17_reg_income_avg_trust.do`
- [ ] After m4: add `testparm i.age_bin`, `testparm i.race_eth`
- [ ] Add to stats

### 4. `13_reg_returns_trust.do`
- [ ] After each spec with controls: add `testparm i.age_bin`, `testparm i.race_eth`
- [ ] For r5 (and r4 if wealth in model): add `testparm wealth_d2_2020-wealth_d10_2020` (or equivalent)
- [ ] Add to stats in esttab

### 5. `18_reg_returns_avg_trust.do`
- [ ] Same pattern as 13

### 6. Panel regressions (14, 15, 16)
- [ ] Add joint tests for age_bin, race_eth, wealth deciles (when present)
- [ ] Add to stats; may need to handle many stats (share tests already present)

### 7. `25_reg_trust_fininst.do`
- [ ] Add joint tests for age_bin, race_eth, wealth deciles in cross-section, avg, panel blocks

---

## Table Layout

Report all joint tests in one block at the bottom of each table, e.g.:

| Stat | Col 1 | Col 2 | Col 3 | Col 4 |
|------|-------|-------|-------|-------|
| Observations | ... | ... | ... | ... |
| Adj. R-squared | ... | ... | ... | ... |
| Joint test: Trust+Trust² p-value | . | ... | . | ... |
| Joint test: Age bins p-value | . | . | ... | ... |
| Joint test: Race p-value | . | . | ... | ... |
| Joint test: Wealth deciles p-value | . | . | . | ... |

Use `.` for columns where the control is not in the model.

---

## Execution Order

1. Implement joint tests in each .do file.
2. Add corresponding stats to esttab.
3. Re-run full pipeline.
4. Verify tables in paper.

---

## Related Plans (Preserved)

- **Table presentation revamp:** `Notes/table_presentation_revamp_plan.md` — title/footnote edits
- **Maximal trust math:** `~/.cursor/plans/maximal_trust_math_and_tables_64e05972.plan.md` — turning points, delta method
