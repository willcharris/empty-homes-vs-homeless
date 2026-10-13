# Map 1 Pre-registration: Amendment 5

Date: 2026-10-13. Amends: data integrity checks for the Claim 1c rent-burden pull (10_pull_rent_burden.R).
Claim 1c, its measure, thresholds and verdict rule are NOT changed.

## What happened
ACS 2020-2024 5-year, B25070_001 (renter-occupied households with gross rent as a percentage of income). 50 of 51 units match their published state totals exactly. New York tracts sum to 3,521,092 vs. a published state total of 3,525,661 (-4,569). The gap is entirely in Suffolk County (36103): 86,850 across the county's tracts vs. a county total of 91,419 (-5.0%). All other New York counties match.

## Pattern across tables
The same county shows a shortfall in three ACS tract tables: vacant units (-709; -1.0% of the county; Amendment 2), total population (-77,579; -5.1%; Amendment 4) and renter households (-4,569; -5.0%). The cause inside Census's published tables is not known.

## Effect
- The pull script allowed a New York gap only if confined to Suffolk County (confirmed) and stopped on anything else.
- Tract data are used as published; nothing is adjusted.
- Burden share is computed as a ratio of summed counts, so a proportional shortfall in Suffolk's tracts would not bias NY-603's share much; a non-proportional one could. The unknown direction of that bias is a stated limit.
- Claim 1c is reported with and without New York's CoCs (pre-registered row 2).

## Other pull results
- National: state totals sum to the published U.S. total (45,017,354); tract sum 45,012,785 (4,569 lower).
- Renter households with burden not computed (B25070_011): 3,108,285, or 6.9%; excluded from the denominator as pre-registered.

## Record-keeping note
The pre-registration file for Claim 1c was written and delivered before the pull ran (chat record, 2026-10-13 17:20 America/New_York) but was saved to the local project folder after the pull. Its content is unchanged.
