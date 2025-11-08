# Working with HGNC Gene Groups

## Introduction

HGNC organizes genes into functional groups and families based on shared
characteristics such as:

- **Protein families** - Genes encoding proteins with similar
  structure/function
- **Gene families** - Related genes arising from duplication events
- **Functional categories** - Genes involved in similar biological
  processes
- **Structural features** - Genes encoding proteins with specific
  domains

Gene groups are invaluable for:

- Building gene panels for specific pathways or diseases
- Systematic literature reviews
- Pathway enrichment analysis
- Comparative genomics studies
- Identifying functionally related genes

This vignette demonstrates how to discover, explore, and work with HGNC
gene groups using `hgnc.mcp`.

## Setup

``` r
library(hgnc.mcp)

# Load HGNC data
hgnc_data <- load_hgnc_data()
```

## Discovering Gene Groups

### Searching by Keyword

Use
[`hgnc_search_groups()`](https://armish.github.io/hgnc.mcp/reference/hgnc_search_groups.md)
to find gene groups by keyword:

``` r
# Search for kinase-related groups
kinase_groups <- hgnc_search_groups("kinase")

# View results
print(kinase_groups)

# How many groups found?
cat("Found", nrow(kinase_groups), "kinase-related groups\n")

# View group names
head(kinase_groups$gene_group_name, 10)
```

### Common Search Terms

Here are some useful search terms for different domains:

``` r
# Cancer-related
cancer_groups <- hgnc_search_groups("cancer")
oncogene_groups <- hgnc_search_groups("oncogene")

# Immunology
immune_groups <- hgnc_search_groups("immune")
cytokine_groups <- hgnc_search_groups("cytokine")
chemokine_groups <- hgnc_search_groups("chemokine")

# Metabolism
metabolic_groups <- hgnc_search_groups("metabol")
enzyme_groups <- hgnc_search_groups("enzyme")

# Neuroscience
neuro_groups <- hgnc_search_groups("neuro")
receptor_groups <- hgnc_search_groups("receptor")

# Development
homeobox_groups <- hgnc_search_groups("homeobox")
transcription_groups <- hgnc_search_groups("transcription")
```

### Browsing All Groups

``` r
# Get all gene groups (this may return many results)
all_groups <- hgnc_search_groups("")

# How many total groups?
cat("Total gene groups:", nrow(all_groups), "\n")

# View a random sample
set.seed(42)
sample_groups <- all_groups[sample(nrow(all_groups), 10), ]
print(sample_groups[, c("gene_group_name", "gene_group_id")])
```

## Getting Group Members

### Basic Group Retrieval

Use
[`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members.md)
to get all genes in a specific group:

``` r
# Get members of a specific group by name
kinase_members <- hgnc_group_members("Protein kinases")

# View basic information
cat("Number of protein kinases:", nrow(kinase_members), "\n")

# View first few members
head(kinase_members[, c("symbol", "name", "hgnc_id")])

# Get members by group ID
# aurora_kinases <- hgnc_group_members("588")
```

### Exploring Group Members

``` r
# Get detailed information about group members
kinase_members <- hgnc_group_members("Protein kinases")

# What fields are available?
colnames(kinase_members)

# View symbols
kinase_symbols <- kinase_members$symbol
cat("Kinase symbols:\n")
head(kinase_symbols, 20)

# Export to file for further analysis
# write.csv(kinase_members, "protein_kinases.csv", row.names = FALSE)
```

## Building Gene Panels from Groups

### Example 1: DNA Repair Genes

``` r
# Search for DNA repair groups
dna_repair_groups <- hgnc_search_groups("DNA repair")

# View available groups
print(dna_repair_groups$gene_group_name)

# Get members from multiple related groups
# For this example, let's get Fanconi anemia genes
fanconi_genes <- hgnc_group_members("Fanconi anemia")

# Build a panel
fanconi_panel <- fanconi_genes$symbol

cat("Fanconi anemia panel (", length(fanconi_panel), " genes):\n", sep = "")
cat(paste(fanconi_panel, collapse = ", "), "\n")

# Validate the panel
validation <- hgnc_validate_panel(fanconi_panel)
cat("\nValidation status:", validation$summary$status, "\n")
```

### Example 2: Combining Multiple Groups

``` r
# Build a comprehensive cancer panel from multiple groups

# Get oncogenes
oncogene_groups <- hgnc_search_groups("oncogene")
# Assuming we find a specific group:
# oncogenes <- hgnc_group_members("Oncogenes")$symbol

# Get tumor suppressors
ts_groups <- hgnc_search_groups("tumor suppressor")
# tumor_suppressors <- hgnc_group_members("Tumor suppressors")$symbol

# Combine into comprehensive panel
# cancer_panel <- unique(c(oncogenes, tumor_suppressors))
# cat("Comprehensive cancer panel:", length(cancer_panel), "genes\n")
```

### Example 3: G Protein-Coupled Receptors

``` r
# GPCRs are a large and important gene family
gpcr_groups <- hgnc_search_groups("G protein-coupled receptor")

# View GPCR-related groups
print(gpcr_groups$gene_group_name)

# Get members of a specific GPCR subfamily
# For example, chemokine receptors
chemokine_receptors <- hgnc_group_members("Chemokine receptors")

cat("Chemokine receptors (", nrow(chemokine_receptors), "):\n", sep = "")
print(chemokine_receptors[, c("symbol", "name", "location")])
```

## Working with Gene Families

### Example: Nuclear Receptor Superfamily

``` r
# Nuclear receptors are important transcription factors
nr_groups <- hgnc_search_groups("nuclear receptor")

# Get nuclear receptor subfamily
# nuclear_receptors <- hgnc_group_members("Nuclear receptors")

# Explore subgroups
# cat("Nuclear receptor subgroups:\n")
# unique(nuclear_receptors$gene_group)
```

### Example: Immunoglobulin Genes

``` r
# Search for immunoglobulin groups
ig_groups <- hgnc_search_groups("immunoglobulin")

# View results
print(ig_groups$gene_group_name)

# Get members
# ig_heavy <- hgnc_group_members("Immunoglobulin heavy chain")
# ig_light_kappa <- hgnc_group_members("Immunoglobulin kappa light chain")
```

### Example: Cytochrome P450 Family

``` r
# CYP450 enzymes are important for drug metabolism
cyp_groups <- hgnc_search_groups("cytochrome P450")

# Get all CYP genes
# cyp_genes <- hgnc_group_members("Cytochrome P450 family")

# View by subfamily
# table(cyp_genes$gene_group)
```

## Advanced Group Analysis

### Analyzing Group Composition

``` r
# Get a gene group
kinases <- hgnc_group_members("Protein kinases")

# Analyze by locus type
if ("locus_type" %in% colnames(kinases)) {
  locus_table <- table(kinases$locus_type)
  cat("Locus types:\n")
  print(locus_table)
}

# Analyze by chromosome location
if ("location" %in% colnames(kinases)) {
  # Extract chromosome
  kinases$chr <- sub(":.*", "", kinases$location)
  chr_table <- table(kinases$chr)
  cat("\nDistribution by chromosome:\n")
  print(head(sort(chr_table, decreasing = TRUE), 10))
}

# Analyze by status
if ("status" %in% colnames(kinases)) {
  status_table <- table(kinases$status)
  cat("\nGene status:\n")
  print(status_table)
}
```

### Finding Overlapping Groups

``` r
# Find genes that belong to multiple groups of interest

# Get members from different groups
group1 <- hgnc_group_members("Transcription factors")$symbol
group2 <- hgnc_group_members("Zinc fingers")$symbol

# Find overlap
overlap <- intersect(group1, group2)
cat("Genes in both groups:", length(overlap), "\n")
cat("Examples:", paste(head(overlap, 10), collapse = ", "), "\n")

# Find unique to each group
unique_to_group1 <- setdiff(group1, group2)
unique_to_group2 <- setdiff(group2, group1)

cat("\nUnique to group 1:", length(unique_to_group1), "\n")
cat("Unique to group 2:", length(unique_to_group2), "\n")
```

### Temporal Analysis

Track changes in gene groups over time:

``` r
# Get group members
group_genes <- hgnc_group_members("Protein kinases")$symbol

# Check for recent changes to these genes
recent_changes <- hgnc_changes(
  since = Sys.Date() - 365,
  change_type = "all"
)

# Filter for genes in our group
group_changes <- recent_changes$changes[
  recent_changes$changes$symbol %in% group_genes,
]

if (nrow(group_changes) > 0) {
  cat("Changes to protein kinases in last year:\n")
  print(group_changes[, c("symbol", "date_modified")])
} else {
  cat("No changes to protein kinases in the last year.\n")
}
```

## Creating Custom Gene Collections

### Workflow for Literature-Based Panels

``` r
# Start with genes from a specific biological process

# 1. Search for relevant groups
autophagy_groups <- hgnc_search_groups("autophagy")

# 2. Get initial gene set
# autophagy_genes <- hgnc_group_members("Autophagy")$symbol

# 3. Add genes from literature (hypothetical)
literature_genes <- c("BECN1", "ATG5", "ATG7", "LC3A", "LC3B")

# 4. Combine and deduplicate
# combined_panel <- unique(c(autophagy_genes, literature_genes))

# 5. Validate and normalize
# result <- hgnc_normalize_list(combined_panel)
# validated_panel <- result$results$symbol

# 6. Document provenance
# panel_info <- list(
#   name = "Autophagy Gene Panel",
#   version = "1.0",
#   date = Sys.Date(),
#   source_groups = autophagy_groups$gene_group_name,
#   literature_additions = literature_genes,
#   total_genes = length(validated_panel)
# )
```

### Building Disease-Specific Panels

``` r
# Example: Build a cardiomyopathy panel

# 1. Search for cardiac-related groups
cardiac_groups <- hgnc_search_groups("cardiac")
cardio_groups <- hgnc_search_groups("cardio")

# View available groups
all_cardiac <- rbind(cardiac_groups, cardio_groups)
unique_cardiac <- unique(all_cardiac)

cat("Cardiac-related groups:\n")
print(unique_cardiac$gene_group_name)

# 2. Select relevant groups and get members
# cardiomyopathy_genes <- hgnc_group_members("Cardiomyopathy")$symbol
# ion_channels <- hgnc_group_members("Cardiac ion channels")$symbol

# 3. Combine
# cardio_panel <- unique(c(cardiomyopathy_genes, ion_channels))

# 4. Add known genes from clinical guidelines
# guideline_genes <- c("MYH7", "MYBPC3", "TNNT2", "TNNI3", "TPM1")
# complete_panel <- unique(c(cardio_panel, guideline_genes))

# 5. Get cross-references for clinical reporting
# panel_with_xrefs <- hgnc_normalize_list(
#   complete_panel,
#   return_fields = c("symbol", "name", "hgnc_id", "omim_id", "entrez_id")
# )
```

## Exporting Gene Groups

### Export Formats

``` r
# Get a gene group
kinases <- hgnc_group_members("Protein kinases")

# Export as CSV
write.csv(
  kinases,
  "protein_kinases.csv",
  row.names = FALSE
)

# Export just symbols (one per line)
writeLines(
  kinases$symbol,
  "kinase_symbols.txt"
)

# Export with metadata as JSON
kinase_export <- list(
  metadata = list(
    group_name = "Protein kinases",
    export_date = Sys.Date(),
    gene_count = nrow(kinases),
    hgnc_version = get_hgnc_cache_info()$download_date
  ),
  genes = kinases
)

# jsonlite::write_json(kinase_export, "kinases.json", pretty = TRUE)
```

### Creating Gene Set Files for Analysis Tools

``` r
# Format for GSEA (Gene Set Enrichment Analysis)
create_gmt_entry <- function(group_name, genes, description = "") {
  paste(
    group_name,
    description,
    paste(genes, collapse = "\t"),
    sep = "\t"
  )
}

# Example
kinase_symbols <- hgnc_group_members("Protein kinases")$symbol
gmt_line <- create_gmt_entry(
  "HGNC_PROTEIN_KINASES",
  kinase_symbols,
  "Protein kinase genes from HGNC"
)

# Write to file
# writeLines(gmt_line, "hgnc_kinases.gmt")
```

## Using MCP Resources for Gene Groups

If you’re running the MCP server, you can access gene groups via MCP
resources:

``` r
# Via MCP client, you can use:
# - Tool: search_groups(query) to find groups
# - Tool: group_members(id_or_name) to get members
# - Resource: get_group_card(id_or_name) for formatted cards

# Example API calls:
library(httr)

# Search for groups
# response <- POST(
#   "http://localhost:8080/tools/search_groups",
#   body = list(query = "kinase"),
#   encode = "json"
# )
# groups <- content(response)

# Get group members
# response <- POST(
#   "http://localhost:8080/tools/group_members",
#   body = list(group_id_or_name = "Protein kinases"),
#   encode = "json"
# )
# members <- content(response)
```

## Best Practices

### 1. Version Control for Gene Panels

``` r
# Always document the HGNC version used
create_versioned_panel <- function(genes, panel_name) {
  list(
    panel_name = panel_name,
    creation_date = Sys.Date(),
    hgnc_version = get_hgnc_cache_info()$download_date,
    gene_count = length(genes),
    genes = genes
  )
}

# Example
# kinase_panel <- create_versioned_panel(
#   hgnc_group_members("Protein kinases")$symbol,
#   "Protein Kinase Panel v1.0"
# )
# saveRDS(kinase_panel, "kinase_panel_v1.rds")
```

### 2. Documenting Group Selections

``` r
# Document why you chose specific groups
panel_rationale <- list(
  objective = "Build comprehensive DNA damage response panel",
  groups_included = c(
    "Fanconi anemia",
    "DNA repair",
    "Cell cycle checkpoints"
  ),
  exclusion_criteria = "Excluded genes without established clinical relevance",
  review_date = Sys.Date(),
  reviewer = "Your Name"
)

# Save with panel
# panel_with_rationale <- list(
#   rationale = panel_rationale,
#   genes = panel_genes
# )
# saveRDS(panel_with_rationale, "ddr_panel.rds")
```

### 3. Regular Updates

``` r
# Check for updates to gene groups periodically

# Function to compare panel versions
compare_panel_versions <- function(old_panel, current_group_name) {
  # Get current members
  current_members <- hgnc_group_members(current_group_name)$symbol

  # Compare
  added <- setdiff(current_members, old_panel)
  removed <- setdiff(old_panel, current_members)

  list(
    total_current = length(current_members),
    total_old = length(old_panel),
    added = added,
    removed = removed,
    unchanged = length(intersect(current_members, old_panel))
  )
}

# Example
# old_kinases <- readRDS("kinase_panel_v1.rds")$genes
# comparison <- compare_panel_versions(old_kinases, "Protein kinases")
# print(comparison)
```

## Troubleshooting

### Group Not Found

``` r
# If a group isn't found, search for similar names
query <- "kinase"
results <- hgnc_search_groups(query)

if (nrow(results) == 0) {
  cat("No groups found for:", query, "\n")
  cat("Try broader search terms\n")
} else {
  cat("Found", nrow(results), "groups matching:", query, "\n")
  print(results$gene_group_name)
}
```

### Empty Group Results

``` r
# Check if group name is exact
group_name <- "Protein kinases"
members <- hgnc_group_members(group_name)

if (is.null(members) || nrow(members) == 0) {
  cat("No members found for group:", group_name, "\n")
  cat("Search for correct group name:\n")
  search_results <- hgnc_search_groups("kinase")
  print(search_results$gene_group_name)
}
```

## Next Steps

- Learn about [Normalizing Gene Lists for Clinical
  Panels](https://armish.github.io/hgnc.mcp/articles/normalizing-gene-lists.md)
- Set up the [MCP
  Server](https://armish.github.io/hgnc.mcp/articles/running-mcp-server.md)
  to access groups via API
- Review the [Getting
  Started](https://armish.github.io/hgnc.mcp/articles/getting-started.md)
  guide

## References

- HGNC Gene Groups: <https://www.genenames.org/data/genegroup/>
- Gene Family Information:
  <https://www.genenames.org/help/gene-families/>
- HGNC Guidelines: <https://www.genenames.org/about/guidelines/>
