# Get Group Card Resource

Retrieve a formatted gene group card with members and metadata.

## Usage

``` r
hgnc_get_group_card(
  group_id_or_name,
  format = c("json", "markdown", "text"),
  include_members = TRUE
)
```

## Arguments

- group_id_or_name:

  Numeric gene group ID or group name/slug.

- format:

  Character. Output format: "json" (default), "markdown", or "text".

- include_members:

  Logical. Whether to include full member gene records (default: TRUE).
  If FALSE, only member count is included.

## Value

A list with components:

- uri:

  Resource URI

- mimeType:

  Content MIME type

- content:

  Formatted group card content

- group:

  Raw group data (if format="json")

## Examples

``` r
if (FALSE) { # \dontrun{
# Get kinase group card
card <- hgnc_get_group_card("kinase")

# Get group as markdown
card <- hgnc_get_group_card(588, format = "markdown")
} # }
```
