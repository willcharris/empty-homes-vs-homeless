# Map 1 Pre-registration

Locked: 2026-10-13, before any ACS or PIT data pulled.
Disclosure: before locking, I had seen only two headline figures while vetting sources: HUD's national PIT total (745,652, Jan 2025) and Census's national seasonal/for-sale vacancy figures. No CoC-level or tract-level data has been seen.

Stance (author's view, labeled in caption, kept separate from findings): advocate. My view: the barrier to housing is price and policy, not a lack of buildings.

## Data pairing (fixed)
- Vacancy: ACS 2020-2024 5-year, tract level (B25002, B25004), aggregated to CoCs. National comparison also reported from ACS 2024 1-year.
- Homelessness: HUD PIT, January 2025, by CoC.
- Boundaries: HUD CoC 2025 national geodatabase.
- Tract-to-CoC assignment: tract centroid inside CoC polygon. Method may be revised only if it fails validation, and any change will be logged.
- Year mismatch (ACS 2020-2024 vs PIT 2025) is stated on the graphic.

## Claim 1: Empty homes outnumber homeless people
Definitions (all three reported; verdict uses the narrow one):
- Broad: all vacant units (B25002_003).
- Narrow: for rent + for sale + other vacant (B25004). Excludes seasonal/recreational, rented or sold but not yet occupied, and migrant-worker units.
- Strictest: "other vacant" only.

Test:
- Supported if narrow vacant units exceed PIT homeless people nationally AND in at least 90% of CoCs.
- Mixed if true nationally but in 50-90% of CoCs, or true under broad but not narrow.
- Contradicted if narrow vacant units are fewer than the PIT count nationally, or exceed it in under 50% of CoCs.

Known limits: units vs. people; PIT undercount (ratio overstates coverage); narrow definition still includes normal turnover vacancy; a count mismatch cannot show cause or that units are available or habitable.

## Claim 1b (separate claim): Homelessness is higher where rents are higher and vacancy is lower
Variables, per CoC: PIT homeless per 10,000 residents; ACS median gross rent (B25064, population-weighted across tracts); narrow vacancy rate.
Test: Spearman rank correlation across CoCs.
- Supported if rent rho >= 0.3 AND vacancy rho < 0.
- Contradicted if rent rho <= 0 OR vacancy rho > 0.
- Mixed otherwise.

Reading note: this tests a tight-market explanation. It does not separate "supply constrained" from "supply withheld." Area-level correlations cannot be read as individual-level causes.

## Rules
- Refinements (a narrower geography, another metric, a different year) are tested as new labeled claims. The count of refinements tried will be reported.
- If Claim 1b contradicts or complicates the author's view, it is published anyway.
- Corrections-log line to be added at publication.
