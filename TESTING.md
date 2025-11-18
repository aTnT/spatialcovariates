# Testing Guide for spatialcovariates

## Prerequisites

Ensure you have R (\>= 4.0) installed with the following packages:

``` r
install.packages(c("devtools", "testthat", "roxygen2", "rcmdcheck"))
```

## Quick Test

Run the automated test script from the package root directory:

``` bash
cd /path/to/spatialcovariates
Rscript run_tests.R
```

This will: 1. Generate documentation 2. Load the package 3. Run unit
tests 4. Perform R CMD check 5. Test basic functionality

## Manual Testing Steps

### 1. Generate Documentation

``` r
devtools::document()
```

This creates the `man/` directory with .Rd files for all documented
functions.

### 2. Load Package

``` r
devtools::load_all()
```

### 3. Run Unit Tests

``` r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-utils.R")
```

### 4. R CMD Check

``` r
# Standard check
devtools::check()

# CRAN-style check
devtools::check(args = c("--as-cran"))
```

Expected results: - **0 errors** - **0 warnings** - **0-1 notes** (NOTE
about new package is acceptable)

### 5. Test Coverage

``` r
# Install covr package
install.packages("covr")

# Calculate test coverage
covr::package_coverage()
```

Target: \>80% code coverage

## Functional Tests

### Test 1: Utility Functions

``` r
library(spatialcovariates)

# Test extent validation
bbox <- c(-75, -10, -70, -5)
validated <- spatialcovariates:::validate_extent(bbox)
print(validated)

# Test resolution parsing
res_meters <- spatialcovariates:::parse_resolution("10km")
stopifnot(res_meters == 10000)

# Test tile name generation
tiles <- spatialcovariates:::calculate_tile_names(bbox, tile_size = 10)
print(tiles)
```

### Test 2: ESA CCI Validation

``` r
library(spatialcovariates)

# Test year/version validation
result <- spatialcovariates:::validate_esacci_args(2010, "v3.0")
stopifnot(result$year == 2010)
stopifnot(result$version == "v3.0")

# Test tile naming
bbox <- c(-75, -10, -70, -5)
tiles <- spatialcovariates:::esacci_tile_names(bbox, 2010, "v3.0", type = "agb")
print(tiles)
```

### Test 3: Download Functions (requires internet)

**WARNING**: These tests will download real data. Use a small extent.

``` r
library(spatialcovariates)

# Small test extent in Colombia
test_bbox <- c(xmin = -74, ymin = 4, xmax = -73, ymax = 5)

# Test Dinerstein biomes (downloads global shapefile ~50 MB)
biomes <- getDinersteinBiome(
  extent = test_bbox,
  resolution = "10km",
  download = TRUE
)
plot(biomes, main = "Test: Dinerstein Biomes")

# Test ESA CCI download (1-2 tiles)
# WARNING: Each tile is ~100 MB
agb <- getESACCIAGB(
  extent = test_bbox,
  year = 2010,
  version = "v3.0",
  resolution = "10km",
  n_cores = 2
)
plot(agb$agb, main = "Test: ESA CCI AGB")
```

### Test 4: Full Integration Test

``` r
library(spatialcovariates)

# Very small test extent
small_bbox <- c(xmin = -74, ymin = 4, xmax = -73, ymax = 5)

# Fetch all covariates (will download several GB of data!)
covariates <- getBiasCovariates(
  extent = small_bbox,
  year = 2010,
  resolution = "25km",  # Use coarser resolution for testing
  n_cores = 4,
  download = TRUE
)

# Verify stack
print(names(covariates))
plot(covariates)
```

## Troubleshooting

### Error: “Failed to read shapefile”

Ensure you have write permissions in the data directory and sufficient
disk space.

### Error: “Failed to download”

Check internet connectivity and firewall settings. Some data sources may
be temporarily unavailable.

### Error: “Package ‘terra’ not available”

Install required spatial packages:

``` r
install.packages(c("terra", "sf"))
```

### Memory Issues

For large extents, increase R memory limit:

``` r
# Windows
memory.limit(size = 16000)  # 16 GB

# Linux/Mac (set before starting R)
# ulimit -s unlimited
```

## Performance Benchmarks

Expected download times (single tile, 50 Mbps connection):

| Dataset             | Tile Size | Time   |
|---------------------|-----------|--------|
| ESA CCI AGB         | 100 MB    | 15-20s |
| Potapov Height      | 200 MB    | 30-40s |
| Sexton Tree Cover   | 150 MB    | 20-30s |
| SRTM DEM            | 20 MB     | 5-10s  |
| Dinerstein (global) | 50 MB     | 10-15s |
| IFL (global)        | 30 MB     | 5-10s  |

Processing times (10km resolution, single tile, 4 cores):

| Operation              | Time   |
|------------------------|--------|
| Crop & Mosaic          | 5-10s  |
| Aggregate (30m → 10km) | 20-60s |
| Terrain computation    | 10-20s |
| Stack all covariates   | 2-5min |

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/R-CMD-check.yaml`:

``` yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

name: R-CMD-check

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck
          needs: check

      - uses: r-lib/actions/check-r-package@v2
```

## Pre-CRAN Checklist

Before submitting to CRAN:

`devtools::check()` passes with 0 errors, 0 warnings, 0 notes

All examples run without errors

Documentation is complete and accurate

NEWS.md is updated

Version number is incremented

All URLs in documentation are valid

`devtools::spell_check()` passes

Package builds on Windows, Mac, and Linux (use rhub)

Test coverage \>80%

No calls to
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html) in
code

No [`library()`](https://rdrr.io/r/base/library.html) calls in functions
(use `::` or
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html))

LICENSE file is correct

DESCRIPTION file is complete

## Getting Help

- Package documentation:
  [`?spatialcovariates`](https://atnt.github.io/spatialcovariates/reference/spatialcovariates-package.md)
- Function help:
  [`?getBiasCovariates`](https://atnt.github.io/spatialcovariates/reference/getBiasCovariates.md)
- Run examples: `example(getBiasCovariates)`
- Report issues: <https://github.com/aTnT/spatialcovariates/issues>
