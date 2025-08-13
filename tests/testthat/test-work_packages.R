test_that("create_wp creates directories correctly", {
  # Load the package functions
  devtools::load_all()

  # Test with a valid work package number
  wp_to_test <- 2
  create_wp(wp_to_test)

  analyses_path <- file.path("ANALYSES", paste0("WP", wp_to_test))
  output_path <- file.path("OUTPUT", paste0("WP", wp_to_test))

  # Check if directories are created
  expect_true(dir.exists(analyses_path))
  expect_true(dir.exists(output_path))

  # Clean up the created directories
  unlink(analyses_path, recursive = TRUE)
  unlink(output_path, recursive = TRUE)
})

test_that("create_wp handles invalid input", {
  # Load the package functions
  devtools::load_all()

  # Test with non-numeric input
  expect_error(create_wp("a"), "wp_number must be a positive integer.")

  # Test with a negative number
  expect_error(create_wp(-1), "wp_number must be a positive integer.")

  # Test with zero
  expect_error(create_wp(0), "wp_number must be a positive integer.")

  # Test with a non-integer number
  expect_error(create_wp(1.5), "wp_number must be a positive integer.")
})
