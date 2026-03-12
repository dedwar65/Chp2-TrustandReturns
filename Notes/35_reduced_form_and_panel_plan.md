# Plan for `35_reduced_form.do`

## Goal

Create `Code/Analysis/35_reduced_form.do` for a fixed-sample cross-sectional check that:

- starts from the `33`-style `pwcorr` sample rule, narrowed to the `r5` control set
- shows trust reduced forms on contemporaneous depression
- shows `r5` regressions on `trust_others_2020` and `trust_others_2020_sq` using only the reduced control set

In parallel, pin down the exact balanced/common-sample rule needed for a future panel `r5` reduced-form file and the panel-model sequence that follows once that sample is locked.

## Structure

Use `Code/Analysis/34_2sls_trust_ret.do` for setup and `depression_2020` construction, use the baseline-only sample logic reflected in `Code/Analysis/33_returns_control_build_2.do`, and use the long-panel naming in `Code/Processing/10_build_panel.do` and `Code/Regressions/14_panel_reg_ret.do` for the panel-sample design note.

## Planned behavior

- Start with a `pwcorr` sample-definition block modeled on the `33` baseline-only block, but restricted to:
  - `r5_annual_avg_w5`
  - `trust_others_2020` and `trust_others_2020_sq`
  - net-wealth deciles only: `wealth_d2_2020` through `wealth_d10_2020`
  - age-bin dummies
  - `inlbrf_2020`
  - education-category dummies
  - `depression_2020`
- Define one common complete-case sample from that list and print the `pwcorr` on that sample.
- Add reduced-form regressions of `trust_others_2020` on `depression_2020`, using:
  - `wealth_d2_2020` through `wealth_d10_2020`
  - age-bin dummies
  - `inlbrf_2020`
  - education-category dummies
  - gender
  - race
- Add `r5_annual_avg_w5` regressions on `trust_others_2020` and `trust_others_2020_sq`, using only:
  - `wealth_d2_2020` through `wealth_d10_2020`
  - age-bin dummies
  - `inlbrf_2020`
  - education-category dummies
- Keep the existing project conventions for config, log file path, and defensive variable checks.
- For the panel next step, document the exact rule for keeping only households with nonmissing:
  - `trust_others_2020`
  - `trust_others_2020_sq`
  - `r5` in every required return wave
  - the reduced control set in every required wave
  using the actual long-panel variable names after reshape rather than guessing from wide naming.
- After the panel sample rule is fixed, the planned panel sequence is:
  - pooled OLS for panel `r5` with the standard reduced control set and year dummies
  - FE for panel `r5`, letting Stata omit time-invariant regressors automatically
  - a second-step regression of time-invariant variables on the estimated fixed effects
  - a comparison RE model using the same time-varying regressors as FE so the classic Hausman test is well defined
  - the classic Hausman test on the shared FE/RE specification
  - the substantive RE model for panel `r5` with trust and trust squared included
  - a CRE/Mundlak test step
  - the substantive CRE/Mundlak model for panel `r5`, so time-invariant trust can be estimated while allowing correlation between unit effects and time-varying regressors
- Before moving from the standard FE version to the RE/CRE stage, include an FE-vs-RE decision step. Based on Stata guidance, the plan should:
  - run the Hausman comparison only on the coefficients FE and RE both estimate, meaning the shared time-varying specification
  - not rely only on a naive clustered Hausman test, because that is fragile with robust/clustered VCEs
  - prefer a CRE/Mundlak specification test such as `estat mundlak` as the more reliable panel diagnostic in this setup

## Expected log sections

- `1) COMMON SAMPLE PWCORR`
- `2) REDUCED FORM: TRUST ON CONTEMPORANEOUS DEPRESSION`
- `3) r5 ON TRUST AND TRUST SQUARED (REDUCED CONTROL SET)`
- `4) PANEL SAMPLE DESIGN NOTES FOR FUTURE r5 REDUCED FORM`
- `5) PANEL MODEL SEQUENCE AFTER SAMPLE LOCK`

## Reference

The sample-definition style to mimic is the baseline-only block in `33`, where a block-specific varlist is assembled and then used with `markout` before both `pwcorr` and regressions.

For the panel follow-up, the critical reference is that `Code/Processing/10_build_panel.do` reshapes the wide return and control series to long `hhidpn`-by-`year`, while `Code/Regressions/14_panel_reg_ret.do` currently uses looser `if !missing(yvar)` restrictions that will need to be replaced with one fixed panel sample rule requiring nonmissing `trust`, `trust^2`, `r5`, and the reduced control set over the full return window. The Hausman step should compare FE to a matching RE model on the shared time-varying regressors only; the full RE and CRE models with time-invariant trust come afterward.
