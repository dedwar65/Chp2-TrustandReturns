# Why Second-Stage FE Inference Needs Bootstrap

## The two-step procedure (Spec 3)

1. **First stage:**
   - Estimate individual fixed effects from panel regression:
   - `xtreg y_it X_it, fe vce(cluster hhidpn)`
   - Predict person FE: `u_i_hat`.

2. **Second stage:**
   - Regress estimated FE on time-invariant covariates:
   - `reg u_i_hat Z_i, vce(robust)`.

---

## The problem

- `u_i_hat` is not observed data; it is an **estimated object** from step 1.
- Plain robust SE in step 2 treat `u_i_hat` like observed data and do not fully account for first-stage estimation uncertainty.
- This can make second-stage SE too small and p-values too optimistic.

---

## Implication

- Keep first-stage clustered FE SE as is.
- For second-stage inference, use a **cluster bootstrap of the entire two-step pipeline** (resample at `hhidpn` level).

---

## Recommended implementation

**Rule:** Each bootstrap replication must:

1. Resample individuals (`hhidpn`) with replacement.
2. Re-estimate first-stage FE model.
3. Recompute `u_i_hat`.
4. Re-run second-stage regression on `u_i_hat`.
5. Store target coefficients (e.g., trust, trust², educ).

- Use bootstrap percentile or normal-based CIs from the empirical distribution.
- Report bootstrap SE/p-values for second-stage coefficients in main or robustness table.

---

## Why cluster bootstrap by `hhidpn`

- Preserves within-person time dependence structure in panel data.
- Matches dependence assumptions used in first-stage clustering.
