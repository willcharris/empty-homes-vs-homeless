# Map 1 spec: Are there more empty homes than homeless people?

Status: draft spec, 2026-10-13. Stance: advocate (the author's view, labeled as such). Finding and stance are kept separate.
Numbers marked [pull] are filled from `map1/data/national_coc_vacancy_vs_pit.csv`, `national_coc_1b.csv` and `national_coc_1c.csv`, never typed from memory.

## Verdicts this map rests on (from map1-results-log.md)
- Claim 1 (narrow vacant units outnumber homeless people): supported. National 8,665,393 vs 742,420 (11.7 to 1); true in 382 of 382 CoCs on point estimates (the pre-registered rule). Even the strictest definition (other vacant only, 5,223,171) is 7.0 to 1 nationally. The CoC table holds 8,664,169 narrow units; 1,224 sit in tracts that could not be placed in a CoC.
- Post-hoc sensitivity S1 (not pre-registered; does not change the verdict; 2026-10-13): with 90% margins of error (Census approximate method, ACS sampling error only), 381 of 382 CoCs still beat their homeless count at the low end. The exception is Lynn, MA (MA-502): 1,316 narrow units vs 1,271 homeless (1.04 to 1; range 0.81 to 1.27), too close to call.
- Spread: ratio ranges 1.04 to 231 across CoCs (median 18.5). 7 CoCs are under 2 to 1, 54 under 5 to 1, 116 under 10 to 1. The highest ratios are rural Balance-of-State regions (e.g. Mississippi BoS, 484 homeless vs 112,043 vacant units), where homelessness is hardest to count.
- Claim 1b (rent level and low vacancy track the homelessness rate): mixed. rho(rent) 0.28, rho(vacancy) -0.10. Rent falls just under the pre-registered 0.3 bar.
- Claim 1c (rent burden tracks the homelessness rate): mixed. rho 0.29, just under 0.3.
- Refinements tried after the mixed results: 1 (reported in the results log).

## Map type and unit
- Dot-density map, CoC geography (HUD Continuum of Care regions), 50 states + DC, 382 CoCs.
- Two layers with the SAME dot value so area and count compare honestly:
  - Amber dots: narrow vacant housing units (vacant for rent + vacant for sale + other vacant; seasonal/recreational excluded). ACS 2020-2024 5-year, tract tables, summed to CoC.
  - Cyan dots: people counted homeless on one night in January 2025. HUD AHAR Part 1 PIT counts by CoC.
- DECIDED: 1 dot = 100 (units or people), same for both layers. About 86,642 amber and 7,424 cyan dots. At 250, 56 CoCs would expect under one cyan dot (7 at 100), so 100 it is; the random rounding below handles those 7. Check legibility at 1080 px wide.
- Dot count per CoC = floor(n / 100) plus one extra dot with probability equal to the remainder / 100, fixed seed (set.seed(1)), so small CoCs are not rounded to nothing and the rule is reproducible.
- Placement (DECIDED 2026-10-13, replaces random-in-polygon): both layers placed inside the CoC's census tracts, each dot's tract drawn with probability proportional to the tract's total housing units (ACS B25002_001), then a random point inside that tract (sf::st_sample). Same rule for both layers. Dot position is modeled, NOT measured: vacancy is known by tract but homelessness only by CoC, so using real tract vacancy for one layer would give false precision to one side. Reason for changing: random placement inside a CoC polygon scatters dots across mountains and desert, which looks wrong and adds noise. Tract outlines: Census cartographic boundary tracts (tigris, 2023, 2020 geography, matching the ACS 2020-2024 tracts).
- Water check (2026-10-13, map1/15_water_check.R): 0.07% of total CoC area lies outside land (Census coast-clipped state outlines, 500k); 3 CoCs over 1% (VA-507 4.3%, MA-503 1.8%, CA-501 1.6%); none over 5%. Pre-set rule: no clipping needed. Tract-based placement makes this moot for dots anyway.
- Projection: EPSG:5070 (Albers equal area) for sampling and drawing, so dot density is not distorted by latitude. Alaska and Hawaii inset: decision needed at render time.

## Color logic (dark, glowing, additive blend)
- Background: near black (about #0B0F14); validator was run on #1a1a19, re-run on the final background before export.
- Vacant units: amber #C98500. Homeless people: cyan #1E96BA.
- Validator (dark mode, surface #1a1a19, all-pairs check): lightness band PASS, chroma PASS, color-vision separation PASS (protan delta E 19.7, tritan 24.2), normal vision PASS (24.9), contrast against surface PASS. The brighter amber/cyan I tried first failed the lightness band, so the base colors are mid-tone and the glow comes from additive blending and a soft halo.
- Overlap: where amber and cyan overlap the blend goes pale. Stated in the legend ("overlap = both").
- Colorblind safety does not rely on hue alone: the legend labels each layer by name and the live counts carry the numbers; cyan dots are drawn slightly larger and on top so the small layer stays visible.
- Restrained labels: no state names; only the title, the live-counts legend, and the footer.

## Title and first thing to notice
- Title (a question): "Are there more empty homes than homeless people?"
- Viewer should notice first: a sea of amber with a thin scatter of cyan, in every region, not just a few.
- The note that must be on the frame: "Dots are placed in proportion to housing within each region, not at actual locations."

## Animation (no real time series, so this is a reveal, not time)
- Label on frame: "Reveal order is a west-to-east sweep, not time."
- Vertical 1080 x 1920, 30 fps, about 20 s:
  - 0-2 s: title question.
  - 2-9 s: amber dots appear region by region (west to east by CoC centroid longitude); legend count ticks up toward 8,665,393.
  - 9-14 s: cyan dots appear the same way; count ticks toward 742,420.
  - 14-17 s: hold; show "11.7 to 1" and "7.0 to 1 even counting only the strictest definition".
  - 17-20 s: one-line limit ("These counts don't show the empty units could house these people.") and source credits.
- Live-counts legend (small, bottom left): vacant units, homeless people, ratio. 1 dot = 100.
- Possible future time dimension (unvetted): earlier-year PIT counts by CoC. That would be a separate claim.

## Accessible variant (required for some buyers)
- Static CoC choropleth of the narrow-vacant to homeless ratio (log scale, single-hue sequential, light to dark), direct labels on the 3 lowest ratios (Lynn MA-502 at 1.04; Portland/Multnomah OR-501 at 1.54; Central Oregon OR-503 at 1.55) and 3 highest (Mississippi BoS MS-501 at 231; Southeast Arkansas AR-505 at 211; Lynchburg VA-508 at 181), plus a data table in the methodology note. Oklahoma BoS (OK-503, 192) is skipped as a label because it is a sheltered-only count, which overstates its ratio.
- Alt text for every slide (drafts below).
- Light-background version of the dot map for print and low-contrast screens.

## Instagram carousel (5 slides) - claim-to-map step 10
1. Claim as a question: "Are there more empty homes than homeless people?" One line: "One claim says yes. I tested it."
2. The map (dot-density, still frame at the end of the reveal).
3. The surprise, which is the complication to my own side: rents and rent burden line up only loosely with homelessness across regions (rank correlations 0.28 and 0.29, both below my 0.3 bar). [Add the 1b/1c scatter once drawn.] Shortage-of-buildings is not what this shows; neither is price. The data shows a mismatch, not a cause.
4. Limits (as prominent as findings): in one region (Lynn, MA) the counts are too close to call, and in 6 more the margin is under 2 to 1; the thickest amber is in rural regions where homelessness is hardest to count and vacant units may be unlivable, so the map may look more lopsided there than reality; the units may be in the wrong place, in poor condition or unaffordable; homeless count is one night in January and an undercount; vacancy is a 2020-2024 survey average; estimates have margins of error that were not carried through; 19 tracts could not be placed in a region; Suffolk County NY has known gaps in three ACS tables; territories excluded (3,232 people counted).
5. Sources and method: ACS 2020-2024 5-year (B25002, B25004, B25064, B01003, B25070), HUD 2025 AHAR Part 1 PIT counts, HUD FY2025 CoC boundaries; pulled 2026-10-13; code and pre-registration in the repo [link when public].

## Caption (stance labeled as the author's view)
Are there more empty homes than homeless people? One claim says yes. Counting only units that are for rent, for sale, or vacant for other reasons (not seasonal homes), the U.S. has about 8.7 million vacant units and about 742,000 people counted homeless in January 2025. In 381 of the 382 regions I tested, vacant units outnumber the people even after allowing for survey error. In one (Lynn, Massachusetts) it is too close to call, and the gap varies from about 1 to 1 to over 200 to 1.

What this can't show: that those units could house those people. They may be in the wrong place, in poor condition, or too expensive. And rents and rent burden only loosely track homelessness across regions (rank correlation 0.28 and 0.29, under the 0.3 bar I set before looking).

My view (advocate): price and policy, not a lack of buildings, is the main barrier. That is my reading, not something this map proves.

Dots are placed in proportion to housing within each region, not at actual locations. Sources: U.S. Census Bureau ACS 2020-2024; HUD 2025 AHAR Part 1; HUD CoC boundaries. Method and limits in the link in bio.

## Corrections-log line
[publish date]: Map 1 published. Data pulled 2026-10-13. Pre-registration amendments 1-5 are listed in the repo. No corrections to date.

## Done so far
- Slide 3 figure: map1/out/scatter_1b_1c.png (14_scatter_plots.R), committed.
- Water check (15_water_check.R), committed.

## Still to write
- Dot generation (16_make_dots.R), then the render (static still first, then animation frames).
- Log sensitivity S1 in map1-results-log.md; add the survey-error limit to the methodology note.
- Methodology note (datasets, years, steps, limits), built from map1-results-log.md and the five amendments.
- Alt text, final versions.
- Render scripts (13_render_*.R), then a check of Instagram specs before export.

## Instagram specs checked 2026-10-13 (one secondary source; re-verify on Instagram's own help pages before export)
- Reels: 9:16, 1080 x 1920, at least 30 fps, MP4 or MOV, H.264/AAC. Source page contradicts itself on max file size, so confirm.
- Carousel: up to 10 slides; 1:1 (1080 x 1080), 4:5 (1080 x 1350) or 1.91:1. Use 4:5 for stills.
- Source: https://www.socialpilot.co/blog/instagram-video-size (published 2025-12-04)
