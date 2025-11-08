# Download HGNC data from the official source

Downloads the complete HGNC dataset from the official Google Cloud
Storage and saves it to the cache directory along with metadata.

## Usage

``` r
download_hgnc_data(url = .HGNC_DATA_URL, force = FALSE)
```

## Arguments

- url:

  URL to the HGNC data file (default: official HGNC complete set)

- force:

  Force download even if cache exists (default: FALSE)

## Value

Invisible path to the cached file

## Examples

``` r
if (FALSE) { # \dontrun{
download_hgnc_data()
download_hgnc_data(force = TRUE)
} # }
```
