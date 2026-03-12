# Statistical test inventory for files 34-37 (updated)

Scope logs:
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/34_2sls_trust_ret.log`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/35_reduced_form.log`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/36_2sls_linear_trust.log`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/Logs/37_reduced_form_ext.log`

Companion interpretation files with conclusions:
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/iv_2sls_writeup_34.md`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/iv_2sls_writeup_36.md`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/reduced_form_writeup_35.md`
- `/Volumes/SSD PRO/Github-forks/Chp2-TrustandReturns/Notes/reduced_form_writeup_37.md`

## A. Coefficient-level inference

- t-test / z-test for individual coefficients (`H0: beta_j=0`)
  - Commands: `regress`, `xtreg, fe`, `xtreg, re`, `ivregress 2sls`, `ivreg2`.

## B. Joint linear restrictions (Wald/F/chi2)

- Joint block test (`H0: R*beta=0`)
  - Command: `testparm ...`
  - Used for trust block, wealth deciles, age bins, education categories, gender, race, region, year, Mundlak means.

- Single linear restriction (`H0: beta=0`)
  - Command: `test varname`.

## C. Correlation significance

- Pairwise correlation test (`H0: rho=0`)
  - Command: `pwcorr ..., sig obs`.

## D. FE vs RE / CRE specification tests

- Classic Hausman (`H0: RE consistent on shared coefficients`)
  - Command: `hausman fe_haus re_haus, sigmamore`.

- Mundlak means joint test (`H0: coefficients on means = 0`)
  - Command: `testparm m_*` (after CRE specification).

## E. IV postestimation from `ivregress`

- First-stage diagnostics
  - Command: `estat firststage`.

- Endogeneity test (`H0: specified endogenous regressors are exogenous`)
  - Command: `estat endogenous`.

- Overidentification test (`H0: overidentifying restrictions valid`)
  - Command: `estat overid` (only when overidentified/available).

- Weak-IV-robust postestimation
  - Command: `estat weakrobust` (and options `, ar`, `, clr`), availability depends on specification.

## F. IV diagnostics from `ivreg2`

Command family:
- `ivreg2 y controls (endog = excluded_iv), robust first weakiv`

Reported tests/statistics:
- Excluded-instrument F (first-stage relevance).
- Sanderson-Windmeijer multivariate F (conditional strength).
- Kleibergen-Paap rk LM (underidentification test).
- Kleibergen-Paap rk Wald F and Cragg-Donald F (weak-ID diagnostics).
- Stock-Yogo critical values (benchmark thresholds).
- Anderson-Rubin Wald F/chi2 (weak-IV-robust structural test).
- Stock-Wright LM S (weak-IV-robust test when computable).

## G. Where conclusions now live

- File 34 conclusions (quadratic IV weak-ID):
  - weak-ID diagnostics dominate; AR non-rejection; trust block not robustly identified.
- File 36 conclusions (linear IV):
  - identification improves vs 34 but still weak under strict thresholds; AR non-rejection persists.
- File 35 conclusions (reduced-form panel):
  - RE trust not significant; CRE trust significant; Hausman+Mundlak reject plain RE.
- File 37 conclusions (extended controls):
  - same model-ranking conclusion as 35; CRE retains trust significance while RE is weaker/marginal.

All test purposes and file-specific conclusions are explicitly written in those four companion `.md` files.
