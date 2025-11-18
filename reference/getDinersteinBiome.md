# Fetch RESOLVE Ecoregions Biomes (Dinerstein et al., 2017)

Downloads and processes the RESOLVE Ecoregions 2017 dataset, rasterizing
biome classifications to the target resolution.

## Usage

``` r
getDinersteinBiome(
  extent,
  resolution = "10km",
  outdir = NULL,
  download = TRUE,
  data_dir = "data/ECOREGIONS"
)
```

## Arguments

- extent:

  sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
  specifying the region of interest

- resolution:

  Character, target resolution (e.g., "10km", "1000m"). Default: "10km"

- outdir:

  Character, optional directory to save processed raster. Default: NULL

- download:

  Logical, whether to download shapefile (TRUE) or use existing.
  Default: TRUE

- data_dir:

  Character, directory containing/to contain ecoregions shapefile.
  Default: "data/ECOREGIONS"

## Value

SpatRaster object with biome classes as integers (1-14). Biome codes:

- 1:

  Tropical & Subtropical Moist Broadleaf Forests

- 2:

  Tropical & Subtropical Dry Broadleaf Forests

- 3:

  Tropical & Subtropical Coniferous Forests

- 4:

  Temperate Broadleaf & Mixed Forests

- 5:

  Temperate Conifer Forests

- 6:

  Boreal Forests/Taiga

- 7:

  Tropical & Subtropical Grasslands, Savannas & Shrublands

- 8:

  Temperate Grasslands, Savannas & Shrublands

- 9:

  Flooded Grasslands & Savannas

- 10:

  Montane Grasslands & Shrublands

- 11:

  Tundra

- 12:

  Mediterranean Forests, Woodlands & Scrub

- 13:

  Deserts & Xeric Shrublands

- 14:

  Mangroves

## References

Dinerstein, E., Olson, D., Joshi, A., Vynne, C., Burgess, N. D.,
Wikramanayake, E., ... & Saleem, M. (2017). An ecoregion-based approach
to protecting half the terrestrial realm. BioScience, 67(6), 534-545.
[doi:10.1093/biosci/bix014](https://doi.org/10.1093/biosci/bix014)

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
# Define extent for Amazon region
bbox <- c(xmin = -75, ymin = -10, xmax = -50, ymax = 5)

# Fetch biome classification
biomes <- getDinersteinBiome(bbox, resolution = "10km")
plot(biomes, main = "RESOLVE Ecoregions Biomes")
} # }
```
