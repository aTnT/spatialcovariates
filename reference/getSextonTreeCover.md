# Fetch Global Tree Canopy Cover (Sexton et al., 2015)

Downloads and processes Global Tree Canopy Cover data at 30m resolution
(2015 or 2010) and aggregates to target resolution.

## Usage

``` r
getSextonTreeCover(
  extent,
  year = 2015,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  tiles_dir = "data/SEXTON_TCC",
  n_cores = 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, year to fetch (2010 or 2015). Default: 2015

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- tiles_dir:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/SEXTON_TCC"

- n_cores:

  Integer, number of cores for parallel download. Default: 1

## Value

SpatRaster object with percent tree cover (0-100)

## References

Sexton, J. O., Song, X. P., Feng, M., Noojipady, P., Anand, A., Huang,
C., ... & Townshend, J. R. (2013). Global, 30-m resolution continuous
fields of tree cover: Landsat-based rescaling of MODIS vegetation
continuous fields with lidar-based estimates of error. International
Journal of Digital Earth, 6(5), 427-448.
[doi:10.1080/17538947.2013.786146](https://doi.org/10.1080/17538947.2013.786146)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch tree cover data
treecover <- getSextonTreeCover(bbox, year = 2015, resolution = "10km")
plot(treecover, main = "Tree Cover (%)")
} # }
```
