# 37 reduced form extension write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/37_reduced_form_ext.log` (closed 12 Mar 2026, 19:42:12).

Relative to 35, file 37 adds time-invariant controls (`i.gender i.race_eth born_us i.censreg married`) in pooled/RE/CRE and FE second-stage regressions.

## Key result

- Trust remains not jointly significant in RE at 5% (`p=0.0525`, marginal).
- Trust is jointly significant in CRE (`p=0.0178`).
- Hausman and Mundlak tests still strongly reject plain RE assumptions (`p=0.0000` both).

## Where N comes from

- Cross-section (`r5_annual_avg_w5`): listwise deletion per model; `N=592`.
- Pooled OLS panel with trust: listwise deletion on panel rows; `N=2,899`.
- FE time-varying model: outcome + time-varying controls only -> `N=102,894`.
- FE second-step after collapse by household:
  - Spec 1 (no trust): `N=21,869`.
  - Specs 2-3 (require trust): `N=572`.
- RE and CRE substantive trust models: `N=2,899`.

## Test-by-test interpretation (purpose + result)

1. Cross-section trust joint test (`testparm trust trust^2`)
- Purpose: test hump-shape block significance in cross-section.
- Result: `p=0.0201` -> reject.

2. Pooled OLS trust joint test
- Purpose: same block significance in pooled panel OLS.
- Result: `p=0.0018` -> reject.

3. FE second-step trust joint test
- Purpose: test whether trust explains estimated FE after adding time-invariant controls.
- Result: `p=0.6856` -> fail to reject.

4. FE second-step race joint test (`testparm i.race_eth`)
- Purpose: test whether race block explains FE heterogeneity.
- Result: `p=0.0000` -> reject (race matters strongly in FE second-step).

5. Hausman (`hausman fe_haus re_haus, sigmamore`)
- Purpose: test RE orthogonality condition on shared FE/RE specification.
- Result: `p=0.0000` -> reject plain RE consistency assumption.

6. RE trust joint test
- Purpose: trust-block significance under plain RE assumptions.
- Result: `p=0.0525` -> not rejected at 5%, borderline at 10%.

7. CRE trust joint test
- Purpose: trust-block significance after Mundlak correction.
- Result: `p=0.0178` -> reject.

8. Mundlak means joint test
- Purpose: test whether means are jointly zero (if yes, RE would be sufficient).
- Result: `chi2(11)=239.52`, `p=0.0000` -> reject, supporting CRE.

## Bottom line for file 37

- Adding extra time-invariant controls increases fit and changes some block significance, but inference pattern is unchanged: FE/RE diagnostics favor CRE, and trust significance is recovered in CRE rather than plain RE.
