# Download ESA CCI Biomass data from CEDA Archive

Download ESA CCI Biomass data from CEDA Archive

## Usage

``` r
download_esacci_biomass(
  roi = NULL,
  year = 2010,
  version = "v3.0",
  output_folder = "data/ESACCI-BIOMASS",
  n_cores = 1,
  timeout = 600,
  file_names = NULL
)
```

## Arguments

- roi:

  sf object, SpatVector, or NULL for all tiles

- year:

  Numeric or "latest", year to download (2010, 2015-2022)

- version:

  Character or "latest", version to download (v2.0-v6.0)

- output_folder:

  Character, directory to save files (default: "data/ESACCI-BIOMASS")

- n_cores:

  Integer, number of cores for parallel download (default: 1)

- timeout:

  Numeric, download timeout in seconds (default: 600)

- file_names:

  Character vector, optional specific filenames to download

## Value

Character vector of downloaded file paths
