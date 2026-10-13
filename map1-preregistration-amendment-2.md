# Map 1 Pre-registration: Amendment 2

Date: 2026-10-13. Amends: data integrity checks in the national ACS pull (05_pull_national.R).
Claims, definitions, thresholds and verdict rules are NOT changed.

## What changed
The check "tract rows must sum exactly to each state's published vacant-unit total" now allows one documented exception.

## Why
ACS 2020-2024 5-year, table B25002_003 (vacant units). 50 of 51 units (50 states + DC) match exactly. In New York, the tract rows sum to 861,886 and the published state total is 862,595 (-709). The gap is entirely in Suffolk County (36103): 67,498 across 371 tracts vs. a county total of 68,207. All other New York counties match. A fresh pull reproduced the same tract sum and tract count (5,397), and no estimates were missing, so the pull is not the cause. The cause inside Census's published tables is not known.

## Effect
- National: state totals sum to the published U.S. total (14,547,859). Tract rows sum to 14,547,150, which is 709 lower (about 0.005%).
- The check now permits a shortfall only in New York, capped at 709 units. Any other discrepancy still stops the script.
- Tract data are used as published. No units were added or adjusted.

## Reporting commitments
- The Suffolk gap is stated in the methodology note and the limits section.
- If a result is close enough that 709 units could matter (it cannot for any national or CoC-level claim unless a CoC is near a ratio of 1), it will be flagged.

Date pulled for national tract tables: 2026-10-13.
