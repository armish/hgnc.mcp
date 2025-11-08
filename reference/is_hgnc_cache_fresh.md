# Check if cached HGNC data exists and is fresh

Check if cached HGNC data exists and is fresh

## Usage

``` r
is_hgnc_cache_fresh(max_age_days = 30)
```

## Arguments

- max_age_days:

  Maximum age of cache in days before it's considered stale (default:
  30)

## Value

Logical indicating whether cache exists and is fresh

## Examples

``` r
if (FALSE) { # \dontrun{
is_hgnc_cache_fresh()
is_hgnc_cache_fresh(max_age_days = 7)
} # }
```
