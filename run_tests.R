#!/usr/bin/env Rscript
# Test script for spatialcovariates package
# Run this script from the package root directory

cat("================================\n")
cat("spatialcovariates Package Tests\n")
cat("================================\n\n")

# Check if required packages are installed
required_packages <- c("devtools", "testthat", "roxygen2", "rcmdcheck")
missing <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing) > 0) {
  cat("Installing required packages:", paste(missing, collapse = ", "), "\n")
  install.packages(missing)
}

library(devtools)
library(testthat)

cat("\n=== Step 1: Generate documentation ===\n")
tryCatch({
  document()
  cat("✓ Documentation generated successfully\n")
}, error = function(e) {
  cat("✗ Documentation generation failed:", e$message, "\n")
  stop(e)
})

cat("\n=== Step 2: Load package ===\n")
tryCatch({
  load_all()
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Package loading failed:", e$message, "\n")
  stop(e)
})

cat("\n=== Step 3: Run unit tests ===\n")
tryCatch({
  test_results <- test()
  cat("✓ Tests completed\n")
  print(test_results)
}, error = function(e) {
  cat("✗ Tests failed:", e$message, "\n")
})

cat("\n=== Step 4: Check package ===\n")
cat("Running R CMD check (this may take a few minutes)...\n\n")
tryCatch({
  check_results <- rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))
  cat("\n✓ R CMD check completed\n\n")
  print(check_results)

  # Summary
  cat("\n=================================\n")
  cat("CHECK SUMMARY\n")
  cat("=================================\n")
  cat("Errors:  ", length(check_results$errors), "\n")
  cat("Warnings:", length(check_results$warnings), "\n")
  cat("Notes:   ", length(check_results$notes), "\n")

  if (length(check_results$errors) > 0) {
    cat("\n✗ Package has errors!\n")
  } else if (length(check_results$warnings) > 0) {
    cat("\n⚠ Package has warnings\n")
  } else if (length(check_results$notes) > 0) {
    cat("\n⚠ Package has notes\n")
  } else {
    cat("\n✓ Package passed all checks!\n")
  }
}, error = function(e) {
  cat("✗ R CMD check failed:", e$message, "\n")
})

cat("\n=== Step 5: Test basic functionality ===\n")
cat("Testing utility functions with sample data...\n\n")

# Test validate_extent
cat("Testing validate_extent()... ")
tryCatch({
  bbox <- c(-75, -10, -70, -5)
  result <- spatialcovariates:::validate_extent(bbox)
  stopifnot(length(result) == 4)
  stopifnot(all(names(result) == c("xmin", "ymin", "xmax", "ymax")))
  cat("✓\n")
}, error = function(e) {
  cat("✗:", e$message, "\n")
})

# Test parse_resolution
cat("Testing parse_resolution()... ")
tryCatch({
  stopifnot(spatialcovariates:::parse_resolution("10km") == 10000)
  stopifnot(spatialcovariates:::parse_resolution("1000m") == 1000)
  cat("✓\n")
}, error = function(e) {
  cat("✗:", e$message, "\n")
})

# Test calc_aggregation_factor
cat("Testing calc_aggregation_factor()... ")
tryCatch({
  stopifnot(spatialcovariates:::calc_aggregation_factor(30, 300) == 10)
  stopifnot(spatialcovariates:::calc_aggregation_factor(100, 1000) == 10)
  cat("✓\n")
}, error = function(e) {
  cat("✗:", e$message, "\n")
})

# Test calculate_tile_names
cat("Testing calculate_tile_names()... ")
tryCatch({
  bbox <- c(-75, -10, -70, -5)
  tiles <- spatialcovariates:::calculate_tile_names(bbox, tile_size = 10)
  stopifnot(length(tiles) > 0)
  stopifnot(all(grepl("^\\d{2}[NS]_\\d{3}[EW]$", tiles)))
  cat("✓\n")
}, error = function(e) {
  cat("✗:", e$message, "\n")
})

cat("\n=================================\n")
cat("TESTING COMPLETE\n")
cat("=================================\n")
cat("\nFor manual testing with real data, try:\n")
cat('  library(spatialcovariates)\n')
cat('  bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)\n')
cat('  covariates <- getBiasCovariates(extent = bbox, year = 2010, resolution = "10km")\n')
cat('\n')
