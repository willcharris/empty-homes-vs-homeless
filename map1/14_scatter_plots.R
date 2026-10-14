# 14_scatter_plots.R
# Slide 3 figure: homelessness rate vs rent level, vacancy rate and rent burden,
# across 382 CoCs. Reads saved files only. Rank correlations are recomputed here and
# must match the logged results (09_claim_1b.R, 11_claim_1c.R) or the script stops.
# No trend line on purpose: correlations are weak and a line would imply more.

library(tidyverse)

b  <- read_csv("map1/data/national_coc_1b.csv", show_col_types = FALSE)
c1 <- read_csv("map1/data/national_coc_1c.csv", show_col_types = FALSE)
stopifnot(nrow(b) == 382, nrow(c1) == 382)

mk <- function(d, xcol, scale, panel) {
  d |> transmute(COCNUM, coc_name, x = .data[[xcol]] * scale, y = rate_10k, panel = panel)
}
long <- bind_rows(
  mk(b,  "rent_w",   1,   "Median gross rent ($)"),
  mk(b,  "vac_rate", 100, "Vacancy rate, narrow definition (%)"),
  mk(c1, "burden",   100, "Renters paying 30%+ of income (%)")
) |> filter(!is.na(x), !is.na(y))

rho_tbl <- long |>
  group_by(panel) |>
  summarise(rho = cor(x, y, method = "spearman"), n = n(), .groups = "drop")
print(rho_tbl)

get <- function(p) rho_tbl$rho[rho_tbl$panel == p]
stopifnot(abs(get("Median gross rent ($)") - 0.28) < 0.006,
          abs(get("Vacancy rate, narrow definition (%)") - (-0.10)) < 0.006,
          abs(get("Renters paying 30%+ of income (%)") - 0.29) < 0.006,
          all(rho_tbl$n == 382))

panel_order <- c("Median gross rent ($)",
                 "Vacancy rate, narrow definition (%)",
                 "Renters paying 30%+ of income (%)")
lab_tbl <- rho_tbl |>
  mutate(label = sprintf("%s\nrank correlation %.2f", panel, rho)) |>
  select(panel, label)

long <- long |>
  left_join(lab_tbl, by = "panel") |>
  mutate(label = factor(label, levels = lab_tbl$label[match(panel_order, lab_tbl$panel)]))

bg <- "#0B0F14"; fg <- "#C9D1D9"; dim <- "#8B949E"; grid <- "#1B222B"

p <- ggplot(long, aes(x, y)) +
  geom_point(colour = "#1E96BA", alpha = 0.55, size = 1.5) +
  facet_wrap(~ label, ncol = 1, scales = "free_x") +
  scale_y_log10(breaks = c(1, 3, 10, 30, 100), labels = c("1", "3", "10", "30", "100")) +
  labs(x = NULL, y = "Homeless people per 10,000 residents (log scale)",
       caption = str_wrap("Each dot is one of 382 CoCs. Rank correlation runs from -1 to 1; 0 means no link. Sources: ACS 2020-2024 5-year; HUD 2025 AHAR Part 1 (PIT counts); HUD FY2025 CoC boundaries.", 85)) +
  theme_minimal(base_size = 11) +
  theme(plot.background  = element_rect(fill = bg, colour = NA),
        panel.background = element_rect(fill = bg, colour = NA),
        panel.grid.major = element_line(colour = grid, linewidth = 0.3),
        panel.grid.minor = element_blank(),
        text             = element_text(colour = fg),
        axis.text        = element_text(colour = dim, size = 8),
        axis.title.y     = element_text(colour = dim, size = 8),
        strip.text       = element_text(colour = fg, hjust = 0, size = 10, face = "bold"),
        plot.caption     = element_text(colour = dim, size = 6.5, hjust = 0),
        plot.margin      = margin(12, 14, 10, 12))

dir.create("map1/out", showWarnings = FALSE)
ggsave("map1/out/scatter_1b_1c.png", p, width = 4.5, height = 5.625, dpi = 240, bg = bg)
write_csv(long |> select(panel, COCNUM, coc_name, x, y), "map1/out/scatter_data.csv")

cat("\nSaved map1/out/scatter_1b_1c.png (1080 x 1350) and scatter_data.csv\n")
cat("Date run:", format(Sys.Date()), "\n")