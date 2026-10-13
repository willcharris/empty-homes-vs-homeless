# 04_michigan_join.R
# Michigan test: assign ACS tracts to HUD CoCs by largest overlap, then
# build a CoC-level vacancy vs. PIT table. PIPELINE CHECK ONLY: the Map 1
# verdict comes from the national run, per map1-preregistration.md.
# Run from the project root ("Empty homes vs homeless claim map").

library(tidycensus); library(tidyverse); library(sf)
options(tigris_use_cache = TRUE)

stopifnot(file.exists("map1/data/pit_2025_by_coc_clean.csv"))   # wrong folder? stop

# ---- 1. Inputs (all from saved files, except tract shapes) ----
gdb <- "map1/data/coc_boundaries/CoC_GIS_National_Boundary_2025/CoC_GIS_National_Boundary.gdb"
coc <- st_read(gdb, layer = "FY25_CoC_National_Bnd", quiet = TRUE)

pit <- read_csv("map1/data/pit_2025_by_coc_clean.csv", show_col_types = FALSE)
mi_vac <- read_csv("map1/data/mi_B25004_tract_2020-2024.csv",
                   col_types = cols(GEOID = col_character()))   # keep GEOID as text

stopifnot(nrow(pit) == 386, sum(pit$`Overall Homeless`) == 745652)   # ties to HUD

# ---- 2. Michigan tracts with geometry ----
mi_tracts <- get_acs(geography = "tract", state = "MI", variables = "B25002_003",
                     year = 2024, survey = "acs5", geometry = TRUE)
stopifnot(nrow(mi_tracts) == 3017, sum(mi_tracts$estimate) == 545867)

# ---- 3. Assign each tract to the CoC with the largest area overlap ----
# Project to an equal-area CRS (EPSG:5070) so areas are real areas, not degrees.
tr <- mi_tracts |> filter(!st_is_empty(geometry)) |> st_transform(5070) |> st_make_valid()
cm <- coc |> filter(ST == "MI") |> st_transform(5070) |> st_make_valid()

ov <- st_intersection(tr[, c("GEOID", "estimate")], cm[, "COCNUM"])
ov$a <- as.numeric(st_area(ov))

best <- ov |> st_drop_geometry() |>
  group_by(GEOID) |> slice_max(a, n = 1, with_ties = FALSE) |> ungroup()

stopifnot(nrow(best) == 2971,
          length(setdiff(tr$GEOID, best$GEOID)) == 0,   # every tract matched
          sum(best$estimate) == 545867)                 # no units lost

# ---- 4. Diagnostics: how much of each tract is in its assigned CoC ----
tr$tract_area <- as.numeric(st_area(tr))
best2 <- best |>
  left_join(st_drop_geometry(tr)[, c("GEOID", "tract_area")], by = "GEOID") |>
  mutate(share = a / tract_area)
summary(best2$share)
sum(best2$share < 0.9)                       # tracts under 90% in one CoC
sum(best2$estimate[best2$share < 0.9])       # vacant units in those tracts

# ---- 5. CoC-level table: vacancy under three definitions vs PIT ----
mi_vac_w <- mi_vac |> select(GEOID, variable, estimate) |>
  pivot_wider(names_from = variable, values_from = estimate)

mi_coc <- best |> select(GEOID, COCNUM) |>
  inner_join(mi_vac_w, by = "GEOID") |>
  group_by(COCNUM) |>
  summarise(broad  = sum(B25004_001),
            narrow = sum(B25004_002 + B25004_004 + B25004_008),  # rent + sale + other
            strict = sum(B25004_008),                            # other vacant only
            .groups = "drop") |>
  left_join(pit |> select(COCNUM = coc_id, homeless = `Overall Homeless`,
                          count_type = `Count Types`), by = "COCNUM") |>
  mutate(ratio_narrow = round(narrow / homeless, 1))

stopifnot(sum(mi_coc$broad) == 545867)
sum(mi_coc$homeless)
print(mi_coc, n = Inf)

write_csv(mi_coc, "map1/data/mi_coc_vacancy_vs_pit.csv")