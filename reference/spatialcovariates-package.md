# spatialcovariates: Automated Covariate Fetching for Plot2Map Bias Modeling

Provides automated functions to fetch, process, and stack environmental
covariates commonly used in Plot2Map workflows for bias modeling and
uncertainty quantification. The package focuses on reproducibility by
downloading data from reliable sources, clipping rasters to
user-specified extents, and resampling to target resolutions (e.g., 10
km to match ESA CCI AGB maps). Supports multiple data sources including
ESA CCI Biomass, Global Forest Canopy Height, RESOLVE Ecoregions, Tree
Cover datasets, SRTM terrain, and Intact Forest Landscapes.

The spatialcovariates package provides automated functions to fetch,
process, and stack environmental covariates commonly used in Plot2Map
workflows for bias modeling and uncertainty quantification.

## Main Functions

The package exports the following main user-facing functions:

- [`getBiasCovariates`](https://atnt.github.io/spatialcovariates/reference/getBiasCovariates.md):

  Fetch and stack all covariates at once (recommended)

- [`getESACCIAGB`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md):

  Fetch ESA CCI Biomass AGB and SD maps

- [`getGLADTCC2010`](https://atnt.github.io/spatialcovariates/reference/getGLADTCC2010.md):

  Fetch GLAD Tree Canopy Cover 2010

- [`getETHCanopyHeight`](https://atnt.github.io/spatialcovariates/reference/getETHCanopyHeight.md):

  Fetch ETH Global Canopy Height 2020 (requires rgee)

- [`getDinersteinBiome`](https://atnt.github.io/spatialcovariates/reference/getDinersteinBiome.md):

  Fetch RESOLVE Ecoregions biomes

- [`getHansenGFC`](https://atnt.github.io/spatialcovariates/reference/getHansenGFC.md):

  Fetch Hansen Global Forest Change Tree Cover 2000

- [`getSRTMTerrain`](https://atnt.github.io/spatialcovariates/reference/getSRTMTerrain.md):

  Fetch SRTM terrain (slope and aspect)

- [`getIFL`](https://atnt.github.io/spatialcovariates/reference/getIFL.md):

  Fetch Intact Forest Landscapes

## Key Features

- Download data from public sources without API keys

- Automatic spatial cropping and resolution resampling

- Parallel downloads for faster processing

- Built-in caching to avoid redundant downloads

- Full integration with Plot2Map workflows

## Getting Started

The simplest way to use the package is with
[`getBiasCovariates()`](https://atnt.github.io/spatialcovariates/reference/getBiasCovariates.md):

    library(spatialcovariates)

    # Define your region of interest
    bbox <- c(xmin = -75, ymin = -10, xmax = -50, ymax = 5)

    # Fetch all covariates
    covariates <- getBiasCovariates(
      extent = bbox,
      year = 2010,
      resolution = "10km",
      n_cores = 4
    )

    # Use in Plot2Map
    library(Plot2Map)
    extractBiasCovariates(plot_data, covariates[["agb"]], covariates[[-1]])

## See also

Useful links:

- <https://atnt.github.io/spatialcovariates/>

- <https://github.com/aTnT/spatialcovariates>

- Report bugs at <https://github.com/aTnT/spatialcovariates/issues>

## Author

**Maintainer**: Plot2Map Developers <plot2map@example.com>
