# Miscellaneous notes: quirks in computing returns

*(For appendix or reference—quirky things encountered when computing returns.)*

---

## r5 sample-size drop from wealth-decile controls

**Finding:** The output is internally consistent and pinpoints the issue clearly.

- **r5** has the largest raw availability (N outcome nonmissing: 137,646) and largest trust overlap (4,120), so construction is not the bottleneck.
- The big r5 drop happens when you add return-specific wealth controls: 4,064 → 2,901.
- The missing table shows `wealth_d2`–`wealth_d10` are each missing for ~1,176 rows in the outcome+trust sample, which is almost exactly the source of that drop.
- **r1** and **r4** do not show this extra drop because their return-specific control sets do not impose the same wealth-decile missingness burden.

**Interpretation:** The N jump is mostly from wealth-decile controls in the r5 spec, not from trust overlap itself.

**Check:** Run this one-liner to confirm the exact rows dropped by wealth controls after base controls for r5:

```stata
* (one-liner to be inserted)
```
