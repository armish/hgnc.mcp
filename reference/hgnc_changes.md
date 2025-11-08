# Track Gene Nomenclature Changes

Query genes that have been modified since a specified date. This is
useful for monitoring watchlists, ensuring compliance, and staying
up-to-date with nomenclature changes.

## Usage

``` r
hgnc_changes(
  since,
  fields = c("symbol", "name", "status"),
  change_type = c("all", "symbol", "name", "status", "modified"),
  use_cache = TRUE
)
```

## Arguments

- since:

  Date from which to track changes. Can be a Date object, character
  string (ISO 8601 format: "YYYY-MM-DD"), or POSIXct object.

- fields:

  Character vector of fields to include in the results. Default:
  c("symbol", "name", "status"). Common date fields: date_modified,
  date_symbol_changed, date_name_changed, date_approved_reserved

- change_type:

  Type of changes to track. One of:

  - "all": All changes (default)

  - "symbol": Only symbol changes

  - "name": Only name changes

  - "status": Only status changes

  - "modified": Any modification

- use_cache:

  Whether to use locally cached data (default: TRUE). If FALSE, will
  attempt to use REST API date filtering (may not be supported).

## Value

A list containing:

- `changes`: Data frame of genes modified since the specified date

- `summary`: Summary statistics (total changes, by type, etc.)

- `since`: The date used for filtering (for reference)

- `query_time`: When the query was executed

## Details

This function identifies genes that have been modified since a given
date by examining the HGNC date fields:

- `date_modified`: Last modification date (any field)

- `date_symbol_changed`: When the symbol was last changed

- `date_name_changed`: When the name was last changed

- `date_approved_reserved`: When the gene was approved/reserved

The function uses cached HGNC data for speed and reliability. Date
fields in HGNC data are in ISO 8601 format (YYYY-MM-DD).

## Examples

``` r
if (FALSE) { # \dontrun{
# Find all genes modified in the last 30 days
recent_changes <- hgnc_changes(since = Sys.Date() - 30)
print(recent_changes$summary)

# Find symbol changes since a specific date
symbol_changes <- hgnc_changes(
  since = "2024-01-01",
  change_type = "symbol"
)

# Include more fields and date information
detailed_changes <- hgnc_changes(
  since = "2023-06-01",
  fields = c("symbol", "name", "status", "prev_symbol",
            "date_modified", "date_symbol_changed")
)

# View changes
print(detailed_changes$changes)
} # }
```
