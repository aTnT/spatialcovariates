# Fetch ESA CCI Biomass AGB and SD maps

Downloads and processes ESA CCI Biomass Aboveground Biomass (AGB) and
Standard Deviation (SD) maps for a specified region, year, and version.

## Usage

``` r
getESACCIAGB(
  extent,
  esacci_biomass_year = 2010,
  esacci_biomass_version = "latest",
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  esacci_folder = "data/ESACCI-BIOMASS",
  n_cores = parallel::detectCores() - 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- esacci_biomass_year:

  Numeric or "latest", year to fetch (2007, 2010, 2015-2022). Default:
  2010

- esacci_biomass_version:

  Character or "latest", ESA CCI version (v2.0-v6.0). Default: "latest"

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed rasters. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- esacci_folder:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/ESACCI-BIOMASS"

- n_cores:

  Integer, number of cores for parallel download. Default:
  parallel::detectCores() - 1

## Value

Named list with two SpatRaster objects: `agb` (Aboveground Biomass in
Mg/ha) and `sd` (Standard Deviation in Mg/ha). If SD data is not
available, sd will be NULL.

## References

Santoro, M., & Cartus, O. (2025). ESA Biomass Climate Change Initiative
(Biomass_cci): Global datasets of forest above-ground biomass for the
years 2007, 2010, 2015-2022, v6.0. NERC EDS Centre for Environmental
Data Analysis.
[doi:10.5285/95913ffb6467447ca72c4e9d8cf30501](https://doi.org/10.5285/95913ffb6467447ca72c4e9d8cf30501)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for Mexico
mexico_bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)

# Fetch ESA CCI Biomass for 2010
biomass <- getESACCIAGB(mexico_bbox, esacci_biomass_year = 2010, resolution = "10km")

# Access AGB and SD
plot(biomass$agb, main = "AGB 2010")
plot(biomass$sd, main = "SD 2010")
} # }
```
