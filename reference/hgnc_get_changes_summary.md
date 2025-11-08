# Get Changes Summary Resource

Retrieve a summary of nomenclature changes since a specified date.
Provides a compact change log with gene IDs, symbols, and modification
dates.

## Usage

``` r
hgnc_get_changes_summary(
  since,
  format = c("json", "markdown", "text"),
  change_type = "all",
  max_results = 100
)
```

## Arguments

- since:

  Character. ISO 8601 date (YYYY-MM-DD) from which to track changes.

- format:

  Character. Output format: "json" (default), "markdown", or "text".

- change_type:

  Character. Type of changes: "all" (default), "symbol", "name",
  "status", or "modified".

- max_results:

  Integer. Maximum number of changes to return (default: 100).

## Value

A list with components:

- uri:

  Resource URI

- mimeType:

  Content MIME type

- content:

  Formatted changes summary

- changes:

  Raw changes data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get changes since 2024-01-01
changes <- hgnc_get_changes_summary("2024-01-01")

# Get symbol changes only as markdown
changes <- hgnc_get_changes_summary("2024-01-01",
  format = "markdown",
  change_type = "symbol"
)
} # }
```
