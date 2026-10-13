# 10_pull_rent_burden.R
# Claim 1c: pull ACS 2020-2024 5-year tract table B25070 (gross rent as a percentage
# of household income), 50 states + DC. Attribute data only. Run from the project root.
# Verifies the variable labels first, then checks totals against state and U.S. totals.
# Any discrepancy outside New York / Suffolk County (36103) stops the script.

library(tidycensus); library(tidyverse)
options(tigris_use_cache = TRUE)

stopifnot(file.exists("map1/data/national_tract_to_coc_assignment.csv"))

# ---- 0. Check the variable labels before relying on them ----
lab <- load_variables(2024, "acs5") |>
  filter(str_starts(name, "B25070_")) |> select(name, label)
print(lab, n = Inf)
stopifnot(
  str_detect(lab$label[lab$name == "B25070_001"], "Total"),
  str_detect(lab$label[lab$name == "B25070_007"], "30\\.0 to 34\\.9"),
  str_detect(lab$label[lab$name == "B25070_008"], "35\\.0 to 39\\.9"),
  str_detect(lab$label[lab$name == "B25070_009"], "40\\.0 to 49\\.9"),
  str_detect(lab$label[lab$name == "B25070_010"], "50\\.0 percent or more"),
  str_detect(lab$label[lab$name == "B25070_011"], "Not computed")
)

# ---- 1. Pull ----
states <- c(state.abb, "DC")
stopifnot(length(states) == 51)

pull_state <- function(st) {
  get_acs(geography = "tract", state = st, table = "B25070",
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

rb <- bind_rows(out, .id = "state")
print(c(tracts = n_distinct(rb$GEOID)))
stopifnot(n_distinct(rb$GEOID) == 84401)              # same tracts as the other pulls

# ---- 2. Checks: renter-occupied households (B25070_001) ----
tot_tr <- rb |> filter(variable == "B25070_001") |>
  mutate(GEOID_state = str_sub(GEOID, 1, 2)) |>
  group_by(GEOID_state) |> summarise(tract_total = sum(estimate), .groups = "drop")

tot_st <- get_acs(geography = "state", variables = "B25070_001",
                  year = 2024, survey = "acs5") |>
  filter(NAME != "Puerto Rico") |> select(GEOID, NAME, state_total = estimate)

chk <- inner_join(tot_st, tot_tr, by = c("GEOID" = "GEOID_state")) |>
  mutate(diff = tract_total - state_total)
print(chk |> filter(diff != 0))                       # want: zero rows, or New York only
stopifnot(nrow(chk) == 51, all(chk$GEOID[chk$diff != 0] == "36"))

if (any(chk$diff != 0)) {                             # confirm any NY gap is Suffolk only
  cty <- get_acs(geography = "county", state = "NY", variables = "B25070_001",
                 year = 2024, survey = "acs5") |> select(GEOID, NAME, cty_total = estimate)
  ny_tr <- rb |> filter(state == "NY", variable == "B25070_001") |>
    mutate(cty = str_sub(GEOID, 1, 5)) |>
    group_by(cty) |> summarise(tract_total = sum(estimate), .groups = "drop")
  offc <- inner_join(cty, ny_tr, by = c("GEOID" = "cty")) |>
    mutate(diff = tract_total - cty_total) |> filter(diff != 0)
  print(offc)
  stopifnot(all(offc$GEOID == "36103"))
}

us_total <- get_acs(geography = "us", variables = "B25070_001",
                    year = 2024, survey = "acs5")$estimate
print(c(states = sum(tot_st$state_total), us = us_total, tracts = sum(tot_tr$tract_total)))
stopifnot(sum(tot_st$state_total) == us_total,
          sum(tot_tr$tract_total) == us_total + sum(chk$diff))

# Share of renter households with burden not computed (nationally)
nc <- rb |> filter(variable %in% c("B25070_001", "B25070_011")) |>
  group_by(variable) |> summarise(n = sum(estimate))
print(nc)
print(round(nc$n[nc$variable == "B25070_011"] / nc$n[nc$variable == "B25070_001"], 3))

write_csv(rb, "map1/data/national_B25070_tract_2020-2024.csv")
cat("Date pulled:", format(Sys.Date()), "\n")
