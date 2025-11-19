# Download GLAD Tree Cover 2010 data

Downloads GLAD Tree Cover 2010 data from University of Maryland GLAD
lab. Data represents tree canopy cover percentage (0-100) for year 2010
at 30m resolution.

## Usage

``` r
download_glad_tcc_2010(
  roi = NULL,
  output_folder = "data/GLAD_TCC_2010",
  n_cores = 1,
  timeout = 1800
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL for global

- output_folder:

  Character, directory to save files (default: "data/GLAD_TCC_2010")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 1800)

## Value

Character vector of downloaded file paths
