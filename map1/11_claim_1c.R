# 11_claim_1c.R
# Claim 1c (pre-registered in map1-preregistration-claim-1c.md): homelessness rates
# are higher in CoCs where a larger share of renter households are cost-burdened.
# Spearman rank correlation across 382 CoCs, bootstrap 95% intervals.
# Reads saved files only. Run from the project root.
#
# Burden share = renter households paying >= 30% of income on rent (B25070_007..010)
#                / (B25070_001 - B25070_011)   [summed over a CoC's tracts]
# Severe share = B25070_010 / (B25070_001 - B25070_011)   (labeled sensitivity)
# Rule: supported if rho >= 0.3; contradicted if rho <= 0; mixed otherwise.
# Rows: (1) all 382 CoCs = verdict; (2) excluding NY CoCs; (3) excluding sheltered-only
#       CoCs; (4) severe-burden measure, all 382 (sensitivity). Nothing else is run.

library(tidyverse)

files <- c("map1/data/national_tract_to_coc_assignment.csv",
           "map1/data/national_B25070_tract_2020-2024.csv",
           "map1/data/national_B25064_B01003_tract_2020-2024.csv",
           "map1/data/pit_2025_by_coc_clean.csv")
stopifnot(all(file.exists(files)))

rd <- function(f) read_csv(f, col_types = cols(GEOID = col_character()), show_col_types = FALSE)
asg <- rd(files[1]); rb <- rd(files[2]); rp <- rd(files[3])

pit_all <- read_csv(files[4], show_col_types = FALSE)
stopifnot(nrow(pit_all) == 386, sum(pit_all$`Overall Homeless`) == 745652)
pit <- pit_all |> filter(!str_detect(coc_id, "^(AS|GU|MP|PR|VI)-"))
stopifnot(nrow(pit) == 382, sum(pit$`Overall Homeless`) == 745652 - 3232)

# ---- Tract-level burden counts ----
bw <- rb |> select(GEOID, variable, estimate) |>
  pivot_wider(names_from = variable, values_from = estimate) |>
  transmute(GEOID,
            renters   = B25070_001,
            computed  = B25070_001 - B25070_011,
            burdened  = B25070_007 + B25070_008 + B25070_009 + B25070_010,
            severe    = B25070_010)
stopifnot(!anyNA(bw$computed), all(bw$computed >= 0))

pop_t <- rp |> filter(variable == "B01003_001") |> select(GEOID, pop = estimate)

tr <- asg |> select(GEOID, COCNUM) |>
  left_join(bw, by = "GEOID") |> left_join(pop_t, by = "GEOID")
stopifnot(!anyNA(tr$computed), !anyNA(tr$pop))

# ---- CoC level ----
coc <- tr |> group_by(COCNUM) |>
  summarise(pop_n = sum(pop), computed_n = sum(computed),
            burdened_n = sum(burdened), severe_n = sum(severe), .groups = "drop")

d <- pit |>
  select(COCNUM = coc_id, coc_name = `CoC Name`, homeless = `Overall Homeless`,
         count_type = `Count Types`) |>
  left_join(coc, by = "COCNUM") |>
  mutate(rate_10k = homeless / pop_n * 10000,
         burden   = burdened_n / computed_n,
         severe   = severe_n / computed_n)

stopifnot(nrow(d) == 382, !anyNA(d$pop_n), all(d$computed_n > 0), !anyNA(d$burden))
cat("Renter households (computed) in CoC table:", sum(d$computed_n), "\n")
write_csv(d, "map1/data/national_coc_1c.csv")

# ---- Test ----
test_1c <- function(x, col, label) {
  b <- x[[col]]; y <- x$rate_10k
  r <- cor(b, y, method = "spearman")
  set.seed(1)
  bs <- replicate(2000, {
    i <- sample(length(y), replace = TRUE)
    cor(b[i], y[i], method = "spearman")
  })
  ci <- quantile(bs, c(0.025, 0.975))
  rule <- if (r >= 0.3) "supported" else if (r <= 0) "contradicted" else "mixed"
  tibble(group = label, n = length(y), rho = round(r, 2),
         ci95 = sprintf("%.2f to %.2f", ci[1], ci[2]), rule_result = rule)
}

res <- bind_rows(
  test_1c(d, "burden", "1. all 382 CoCs (verdict row)"),
  test_1c(filter(d, !str_starts(COCNUM, "NY-")), "burden", "2. excluding NY CoCs"),
  test_1c(filter(d, count_type != "Sheltered-Only Count"), "burden", "3. excl sheltered-only (sensitivity)"),
  test_1c(d, "severe", "4. severe burden, all 382 (sensitivity)")
)
print(res, width = Inf)

cat("\nSummary of inputs (all 382):\n")
print(summary(d[, c("rate_10k", "burden", "severe")]))
cat("Date run:", format(Sys.Date()), "\n")
