# Map 1 Pre-registration: Claim 1c (rent burden)

Locked: 2026-10-13, before any rent-burden data (ACS B25070) were pulled or seen.
Status: a refinement tried AFTER Claim 1b came out "mixed" (rent rho 0.28, below the 0.3 bar). Refinements tried after a mixed result: 1 (this one). It is a new, separately labeled claim; it does not replace or rescue 1b.
Disclosure: results already seen are those in map1-results-log.md (Claim 1 supported; Claim 1b mixed). No rent-burden figures have been seen.

Stance (author's view, labeled in the caption, kept separate from findings): advocate. The author's view is that affordability, not a shortage of buildings, is the barrier to housing. Claim 1c tests the affordability mechanism more directly than rent level does, because it accounts for income.

## Claim 1c (restated)
Homelessness rates are higher in CoCs where a larger share of renter households are cost-burdened.

## Data and scope (same as Claim 1b)
- ACS 2020-2024 5-year, table B25070 (gross rent as a percentage of household income), tract level, 50 states + DC.
- Tract-to-CoC assignment: the saved largest-overlap file (Amendments 1 and 3).
- Homeless per 10,000 residents: as in Claim 1b (PIT 2025 over summed tract population).
- Scope: 382 CoCs.

## Measure (primary, fixed now)
Burden share per CoC = renter households paying 30 percent or more of income on gross rent, divided by renter households for which the percentage was computed. Counts are summed across a CoC's tracts (an exact aggregate, not an average of tract values).
- Numerator: B25070_007 + _008 + _009 + _010 (30.0 to 34.9, 35.0 to 39.9, 40.0 to 49.9, 50.0 percent or more).
- Denominator: B25070_001 minus B25070_011 (not computed).
- Variable meanings are checked against the Census variable labels by the pull script before use; a mismatch stops it.

Pre-specified secondary measure, reported only as a labeled sensitivity (never a second verdict): severe burden share = B25070_010 / (B25070_001 - B25070_011).

## Test and rule (fixed now)
Spearman rank correlation between burden share and homeless per 10,000 residents, across CoCs, with bootstrap 95% intervals (2,000 resamples, seed 1).
- Supported if rho >= 0.3.
- Contradicted if rho <= 0.
- Mixed otherwise.
The 0.3 line is the same conventional threshold used for Claim 1b, set before seeing data.

## Reporting rows
1. All 382 CoCs: the verdict row.
2. Excluding New York CoCs (carry-over from Amendment 4; Suffolk County tract gaps).
3. Excluding sheltered-only CoCs (labeled sensitivity).
4. Severe-burden measure, all 382 CoCs (labeled sensitivity).
No other specifications will be run. All four rows are published whatever they show.

## Known limits (stated in advance)
- Burden is computed only for renter households that report income; "not computed" households are excluded and may differ systematically.
- Area-level correlation across CoCs does not show individual causes.
- CoCs differ greatly in size and in how they count; Balance-of-State CoCs combine whole regions.
- PIT is a one-night undercount; sheltered-only CoCs have no unsheltered count.
- Any tract-data gap found in the pull (as with Suffolk County in Amendments 2 and 4) will be handled by a documented exception confined to that county and logged as an amendment; any other discrepancy stops the pull.
- If 1c comes out supported, that is one result among the two claims tried after a mixed 1b, and the caption will say so.
