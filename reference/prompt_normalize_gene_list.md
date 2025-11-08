# Generate Normalize Gene List Prompt

Creates a prompt template that guides an AI assistant through the
process of normalizing a gene symbol list to approved HGNC nomenclature.

## Usage

``` r
prompt_normalize_gene_list(
  gene_list = "",
  strictness = "lenient",
  return_xrefs = FALSE
)
```

## Arguments

- gene_list:

  Character vector or comma-separated string of gene symbols to
  normalize

- strictness:

  Character. Either "lenient" (default, allows aliases/prev symbols) or
  "strict" (approved symbols only)

- return_xrefs:

  Logical. Whether to include cross-references (Entrez, Ensembl, etc.)
  in the output (default: FALSE)

## Value

A formatted prompt string guiding the normalization workflow

## Details

This prompt template helps AI assistants understand how to:

1.  Parse and clean the input gene list

2.  Use normalize_list tool for batch processing

3.  Interpret warnings and suggested replacements

4.  Optionally fetch cross-references for harmonization

5.  Present results in a user-friendly format

## Examples

``` r
if (FALSE) { # \dontrun{
prompt_normalize_gene_list(
  gene_list = "BRCA1, tp53, EGFR, OLD_SYMBOL",
  strictness = "lenient",
  return_xrefs = TRUE
)
} # }
```
