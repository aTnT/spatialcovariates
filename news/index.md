# Changelog

## spatialcovariates 0.1.0

### Initial Release

- Initial CRAN release of spatialcovariates package
- Core covariate fetching functions:
  - [`getESACCIAGB()`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md):
    Fetch ESA CCI Biomass AGB and SD maps
  - `getPotapovHeight()`: Fetch Global Forest Canopy Height data
  - [`getDinersteinBiome()`](https://atnt.github.io/spatialcovariates/reference/getDinersteinBiome.md):
    Fetch and rasterize RESOLVE Ecoregions biomes
  - `getSextonTreeCover()`: Fetch Global Tree Canopy Cover data
  - [`getSRTMTerrain()`](https://atnt.github.io/spatialcovariates/reference/getSRTMTerrain.md):
    Fetch SRTM DEM and compute slope/aspect
  - [`getIFL()`](https://atnt.github.io/spatialcovariates/reference/getIFL.md):
    Fetch Intact Forest Landscapes data
  - [`getBiasCovariates()`](https://atnt.github.io/spatialcovariates/reference/getBiasCovariates.md):
    Wrapper to fetch and stack all covariates
- Three-layer architecture: download, process, and user-facing wrapper
  functions
- Full roxygen2 documentation for all exported functions
- Unit tests with testthat framework
- MIT license for broad compatibility

### Data Source Changes

- **Tree Cover**: `getSextonTreeCover()` now uses Hansen et al. (2013)
  Global Forest Change data instead of Sexton et al. data due to UMD
  GLCF FTP server discontinuation.
  - Data source: Google Cloud Storage (Hansen GFC v1.11)
  - Year: 2000 baseline (year parameter deprecated)
  - The Hansen dataset provides comparable tree cover estimates and is
    actively maintained
  - Function name retained for backward compatibility
  - See Hansen et al. (2013) “High-Resolution Global Maps of
    21st-Century Forest Cover Change” - Science 342(6160): 850-853
