# Table Presentation Revamp Plan

**Goal:** Make small changes to each table for a presentable draft. All changes will be made in the **code that generates the tables** (.do files), so rerunning the pipeline produces the correct output.

**Execution:** Once all instructions are collected, implement changes in the relevant .do files. User will then rerun the full pipeline.

**Related plan:** [joint_tests_categorical_vars_plan.md](joint_tests_categorical_vars_plan.md) — add joint F-tests for age bins, wealth deciles, race, etc. Execute that plan first (or in parallel); the joint-test stats will appear in the same tables.

---

## Global: Remove table comments (addnotes/footnotes)

**Scope:** Every single table produced by the pipeline.

**Change:** Replace all `addnotes(...)` content with a single period `"."`. User will add proper captions later; for now, avoid long footnotes that clutter tables.

**Implementation:**
- In each .do file that exports tables via `esttab`, change `addnotes("...")` to `addnotes(".")` (or equivalent minimal footnote).
- Do this for **every** esttab call across: 11, 12, 13, 14, 15, 16, 17, 18, 20, 25, 26, and any other table-producing scripts.
- **Constraint:** Do not break the pipeline. Use minimal, valid LaTeX (e.g. `"."` or `"\."`) so the .tex output remains valid.

---

## Restore joint tests in 13_reg_returns_trust.do (post-Codex rollback)

**Context:** Codex rolled back `13_reg_returns_trust.do` to commit fc63f75, which removed the joint-test stats columns (p_joint_age_bin, p_joint_wealth, p_joint_race). The rollback also restored label-insertion logic; we keep labels in LaTeX only (no Stata post-processing).

**Tasks:**
1. Re-add joint tests for **age bins** (`testparm i.age_bin` → `p_joint_age_bin`), **wealth deciles** (scope-specific: wealth_core_d, wealth_coreira_d, wealth_d → `p_joint_wealth`), and **race** (`testparm i.race_eth` → `p_joint_race`) wherever the corresponding variables are included in the regression.
2. Add these scalars to the `stats()` option in each esttab call.
3. Do **not** re-add label-insertion logic; labels stay in LaTeX (results.tex, appendix.tex, etc.).

---

## Add region joint test wherever region is included

**Scope:** Every regression that includes `i.censreg` (census region) in its controls.

**Change:** Add `testparm i.censreg` → `p_joint_censreg` and include it in the `stats()` option for the table.

**Files to check/update:** 14, 15, 16, 20, 25, 26 (and any others that use `i.censreg`). If region is in the control set, the joint test must be present in the table.

---

## Table 9: General trust (2020) on controls

**Source:** `11_reg_trust.do` — produces `Trust/trust_reg_*.tex` (one per trust var)

**Changes:**
1. **Title:** "General trust (2020) on controls" → **"Determinants of general trust"** (for general stub only; other trust vars may keep current pattern or get "Determinants of [stub] trust")

**Implementation:** In `11_reg_trust.do` line ~148: For stub=="general", use `title("Determinants of general trust")`; for others, optionally `title("Determinants of `capt_stub' trust")` or keep current.

---

## Table 10: Total income (2020) on General trust (2020), scaled asinh

**Source:** `12_reg_income_trust.do` — loop produces `Income/Total/income_trust_*_ihs.tex` and `Income/Labor/income_trust_*_ihs.tex`

**Changes:**
1. **Title:** Remove ", scaled asinh"; remove "(2020)" after trust; lowercase "general" → "Total income (2020) on general trust" (for general). For other trust vars: "Total income (2020) on [capt_stub] trust" (no (2020) after trust)
2. **Footnote:** Remove "Age bins (5-yr) included in columns 3–4." — keep only standard errors line and p-value significance line

**Implementation:** In `12_reg_income_trust.do`:
- Labor IHS (~321): `title("Labor income (2020) on `=cond("`stub'"=="general","general","`capt_stub'")' trust")`; remove addnotes
- Total IHS (~395): same pattern

---

## Table 11: Average total income (avg defl wins, IHS) on General trust (2020)

**Source:** `17_reg_income_avg_trust.do` — produces `Average/Income/Total/income_trust_general_deflwin_ihs.tex`

**Changes:**
1. **Title:** "Average total income (avg defl wins, IHS) on General trust (2020)" → **"Average total income on general trust"**
2. **Footnote:** Remove "Age bins (5-yr) included in columns 3–4." (same as Table 10)

**Implementation:** In `17_reg_income_avg_trust.do`:
- For meas==4 (total IHS): change title to "Average total income on general trust" (or use a conditional since it's general-only for now)
- Remove `addnotes("Age bins (5-yr) included in columns 3–4.")` — applies to all 4 tables (labor/total × log/ihs) from this file

---

## Table 12: (pending)

---

## Figure plan: Spec 3 fixed-effects distribution (net wealth)

**Motivation:** Mirror the style used in comparable papers for FE-distribution figures (histogram of estimated individual fixed effects), and generate this automatically whenever Spec 3 runs.

**Where to implement:** `Code/Regressions/16_panel_reg_fe.do`, immediately after Spec 3 FE estimation and FE extraction for `r5` (net wealth), especially the winsorized outcome used in Table 16.

### What "demean" means (for FE)

If `fe_i` is the estimated fixed effect for person `i`, demeaning is:
- `fe_dm_i = fe_i - mean(fe)`

Interpretation:
- Demeaning recenters the FE distribution at zero.
- It does **not** change ordering/ranks or shape (only location/center).
- This is standard because FE are identified up to an additive constant.

### Implementation steps

1. **Run trigger in Spec 3 block**
   - Execute right after FE estimates are available (`predict ..., u`) and person-level FE are collapsed.
   - Restrict figure generation to `ret == "r5"` and `win == "win"` for the main figure.

2. **Build person-level FE sample**
   - Keep one FE per `hhidpn` (already done in the script via collapse).
   - Work only on estimation sample used for that FE regression.

3. **Demean FE**
   - Compute sample mean of FE.
   - Generate demeaned FE: `fe_dm = fe - mean(fe)`.

4. **Winsorize demeaned FE at 1% tails**
   - Compute p1 and p99 of `fe_dm`.
   - Create `fe_dm_w1 = min(max(fe_dm, p1), p99)`.
   - Track how many observations are clipped in lower/upper tail (for notes).

5. **Export histogram**
   - Plot histogram of `fe_dm_w1`.
   - Export to: `Code/Regressions/Panel/Figures/fe_dist_r5_spec3_win_demeaned_w1.png`
   - Keep a stable filename so reruns overwrite old versions.

6. **Write figure note/caption snippet (auto)**
   - Save a short text/tex snippet (e.g., in `Notes/` or `Paper/Subfiles/auto/`) that says:
     - FE come from Spec 3 net-wealth return regression (winsorized).
     - Distribution is demeaned and winsorized at top/bottom 1%.
     - Include N (individuals) and tail-clipped shares if available.

7. **Optional robustness outputs (appendix)**
   - Also export:
     - raw FE histogram (no 1% winsorization),
     - and/or non-winsorized outcome version (`win=="raw"`),
   - but keep the main text figure tied to Table 16 spec.

### QA checklist before finalizing

- Confirm figure updates automatically whenever `16_panel_reg_fe.do` is rerun.
- Confirm FE sample size equals Spec 3 person-level FE sample for `r5` winsorized.
- Confirm mean of demeaned FE is ~0 (numerical precision tolerance).
- Confirm caption/note text matches paper style and model definition.

---

*Add more tables as user provides instructions.*
