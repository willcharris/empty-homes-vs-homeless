# Map 1 Results Log

Run date: 2026-10-13. Scope: 50 states + DC, 382 CoCs, 742,420 homeless people (HUD PIT, Jan 2025; HUD AHAR Part 1 2025). Vacancy: ACS 2020-2024 5-year, tracts aggregated to HUD FY25 CoC boundaries by largest overlap (Amendment 1). See map1-preregistration.md and Amendments 1-4 for method, exceptions and limits.

## Claim 1: Empty homes outnumber homeless people. Verdict: SUPPORTED (under the pre-registered rule)
- National (50 states + DC): broad 14,547,150 vacant units (19.6 per homeless person); narrow 8,665,393 (11.7); strict (other vacant only) 5,223,171 (7.0).
- By CoC: narrow count exceeds the homeless count in 382 of 382 CoCs (100%); 354 of 354 excluding the sheltered-only CoCs. Rule required at least 90%.
- Closest: MA-502 Lynn, narrow ratio 1.04 (1,316 units vs 1,271 people). Reported as essentially a tie, not a win. Next lowest: OR-501 Portland 1.54, OR-503 1.55, OR-500 1.56, VT-501 1.76, NY-600 New York City 1.78.
- Main reason it could be wrong: the claim compares units with people; normal turnover vacancy cannot be separated; "other vacant" (largest narrow category) is a catch-all; PIT is a one-night undercount; vacancy is a 2020-2024 average vs. a January 2025 count.

## Claim 1b: Homelessness is higher where rents are higher and vacancy is lower. Verdict: MIXED
Spearman rank correlations across CoCs, homeless per 10,000 residents vs. (a) population-weighted average of tract median gross rent, (b) narrow vacancy rate. Bootstrap 95% intervals, 2,000 resamples.
- All 382 CoCs (verdict row): rent rho 0.28 (0.18 to 0.37); vacancy rho -0.10 (-0.20 to 0.01). Rule: supported needed rent rho >= 0.3 and vacancy rho < 0; not met, so mixed.
- Excluding NY CoCs (n=358): 0.29 (0.19 to 0.39); -0.11 (-0.22 to -0.00). Mixed.
- Sensitivity, excluding sheltered-only CoCs (n=354): 0.22 (0.12 to 0.32); -0.08 (-0.20 to 0.03). Mixed.
- Reading: weak association in the predicted direction; rent rank accounts for roughly 8% of the variation in homelessness-rate rank. This complicates the author's stated view (advocate: the barrier is price and policy, not a lack of buildings).
- Limits: rent level is not affordability; the CoC rent figure is an average of tract medians; area-level correlations do not show individual causes; CoCs differ in size and counting methods; Suffolk County gaps (Amendments 2 and 4).

## Claim 1c (refinement after mixed 1b): homelessness rates are higher where more renter households are cost-burdened. Verdict: MIXED
Pre-registered before any burden data were pulled (map1-preregistration-claim-1c.md). Burden share = renter households paying 30% or more of income on rent (B25070_007 to _010) over households with burden computed; summed counts across a CoC's tracts. Spearman rank correlation with homeless per 10,000 residents; bootstrap 95% intervals. Rule: supported at rho >= 0.3, contradicted at rho <= 0, mixed otherwise.
- 1. All 382 CoCs (verdict row): rho 0.29 (0.19 to 0.37). Mixed.
- 2. Excluding NY CoCs (n=358): 0.29 (0.19 to 0.38). Mixed.
- 3. Excluding sheltered-only CoCs (n=354, sensitivity): 0.27 (0.17 to 0.35). Mixed.
- 4. Severe burden (50% or more of income), all 382 (sensitivity): 0.25 (0.15 to 0.34). Mixed.
- Reading: same weak positive association as rent level in 1b (0.28); burden rank accounts for roughly 8% of the variation in homelessness-rate rank. Near miss on the 0.3 line, reported as mixed. Does not refute, and does not strongly support, the author's stated view (affordability, not a lack of buildings, is the barrier).
- Limits: burden is computed only for renter households that report income (6.9% of renter households nationally are not computed and excluded); area-level correlation does not show individual causes; CoCs differ in size and counting methods; Suffolk County tract gaps (Amendments 2, 4, 5). Renter households in the CoC table: 41,897,841.
- Pull date 2026-10-13 (B25070). Suffolk exception: Amendment 5.

## Specifications and refinements tried
- Claim 1: 3 vacancy definitions (pre-registered); 3 tract-assignment methods tried before settling (Amendment 1).
- Claim 1b: 3 reported rows (all CoCs, excluding NY, excluding sheltered-only). No other specifications run.
- Claim 1c: 4 pre-registered rows (3 for the main measure, 1 severe-burden sensitivity). No other specifications run.
- Refinements after a mixed result: 1 (Claim 1c, rent burden). No further refinements planned: both 1b (0.28) and 1c (0.29) fall just under the 0.3 line, and further tries would risk fitting the result.

## Corrections log
- 2026-10-13: an earlier national comparison paired 50-state-plus-DC vacancy with HUD's 745,652 (which includes territories); corrected to 742,420 (Amendment 3).


## Sensitivity S1 (post-hoc, NOT pre-registered; 2026-10-13)
Script: map1/13_moe_check.R. Question: does each CoC's narrow vacant count beat its homeless count after allowing for ACS sampling error? Method: 90% margins of error summed across tracts (square root of summed squares; only the largest MOE among zero-estimate parts counted). PIT has no sampling MOE here; its undercount is a separate limit.
Result: 381 of 382 CoCs beat the homeless count at the low end. Exception: MA-502 Lynn (1,316 vs 1,271; range 0.81 to 1.27 to 1), too close to call. Claim 1 verdict unchanged (pre-registered rule used point estimates).
Spread: ratio 1.04 to 231 (median 18.5); 7 CoCs under 2:1, 54 under 5:1, 116 under 10:1.
Specifications tried so far: unchanged. S1 is a sensitivity check, not a refinement.
