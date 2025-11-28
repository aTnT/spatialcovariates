# Fetch and Stack All Bias Covariates for Plot2Map

Orchestrates the fetching and processing of all environmental covariates
commonly used in Plot2Map workflows for bias modeling and uncertainty
quantification. Downloads and processes ESA CCI Biomass, Tree Canopy
Cover, Biomes, Terrain (slope/aspect), and Intact Forest Landscapes.

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
  include_agb = FALSE,
  include_tcc = TRUE,
  include_height = FALSE,
  include_biome = TRUE,
  include_treecover = TRUE,
  include_terrain = TRUE,
  include_ghm = FALSE,
  include_ifl = TRUE,
  gee_scale = 30
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

  Logical, include ESA CCI AGB data. Default: FALSE. Note: For Plot2Map
  workflows, use
  [`getESACCIAGB`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md)
  separately to get both AGB and SD together, avoiding duplicate
  downloads.

- include_tcc:

  Logical, include GLAD TCC 2010 tree cover data. Default: TRUE

- include_height:

  Logical, include ETH Canopy Height 2020 (requires rgee). Default:
  FALSE

- include_biome:

  Logical, include Dinerstein biomes. Default: TRUE

- include_treecover:

  Logical, include Hansen GFC tree cover. Default: TRUE

- include_terrain:

  Logical, include SRTM terrain metrics (elevation, slope, aspect, TRI,
  TPI, roughness). Default: TRUE

- include_ghm:

  Logical, include Global Human Modification Index (requires rgee).
  Default: FALSE

- include_ifl:

  Logical, include Intact Forest Landscapes. Default: TRUE

- gee_scale:

  Numeric, scale for GEE exports (used for include_height and
  include_ghm). Default: 30

## Value

SpatRaster stack with named layers (exact layers depend on include\_\*
parameters):

- agb:

  Aboveground Biomass (Mg/ha) from ESA CCI (if include_agb=TRUE)

- tcc2010:

  Tree Canopy Cover (percent) from GLAD TCC 2010

- canopy_height:

  Canopy Height (m) from ETH 2020 (if include_height=TRUE)

- biome:

  Biome classification (1-14) from RESOLVE Ecoregions

- treecover2000:

  Percent Tree Cover (0-100) from Hansen GFC 2000

- elevation:

  Elevation (m) from SRTM (if include_terrain=TRUE)

- slope:

  Slope (degrees) from SRTM (if include_terrain=TRUE)

- aspect:

  Aspect (degrees, 0-360) from SRTM (if include_terrain=TRUE)

- tri:

  Terrain Ruggedness Index from SRTM (if include_terrain=TRUE)

- tpi:

  Topographic Position Index from SRTM (if include_terrain=TRUE)

- roughness:

  Roughness from SRTM (if include_terrain=TRUE)

- ghm:

  Global Human Modification Index (0-1) from Kennedy et al. (2019) (if
  include_ghm=TRUE, requires rgee)

- ifl:

  Intact Forest Landscape binary (0/1)

## Details

**Temporal Coverage**

Not all datasets have data for all years. The function uses the
following logic:

- **ESA CCI AGB**: Available for 2010, 2017-2022. Uses specified year if
  available, otherwise defaults to 2010.

- **GLAD TCC 2010**: Static dataset representing year 2010 tree canopy
  cover.

- **ETH Canopy Height 2020**: Static dataset representing year 2020
  canopy height (10m resolution). Requires rgee package and Google Earth
  Engine account.

- **Dinerstein Biomes**: Static dataset (2017), no temporal variation.

- **Hansen GFC Tree Cover**: Uses year 2000 baseline regardless of year
  parameter.

- **SRTM Terrain**: Static DEM, no temporal variation. Provides
  elevation and derived metrics (slope, aspect, TRI, TPI, roughness).

- **Global Human Modification**: Static dataset (2016), no temporal
  variation. Requires rgee.

- **IFL**: Available for 2000, 2013, 2016, 2020. Uses closest available
  year.

**Data Sources**

Data is downloaded from public sources. Most do not require API keys:

- ESA CCI: CEDA Archive

- GLAD TCC 2010: GLAD/UMD

- ETH Canopy Height 2020: Google Earth Engine (requires rgee + GEE
  account)

- Dinerstein: RESOLVE Ecoregions

- Hansen GFC: Google Cloud Storage

- SRTM: USGS MEASURES (requires NASA Earthdata authentication)

- gHM: Google Earth Engine (requires rgee + GEE account)

- IFL: Intact Forests

## References

See individual function documentation for detailed references:
[`getESACCIAGB`](https://atnt.github.io/spatialcovariates/reference/getESACCIAGB.md),
[`getGLADTCC2010`](https://atnt.github.io/spatialcovariates/reference/getGLADTCC2010.md),
[`getETHCanopyHeight`](https://atnt.github.io/spatialcovariates/reference/getETHCanopyHeight.md),
[`getDinersteinBiome`](https://atnt.github.io/spatialcovariates/reference/getDinersteinBiome.md),
[`getHansenGFC`](https://atnt.github.io/spatialcovariates/reference/getHansenGFC.md),
[`getSRTMTerrain`](https://atnt.github.io/spatialcovariates/reference/getSRTMTerrain.md),
[`getGlobalHumanMod`](https://atnt.github.io/spatialcovariates/reference/getGlobalHumanMod.md),
[`getIFL`](https://atnt.github.io/spatialcovariates/reference/getIFL.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)

# Define extent for Mexico
mexico_bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)

# Recommended: Fetch AGB and SD separately (for Plot2Map workflows)
biomass_data <- getESACCIAGB(
  extent = mexico_bbox,
  esacci_biomass_year = 2010,
  esacci_biomass_version = "latest",
  resolution = "10km"
)
agb_map <- biomass_data$agb
sd_map <- biomass_data$sd

# Fetch environmental covariates (no AGB duplication)
covariates <- getBiasCovariates(
  extent = mexico_bbox,
  year = 2010,
  resolution = "10km",
  n_cores = 4
  # include_agb = FALSE by default
)

# Plot stack
plot(covariates)

# Use in Plot2Map workflow
library(Plot2Map)
bias_data <- extractBiasCovariates(
  plot_data = my_plots,
  map_agb = agb_map,
  map_sd = sd_map,
  covariates = list(
    height = covariates[["height"]],
    biome = covariates[["biome"]],
    treecover = covariates[["treecover2000"]],
    slope = covariates[["slope"]],
    aspect = covariates[["aspect"]],
    ifl = covariates[["ifl"]]
  )
)
} # }
```
