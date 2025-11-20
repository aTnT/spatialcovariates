# Tests for utility functions

test_that("validate_extent works with numeric bbox", {
  bbox <- c(-75, -10, -70, -5)  # xmin, ymin, xmax, ymax
  result <- validate_extent(bbox)
  expect_equal(length(result), 4)
  expect_equal(names(result), c("xmin", "ymin", "xmax", "ymax"))
})

test_that("validate_extent rejects invalid input", {
  expect_error(validate_extent("invalid"), "'extent' must be")
  expect_error(validate_extent(c(1, 2, 3)), "'extent' must be")
})

test_that("validate_extent catches wrong coordinate order", {
  # xmin > xmax
  expect_error(
    validate_extent(c(-70, -10, -75, -5)),
    "xmin.*must be < xmax.*wrong order"
  )

  # ymin > ymax
  expect_error(
    validate_extent(c(-75, -5, -70, -10)),
    "ymin.*must be < ymax.*wrong order"
  )
})

test_that("validate_extent catches invalid coordinate ranges", {
  # Invalid longitude
  expect_error(
    validate_extent(c(-200, -10, -70, -5)),
    "Invalid longitude.*between -180 and 180"
  )

  # Invalid latitude
  expect_error(
    validate_extent(c(-75, -100, -70, -5)),
    "Invalid latitude.*between -90 and 90"
  )
})

test_that("parse_resolution handles km correctly", {
  expect_equal(parse_resolution("10km"), 10000)
  expect_equal(parse_resolution("1km"), 1000)
  expect_equal(parse_resolution("5km"), 5000)
})

test_that("parse_resolution handles meters correctly", {
  expect_equal(parse_resolution("1000m"), 1000)
  expect_equal(parse_resolution("500m"), 500)
})

test_that("parse_resolution handles numeric input", {
  expect_equal(parse_resolution(10000), 10000)
})

test_that("calc_aggregation_factor works correctly", {
  expect_equal(calc_aggregation_factor(30, 300), 10)
  expect_equal(calc_aggregation_factor(100, 1000), 10)
  expect_equal(calc_aggregation_factor(90, 10000), 111)
})

test_that("calc_aggregation_factor handles edge cases", {
  expect_equal(calc_aggregation_factor(100, 100), 1)
  expect_warning(calc_aggregation_factor(100, 50))
})

test_that("calculate_tile_names generates correct format", {
  bbox <- c(-75, -10, -70, -5)  # xmin, ymin, xmax, ymax
  tiles <- calculate_tile_names(bbox, tile_size = 10)

  expect_true(length(tiles) > 0)
  expect_true(all(grepl("^\\d{2}[NS]_\\d{3}[EW]$", tiles)))
})

test_that("ensure_directory creates directory", {
  test_dir <- tempfile()
  expect_false(dir.exists(test_dir))

  suppressMessages(ensure_directory(test_dir))
  expect_true(dir.exists(test_dir))

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("ensure_directory handles NULL input", {
  expect_silent(ensure_directory(NULL))
})
