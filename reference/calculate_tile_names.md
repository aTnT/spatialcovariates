# Generate tile names for 10x10 degree global grid

Generate tile names for 10x10 degree global grid

## Usage

``` r
calculate_tile_names(bbox, tile_size = 10)
```

## Arguments

- bbox:

  Numeric vector of length 4 (xmin, ymin, xmax, ymax)

- tile_size:

  Numeric, size of tiles in degrees (default 10)

## Value

Character vector of tile names in format "NNx_EEWW"
