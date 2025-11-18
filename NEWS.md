# spatialcovariates 0.1.0

## Initial Release

* Initial CRAN release of spatialcovariates package
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
