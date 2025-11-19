# Fetch SRTM Terrain

Downloads SRTM DEM data and computes terrain derivatives such as slope,
aspect, Terrain Ruggedness Index (TRI), Topographic Position Index (TPI)
and roughness at the target resolution.

## Usage

``` r
getSRTMTerrain(
  extent,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  tiles_dir = "data/SRTM",
  n_cores = 1
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed rasters. Default: NULL

- download:

  Logical, whether to download tiles (TRUE) or use existing. Default:
  TRUE

- tiles_dir:

  Character, directory containing existing tiles (if download=FALSE).
  Default: "data/SRTM"

- n_cores:

  Integer, number of cores for parallel download. Default: 1

## Value

Named list with six SpatRaster objects:

- elevation:

  Elevation in meters above sea level

- slope:

  Slope in degrees (0-90)

- aspect:

  Aspect in degrees (0-360), where 0=North, 90=East, 180=South, 270=West

- tri:

  Terrain Ruggedness Index - mean elevation difference between adjacent
  cells

- tpi:

  Topographic Position Index - difference from mean elevation of
  surrounding cells

- roughness:

  Roughness - difference between max and min elevation in 3x3
  neighborhood

## References

Farr, T. G., Rosen, P. A., Caro, E., Crippen, R., Duren, R., Hensley,
S., ... & Alsdorf, D. (2007). The shuttle radar topography mission.
Reviews of Geophysics, 45(2).
[doi:10.1029/2005RG000183](https://doi.org/10.1029/2005RG000183)

Jarvis, A., Reuter, H. I., Nelson, A., & Guevara, E. (2008). Hole-filled
SRTM for the globe Version 4. Available from the CGIAR-CSI SRTM 90m
Database.

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch terrain data
terrain <- getSRTMTerrain(bbox, resolution = "10km")

# Plot individual metrics
plot(terrain$elevation, main = "Elevation (m)")
plot(terrain$slope, main = "Slope (degrees)")
plot(terrain$aspect, main = "Aspect (degrees)")
plot(terrain$tri, main = "Terrain Ruggedness Index")
plot(terrain$tpi, main = "Topographic Position Index")
plot(terrain$roughness, main = "Roughness")
} # }
```
