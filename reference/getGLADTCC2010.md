# Fetch GLAD Tree Cover 2010 data

Downloads and processes GLAD Tree Cover 2010 data at 30m resolution and
aggregates to target resolution.

## Usage

``` r
getGLADTCC2010(
  extent,
  year = 2010,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  tiles_dir = "data/GLAD_TCC_2010",
  n_cores = 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, year parameter (deprecated - data is for 2010). Default: 2010

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- tiles_dir:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/GLAD_TCC_2010"

- n_cores:

  Integer, number of cores for parallel download. Default: 1

## Value

SpatRaster object with tree canopy cover percentage (0-100) for year
2010

## Note

For actual canopy height data, consider using Google Earth Engine with
the ETH Global Canopy Height 2020 product:
`users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1`

## References

Potapov, P., et al. (2011). Quantifying forest cover loss in Democratic
Republic of the Congo, 2000-2010, with Landsat ETM+ data. Remote Sensing
of Environment, 122, 106-116.

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch GLAD TCC 2010 data
tcc <- getGLADTCC2010(bbox, resolution = "10km")
plot(tcc, main = "Tree Canopy Cover 2010 (%)")
} # }
```
