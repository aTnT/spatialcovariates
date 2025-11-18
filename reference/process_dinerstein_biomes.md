# Process Dinerstein biomes (rasterize, crop, aggregate)

Process Dinerstein biomes (rasterize, crop, aggregate)

## Usage

``` r
process_dinerstein_biomes(shp_file, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- shp_file:

  Character, path to ecoregions shapefile

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed raster

## Value

SpatRaster object with biome classes as integers
