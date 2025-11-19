# Fetch Hansen Global Forest Change Tree Cover 2000

Downloads and processes Hansen Global Forest Change tree cover data at
30m resolution (year 2000 baseline) and aggregates to target resolution.

## Usage

``` r
getHansenGFC(
  extent,
  year = 2000,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  tiles_dir = "data/HANSEN_TC",
  n_cores = 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, year parameter (deprecated - Hansen GFC uses year 2000
  baseline). Included for backward compatibility. Default: 2000

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- tiles_dir:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/HANSEN_TC"

- n_cores:

  Integer, number of cores for parallel download. Default: 1

## Value

SpatRaster object with percent tree cover (0-100) for year 2000

## References

Hansen, M. C., Potapov, P. V., Moore, R., Hancher, M., Turubanova, S.
A., Tyukavina, A., ... & Townshend, J. R. G. (2013). High-resolution
global maps of 21st-century forest cover change. Science, 342(6160),
850-853.
[doi:10.1126/science.1244693](https://doi.org/10.1126/science.1244693)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch Hansen GFC tree cover data
treecover <- getHansenGFC(bbox, resolution = "10km")
plot(treecover, main = "Tree Cover 2000 (%)")
} # }
```
