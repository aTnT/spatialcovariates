# Generate ESA CCI AGB tile names for a region

Generate ESA CCI AGB tile names for a region

## Usage

``` r
esacci_tile_names(roi, year, version, type = "agb")
```

## Arguments

- roi:

  sf object, SpatVector, or numeric bbox

- year:

  Numeric, year

- version:

  Character, version string

- type:

  Character, either "agb" or "sd" for standard deviation

## Value

Character vector of tile filenames
