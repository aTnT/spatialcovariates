# Process SRTM DEM tiles and compute terrain derivatives

Process SRTM DEM tiles and compute terrain derivatives

## Usage

``` r
process_srtm_terrain(files, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- files:

  Character vector of file paths to SRTM DEM tiles

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed rasters

## Value

Named list with SpatRaster objects: slope (degrees) and aspect (degrees)
