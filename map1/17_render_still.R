# 17_render_still.R  (v3, locked 2026-10-14)
# Still of Map 1 (1080 x 1350, the 4:5 carousel size).
# Reads saved files only. Run from the project root.
#
# Rendering rules (these are design decisions and belong in the methodology note):
# - Both layers get the SAME ink per dot: same core size (sigma 0.9 px), same halo
#   (sigma 3.5 px, weight 0.08) and same gain (0.8). Dot COUNTS are 1:1 per 100 units
#   or people, and the picture does not exaggerate either layer.
# - Amber (vacant units) is added to the background; cyan (homeless) is composited ON
#   TOP so each cyan dot stays visible against the amber (spec).
# - An earlier version drew cyan larger and brighter; that made metros look mostly
#   homeless and was rejected because it distorted the 11.7 to 1 ratio.
# - Dot positions are modeled (tract drawn in proportion to housing units); see
#   16_make_dots.R. Alaska is inset at 35% scale; Hawaii at full scale.

library(tidyverse); library(sf); library(tigris)
options(tigris_use_cache = TRUE)

W <- 1080; H <- 1350
bg <- "#0B0F14"
col_amber <- c(201, 133, 0) / 255      # #C98500 (palette check passed, dark mode)
col_cyan  <- c(30, 150, 186) / 255     # #1E96BA (palette check passed, dark mode)
GAIN_A <- 0.8                          # same gain for both layers
GAIN_C <- 0.8

dots <- read_csv("map1/data/dots_unit100.csv",
                 col_types = cols(GEOID = col_character()), show_col_types = FALSE)
stopifnot(nrow(dots) == 86642 + 7414)
v <- read_csv("map1/data/national_coc_vacancy_vs_pit.csv", show_col_types = FALSE)
narrow_total <- sum(v$narrow); homeless_total <- sum(v$homeless)
stopifnot(homeless_total == 742420)

# ---- State outlines and the AK / HI insets (coordinate arithmetic, no sfc maths) ----
st <- states(cb = TRUE, resolution = "20m", year = 2023, progress_bar = FALSE) |>
  filter(STUSPS %in% c(state.abb, "DC")) |> select(STUSPS)
st5070 <- st_transform(st, 5070)
cb <- st_bbox(filter(st5070, !STUSPS %in% c("AK", "HI")))
Wc <- as.numeric(cb["xmax"] - cb["xmin"]); Hc <- as.numeric(cb["ymax"] - cb["ymin"])

crs_ak <- st_crs(3338)
crs_hi <- st_crs("+proj=aea +lat_1=8 +lat_2=18 +lat_0=13 +lon_0=-157 +datum=NAD83 +units=m +no_defs")
inset <- list(
  AK = list(fips = "02", crs = crs_ak, scale = 0.35,
            target = c(cb["xmin"] + 0.12 * Wc, cb["ymin"] - 0.14 * Hc)),
  HI = list(fips = "15", crs = crs_hi, scale = 1.0,
            target = c(cb["xmin"] + 0.38 * Wc, cb["ymin"] - 0.12 * Hc))
)
inset <- map(inset, \(s) { s$target <- as.numeric(s$target); s })
for (abb in names(inset)) {
  g <- st_transform(filter(st, STUSPS == abb), inset[[abb]]$crs)
  b <- st_bbox(g)
  inset[[abb]]$anchor <- c((b["xmin"] + b["xmax"]) / 2, (b["ymin"] + b["ymax"]) / 2) |> as.numeric()
}
move <- function(xy, s) sweep(sweep(xy, 2, s$anchor, "-") * s$scale, 2, s$target, "+")

# dots
fips <- substr(dots$GEOID, 1, 2)
xy_all <- cbind(dots$x, dots$y)
for (abb in names(inset)) {
  s <- inset[[abb]]; i <- fips == s$fips
  pts <- st_as_sf(tibble(x = dots$x[i], y = dots$y[i]), coords = c("x", "y"), crs = 5070) |>
    st_transform(s$crs)
  xy_all[i, ] <- move(st_coordinates(pts), s)
}
dots$mx <- xy_all[, 1]; dots$my <- xy_all[, 2]

# outlines
outline_df <- function(sfobj, s = NULL) {
  g <- if (is.null(s)) st_transform(sfobj, 5070) else st_transform(sfobj, s$crs)
  g <- st_cast(g, "MULTIPOLYGON")
  m <- st_coordinates(g)
  xy <- m[, c("X", "Y")]
  if (!is.null(s)) xy <- move(xy, s)
  tibble(mx = xy[, 1], my = xy[, 2], grp = paste(m[, "L1"], m[, "L2"], m[, "L3"], sep = "_"))
}
outline <- bind_rows(
  outline_df(filter(st, !STUSPS %in% c("AK", "HI"))) |> mutate(grp = paste0("c", grp)),
  outline_df(filter(st, STUSPS == "AK"), inset$AK) |> mutate(grp = paste0("a", grp)),
  outline_df(filter(st, STUSPS == "HI"), inset$HI) |> mutate(grp = paste0("h", grp))
)

