# Data Sources: Contrast Maps

Working checklist. Status key: `unverified` / `partly verified` / `verified` / `rejected`.
For Map 1, "verified" means the source was opened, downloaded and checked against an independent total (see Checks). Map 2 and series-level entries are still unvetted.

Last updated: 2026-10-13.

---

## Map 1: Poverty vs. scarcity (vacancy vs. homelessness)

Claims tested: (1) empty homes outnumber homeless people; (1b) homelessness is higher where rents are higher and vacancy is lower. Stance: advocate (author's view, labeled separately from findings). Scope: 50 states + DC, 382 CoCs, 742,420 homeless people. Method and amendments: map1-preregistration.md and amendments 1-4. Results: map1-results-log.md.

Date pulled for all sources below: **2026-10-13**. Files are in `map1/data`.

| Layer | Source | Geography | Time coverage | URL / access | Files saved | Status |
|---|---|---|---|---|---|---|
| Vacant housing units | US Census Bureau, ACS tables B25002 (occupancy) and B25004 (vacancy status) | Tract (84,401 tracts, 50 states + DC) | 2020-2024 5-year, released Jan 29, 2026 | R `tidycensus::get_acs(year = 2024, survey = "acs5")`; Census API key (free) https://api.census.gov/data/key_signup.html; key is stored in the user's `.Renviron`, outside the project, and must never be committed | national_B25002_tract_2020-2024.csv; national_B25004_tract_2020-2024.csv; Michigan test files mi_*.csv | verified |
| Rent and population (Claim 1b) | ACS B25064_001 (median gross rent), B01003_001 (total population) | Tract | 2020-2024 5-year | `tidycensus` | national_B25064_B01003_tract_2020-2024.csv | verified. Rent missing for 5,116 of 84,401 tracts (no renter-occupied units). |
| Homelessness counts | HUD, 2025 AHAR Part 1, Point-in-Time (PIT) estimates, CoC-level workbook 2007-2025; January 2025 count, released May 29, 2026 | CoC | Annual (2025 sheet used) | https://www.huduser.gov/portal/datasets/ahar/2025-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html ; file https://www.huduser.gov/portal/sites/default/files/xls/2007-2025-PIT-Counts-by-CoC.xlsb | 2007-2025-PIT-Counts-by-CoC.xlsb (original, 8,859,426 bytes); .xlsx working copy; pit_2025_by_coc_clean.csv | verified |
| CoC boundaries | HUD Exchange, FY2025 national CoC geodatabase | CoC polygons (388 features) | FY2025 | https://www.hudexchange.info/programs/coc/gis-tools/ ; https://files.hudexchange.info/resources/documents/CoC_GIS_National_Boundary_2025.zip (30,414,787 bytes) | coc_boundaries/ (unzipped .gdb, layer FY25_CoC_National_Bnd, NAD83) | verified |
| Tract geometry | Census tract shapes via `tidycensus::get_acs(geometry = TRUE)` (tigris), 2024 vintage | Tract | 2024 | `tidycensus` | not saved (fetched each run) | verified |
| Tract-to-CoC assignment | Derived (largest area overlap, EPSG:5070) | Tract | n/a | scripts 04, 06 | national_tract_to_coc_assignment.csv; national_coc_vacancy_vs_pit.csv; national_coc_1b.csv | derived |
| Poverty rate (ACS B17001/B17020) | US Census Bureau | Tract | 2020-2024 | `tidycensus` | not pulled | dropped from v1: the claims do not need it |

**Rejected:** HomeSnacks "Vacant Homes by State" (homesnacks.com). Aggregator; its own figures disagree (15.3M vs 14M); restates Census numbers.

**Processing notes**
- PIT workbook: .xlsb cannot be read by `readxl`; converted to .xlsx in Excel (a VB project in the workbook was erased in conversion; the original .xlsb is kept). Sheet "2025" has 389 rows: 386 CoCs plus a Total row, a blank row and a footnote. One CoC ID carries a footnote letter (MO-604a, stored as MO-604). Cleaned table sums to 745,652, matching HUD's published total.
- 29 CoCs report "Sheltered-Only Count" (no unsheltered count); their homeless figures are lower bounds.
- HUD's boundary file has 388 CoCs; 386 have PIT rows. AS-500 and MP-500 have no PIT row. GU-500, PR-502, PR-503 and VI-500 have PIT rows (3,232 people) but no ACS tracts were pulled, so all five territory groups are excluded (Amendment 3).
- Vacancy definitions: broad = all vacant (B25004_001); narrow = for rent + for sale only + other vacant (B25004_002, _004, _008); strict = other vacant only.

**Checks run (all passed unless noted)**
- ACS vacant units: tract sums equal state totals for 50 of 51 units. New York is 709 units short, entirely in Suffolk County (36103); Census-side gap, reproduced on re-pull (Amendment 2). State totals sum to the U.S. total (14,547,859); tract sum is 14,547,150.
- ACS population: same pattern. New York is 77,579 people short, entirely in Suffolk County (-5.1% of the county), same 371 tracts (Amendment 4). Suffolk tracts are in NY-603. U.S. total 334,922,499; tract sum 334,844,920.
- B25004 total line equals B25002 vacant count in every tract.
- Tract assignment: 84,086 tracts assigned, 296 tracts have empty geometry (0 vacant units), 19 tracts with geometry matched no CoC (1,512 vacant units, 0.01%). 2,166 tracts (2.6%) hold under 90% of their area in the assigned CoC (863,546 vacant units, 5.9%). All 382 in-scope CoCs received tracts (Amendment 3).

**Known issues and caveats**
- Year and window mismatch: PIT is one night in January 2025; ACS is a 2020-2024 average. Not checked: whether a 2025 ACS 1-year release exists.
- ACS "vacant" is not "available": it includes seasonal/recreational (4,743,150 nationally), rented or sold but not occupied, and a large "other vacant" catch-all.
- Units vs. people: vacancy counts units; PIT counts people.
- PIT is a single-night snapshot, widely considered an undercount, and excludes people already in housing for formerly homeless people.
- ACS estimates carry margins of error; tract estimates are noisy. Margins of error were not propagated.
- CoC rent is an average of tract medians weighted by population, not a true CoC median.
- Alaska and Hawaii areas were computed in a US-wide equal-area projection (EPSG:5070); not tested against a local projection.
- HUD's press release for the 2025 report includes editorial framing. Only counts from the data workbook are used.

**Licence / terms**
- HUD: data.gov listing says "No license information was provided"; treated as a US Government Work. HUD Exchange page carries a no-warranty disclaimer. Credit HUD.
- Census: terms text not yet confirmed on census.gov. Credit US Census Bureau, American Community Survey.

---

## Map 2: Robots vs. hazardous work

Not vetted in this pass. All entries remain `unverified`.

| Layer | Source | Geography | Time coverage | Access | URL | Status |
|---|---|---|---|---|---|---|
| Mining footprints | Maus et al., global mining area polygons (Scientific Data) | Global polygons | Snapshot, with later update | Open data download | _TBD_ | unverified |
| Toxic chemical facilities (US) | EPA Toxics Release Inventory (TRI) | Facility points (lat/long) | Annual | EPA downloads / API | _TBD_ | unverified |
| Occupational fatalities (US) | BLS Census of Fatal Occupational Injuries (CFOI) | State and industry, **not point locations** | Annual | BLS downloads | _TBD_ | unverified |
| Ocean plastic | The Ocean Cleanup / Meijer et al. river plastic emissions model | River mouths, global | Modeled snapshot | Published with paper | _TBD_ | unverified |
| Robot density | International Federation of Robotics (IFR), World Robotics | Country | Annual | **Full data is largely paid; free summaries only** | _TBD_ | unverified |
| Data center locations | _No authoritative open global source identified yet_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ | unverified |

**Known issues:**
- IFR access may block the animated by-year version. Confirm what's free before committing.
- CFOI is aggregated, so hazard can't be shown as points the way TRI can.
- The claim blends chatbots (software) with robots (hardware). The map needs to decide which layer it actually measures.

---

## Series-level sources (cross-map)

| Layer | Source | Geography | Notes | Status |
|---|---|---|---|---|
| Global poverty | World Bank Poverty and Inequality Platform (PIP) | Country | Good for global poverty time series | unverified |
| Wealth/income inequality | World Inequality Database (WID) | Country | Good for the "hoarding" side of the poverty claim | unverified |
| Country boundaries | Eurostat GISCO (used in the France reference map) or Natural Earth | Global/European | Basemap geometry | unverified |
| Basemap context | OpenStreetMap | Global | Credit required | unverified |

---

## Adding a new source

| Layer | Source | Geography | Time coverage | Access | URL | Status |
|---|---|---|---|---|---|---|
| | | | | | | unverified |

Record for each source: date pulled, license/terms, and any known bias or undercount, so the final graphic can credit and caveat it properly.
