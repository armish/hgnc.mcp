# Essential Lookup Tools - Usage Examples

This document demonstrates the core HGNC lookup tools implemented in Phase 1.2.

## Overview

Six essential lookup and batch processing functions have been implemented:

### Core Lookup Functions (Phase 1.2)
1. **`hgnc_find()`** - Search for genes across multiple fields
2. **`hgnc_fetch()`** - Retrieve complete gene records by field value
3. **`hgnc_resolve_symbol()`** - Resolve gene symbols to approved symbols
4. **`hgnc_xrefs()`** - Extract cross-references from gene records

### Batch Operations (Phase 1.3)
5. **`build_symbol_index()`** - Create fast lookup index from cached data
6. **`hgnc_normalize_list()`** - Batch normalize gene symbol lists using cached data

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

## Batch Operations (Phase 1.3)

For processing large lists of gene symbols efficiently using cached data.

### 5. Build Symbol Index: `build_symbol_index()`

Create a fast in-memory lookup index from cached HGNC data:

```r
# Build index from cached data (loads cache if needed)
index <- build_symbol_index()

# The index contains multiple lookup tables:
# - symbol_to_id: Direct symbol → HGNC ID mapping
# - alias_to_id: Alias symbols → HGNC ID(s) mapping
# - prev_to_id: Previous symbols → HGNC ID(s) mapping
# - id_to_record: HGNC ID → full gene record mapping

# Quick lookups
hgnc_id <- index$symbol_to_id["BRCA1"]
gene_record <- index$id_to_record[[hgnc_id]]
print(gene_record$name)

# Check if a symbol has aliases
if ("TP53" %in% names(index$alias_to_id)) {
  print(index$alias_to_id[["TP53"]])
}

# Build index from custom data (useful for testing)
custom_data <- load_hgnc_data()
index <- build_symbol_index(custom_data)
```

### 6. Normalize Gene Lists: `hgnc_normalize_list()`

Batch normalize and validate gene symbol lists:

```r
# Basic usage: normalize a list of symbols
gene_list <- c("BRCA1", "TP53", "EGFR", "KRAS", "MYC")
result <- hgnc_normalize_list(gene_list)

# Examine summary
print(result$summary)
# $total_input: 5
# $found: 5
# $not_found: 0
# $withdrawn: 0
# $duplicates_removed: 0

# Access normalized results
print(result$results)
#   symbol  name                    hgnc_id     status    query_symbol match_type
#   BRCA1   BRCA1 DNA repair...     HGNC:1100  Approved  BRCA1        exact
#   TP53    tumor protein p53       HGNC:11998 Approved  TP53         exact
#   ...

# Check warnings
if (length(result$warnings) > 0) {
  cat("Warnings:\n")
  cat(result$warnings, sep = "\n")
}

# Handle not found symbols
if (length(result$not_found) > 0) {
  cat("Not found:", paste(result$not_found, collapse = ", "), "\n")
}
```

**Advanced Usage:**

```r
# Handle mixed case and whitespace
messy_symbols <- c(" brca1 ", "Tp53", "EGFR", "  kras  ")
result <- hgnc_normalize_list(messy_symbols)
# All symbols normalized to uppercase and trimmed

# Detect duplicates
duplicated_list <- c("BRCA1", "BRCA2", "BRCA1", "TP53", "BRCA1")
result <- hgnc_normalize_list(duplicated_list, dedupe = TRUE)
print(result$summary$duplicates_removed)  # 2
# Warnings will indicate which entries were duplicates

# Include all statuses (even withdrawn genes)
result <- hgnc_normalize_list(gene_list, status = NULL)
# Check withdrawn genes
if (nrow(result$withdrawn) > 0) {
  print(result$withdrawn)
}

# Custom return fields
result <- hgnc_normalize_list(
  gene_list,
  return_fields = c("symbol", "name", "hgnc_id", "entrez_id", "location")
)

# Return all available fields
result <- hgnc_normalize_list(gene_list, return_fields = "all")

# Reuse index for multiple batches (much faster)
index <- build_symbol_index()
batch1_result <- hgnc_normalize_list(batch1, index = index)
batch2_result <- hgnc_normalize_list(batch2, index = index)
batch3_result <- hgnc_normalize_list(batch3, index = index)
```

