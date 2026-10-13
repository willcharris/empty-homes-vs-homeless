# 05_pull_national.R
# Pull ACS 2020-2024 5-year tract tables B25002 (occupancy) and B25004 (vacancy
# status) for all 50 states + DC. Territories excluded (no PIT/ACS match).
# Attribute data only (no geometry); geometry and the CoC join come later.
# Checks every state's tract sum against that state's own published total.
# Run from the project root ("Empty homes vs homeless claim map").

library(tidycensus); library(tidyverse)
options(tigris_use_cache = TRUE)

stopifnot(file.exists("map1/data/pit_2025_by_coc_clean.csv"))   # right folder?
dir.create("map1/data", showWarnings = FALSE)

states <- c(state.abb, "DC")           # 51 units
stopifnot(length(states) == 51)

pull_state <- function(st) {
  occ <- get_acs(geography = "tract", state = st, table = "B25002",
                 year = 2024, survey = "acs5")
  vac <- get_acs(geography = "tract", state = st, table = "B25004",
                 year = 2024, survey = "acs5")
  list(occ = occ, vac = vac)
}

occ_list <- list(); vac_list <- list(); failed <- character()

for (st in states) {
  res <- tryCatch(pull_state(st), error = function(e) NULL)
  if (is.null(res)) { failed <- c(failed, st); message("FAILED: ", st); next }
  occ_list[[st]] <- res$occ
  vac_list[[st]] <- res$vac
  message("done: ", st)
}

# Retry failures once
for (st in failed) {
  res <- tryCatch(pull_state(st), error = function(e) NULL)
  if (!is.null(res)) {
    occ_list[[st]] <- res$occ; vac_list[[st]] <- res$vac
    failed <- setdiff(failed, st)
  }
}
stopifnot(length(failed) == 0)          # stop if any state still missing

occ <- bind_rows(occ_list, .id = "state")
vac <- bind_rows(vac_list, .id = "state")

# ---- Checks ----
state_tot <- get_acs(geography = "state", variables = "B25002_003",
                     year = 2024, survey = "acs5") |>
  filter(NAME != "Puerto Rico") |>
  select(GEOID, NAME, state_vacant = estimate)

tract_tot <- occ |> filter(variable == "B25002_003") |>
  mutate(GEOID_state = str_sub(GEOID, 1, 2)) |>
  group_by(GEOID_state) |> summarise(tract_vacant = sum(estimate), n_tracts = n())

chk <- inner_join(state_tot, tract_tot, by = c("GEOID" = "GEOID_state")) |>
  mutate(diff = tract_vacant - state_vacant)

# Documented exception (Amendment 2): NY / Suffolk County, -709 units,
# a mismatch inside Census's own published tables.
off <- chk |> filter(diff != 0)
print(off)
stopifnot(nrow(chk) == 51, all(off$GEOID == "36"), all(abs(off$diff) <= 709))

# National: state totals must sum to the U.S. total; tract sum differs only by the exception
us_tot <- get_acs(geography = "us", variables = "B25002_003",
                  year = 2024, survey = "acs5")$estimate
print(c(states = sum(state_tot$state_vacant), us = us_tot,
        tracts = sum(tract_tot$tract_vacant)))
stopifnot(sum(state_tot$state_vacant) == us_tot,
          sum(tract_tot$tract_vacant) == us_tot + sum(chk$diff))

# B25004 total line equals B25002 vacant per tract
vt <- vac |> filter(variable == "B25004_001") |> select(GEOID, v4 = estimate)
ot <- occ |> filter(variable == "B25002_003") |> select(GEOID, v2 = estimate)
stopifnot(all(inner_join(vt, ot, by = "GEOID") |> mutate(d = v4 - v2) |> pull(d) == 0))

print(c(states = nrow(chk), occ_tracts = nrow(occ) / 3, vac_tracts = nrow(vac) / 8))

write_csv(occ, "map1/data/national_B25002_tract_2020-2024.csv")
write_csv(vac, "map1/data/national_B25004_tract_2020-2024.csv")
cat("Date pulled:", format(Sys.Date()), "\n")
