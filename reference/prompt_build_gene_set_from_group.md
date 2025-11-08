# Generate Build Gene Set from Group Prompt

Creates a prompt template for discovering an HGNC gene group and
building a reusable gene set definition from its members.

## Usage

``` r
prompt_build_gene_set_from_group(group_query = "")
```

## Arguments

- group_query:

  Character. Search query for finding gene groups (e.g., "kinase", "zinc
  finger", "immunoglobulin")

## Value

A formatted prompt string guiding the gene set building workflow

## Details

This prompt helps AI assistants:

1.  Search for relevant HGNC gene groups by keyword

2.  Select the most appropriate group

3.  Retrieve all member genes

4.  Build a structured gene set definition

5.  Provide metadata for reproducibility

## Examples

``` r
if (FALSE) { # \dontrun{
prompt_build_gene_set_from_group(group_query = "protein kinase")
} # }
```
