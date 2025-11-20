# Generate SRTM tile names for a region

USGS MEASURES SRTM uses 1x1 degree tiles

## Usage

``` r
srtm_tile_names(roi)
```

## Arguments

- roi:

  sf object, SpatVector, or numeric bbox

## Value

Character vector of tile names in format "N00E000" or "S00W000"
