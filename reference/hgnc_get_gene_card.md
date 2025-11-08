# Get Gene Card Resource

Retrieve a formatted gene card with essential information for LLM
context. Returns a structured view of gene information including symbol,
name, location, status, aliases, cross-references, and group
memberships.

## Usage

``` r
hgnc_get_gene_card(hgnc_id, format = c("json", "markdown", "text"))
```

## Arguments

- hgnc_id:

  Character or numeric. HGNC ID (with or without "HGNC:" prefix) or gene
  symbol to look up.

- format:

  Character. Output format: "json" (structured data, default),
  "markdown" (human-readable), or "text" (plain text summary).

## Value

A list with components:

- uri:

  Resource URI

- mimeType:

  Content MIME type

- content:

  Formatted gene card content

- gene:

  Raw gene data (if format="json")

## Examples

``` r
if (FALSE) { # \dontrun{
# Get BRCA1 gene card as JSON
card <- hgnc_get_gene_card("HGNC:1100")

# Get gene card as markdown for display
card <- hgnc_get_gene_card("BRCA1", format = "markdown")
} # }
```
