# spatialcovariates 0.1.1 (Development)

## Breaking Changes

* **ESA CCI Biomass functions now Plot2Map compatible** - Parameter names updated for consistency
  - **Affected functions**: `getESACCIAGB()`, `download_esacci_biomass()`, `validate_esacci_biomass_args()`, new `ESACCIAGBtileNames()`
  - **Parameter changes**:
    - `year` → `esacci_biomass_year`
    - `version` → `esacci_biomass_version`
    - `tiles_dir`/`output_folder` → `esacci_folder`
  - **Default version changed**: `"v3.0"` → `"latest"` (now uses v6.0)
  - **Reason**: Full compatibility with Plot2Map package for future integration
  - **Migration**: Update parameter names in existing code:
    ```r
    # Old (v0.1.0)
    biomass <- getESACCIAGB(extent, year = 2010, version = "v3.0")

    # New (v0.1.1+)
    biomass <- getESACCIAGB(extent, esacci_biomass_year = 2010, esacci_biomass_version = "latest")
    ```

## New Features

* **ESA CCI Biomass v6.0 support** - Added latest ESA CCI Biomass dataset
  - **New years**: 2007 (new!), 2010, 2015-2022 (2022 is new!)
  - **Previous versions**: 2010, 2017-2022
  - **Improvements in v6.0**:
    - Extended temporal coverage (2007, 2022)
    - Improved calibration with extended ICESat-2 observations
    - Refined cost function to reduce biases between time periods
  - **Reference**: Santoro, M., & Cartus, O. (2025). ESA Biomass Climate Change Initiative (Biomass_cci): Global datasets of forest above-ground biomass for the years 2007, 2010, 2015-2022, v6.0. https://doi.org/10.5285/95913ffb6467447ca72c4e9d8cf30501

* **SRTM terrain metrics expanded** - Now returns 6 metrics instead of 2
  - **New metrics**: elevation (DEM), TRI (Terrain Ruggedness Index), TPI (Topographic Position Index), roughness
  - **Previous metrics**: slope, aspect (still included)
  - **Processing**: All derivatives computed at native resolution before aggregation for accuracy
  - **Aggregation**: Circular mean for aspect, standard mean for others

* **Global Human Modification Index (gHM)** - New covariate via Google Earth Engine
  - **Function**: `getGlobalHumanMod()` (optional, requires rgee)
  - **Source**: Kennedy et al. (2019) via GEE asset `CSP/HM/GlobalHumanModification`
  - **Resolution**: 1km native, aggregated to target resolution
  - **Range**: 0-1 (0 = no modification, 1 = maximum modification)
  - **Default**: `include_ghm = FALSE` in `getBiasCovariates()`

## Performance Improvements

* **Optimisation for tile-based raster processing** - Reduced processing time for typical regions
  - **Affected functions**: `getGLADTCC2010()`, `getHansenGFC()`, `getESACCIAGB()`, `getSRTMTerrain()`
  - **Optimisation**: Crop and aggregate tiles individually before mosaicking (instead of mosaic-then-crop-then-aggregate)
  - **Impact**:
    - Reduces data volume by 95-99% before mosaicking
    - Single-pass aggregation (removed inefficient step-wise aggregation)
    - Lower memory usage
  - **Technical details**: Processing pattern changed from:
    - Old: Load full tiles → Mosaic → Crop → Multi-step aggregate
    - New: Load tile → Crop immediately → Single-pass aggregate → Mosaic small tiles
  - **SRTM case**:
    - SRTM terrain derivatives still computed at native resolution before aggregation for accuracy

## Data Source Changes

* **SRTM data source updated** - Switched from CGIAR-CSI to USGS MEASURES server
  - **Previous source**: CGIAR-CSI SRTM v4.1 (5°×5° tiles) - server discontinued
  - **New source**: USGS MEASURES SRTMGL3 v003 (1°×1° tiles) - actively maintained
  - **URL**: https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/
  - **File format**: Changed from `.tif` to `.hgt` (both supported by terra)
  - **Benefits**: Finer tile granularity (1°×1° instead of 5°×5°), less unnecessary data
  - **Authentication**: USGS server requires NASA Earthdata authentication (free account)
  - **Setup**: Install `earthdatalogin` package for seamless authentication:
    ```r
    install.packages("earthdatalogin")
    earthdatalogin::edl_netrc(username = "your_username", password = "your_password")
    ```
  - **Alternatives**: elevation package, Google Earth Engine, or manual download
  - **Impact**: Tile naming changed, but no user-facing API changes - `getSRTMTerrain()` works the same

## Bug Fixes

* **Fixed SRTM tile selection** - Corrected tile boundary handling in `srtm_tile_names()`
  - Previously selected tiles at exact bbox boundaries even when not needed
  - Example: bbox `c(-96, 18.5, -95, 19.5)` previously selected 4 tiles, now correctly selects 2 tiles
  - SRTM tiles are `[start, start+1)` (inclusive lower, exclusive upper)
  - Significantly reduces unnecessary tile downloads and processing time

* **Enhanced bbox validation** - Added comprehensive validation to `validate_extent()`
  - Detects incorrect coordinate order (e.g., `c(xmin, xmax, ymin, ymax)` instead of `c(xmin, ymin, xmax, ymax)`)
  - Validates coordinates are within valid ranges (longitude: -180 to 180, latitude: -90 to 90)
  - Provides clear error messages indicating the likely issue
  - **Note**: Bboxes should be specified as `c(xmin, ymin, xmax, ymax)`. Named parameters are recommended: `c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)`

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
