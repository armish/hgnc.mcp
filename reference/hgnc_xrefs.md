# Extract Cross-References from Gene Record

Extract external database cross-references from an HGNC gene record.
Useful for harmonizing datasets across different identifier systems.

## Usage

``` r
hgnc_xrefs(id_or_symbol)
```

## Arguments

- id_or_symbol:

  Either an HGNC ID (e.g., "HGNC:5") or gene symbol (e.g., "BRCA1")

## Value

A list containing cross-reference identifiers:

- `hgnc_id`: HGNC identifier

- `symbol`: Official gene symbol

- `entrez_id`: NCBI Gene ID

- `ensembl_gene_id`: Ensembl gene ID

- `uniprot_ids`: UniProt accessions

- `omim_id`: OMIM identifiers

- `ccds_id`: CCDS identifiers

- `refseq_accession`: RefSeq accessions

- `mane_select`: MANE Select transcript

- `agr`: Alliance of Genome Resources ID

- `ucsc_id`: UCSC identifier

- `vega_id`: Vega identifier

- `ena`: ENA accessions

- `status`: Gene status (to help identify withdrawn genes)

## Details

This function retrieves the gene record and extracts all common
cross-reference identifiers. Missing identifiers are returned as NA.

The function automatically detects whether the input is an HGNC ID
(starts with "HGNC:") or a symbol, and queries accordingly.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get cross-references by symbol
xrefs <- hgnc_xrefs("BRCA1")
print(xrefs$entrez_id)
print(xrefs$ensembl_gene_id)

# Get cross-references by HGNC ID
xrefs <- hgnc_xrefs("HGNC:1100")

# Use for dataset harmonization
# Map your Entrez IDs to Ensembl
my_genes <- c("BRCA1", "TP53", "EGFR")
xref_table <- lapply(my_genes, hgnc_xrefs)
} # }
```
