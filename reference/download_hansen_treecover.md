# Download Hansen Global Forest Change tree cover data

Downloads Global Forest Change tree cover data (Hansen et al., 2013)
representing year 2000 conditions at 30m resolution from Google Cloud
Storage.

## Usage

``` r
download_hansen_treecover(
  roi = NULL,
  output_folder = "data/HANSEN_TC",
  n_cores = 1,
  timeout = 1800,
  version = "GFC-2023-v1.11"
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL

- output_folder:

  Character, directory to save files (default: "data/HANSEN_TC")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 1800)

- version:

  Character, GFC version to download (default: "GFC-2023-v1.11")

## Value

Character vector of downloaded file paths
