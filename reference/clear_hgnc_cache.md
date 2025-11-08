# Clear HGNC Caches

Clears both session-level (memoise) caches and local file caches used by
hgnc.mcp. This forces fresh API calls and file downloads on the next
request.

## Usage

``` r
clear_hgnc_cache()
```

## Value

Invisible TRUE

## Details

This clears:

- The memoise cache for functions like
  [`hgnc_rest_info()`](https://armish.github.io/hgnc.mcp/reference/hgnc_rest_info_uncached.md)

- The local file cache (hgnc_complete_set.txt and metadata)

It does NOT affect:

- The rate limiter state (use
  [`reset_rate_limiter()`](https://armish.github.io/hgnc.mcp/reference/reset_rate_limiter.md)
  for that)

You might want to clear the cache when:

- You know the HGNC database has been updated

- You're debugging and want to ensure fresh data

- You're running tests

## Examples

``` r
if (FALSE) { # \dontrun{
# Get info (will hit API)
info1 <- hgnc_rest_info()

# Get info again (will use cache)
info2 <- hgnc_rest_info()

# Clear cache
clear_hgnc_cache()

# Get info again (will hit API)
info3 <- hgnc_rest_info()
} # }
```
