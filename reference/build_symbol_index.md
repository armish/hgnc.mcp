# Build Symbol Index from Cached Data

Creates an in-memory lookup index from cached HGNC data for fast symbol
resolution. The index maps symbols, aliases, and previous symbols to
HGNC IDs.

## Usage

``` r
build_symbol_index(hgnc_data = NULL)
```

## Arguments

- hgnc_data:

  Optional data.frame of HGNC data. If NULL, will load from cache.

## Value

A list containing:

- `symbol_to_id`: Named character vector mapping symbols to HGNC IDs

- `alias_to_id`: Named list mapping alias symbols to HGNC IDs (may have
  multiple matches)

- `prev_to_id`: Named list mapping previous symbols to HGNC IDs (may
  have multiple matches)

- `id_to_record`: Named list mapping HGNC IDs to full gene records

- `indexed_at`: Timestamp of index creation

## Details

This function creates lookup tables that enable fast O(1) symbol
resolution without needing to query the REST API. It handles:

- Multiple aliases per gene (stored as lists)

- Multiple previous symbols per gene (stored as lists)

- Potential ambiguity (same alias/prev_symbol for multiple genes)

The index is designed for use by
[`hgnc_normalize_list()`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md)
and other batch operations that need to process many symbols quickly.

## Examples

``` r
if (FALSE) { # \dontrun{
# Build index from cache
index <- build_symbol_index()

# Look up a symbol
hgnc_id <- index$symbol_to_id["BRCA1"]

# Get full record
gene <- index$id_to_record[[hgnc_id]]
print(gene$name)

# Check aliases
if ("BRCA1" %in% names(index$alias_to_id)) {
  print(index$alias_to_id[["BRCA1"]])
}
} # }
```
