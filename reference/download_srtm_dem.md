# Download SRTM DEM tiles

Downloads SRTM Version 4.1 tiles from CGIAR-CSI or OpenTopography.

## Usage

``` r
download_srtm_dem(
  roi = NULL,
  output_folder = "data/SRTM",
  n_cores = 1,
  timeout = 600
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL

- output_folder:

  Character, directory to save files (default: "data/SRTM")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 600)

## Value

Character vector of downloaded file paths
