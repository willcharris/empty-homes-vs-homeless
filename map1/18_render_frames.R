# 18_render_frames.R  (v3, 2026-10-14: resumable, frees memory every 5 frames)
# Frames for the Map 1 vertical reveal (1080 x 1920, 30 fps, 20 s = 600 frames).
# Same glow rules as 17_render_still.R (equal ink per dot, cyan on top).
# Reads saved files only. Run from the project root.
#
# TEST <- TRUE  renders 5 sample frames to map1/out/frames_test/ (about 1 minute).
# TEST <- FALSE renders all 600 frames to map1/out/frames/ (about 20-30 minutes).
#
# Timeline (seconds):
#   0-2    title only (outlines fade in from 1 s)
#   2-9    amber layer fades in; vacant-unit counter ticks up
#   9-14   cyan layer fades in; homeless counter ticks up
#   14-17  hold: "11.7 to 1" and the strictest-definition line
#   17-20  limit line and sources
# The layers fade in for effect. It is NOT a time series, and the frame says so.
#
# Layout keeps key text out of the Reels interface zones (top ~250 px, bottom ~340 px).

TEST <- FALSE

library(tidyverse); library(sf); library(tigris)
options(tigris_use_cache = TRUE)

W <- 1080; H <- 1920; FPS <- 30; DUR <- 20
bg <- "#0B0F14"
col_amber <- c(201, 133, 0) / 255
col_cyan  <- c(30, 150, 186) / 255
GAIN_A <- 0.8; GAIN_C <- 0.8
STRICT_RATIO <- 7.0     # other-vacant-only 5,223,171 / 742,420 (results log)

dots <- read_csv("map1/data/dots_unit100.csv",
                 col_types = cols(GEOID = col_character()), show_col_types = FALSE)
stopifnot(nrow(dots) == 86642 + 7414)
v <- read_csv("map1/data/national_coc_vacancy_vs_pit.csv", show_col_types = FALSE)
narrow_total <- sum(v$narrow); homeless_total <- sum(v$homeless)
stopifnot(homeless_total == 742420)

# ---- State outlines and AK / HI insets (same as the still) ----
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

fips <- substr(dots$GEOID, 1, 2)
xy_all <- cbind(dots$x, dots$y)
for (abb in names(inset)) {
  s <- inset[[abb]]; i <- fips == s$fips
  pts <- st_as_sf(tibble(x = dots$x[i], y = dots$y[i]), coords = c("x", "y"), crs = 5070) |>
    st_transform(s$crs)
  xy_all[i, ] <- move(st_coordinates(pts), s)
}
dots$mx <- xy_all[, 1]; dots$my <- xy_all[, 2]

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

# ---- Map meters -> canvas pixels (map sits in the middle band of the tall canvas) ----
margin <- 50
sc <- (W - 2 * margin) / Wc
MAP_Y0 <- 820                      # was 460 on the 1350 px still
to_px <- function(d) mutate(d, px = (mx - cb["xmin"]) * sc + margin,
                               py = (my - cb["ymin"]) * sc + MAP_Y0)
dots_px <- to_px(dots); outline_px <- to_px(outline)
cat("Dots outside the canvas:", sum(dots_px$px < 0 | dots_px$px > W | dots_px$py < 0 | dots_px$py > H), "\n")
stopifnot(all(dots_px$px >= 0 & dots_px$px <= W & dots_px$py >= 0 & dots_px$py <= H))
cat("Map spans canvas y (from bottom):", round(min(dots_px$py)), "to", round(max(dots_px$py)), "\n")

