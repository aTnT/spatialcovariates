# Changelog

## spatialcovariates 0.1.0

### Initial Release

- Initial CRAN release of spatialcovariates package
- Core covariate fetching functions:
  - [`getESACCIAGB()`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md):
    Fetch ESA CCI Biomass AGB and SD maps
  - [`getPotapovHeight()`](https://atnt.github.io/spatialcovariates/reference/getPotapovHeight.md):
    Fetch Global Forest Canopy Height data
  - [`getDinersteinBiome()`](https://atnt.github.io/spatialcovariates/reference/getDinersteinBiome.md):
    Fetch and rasterize RESOLVE Ecoregions biomes
  - [`getSextonTreeCover()`](https://atnt.github.io/spatialcovariates/reference/getSextonTreeCover.md):
    Fetch Global Tree Canopy Cover data
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
