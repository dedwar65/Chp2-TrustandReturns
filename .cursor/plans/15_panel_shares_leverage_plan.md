# Plan: 15_panel_reg_ret_shares.do — Shares × Year + Leverage + Full Controls

## Goal
Create regression script 15 that extends the baseline panel specification (14) with:
1. **Leverage ratios** (long-term and other) — created upstream.
2. **Asset shares interacted with year dummies** on the RHS.
3. Full baseline controls (age bins, region, year dummies, wealth deciles, educ, gender, race_eth, inlbrf, married, born_us).
4. Same 3 specs per return: controls only; + trust; + trust².
5. Output: 6 tables (r1, r4, r5 × raw/winsorized) — same layout as 14.

---

## Pipeline Pre-requisites

### 1. Create leverage variables in 03_prep_controls.do

**File:** [Code/Processing/03_prep_controls.do](Code/Processing/03_prep_controls.do)

**Location:** Inside the wealth-decile loop (around line 337, after `_debt_total_`y'` is computed), add:

**Long-term leverage ratio:**
- `long_term_debt_`y'` = mortgages (hamort) + other home loans (ahmln) + mortgage on 2nd home (amrtb)
- `leverage_long_`y'` = long_term_debt_`y' / wealth_total_`y'
- Replace with . when wealth_total ≤ 0 or missing

**Other leverage ratio:**
- `leverage_other_`y'` = adebt / wealth_total_`y'
- Replace with . when wealth_total ≤ 0 or missing

**Keep:** Add `leverage_long_*` and `leverage_other_*` to `_wealthvars` (or a new capture unab) and include in `keepvars`.

**Debt components (from HRS):**
- h`j'amort = mortgages on primary residence
- h`j'ahmln = other home loans
- h`j'amrtb = mortgage on 2nd home
- h`j'adebt = total other debt

---

### 2. Extend 10_build_panel.do for leverage and full shares

**File:** [Code/Processing/10_build_panel.do](Code/Processing/10_build_panel.do)

**Leverage stubs:** Add to wealth_stubs (or a new leverage_stubs block):
```stata
foreach s in leverage_long leverage_other {
    capture unab tmp : `s'_*
    if !_rc {
        local wealth_stubs "`wealth_stubs' `s'_"
        local wealth_vars  "`wealth_vars' `tmp'"
    }
}
```

**Share stubs:** Extend beyond share_core, share_m3_ira, share_residential to include scope-appropriate shares for each return:
- **r1 (core):** share_m1_re, share_m1_bus, share_m1_stk, share_m1_chck, share_m1_cd, share_m1_bond (or share_core if using aggregate)
- **r4 (core+IRA):** share_m2_re, share_m2_bus, share_m2_ira, share_m2_stk, share_m2_chck, share_m2_cd, share_m2_bond
- **r5 (total):** share_m3_re, share_m3_bus, share_m3_ira, share_m3_stk, share_m3_chck, share_m3_cd, share_m3_bond, share_residential, share_m3_vehicles, share_m3_other

Add these share stubs to the share_stubs foreach so they are reshaped to long.

---

## New File: 15_panel_reg_ret_shares.do

**Location:** `Code/Regressions/15_panel_reg_ret_shares.do`  
**Output:** `Code/Regressions/Panel/` — `panel_reg_r1_shares.tex`, `panel_reg_r4_shares.tex`, `panel_reg_r5_shares.tex` (raw) and `panel_reg_r1_shares_win.tex`, etc. (winsorized).

### Structure

1. **Setup**
   - Same as 14: config, log, load `analysis_final_long_unbalanced.dta`, `xtset hhidpn year`.

2. **Controls**
   - Full baseline: i.age_bin, educ_yrs, i.gender, i.race_eth, inlbrf, married, born_us, i.region, i.year, scope-specific wealth deciles.
   - **Add:** leverage_long, leverage_other.
   - **Add:** Share variables × i.year interactions (e.g. `c.share_m1_re#i.year`, `c.share_m1_bus#i.year`, …).

3. **Scope-specific shares (to interact with year)**
   - r1: share_m1_re, share_m1_bus, share_m1_stk, share_m1_chck, share_m1_cd, share_m1_bond (or share_core if aggregate preferred).
   - r4: share_m2_re, share_m2_bus, share_m2_ira, share_m2_stk, share_m2_chck, share_m2_cd, share_m2_bond.
   - r5: share_m3_re, share_m3_bus, share_m3_ira, share_m3_stk, share_m3_chck, share_m3_cd, share_m3_bond, share_residential (and optionally share_m3_vehicles, share_m3_other).

4. **Specs**

   - Col 1: controls + leverage + shares#i.year.
   - Col 2: same + trust.
   - Col 3: same + trust + trust².

5. **Output**
   - 6 tables: raw r1, r4, r5 and winsorized r1, r4, r5.
   - Each: 3 columns.
   - esttab: drop age bins, wealth deciles, region dummies, year dummies, share interactions, leverage (or show leverage; TBD).
   - **Add note:** *"Age bins (5-yr), wealth deciles, region dummies, year dummies, share×year interactions, and leverage ratios omitted from table but included in regressions."*

6. **SE**
   - `vce(cluster hhidpn)`.

---

## Data Flow

```
03_prep_controls  → leverage_long_*, leverage_other_*
10_build_panel    → leverage_long, leverage_other, share_* (long)
15_panel_reg_ret_shares → Panel/panel_reg_r*_shares*.tex
```

---

## Execution Order

Run: 03 → 04 → 05 → 08 → 10 → 15

---

## Files to Change/Create

| File | Action |
|------|--------|
| `Code/Processing/03_prep_controls.do` | Add leverage_long_* and leverage_other_* per wave |
| `Code/Processing/10_build_panel.do` | Add leverage stubs; extend share stubs for full shares |
| `Code/Regressions/15_panel_reg_ret_shares.do` | **Create** — panel regressions with shares×year + leverage + full controls |

---

## Open Questions

1. **Leverage in table:** Show leverage coefficients or omit from table (like wealth deciles)?
2. **Share collinearity:** Shares sum to 1 within scope — omit one category as base to avoid collinearity?
3. **Share×year:** Use `c.share_m1_re#i.year` or `c.share_m1_re#ib2002.year` (base year)?
