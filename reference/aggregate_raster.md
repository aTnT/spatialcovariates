# Aggregate raster with proper handling of circular variables

Aggregate raster with proper handling of circular variables

## Usage

``` r
aggregate_raster(rast, fact, circular = FALSE, fun = "mean")
```

## Arguments

- rast:

  SpatRaster object

- fact:

  Integer, aggregation factor

- circular:

  Logical, whether variable is circular (e.g., aspect)

- fun:

  Character, aggregation function ("mean", "sum", "modal")

## Value

Aggregated SpatRaster
