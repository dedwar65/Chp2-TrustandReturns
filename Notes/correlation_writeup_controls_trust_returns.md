# Correlation write-up (updated `pwcorr` with `r3_annual_avg_w5`)

This note uses the updated `pwcorr` block from:
- `Notes/Logs/32_returns_control_build.log`
- section `pwcorr \`corr_full', sig obs`

That block includes trust, the control set used in file 32 (with factor expansions such as `corr_race_*`, `corr_censreg_*`, `corr_agebin_*`), and four return outcomes:
- `r1_annual_avg_w5`
- `r4_annual_avg_w5`
- `r5_annual_avg_w5`
- `r3_annual_avg_w5` (newly added)

All inference below on correlation tests uses the p-values reported directly in `pwcorr`.

## 1) Trust correlations (what changed with the new table)

Trust vs returns:
- `corr(trust, r1_annual_avg_w5) = 0.0485`, `p = 0.1909` -> **do not reject** `H0: corr = 0`
- `corr(trust, r4_annual_avg_w5) = 0.0942`, `p = 0.0143` -> **reject** at 5% (positive)
- `corr(trust, r5_annual_avg_w5) = 0.0904`, `p = 0.0132` -> **reject** at 5% (positive)
- `corr(trust, r3_annual_avg_w5) = 0.0390`, `p = 0.3133` -> **do not reject**

Interpretation:
- After the update, trust has statistically significant positive pairwise correlation with `r4` and `r5`, but not with `r1` or `r3`.
- Direction is positive for all four returns; significance is concentrated in broader portfolio outcomes (`r4`, `r5`).

## 2) Strongest trust-control correlations (direction + significance)

Largest absolute correlations with trust in this `pwcorr` block:
- `corr(trust, corr_race_eth_2) = -0.1825`, `p < 0.001` -> **reject**, negative
- `corr(trust, wealth_d2_2020) = -0.1600`, `p < 0.001` -> **reject**, negative
- `corr(trust, corr_agebin_85) = 0.1251`, `p = 0.0002` -> **reject**, positive
- `corr(trust, corr_agebin_55) = -0.1227`, `p = 0.0002` -> **reject**, negative
- `corr(trust, corr_agebin_35) = -0.0689`, `p = 0.0388` -> **reject**, negative
- `corr(trust, corr_agebin_40) = -0.0752`, `p = 0.0240` -> **reject**, negative
- `corr(trust, corr_agebin_70) = 0.0801`, `p = 0.0162` -> **reject**, positive
- `corr(trust, corr_agebin_80) = 0.0847`, `p = 0.0110` -> **reject**, positive
- `corr(trust, educ_yrs) = 0.0966`, `p = 0.0038` -> **reject**, positive
- `corr(trust, married_2020) = 0.1111`, `p = 0.0008` -> **reject**, positive
- `corr(trust, born_us) = 0.1099`, `p = 0.0010` -> **reject**, positive

Interpretation:
- Signs are broadly plausible: trust is higher among married, higher-education, and born-U.S. respondents.
- Negative trust correlation with `corr_race_eth_2` is consistent with documented group heterogeneity in trust.
- Age effects are non-monotone in dummy form (some bins negative, older bins positive), which is plausible in a rich age-profile setting.

## 3) Controls vs returns (largest patterns, including new `r3`)

### `r1_annual_avg_w5`
Stronger correlations:
- with `educ_yrs`: `0.1970`, `p < 0.001` -> **reject**, positive
- with `wealth_d2_2020`: `-0.2045`, `p < 0.001` -> **reject**, negative
- with `married_2020`: `0.1247`, `p < 0.001` -> **reject**, positive
- with `inlbrf_2020`: `0.1170`, `p < 0.001` -> **reject**, positive

### `r4_annual_avg_w5`
Stronger correlations:
- with `r1_annual_avg_w5`: `0.4814`, `p < 0.001` -> **reject**
- with `r5_annual_avg_w5`: `0.3938`, `p < 0.001` -> **reject**
- small but significant negatives with lower age-bin dummies and some wealth dummies.

### `r5_annual_avg_w5`
Stronger correlations:
- with `r4_annual_avg_w5`: `0.3938`, `p < 0.001` -> **reject**
- with `r3_annual_avg_w5`: `0.2545`, `p < 0.001` -> **reject**
- with `inlbrf_2020`: `0.0940`, `p < 0.001` -> **reject**, positive

### `r3_annual_avg_w5` (newly included)
Stronger correlations:
- with `wealth_d2_2020`: `-0.2819`, `p < 0.001` -> **reject**, negative
- with `wealth_d3_2020`: `-0.1282`, `p < 0.001` -> **reject**, negative
- with `educ_yrs`: `0.1292`, `p < 0.001` -> **reject**, positive
- with `married_2020`: `0.1744`, `p < 0.001` -> **reject**, positive
- with `inlbrf_2020`: `0.1158`, `p < 0.001` -> **reject**, positive

Interpretation for `r3`:
- The sign pattern is sensible: residential returns are lower for the bottom wealth deciles and higher with education/marriage/labor-force attachment.

## Bottom line from the updated `pwcorr`
- The added `r3_annual_avg_w5` does not materially change the trust story: trust remains weakly positive for all returns, but statistically significant only for `r4` and `r5`.
- Many control-return and control-trust correlations reject `corr = 0`, with economically plausible signs.
- Pairwise correlations remain descriptive; your regression and IV specifications are still the correct place for inference.
