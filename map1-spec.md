# Map 1 spec: Are there more empty homes than homeless people?

Status: draft spec, 2026-10-13. Stance: advocate (the author's view, labeled as such). Finding and stance are kept separate.
Numbers marked [pull] are filled from `map1/data/national_coc_vacancy_vs_pit.csv`, `national_coc_1b.csv` and `national_coc_1c.csv`, never typed from memory.

## Verdicts this map rests on (from map1-results-log.md)
- Claim 1 (narrow vacant units outnumber homeless people): supported. National 8,665,393 vs 742,420 (11.7 to 1); true in 382 of 382 CoCs. Even the strictest definition (other vacant only, 5,223,171) is 7.0 to 1 nationally.
- Claim 1b (rent level and low vacancy track the homelessness rate): mixed. rho(rent) 0.28, rho(vacancy) -0.10. Rent falls just under the pre-registered 0.3 bar.
- Claim 1c (rent burden tracks the homelessness rate): mixed. rho 0.29, just under 0.3.
- Refinements tried after the mixed results: 1 (reported in the results log).

## Map type and unit
- Dot-density map, CoC geography (HUD Continuum of Care regions), 50 states + DC, 382 CoCs.
- Two layers with the SAME dot value so area and count compare honestly:
  - Amber dots: narrow vacant housing units (vacant for rent + vacant for sale + other vacant; seasonal/recreational excluded). ACS 2020-2024 5-year, tract tables, summed to CoC.
  - Cyan dots: people counted homeless on one night in January 2025. HUD AHAR Part 1 PIT counts by CoC.
- 1 dot = 100 (units or people). Expected about 86,654 amber and 7,424 cyan dots. Check legibility at 1080 px wide; if too dense, 1 dot = 250 for both layers.
- Dot count per CoC = floor(n / 100) plus one extra dot with probability equal to the remainder / 100, fixed seed (set.seed(1)), so small CoCs are not rounded to nothing and the rule is reproducible.
- Placement: both layers placed at random inside the same CoC polygon (sf::st_sample). Location inside a CoC is NOT data. This matters most for large "balance of state" CoCs. It is stated on the map. Vacancy is known by tract and homelessness only by CoC, so tract-level placement for one layer only would give false precision to one side; random placement treats both the same.
- Check before rendering: confirm CoC polygons are clipped to land (HUD boundaries may include water); clip with a land layer if they do.
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
- The note that must be on the frame: "Dots are placed at random inside each region. Position within a region is not data."

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
- Static CoC choropleth of the narrow-vacant to homeless ratio (log scale, single-hue sequential, light to dark), direct labels on the 3 lowest and 3 highest ratios [pull], plus a data table in the methodology note.
- Alt text for every slide (drafts below).
- Light-background version of the dot map for print and low-contrast screens.

## Instagram carousel (5 slides) - claim-to-map step 10
1. Claim as a question: "Are there more empty homes than homeless people?" One line: "One claim says yes. I tested it."
2. The map (dot-density, still frame at the end of the reveal).
3. The surprise, which is the complication to my own side: rents and rent burden line up only loosely with homelessness across regions (rank correlations 0.28 and 0.29, both below my 0.3 bar). [Add the 1b/1c scatter once drawn.] Shortage-of-buildings is not what this shows; neither is price. The data shows a mismatch, not a cause.
4. Limits (as prominent as findings): the units may be in the wrong place, in poor condition or unaffordable; homeless count is one night in January and an undercount; vacancy is a 2020-2024 survey average; estimates have margins of error that were not carried through; 19 tracts could not be placed in a region; Suffolk County NY has known gaps in three ACS tables; territories excluded (3,232 people counted).
5. Sources and method: ACS 2020-2024 5-year (B25002, B25004, B25064, B01003, B25070), HUD 2025 AHAR Part 1 PIT counts, HUD FY2025 CoC boundaries; pulled 2026-10-13; code and pre-registration in the repo [link when public].

## Caption (stance labeled as the author's view)
Are there more empty homes than homeless people? One claim says yes. Counting only units that are for rent, for sale, or vacant for other reasons (not seasonal homes), the U.S. has about 8.7 million vacant units and about 742,000 people counted homeless in January 2025. The vacant units outnumber the people in all 382 regions I tested.

What this can't show: that those units could house those people. They may be in the wrong place, in poor condition, or too expensive. And rents and rent burden only loosely track homelessness across regions (rank correlation 0.28 and 0.29, under the 0.3 bar I set before looking).

My view (advocate): price and policy, not a lack of buildings, is the main barrier. That is my reading, not something this map proves.

Dots are placed at random inside each region. Sources: U.S. Census Bureau ACS 2020-2024; HUD 2025 AHAR Part 1; HUD CoC boundaries. Method and limits in the link in bio.

## Corrections-log line
[publish date]: Map 1 published. Data pulled 2026-10-13. Pre-registration amendments 1-5 are listed in the repo. No corrections to date.

## Still to write
- Methodology note (datasets, years, steps, limits), built from map1-results-log.md and the five amendments.
- Alt text, final versions.
- Render scripts (13_render_*.R), then a check of Instagram specs before export.

## Instagram specs checked 2026-10-13 (one secondary source; re-verify on Instagram's own help pages before export)
- Reels: 9:16, 1080 x 1920, at least 30 fps, MP4 or MOV, H.264/AAC. Source page contradicts itself on max file size, so confirm.
- Carousel: up to 10 slides; 1:1 (1080 x 1080), 4:5 (1080 x 1350) or 1.91:1. Use 4:5 for stills.
- Source: https://www.socialpilot.co/blog/instagram-video-size (published 2025-12-04)
