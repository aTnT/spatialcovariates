# Download Intact Forest Landscapes shapefile

Downloads IFL 2016 shapefile from the official Intact Forests website.

## Usage

``` r
download_ifl(output_folder = "data/IFL", timeout = 600, year = 2016)
```

## Arguments

- output_folder:

  Character, directory to save and extract files (default: "data/IFL")

- timeout:

  Numeric, download timeout in seconds (default: 600)

- year:

  Numeric, year to download (2000, 2013, 2016, or 2020). Default: 2016

## Value

Character, path to the extracted shapefile
