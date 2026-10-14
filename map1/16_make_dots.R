# 16_make_dots.R
# Generate the dots for Map 1 (1 dot = 100 units or people, same for both layers).
# Placement rule (spec, decided 2026-10-13): within each CoC, each dot's tract is drawn
# with probability proportional to total housing units (B25002_001); the dot is then a
# random point inside that tract. Same rule for both layers. Position is MODELED.
# Dot counts per CoC = floor(n/100) plus one extra dot with probability (n mod 100)/100.
# Fixed seed; run from the project root. Slow step: sampling points (several minutes).

library(tidyverse); library(sf); library(tigris)
options(tigris_use_cache = TRUE)
set.seed(1)
UNIT <- 100

asg <- read_csv("map1/data/national_tract_to_coc_assignment.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE) |>
  select(GEOID, COCNUM)
occ <- read_csv("map1/data/national_B25002_tract_2020-2024.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE) |>
  filter(variable == "B25002_001") |> select(GEOID, units = estimate)
v <- read_csv("map1/data/national_coc_vacancy_vs_pit.csv", show_col_types = FALSE) |>
  select(COCNUM, homeless, narrow)
stopifnot(nrow(v) == 382, sum(v$homeless) == 742420)

tr_w <- asg |> left_join(occ, by = "GEOID")
stopifnot(!anyNA(tr_w$units), all(v$COCNUM %in% tr_w$COCNUM))

# ---- Tract outlines (Census cartographic boundary, 2020 geography) ----
cat("Downloading tract outlines for 50 states + DC (first run takes a few minutes)...\n")
tr_geo <- map(c(state.abb, "DC"), \(st) {
  tracts(state = st, cb = TRUE, year = 2023, progress_bar = FALSE) |> select(GEOID)
}) |> bind_rows() |> st_transform(5070) |> st_make_valid()

miss <- anti_join(tr_w, st_drop_geometry(tr_geo), by = "GEOID")
cat("Assigned tracts without an outline:", nrow(miss),
    "| housing units in them:", sum(miss$units), "of", sum(tr_w$units), "\n")
stopifnot(sum(miss$units) < 0.001 * sum(tr_w$units))

tr <- tr_geo |> inner_join(tr_w, by = "GEOID") |> filter(units > 0)
tw_by <- tr |> st_drop_geometry() |> select(GEOID, COCNUM, units) |> split(~ COCNUM)

# ---- Dot counts per CoC ----
round_dots <- function(n) floor(n / UNIT) + (runif(length(n)) < (n %% UNIT) / UNIT)
counts <- v |> arrange(COCNUM) |>
  mutate(amber_n = round_dots(narrow), cyan_n = round_dots(homeless))
cat("Amber dots:", sum(counts$amber_n), "(expected about", round(sum(v$narrow) / UNIT), ")\n")
cat("Cyan dots: ", sum(counts$cyan_n),  "(expected about", round(sum(v$homeless) / UNIT), ")\n")
stopifnot(abs(sum(counts$amber_n) - sum(v$narrow) / UNIT) < 0.01 * sum(v$narrow) / UNIT,
          abs(sum(counts$cyan_n)  - sum(v$homeless) / UNIT) < 0.01 * sum(v$homeless) / UNIT)

# ---- Place the dots ----
make_layer <- function(k_vec, layer) {
  alloc <- map2_dfr(counts$COCNUM, k_vec, \(coc, k) {
    if (k == 0) return(NULL)
    t <- tw_by[[coc]]
    idx <- sample.int(nrow(t), size = k, replace = TRUE, prob = t$units)
    tab <- table(idx)
    tibble(GEOID = t$GEOID[as.integer(names(tab))], COCNUM = coc, k = as.integer(tab))
  })
  g <- st_geometry(tr)[match(alloc$GEOID, tr$GEOID)]
  cat("Sampling", sum(alloc$k), layer, "dots in", nrow(alloc), "tracts...\n")
  pts <- st_sample(g, size = alloc$k, type = "random")
  xy <- st_coordinates(pts)
  stopifnot(nrow(xy) == sum(alloc$k))
  tibble(x = xy[, 1], y = xy[, 2], layer = layer,
         COCNUM = rep(alloc$COCNUM, alloc$k), GEOID = rep(alloc$GEOID, alloc$k))
}

dots <- bind_rows(make_layer(counts$amber_n, "vacant"),
                  make_layer(counts$cyan_n,  "homeless"))

# ---- Integrity check: 2,000 random dots must lie inside their own tract ----
chk <- slice_sample(dots, n = 2000)
inside <- map_lgl(seq_len(nrow(chk)), \(i) {
  pt <- st_sfc(st_point(c(chk$x[i], chk$y[i])), crs = 5070)
  lengths(st_intersects(pt, st_geometry(tr)[match(chk$GEOID[i], tr$GEOID)])) > 0
})
cat("Spot check: dots inside their tract:", sum(inside), "of 2000\n")
stopifnot(all(inside))

write_csv(dots, "map1/data/dots_unit100.csv")
cat("\nDots by layer:\n"); print(count(dots, layer))
cat("Saved map1/data/dots_unit100.csv (x, y in EPSG:5070). Date run:", format(Sys.Date()), "\n")