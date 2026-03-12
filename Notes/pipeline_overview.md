# Pipeline Overview

## Full pipeline (run everything)

**File:** `Code/0_run_full_pipeline.do`

Runs in order:
1. **00–05** (data + processing)
2. **06–08** (descriptives)
3. **10–18, 20, 22, 25, 29** (panel + regressions)

---

## Stage 1: Data + processing (00–05)

**File:** `Code/Raw data/0_run_pipeline_00_05.do`

| Step | File | Purpose |
|------|------|---------|
| 00 | `00_config.do` | Paths, globals |
| 01 | `01_merge_all_data.do` | Merge HRS flows → all_data_merged.dta |
| 02 | `02_compute_returns_income.do` | Returns, income measures |
| 03 | `03_prep_controls.do` | Controls (age, censreg, born_us, etc.), reduce dataset |
| 04 | `04_processing_income.do` | Income processing |
| 05 | `05_processing_returns.do` | Returns processing |

**Output:** `Code/Processing/analysis_ready_processed.dta`

---

## Stage 2: Descriptives (06–08)

**File:** `Code/Descriptive/1_run_pipeline_06_08.do`

| Step | File | Purpose |
|------|------|---------|
| 06 | `06_descriptive_income.do` | Income descriptives |
| 07 | `07_descriptive_returns.do` | Returns descriptives |
| 08 | `08_descriptive_controls.do` | Controls descriptives |

---

## Stage 3: Panel + regressions (10–18, 20, 22, 25, 29)

**File:** `Code/Regressions/2_run_pipeline_10_18.do`

| Step | File | Purpose |
|------|------|---------|
| 10 | `10_build_panel.do` | Build long panel |
| 11 | `11_reg_trust.do` | Trust (LHS) cross-section |
| 12 | `12_reg_income_trust.do` | Income on trust |
| 13 | `13_reg_returns_trust.do` | Returns on trust (2022 CS) |
| 14 | `14_panel_reg_ret.do` | Panel returns (pooled OLS) |
| 15 | `15_panel_reg_ret_shares.do` | Panel returns (share×year) |
| 16 | `16_panel_reg_fe.do` | Panel FE |
| 17 | `17_reg_income_avg_trust.do` | Avg income on trust |
| 18 | `18_reg_returns_avg_trust.do` | Avg returns on trust (incl. region) |
| 20 | `20_finlit_extension.do` | Financial literacy extension |
| 22 | `22_2sls_tests.do` | 2SLS first-stage, exclusion diagnostics |
| 25 | `25_reg_trust_fininst.do` | Financial-institutional trust (PCA) |
| 29 | `29_2sls_untrust.do` | Untrust diagnostics (incl. born_us) |

---

## Excluded from pipeline (run manually)

| File | Purpose |
|------|---------|
| 19 | `19_inspect_finlit_r5.do` | Inspect finlit × r5 |
| 21 | `21_inspect_panel_r1_r4.do` | Inspect panel r1/r4 |
| 23 | `23_inspect_trust_fin.do` | Inspect trust fin |
| 24 | `24_inspect_trust_govt.do` | Inspect trust govt |
| 26 | `26_results_edu_categorical.do` | Education categorical results |
| 27 | `27_turning_points_original_results.do` | Turning points |
| 28 | `28_more_descriptive_stats.do` | More descriptives |
| 09 | `09_robustness_returns_trust.do` | Robustness (separate) |

---

## How to run

```stata
* From repo root (or Code/):
do Code/0_run_full_pipeline.do
```

Or run stages separately:
```stata
do Code/Raw data/0_run_pipeline_00_05.do      // data only
do Code/Descriptive/1_run_pipeline_06_08.do  // descriptives only
do Code/Regressions/2_run_pipeline_10_18.do  // regressions only (requires 00–05 first)
```
