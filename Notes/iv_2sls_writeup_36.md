# 36 2SLS (linear trust) write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/36_2sls_linear_trust.log` (closed 12 Mar 2026, 19:41:24).

Model focus: `r5_annual_avg_w5` with one endogenous regressor (`trust_others_2020`).

## N provenance

- N varies by instrument availability under listwise deletion:
  - `N=594` in contemporaneous/ever-depression schemes.
  - `N=556` in lagged-depression schemes.

## Core inference

- Weak-IV diagnostics improve relative to file 34 (single endogenous regressor is easier to identify), but still do not support strong IV inference.
- AR weak-IV-robust tests do not reject in all schemes (`p` values from about `0.135` to `0.843`).

## Test-by-test interpretation (purpose + result)

1. Excluded-instrument F test
- Purpose: first-stage relevance.
- Result: stronger than file 34 (e.g., `p=0.0568`, `0.0032`, `0.0020`, `0.0012`, `0.0001`, `0.0001`).

2. Sanderson-Windmeijer F (K1=1 case)
- Purpose: conditional first-stage strength (coincides with single-endog first-stage strength).
- Result: same strength pattern as above; better than file 34 but not uniformly strong.

3. KP rk LM underidentification test
- Purpose: test whether model is identified.
- Result: rejected in most schemes (`p=0.0037`, `0.0024`, `0.0015`, `0.0003`, `0.0001`), borderline in weakest contemporaneous-only case (`p=0.0541`).

4. KP rk Wald F vs Stock-Yogo
- Purpose: weak-ID severity.
- Result: F improves (about `3.64` to `9.88`) but remains below conservative Stock-Yogo thresholds (`16.38` for `L1=1`, `19.93` for `L1=2`). So still weak-to-moderate under strict criteria.

5. Anderson-Rubin weak-IV-robust test
- Purpose: structural significance test robust to weak instruments.
- Result: non-rejection in all schemes (e.g., `p=0.6716`, `0.8434`, `0.1460`, `0.6640`, `0.6455`, `0.2680`).

6. Structural trust Wald test in IV equation (`test trust_others_2020=0`)
- Purpose: significance of instrumented trust coefficient.
- Result: generally non-significant (example dep0 case: `p=0.6717`).

7. `estat endogenous`
- Purpose: test whether IV treatment is necessary (exogeneity null).
- Result: mixed but mostly non-rejection; no consistent evidence that endogeneity correction is required.

8. `estat overid` (overidentified specs only)
- Purpose: test exclusion validity of extra instruments.
- Result: available in overidentified runs; not the binding issue here relative to weak-ID diagnostics.

## Practical conclusion for 36

- Moving from quadratic-IV to linear-IV improves identification diagnostics, confirming the earlier weakness was largely the multi-endogenous burden.
- But weak-IV-robust tests still do not provide positive structural evidence for trust in this setup.
- File 36 is useful as a diagnostic check; it does not overturn the main reduced-form/CRE story.
