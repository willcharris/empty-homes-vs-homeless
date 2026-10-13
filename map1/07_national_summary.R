# 07_national_summary.R
# Resume point after 06_national_join.R: uses the SAVED tract-to-CoC assignment, so the
# slow overlay does not need rerunning. Scope: 50 states + DC (Amendment 3).
# Prints the pre-registered summary statistics. Run from the project root.

library(tidyverse)

stopifnot(file.exists("map1/data/national_tract_to_coc_assignment.csv"),
          file.exists("map1/data/national_B25004_tract_2020-2024.csv"),
          file.exists("map1/data/pit_2025_by_coc_clean.csv"))

asg <- read_csv("map1/data/national_tract_to_coc_assignment.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE)
vac <- read_csv("map1/data/national_B25004_tract_2020-2024.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE)

pit_all <- read_csv("map1/data/pit_2025_by_coc_clean.csv", show_col_types = FALSE)
stopifnot(nrow(pit_all) == 386, sum(pit_all$`Overall Homeless`) == 745652)   # ties to HUD
pit <- pit_all |> filter(!str_detect(coc_id, "^(AS|GU|MP|PR|VI)-"))
stopifnot(nrow(pit) == 382, sum(pit$`Overall Homeless`) == 745652 - 3232)    # 742,420

stopifnot(nrow(asg) == 84086, sum(asg$estimate) == 14547150 - 1512)  # 06's reported output

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

cat("CoCs with no tract assigned:", sum(is.na(final$n_tracts)), "(want 0)\n")
stopifnot(sum(is.na(final$n_tracts)) == 0)

cat("Vacant units in CoC table:", sum(final$broad),
    "| national tract total minus unmatched tracts:", 14547150 - 1512, "\n")
stopifnot(sum(final$broad) == 14547150 - 1512)   # every assigned unit is in some CoC

final <- final |> mutate(ratio_narrow = narrow / homeless)
write_csv(final, "map1/data/national_coc_vacancy_vs_pit.csv")

# ---- National, corrected scope (50 states + DC) ----
nat <- c(broad = sum(final$broad) + 1512, narrow = NA, strict = NA)
vac_nat <- vac |> group_by(variable) |> summarise(u = sum(estimate))
nat <- c(broad  = vac_nat$u[vac_nat$variable == "B25004_001"],
         narrow = sum(vac_nat$u[vac_nat$variable %in% c("B25004_002", "B25004_004", "B25004_008")]),
         strict = vac_nat$u[vac_nat$variable == "B25004_008"])
print(nat)
print(round(nat / sum(pit$`Overall Homeless`), 1))

# ---- Pre-registered CoC-level statistics (printed, not interpreted) ----
summ <- function(d, label) {
  tibble(group = label, n_cocs = nrow(d),
         pct_broad_gt_homeless  = round(100 * mean(d$broad  > d$homeless), 1),
         pct_narrow_gt_homeless = round(100 * mean(d$narrow > d$homeless), 1),
         pct_strict_gt_homeless = round(100 * mean(d$strict > d$homeless), 1),
         min_ratio_narrow = round(min(d$ratio_narrow), 2))
}
print(bind_rows(
  summ(final, "all 382 CoCs"),
  summ(filter(final, count_type != "Sheltered-Only Count"), "excluding sheltered-only")
))

cat("\nLowest 10 narrow ratios:\n")
print(final |> arrange(ratio_narrow) |>
        select(COCNUM, coc_name, homeless, narrow, ratio_narrow, count_type) |> head(10))
cat("Date run:", format(Sys.Date()), "\n")