**Handling Problematic Symbols:**

```r
# Mix of valid, invalid, and withdrawn symbols
problem_list <- c(
  "BRCA1",           # valid
  "NOTAREALGENE",    # invalid
  "brca2",           # valid (case insensitive)
  "",                # empty
  NA,                # missing
  "WITHDRAWN_GENE"   # withdrawn (example)
)

result <- hgnc_normalize_list(problem_list)

# Examine each issue category
cat("Found:", result$summary$found, "\n")
cat("Not found:", result$summary$not_found, "\n")
cat("Withdrawn:", result$summary$withdrawn, "\n")

# Get detailed warnings
cat("\nDetailed warnings:\n")
cat(result$warnings, sep = "\n")

# List of symbols that couldn't be resolved
print(result$not_found)

# Details about withdrawn genes
if (nrow(result$withdrawn) > 0) {
  print(result$withdrawn[, c("symbol", "status", "name")])
}
```

**Performance Comparison:**

```r
# Batch operations using cached data (FAST)
system.time({
  result <- hgnc_normalize_list(large_gene_list)
})
# ~1-2 seconds for 1000 symbols

# vs. individual REST API calls (SLOW)
system.time({
  results <- lapply(large_gene_list, function(sym) {
    hgnc_resolve_symbol(sym, mode = "lenient")
  })
})
# ~100+ seconds for 1000 symbols (rate limited)

# For large lists, always use hgnc_normalize_list()!
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

### Example 4: Batch Normalize Clinical Gene Panel

```r
# Scenario: Validate and normalize a clinical gene panel
# Input may have mixed case, aliases, outdated symbols

clinical_panel <- c(
  "BRCA1", "BRCA2",        # Hereditary breast cancer
  "tp53",                   # Mixed case
  "MLH1", "MSH2", "MSH6",  # Lynch syndrome
  "APC",                    # Familial adenomatous polyposis
  "RET",                    # MEN syndromes
  "BRCA1"                   # Duplicate entry
)

# Normalize the entire list at once
result <- hgnc_normalize_list(
  clinical_panel,
  return_fields = c("symbol", "name", "hgnc_id", "location", "status"),
  dedupe = TRUE
)

# Generate QC report
cat("=== Gene Panel Validation Report ===\n\n")
cat("Total input symbols:", result$summary$total_input, "\n")
cat("Valid genes found:", result$summary$found, "\n")
cat("Not found:", result$summary$not_found, "\n")
cat("Withdrawn genes:", result$summary$withdrawn, "\n")
cat("Duplicates removed:", result$summary$duplicates_removed, "\n\n")

# Show match types
if (!is.null(result$summary$match_types)) {
  cat("Match types:\n")
  print(result$summary$match_types)
  cat("\n")
}

# Display warnings
if (length(result$warnings) > 0) {
  cat("Warnings:\n")
  cat(paste("  -", result$warnings), sep = "\n")
  cat("\n")
}

# Final normalized panel
cat("=== Normalized Gene Panel ===\n")
print(result$results[, c("symbol", "name", "location")])

# Export for downstream use
write.csv(result$results, "normalized_panel.csv", row.names = FALSE)
```

### Example 5: Large-Scale Data Harmonization

```r
# Scenario: Harmonize gene symbols from multiple datasets
# Each dataset may use different nomenclature (aliases, old symbols)

# Simulate datasets with different symbol conventions
dataset1 <- c("BRCA1", "TP53", "EGFR")
dataset2 <- c("brca1", "tp53", "her2")  # Mixed case, alias for ERBB2
dataset3 <- c("BRCA1", "P53", "EGFR")   # P53 is old symbol for TP53

# Build index once for efficiency
index <- build_symbol_index()

# Normalize each dataset
datasets <- list(
  dataset1 = dataset1,
  dataset2 = dataset2,
  dataset3 = dataset3
)

harmonized <- lapply(names(datasets), function(ds_name) {
  cat("Processing", ds_name, "...\n")

  result <- hgnc_normalize_list(
    datasets[[ds_name]],
    index = index,
    return_fields = c("symbol", "hgnc_id", "entrez_id")
  )

  # Add dataset source
  if (nrow(result$results) > 0) {
    result$results$dataset <- ds_name
  }

  return(result$results)
})

