# Get Snapshot Metadata Resource

Retrieve metadata about the currently cached HGNC dataset. Includes
information about the snapshot version, date, source URL, and basic
statistics.

## Usage

``` r
hgnc_get_snapshot_metadata(format = c("json", "markdown", "text"))
```

## Arguments

- format:

  Character. Output format: "json" (default), "markdown", or "text".

## Value

A list with components:

- uri:

  Resource URI

- mimeType:

  Content MIME type

- content:

  Formatted snapshot metadata

## Examples

``` r
if (FALSE) { # \dontrun{
# Get snapshot metadata
meta <- hgnc_get_snapshot_metadata()

# Get as markdown
meta <- hgnc_get_snapshot_metadata(format = "markdown")
} # }
```
