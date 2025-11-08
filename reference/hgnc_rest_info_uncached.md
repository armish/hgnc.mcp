# Get HGNC REST API Information

Retrieves metadata about the HGNC REST API, including the last
modification date, searchable fields, and stored fields. Useful for
cache invalidation decisions and understanding API capabilities.

## Usage

``` r
hgnc_rest_info_uncached()

hgnc_rest_info()
```

## Value

A list containing:

- lastModified: Timestamp of last database update

- searchableFields: Fields that can be used in search queries

- storedFields: All fields stored in gene records

## Details

The /info endpoint provides:

- `lastModified`: ISO 8601 timestamp of the last HGNC database update.
  Use this to determine if your local cache is stale.

- `searchableFields`: Fields you can filter/search on

- `storedFields`: All available fields in gene records

This function is cached by default using memoise, so repeated calls
within the same R session will return instantly without hitting the API.
The cache can be cleared with
[`clear_hgnc_cache()`](https://armish.github.io/hgnc.mcp/reference/clear_hgnc_cache.md).

## See also

[`clear_hgnc_cache()`](https://armish.github.io/hgnc.mcp/reference/clear_hgnc_cache.md)
to clear the session cache

## Examples

``` r
if (FALSE) { # \dontrun{
# Get API info
info <- hgnc_rest_info()

# Check last modification date
last_modified <- info$lastModified
print(last_modified)

# See what fields are searchable
print(info$searchableFields)

# See what fields are stored
print(info$storedFields)
} # }
```
