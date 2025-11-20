# spatialcovariates 0.1.1 (Development)

## Function Default Changes

* **`getBiasCovariates()`**: Changed `include_agb` parameter default from `TRUE` to `FALSE`
  - **Rationale**: Avoids duplicate downloads when users fetch AGB and SD separately
    using `getESACCIAGB()`, which is often required for Plot2Map workflows.
  - **Migration**: For Plot2Map workflows, use the recommended two-step approach:
    ```r
    # Step 1: Get AGB and SD together (if required)
    biomass <- getESACCIAGB(extent = bbox, year = 2010, resolution = "10km")
    agb_map <- biomass$agb
    sd_map <- biomass$sd

    # Step 2: Get environmental covariates (no duplication)
    covariates <- getBiasCovariates(extent = bbox, year = 2010, resolution = "10km")
    ```
  - **Backward compatibility**: Set `include_agb = TRUE` to restore previous behavior

## Documentation Improvements

* Updated `getBiasCovariates()` documentation to clarify AGB/SD separation
* Added `@note` explaining recommended workflow for Plot2Map users
* Updated examples to demonstrate optimized two-step covariate fetching

# spatialcovariates 0.1.0

## Initial Release

* Core covariate fetching functions:
  - `getESACCIAGB()`: Fetch ESA CCI Biomass AGB and SD maps
  - `getPotapovHeight()`: Fetch Global Forest Canopy Height data
  - `getDinersteinBiome()`: Fetch and rasterize RESOLVE Ecoregions biomes
  - `getSextonTreeCover()`: Fetch Global Tree Canopy Cover data
  - `getSRTMTerrain()`: Fetch SRTM DEM and compute slope/aspect
  - `getIFL()`: Fetch Intact Forest Landscapes data
  - `getBiasCovariates()`: Wrapper to fetch and stack all covariates
* Three-layer architecture: download, process, and user-facing wrapper functions
* Full roxygen2 documentation for all exported functions
* Unit tests with testthat framework
* MIT license for broad compatibility

## Data Source Changes

* **Tree Cover**: `getSextonTreeCover()` now uses Hansen et al. (2013) Global Forest
  Change data instead of Sexton et al. data due to UMD GLCF FTP server discontinuation.
  - Data source: Google Cloud Storage (Hansen GFC v1.11)
  - Year: 2000 baseline (year parameter deprecated)
  - The Hansen dataset provides comparable tree cover estimates and is actively maintained
  - Function name retained for backward compatibility
  - See Hansen et al. (2013) "High-Resolution Global Maps of 21st-Century Forest
    Cover Change" - Science 342(6160): 850-853
