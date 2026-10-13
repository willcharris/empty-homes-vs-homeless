# Map 1 Pre-registration: Amendment 4

Date: 2026-10-13. Amends: data integrity checks for the Claim 1b population pull (08_pull_rent_pop.R).
Claims, definitions, thresholds and verdict rules are NOT changed.

## What changed
The check "tract population must match each state's published total" now allows one documented exception, as in Amendment 2.

## Why
ACS 2020-2024 5-year, B01003_001 (total population). 50 of 51 units match exactly. New York tracts sum to 19,774,787 vs. a published state total of 19,852,366 (-77,579; -0.39%). The gap is entirely in Suffolk County (36103): 1,452,567 across 371 tracts vs. a county total of 1,530,146 (-5.1% of the county). All other New York counties match. The same county, with the same 371 tracts, carries the vacant-unit gap in Amendment 2 (-709 units). The cause inside Census's published tables is not known.

## Effect
- The check permits a shortfall only in New York, capped at 77,579 people. Any other discrepancy stops the script.
- Tract data are used as published; nothing is adjusted.
- The CoC covering Suffolk County (believed to be NY-603; to be confirmed against the assignment file) will have its population understated and its homeless-per-10,000 rate overstated by a few percent.

## Reporting commitments
- Claim 1b is reported twice: with all 382 CoCs, and with New York CoCs excluded. A material difference between the two goes in the limits.
- The Suffolk gaps (Amendments 2 and 4) are stated in the methodology note and the limits section.