# Combine all harmonized data
harmonized_df <- do.call(rbind, harmonized)

# Create unified gene list (deduplicated by HGNC ID)
unified <- harmonized_df[!duplicated(harmonized_df$hgnc_id), ]

cat("\n=== Harmonization Summary ===\n")
cat("Total genes across datasets:", nrow(harmonized_df), "\n")
cat("Unique genes:", nrow(unified), "\n")
print(unified)
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

## Change Tracking & Validation (Phase 1.5)

Functions for monitoring gene nomenclature changes and validating gene lists against HGNC policies.

### 7. Track Gene Changes: `hgnc_changes()`

Monitor genes that have been modified since a specific date:

```r
# Find all genes modified in the last 30 days
recent_changes <- hgnc_changes(since = Sys.Date() - 30)

# View summary
print(recent_changes$summary)
# $total: number of changed genes
# $since: the date used for filtering
# $change_type: type of changes tracked
# $symbol_changes: count of symbol changes
# $name_changes: count of name changes

# View changed genes
print(recent_changes$changes)

# Find symbol changes since a specific date
symbol_changes <- hgnc_changes(
  since = "2024-01-01",
  change_type = "symbol"
)

# See which genes had their symbols changed
if (nrow(symbol_changes$changes) > 0) {
  cat("Genes with symbol changes:\n")
  print(symbol_changes$changes[, c("symbol", "prev_symbol", "date_symbol_changed")])
}

# Track name changes with detailed information
name_changes <- hgnc_changes(
  since = "2023-06-01",
  change_type = "name",
  fields = c("symbol", "name", "status", "date_name_changed", "date_modified")
)

# All changes (any modification)
all_changes <- hgnc_changes(
  since = "2024-01-01",
  change_type = "all"
)
print(all_changes$summary)
```

**Use Cases:**
- Monitor watchlists for nomenclature updates
- Ensure compliance with current nomenclature
- Track when genes in your panel were last updated
- Identify genes that need review in your datasets

### 8. Validate Gene Panels: `hgnc_validate_panel()`

Comprehensive quality assurance for gene lists:

```r
# Basic validation
gene_panel <- c("BRCA1", "TP53", "EGFR", "KRAS", "MYC")
validation <- hgnc_validate_panel(gene_panel)

# View summary statistics
print(validation$summary)
# $total_items: total input
# $valid: approved symbols
# $issues: problems found
# $issues_by_type: breakdown by issue type
# $issues_by_severity: errors vs warnings

# View human-readable report
cat(validation$report, sep = "\n")

# Check valid genes
if (nrow(validation$valid) > 0) {
  print(validation$valid[, c("symbol", "name", "hgnc_id")])
}

# Check issues
if (nrow(validation$issues) > 0) {
  print(validation$issues[, c("position", "input", "issue", "message")])
}

# Get replacement suggestions
if (length(validation$replacements) > 0) {
  for (repl in validation$replacements) {
    cat(sprintf("Position %d: '%s' → '%s' (%s)\n",
                repl$position, repl$input,
                repl$suggested, repl$rationale))
  }
}
```

**Validate Clinical Gene Panel with Mixed Quality:**

