# 19_render_carousel.R  (v3, 2026-10-14: Census API notice added to slide 5)
# Five carousel slides, 1080 x 1350 (4:5). Reads saved files only. Run from the project root.
#   1 the claim as a question   2 the map (copy of the locked still)
#   3 the complication (rent / rent burden / vacancy vs homelessness rate, redrawn dark)
#   4 limits                    5 sources, method and my view
# Outputs: map1/out/carousel_1_question.png ... carousel_5_sources.png

library(tidyverse)

W <- 1080; H <- 1350
bg <- "#0B0F14"; fg <- "#E6EDF3"; dimc <- "#8B949E"
amber <- "#C98500"; cyan <- "#1E96BA"
dir.create("map1/out", showWarnings = FALSE)

# Slide 5 says the code and pre-registration are "in the link in bio". That is only true once
# the repo is public and the link is set. Change this line if that is not the case at posting time.
REPO_LINE <- "Code, pre-registration and method note: link in bio."

# ---- helpers ----
canvas <- function(layers) {
  ggplot() + layers +
    scale_x_continuous(limits = c(0, W), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, H), expand = c(0, 0)) +
    coord_fixed(expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = bg, colour = NA),
          plot.margin = margin(0, 0, 0, 0))
}
save_slide <- function(p, file) {
  ggsave(file, p, width = 4.5, height = 5.625, dpi = 240, bg = bg, device = ragg::agg_png)
  cat("Saved", file, "\n")
}
txt <- function(x, y, label, size = 3.4, col = fg, bold = FALSE, hjust = 0, vjust = 1,
                wrap = NULL, lh = 1.1) {
  if (!is.null(wrap)) label <- str_wrap(label, wrap)
  annotate("text", x = x, y = y, label = label, hjust = hjust, vjust = vjust,
           colour = col, size = size, fontface = if (bold) "bold" else "plain", lineheight = lh)
}
n_lines <- function(label) str_count(label, "\n") + 1
bullets <- function(items, y0, size = 3.4, wrap = 54, gap = 24, lh = 1.1, x = 50, col_b = amber) {
  layers <- list(); y <- y0
  line_px <- size * 9.48 * lh            # text size -> pixels per line on this canvas
  for (it in items) {
    lab <- str_wrap(it, wrap)
    layers <- c(layers, list(
      annotate("point", x = x + 6, y = y - line_px * 0.45, shape = 15, size = 2.2, colour = col_b),
      txt(x + 34, y, lab, size = size, lh = lh)))
    y <- y - n_lines(lab) * line_px - gap
  }
  attr(layers, "y_end") <- y
  layers
}

# ---- Slide 1: the question ----
s1 <- canvas(list(
  txt(50, 1010, "Are there more\nempty homes\nthan homeless\npeople?", size = 11, bold = TRUE, lh = 0.95),
  txt(50, 470, "One claim says yes. I tested it.", size = 5.5),
  txt(50, 100, "United States, 382 regions (HUD Continuums of Care)", size = 3.1, col = dimc, vjust = 0.5),
  txt(1030, 100, "Swipe  >", size = 3.1, col = dimc, hjust = 1, vjust = 0.5)
))
save_slide(s1, "map1/out/carousel_1_question.png")

# ---- Slide 2: the map (the locked still, unchanged) ----
stopifnot(file.exists("map1/out/map1_still_4x5.png"))
file.copy("map1/out/map1_still_4x5.png", "map1/out/carousel_2_map.png", overwrite = TRUE)
cat("Saved map1/out/carousel_2_map.png (copy of the still)\n")

