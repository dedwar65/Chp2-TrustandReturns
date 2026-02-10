### Hometown size, population, and trust IVs – sample restriction reminder

- The variables `population_2020` and `population_3bin_2020` come from the 2020 trust module and are **time-invariant** in the processed data.
- The `hometown_size_*` variables are constructed in `Code/Processing/03_prep_controls.do` as:
  - `hometown_size_YYYY = region_YYYY * 100 + population_2020`
  - So population bin is fixed at its 2020 value and only the region component can change over time.

Implications for causal effects of trust:

- If you use combinations of `population_2020`, `population_3bin_2020`, `hometown_size_*`, or related regional contextual trust variables (e.g. `townsize_trust_*`, `pop_trust_*`, `regional_trust_*`) as instruments or for causal interpretation of trust:
  - **Restrict the sample** to individuals whose *region does not change* over the panel window you analyze (e.g. drop observations where `region_YYYY` varies across years for a given `hhidpn`), or apply an equivalent stability restriction.
  - Otherwise, changes in region over time can confound the interpretation of hometown-size or population-based instruments as fixed “origin” characteristics.

When setting up IV or panel regressions using these variables, revisit this note and explicitly code an appropriate sample restriction in your regression do-files.

