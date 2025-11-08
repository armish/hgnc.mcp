# Resolve Gene Symbol to Approved Symbol

Resolve a gene symbol (which might be an alias or previous symbol) to
the current approved HGNC symbol.

## Usage

``` r
hgnc_resolve_symbol(symbol, mode = "lenient", return_record = FALSE)
```

## Arguments

- symbol:

  Gene symbol to resolve (case-insensitive)

- mode:

  Resolution mode:

  - `"strict"`: Only exact matches on approved symbols

  - `"lenient"`: Search across symbol, alias_symbol, and prev_symbol

- return_record:

  Whether to return the full gene record (default: FALSE)

## Value

A list containing:

- `query`: The original query symbol

- `approved_symbol`: The current approved HGNC symbol (or NA if not
  found)

- `status`: Gene status (e.g., "Approved", "Withdrawn")

- `confidence`: Match confidence ("exact", "alias", "previous", or
  "not_found")

- `hgnc_id`: HGNC identifier

- `candidates`: If ambiguous, list of possible matches

- `record`: Full gene record (if return_record = TRUE)

## Details

This function handles common gene symbol resolution scenarios:

**Strict Mode**:

- Only finds genes where the query exactly matches the approved symbol

- Fastest and most conservative

- Use when you only want official current symbols

**Lenient Mode** (default):

- Searches approved symbols, aliases, and previous symbols

- Handles renamed genes and common aliases

- Returns the current approved symbol

- Indicates how the match was found (exact, alias, or previous)

The function automatically normalizes symbols to uppercase (HGNC
convention).

## Examples

``` r
if (FALSE) { # \dontrun{
# Resolve current symbol
result <- hgnc_resolve_symbol("BRCA1")
print(result$approved_symbol)  # "BRCA1"
print(result$confidence)        # "exact"

# Resolve alias or previous symbol
result <- hgnc_resolve_symbol("GRCh38", mode = "lenient")

# Get full record
result <- hgnc_resolve_symbol("TP53", return_record = TRUE)
print(result$record$location)

# Strict mode
result <- hgnc_resolve_symbol("some_alias", mode = "strict")
# Will return not_found if it's not the approved symbol
} # }
```
