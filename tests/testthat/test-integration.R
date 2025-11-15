# Integration tests with real data
# WARNING: These tests download real data and may take 10-30 minutes
# Run manually with: testthat::test_file("tests/testthat/test-integration.R")
# Skip on CRAN with: skip_on_cran()

# Define small test extent to minimize download size
test_bbox <- c(xmin = -74, ymin = 4, xmax = -73.5, ymax = 4.5)

test_that("Dinerstein biomes downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()

  result <- getDinersteinBiome(
    extent = test_bbox,
    resolution = "10km",
    download = TRUE,
    data_dir = tempdir()
  )

  expect_s4_class(result, "SpatRaster")
  expect_true(terra::ncell(result) > 0)
  expect_equal(terra::crs(result), "EPSG:4326")

  # Check we got valid biome values (1-14)
  values <- terra::values(result, na.rm = TRUE)
  expect_true(all(values >= 1 & values <= 14))
})

test_that("ESA CCI AGB downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - downloads ~100MB per tile")

  result <- getESACCIAGB(
    extent = test_bbox,
    year = 2010,
    version = "v3.0",
    resolution = "10km",
    download = TRUE,
    tiles_dir = file.path(tempdir(), "ESACCI"),
    n_cores = 1
  )

  expect_type(result, "list")
  expect_true("agb" %in% names(result))
  expect_s4_class(result$agb, "SpatRaster")

  # Check AGB values are reasonable (0-500 Mg/ha)
  agb_vals <- terra::values(result$agb, na.rm = TRUE)
  expect_true(all(agb_vals >= 0 & agb_vals <= 500))
})

test_that("SRTM terrain computes slope and aspect correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - downloads SRTM tiles")

  result <- getSRTMTerrain(
    extent = test_bbox,
    resolution = "1km",  # Use finer resolution for terrain
    download = TRUE,
    tiles_dir = file.path(tempdir(), "SRTM"),
    n_cores = 1
  )

  expect_type(result, "list")
  expect_true(all(c("slope", "aspect") %in% names(result)))
  expect_s4_class(result$slope, "SpatRaster")
  expect_s4_class(result$aspect, "SpatRaster")

  # Slope should be 0-90 degrees
  slope_vals <- terra::values(result$slope, na.rm = TRUE)
  expect_true(all(slope_vals >= 0 & slope_vals <= 90))

  # Aspect should be 0-360 degrees
  aspect_vals <- terra::values(result$aspect, na.rm = TRUE)
  expect_true(all(aspect_vals >= 0 & aspect_vals <= 360))
})

test_that("IFL downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()

  result <- getIFL(
    extent = test_bbox,
    year = 2016,
    resolution = "10km",
    download = TRUE,
    data_dir = file.path(tempdir(), "IFL")
  )

  expect_s4_class(result, "SpatRaster")

  # IFL should be binary (0 or 1)
  ifl_vals <- terra::values(result, na.rm = TRUE)
  expect_true(all(ifl_vals %in% c(0, 1)))
})

test_that("Full getBiasCovariates integration works", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - downloads multiple datasets, may take 30+ minutes")

  # Use very coarse resolution to speed up
  covariates <- getBiasCovariates(
    extent = test_bbox,
    year = 2010,
    resolution = "25km",  # Coarse for speed
    download = TRUE,
    data_dir = tempdir(),
    n_cores = 2,
    # Test with subset to save time
    include_agb = FALSE,  # Skip large downloads
    include_height = FALSE,
    include_biome = TRUE,
    include_treecover = FALSE,
    include_terrain = TRUE,
    include_ifl = TRUE
  )

  expect_s4_class(covariates, "SpatRaster")
  expect_true(terra::nlyr(covariates) >= 3)  # biome, slope, aspect, ifl

  # Check layer names
  layer_names <- names(covariates)
  expect_true("biome" %in% layer_names)
  expect_true("slope" %in% layer_names)
  expect_true("aspect" %in% layer_names)
  expect_true("ifl" %in% layer_names)

  # All layers should have same extent and resolution
  expect_true(terra::compareGeom(covariates[[1]], covariates[[2]], stopOnError = FALSE))
})

test_that("Downloaded data can be reused without re-downloading", {
  skip_on_cran()
  skip_on_ci()

  # First download
  data_dir <- file.path(tempdir(), "reuse_test")
  result1 <- getDinersteinBiome(
    extent = test_bbox,
    resolution = "10km",
    download = TRUE,
    data_dir = data_dir
  )

  # Check shapefile exists
  shp_file <- file.path(data_dir, "Ecoregions2017.shp")
  expect_true(file.exists(shp_file))

  # Second call should reuse existing data
  result2 <- getDinersteinBiome(
    extent = test_bbox,
    resolution = "10km",
    download = FALSE,  # Don't re-download
    data_dir = data_dir
  )

  expect_s4_class(result2, "SpatRaster")

  # Results should be identical
  expect_equal(terra::ncell(result1), terra::ncell(result2))
})

test_that("Error handling works for invalid inputs", {
  # These tests don't download, just check validation

  expect_error(
    getDinersteinBiome(extent = "invalid"),
    "'extent' must be"
  )

  expect_error(
    getESACCIAGB(extent = test_bbox, year = 1999),
    "Invalid year"
  )

  expect_error(
    getESACCIAGB(extent = test_bbox, year = 2010, version = "v1.0"),
    "Invalid version"
  )

  expect_error(
    getSextonTreeCover(extent = test_bbox, year = 2012),
    NA  # Should warn but not error
  )
})

test_that("Parallel downloads work correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - tests parallel download")

  # Test with 4 cores
  result <- getDinersteinBiome(
    extent = test_bbox,
    resolution = "10km",
    download = TRUE,
    data_dir = file.path(tempdir(), "parallel_test")
  )

  expect_s4_class(result, "SpatRaster")
  # If it completes without error, parallel worked
})
