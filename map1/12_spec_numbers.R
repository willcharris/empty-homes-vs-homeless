# 12_spec_numbers.R
# Prints the numbers the Map 1 spec marks [pull]. Reads saved files only; changes nothing.
# Run from the project root:  source("map1/12_spec_numbers.R", echo = FALSE)

library(tidyverse)

v  <- read_csv("map1/data/national_coc_vacancy_vs_pit.csv", show_col_types = FALSE)
c1 <- read_csv("map1/data/national_coc_1c.csv",             show_col_types = FALSE)
stopifnot(nrow(v) == 382, sum(v$homeless) == 742420)
gap <- 8665393 - sum(v$narrow)
cat("Narrow units in CoC table:", sum(v$narrow), "| gap to tract total 8,665,393:", gap,
    "(units in unmatched or empty-geometry tracts)\n")
stopifnot(gap >= 0, gap < 0.01 * 8665393)   # gap must be small and not negative

cat("\n== Ratio of narrow vacant units to homeless people, across 382 CoCs ==\n")
print(summary(v$ratio_narrow))

cat("\n== 5 LOWEST ratios (for the accessible variant labels) ==\n")
print(v |> arrange(ratio_narrow) |> slice_head(n = 5) |>
        select(COCNUM, coc_name, homeless, narrow, ratio_narrow, count_type), width = Inf)

cat("\n== 5 HIGHEST ratios ==\n")
print(v |> arrange(desc(ratio_narrow)) |> slice_head(n = 5) |>
        select(COCNUM, coc_name, homeless, narrow, ratio_narrow, count_type), width = Inf)

cat("\n== How many CoCs fall under each ratio ==\n")
print(tibble(under_2 = sum(v$ratio_narrow < 2),
             under_5 = sum(v$ratio_narrow < 5),
             under_10 = sum(v$ratio_narrow < 10)))

cat("\n== Dot counts if 1 dot = 100 vs 250 (same unit for both layers) ==\n")
for (u in c(100, 250)) {
  cat("unit", u, "| amber dots ~", round(sum(v$narrow) / u),
      "| cyan dots ~", round(sum(v$homeless) / u),
      "| smallest CoC homeless count:", min(v$homeless),
      "| CoCs with fewer than one expected cyan dot:", sum(v$homeless < u), "\n")
}

cat("\n== Claim 1c file: column names and first rows (to build the scatter) ==\n")
print(names(c1))
print(head(c1, 3), width = Inf)

cat("\nDate run:", format(Sys.Date()), "\n")