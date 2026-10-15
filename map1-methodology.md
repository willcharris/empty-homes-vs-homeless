# Map 1 methodology: Are there more empty homes than homeless people?

Data pulled 2026-10-13. Data currency checked 2026-10-14. Stance: advocate (the author's view, labeled as such and kept separate from the findings below).

## In short
The claim tested, restated: the United States has more vacant homes than homeless people. On the pre-registered rule it is supported. Counting only units that are for rent, for sale or vacant for other reasons (not seasonal homes), there are 8,665,393 vacant units and 742,420 people counted homeless in the 50 states and DC, about 11.7 to 1. In 381 of 382 regions the units outnumber the people even after allowing for survey error. In one (Lynn, MA) it is too close to call. A count mismatch does not show that the units could house these people.

## Claims, rules and verdicts
Rules were written before the data were pulled (see the pre-registration files in the repo).

| Claim | Rule (fixed in advance) | Result | Verdict |
|---|---|---|---|
| 1. Narrow vacant units exceed homeless people | Nationally and in at least 90% of regions | 11.7 to 1 nationally; 382 of 382 regions on point estimates | Supported |
| 1b. Homelessness rate is higher where rents are higher and vacancy is lower | Rank correlation: rent at least 0.3 and vacancy below 0 | rent 0.28, vacancy -0.10 | Mixed |
| 1c. Homelessness rate is higher where more renters are cost-burdened | Rank correlation at least 0.3 | 0.29 | Mixed |

1b and 1c are weak positive links, just under the 0.3 line I set before looking. 1c was tried after 1b came out mixed and is reported as a separate claim. It is the only refinement tried.

## Data
| Layer | Source | Period | Geography |
|---|---|---|---|
| Vacant housing units | U.S. Census Bureau, American Community Survey 5-year, tables B25002 and B25004 | 2020-2024 | Census tracts, 50 states + DC |
| Rent, population, rent burden | Same survey, tables B25064, B01003, B25070 | 2020-2024 | Census tracts |
| People counted homeless | HUD 2025 Annual Homeless Assessment Report, Part 1, point-in-time counts by Continuum of Care | One night, January 2025 | Continuum of Care (CoC) |
| Regions | HUD FY2025 CoC national boundary file | FY2025 | 382 CoCs in scope |
| Outlines for drawing | Census cartographic boundary files for states and tracts (via the tigris R package) | 2023 | State, tract |

Sources: https://www.huduser.gov/portal/datasets/ahar/2025-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html, https://www.hudexchange.info/programs/coc/gis-tools/, and the Census API through the tidycensus R package.

## Method
1. **Scope.** 50 states and DC: 382 CoCs and 742,420 people. Four territorial CoCs (Guam, Puerto Rico x2, U.S. Virgin Islands; 3,232 people) are excluded because no tract data were pulled. With them HUD's national total is 745,652, which this scope reconciles to exactly.
2. **Vacancy definitions.** Broad: all vacant units. Narrow (used for the verdict): for rent + for sale + other vacant, excluding seasonal and recreational units and units rented or sold but not yet occupied. Strictest: other vacant only.
3. **Tracts to CoCs.** Each tract is assigned whole to the CoC with the largest area overlap (equal-area projection, EPSG:5070). Three methods were tried on Michigan before settling (Amendment 1). Of 84,086 assigned tracts, 2,166 (2.6%) have under 90% of their area in their assigned CoC; they hold 5.9% of vacant units, an upper bound on units that could sit in the wrong region.
4. **Counts and ratios.** Tract counts are summed to each CoC and compared with that CoC's homeless count.
5. **Correlations.** Spearman rank correlation across 382 CoCs between homeless per 10,000 residents and rent, vacancy rate and burden share, with bootstrap 95% intervals (2,000 resamples).
6. **Survey error (post hoc).** After the verdict, I checked each region against the low end of its 90% margin of error (sampling error only, summed across tracts): 381 of 382 still hold. This check was not pre-registered and does not change the verdict.

## How the map is drawn
- Dot density: 1 dot = 100 units or 100 people, the same for both layers. Each region gets the whole number of dots plus one extra dot with probability equal to the remainder (fixed random seed), so small regions are not rounded to nothing. Total: 86,642 amber and 7,414 cyan dots.
- **Dot positions are modeled, not measured.** Vacancy is known by tract but homelessness only by region, so both layers are placed by the same rule: a tract inside the region, chosen in proportion to its total housing units, then a random point inside that tract.
- Equal-area projection (EPSG:5070). Alaska is shown at 35% scale as an inset; Hawaii at full scale.
- Both layers get the same dot size, glow and brightness. Cyan is drawn on top of amber so overlaps stay visible. An earlier version drew cyan larger and brighter; I rejected it because it made the small layer look bigger than 1 to 11.7.
- The legend shows 8,664,169 vacant units, the units that could be placed in a region; the national total is 8,665,393. The 1,224-unit difference sits in 19 tracts that overlap no CoC.
- The video is a 20-second fade of the two layers (amber, then cyan). It is a reveal, not a time series.
- Colors (amber #C98500, cyan #1E96BA) were checked for color-vision separation against a near-black surface (#1a1a19). Layers are also named in the legend with live counts, so meaning does not rest on color alone.

## Limits
- **Units are not homes for these people.** Vacant units may be in the wrong place, in poor condition, or unaffordable. "Other vacant" is a catch-all, and normal turnover vacancy cannot be separated out. The map shows a mismatch, not a cause.
- **Homeless counts are a one-night undercount.** 28 of the 382 regions (29 nationally) report sheltered people only, so their counts are lower bounds. The highest ratios (up to 231 to 1) are in rural Balance-of-State regions, where homelessness is hardest to count; the map may look more lopsided there than reality.
- **Different windows.** Vacancy is a 2020-2024 survey average; homelessness is January 2025.
- **Survey error.** Tract estimates are noisy. The post hoc check above covers only Claim 1. The correlation intervals reflect variation across regions, not the survey's sampling error.
- **Close calls.** Lynn, MA is 1.04 to 1 (1,316 units, 1,271 people; range 0.81 to 1.27). Six more regions are under 2 to 1. Overall, the ratio runs from 1.04 to 231 (median 18.5); 54 regions are under 5 to 1 and 116 under 10 to 1.
- **Tract data gaps.** In Suffolk County, NY, Census tract tables sum to less than the county total in three tables (vacant units -709, population -77,579, renter households -4,569). Cause unknown; data used as published (Amendments 2, 4, 5).
- **Correlations are area-level.** They do not show individual causes. Rent level is not affordability, and a CoC's rent figure is a population-weighted average of tract medians. CoCs differ in size and counting methods.
- Territories are excluded (3,232 people counted).

## What changed along the way
- Pre-registration locked 2026-10-13 before data were pulled. Before locking I had seen only HUD's national total (745,652) and national seasonal/for-sale vacancy figures.
- Amendment 1: tract assignment by largest overlap. 2: Suffolk County gap, vacant units. 3: scope clarified to 50 states + DC, an earlier national comparison corrected to match, assignment outcomes recorded. 4: Suffolk County gap, population. 5: Suffolk County gap, renter households.
- Claim 1c's pre-registration was written and delivered in chat before its data were pulled but saved to the project folder after the pull. Its content is unchanged.
- The pre-registration also called for a national comparison from the ACS 2024 1-year estimates. I ran it on 2026-10-14, after the main analysis: 8,566,020 narrow vacant units (+/- 85,398), or 11.5 to 1, against 8,665,393 and 11.7 to 1 in the 5-year data. The 1-year figure is 1.1% lower, which is expected when one year is compared with a five-year average. The conclusion is unchanged.
- Specifications tried: 3 vacancy definitions, 3 tract-assignment methods, 3 rows for 1b, 4 rows for 1c, and the post hoc survey-error check. Nothing else was run.
- Findings are published whatever they showed. 1b and 1c complicate my stated view that price and policy, not a lack of buildings, is the main barrier.

## Data currency (checked 2026-10-14)
HUD's 2025 report is the latest national homeless count I found; I found no 2026 national report. As of Census's August 4, 2026 advisory, the release date for the 2025 ACS 1-year estimates was still being determined, and I found no date for the 2021-2025 5-year estimates. This map will be rerun when both arrive.

## Corrections log
- YYYY-MM-DD: Map 1 published. Data pulled 2026-10-13. Pre-registration amendments 1-5 are listed in the repo. No corrections since publication.
- 2026-10-13 (before publication): an earlier national comparison paired 50-state-plus-DC vacancy with HUD's 745,652, which includes territories; corrected to 742,420 (Amendment 3). Ratios moved from 19.5, 11.6 and 7.0 to 19.6, 11.7 and 7.0.

## Reproduce
Scripts are in `map1/`, numbered in run order (15 water check, 16 dots, 17 still, 18 video frames, 19 carousel). Data files are not committed. Pull scripts need a free Census API key stored outside the project.