# ---- Glow layers, computed once ----
blur <- function(m, sigma) {
  r <- ceiling(3 * sigma); k <- exp(-(-r:r)^2 / (2 * sigma^2))
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
cat("Computing glow layers...\n")
Ta <- layer_T(filter(dots_px, layer == "vacant"),   0.9, 3.5, 0.08, GAIN_A)
Tc <- layer_T(filter(dots_px, layer == "homeless"), 0.9, 3.5, 0.08, GAIN_C)
bgc <- as.numeric(col2rgb(bg)) / 255
fg <- "#E6EDF3"; dim <- "#8B949E"
ratio <- narrow_total / homeless_total

ease <- function(x) { x <- pmin(pmax(x, 0), 1); x * x * (3 - 2 * x) }   # smooth 0 -> 1

render_frame <- function(t, file) {
  a_a <- ease((t - 2) / 7)          # amber layer
  a_c <- ease((t - 9) / 5)          # cyan layer
  arr <- array(0, dim = c(H, W, 3))
  for (k in 1:3) {
    base <- pmin(bgc[k] + a_a * Ta * col_amber[k], 1)
    arr[, , k] <- (1 - a_c * Tc) * base + a_c * Tc * col_cyan[k]
  }
  n_a <- round(narrow_total * a_a); n_c <- round(homeless_total * a_c)
  l_a <- ease((t - 2) / 0.8)                          # amber legend row
  l_c <- ease((t - 9) / 0.8)                          # cyan legend row
  n_t <- ease((t - 2) / 0.8)                          # notes
  h_t <- ease((t - 14) / 0.6) * (1 - ease((t - 17) / 0.6))   # hold text
  e_t <- ease((t - 17) / 0.6)                         # limit line and sources
  o_t <- 0.6 * ease((t - 1) / 1)                      # outlines

  p <- ggplot() +
    annotation_raster(as.raster(arr), xmin = 0, xmax = W, ymin = 0, ymax = H, interpolate = FALSE) +
    geom_path(data = outline_px, aes(px, py, group = grp), colour = "#2A323C",
              linewidth = 0.12, alpha = o_t) +
    annotate("text", x = 50, y = 1650, label = "Are there more empty homes", hjust = 0,
             colour = fg, size = 6.2, fontface = "bold") +
    annotate("text", x = 50, y = 1583, label = "than homeless people?", hjust = 0,
             colour = fg, size = 6.2, fontface = "bold") +
    annotate("text", x = 50, y = 1520, hjust = 0, colour = dim, size = 3.1, alpha = n_t,
             label = "United States, 382 regions (HUD Continuums of Care)") +
    annotate("point", x = 62, y = 630, shape = 15, size = 3, colour = "#C98500", alpha = l_a) +
    annotate("text", x = 82, y = 630, hjust = 0, colour = fg, size = 3.3, alpha = l_a,
             label = sprintf("%s vacant housing units", scales::comma(n_a))) +
    annotate("point", x = 62, y = 590, shape = 15, size = 3, colour = "#1E96BA", alpha = l_c) +
    annotate("text", x = 82, y = 590, hjust = 0, colour = fg, size = 3.3, alpha = l_c,
             label = sprintf("%s people counted homeless, January 2025", scales::comma(n_c))) +
    annotate("text", x = 50, y = 545, hjust = 0, colour = fg, size = 4.2, fontface = "bold", alpha = h_t,
             label = sprintf("%.1f to 1   |   1 dot = 100", ratio)) +
    annotate("text", x = 50, y = 508, hjust = 0, colour = fg, size = 3.1, alpha = h_t,
             label = sprintf("%.1f to 1 even counting only the strictest definition", STRICT_RATIO)) +
    annotate("text", x = 50, y = 545, hjust = 0, vjust = 1, colour = fg, size = 3.5, lineheight = 1.05, alpha = e_t,
             label = str_wrap("These counts don't show that the empty units could house these people.", 52)) +
    annotate("text", x = 50, y = 455, hjust = 0, vjust = 1, colour = dim, size = 2.5, lineheight = 1.05, alpha = n_t,
             label = str_wrap("Dots are placed in proportion to housing within each region, not at actual locations. Layers fade in for effect; this is not a time series. Alaska is shown at 35% scale.", 92)) +
    annotate("text", x = 50, y = 380, hjust = 0, vjust = 1, colour = dim, size = 2.2, lineheight = 1.05, alpha = n_t,
             label = "Sources: ACS 2020-2024 (Census Bureau); HUD 2025 AHAR Part 1; HUD FY2025 CoC boundaries") +
    scale_x_continuous(limits = c(0, W), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, H), expand = c(0, 0)) +
    coord_fixed(expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = bg, colour = NA),
          plot.margin = margin(0, 0, 0, 0))
  ggsave(file, p, width = 4.5, height = 8, dpi = 240, bg = bg, device = ragg::agg_png)
}

if (TEST) {
  dir.create("map1/out/frames_test", recursive = TRUE, showWarnings = FALSE)
  tt <- c(1.0, 5.5, 11.5, 15.5, 18.8)
  for (i in seq_along(tt)) {
    f <- sprintf("map1/out/frames_test/test_%d_t%04.1f.png", i, tt[i])
    render_frame(tt[i], f); cat("wrote", f, "\n")
  }
  cat("TEST done. Open the 5 PNGs in map1/out/frames_test/ and check them.\n")
} else {
  dir.create("map1/out/frames", recursive = TRUE, showWarnings = FALSE)
  n <- FPS * DUR
  for (i in 1:n) {
    f <- sprintf("map1/out/frames/frame_%04d.png", i)
    if (file.exists(f) && file.size(f) > 10000) next      # already done: resume
    render_frame((i - 1) / FPS, f)
    if (i %% 5 == 0) invisible(gc())                       # free memory every 5 frames
    if (i %% 50 == 0) cat("frame", i, "of", n, format(Sys.time(), "%H:%M:%S"), "\n")
  }
  cat("All", n, "frames written to map1/out/frames/\n")
}
