# Map 1 Pre-registration: Amendment 1

Date: 2026-10-13. Amends: map1-preregistration.md ("Tract-to-CoC assignment").
Claims, definitions, thresholds and verdict rules are NOT changed.

## What changed
Tract-to-CoC assignment method: from "tract centroid inside CoC polygon" to "each tract assigned to the CoC with the largest area overlap" (areas computed in EPSG:5070, equal-area).

## Why (Michigan test, ACS 2020-2024 5-yr tracts vs HUD FY25 CoC boundaries)
- Centroid method: 52 of 3,017 tracts matched no CoC. 46 have no geometry (water-only, 0 vacant units). 6 real tracts did not match, holding 3,001 vacant units (0.55% of Michigan's 545,867).
- Point-on-surface alternative: 4 real tracts unmatched (718 units), but a different set from the centroid failures; 2 tracts changed CoC between the two methods.
- Largest overlap: all 2,971 tracts with geometry assigned; 0 units unassigned; assigned total equals the state total (545,867).
- Likely cause (not confirmed): CoC polygons and Census tract shapes are clipped differently along shorelines, so a single point can fall in a gap.

## Reporting commitments
- Centroid and point-on-surface results are kept as sensitivity checks and reported at the national stage.
- Share of tract area falling in the assigned CoC will be reported; tracts split across CoCs are assigned whole to one CoC.
- Methods tried before settling: 3 (centroid, point-on-surface, largest overlap). Chosen after seeing Michigan assignment results only, not any claim-level result.
