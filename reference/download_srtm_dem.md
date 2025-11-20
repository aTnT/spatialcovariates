# Download SRTM DEM tiles

Downloads SRTM 90m (SRTMGL3 v003) tiles from USGS MEASURES server.

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

## Details

**Authentication**: USGS MEASURES server requires NASA Earthdata
authentication.

**Setup (recommended)**: Install earthdatalogin package and configure
credentials:

    install.packages("earthdatalogin")
    earthdatalogin::edl_netrc(username = "your_username", password = "your_password")

Register for free at: https://urs.earthdata.nasa.gov/users/new

**Alternative Sources**:

- Manual Download: Download tiles from
  https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/

- Google Earth Engine: Use `ee$Image("USGS/SRTMGL1_003")` if you have
  rgee configured

- elevation package: R package with alternative SRTM access
  (install.packages("elevation"))
