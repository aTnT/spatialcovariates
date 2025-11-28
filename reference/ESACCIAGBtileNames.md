# Generate ESA-CCI AGB tile names (Plot2Map compatible)

This function generates file names for ESA-CCI AGB tiles based on a
given polygon.

## Usage

``` r
ESACCIAGBtileNames(
  pol,
  esacci_biomass_year = "latest",
  esacci_biomass_version = "latest"
)
```

## Arguments

- pol:

  An sf or SpatVector object representing the polygon of interest.

- esacci_biomass_year:

  Numeric or "latest", year to download (2007, 2010, 2015-2022)

- esacci_biomass_version:

  Character or "latest", version to download (v2.0-v6.0)

## Value

A character vector of unique file names for ESA-CCI AGB tiles.
