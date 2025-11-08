# Search for Gene Groups

Search for HGNC gene groups by keyword. Gene groups represent
functionally related genes such as protein families, complexes, or genes
with shared characteristics.

## Usage

``` r
hgnc_search_groups(query, limit = 100)
```

## Arguments

- query:

  Search query string (e.g., "kinase", "zinc finger", "immunoglobulin")

- limit:

  Maximum number of results to return (default: 100)

## Value

A list containing:

- `numFound`: Total number of matching groups

- `groups`: List of matching gene group records, each containing:

  - `id`: Gene group ID (numeric)

  - `name`: Gene group name

  - `description`: Detailed description (if available)

- `query`: The original query for reference

## Details

This function searches the HGNC database for gene groups matching your
query. Groups are collections of functionally related genes, such as:

- Protein families (e.g., "Zinc fingers", "Kinases", "Immunoglobulins")

- Gene complexes (e.g., "Proteasome", "Ribosomal proteins")

- Functional categories (e.g., "Transcription factors", "G-protein
  coupled receptors")

The search is performed across group names and descriptions, returning
groups with relevance-based ranking.

Once you have a group ID, use
[`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md)
to retrieve all genes in that group.

## See also

[`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md)
to get genes in a specific group

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for kinase groups
kinase_groups <- hgnc_search_groups("kinase")
print(kinase_groups$numFound)

# Show group names
for (group in kinase_groups$groups) {
  cat(group$id, ":", group$name, "\n")
}

# Search for zinc finger groups
zf_groups <- hgnc_search_groups("zinc finger", limit = 10)

# Get members of the first matching group
if (zf_groups$numFound > 0) {
  first_group_id <- zf_groups$groups[[1]]$id
  members <- hgnc_group_members(first_group_id)
  print(members$numFound)
}
} # }
```
