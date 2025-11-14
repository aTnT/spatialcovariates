# Tests for ESA CCI Biomass functions

test_that("validate_esacci_args accepts valid inputs", {
  result <- validate_esacci_args(2010, "v3.0")
  expect_equal(result$year, 2010)
  expect_equal(result$version, "v3.0")
})

test_that("validate_esacci_args handles 'latest' keywords", {
  result <- validate_esacci_args("latest", "latest")
  expect_equal(result$year, 2022)
  expect_equal(result$version, "v6.0")
})

test_that("validate_esacci_args rejects invalid years", {
  expect_error(validate_esacci_args(1999, "v3.0"), "Invalid year")
  expect_error(validate_esacci_args(2023, "v3.0"), "Invalid year")
})

test_that("validate_esacci_args rejects invalid versions", {
  expect_error(validate_esacci_args(2010, "v1.0"), "Invalid version")
  expect_error(validate_esacci_args(2010, "v7.0"), "Invalid version")
})

test_that("validate_esacci_args enforces version-year constraints", {
  expect_error(validate_esacci_args(2020, "v2.0"), "only supports years")
  expect_error(validate_esacci_args(2022, "v4.0"), "only supports years")
})

test_that("esacci_tile_names generates correct format", {
  bbox <- c(-75, -10, -70, -5)
  tiles <- esacci_tile_names(bbox, 2010, "v3.0", type = "agb")

  expect_true(length(tiles) > 0)
  expect_true(all(grepl("ESACCI-BIOMASS", tiles)))
  expect_true(all(grepl("2010", tiles)))
  expect_true(all(grepl("v3\\.0", tiles)))
})

test_that("esacci_tile_names generates SD filenames correctly", {
  bbox <- c(-75, -10, -70, -5)
  tiles <- esacci_tile_names(bbox, 2010, "v3.0", type = "sd")

  expect_true(all(grepl("AGB_SD", tiles)))
})
