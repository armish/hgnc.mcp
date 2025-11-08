# Normalize Gene Symbol List

Batch normalize a list of gene symbols using cached HGNC data. This
function is optimized for processing large lists of symbols quickly
without making REST API calls.

## Usage

``` r
hgnc_normalize_list(
  symbols,
  return_fields = c("symbol", "name", "hgnc_id", "status", "locus_type", "location",
    "alias_symbol", "prev_symbol"),
  status = "Approved",
  dedupe = TRUE,
  index = NULL
)
```

## Arguments

- symbols:

  Character vector of gene symbols to normalize

- return_fields:

  Character vector of fields to include in output. Default includes
  essential fields. Use "all" to return all available fields. Common
  fields: symbol, name, hgnc_id, status, locus_type, location,
  entrez_id, ensembl_gene_id, uniprot_ids, alias_symbol, prev_symbol

- status:

  Character vector of statuses to include (default: "Approved"). Set to
  NULL to include all statuses.

- dedupe:

  Logical, whether to deduplicate by HGNC ID (default: TRUE)

- index:

  Optional pre-built symbol index from
  [`build_symbol_index()`](https://armish.github.io/hgnc.mcp/reference/build_symbol_index.md).
  If NULL, will build index from cached data.

## Value

A list containing:

- `results`: Data frame with normalized gene information

- `summary`: Summary statistics (total, found, not_found, withdrawn,
  duplicates)

- `warnings`: Character vector of warning messages for problematic
  entries

- `not_found`: Character vector of symbols that could not be resolved

- `withdrawn`: Data frame of withdrawn genes (if any)

- `duplicates`: Data frame of duplicate entries (if dedupe = TRUE)

## Details

This function performs the following steps:

1.  Normalizes input symbols (uppercase, trim whitespace)

2.  Resolves symbols using the index (checks symbol, then alias, then
    prev_symbol)

3.  Filters by status if specified

4.  Deduplicates by HGNC ID if requested

5.  Returns comprehensive results with warnings for problematic entries

**Resolution Strategy**:

- First tries exact match on approved symbol (highest confidence)

- Then tries alias_symbol matches (medium confidence)

- Finally tries prev_symbol matches (lower confidence, gene may be
  renamed)

- Reports match type and potential ambiguity

**Performance**:

- Uses in-memory lookups (no API calls)

- Can process thousands of symbols per second

- Ideal for bulk validation and normalization

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic normalization
symbols <- c("BRCA1", "BRCA2", "TP53", "INVALID", "withdrawn_gene")
result <- hgnc_normalize_list(symbols)

# Check results
print(result$summary)
print(result$results)

# View warnings
if (length(result$warnings) > 0) {
  cat(result$warnings, sep = "\n")
}

# Include all statuses
result <- hgnc_normalize_list(symbols, status = NULL)

# Custom fields
result <- hgnc_normalize_list(
  symbols,
  return_fields = c("symbol", "name", "hgnc_id", "entrez_id", "location")
)

# Reuse index for multiple batches (more efficient)
index <- build_symbol_index()
result1 <- hgnc_normalize_list(batch1, index = index)
result2 <- hgnc_normalize_list(batch2, index = index)
} # }
```
