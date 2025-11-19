# Fetch Global Human Modification Index via Google Earth Engine

Downloads and processes Global Human Modification (gHM) data at 1km
resolution via Google Earth Engine and aggregates to target resolution.
The gHM quantifies the cumulative impact of direct human pressures on
the environment. Requires rgee package and authenticated Google Earth
Engine account.

## Usage

``` r
getGlobalHumanMod(extent, resolution = "10km", outdir = NULL, scale = 1000)
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

  Numeric, scale in meters for GEE export (default: 1000 for native
  resolution). For very large areas, use larger scale to reduce
  processing time.

## Value

SpatRaster object with human modification index (0-1), where: 0 = No
human modification, 1 = Maximum human modification

## Note

**Requirements**:

- Install rgee package: `install.packages("rgee")`

- Set up Google Earth Engine account:
  https://earthengine.google.com/signup/

- Initialize rgee:
  [`rgee::ee_Initialize()`](https://r-spatial.github.io/rgee/reference/ee_Initialize.html)

**GEE Asset**: `CSP/HM/GlobalHumanModification`

**Performance Notes**:

- Native 1km resolution is usually fast enough for most regions

- For very large regions (\>10,000 km²), consider using `scale = 5000`
  or higher

## References

Kennedy, C. M., Oakleaf, J. R., Theobald, D. M., Baruch-Mordo, S., &
Kiesecker, J. (2019). Managing the middle: A shift in conservation
priorities based on the global human modification gradient. \*Global
Change Biology\*, 25(3), 811-826.
[doi:10.1111/gcb.14549](https://doi.org/10.1111/gcb.14549)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
library(rgee)

# Initialize Earth Engine (first time setup)
ee_Initialize()

# Define extent for a region
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)

# Fetch Global Human Modification Index
ghm <- getGlobalHumanMod(bbox, resolution = "10km")
plot(ghm, main = "Human Modification Index (0-1)")
} # }
```
