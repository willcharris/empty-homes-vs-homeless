readRenviron("~/.Renviron")
library(tidycensus)
nchar(Sys.getenv("CENSUS_API_KEY"))
get_acs(geography = "state", variables = "B25002_003", year = 2024, survey = "acs5") |> head()
