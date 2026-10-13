# 08_pull_rent_pop.R
# Pull ACS 2020-2024 5-year tract data for Claim 1b: median gross rent (B25064_001)
# and total population (B01003_001), 50 states + DC. Run from the project root.
# Attribute data only. Checks population against state and U.S. totals.

library(tidycensus); library(tidyverse)
options(tigris_use_cache = TRUE)

stopifnot(file.exists("map1/data/national_tract_to_coc_assignment.csv"))

states <- c(state.abb, "DC")
stopifnot(length(states) == 51)

pull_state <- function(st) {
  get_acs(geography = "tract", state = st,
          variables = c("B25064_001", "B01003_001"),
          year = 2024, survey = "acs5")
}

out <- list(); failed <- character()
for (st in states) {
  r <- tryCatch(pull_state(st), error = function(e) NULL)
  if (is.null(r)) { failed <- c(failed, st); message("FAILED: ", st); next }
  out[[st]] <- r
  message("done: ", st)
}
for (st in failed) {                                  # retry once
  r <- tryCatch(pull_state(st), error = function(e) NULL)
  if (!is.null(r)) { out[[st]] <- r; failed <- setdiff(failed, st) }
}
stopifnot(length(failed) == 0)

rp <- bind_rows(out, .id = "state")

# ---- Checks ----
tr_n <- rp |> distinct(GEOID) |> nrow()
print(c(tracts = tr_n))                                # expect 84401 (matches earlier pulls)
stopifnot(tr_n == 84401)

# Population: tract sums vs state totals
pop_tr <- rp |> filter(variable == "B01003_001") |>
  mutate(GEOID_state = str_sub(GEOID, 1, 2)) |>
  group_by(GEOID_state) |> summarise(tract_pop = sum(estimate), .groups = "drop")

pop_st <- get_acs(geography = "state", variables = "B01003_001",
                  year = 2024, survey = "acs5") |>
  filter(NAME != "Puerto Rico") |> select(GEOID, NAME, state_pop = estimate)

pchk <- inner_join(pop_st, pop_tr, by = c("GEOID" = "GEOID_state")) |>
  mutate(diff = tract_pop - state_pop, pct = 100 * diff / state_pop)
print(pchk |> filter(diff != 0))                       # want: zero or very few rows
# Documented exception (Amendment 4): NY / Suffolk County, -77,579 people, a mismatch
# inside Census's published tables (same county as the -709 vacant-unit gap).
off <- pchk |> filter(diff != 0)
stopifnot(nrow(pchk) == 51, all(off$GEOID == "36"), all(abs(off$diff) <= 77579))

us_pop <- get_acs(geography = "us", variables = "B01003_001",
                  year = 2024, survey = "acs5")$estimate
print(c(states = sum(pop_st$state_pop), us = us_pop, tracts = sum(pop_tr$tract_pop)))
stopifnot(sum(pop_st$state_pop) == us_pop,
          sum(pop_tr$tract_pop) == us_pop + sum(pchk$diff))   # tracts differ only by the exception

# Rent: missing values by design (tracts with no renter-occupied units)
rent <- rp |> filter(variable == "B25064_001")
print(c(tracts_with_rent = sum(!is.na(rent$estimate)), tracts_rent_NA = sum(is.na(rent$estimate))))

write_csv(rp, "map1/data/national_B25064_B01003_tract_2020-2024.csv")
cat("Date pulled:", format(Sys.Date()), "\n")
