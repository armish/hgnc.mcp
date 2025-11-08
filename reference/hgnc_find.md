# Search for Genes in HGNC Database

Search across gene symbols, aliases, previous symbols, and names using
the HGNC REST API `/search` endpoint.

## Usage

``` r
hgnc_find(query, filters = NULL, limit = 100)
```

## Arguments

- query:

  Search query string (e.g., "BRCA1", "insulin", "kinase")

- filters:

  Optional named list of filters to apply. Supported filters include:
  `status` (e.g., "Approved"), `locus_type` (e.g., "gene with protein
  product"), `locus_group`, etc. See HGNC API documentation for complete
  list.

- limit:

  Maximum number of results to return (default: 100)

## Value

A list containing:

- `numFound`: Total number of matches

- `docs`: List of matched gene records with scores

- `query`: The original query for reference

## Details

The search function queries across multiple fields including:

- symbol: Official gene symbol

- alias_symbol: Alternative symbols

- prev_symbol: Previous symbols

- name: Gene name

Results include a relevance score to help rank matches.

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple search
results <- hgnc_find("BRCA1")

# Search with filters
results <- hgnc_find("kinase",
  filters = list(
    status = "Approved",
    locus_type = "gene with protein product"
  )
)

# Check number of results
print(results$numFound)

# Access top result
top_gene <- results$docs[[1]]
print(top_gene$symbol)
} # }
```
