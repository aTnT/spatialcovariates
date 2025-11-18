# Fetch Global Forest Canopy Height (Potapov et al., 2021)

Downloads and processes Global Forest Canopy Height data at 30m
resolution (circa 2019) and aggregates to target resolution.

## Usage

``` r
getPotapovHeight(
  extent,
  year = 2010,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  tiles_dir = "data/POTAPOV_HEIGHT",
  n_cores = 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, year parameter (currently only 2019 data available). Default:
  2010 Note: Data represents ~2019 conditions regardless of year
  parameter.

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- tiles_dir:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/POTAPOV_HEIGHT"

- n_cores:

  Integer, number of cores for parallel download. Default: 1

## Value

SpatRaster object with forest canopy height in meters

## References

Potapov, P., Li, X., Hernandez-Serna, A., Tyukavina, A., Hansen, M. C.,
Kommareddy, A., ... & Hofton, M. (2021). Mapping global forest canopy
height through integration of GEDI and Landsat data. Remote Sensing of
Environment, 253, 112165.
[doi:10.1016/j.rse.2020.112165](https://doi.org/10.1016/j.rse.2020.112165)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch Potapov height data
height <- getPotapovHeight(bbox, resolution = "10km")
plot(height, main = "Forest Canopy Height (m)")
} # }
```
