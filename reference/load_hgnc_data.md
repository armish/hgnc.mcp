# Load HGNC data

Loads the HGNC complete dataset. If the data is not cached or the cache
is stale, it will download the latest version first.

## Usage

``` r
load_hgnc_data(max_age_days = 30, force = FALSE)
```

## Arguments

- max_age_days:

  Maximum age of cache in days (default: 30)

- force:

  Force download even if cache is fresh (default: FALSE)

## Value

A data.frame containing the HGNC complete dataset

## Examples

``` r
if (FALSE) { # \dontrun{
hgnc <- load_hgnc_data()
head(hgnc)
} # }
```
