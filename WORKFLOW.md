# Paper Workflow and Conventions

This document captures the pipeline, conventions, and nuances for reproducing and extending this paper. Use it as a reference when adapting this repo for future papers.

---

## Pipeline Run Order

1. **Full pipeline:** Run `Code/0_run_full_pipeline.do` from repo root or `Code/` directory.
   - Runs `0_run_pipeline_00_05.do` (data + processing 00–05)
   - Then `2_run_pipeline_10_18.do` (panel + regressions 10–18, 22, **25**)

2. **Regression pipeline only** (if processed data already exists): Run `Code/Regressions/2_run_pipeline_10_18.do`
   - Order: 10 (build panel) → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 22 → **25**

3. **Standalone scripts** (not in pipeline): 09, 19, 21, 23, 24. Run as needed.

---

## Key Conventions

### Trust variable labels (in regression tables)

- **Fin. Institutions** — aggregated score (mean of banks, advisors, mutual funds)
- **Fin. Inst. PC1** — first principal component (4 vars: general, banks, advisors, mutual funds)
- **Fin. Inst. PC2** — second principal component (same 4 vars)
- Squared terms: `(Fin. Institutions)²`, `(Fin. Inst. PC1)²`, `(Fin. Inst. PC2)²`

### Financial-institutional trust (file 25)

- **Summary table:** Banks, Financial advisors, Mutual funds, Trust in Fin. Institutions (N and Mean only)
- **PCA:** Scree plot + loadings table
- **Output path:** `Code/Regressions/Trust/FinInst/`
- **Figures:** `Code/Regressions/Trust/FinInst/Figures/fin_trust_scree.png`

### LaTeX integration (`Paper/Subfiles/extensions.tex`)

**Trust in financial institutions** section:

- **Composite trust score:** summary table → avg regression tables (cross_section, avg, panel1–3)
- **Principal component analysis:** scree plot → loadings table → PC1 tables → PC2 tables

---

## Paper structure

- `Paper/Chp2-draft.tex` — main document
- `Paper/Subfiles/` — data.tex, results.tex, extensions.tex, appendix.tex
- Tables use `\inputtable{../../Code/...}` with paths relative to Subfiles/

---

## Future papers: adaptation checklist

1. Update `00_config.do` paths if repo structure changes
2. Adjust trust labels in regression .do files (11, 12, 13, 18, 25) for consistency
3. PCA for 2022 cross-section r5 (early pipeline) may need same label conventions (Fin. Inst. PC1, PC2)
4. Extensions.tex: add new sections following the Trust in fin institutions pattern (descriptive → results by model)

---

## Logs

All regression logs go to `Notes/Logs/<script_name>.log`.
