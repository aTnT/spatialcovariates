# Process GLAD TCC 2010 tiles (crop, mosaic, aggregate)

Process GLAD TCC 2010 tiles (crop, mosaic, aggregate)

## Usage

``` r
process_glad_tcc_2010(files, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- files:

  Character vector of file paths to GLAD TCC 2010 tiles

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed raster

## Value

SpatRaster object with tree canopy cover percentage (0-100)
