# Generate ESA CCI AGB tile names for a region

Generate ESA CCI AGB tile names for a region

## Usage

``` r
esacci_tile_names(
  roi,
  esacci_biomass_year,
  esacci_biomass_version,
  type = "agb"
)
```

## Arguments

- roi:

  sf object, SpatVector, or numeric bbox

- esacci_biomass_year:

  Numeric, year

- esacci_biomass_version:

  Character, version string

- type:

  Character, either "agb" or "sd" for standard deviation

## Value

Character vector of tile filenames
