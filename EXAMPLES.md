# Essential Lookup Tools - Usage Examples

This document demonstrates the core HGNC lookup tools implemented in Phase 1.2.

## Overview

Four essential lookup functions have been implemented:

1. **`hgnc_find()`** - Search for genes across multiple fields
2. **`hgnc_fetch()`** - Retrieve complete gene records by field value
3. **`hgnc_resolve_symbol()`** - Resolve gene symbols to approved symbols
4. **`hgnc_xrefs()`** - Extract cross-references from gene records

## Installation & Setup

```r
# Install dependencies if needed
# install.packages(c("httr", "jsonlite", "memoise", "rappdirs", "readr", "lubridate"))

# Load the package
library(hgnc.mcp)
```

## Function Examples

### 1. Search for Genes: `hgnc_find()`

Search across gene symbols, aliases, previous symbols, and names:

```r
# Simple search
results <- hgnc_find("BRCA1")
print(results$numFound)
print(results$docs[[1]]$symbol)

# Search with filters
kinase_genes <- hgnc_find("kinase",
  filters = list(
    status = "Approved",
    locus_type = "gene with protein product"
  ),
  limit = 10
)

# Explore results
for (doc in kinase_genes$docs) {
  cat(sprintf("%s - %s\n", doc$symbol, doc$name))
}
```

### 2. Fetch Gene Records: `hgnc_fetch()`

Retrieve complete gene information using various identifiers:

```r
# Fetch by official symbol
gene <- hgnc_fetch("symbol", "BRCA1")
record <- gene$docs[[1]]

cat("Symbol:", record$symbol, "\n")
cat("Name:", record$name, "\n")
cat("Location:", record$location, "\n")
cat("Status:", record$status, "\n")

# Fetch by HGNC ID
gene <- hgnc_fetch("hgnc_id", "HGNC:1100")

# Fetch by Entrez ID
gene <- hgnc_fetch("entrez_id", "672")

# Fetch by Ensembl ID
gene <- hgnc_fetch("ensembl_gene_id", "ENSG00000012048")
```

### 3. Resolve Gene Symbols: `hgnc_resolve_symbol()`

Resolve symbols, aliases, or previous symbols to current approved symbols:

```r
# Resolve current symbol (strict mode)
result <- hgnc_resolve_symbol("BRCA1", mode = "strict")
cat("Approved Symbol:", result$approved_symbol, "\n")
cat("Confidence:", result$confidence, "\n")
cat("HGNC ID:", result$hgnc_id, "\n")

# Resolve with lenient mode (searches aliases and previous symbols)
result <- hgnc_resolve_symbol("TP53", mode = "lenient")
cat("Approved Symbol:", result$approved_symbol, "\n")
cat("Match Type:", result$confidence, "\n")

# Case insensitive
result <- hgnc_resolve_symbol("brca1", mode = "strict")
# Returns "BRCA1"

# Get full gene record
result <- hgnc_resolve_symbol("EGFR", mode = "lenient", return_record = TRUE)
cat("Location:", result$record$location, "\n")
cat("Chromosome:", result$record$chromosome, "\n")

# Handle not found
result <- hgnc_resolve_symbol("NOTAREALGENE", mode = "strict")
if (result$confidence == "not_found") {
  cat("Gene not found\n")
}
```

### 4. Extract Cross-References: `hgnc_xrefs()`

Get external database identifiers for dataset harmonization:

```r
# Get cross-references by symbol
xrefs <- hgnc_xrefs("BRCA1")

cat("HGNC ID:", xrefs$hgnc_id, "\n")
cat("Symbol:", xrefs$symbol, "\n")
cat("Entrez ID:", xrefs$entrez_id, "\n")
cat("Ensembl ID:", xrefs$ensembl_gene_id, "\n")
cat("UniProt:", xrefs$uniprot_ids, "\n")
cat("OMIM:", xrefs$omim_id, "\n")
cat("MANE Select:", xrefs$mane_select, "\n")

# Get cross-references by HGNC ID
xrefs <- hgnc_xrefs("HGNC:1100")

# Batch processing example
my_genes <- c("BRCA1", "BRCA2", "TP53", "EGFR", "KRAS")
xref_table <- lapply(my_genes, function(gene) {
  x <- hgnc_xrefs(gene)
  if (!is.null(x)) {
    data.frame(
      symbol = x$symbol,
      hgnc_id = x$hgnc_id,
      entrez = x$entrez_id,
      ensembl = x$ensembl_gene_id,
      stringsAsFactors = FALSE
    )
  }
})
xref_df <- do.call(rbind, xref_table)
print(xref_df)
```

