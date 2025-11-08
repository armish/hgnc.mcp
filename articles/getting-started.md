# Getting Started with hgnc.mcp

## Introduction

The `hgnc.mcp` package provides tools for accessing HGNC (HUGO Gene
Nomenclature Committee) gene nomenclature data. It offers:

- **Gene symbol search and resolution** - Find genes by symbol, alias,
  or previous symbol
- **Batch normalization** - Clean and standardize gene lists using local
  cached data
- **Validation** - Check gene panels for nomenclature compliance
- **Change tracking** - Monitor updates to gene symbols and status
- **MCP Server** - Expose HGNC services to AI assistants and copilots

This vignette will walk you through the basic functionality and get you
up and running quickly.

## Installation

``` r
# Install from GitHub
# remotes::install_github("yourusername/hgnc.mcp")

# Load the package
library(hgnc.mcp)
```

## Data Management

The package uses smart caching to manage the HGNC complete dataset. On
first use, it downloads data from the official HGNC source and caches it
locally for fast access.

### Loading HGNC Data

``` r
# Load HGNC data (downloads and caches on first use)
hgnc <- load_hgnc_data()

# View basic information
dim(hgnc)
colnames(hgnc)
```

### Cache Management

``` r
# Check cache status
cache_info <- get_hgnc_cache_info()
print(cache_info)

# Check if cache is fresh (default: 30 days)
is_fresh <- is_hgnc_cache_fresh()

# Force refresh the cache if needed
if (!is_fresh) {
  hgnc <- load_hgnc_data(force = TRUE)
}

# Clear cache if needed
# clear_hgnc_cache()
```

### Cache Location

The cache is stored in a platform-appropriate location:

- **Linux**: `~/.cache/hgnc.mcp/`
- **macOS**: `~/Library/Caches/hgnc.mcp/`
- **Windows**: `%LOCALAPPDATA%/hgnc.mcp/Cache/`

## Basic Gene Lookups

### Searching for Genes

Use
[`hgnc_find()`](https://armish.github.io/hgnc.mcp/reference/hgnc_find.md)
to search across gene symbols, aliases, previous symbols, and names:

``` r
# Simple search
results <- hgnc_find("BRCA")
print(results$numFound)

# View first result
if (results$numFound > 0) {
  gene <- results$docs[[1]]
  cat("Symbol:", gene$symbol, "\n")
  cat("Name:", gene$name, "\n")
  cat("Location:", gene$location, "\n")
}

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

### Fetching Complete Gene Records

Use
[`hgnc_fetch()`](https://armish.github.io/hgnc.mcp/reference/hgnc_fetch.md)
to retrieve complete gene information:

``` r
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

### Resolving Gene Symbols

Use
[`hgnc_resolve_symbol()`](https://armish.github.io/hgnc.mcp/reference/hgnc_resolve_symbol.md)
to resolve symbols, aliases, or previous symbols to current approved
symbols:

``` r
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
```

### Getting Cross-References

Use
[`hgnc_xrefs()`](https://armish.github.io/hgnc.mcp/reference/hgnc_xrefs.md)
to extract cross-references to other databases:

``` r
# Get cross-references for a gene
xrefs <- hgnc_xrefs("BRCA1")

# View available cross-references
names(xrefs)

# Access specific cross-references
cat("Entrez ID:", xrefs$entrez_id, "\n")
cat("Ensembl ID:", xrefs$ensembl_gene_id, "\n")
cat("UniProt ID:", xrefs$uniprot_id, "\n")
cat("OMIM ID:", xrefs$omim_id, "\n")
```

## Batch Operations

### Normalizing Gene Lists

Use
[`hgnc_normalize_list()`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md)
to batch normalize gene symbols using local cached data:

``` r
# Create a list of gene symbols with various issues
symbols <- c(
  "BRCA1",        # Valid approved symbol
  "tp53",         # Lowercase (should uppercase)
  "EGFR",         # Valid
  "OLD_SYMBOL",   # May be a previous symbol
  "invalid",      # Invalid
  "BRCA1"         # Duplicate
)

# Normalize the list
result <- hgnc_normalize_list(symbols)

# View results
print(result$results)

# Check summary
print(result$summary)

# View warnings
print(result$warnings)
```

### Validation

Use
[`hgnc_validate_panel()`](https://armish.github.io/hgnc.mcp/reference/hgnc_validate_panel.md)
to validate gene panels against HGNC policy:

``` r
# Validate a gene panel
panel <- c("BRCA1", "BRCA2", "TP53", "ATM", "CHEK2")
validation <- hgnc_validate_panel(panel)

# Check for issues
print(validation$summary)
print(validation$report)

# View replacement suggestions if any
if (!is.null(validation$suggestions)) {
  print(validation$suggestions)
}
```

## Working with Gene Groups

### Searching for Gene Groups

Use
[`hgnc_search_groups()`](https://armish.github.io/hgnc.mcp/reference/hgnc_search_groups.md)
to find gene groups by keyword:

``` r
# Search for gene groups
kinases <- hgnc_search_groups("kinase")

# View results
for (i in seq_len(min(5, nrow(kinases)))) {
  cat(sprintf("%s: %s\n",
              kinases$gene_group_name[i],
              kinases$gene_group_id[i]))
}
```

### Getting Group Members

Use
[`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md)
to retrieve all genes in a specific group:

``` r
# Get members of a specific group
members <- hgnc_group_members("Protein kinases")

# View member count
cat("Number of members:", nrow(members), "\n")

# View first few members
head(members[, c("symbol", "name", "hgnc_id")])
```

## Tracking Changes

Use
[`hgnc_changes()`](https://armish.github.io/hgnc.mcp/reference/hgnc_changes.md)
to track nomenclature changes over time:

``` r
# Find genes modified in the last 30 days
recent_changes <- hgnc_changes(since = Sys.Date() - 30)
print(recent_changes$summary)

# Track symbol changes since a specific date
symbol_changes <- hgnc_changes(
  since = "2024-01-01",
  change_type = "symbol"
)

# View changes
if (nrow(symbol_changes$changes) > 0) {
  head(symbol_changes$changes[, c("symbol", "date_symbol_changed")])
}
```

## Next Steps

Now that you’re familiar with the basics, you can:

- Learn about [Normalizing Gene Lists for Clinical
  Panels](https://armish.github.io/hgnc.mcp/articles/normalizing-gene-lists.md)
- Set up the [MCP
  Server](https://armish.github.io/hgnc.mcp/articles/running-mcp-server.md)
- Explore [Working with HGNC Gene
  Groups](https://armish.github.io/hgnc.mcp/articles/gene-groups.md)

## Getting Help

- Function documentation:
  [`?hgnc_find`](https://armish.github.io/hgnc.mcp/reference/hgnc_find.md),
  [`?hgnc_normalize_list`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md),
  etc.
- Package help:
  [`help(package = "hgnc.mcp")`](https://rdrr.io/pkg/hgnc.mcp/man)
- Examples: See `EXAMPLES.md` in the package repository
- Issues: Report bugs at
  <https://github.com/yourusername/hgnc.mcp/issues>
