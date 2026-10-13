# 09_claim_1b.R
# Claim 1b (pre-registered): homelessness is higher where rents are higher and
# vacancy is lower. Spearman rank correlations across the 382 CoCs (50 states + DC).
# Reads saved files only. Run from the project root.
#
# Per CoC:
#   rate_10k = PIT homeless / summed tract population * 10,000
#   rent_w   = population-weighted mean of tract median gross rents (tracts with no
#              rent skipped); an average of medians, NOT a true CoC median
#   vac_rate = narrow vacant units / total housing units
# Verdict rule (map1-preregistration.md):
#   supported    if rho(rent, rate) >= 0.3 AND rho(vac_rate, rate) < 0
#   contradicted if rho(rent, rate) <= 0  OR  rho(vac_rate, rate) > 0
#   mixed        otherwise
# Verdict uses ALL 382 CoCs. The other two rows are reported sensitivity checks
# (Amendment 4 commits to the NY-excluded run; the sheltered-only run is added as a
# labeled sensitivity). No other specifications are tried.

library(tidyverse)

files <- c("map1/data/national_tract_to_coc_assignment.csv",
           "map1/data/national_B25002_tract_2020-2024.csv",
           "map1/data/national_B25004_tract_2020-2024.csv",
           "map1/data/national_B25064_B01003_tract_2020-2024.csv",
           "map1/data/pit_2025_by_coc_clean.csv")
stopifnot(all(file.exists(files)))

rd <- function(f) read_csv(f, col_types = cols(GEOID = col_character()), show_col_types = FALSE)
asg <- rd(files[1]); occ <- rd(files[2]); vac <- rd(files[3]); rp <- rd(files[4])

pit_all <- read_csv(files[5], show_col_types = FALSE)
stopifnot(nrow(pit_all) == 386, sum(pit_all$`Overall Homeless`) == 745652)
pit <- pit_all |> filter(!str_detect(coc_id, "^(AS|GU|MP|PR|VI)-"))
stopifnot(nrow(pit) == 382, sum(pit$`Overall Homeless`) == 745652 - 3232)

# ---- Tract-level pieces ----
units  <- occ |> filter(variable == "B25002_001") |> select(GEOID, housing_units = estimate)
narrow <- vac |> filter(variable %in% c("B25004_002", "B25004_004", "B25004_008")) |>
  group_by(GEOID) |> summarise(narrow = sum(estimate), .groups = "drop")
pop_t  <- rp  |> filter(variable == "B01003_001") |> select(GEOID, pop = estimate)
rent_t <- rp  |> filter(variable == "B25064_001") |> select(GEOID, rent = estimate)

tr <- asg |> select(GEOID, COCNUM) |>
  left_join(units, by = "GEOID") |> left_join(narrow, by = "GEOID") |>
  left_join(pop_t, by = "GEOID") |> left_join(rent_t, by = "GEOID")
stopifnot(!anyNA(tr$housing_units), !anyNA(tr$narrow), !anyNA(tr$pop))

# Which CoC holds Suffolk County, NY (Amendment 4 said "believed NY-603")
print(asg |> filter(str_starts(GEOID, "36103")) |> count(COCNUM))

# ---- CoC level ----
coc1b <- tr |> group_by(COCNUM) |>
  summarise(pop_n = sum(pop), units_n = sum(housing_units), narrow_n = sum(narrow),
            rent_w = sum(rent * pop, na.rm = TRUE) / sum(pop[!is.na(rent)]),
            tracts_no_rent = sum(is.na(rent)), .groups = "drop")

d <- pit |>
  select(COCNUM = coc_id, coc_name = `CoC Name`, homeless = `Overall Homeless`,
         count_type = `Count Types`) |>
  left_join(coc1b, by = "COCNUM") |>
  mutate(rate_10k = homeless / pop_n * 10000,
         vac_rate = narrow_n / units_n)

stopifnot(nrow(d) == 382, !anyNA(d$pop_n), !anyNA(d$rent_w), all(d$pop_n > 0))
cat("Population in CoC table:", sum(d$pop_n), " (tract total 334844920;",
    "difference = people in unmatched tracts)\n")

write_csv(d, "map1/data/national_coc_1b.csv")

# ---- Spearman test with bootstrap intervals ----
test_1b <- function(x, label) {
  r_rent <- cor(x$rent_w,   x$rate_10k, method = "spearman")
  r_vac  <- cor(x$vac_rate, x$rate_10k, method = "spearman")
  set.seed(1)
  b <- replicate(2000, {
    i <- sample(nrow(x), replace = TRUE)
    c(cor(x$rent_w[i],   x$rate_10k[i], method = "spearman"),
      cor(x$vac_rate[i], x$rate_10k[i], method = "spearman"))
  })
  ci <- apply(b, 1, quantile, c(0.025, 0.975))
  verdict <- if (r_rent >= 0.3 & r_vac < 0) "supported"
             else if (r_rent <= 0 | r_vac > 0) "contradicted" else "mixed"
  tibble(group = label, n = nrow(x),
         rho_rent = round(r_rent, 2), rent_95ci = sprintf("%.2f to %.2f", ci[1, 1], ci[2, 1]),
         rho_vac  = round(r_vac, 2),  vac_95ci  = sprintf("%.2f to %.2f", ci[1, 2], ci[2, 2]),
         rule_result = verdict)
}

res <- bind_rows(
  test_1b(d, "all 382 CoCs (verdict row)"),
  test_1b(filter(d, !str_starts(COCNUM, "NY-")), "excluding NY CoCs (Amendment 4)"),
  test_1b(filter(d, count_type != "Sheltered-Only Count"), "sensitivity: excl sheltered-only")
)
print(res, width = Inf)

cat("\nSummary of inputs (all 382):\n")
print(summary(d[, c("rate_10k", "rent_w", "vac_rate")]))
cat("Date run:", format(Sys.Date()), "\n")
