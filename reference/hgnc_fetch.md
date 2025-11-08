# Fetch Gene Records by Field Value

Retrieve complete gene records from HGNC by searching a specific field.
This is the most direct way to get gene information when you have a
known identifier.

## Usage

``` r
hgnc_fetch(field, term)
```

## Arguments

- field:

  The field to search. Common fields include:

  - `hgnc_id`: HGNC identifier (e.g., "HGNC:5")

  - `symbol`: Official gene symbol (e.g., "BRCA1")

  - `entrez_id`: NCBI Gene ID (e.g., "672")

  - `ensembl_gene_id`: Ensembl gene ID (e.g., "ENSG00000012048")

  - `uniprot_ids`: UniProt accession

  - `refseq_accession`: RefSeq accession

- term:

  The value to search for in the specified field

## Value

A list containing:

- `numFound`: Number of matching records (usually 1 for exact matches)

- `docs`: List of complete gene records with all stored fields

- `field`: The field that was searched

- `term`: The search term

## Details

This function is the primary method for retrieving complete gene
information when you have a specific identifier. Each gene record (doc)
contains all available HGNC fields including:

- Core identifiers: hgnc_id, symbol, name, status

- Location: location, chromosome

- Aliases: alias_symbol, prev_symbol

- Cross-references: entrez_id, ensembl_gene_id, uniprot_ids, omim_id,
  etc.

- Groups: gene_group, gene_group_id

- Dates: date_modified, date_symbol_changed, etc.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch by HGNC ID
gene <- hgnc_fetch("hgnc_id", "HGNC:5")

# Fetch by symbol
gene <- hgnc_fetch("symbol", "BRCA1")

# Fetch by Entrez ID
gene <- hgnc_fetch("entrez_id", "672")

# Access gene data
if (gene$numFound > 0) {
  record <- gene$docs[[1]]
  cat("Symbol:", record$symbol, "\n")
  cat("Name:", record$name, "\n")
  cat("Location:", record$location, "\n")
}
} # }
```
