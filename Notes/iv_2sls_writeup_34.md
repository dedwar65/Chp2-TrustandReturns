# 34 2SLS (quadratic trust) write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/34_2sls_trust_ret.log` (closed 12 Mar 2026, 19:40:17).

Model focus: `r5_annual_avg_w5` with two endogenous regressors (`trust_others_2020`, `trust_others_2020_sq`).

## N provenance

- N changes by instrument scheme because regressions now use listwise deletion (no common-sample restriction).
- Typical values in this run:
  - `N=594` for contemporaneous/ever schemes with available instrument data.
  - `N=556` for lagged-depression schemes (loss from missing lagged depression).

## Core inference

- Structural trust block is not supported by weak-IV-robust inference.
- Across schemes, Anderson-Rubin tests do not reject (`p` values around `0.22` to `0.66`).
- Joint trust tests in 2SLS outputs are generally high (e.g., `p=0.8508` in the shown dep0+Black case).

## Test-by-test interpretation (purpose + result)

1. Excluded-instrument F test (first-stage relevance)
- Purpose: test whether excluded IVs enter first-stage equations.
- Result: often statistically nonzero (`p` frequently <= 0.01), so some relevance exists.

2. Sanderson-Windmeijer multivariate F
- Purpose: conditional first-stage strength with multiple endogenous regressors.
- Result: weak (`p` often high; e.g., `0.5337`, `0.4822`, `0.3942`; best cases still marginal, e.g., `0.0966`).

3. Kleibergen-Paap rk LM (underidentification)
- Purpose: test rank condition (identified vs underidentified).
- Result: mostly fail to reject underidentification (examples: `p=0.5275`, `0.4707`, `0.3847`; borderline in some 3-IV specs near `0.09`).

4. Kleibergen-Paap rk Wald F vs Stock-Yogo critical values
- Purpose: weak-ID severity.
- Result: very low F (roughly `0.19` to `1.54`), far below Stock-Yogo critical values (`7.03` for `K1=2,L1=2`; `13.43` for `K1=2,L1=3`). Strong weak-ID signal.

5. Anderson-Rubin weak-IV-robust test
- Purpose: test structural significance of endogenous block, valid under weak IV.
- Result: non-rejection across schemes (e.g., `p=0.6640`, `0.6455`, `0.2680`, `0.4191`, `0.6020`, `0.2225`).

6. `estat endogenous` (when available)
- Purpose: test exogeneity of endogenous regressors.
- Result: mostly high p-values in this run; no robust evidence that endogeneity correction is essential.

7. `estat overid`
- Purpose: overidentifying-restrictions validity in overidentified cases.
- Result: unavailable in several specifications in this run; where unavailable, rely on `ivreg2` diagnostics.

## Practical conclusion for 34

- With two endogenous trust terms, identification is weak in this dataset/specification.
- The right interpretation is not "trust has no effect," but "2SLS here is too weakly identified to deliver reliable structural inference for the quadratic trust block."
- This supports keeping OLS/CRE evidence as primary and presenting quadratic-IV as a weak-identification robustness check.
