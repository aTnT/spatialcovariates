# spatialcovariates

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R-CMD-check](https://github.com/aTnT/spatialcovariates/workflows/R-CMD-check/badge.svg)](https://github.com/aTnT/spatialcovariates/actions)
<!-- badges: end -->

**Automated Covariate Fetching for Plot2Map Bias Modeling**

`spatialcovariates` provides automated functions to fetch, process, and stack environmental covariates commonly used in [Plot2Map](https://github.com/aTnT/Plot2Map) workflows for bias modeling and uncertainty quantification in forest biomass mapping.

## Features

- **Multi-source data integration**: Download from ESA CCI, GLAD, RESOLVE, UMD GLCF, CGIAR-CSI, and Intact Forests
- **One-line workflows**: Single function to fetch and stack all covariates
- **Reproducible pipelines**: Standardized spatial processing (crop, resample, aggregate)
- **Parallel downloads**: Speed up data acquisition with multi-core support
- **Smart caching**: Avoid redundant downloads with local file management
- **No API keys required**: All data from public sources
- **CRAN-ready**: Fully documented with comprehensive testing

## Installation

Install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("aTnT/spatialcovariates")
```

## Quick Start

### Fetch All Covariates at Once

The simplest workflow uses `getBiasCovariates()` to download and stack all environmental covariates:

```r
library(spatialcovariates)

# Define region of interest (example within Mexico)
mexico_bbox <- c(xmin = -101, ymin = 20.5, xmax = -100.5, ymax = 21)

# Fetch all covariates at 10km resolution
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  year = 2010,
  resolution = "10km",
  n_cores = 4  # Use 4 cores for parallel downloads
)

# View the stack
plot(covariates)
names(covariates)
# [1] "agb"       "height"    "biome"     "treecover"
# [5] "slope"     "aspect"    "ifl"
```

### Integration with Plot2Map

Use the fetched covariates directly in Plot2Map workflows:

```r
library(Plot2Map)

# Extract bias covariates for your plot data
bias_model <- extractBiasCovariates(
  plot_data = my_field_plots,
  map_agb_raster = covariates[["agb"]],
  covariate_rasters = covariates[[c("height", "biome", "treecover",
                                    "slope", "aspect", "ifl")]]
)
```

## Available Covariates

| Covariate | Function | Source | Resolution | Years |
|-----------|----------|--------|------------|-------|
| **AGB & SD** | `getESACCIAGB()` | ESA CCI Biomass | 100m | 2010, 2017-2022 |
| **Forest Height** | `getPotapovHeight()` | GLAD/Potapov et al. | 30m | ~2019 |
| **Biomes** | `getDinersteinBiome()` | RESOLVE Ecoregions | Vector | 2017 (static) |
| **Tree Cover** | `getSextonTreeCover()` | UMD GLCF | 30m | 2010, 2015 |
| **Slope & Aspect** | `getSRTMTerrain()` | SRTM v4.1 | 90m | Static |
| **Intact Forests** | `getIFL()` | Intact Forest Landscapes | Vector | 2000, 2013, 2016, 2020 |

## Individual Covariate Examples

### ESA CCI Biomass (AGB and Standard Deviation)

```r
# Fetch AGB and SD for 2010
biomass <- getESACCIAGB(
  extent = mexico_bbox,
  year = 2010,
  version = "v3.0",
  resolution = "10km"
)

# Access individual layers
agb <- biomass$agb    # Aboveground biomass (Mg/ha)
sd <- biomass$sd      # Standard deviation (Mg/ha)
```

### Forest Canopy Height

```r
# Fetch Potapov height data
height <- getPotapovHeight(
  extent = mexico_bbox,
  resolution = "10km"
)

plot(height, main = "Forest Canopy Height (m)")
```

### Biome Classification

```r
# Fetch RESOLVE Ecoregions biomes
biomes <- getDinersteinBiome(
  extent = mexico_bbox,
  resolution = "10km"
)

# Biome codes: 1-14 (see ?getDinersteinBiome for details)
plot(biomes, main = "RESOLVE Biomes")
```

### Tree Cover Percentage

```r
# Fetch Sexton tree cover for 2015
treecover <- getSextonTreeCover(
  extent = mexico_bbox,
  year = 2015,
  resolution = "10km"
)

plot(treecover, main = "Tree Cover (%)")
```

### Terrain (Slope and Aspect)

```r
# Fetch SRTM terrain derivatives
terrain <- getSRTMTerrain(
  extent = mexico_bbox,
  resolution = "10km"
)

par(mfrow = c(1, 2))
plot(terrain$slope, main = "Slope (degrees)")
plot(terrain$aspect, main = "Aspect (degrees)")
```

### Intact Forest Landscapes

```r
# Fetch IFL 2016
ifl <- getIFL(
  extent = mexico_bbox,
  year = 2016,
  resolution = "10km"
)

plot(ifl, main = "Intact Forest Landscapes (1 = intact)")
```

## Advanced Usage

### Selective Covariate Fetching

Fetch only specific covariates:

```r
# Fetch only AGB, height, and terrain
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  year = 2010,
  resolution = "10km",
  include_biome = FALSE,
  include_treecover = FALSE,
  include_ifl = FALSE
)
```

### Using Existing Downloaded Data

Avoid re-downloading by using local files:

```r
# First download
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  download = TRUE,
  data_dir = "my_data"  # Save tiles here
)

