library(tidycensus)
library(tidyverse)

getwd()  # should end in "Empty homes vs homeless claim map"
dir.create("map1/data", showWarnings = FALSE)

# What do the B25004 codes mean? Check, don't assume.
load_variables(2024, "acs5") |>
  filter(str_starts(name, "B25004")) |>
  select(name, label) |>
  print(n = Inf)

# Tract-level pulls for Michigan, 2020-2024 5-year
mi_occ <- get_acs(geography = "tract", state = "MI",
                  table = "B25002", year = 2024, survey = "acs5")
mi_vac <- get_acs(geography = "tract", state = "MI",
                  table = "B25004", year = 2024, survey = "acs5")

nrow(mi_occ); nrow(mi_vac)

write_csv(mi_occ, "map1/data/mi_B25002_tract_2020-2024.csv")
write_csv(mi_vac, "map1/data/mi_B25004_tract_2020-2024.csv")

# Do tract rows sum to the state figure?
mi_occ |> filter(variable == "B25002_003") |> summarise(tract_sum = sum(estimate))
get_acs(geography = "state", state = "MI", variables = "B25002_003",
        year = 2024, survey = "acs5") |> select(NAME, estimate, moe)

# Michigan totals under the three pre-registered definitions
mi_vac |>
  group_by(variable) |>
  summarise(units = sum(estimate)) |>
  mutate(label = case_when(
    variable == "B25004_001" ~ "broad (all vacant)",
    variable == "B25004_002" ~ "for rent",
    variable == "B25004_004" ~ "for sale only",
    variable == "B25004_008" ~ "other vacant",
    TRUE ~ "excluded"))
