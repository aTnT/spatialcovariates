# Fetch ETH Global Canopy Height 2020 via Google Earth Engine

Downloads and processes ETH Global Canopy Height 2020 data at 10m
resolution via Google Earth Engine and aggregates to target resolution.
Requires rgee package and authenticated Google Earth Engine account.

## Usage

``` r
getETHCanopyHeight(extent, resolution = "10km", outdir = NULL, scale = 10)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- scale:

  Numeric, scale in meters for GEE export (default: 10 for native
  resolution). For large areas, use larger scale (e.g., 30, 100) to
  reduce processing time.

## Value

SpatRaster object with canopy height in meters for year 2020

## Note

\*\*Requirements\*\*: - Install rgee package:
\`install.packages("rgee")\` - Set up Google Earth Engine account:
https://earthengine.google.com/signup/ - Initialize rgee:
\`rgee::ee_Initialize()\`

\*\*GEE Asset\*\*: \`users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1\`

\*\*Performance Notes\*\*: - For large regions (\>1000 km²), use \`scale
= 30\` or higher to reduce processing time - Native 10m resolution may
cause memory issues for very large extents - Consider processing large
regions in smaller chunks

## References

Lang, N., Kalischek, N., Armston, J., Schindler, K., Dubayah, R., &
Wegner, J. D. (2023). Global canopy height regression and uncertainty
estimation from GEDI LIDAR waveforms with deep ensembles. \*Remote
Sensing of Environment\*, 268, 112760.
[doi:10.1016/j.rse.2021.112760](https://doi.org/10.1016/j.rse.2021.112760)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
library(rgee)

# Initialize Earth Engine (first time setup)
ee_Initialize()

# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch ETH Canopy Height 2020
height <- getETHCanopyHeight(bbox, resolution = "10km")
plot(height, main = "Canopy Height 2020 (m)")
} # }
```
