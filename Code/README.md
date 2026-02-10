---
# Workflow

The workflow for this is repository is the following: i) Raw data,  ii) Cleaned data,  iii) Processing,  iv) Descriptive,  and v) Regressions.

    * Raw data: This folder contains all the raw data files needed to execute the analysis of this repository. Specifically, the [RAND version of the HRS data](https://hrsdata.isr.umich.edu/data-products/rand), both the longitudinal file and the fat files (for merging in variables not processed in the longitudinal file), and the documentation for the variables are present in the zip files.

    * Cleaned data: This folder contains the .do files necessary to compute returns, prepare the **trust** regressor and relevant control variables, and the .dta files containing the final set of variables needed for the proceeding statistical analysis. The wide and long version of the final dataset is here. **Run order (after 00_config and 01_merge_all_data):** run `02_process_flows.do`, then `02_compute_returns_income.do`, then `Code/Processing/03_prep_controls.do` (prep demographics/controls). 

    * Processing: This folder goes a step further than cleaning and creating the .dta files by applying numerous data processing techniques (such as Windsorization) to the relevant variables in the final set. The .do files in this folder will be used to export a final .dta dataset to the Cleaned folder. After running `03_prep_controls.do`, `04_processing_income.do`, and `05_processing_returns.do`, you can run `Code/Processing/10_build_panel.do` to create a long, panel-ready dataset for regressions (`${PROCESSED}/analysis_final_long_unbalanced.dta`) based on the existing wide processed dataset; the panel includes **r1, r4, and r5** returns (and winsorized versions where present).

    * Descriptive: This folder produces desriptive statistics of the relevant processed variables. **Robustness:** `09_robustness_returns_trust.do` produces trust-vs-returns scatterplots and a **trust vs age (5-year bins)** plot; the latter is saved as `Descriptive/Figures/Robustness/trust_mean_by_age_bin.png`. Run `09` to regenerate that graph.

    * Regressions: This folder contains the **.do files**; they **export to subdirectories** under `Code/Regressions/`. Logs go to `Notes/Logs/`. Age is controlled with **5-year age bins** (`i.age_bin`).

    * **Output layout:**  
      * `Regressions/Trust/` — tables from trust-on-controls regressions (11).  
      * `Regressions/Income/Spec1/` — income–trust tables with **linear** trust.  
      * `Regressions/Income/Spec2/` — income–trust tables with **quadratic** trust (trust + trust²).  
      * `Regressions/Returns/Spec1/` — returns–trust tables, **linear** trust: **one table per trust variable** (10 tables), each with 6 columns (r1, r4, r5 × no controls | with controls). Filename: `returns_trust_<trust_stub>.tex` (e.g. general, social_security); add `_win` for winsorized (e.g. `returns_trust_general_win.tex`).  
      * `Regressions/Returns/Spec2/` — same: one table per trust variable (10 tables), **trust + trust²** on RHS; same filename convention.  

    * **10** = long-dataset regressions (when added).

    * **11** = trust: `11_reg_trust.do` regresses **every** 2020 trust variable (8 items + PC1, PC2) on demographics vs full controls; one table per outcome. **Output:** `Regressions/Trust/trust_levels_<stub>.tex`. Log: `11_reg_trust.log`.

    * **12** = income and trust (contemporary): `12_reg_income_trust.do` runs for **every** trust variable (8 + PC1, PC2), **twice** — once with **linear** trust (Spec1), once with **quadratic** trust (Spec2). For each (trust var, spec): one table, four columns — **Labor income** (no ctrl | with ctrl) | **Total income** (no ctrl | with ctrl). Variable labels used for all coefficients. **vce(robust)**. **Output:** `Regressions/Income/Spec1/income_trust_<stub>.tex` and `Regressions/Income/Spec2/income_trust_<stub>.tex`. Log: `12_reg_income_trust.log`.

    * **13** = returns and trust: `13_reg_returns_trust.do` regresses **2022 returns** (r1, r4, r5) on **2020 trust** — **one table per trust variable** in Spec1 and one per trust variable in Spec2 (10 trust vars each). Each table has 6 columns: r1, r4, r5 × no controls | with controls. Unwinsorized and winsorized indicated in filename (e.g. `returns_trust_general.tex`, `returns_trust_general_win.tex`). **Spec1** = linear trust; **Spec2** = trust + trust². **Output:** `Regressions/Returns/Spec1/returns_trust_<trust_stub>.tex`, `Regressions/Returns/Spec2/returns_trust_<trust_stub>.tex`. Log: `13_reg_returns_trust.log`.

* **Regression plan (conventions)**  
  * **Standard errors:** Cross-section income/trust and return/trust use **vce(robust)**. Panel regressions (if any) use **vce(cluster hhidpn)**.  
  * **Output:** .do files live in `Regressions/`; LaTeX tables go to `Regressions/Trust/`, `Regressions/Income/Spec1/`, `Regressions/Income/Spec2/`, `Regressions/Returns/Spec1/`, `Regressions/Returns/Spec2/`.  
  * **11:** All trust variables; two specs per outcome (Demographics | Full controls).  
  * **12:** Linear trust (Spec1) and quadratic trust (Spec2); one 4-column table per trust variable per spec.  
  * **12:** 2020 income on 2020 trust; column titles "Labor income" and "Total income"; proper variable labels. **13:** One table per trust variable (not per return) in Spec1 and Spec2; each table 6 columns (r1, r4, r5 × no ctrl | with ctrl); scope-appropriate wealth deciles. 

