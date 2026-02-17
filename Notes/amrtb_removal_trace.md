# Secondary Mortgage (amrtb) Removal Trace

**Variable**: `hamrtb` = mortgage on 2nd home (secondary mortgage)  
**User decision**: Remove amrtb everywhere — use only amort (first mortgages) + ahmln (other home loans) for long-term debt. These appear in every wave.

---

## 1. 02_compute_returns_income.do

| Line | Usage | Change |
|------|-------|--------|
| 66-67 | `capture confirm variable h`wprev'amrtb` → if exists, add to req_vars | **Remove**: Do not add amrtb to req_vars |
| 95 | `foreach v in ... h`wcur'amrtb h`wprev'amrtb` — clean missing codes | **Remove** amrtb from loop |
| 214-215 | `secmort_term` = subtract amrtb from net_total when computing base | **Remove**: Delete secmort_term; net_total uses amort+ahmln+adebt only |
| 221 | `net_total_`y'` formula includes `secmort_term` | **Remove** secmort_term from formula |
| 386-387 | `_debt_total_`y'` = rowtotal(amort, ahmln, adebt, amrtb) | **Change** to rowtotal(amort, ahmln, adebt) — drop amrtb |
| 387 | `_debt_n_`y'` = rownonmiss(amort, ahmln, adebt, amrtb) | **Change** to rownonmiss(amort, ahmln, adebt) |

---

## 2. 03_prep_controls.do

| Line | Usage | Change |
|------|-------|--------|
| 339-340 | `_debt_total_`y'` and `_debt_n_`y'` use rowtotal/rownonmiss with amrtb | **Change** to rowtotal(h`j'amort h`j'ahmln h`j'adebt), missing and rownonmiss(amort, ahmln, adebt) |
| 352-360 | Leverage block (long_term_debt, leverage_long, leverage_other) | **Removed** — entire leverage block deleted per user request |
| 465-467 | `share_debt_long_`y'` = (amort+ahmln)/gross — already excludes amrtb | **No change** (share_debt_long already correct) |

**Plan update**: The share descriptive stats plan called for adding share_debt_amort, share_debt_ahmln, share_debt_amrtb and fixing share_debt_long to include amrtb. **Revert**: Keep share_debt_long = (amort+ahmln)/gross only. Add only share_debt_amort and share_debt_ahmln (no share_debt_amrtb). Graph 2c shows amort and ahmln components only.

---

## 3. 07_descriptive_returns.do

| Line | Usage | Change |
|------|-------|--------|
| 58 | `_debt_n_`y'` = rownonmiss(amort, ahmln, adebt, amrtb) | **Change** to rownonmiss(amort, ahmln, adebt) |
| 60 | `_debt_total_`y'` = sum of amort, ahmln, adebt, amrtb | **Change** to sum of amort, ahmln, adebt only |

---

## 4. 10_build_panel.do

| Line | Usage | Change |
|------|-------|--------|
| 133-140 | Leverage stubs (leverage_long, leverage_other) added to wealth_stubs | **Removed** — entire leverage block deleted |

---

## 5. Deleted

- `.cursor/plans/15_panel_shares_leverage_plan.md` — plan file deleted (leverage + shares regression spec)

---

## Summary: Debt Variables After Removal

| Variable | Definition |
|----------|------------|
| amort | First mortgages on primary residence |
| ahmln | Other home loans |
| adebt | Total other debt (short-term / non-mortgage) |
| **Long-term debt** | amort + ahmln only |
| **share_debt_long** | (amort + ahmln) / gross_assets |
| **share_debt_other** | adebt / gross_assets |
| **share_debt_amort** (new) | amort / gross_assets |
| **share_debt_ahmln** (new) | ahmln / gross_assets |

**No** share_debt_amrtb.
