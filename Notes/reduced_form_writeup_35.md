# 35 reduced form and panel write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/35_reduced_form.log` (closed 12 Mar 2026, 19:41:04).

## Key result

- In panel `r5_annual_w5` models, trust is not jointly significant in standard RE (`p=0.1396`) but is jointly significant in CRE/Mundlak (`p=0.0087`).
- Hausman (`p=0.0000`) and Mundlak-means test (`p=0.0000`) both reject standard RE assumptions.

## Where N comes from (important)

- Cross-section block (`r5_annual_avg_w5`): listwise deletion in each regression; here `N=595`.
- Pooled OLS panel (`regress` with trust + controls): listwise deletion on panel rows; `N=2,920`.
- FE time-varying model (`xtreg, fe`): uses all person-year rows with nonmissing outcome and time-varying controls; `N=102,894`.
- FE second-step:
  - Spec 1 (FE on education only): after `predict u` and `collapse by(hhidpn)`, many households remain; `N=21,997`.
  - Specs 2-3 (add trust terms): restricted to households with nonmissing trust; `N=575`.
- RE and CRE substantive models with trust terms: listwise deletion with trust + controls; both `N=2,920`.

This is why FE without trust has much larger N than trust-including second-step regressions.

## Test-by-test interpretation (purpose + result)

1. `testparm c.trust_others_2020 c.trust_others_2020#c.trust_others_2020` (cross-section)
- Purpose: Wald/F test that trust linear and quadratic terms are jointly zero.
- Result: `p=0.0251` -> reject at 5%.

2. Same trust joint test in pooled panel OLS
- Purpose: joint significance of trust block in pooled panel equation.
- Result: `p=0.0057` -> reject.

3. FE second-step trust joint test (`testparm trust_others_2020 trust_others_2020_sq`)
- Purpose: does trust explain estimated individual FE in second-step cross-section.
- Result: `p=0.6264` -> fail to reject.

4. Hausman test (`hausman fe_haus re_haus, sigmamore`)
- Purpose: test RE orthogonality (`Cov(u_i, X_it)=0`) on shared FE/RE specification.
- Result: `Prob > chi2 = 0.0000` -> reject RE consistency assumption.

5. RE trust joint Wald test (chi-square form)
- Purpose: trust-block significance under RE assumptions.
- Result: `p=0.1396` -> fail to reject.

6. CRE trust joint Wald test (chi-square form)
- Purpose: trust-block significance after adding Mundlak means.
- Result: `p=0.0087` -> reject.

7. Mundlak-means joint test (`testparm m_*`)
- Purpose: test whether unit effects are correlated with regressors (means jointly zero).
- Result: `chi2(11)=245.25`, `p=0.0000` -> strong evidence against plain RE, supports CRE.

## Bottom line for file 35

- Your previous significance loss is largely a sample/power issue when moving across model constructions.
- For panel identification with time-invariant trust, CRE is the defensible main specification in this file.
