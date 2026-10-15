# Map 1 spec: Are there more empty homes than homeless people?

Status: built 2026-10-14 (still, 20 s video, 5-slide carousel, methodology note). Waiting on: repo made public, Instagram format check on Instagram's own pages, final caption approved. Stance: advocate (the author's view, labeled as such). Finding and stance are kept separate.
Numbers come from `map1/data/national_coc_vacancy_vs_pit.csv`, `national_coc_1b.csv` and `national_coc_1c.csv` and the results log, never typed from memory.

## Verdicts this map rests on (from map1-results-log.md)
- Claim 1 (narrow vacant units outnumber homeless people): supported. National 8,665,393 vs 742,420 (11.7 to 1); true in 382 of 382 CoCs on point estimates (the pre-registered rule). Even the strictest definition (other vacant only, 5,223,171) is 7.0 to 1 nationally. The CoC table holds 8,664,169 narrow units; 1,224 sit in tracts that could not be placed in a CoC (19 tracts). The legend shows 8,664,169 (the units that could be placed); the headline ratio and caption use the national 8,665,393.
- Post-hoc sensitivity S1 (not pre-registered; does not change the verdict; 2026-10-13): with 90% margins of error (Census approximate method, ACS sampling error only), 381 of 382 CoCs still beat their homeless count at the low end. The exception is Lynn, MA (MA-502): 1,316 narrow units vs 1,271 homeless (1.04 to 1; range 0.81 to 1.27), too close to call.
- Pre-registered ACS 2024 1-year national check (run late, 2026-10-14): 8,566,020 narrow vacant units (+/- 85,398), 11.5 to 1, vs 8,665,393 and 11.7 to 1 from the 5-year data (-1.1%). Same conclusion.
- Spread: ratio ranges 1.04 to 231 across CoCs (median 18.5). 7 CoCs are under 2 to 1, 54 under 5 to 1, 116 under 10 to 1. The highest ratios are rural Balance-of-State regions (e.g. Mississippi BoS, 484 homeless vs 112,043 vacant units), where homelessness is hardest to count.
- Claim 1b (rent level and low vacancy track the homelessness rate): mixed. rho(rent) 0.28, rho(vacancy) -0.10. Rent falls just under the pre-registered 0.3 bar.
- Claim 1c (rent burden tracks the homelessness rate): mixed. rho 0.29, just under 0.3.
- Refinements tried after the mixed results: 1 (reported in the results log).
- Data currency (checked 2026-10-14): HUD's 2025 report is the latest national count; Census had not announced the 2025 ACS 1-year date (advisory of 2026-08-04) or any 2021-2025 5-year date. Rerun Map 1 when both arrive (separate, labeled claim if it adds a time comparison).

## Map type and unit (built)
- Dot-density map, CoC geography (HUD Continuum of Care regions), 50 states + DC, 382 CoCs.
- Two layers with the SAME dot value so area and count compare honestly:
  - Amber dots: narrow vacant housing units (vacant for rent + vacant for sale + other vacant; seasonal/recreational excluded). ACS 2020-2024 5-year, tract tables, summed to CoC.
  - Cyan dots: people counted homeless on one night in January 2025. HUD AHAR Part 1 PIT counts by CoC.
- 1 dot = 100 (units or people), same for both layers. Built: 86,642 amber and 7,414 cyan dots (94,056).
- Dot count per CoC = floor(n / 100) plus one extra dot with probability equal to the remainder / 100, fixed seed (set.seed(1)).
- Placement: both layers placed inside the CoC's census tracts, each dot's tract drawn with probability proportional to total housing units (ACS B25002_001), then a random point inside that tract. Same rule for both layers. Dot position is modeled, NOT measured. Tract outlines: Census cartographic boundary tracts (tigris, 2023).
- Water check (15_water_check.R): 0.07% of total CoC area outside land; none over 5%; no clipping needed.
- Projection: EPSG:5070 (Albers equal area). Alaska inset at 35% scale (EPSG:3338); Hawaii at full scale (Albers Hawaii).

