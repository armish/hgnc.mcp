# Validate Gene Panel Against HGNC Policy

Perform quality assurance on gene lists against HGNC nomenclature
policy. This function checks for non-approved symbols, withdrawn genes,
duplicates, and provides replacement suggestions with rationale.

## Usage

``` r
hgnc_validate_panel(
  items,
  policy = "HGNC",
  suggest_replacements = TRUE,
  include_dates = TRUE,
  index = NULL
)
```

## Arguments

- items:

  Character vector of gene symbols/identifiers to validate

- policy:

  Validation policy to apply. Currently only "HGNC" is supported, which
  enforces:

  - Only approved symbols

  - No withdrawn genes

  - No duplicate entries

  - Proper nomenclature format

- suggest_replacements:

  Logical, whether to suggest replacements for problematic symbols using
  prev_symbol and alias_symbol mappings (default: TRUE)

- include_dates:

  Logical, whether to include date information for changes (default:
  TRUE)

- index:

  Optional pre-built symbol index from
  [`build_symbol_index()`](https://armish.github.io/hgnc.mcp/reference/build_symbol_index.md).
  If NULL, will build index from cached data.

## Value

A list containing:

- `valid`: Data frame of genes that passed all validation checks

- `issues`: Data frame of genes with validation issues

- `summary`: Summary of validation results

- `report`: Character vector with human-readable validation report

- `replacements`: Suggested replacements for problematic entries (if
  enabled)

## Details

The validation process checks for:

**1. Non-Approved Symbols**

- Symbols that don't match current approved HGNC symbols

- May be aliases, previous symbols, or invalid entries

**2. Withdrawn Genes**

- Genes with status = "Withdrawn"

- No longer valid identifiers

- Replacements suggested where possible

**3. Duplicates**

- Multiple entries that map to the same HGNC ID

- Can occur with mixed use of symbols and aliases

**4. Not Found**

- Symbols that don't exist in HGNC database

- May be typos, non-human genes, or outdated identifiers

**Replacement Strategy**:

- For previous symbols: suggests current approved symbol with change
  date

- For aliases: suggests official symbol

- For withdrawn genes: attempts to find merged/replaced gene

- Includes rationale and dates where available

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic validation
gene_panel <- c("BRCA1", "TP53", "EGFR", "KRAS", "MYC")
validation <- hgnc_validate_panel(gene_panel)

# View summary
print(validation$summary)

# View readable report
cat(validation$report, sep = "\n")

# Check for issues
if (nrow(validation$issues) > 0) {
  print(validation$issues)
}

# Get suggested replacements
if (length(validation$replacements) > 0) {
  print(validation$replacements)
}

# Validate with mixed quality input
messy_panel <- c(
  "BRCA1",         # Valid
  "brca1",         # Valid (case insensitive)
  "BRCA1",         # Duplicate
  "OLDNAME",       # Previous symbol
  "WITHDRAWN",     # Withdrawn gene
  "NOTREAL"        # Invalid
)
validation <- hgnc_validate_panel(messy_panel)
cat(validation$report, sep = "\n")
} # }
```
