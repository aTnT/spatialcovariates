# Process ESA CCI Biomass tiles (crop, mosaic, aggregate)

Process ESA CCI Biomass tiles (crop, mosaic, aggregate)

## Usage

``` r
process_esacci_biomass(files, extent, resolution = "10km", outdir = NULL)
```

## Arguments

- files:

  Character vector of file paths to ESA CCI tiles

- extent:

  sf object, SpatVector, or numeric bbox

- resolution:

  Character or numeric, target resolution (e.g., "10km")

- outdir:

  Character, optional output directory to save processed rasters

## Value

Named list with SpatRaster objects: agb and sd
