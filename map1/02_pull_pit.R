dir.create("map1/data", showWarnings = FALSE)
download.file(
  "https://www.huduser.gov/portal/sites/default/files/xls/2007-2025-PIT-Counts-by-CoC.xlsb",
  destfile = "map1/data/2007-2025-PIT-Counts-by-CoC.xlsb",
  mode = "wb")   # "wb" matters on Windows
file.size("map1/data/2007-2025-PIT-Counts-by-CoC.xlsb")