```r
# Real-world scenario: mixed case, duplicates, old symbols, invalid entries
clinical_panel <- c(
  "BRCA1",           # Valid approved symbol
  "brca2",           # Valid (case insensitive)
  "TP53",            # Valid
  "BRCA1",           # Duplicate
  "P53",             # Previous symbol for TP53 (if applicable)
  "HER2",            # Alias for ERBB2 (if applicable)
  "NOTAREALGENE",    # Invalid
  "",                # Empty
  "MLH1",            # Valid
  "MSH2"             # Valid
)

validation <- hgnc_validate_panel(
  clinical_panel,
  suggest_replacements = TRUE,
  include_dates = TRUE
)

# Generate QC report
cat("\n=== Gene Panel Validation Report ===\n\n")
cat(validation$report, sep = "\n")

# Issues breakdown
if ("issues_by_type" %in% names(validation$summary)) {
  cat("\n\nIssues by type:\n")
  print(validation$summary$issues_by_type)
}

# Detailed issue listing
if (nrow(validation$issues) > 0) {
  cat("\n\nDetailed issues:\n")
  for (i in seq_len(nrow(validation$issues))) {
    issue <- validation$issues[i, ]
    cat(sprintf("[%s] Position %d (%s): %s\n",
                toupper(issue$severity),
                issue$position,
                issue$input,
                issue$message))
  }
}

# Suggested fixes
if (length(validation$replacements) > 0) {
  cat("\n\nSuggested replacements:\n")
  for (repl in validation$replacements) {
    if (!is.na(repl$suggested)) {
      cat(sprintf("  '%s' → '%s'\n    Reason: %s\n",
                  repl$input, repl$suggested, repl$rationale))
    }
  }
}

# Export clean panel (only valid genes)
if (nrow(validation$valid) > 0) {
  write.csv(validation$valid, "validated_panel.csv", row.names = FALSE)
  cat("\n\nClean panel exported to validated_panel.csv\n")
}
```

**Common Validation Issues Detected:**

1. **Alias Used**: Using an alias instead of the approved symbol
2. **Previous Symbol**: Using an outdated symbol (gene was renamed)
3. **Withdrawn**: Gene has been withdrawn from HGNC
4. **Duplicate**: Same gene listed multiple times
5. **Not Found**: Symbol doesn't exist in HGNC database
6. **Empty/NA**: Missing or empty values
7. **Ambiguous**: Symbol matches multiple genes

**Performance Optimization with Pre-built Index:**

```r
# Build index once for validating multiple panels
index <- build_symbol_index()

# Validate multiple panels efficiently
panel1 <- c("BRCA1", "BRCA2", "TP53")
panel2 <- c("MLH1", "MSH2", "MSH6")
panel3 <- c("APC", "KRAS", "NRAS")

result1 <- hgnc_validate_panel(panel1, index = index)
result2 <- hgnc_validate_panel(panel2, index = index)
result3 <- hgnc_validate_panel(panel3, index = index)

# Much faster than building index each time!
```

**Integration with Change Tracking:**

```r
# Workflow: Validate panel, then check when genes were last modified

# 1. Validate your panel
panel <- c("BRCA1", "TP53", "EGFR", "KRAS", "APC")
validation <- hgnc_validate_panel(panel)

# 2. Extract valid genes
if (nrow(validation$valid) > 0) {
  valid_symbols <- validation$valid$symbol

  # 3. Check when these genes were last modified
  # Get the HGNC data with dates
  index <- build_symbol_index()

  for (sym in valid_symbols) {
    hgnc_id <- index$symbol_to_id[sym]
    if (!is.null(hgnc_id) && !is.na(hgnc_id)) {
      gene <- index$id_to_record[[hgnc_id]]

      cat(sprintf("%s (HGNC:%s):\n", sym, hgnc_id))
      if (!is.null(gene$date_modified) && !is.na(gene$date_modified)) {
        cat(sprintf("  Last modified: %s\n", gene$date_modified))
      }
      if (!is.null(gene$date_symbol_changed) && !is.na(gene$date_symbol_changed)) {
        cat(sprintf("  Symbol changed: %s\n", gene$date_symbol_changed))
      }
      cat("\n")
    }
  }
}

# 4. Or use hgnc_changes() to monitor these specific genes
# (by filtering the results to your panel)
recent_changes <- hgnc_changes(since = "2024-01-01")
if (nrow(recent_changes$changes) > 0) {
  panel_changes <- recent_changes$changes[
    recent_changes$changes$symbol %in% valid_symbols,
  ]

  if (nrow(panel_changes) > 0) {
    cat("\nGenes in your panel that changed since 2024-01-01:\n")
    print(panel_changes[, c("symbol", "name", "date_modified")])
  }
}
```

## Next Steps

The core lookup tools (Phase 1.2), batch operations (Phase 1.3), groups & collections (Phase 1.4), and change tracking & validation (Phase 1.5) are now complete. Next phases include:

- **Phase 2**: MCP server implementation
- **Phase 3**: Enhanced features
- **Phase 4**: Polish & distribution

See `TODO.md` for the complete implementation roadmap.
