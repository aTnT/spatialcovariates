# Tests for ESA CCI Biomass functions

test_that("validate_esacci_biomass_args accepts valid inputs", {
  result <- validate_esacci_biomass_args(2010, "v3.0")
  expect_equal(result$esacci_biomass_year, 2010)
  expect_equal(result$esacci_biomass_version, "v3.0")
})

test_that("validate_esacci_biomass_args handles 'latest' keywords", {
  result <- validate_esacci_biomass_args("latest", "latest")
  expect_equal(result$esacci_biomass_year, 2022)
  expect_equal(result$esacci_biomass_version, "v6.0")
})

test_that("validate_esacci_biomass_args accepts year 2007 for v6.0", {
  result <- validate_esacci_biomass_args(2007, "v6.0")
  expect_equal(result$esacci_biomass_year, 2007)
  expect_equal(result$esacci_biomass_version, "v6.0")
})

test_that("validate_esacci_biomass_args rejects invalid years", {
  expect_error(validate_esacci_biomass_args(1999, "v3.0"), "Invalid year")
  expect_error(validate_esacci_biomass_args(2023, "v3.0"), "Invalid year")
})

test_that("validate_esacci_biomass_args rejects invalid versions", {
  expect_error(validate_esacci_biomass_args(2010, "v1.0"), "Invalid version")
  expect_error(validate_esacci_biomass_args(2010, "v7.0"), "Invalid version")
})

test_that("validate_esacci_biomass_args enforces version-year constraints", {
  expect_error(validate_esacci_biomass_args(2020, "v2.0"), "only supports years")
  expect_error(validate_esacci_biomass_args(2022, "v4.0"), "only supports years")
  expect_error(validate_esacci_biomass_args(2007, "v5.0"), "only supports years")
})

test_that("validate_esacci_biomass_args accepts all v6.0 years", {
  v6_years <- c(2007, 2010, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022)
  for (year in v6_years) {
    result <- validate_esacci_biomass_args(year, "v6.0")
    expect_equal(result$esacci_biomass_year, year)
  }
})

test_that("esacci_tile_names generates correct format", {
  bbox <- c(-75, -10, -70, -5)  # xmin, ymin, xmax, ymax
  tiles <- esacci_tile_names(bbox, 2010, "v3.0", type = "agb")

  expect_true(length(tiles) > 0)
  expect_true(all(grepl("ESACCI-BIOMASS", tiles)))
  expect_true(all(grepl("2010", tiles)))
  expect_true(all(grepl("fv3\\.0", tiles)))
})

test_that("esacci_tile_names generates SD filenames correctly", {
  bbox <- c(-75, -10, -70, -5)  # xmin, ymin, xmax, ymax
  tiles <- esacci_tile_names(bbox, 2010, "v3.0", type = "sd")

  expect_true(all(grepl("AGB_SD", tiles)))
})

test_that("esacci_tile_names works with v6.0 and year 2007", {
  bbox <- c(-75, -10, -70, -5)  # xmin, ymin, xmax, ymax
  tiles <- esacci_tile_names(bbox, 2007, "v6.0", type = "agb")

  expect_true(length(tiles) > 0)
  expect_true(all(grepl("2007", tiles)))
  expect_true(all(grepl("fv6\\.0", tiles)))
})

test_that("ESACCIAGBtileNames is Plot2Map compatible", {
  # Create a simple bbox as sf object
  bbox <- sf::st_bbox(c(xmin = -75, ymin = -10, xmax = -70, ymax = -5), crs = 4326)
  bbox <- sf::st_as_sfc(bbox)

  tiles <- ESACCIAGBtileNames(bbox, esacci_biomass_year = 2010, esacci_biomass_version = "v6.0")

  expect_true(length(tiles) > 0)
  expect_true(all(grepl("ESACCI-BIOMASS", tiles)))
  expect_true(all(grepl("2010", tiles)))
  expect_true(all(grepl("fv6\\.0", tiles)))
})