# Later: reprocess without downloading
covariates_new <- getBiasCovariates(
  extent = mexico_bbox,
  download = FALSE,
  data_dir = "my_data"  # Use existing tiles
)
```

### Save Processed Rasters

Save processed covariates to disk:

```r
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  year = 2010,
  resolution = "10km",
  outdir = "output/processed"  # Saves all layers as GeoTIFFs
)
```

### Custom Spatial Extents

Use different extent formats:

```r
library(sf)

# From sf polygon
mexico <- st_read("countries.shp") %>%
  filter(name == "Mexico")
covariates <- getBiasCovariates(extent = mexico)

# From terra SpatVector
mexico_vect <- vect(mexico)
covariates <- getBiasCovariates(extent = mexico_vect)

# From numeric bbox
bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)
covariates <- getBiasCovariates(extent = bbox)
```

## Data Sources and References

### ESA CCI Biomass
Santoro, M., & Cartus, O. (2023). ESA Biomass Climate Change Initiative (Biomass_cci): Global datasets of forest above-ground biomass for the years 2010, 2017, 2018, 2019 and 2020. NERC EDS Centre for Environmental Data Analysis. https://doi.org/10.5285/5f331c418e9f4935b8eb1b836f8a91b8

### Potapov Forest Height
Potapov, P., Li, X., Hernandez-Serna, A., et al. (2021). Mapping global forest canopy height through integration of GEDI and Landsat data. *Remote Sensing of Environment*, 253, 112165. https://doi.org/10.1016/j.rse.2020.112165

### RESOLVE Ecoregions (Dinerstein Biomes)
Dinerstein, E., Olson, D., Joshi, A., et al. (2017). An ecoregion-based approach to protecting half the terrestrial realm. *BioScience*, 67(6), 534-545. https://doi.org/10.1093/biosci/bix014

### Sexton Tree Cover
Sexton, J. O., Song, X. P., Feng, M., et al. (2013). Global, 30-m resolution continuous fields of tree cover: Landsat-based rescaling of MODIS vegetation continuous fields with lidar-based estimates of error. *International Journal of Digital Earth*, 6(5), 427-448. https://doi.org/10.1080/17538947.2013.786146

### SRTM DEM
Jarvis, A., Reuter, H. I., Nelson, A., & Guevara, E. (2008). Hole-filled SRTM for the globe Version 4. CGIAR-CSI SRTM 90m Database. http://srtm.csi.cgiar.org

### Intact Forest Landscapes
Potapov, P., Hansen, M. C., Laestadius, L., et al. (2017). The last frontiers of wilderness: Tracking loss of intact forest landscapes from 2000 to 2013. *Science Advances*, 3(1), e1600821. https://doi.org/10.1126/sciadv.1600821

## Temporal Coverage Notes

Not all datasets cover all years. The package handles temporal mismatches as follows:

| Dataset | Available Years | Logic |
|---------|----------------|-------|
| ESA CCI AGB | 2010, 2017-2022 | Uses specified year if available, otherwise 2010 |
| Potapov Height | ~2019 | Static (represents 2019 conditions) |
| Dinerstein Biomes | 2017 | Static |
| Sexton Tree Cover | 2010, 2015 | Uses 2010 if year ≤ 2010, else 2015 |
| SRTM Terrain | Static | No temporal variation |
| IFL | 2000, 2013, 2016, 2020 | Uses closest available year |

## Dependencies

Required packages (automatically installed):
- `terra` (>= 1.7-78)
- `sf` (>= 1.0-16)
- `httr` (>= 1.4.7)
- `rvest` (>= 1.0.0)
- `pbapply` (>= 1.7-0)
- `parallel`
- `stringr` (>= 1.5.0)
- `utils`

## Troubleshooting

### Download Failures

If downloads fail due to network issues:

```r
# Increase timeout
covariates <- getBiasCovariates(
  extent = bbox,
  # Downloads will retry with exponential backoff
)
```

### Memory Issues with Large Extents

For very large regions at fine resolution:

```r
# Use coarser resolution
covariates <- getBiasCovariates(
  extent = large_bbox,
  resolution = "25km"  # Instead of "10km"
)

# Or fetch covariates separately
agb <- getESACCIAGB(extent = large_bbox, resolution = "25km")
height <- getPotapovHeight(extent = large_bbox, resolution = "25km")
```

### Data Source Changes

If a data source URL changes:
1. Check package updates: `devtools::install_github("aTnT/spatialcovariates")`
2. Report issue: https://github.com/aTnT/spatialcovariates/issues

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure `R CMD check` passes
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Citation

If you use this package in your research, please cite:

```
spatialcovariates: Automated Covariate Fetching for Plot2Map Bias Modeling.
R package version 0.1.0. https://github.com/aTnT/spatialcovariates
```

And cite the original data sources (see Data Sources section above).

## Support

- Documentation: `?spatialcovariates`
- Bug reports: https://github.com/aTnT/spatialcovariates/issues
- Questions: Open a GitHub discussion

## Related Packages

- [Plot2Map](https://github.com/aTnT/Plot2Map): Forest biomass mapping and validation
- [terra](https://github.com/rspatial/terra): Spatial data analysis
- [sf](https://github.com/r-spatial/sf): Simple features for R
