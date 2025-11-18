# Download Sexton Tree Cover data from UMD GLCF

Downloads Global Tree Canopy Cover data (Sexton et al., 2015)
representing 2015 conditions at 30m resolution.

## Usage

``` r
download_sexton_treecover(
  roi = NULL,
  output_folder = "data/SEXTON_TCC",
  n_cores = 1,
  timeout = 1800,
  year = 2015
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL

- output_folder:

  Character, directory to save files (default: "data/SEXTON_TCC")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 1800)

- year:

  Numeric, year to download (2010 or 2015, default: 2015)

## Value

Character vector of downloaded file paths