# ---- Slide 3: the complication ----
d <- read_csv("map1/out/scatter_data.csv", show_col_types = FALSE)
spec <- list(
  list(panel = "Median gross rent ($)", title = "Median monthly rent",
       xr = c(700, 3100), brk = c(1000, 1500, 2000, 2500, 3000),
       lab = c("$1,000", "$1,500", "$2,000", "$2,500", "$3,000"), rho = 0.28),
  list(panel = "Renters paying 30%+ of income (%)", title = "Renters paying 30% or more of income",
       xr = c(36, 67), brk = c(40, 45, 50, 55, 60, 65),
       lab = paste0(c(40, 45, 50, 55, 60, 65), "%"), rho = 0.29),
  list(panel = "Vacancy rate, narrow definition (%)", title = "Vacancy rate (narrow definition)",
       xr = c(1, 21), brk = c(2, 5, 10, 15, 20),
       lab = paste0(c(2, 5, 10, 15, 20), "%"), rho = -0.10)
)
tops <- c(1040, 800, 560); BOX_H <- 150
xl <- 120; xr_px <- 1030
yr <- c(1.2, 180); ybrk <- c(2, 5, 10, 20, 50, 100)
layers3 <- list(
  txt(50, 1300, "Where rents are higher, homelessness tends to be higher, but only loosely.",
      size = 5, bold = TRUE, wrap = 40, lh = 0.98)
)
for (i in seq_along(spec)) {
  s <- spec[[i]]; top <- tops[i]; bottom <- top - BOX_H
  ypx <- function(y) bottom + (log10(y) - log10(yr[1])) / diff(log10(yr)) * BOX_H
  xpx <- function(x) xl + (x - s$xr[1]) / diff(s$xr) * (xr_px - xl)
  dp <- d |> filter(panel == s$panel) |> mutate(px = xpx(x), py = ypx(y))
  stopifnot(nrow(dp) == 382, all(dp$x >= s$xr[1] & dp$x <= s$xr[2]),
            all(dp$y >= yr[1] & dp$y <= yr[2]))
  rho <- cor(dp$x, dp$y, method = "spearman")
  stopifnot(abs(rho - s$rho) < 0.006)
  grid <- tibble(gy = ypx(ybrk))
  layers3 <- c(layers3, list(
    geom_segment(data = grid, aes(x = xl, xend = xr_px, y = gy, yend = gy),
                 colour = "#1C232C", linewidth = 0.2),
    annotate("text", x = xl - 10, y = ypx(ybrk), label = ybrk, hjust = 1, size = 2.3, colour = dimc),
    geom_point(data = dp, aes(px, py), colour = cyan, size = 0.9, alpha = 0.6),
    annotate("segment", x = xl, xend = xr_px, y = bottom, yend = bottom, colour = "#2A323C", linewidth = 0.3),
    annotate("text", x = xpx(s$brk), y = bottom - 20, label = s$lab, size = 2.4, colour = dimc),
    txt(50, top + 34, s$title, size = 3.2, bold = TRUE, vjust = 0.5),
    txt(xr_px, top + 34, sprintf("rank correlation %.2f", rho), size = 3, col = dimc, hjust = 1, vjust = 0.5)
  ))
}
layers3 <- c(layers3, list(
  txt(50, 350, "Each dot is one of 382 regions. Vertical axis: people counted homeless per 10,000 residents (log scale). Rank correlation runs from -1 to 1; 0 means no link.",
      size = 2.5, col = dimc, wrap = 92, lh = 1.05),
  txt(50, 275, "That doesn't clearly support my own view that price is the main barrier. The map shows a mismatch, not a cause.",
      size = 3.5, wrap = 56),
  txt(50, 110, "Sources: ACS 2020-2024 (Census Bureau); HUD 2025 AHAR Part 1; HUD FY2025 CoC boundaries",
      size = 2.2, col = dimc)
))
save_slide(canvas(layers3), "map1/out/carousel_3_rents.png")

# ---- Slide 4: limits ----
items4 <- c(
  "Lynn, MA is too close to call (1.04 to 1). Six more regions are under 2 to 1.",
  "The highest ratios are in rural regions, where homelessness is hardest to count. The map may look more lopsided there than reality.",
  "Empty units may be in the wrong place, in poor condition, or unaffordable. Nothing here shows they could house these people.",
  "The homeless count is one night in January, and it is an undercount.",
  "Vacancy is a 2020-2024 survey average. Allowing for survey error, 381 of 382 regions still hold.",
  "Dots show the 8,664,169 units that could be placed in a region; the national total is 8,665,393. Dot positions are modeled, not measured.",
  "Territories are excluded. Suffolk County, NY has known gaps in three tables."
)
b4 <- bullets(items4, y0 = 1170, size = 3.7, wrap = 50, gap = 30)
cat("Slide 4 text ends at y =", round(attr(b4, "y_end")), "(must stay above about 130)\n")
stopifnot(attr(b4, "y_end") > 130)
s4 <- canvas(c(list(txt(50, 1290, "What this can't show", size = 6.2, bold = TRUE)), b4))
save_slide(s4, "map1/out/carousel_4_limits.png")

# ---- Slide 5: sources, method, my view ----
items5 <- c(
  "Vacant housing units: American Community Survey 2020-2024 5-year estimates (U.S. Census Bureau), tables B25002 and B25004.",
  "Rent, rent burden and population (slide 3): same survey, tables B25064, B25070 and B01003.",
  "People counted homeless: HUD 2025 Annual Homeless Assessment Report, Part 1. Point-in-time counts by region, one night in January 2025.",
  "Regions: HUD FY2025 Continuum of Care boundaries, 382 regions in 50 states and DC.",
  "How it is drawn: 1 dot = 100 units or people, with the same ink for both layers. Dots are placed in proportion to housing within each region, not at actual locations.",
  "Data pulled 2026-10-13. The test was written down before looking, with five amendments listed in the repo."
)
b5 <- bullets(items5, y0 = 1170, col_b = cyan)
y5 <- attr(b5, "y_end")
cat("Slide 5 sources end at y =", round(y5), "\n")
s5 <- canvas(c(
  list(txt(50, 1290, "Sources and method", size = 6.2, bold = TRUE)),
  b5,
  list(
    txt(50, y5 - 26, "My view (advocate)", size = 3.4, bold = TRUE, col = amber),
    txt(50, y5 - 70, "Price and policy, not a lack of buildings, is the main barrier. That is my reading, not something this map proves.",
        size = 3.4, wrap = 56),
    txt(50, 130, REPO_LINE, size = 3.1, col = dimc, vjust = 0.5),
    txt(50, 92, "This product uses the Census Bureau Data API but is not endorsed or certified by the Census Bureau.",
        size = 2.4, col = dimc, wrap = 82)
  )))
stopifnot(y5 - 70 - 3 * 3.4 * 9.48 * 1.1 > 150)       # my-view block must clear the footer
save_slide(s5, "map1/out/carousel_5_sources.png")
cat("Done. Date run:", format(Sys.Date()), "\n")