## Complete Workflow Examples

### Example 1: Search → Resolve → Get Cross-References

```r
# 1. Search for genes
search_results <- hgnc_find("breast cancer", limit = 5)

# 2. Resolve top result to ensure it's the current symbol
top_symbol <- search_results$docs[[1]]$symbol
resolved <- hgnc_resolve_symbol(top_symbol, mode = "lenient")

# 3. Get cross-references for the approved symbol
if (resolved$confidence != "not_found") {
  xrefs <- hgnc_xrefs(resolved$approved_symbol)
  cat("Mapping", resolved$query, "to databases:\n")
  cat("  NCBI Gene:", xrefs$entrez_id, "\n")
  cat("  Ensembl:", xrefs$ensembl_gene_id, "\n")
}
```

### Example 2: Normalize a List of Gene Symbols

```r
# Input: mixed case, possibly outdated symbols
gene_list <- c("brca1", "tp53", "egfr", "KRAS", "her2")

# Normalize each symbol
normalized <- lapply(gene_list, function(symbol) {
  result <- hgnc_resolve_symbol(symbol, mode = "lenient")

  list(
    input = symbol,
    approved = result$approved_symbol,
    confidence = result$confidence,
    status = result$status
  )
})

# Convert to data frame
norm_df <- do.call(rbind, lapply(normalized, as.data.frame))
print(norm_df)
```

### Example 3: ID Conversion for Dataset Harmonization

```r
# Convert Entrez IDs to Ensembl IDs
entrez_ids <- c("672", "7157", "1956")  # BRCA1, TP53, EGFR

conversion <- lapply(entrez_ids, function(eid) {
  gene <- hgnc_fetch("entrez_id", eid)

  if (gene$numFound > 0) {
    doc <- gene$docs[[1]]
    data.frame(
      entrez_id = eid,
      symbol = doc$symbol,
      ensembl_id = doc$ensembl_gene_id %||% NA,
      stringsAsFactors = FALSE
    )
  }
})

conversion_table <- do.call(rbind, conversion)
print(conversion_table)
```

## Testing

Run the comprehensive test suite:

```r
# Install testthat if needed
# install.packages("testthat")

# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test-hgnc_tools.R")
```

## Rate Limiting

All functions automatically respect HGNC's rate limit of 10 requests per second:

```r
# The rate limiter works automatically
for (i in 1:20) {
  result <- hgnc_find(paste0("gene", i))
  # Automatically throttled to ≤10 req/sec
}

# Reset rate limiter (mainly for testing)
reset_rate_limiter()
```

## Caching

The `hgnc_rest_info()` function is cached for the session:

```r
# First call hits API
info1 <- hgnc_rest_info()

# Second call uses cache (instant)
info2 <- hgnc_rest_info()

# Clear cache to force fresh API call
clear_hgnc_cache()

# Next call will hit API again
info3 <- hgnc_rest_info()
```

## Error Handling

```r
# Handle not found
result <- hgnc_resolve_symbol("INVALIDGENE", mode = "strict")
if (is.na(result$approved_symbol)) {
  cat("Gene not found\n")
}

# Handle missing cross-references
xrefs <- hgnc_xrefs("BRCA1")
if (!is.na(xrefs$omim_id)) {
  cat("OMIM ID:", xrefs$omim_id, "\n")
} else {
  cat("No OMIM ID available\n")
}

# Handle withdrawn genes
result <- hgnc_resolve_symbol("SOMEGENE", mode = "lenient")
if (result$status == "Withdrawn") {
  cat("Warning: This gene has been withdrawn\n")
}
```

## Next Steps

These essential lookup tools form the foundation for:

- **Phase 1.3**: Batch operations using cached data
- **Phase 1.4**: Gene groups and collections
- **Phase 1.5**: Change tracking and validation
- **Phase 2**: MCP server implementation

See `TODO.md` for the complete implementation roadmap.