## Final render decisions (still v3, locked 2026-10-14)
- Canvas 1080 x 1350 (4:5). Background #0B0F14. Amber #C98500, cyan #1E96BA.
- Equal ink per dot for both layers: core sigma 0.9 px, halo sigma 3.5 px at weight 0.08, gain 0.8. Cyan composited on top of amber so each cyan dot stays visible.
- Rejected: an earlier version with cyan larger and brighter. It made metros look mostly homeless and distorted the 11.7 to 1 ratio.
- Colors: validator (dark mode, surface #1a1a19) passed lightness, chroma, normal vision and color-vision separation (protan delta E 19.7, tritan 24.2). Not re-run on #0B0F14; the methodology note cites #1a1a19. Legend names each layer and carries live counts, so meaning does not rest on color alone.
- Frame text: title question, subtitle, legend with counts, "11.7 to 1 | 1 dot = 100", the placement note, Alaska scale note, sources.

## Animation (built; no real time series, so this is a reveal, not time)
- DECIDED 2026-10-14: no west-to-east sweep. Each layer fades in as a whole. The sweep could read as spread over time and added complexity for little gain; revisit only if the video feels flat.
- map1/out/map1_reveal.mp4: 1080 x 1920, 30 fps, 20 s (600 frames), H.264, yuv420p, bt709, CRF 16, 2.4 MB. Script 18_render_frames.R (resumable; frees memory every 5 frames).
  - 0-2 s: title; outlines fade in from 1 s.
  - 2-9 s: amber layer fades in; vacant-unit count ticks up to 8,664,169.
  - 9-14 s: cyan layer fades in; homeless count ticks up to 742,420.
  - 14-17 s: hold; "11.7 to 1 | 1 dot = 100" and "7.0 to 1 even counting only the strictest definition".
  - 17-20 s: "These counts don't show that the empty units could house these people."
- On-frame note: "Layers fade in for effect; this is not a time series." Key text kept above the bottom ~340 px (Reels interface zone).

## Accessible variant (not yet built; build after posting)
- Static CoC choropleth of the narrow-vacant to homeless ratio (log scale, single-hue sequential, light to dark), direct labels on the 3 lowest ratios (Lynn MA-502 at 1.04; Portland/Multnomah OR-501 at 1.54; Central Oregon OR-503 at 1.55) and 3 highest (Mississippi BoS MS-501 at 231; Southeast Arkansas AR-505 at 211; Lynchburg VA-508 at 181), plus a data table in the methodology note. Oklahoma BoS (OK-503, 192) is skipped as a label because it is a sheltered-only count, which overstates its ratio.
- Light-background version of the dot map for print and low-contrast screens.

## Instagram carousel (built; map1/out/carousel_1 to 5, script 19_render_carousel.R)
1. "Are there more empty homes than homeless people?" / "One claim says yes. I tested it."
2. The locked still.
3. "Where rents are higher, homelessness tends to be higher, but only loosely." Three dark scatter panels (median rent 0.28; renters paying 30%+ 0.29; vacancy rate -0.10), people counted homeless per 10,000 residents on a log axis. Text: "That doesn't clearly support my own view that price is the main barrier. The map shows a mismatch, not a cause." (Headline wording settled 2026-10-14: "slightly" and "even higher" rejected as claims about size the data does not give.)
4. "What this can't show": Lynn too close to call and six more regions under 2 to 1; highest ratios are rural where homelessness is hardest to count; units may be in the wrong place, in poor condition or unaffordable; one-night January undercount; vacancy is a 2020-2024 average and survey error was allowed for after the fact (381 of 382 hold); dots show 8,664,169 placed units vs the 8,665,393 national total and positions are modeled; territories excluded and Suffolk County NY gaps.
5. "Sources and method": ACS tables, HUD report and boundaries, how drawn, pulled 2026-10-13, test written before looking with five amendments, "My view (advocate)" block, "Code, pre-registration and method note: link in bio." (true only once the repo is public), and the Census API notice.

## Alt text (Instagram, each under 100 characters; confirm the cap on Instagram's pages)
1. Title card: Are there more empty homes than homeless people? One claim says yes. I tested it.
2. US dot map: amber dots for 8.7M vacant homes far outnumber cyan dots for 742,000 homeless people.
3. Three scatter plots: rent and rent burden track homelessness rates only loosely; vacancy barely.
4. Limits slide: close calls, rural undercounts, unusable units, a one-night count, survey error.
5. Text slide listing data sources, how the dots are drawn, and the author's stated view.
Video. Vertical animation: amber dots fade in across a US map, then cyan dots, ending on 11.7 to 1.
Longer description for the method note (slide 2): "Dot-density map of the United States. Each amber dot is 100 vacant housing units and each cyan dot is 100 people counted homeless in January 2025. Amber dots cover most of the country and outnumber cyan dots about 11.7 to 1. Cyan dots cluster in large metros, especially the West Coast and Northeast."

## Caption (stance labeled as the author's view; draft for approval)
Are there more empty homes than homeless people? One claim says yes. Counting only units that are for rent, for sale, or vacant for other reasons (not seasonal homes), the U.S. has about 8.7 million vacant units and about 742,000 people counted homeless in January 2025, roughly 11.7 to 1. In 381 of the 382 regions I tested, vacant units still outnumber the people after allowing for survey error (a check I added after the main test). In one (Lynn, Massachusetts) it is too close to call, and the gap varies from about 1 to 1 to over 200 to 1.

What this can't show: that those units could house those people. They may be in the wrong place, in poor condition, or too expensive. And rents and rent burden only loosely track homelessness across regions (rank correlation 0.28 and 0.29, under the 0.3 bar I set before looking).

My view (advocate): price and policy, not a lack of buildings, is the main barrier. That is my reading, not something this map proves.

Dots are placed in proportion to housing within each region, not at actual locations, and the video fades the layers in for effect; it is not a time series. Sources: U.S. Census Bureau ACS 2020-2024; HUD 2025 AHAR Part 1; HUD CoC boundaries. Method, limits and code: link in bio.
This product uses the Census Bureau Data API but is not endorsed or certified by the Census Bureau.

## Corrections log
- [publish date]: Map 1 published. Data pulled 2026-10-13. Pre-registration amendments 1-5 are listed in the repo. No corrections since publication.
- 2026-10-13 (before publication): earlier national comparison paired 50-state-plus-DC vacancy with HUD's 745,652 (includes territories); corrected to 742,420 (Amendment 3).

## Still to do
- Make the repo public (so "link in bio" is true), then set the bio link.
- Verify Instagram specs on Instagram's own pages (Reels size, frame rate, file size, alt-text length, caption length) and finalize the caption.
- Optional before posting: re-run the palette validator on #0B0F14.
- After posting: accessible ratio choropleth, light-background map, README for the repo, rerun when new ACS and HUD data arrive.

## Instagram specs checked 2026-10-13 (one secondary source; re-verify on Instagram's own help pages before export)
- Reels: 9:16, 1080 x 1920, at least 30 fps, MP4 or MOV, H.264/AAC. Source page contradicts itself on max file size, so confirm.
- Carousel: up to 10 slides; 1:1 (1080 x 1080), 4:5 (1080 x 1350) or 1.91:1. Use 4:5 for stills.
- Source: https://www.socialpilot.co/blog/instagram-video-size (published 2025-12-04)
