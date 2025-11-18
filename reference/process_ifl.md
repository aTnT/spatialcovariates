# Process IFL shapefile (rasterize, crop, aggregate)

Process IFL shapefile (rasterize, crop, aggregate)

## Usage

``` r
process_ifl(shp_file, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- shp_file:

  Character, path to IFL shapefile

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed raster

## Value

SpatRaster object with binary IFL classification (1 = intact, 0 = not
intact)
