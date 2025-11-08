# Get Members of a Gene Group

Retrieve all genes that belong to a specific HGNC gene group or family.
Gene groups represent functionally related genes such as protein
families, complexes, or genes with shared characteristics.

## Usage

``` r
hgnc_group_members_uncached(group_id_or_name)

hgnc_group_members(group_id_or_name, use_cache = TRUE)
```

## Arguments

- group_id_or_name:

  Either a numeric gene group ID or a gene group name. Gene group IDs
  are integers (e.g., 588 for "Zinc fingers C2H2-type"). Names can be
  full or partial matches (e.g., "Zinc finger" or "immunoglobulin").

- use_cache:

  Whether to use session-level caching (default: TRUE). Gene groups
  don't change frequently, so caching is recommended.

## Value

A list containing:

- `numFound`: Number of genes in the group

- `docs`: List of gene records for all group members

- `group_id_or_name`: The query parameter for reference

## Details

This function queries the HGNC REST API to fetch all genes associated
with a specific gene group. Each gene record includes:

- Core identifiers: hgnc_id, symbol, name, status

- Location: location, chromosome

- Cross-references: entrez_id, ensembl_gene_id, etc.

- Group memberships: gene_group, gene_group_id

Gene groups are hierarchical and genes may belong to multiple groups.

By default, results are cached for the R session since gene group
memberships are relatively stable. Use `use_cache = FALSE` to force a
fresh API call.

## See also

[`hgnc_search_groups()`](https://armish.github.io/hgnc.mcp/reference/hgnc_search_groups.md)
to find group IDs by keyword

## Examples

``` r
if (FALSE) { # \dontrun{
# Get members by group ID
zinc_fingers <- hgnc_group_members(588)
print(zinc_fingers$numFound)
print(zinc_fingers$docs[[1]]$symbol)

# Get members by group name (searches for matching group)
# Note: This will search for groups matching the name first
kinases <- hgnc_group_members("kinase")

# Iterate over all members
for (gene in zinc_fingers$docs) {
  cat(gene$symbol, "-", gene$name, "\n")
}

# Force fresh data without cache
current_data <- hgnc_group_members(588, use_cache = FALSE)
} # }
```
