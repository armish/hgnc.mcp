# Generate What Changed Since Prompt

Creates a prompt template for generating a human-readable summary of
HGNC nomenclature changes since a specific date.

## Usage

``` r
prompt_what_changed_since(since = NULL)
```

## Arguments

- since:

  Character. ISO 8601 date (YYYY-MM-DD) from which to track changes. If
  not provided, uses 30 days ago as default.

## Value

A formatted prompt string guiding the change tracking workflow

## Details

This prompt helps AI assistants create governance-friendly change
reports by:

1.  Querying HGNC changes since the specified date

2.  Categorizing changes by type (symbol, name, status)

3.  Highlighting significant changes (withdrawals, renames)

4.  Presenting in a format suitable for compliance and watchlist
    tracking

## Examples

``` r
if (FALSE) { # \dontrun{
prompt_what_changed_since(since = "2024-01-01")
} # }
```
