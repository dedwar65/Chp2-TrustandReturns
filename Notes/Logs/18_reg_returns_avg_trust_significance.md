# 18_reg_returns_avg_trust.log: Trust coefficient significance (p ≤ 0.10)

*Note: Joint test (trust + trust²) p-value is not in the log (testparm run quietly); only linear and quadratic individual significance are reported here.*

## Without controls

| Trust variable | Linear sig. | Quadratic sig. | Either (linear or quad) |
|----------------|-------------|----------------|--------------------------|
| general | r4_win, r5_raw, r5_win | r1_win, r5_raw, r5_win | r1_win, r4_win, r5_raw, r5_win |
| social_security | r4_win | r1_win | r1_win, r4_win |
| medicare | none | none | none |
| banks | r4_win | none | r4_win |
| advisors | r1_win | r1_win | r1_win |
| mutual_funds | r1_win, r5_win | r1_raw, r1_win | r1_raw, r1_win, r5_win |
| insurance | none | r1_win | r1_win |
| media | none | none | none |
| pc1 | none | r1_win, r5_win | r1_win, r5_win |
| pc2 | r1_win | r1_win | r1_win |

## With controls

| Trust variable | Linear sig. | Quadratic sig. | Either (linear or quad) |
|----------------|-------------|----------------|--------------------------|
| general | r5_win | r5_win | r5_win |
| social_security | none | none | none |
| medicare | none | none | none |
| banks | none | none | none |
| advisors | r1_win | none | r1_win |
| mutual_funds | r5_win | none | r5_win |
| insurance | none | none | none |
| media | none | none | none |
| pc1 | none | r5_win | r5_win |
| pc2 | r1_win | r1_win | r1_win |

## Summary

**Without controls (linear or quadratic significant):** general, social_security, banks, advisors, mutual_funds, insurance, pc1, pc2

**With controls (linear or quadratic significant):** general, advisors, mutual_funds, pc1, pc2

---

*Specs: r1 = core, r4 = core+IRA, r5 = net wealth; raw/win = raw vs 5% winsorized.*
