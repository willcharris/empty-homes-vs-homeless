# 20_acs1_national.R  (2026-10-14)
# Pre-registered item: "National comparison also reported from ACS 2024 1-year."
# Pulls national narrow vacancy (for rent + for sale only + other vacant) from the
# ACS 2024 1-year estimates and compares it with the 5-year figure used on the map.
# Run from the project root. Needs the Census API key already stored in .Renviron.

library(tidycensus); library(tidyverse)

vars <- c(for_rent = "B25004_002", for_sale = "B25004_004", other_vacant = "B25004_008")
d <- get_acs(geography = "us", variables = vars, year = 2024, survey = "acs1")
print(d)
stopifnot(nrow(d) == 3, !anyNA(d$estimate))

narrow_1yr <- sum(d$estimate)
moe_1yr    <- sqrt(sum(d$moe^2))                # 90% margin of error, Census approximation
narrow_5yr <- 8665393                           # 5-year, 50 states + DC (results log)
homeless   <- 742420                            # HUD PIT Jan 2025, 50 states + DC

cat("\nNarrow vacant units, ACS 2024 1-year:", format(narrow_1yr, big.mark = ","),
    "(+/-", format(round(moe_1yr), big.mark = ","), ", 90% MOE)\n")
cat("Narrow vacant units, ACS 2020-2024 5-year (map):", format(narrow_5yr, big.mark = ","), "\n")
cat("1-year minus 5-year:", format(narrow_1yr - narrow_5yr, big.mark = ","),
    sprintf("(%.1f%% of the 5-year figure)\n", 100 * (narrow_1yr - narrow_5yr) / narrow_5yr))
cat(sprintf("Ratio to %s homeless: %.1f to 1 (1-year); %.1f to 1 (5-year)\n",
            format(homeless, big.mark = ","), narrow_1yr / homeless, narrow_5yr / homeless))
cat(sprintf("Low end of 1-year range: %.1f to 1\n", (narrow_1yr - moe_1yr) / homeless))
cat("Pulled:", format(Sys.Date()), "\n")
