test_that("extract_raster_values works correctly", {
  # 1. Setup: Create sample data

  # Sample spatial points
  pts <- sf::st_as_sf(
    data.frame(id = 1:3, x = c(0.5, 1.5, 2.5), y = c(0.5, 1.5, 2.5)),
    coords = c("x", "y"),
    crs = 4326
  )

  # Sample raster 1 (e.g., DEM)
  r1 <- terra::rast(xmin = 0, xmax = 3, ymin = 0, ymax = 3, resolution = 1)
  terra::values(r1) <- 1:9

  # Sample raster 2 (e.g., Land Cover)
  r2 <- terra::rast(xmin = 0, xmax = 3, ymin = 0, ymax = 3, resolution = 1)
  terra::values(r2) <- 101:109

  raster_list <- list(dem = r1, land_cover = r2)

  # 2. Execution: Call the function
  result <- extract_raster_values(gps_data = pts, raster_list = raster_list)

  # 3. Assertions: Check the output

  # Check if the output is an sf object
  expect_true(inherits(result, "sf"))

  # Check if new columns are added
  expect_true("dem" %in% names(result))
  expect_true("land_cover" %in% names(result))

  # Check if the dimensions are correct
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 4) # id + dem + land_cover + geometry

  # Check if the extracted values are correct
  # Point 1 (0.5, 0.5) is in cell 1 -> value 1 from r1, 101 from r2
  # Point 2 (1.5, 1.5) is in cell 5 -> value 5 from r1, 105 from r2
  # Point 3 (2.5, 2.5) is in cell 9 -> value 9 from r1, 109 from r2
  expected_dem <- c(1, 5, 9)
  expected_lc <- c(101, 105, 109)

  expect_equal(result$dem, expected_dem)
  expect_equal(result$land_cover, expected_lc)
})
