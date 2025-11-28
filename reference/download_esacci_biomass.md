# Download ESA CCI Biomass data from CEDA Archive

Download ESA CCI Biomass data from CEDA Archive

## Usage

``` r
download_esacci_biomass(
  esacci_biomass_year = "latest",
  esacci_biomass_version = "latest",
  esacci_folder = "data/ESACCI-BIOMASS",
  n_cores = parallel::detectCores() - 1,
  timeout = 600,
  file_names = NULL
)
```

## Arguments

- esacci_biomass_year:

  Numeric or "latest", year to download (2007, 2010, 2015-2022)

- esacci_biomass_version:

  Character or "latest", version to download (v2.0-v6.0)

- esacci_folder:

  Character, directory to save files (default: "data/ESACCI-BIOMASS")

- n_cores:

  Integer, number of cores for parallel download (default:
  parallel::detectCores() - 1)

- timeout:

  Numeric, download timeout in seconds (default: 600)

- file_names:

  Character vector, optional specific filenames to download

## Value

Character vector of downloaded file paths
