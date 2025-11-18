# Download Potapov Forest Canopy Height data

Downloads Global Forest Canopy Height data (Potapov et al., 2021) from
GLAD. Data represents forest height circa 2019 at 30m resolution.

## Usage

``` r
download_potapov_height(
  roi = NULL,
  output_folder = "data/POTAPOV_HEIGHT",
  n_cores = 1,
  timeout = 1800
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL for global

- output_folder:

  Character, directory to save files (default: "data/POTAPOV_HEIGHT")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 1800)

## Value

Character vector of downloaded file paths
