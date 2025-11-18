# Fetch Intact Forest Landscapes (IFL)

Downloads and processes Intact Forest Landscapes data, providing binary
classification of intact vs non-intact forest areas.

## Usage

``` r
getIFL(
  extent,
  year = 2016,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  data_dir = "data/IFL"
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- year:

  Numeric, IFL year to fetch (2000, 2013, 2016, or 2020). Default: 2016

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download shapefile (TRUE) or use existing.
  Default: TRUE

- data_dir:

  Character, directory containing/to contain IFL shapefile. Default:
  "data/IFL"

## Value

SpatRaster object with binary values:

- 1:

  Intact Forest Landscape

- 0:

  Non-intact or no forest

## References

Potapov, P., Hansen, M. C., Laestadius, L., Turubanova, S., Yaroshenko,
A., Thies, C., ... & Esipova, E. (2017). The last frontiers of
wilderness: Tracking loss of intact forest landscapes from 2000 to 2013.
Science Advances, 3(1), e1600821.
[doi:10.1126/sciadv.1600821](https://doi.org/10.1126/sciadv.1600821)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for Amazon region
bbox <- c(xmin = -75, ymin = -10, xmax = -50, ymax = 5)

# Fetch IFL 2016 data
ifl <- getIFL(bbox, year = 2016, resolution = "10km")
plot(ifl, main = "Intact Forest Landscapes 2016")
} # }
```
