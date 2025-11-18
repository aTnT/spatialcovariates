# Download file with retry logic and exponential backoff

Download file with retry logic and exponential backoff

## Usage

``` r
download_with_retry(
  url,
  destfile,
  max_attempts = 3,
  timeout = 600,
  quiet = FALSE
)
```

## Arguments

- url:

  Character, URL to download from

- destfile:

  Character, destination file path

- max_attempts:

  Integer, maximum number of retry attempts (default 3)

- timeout:

  Numeric, timeout in seconds (default 600)

- quiet:

  Logical, suppress download messages (default FALSE)

## Value

Logical, TRUE if successful, FALSE otherwise
