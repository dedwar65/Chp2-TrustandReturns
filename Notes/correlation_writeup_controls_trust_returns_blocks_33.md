# 33 controls/trust/returns staged write-up (updated)

Source log: `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/33_returns_control_build_2.log` (closed 12 Mar 2026, 19:39:59).

## What changed in this rerun

- Same update as file 32: no fixed block sample in regressions.
- `pwcorr` and each regression now use model-specific listwise deletion.

## N behavior

- Across models in file 33, observed `N` ranges from about `592` to `723`.
- In the final full-control `r5` specification in the log tail:
  - return equation: `N=592`
  - trust-on-controls equation: `N` differs and is larger where return variables are not required.

## Final full-control `r5` results (tail section)

Model: `r5_annual_avg_w5` on `trust + trust^2 + wealth + age + inlbrf + educ_cat + gender + race + region + born_us + married`.

- Spec 2 (`trust + trust^2`): `N=592`, `R^2=0.1414`.
- Trust terms:
  - linear trust: `p=0.010`
  - quadratic trust: `p=0.034`
  - joint trust test (`testparm trust trust^2`): `p=0.0201` -> reject.

## Joint tests in final full-control `r5` model

Each `testparm` asks whether that control block is jointly zero.

- Wealth deciles: `p=0.1397` -> fail to reject.
- Age bins: `p=0.1098` -> fail to reject.
- Gender: `p=0.1264` -> fail to reject.
- Education categories: `p=0.6925` -> fail to reject.
- Race categories: `p=0.1065` -> fail to reject.
- Region categories: `p=0.0051` -> reject.
- Born in U.S.: `p=0.5343` -> fail to reject.
- Married: `p=0.8847` -> fail to reject.

## Companion trust equation in final block

Model: `trust_others_2020` on the same controls (no return variable required).

- `R^2=0.1229`.
- Joint wealth test: `p=0.0004` -> reject.
- Joint age test: `p=0.0000` -> reject.

## Practical implication for control selection

- In this final staged run, region is the only added social block clearly significant in `r5` after the baseline stack.
- The trust hump-shape remains statistically supported in `r5` (joint trust test rejected).
- Trust itself is strongly structured by age and wealth controls in the companion trust regressions.
- Because N now changes by model, compare significance/R^2 only alongside the model-specific N reported in each regression.
