# 15_water_check.R
# Do HUD CoC polygons extend into water? Measures the share of each CoC's area that
# lies outside land (Census coast-clipped state outlines, 500k). Measure only.
# Pre-set rule (written before running): no clipping needed if < 1% of total CoC area
# is outside land AND no CoC has > 5% outside; otherwise clip dots to land.
# Slow step: the intersection (may take a few minutes). Run from the project root.

library(tidyverse); library(sf); library(tigris)
options(tigris_use_cache = TRUE)

gdb <- "map1/data/coc_boundaries/CoC_GIS_National_Boundary_2025/CoC_GIS_National_Boundary.gdb"
coc <- st_read(gdb, layer = "FY25_CoC_National_Bnd", quiet = TRUE) |>
  filter(!str_detect(COCNUM, "^(AS|GU|MP|PR|VI)-")) |>
  select(COCNUM) |> st_transform(5070) |> st_make_valid()
stopifnot(nrow(coc) == 382)

land <- states(cb = TRUE, resolution = "500k", year = 2023, progress_bar = FALSE) |>
  filter(STUSPS %in% c(state.abb, "DC")) |>
  st_transform(5070) |> st_make_valid() |> st_union() |> st_make_valid()

coc$area_coc <- as.numeric(st_area(coc))

cat("Intersecting CoCs with land (be patient)...\n")
inter <- suppressWarnings(st_intersection(coc, land))
inter$area_land <- as.numeric(st_area(inter))

res <- coc |> st_drop_geometry() |>
  left_join(inter |> st_drop_geometry() |> group_by(COCNUM) |>
              summarise(area_land = sum(area_land), .groups = "drop"),
            by = "COCNUM") |>
  mutate(area_land = replace_na(area_land, 0),
         outside_share = pmax(0, 1 - area_land / area_coc))

cat("\nTotal CoC area outside land:",
    round(100 * (1 - sum(res$area_land) / sum(res$area_coc)), 2), "%\n")
cat("CoCs with > 1% outside:", sum(res$outside_share > 0.01),
    "| > 5% outside:", sum(res$outside_share > 0.05),
    "| > 25% outside:", sum(res$outside_share > 0.25), "\n")

cat("\nShare outside land, across 382 CoCs:\n")
print(summary(res$outside_share))

cat("\nTop 10 CoCs by share outside land:\n")
print(res |> arrange(desc(outside_share)) |>
        transmute(COCNUM, outside_pct = round(100 * outside_share, 1),
                  area_km2 = round(area_coc / 1e6)) |> head(10))

write_csv(res, "map1/data/coc_water_check.csv")
cat("Date run:", format(Sys.Date()), "\n")