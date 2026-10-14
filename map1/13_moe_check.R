# 13_moe_check.R
# Post-hoc sensitivity (NOT pre-registered; does not change the Claim 1 verdict):
# does each CoC's narrow vacant count still exceed its homeless count after allowing
# for ACS sampling error? 90% margins of error (the level Census publishes), summed
# across tracts by Census's approximate method: square root of the sum of squared
# MOEs, counting only the single largest MOE among zero-estimate parts.
# The PIT count has no sampling MOE here (it is a count, not a survey) but is known
# to undercount; that is a separate limit. Reads saved files only.

library(tidyverse)

asg <- read_csv("map1/data/national_tract_to_coc_assignment.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE)
vac <- read_csv("map1/data/national_B25004_tract_2020-2024.csv",
                col_types = cols(GEOID = col_character()), show_col_types = FALSE)
v   <- read_csv("map1/data/national_coc_vacancy_vs_pit.csv", show_col_types = FALSE)

narrow_vars <- c("B25004_002", "B25004_004", "B25004_008")
parts <- vac |>
  filter(variable %in% narrow_vars) |>
  select(GEOID, variable, estimate, moe) |>
  inner_join(select(asg, GEOID, COCNUM), by = "GEOID")

cat("Parts (tract x variable) used:", nrow(parts),
    "| rows with missing MOE:", sum(is.na(parts$moe)), "\n")

per_coc <- parts |>
  group_by(COCNUM) |>
  summarise(
    narrow_chk     = sum(estimate),
    moe_nonzero_sq = sum(moe[estimate > 0]^2, na.rm = TRUE),
    moe_zero_max   = max(c(0, moe[estimate == 0]), na.rm = TRUE),
    .groups = "drop") |>
  mutate(moe90 = sqrt(moe_nonzero_sq + moe_zero_max^2))

res <- v |>
  select(COCNUM, coc_name, homeless, narrow, ratio_narrow, count_type) |>
  left_join(per_coc, by = "COCNUM") |>
  mutate(low90 = narrow - moe90, high90 = narrow + moe90,
         ratio_low = low90 / homeless, ratio_high = high90 / homeless)

stopifnot(nrow(res) == 382, !anyNA(res$moe90), all(res$narrow == res$narrow_chk))

cat("\n== CoCs whose narrow count beats the homeless count even at the LOW end of the 90% range ==\n")
cat(sum(res$low90 > res$homeless), "of 382\n")

cat("\n== CoCs where the low end falls to or below the homeless count ==\n")
print(res |> filter(low90 <= res$homeless) |> arrange(ratio_narrow) |>
        select(COCNUM, coc_name, homeless, narrow, moe90, ratio_narrow, ratio_low, ratio_high),
      n = 50, width = Inf)

cat("\n== The 7 CoCs under 2 to 1, with their ranges ==\n")
print(res |> filter(ratio_narrow < 2) |> arrange(ratio_narrow) |>
        select(COCNUM, coc_name, homeless, narrow, moe90, ratio_narrow, ratio_low, ratio_high),
      width = Inf)

cat("\n== MOE as a share of the narrow count, across 382 CoCs ==\n")
print(summary(res$moe90 / res$narrow))

cat("\nDate run:", format(Sys.Date()), "\n")