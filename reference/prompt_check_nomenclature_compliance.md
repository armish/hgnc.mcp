# Generate Nomenclature Compliance Check Prompt

Creates a prompt template for validating a gene panel against HGNC
nomenclature policy and suggesting corrections.

## Usage

``` r
prompt_check_nomenclature_compliance(panel_text = "", file_uri = NULL)
```

## Arguments

- panel_text:

  Character. Gene panel as text (symbols separated by commas, newlines,
  or whitespace) or empty string if file-based

- file_uri:

  Character. URI to a file containing the gene panel (optional,
  alternative to panel_text)

## Value

A formatted prompt string guiding the compliance check workflow

## Details

This prompt helps AI assistants perform HGNC nomenclature compliance
checks by:

1.  Parsing the gene panel from text or file

2.  Using validate_panel tool to check against HGNC policy

3.  Categorizing issues (withdrawn, non-approved, duplicates)

4.  Presenting replacement suggestions with rationale

5.  Generating a compliance report

## Examples

``` r
if (FALSE) { # \dontrun{
prompt_check_nomenclature_compliance(
  panel_text = "BRCA1, BRCA2, TP53, OLD_SYMBOL"
)
} # }
```
