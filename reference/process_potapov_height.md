# Process Potapov height tiles (crop, mosaic, aggregate)

Process Potapov height tiles (crop, mosaic, aggregate)

## Usage

``` r
process_potapov_height(files, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- files:

  Character vector of file paths to Potapov height tiles

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed raster

## Value

SpatRaster object with forest height in meters
