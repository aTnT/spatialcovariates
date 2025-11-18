# Process Sexton tree cover tiles (crop, mosaic, aggregate)

Process Sexton tree cover tiles (crop, mosaic, aggregate)

## Usage

``` r
process_sexton_treecover(files, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- files:

  Character vector of file paths to tree cover tiles

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed raster

## Value

SpatRaster object with percent tree cover (0-100)
