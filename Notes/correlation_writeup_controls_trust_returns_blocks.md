# 32 controls/trust/returns block write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/32_returns_control_build.log` (closed 12 Mar 2026, 19:38:47).

## What changed in this rerun

- Cross-sectional regressions no longer force a precomputed common sample.
- `pwcorr` uses listwise deletion on the variables passed to each call.
- Each regression uses its own listwise deletion based on that model's RHS and outcome.

So `N` now legitimately differs across models.

## N behavior

- Across regression calls in file 32, `N` ranges from about `596` to `900`.
- For the final `r5_annual_avg_w5` block shown in the log tail:
  - return regression `N=600`
  - trust-on-controls companion regression `N=673`

Interpretation: trust regressions have larger N because they do not require return variables, while return regressions require nonmissing return construction variables.

## Latest displayed block (r5 with wealth + age + born_us)

### Return equation (`r5_annual_avg_w5`)
- Spec 1 (linear trust): `N=600`, `R^2=0.0675`.
- Spec 2 (trust + trust^2): `N=600`, `R^2=0.0816`.

Tests (purpose -> result):
- `testparm trust trust^2`: joint trust-block significance -> `p=0.0023` (reject).
- `testparm wealth deciles`: joint wealth block -> `p=0.5690` (fail to reject).
- `testparm i.age_bin`: joint age block -> `p=0.0052` (reject).

### Trust-on-controls companion equation (`trust_others_2020`)
- `N=673`, `R^2=0.1229`.

Tests (purpose -> result):
- `testparm wealth deciles`: do wealth deciles explain trust jointly -> `p=0.0004` (reject).
- `testparm i.age_bin`: do age bins explain trust jointly -> `p=0.0000` (reject).

## Practical reading

- In this updated setup, compare models by both coefficients and their model-specific N.
- Do not interpret small `R^2` changes as purely control effects unless N is similar.
- The trust hump-shape signal for `r5` remains present in the final displayed block, while trust itself is strongly related to age and wealth composition in the companion trust equation.
