# Map 1 Pre-registration: Amendment 3

Date: 2026-10-13. Amends: geographic scope; records tract-assignment outcomes.
Claims, definitions, thresholds and verdict rules are NOT changed.

## Scope clarification
The original pre-registration did not state the geographic scope. The analysis covers the 50 states and DC only. ACS tract data were not pulled for territories.
- The 2025 PIT table has 386 CoC rows (national total 745,652, ties to HUD). Four are in territories with PIT counts: Guam GU-500 (861), Puerto Rico PR-502 (1,031), PR-503 (1,029), Virgin Islands VI-500 (311) = 3,232 people. American Samoa (AS-500) and the Northern Marianas (MP-500) appear in HUD's boundary file but have no PIT row.
- Scope for all comparisons: 382 CoCs, 742,420 homeless people.
- Error corrected: an earlier national comparison paired 50-state-plus-DC vacancy with HUD's 745,652 (which includes territories). On the corrected scope the national ratios are 19.6 (broad), 11.7 (narrow) and 7.0 (strict), vs. 19.5, 11.6, 7.0 before. No verdict changes.

## Tract-to-CoC assignment outcomes (largest overlap, national run)
- 84,086 tracts assigned; 296 tracts with empty geometry (0 vacant units); 19 tracts with geometry but no overlapping CoC, holding 1,512 vacant units (0.01% of 14,547,150). These units are excluded from CoC-level counts and included in the national count.
- 2,166 tracts (2.6%) have under 90% of their area in the assigned CoC; they hold 863,546 vacant units (5.9% of the national total). Upper bound on vacancy that could sit in the wrong CoC. Tracts are assigned whole to one CoC.
- All 382 in-scope CoCs received at least one tract.
- Alaska and Hawaii areas were computed in a US-wide equal-area projection (EPSG:5070), not tested against a local projection.

## Reporting commitments
- CoCs with narrow ratios near 1 are reported as essentially ties, not wins (lowest: MA-502 Lynn, 1.04).
- The Suffolk County (Amendment 2) and unmatched-tract exclusions are stated in the limits section.