# ---- Map meters -> canvas pixels ----
margin <- 50
sc <- (W - 2 * margin) / Wc
to_px <- function(d) mutate(d, px = (mx - cb["xmin"]) * sc + margin,
                               py = (my - cb["ymin"]) * sc + 460)
dots_px <- to_px(dots); outline_px <- to_px(outline)
cat("Dots outside the canvas:", sum(dots_px$px < 0 | dots_px$px > W | dots_px$py < 0 | dots_px$py > H), "\n")
stopifnot(all(dots_px$px >= 0 & dots_px$px <= W & dots_px$py >= 0 & dots_px$py <= H))

# ---- Glow in the pixel grid ----
blur <- function(m, sigma) {
  r <- ceiling(3 * sigma); k <- exp(-(-r:r)^2 / (2 * sigma^2))   # peak = 1
  f <- function(x) { o <- stats::filter(x, k, sides = 2); o[is.na(o)] <- 0; as.numeric(o) }
  m1 <- t(apply(m, 1, f))
  apply(m1, 2, f)
}
layer_T <- function(d, sigma_core, sigma_halo, halo_w, gain) {
  col <- pmin(pmax(floor(d$px) + 1, 1), W)
  row <- pmin(pmax(H - floor(d$py), 1), H)
  cnt <- matrix(tabulate((col - 1) * H + row, nbins = H * W), nrow = H, ncol = W)
  I <- blur(cnt, sigma_core) + halo_w * blur(cnt, sigma_halo)
  1 - exp(-gain * I)
}
Ta <- layer_T(filter(dots_px, layer == "vacant"),   0.9, 3.5, 0.08, GAIN_A)
Tc <- layer_T(filter(dots_px, layer == "homeless"), 0.9, 3.5, 0.08, GAIN_C)

bgc <- as.numeric(col2rgb(bg)) / 255
arr <- array(0, dim = c(H, W, 3))
for (k in 1:3) {
  base <- pmin(bgc[k] + Ta * col_amber[k], 1)          # amber added to the background
  arr[, , k] <- (1 - Tc) * base + Tc * col_cyan[k]      # cyan composited on top
}

# ---- Frame: title, legend, notes, credits ----
fg <- "#E6EDF3"; dim <- "#8B949E"
ratio <- narrow_total / homeless_total
p <- ggplot() +
  annotation_raster(as.raster(arr), xmin = 0, xmax = W, ymin = 0, ymax = H, interpolate = FALSE) +
  geom_path(data = outline_px, aes(px, py, group = grp), colour = "#2A323C",
            linewidth = 0.12, alpha = 0.6) +
  annotate("text", x = 50, y = 1295, label = "Are there more empty homes", hjust = 0,
           colour = fg, size = 6.2, fontface = "bold") +
  annotate("text", x = 50, y = 1228, label = "than homeless people?", hjust = 0,
           colour = fg, size = 6.2, fontface = "bold") +
  annotate("text", x = 50, y = 1165, hjust = 0, colour = dim, size = 3.1,
           label = "United States, 382 regions (HUD Continuums of Care)") +
  annotate("point", x = 62, y = 240, shape = 15, size = 3, colour = "#C98500") +
  annotate("text", x = 82, y = 240, hjust = 0, colour = fg, size = 3.3,
           label = sprintf("%s vacant housing units (for rent, for sale or other)",
                           scales::comma(narrow_total))) +
  annotate("point", x = 62, y = 200, shape = 15, size = 3, colour = "#1E96BA") +
  annotate("text", x = 82, y = 200, hjust = 0, colour = fg, size = 3.3,
           label = sprintf("%s people counted homeless, January 2025",
                           scales::comma(homeless_total))) +
  annotate("text", x = 50, y = 160, hjust = 0, colour = fg, size = 3.3, fontface = "bold",
           label = sprintf("%.1f to 1   |   1 dot = 100", ratio)) +
  annotate("text", x = 50, y = 136, hjust = 0, vjust = 1, colour = dim, size = 2.5, lineheight = 1.05,
           label = str_wrap("Dots are placed in proportion to housing within each region, not at actual locations. Alaska is shown at 35% scale.", 75)) +
  annotate("text", x = 50, y = 62, hjust = 0, vjust = 1, colour = dim, size = 2.3, lineheight = 1.05,
           label = str_wrap("Sources: ACS 2020-2024 5-year (U.S. Census Bureau); HUD 2025 AHAR Part 1; HUD FY2025 CoC boundaries.", 85)) +
  scale_x_continuous(limits = c(0, W), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, H), expand = c(0, 0)) +
  coord_fixed(expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = bg, colour = NA),
        plot.margin = margin(0, 0, 0, 0))

dir.create("map1/out", showWarnings = FALSE)
ggsave("map1/out/map1_still_4x5.png", p, width = 4.5, height = 5.625, dpi = 240, bg = bg)
cat("Saved map1/out/map1_still_4x5.png (1080 x 1350). Date run:", format(Sys.Date()), "\n")
