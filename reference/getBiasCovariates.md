# Fetch and Stack All Bias Covariates for Plot2Map

Orchestrates the fetching and processing of all environmental covariates
commonly used in Plot2Map workflows for bias modeling and uncertainty
quantification. Downloads and processes ESA CCI Biomass, Forest Height,
Biomes, Tree Cover, Terrain (slope/aspect), and Intact Forest
Landscapes.

## Usage

``` r
getBiasCovariates(
  extent,
  year = 2010,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  data_dir = "data",
  n_cores = 1,
  include_agb = TRUE,
  include_height = TRUE,
  include_biome = TRUE,
  include_treecover = TRUE,
  include_terrain = TRUE,
  include_ifl = TRUE
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, base year for temporal datasets (default: 2010). Note: Not
  all datasets have data for all years. See Details.

- resolution:

  Character, target resolution for all layers (e.g., "10km", "1000m").
  Default: "10km"

- outdir:

  Character, optional directory to save processed rasters. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- data_dir:

  Character, base directory for all data storage. Default: "data"

- n_cores:

  Integer, number of cores for parallel downloads. Default: 1

- include_agb:

  Logical, include ESA CCI AGB data. Default: TRUE

- include_height:

  Logical, include Potapov height data. Default: TRUE

- include_biome:

  Logical, include Dinerstein biomes. Default: TRUE

- include_treecover:

  Logical, include Sexton tree cover. Default: TRUE

- include_terrain:

  Logical, include SRTM terrain (slope/aspect). Default: TRUE

- include_ifl:

  Logical, include Intact Forest Landscapes. Default: TRUE

## Value

SpatRaster stack with named layers:

- agb:

  Aboveground Biomass (Mg/ha) from ESA CCI

- height:

  Forest Canopy Height (m) from Potapov et al.

- biome:

  Biome classification (1-14) from RESOLVE Ecoregions

- treecover:

  Percent Tree Cover (0-100) from Sexton et al.

- slope:

  Slope (degrees) from SRTM

- aspect:

  Aspect (degrees, 0-360) from SRTM

- ifl:

  Intact Forest Landscape binary (0/1)

## Details

\## Temporal Coverage

Not all datasets have data for all years. The function uses the
following logic:

\- \*\*ESA CCI AGB\*\*: Available for 2010, 2017-2022. Uses specified
year if available, otherwise defaults to 2010. - \*\*Potapov Height\*\*:
Represents ~2019 conditions regardless of year parameter. -
\*\*Dinerstein Biomes\*\*: Static dataset (2017), no temporal
variation. - \*\*Sexton Tree Cover\*\*: Available for 2010 and 2015.
Uses 2010 if year \<= 2010, otherwise 2015. - \*\*SRTM Terrain\*\*:
Static DEM, no temporal variation. - \*\*IFL\*\*: Available for 2000,
2013, 2016, 2020. Uses closest available year.

\## Data Sources

All data is downloaded from public sources without requiring API keys: -
ESA CCI: CEDA Archive - Potapov Height: GLAD/UMD - Dinerstein: RESOLVE
Ecoregions - Sexton: UMD GLCF - SRTM: CGIAR-CSI - IFL: Intact Forests

## References

See individual function documentation for detailed references:
[`getESACCIAGB`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md),
[`getPotapovHeight`](https://atnt.github.io/spatialcovariates/reference/getPotapovHeight.md),
[`getDinersteinBiome`](https://atnt.github.io/spatialcovariates/reference/getDinersteinBiome.md),
[`getSextonTreeCover`](https://atnt.github.io/spatialcovariates/reference/getSextonTreeCover.md),
[`getSRTMTerrain`](https://atnt.github.io/spatialcovariates/reference/getSRTMTerrain.md),
[`getIFL`](https://atnt.github.io/spatialcovariates/reference/getIFL.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)

# Define extent for Mexico
mexico_bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)

# Fetch all covariates at 10km resolution
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  year = 2010,
  resolution = "10km",
  n_cores = 4
)

# Plot stack
plot(covariates)

# Access individual layers
agb <- covariates[["agb"]]
slope <- covariates[["slope"]]

# Use in Plot2Map workflow
library(Plot2Map)
bias_model <- extractBiasCovariates(
  plot_data = my_plots,
  map_agb_raster = covariates[["agb"]],
  covariate_rasters = covariates[[c("height", "biome", "treecover",
                                    "slope", "aspect", "ifl")]]
)
} # }
```
