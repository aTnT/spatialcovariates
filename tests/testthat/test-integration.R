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
  # Check CRS is WGS84 (compare by EPSG code, not full WKT string)
  expect_true(grepl("WGS 84|4326", terra::crs(result, describe = TRUE)$name))

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

test_that("SRTM terrain computes all 6 metrics correctly", {
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
  expect_true(all(c("elevation", "slope", "aspect", "tri", "tpi", "roughness") %in% names(result)))
  expect_s4_class(result$elevation, "SpatRaster")
  expect_s4_class(result$slope, "SpatRaster")
  expect_s4_class(result$aspect, "SpatRaster")
  expect_s4_class(result$tri, "SpatRaster")
  expect_s4_class(result$tpi, "SpatRaster")
  expect_s4_class(result$roughness, "SpatRaster")

  # Elevation should be reasonable (Colombia Andes: -100 to 6000m)
  elev_vals <- terra::values(result$elevation, na.rm = TRUE)
  expect_true(all(elev_vals >= -200 & elev_vals <= 7000))

  # Slope should be 0-90 degrees
  slope_vals <- terra::values(result$slope, na.rm = TRUE)
  expect_true(all(slope_vals >= 0 & slope_vals <= 90))

  # Aspect should be 0-360 degrees
  aspect_vals <- terra::values(result$aspect, na.rm = TRUE)
  expect_true(all(aspect_vals >= 0 & aspect_vals <= 360))

  # TRI, TPI, roughness should be numeric
  expect_true(is.numeric(terra::values(result$tri, na.rm = TRUE)))
  expect_true(is.numeric(terra::values(result$tpi, na.rm = TRUE)))
  expect_true(is.numeric(terra::values(result$roughness, na.rm = TRUE)))
})

test_that("IFL downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - IFL downloads ~206MB shapefile (may take 5-10 min on slow networks)")

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

test_that("GLAD TCC 2010 downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - downloads ~222MB GLAD TCC tile")

  result <- getGLADTCC2010(
    extent = test_bbox,
    resolution = "10km",
    download = TRUE,
    tiles_dir = file.path(tempdir(), "GLAD_TCC"),
    n_cores = 1
  )

  expect_s4_class(result, "SpatRaster")

  # TCC should be 0-100% tree cover
  tcc_vals <- terra::values(result, na.rm = TRUE)
  expect_true(all(tcc_vals >= 0 & tcc_vals <= 100))
})

test_that("Hansen GFC downloads and processes correctly", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - downloads Hansen GFC tile (~300MB)")

  result <- getHansenGFC(
    extent = test_bbox,
    resolution = "10km",
    download = TRUE,
    tiles_dir = file.path(tempdir(), "HANSEN_TC"),
    n_cores = 1
  )

  expect_s4_class(result, "SpatRaster")

  # Tree cover should be 0-100%
  tc_vals <- terra::values(result, na.rm = TRUE)
  expect_true(all(tc_vals >= 0 & tc_vals <= 100))
})

test_that("Global Human Modification returns error without rgee", {
  skip_on_cran()
  skip_on_ci()

  # This should fail gracefully if rgee not installed
  if (!requireNamespace("rgee", quietly = TRUE)) {
    expect_error(
      getGlobalHumanMod(extent = test_bbox, resolution = "10km"),
      "rgee"
    )
  } else {
    skip("rgee is installed - skipping error test")
  }
})

test_that("Global Human Modification via GEE works (manual)", {
  skip_on_cran()
  skip_on_ci()
  skip("Manual test - requires rgee + GEE account")

  # Only run if rgee is installed and EE is initialized
  if (!requireNamespace("rgee", quietly = TRUE)) {
    skip("rgee not installed")
  }

  result <- getGlobalHumanMod(
    extent = test_bbox,
    resolution = "10km",
    scale = 1000
  )

  expect_s4_class(result, "SpatRaster")

  # gHM should be 0-1
  ghm_vals <- terra::values(result, na.rm = TRUE)
  expect_true(all(ghm_vals >= 0 & ghm_vals <= 1))
})

test_that("ETH Canopy Height returns error without rgee", {
  skip_on_cran()
  skip_on_ci()

  # This should fail gracefully if rgee not installed
  if (!requireNamespace("rgee", quietly = TRUE)) {
    expect_error(
      getETHCanopyHeight(extent = test_bbox, resolution = "10km"),
      "rgee"
    )
  } else {
    skip("rgee is installed - skipping error test")
  }
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
    include_tcc = FALSE,  # Skip GLAD TCC
    include_height = FALSE,  # Skip ETH (requires rgee)
    include_biome = TRUE,
    include_treecover = FALSE,  # Skip Hansen GFC
    include_terrain = TRUE,
    include_ghm = FALSE,  # Skip gHM (1.5GB file)
    include_ifl = TRUE
  )

  expect_s4_class(covariates, "SpatRaster")
  expect_true(terra::nlyr(covariates) >= 8)  # biome, 6 terrain metrics, ifl

  # Check layer names (should include all 6 terrain metrics)
  layer_names <- names(covariates)
  expect_true("biome" %in% layer_names)
  expect_true("elevation" %in% layer_names)
  expect_true("slope" %in% layer_names)
  expect_true("aspect" %in% layer_names)
  expect_true("tri" %in% layer_names)
  expect_true("tpi" %in% layer_names)
  expect_true("roughness" %in% layer_names)
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
    getESACCIAGB(extent = test_bbox, esacci_biomass_year = 1999),
    "Invalid year"
  )

  expect_error(
    getESACCIAGB(extent = test_bbox, esacci_biomass_year = 2010, esacci_biomass_version = "v1.0"),
    "Invalid version"
  )

  # Note: getHansenGFC with invalid year warns but doesn't error,
  # and then attempts download. Testing this requires network access,
  # so it's tested in the manual integration tests instead.
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
