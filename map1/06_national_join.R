# 06_national_join.R
# Assign every tract (50 states + DC) to the HUD CoC with the largest area overlap
# (Amendment 1), aggregate vacancy to CoCs, join PIT 2025, print the pre-registered
# summary statistics. Run from the project root. Needs 05_pull_national.R outputs.
# NOT yet run end to end. Slow step: st_intersection, state by state.

library(tidycensus); library(tidyverse); library(sf)
options(tigris_use_cache = TRUE)

stopifnot(file.exists("map1/data/national_B25004_tract_2020-2024.csv"),
          file.exists("map1/data/pit_2025_by_coc_clean.csv"))

# ---- Inputs ----
gdb <- "map1/data/coc_boundaries/CoC_GIS_National_Boundary_2025/CoC_GIS_National_Boundary.gdb"
coc <- st_read(gdb, layer = "FY25_CoC_National_Bnd", quiet = TRUE) |>
  # Scope = 50 states + DC (Amendment 3). Territories (AS, GU, MP, PR, VI) excluded:
  # no ACS tracts pulled for them.
  filter(!str_detect(COCNUM, "^(AS|GU|MP|PR|VI)-")) |>
  select(COCNUM) |> st_transform(5070) |> st_make_valid()
stopifnot(nrow(coc) == 382)

pit_all <- read_csv("map1/data/pit_2025_by_coc_clean.csv", show_col_types = FALSE)
stopifnot(nrow(pit_all) == 386, sum(pit_all$`Overall Homeless`) == 745652)  # ties to HUD
pit <- pit_all |> filter(!str_detect(coc_id, "^(AS|GU|MP|PR|VI)-"))
stopifnot(nrow(pit) == 382, sum(pit$`Overall Homeless`) == 745652 - 3232)  # 742,420

vac <- read_csv("map1/data/national_B25004_tract_2020-2024.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE)

states <- c(state.abb, "DC")

# ---- Assign one state's tracts ----
assign_state <- function(st) {
  tr <- get_acs(geography = "tract", state = st, variables = "B25002_003",
                year = 2024, survey = "acs5", geometry = TRUE, progress_bar = FALSE) |>
    select(GEOID, estimate)
  empty <- tr |> filter(st_is_empty(geometry)) |> st_drop_geometry()
  tr <- tr |> filter(!st_is_empty(geometry)) |> st_transform(5070) |> st_make_valid()

  # CoCs near this state (any CoC touching the state's bounding box), so
  # CoCs that cross state lines are included
  box <- st_as_sfc(st_bbox(tr))
  cm <- coc[lengths(st_intersects(coc, box)) > 0, ]

  ov <- suppressWarnings(st_intersection(tr, cm))
  ov$a <- as.numeric(st_area(ov))
  tr$tract_area <- as.numeric(st_area(tr))

  best <- ov |> st_drop_geometry() |>
    group_by(GEOID) |> slice_max(a, n = 1, with_ties = FALSE) |> ungroup() |>
    left_join(st_drop_geometry(tr)[, c("GEOID", "tract_area")], by = "GEOID") |>
    mutate(share = a / tract_area, state = st) |>
    select(state, GEOID, COCNUM, estimate, share)

  unmatched <- tr |> st_drop_geometry() |> filter(!GEOID %in% best$GEOID) |>
    mutate(state = st) |> select(state, GEOID, estimate)

  list(best = best, unmatched = unmatched, empty = empty, n_tr = nrow(tr))
}

# ---- Loop over states ----
res <- list(); failed <- character()
for (st in states) {
  r <- tryCatch(assign_state(st), error = function(e) { message("ERROR ", st, ": ", conditionMessage(e)); NULL })
  if (is.null(r)) { failed <- c(failed, st); next }
  res[[st]] <- r
  message("done: ", st, " (", r$n_tr, " tracts, ",
          nrow(r$unmatched), " unmatched)")
}
for (st in failed) {                      # retry once
  r <- tryCatch(assign_state(st), error = function(e) NULL)
  if (!is.null(r)) { res[[st]] <- r; failed <- setdiff(failed, st) }
}
stopifnot(length(failed) == 0)

asg <- map_dfr(res, "best")
unm <- map_dfr(res, "unmatched")
emp <- map_dfr(res, "empty")

write_csv(asg, "map1/data/national_tract_to_coc_assignment.csv")

# ---- Checks on the assignment ----
cat("\nAssigned tracts:", nrow(asg), "\n")
cat("Tracts with geometry but no CoC:", nrow(unm),
    " | vacant units in them:", sum(unm$estimate), "\n")
cat("Empty-geometry tracts:", nrow(emp), " | vacant units in them:", sum(emp$estimate), "\n")
cat("Assigned + unmatched + empty units:",
    sum(asg$estimate) + sum(unm$estimate) + sum(emp$estimate),
    "(expect 14547150)\n")
stopifnot(sum(asg$estimate) + sum(unm$estimate) + sum(emp$estimate) == 14547150)
cat("Tracts under 90% share in assigned CoC:", sum(asg$share < 0.9),
    " | units:", sum(asg$estimate[asg$share < 0.9]), "\n")

# ---- Aggregate vacancy to CoCs ----
vac_w <- vac |> select(GEOID, variable, estimate) |>
  pivot_wider(names_from = variable, values_from = estimate)

coc_tab <- asg |> select(GEOID, COCNUM) |>
  inner_join(vac_w, by = "GEOID") |>
  group_by(COCNUM) |>
  summarise(n_tracts = n(),
            broad  = sum(B25004_001),
            narrow = sum(B25004_002 + B25004_004 + B25004_008),
            strict = sum(B25004_008), .groups = "drop")

final <- pit |>
  select(COCNUM = coc_id, coc_name = `CoC Name`, homeless = `Overall Homeless`,
         count_type = `Count Types`) |>
  left_join(coc_tab, by = "COCNUM")

cat("\nCoCs with no tract assigned:", sum(is.na(final$n_tracts)), "\n")
stopifnot(sum(is.na(final$n_tracts)) == 0)      # stop: ratios would be wrong

cat("Units in CoC table:", sum(final$broad),
    " + unmatched/empty:", sum(unm$estimate) + sum(emp$estimate), "\n")

final <- final |> mutate(ratio_narrow = narrow / homeless)
write_csv(final, "map1/data/national_coc_vacancy_vs_pit.csv")

# ---- Pre-registered summary statistics (printed, not interpreted) ----
summ <- function(d, label) {
  tibble(group = label, n_cocs = nrow(d),
         pct_broad_gt_homeless  = round(100 * mean(d$broad  > d$homeless), 1),
         pct_narrow_gt_homeless = round(100 * mean(d$narrow > d$homeless), 1),
         pct_strict_gt_homeless = round(100 * mean(d$strict > d$homeless), 1),
         min_ratio_narrow = round(min(d$ratio_narrow), 2))
}
print(bind_rows(
  summ(final, "all CoCs"),
  summ(filter(final, count_type != "Sheltered-Only Count"), "excluding sheltered-only")
))
cat("\nLowest 10 narrow ratios:\n")
print(final |> arrange(ratio_narrow) |>
        select(COCNUM, coc_name, homeless, narrow, ratio_narrow, count_type) |> head(10))
cat("Date run:", format(Sys.Date()), "\n")
