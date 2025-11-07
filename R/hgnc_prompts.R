#' MCP Prompt Helpers for HGNC Workflows
#'
#' These functions generate prompt templates for common HGNC nomenclature
#' workflows. They are designed to be used with plumber2mcp's pr_mcp_prompt()
#' function to provide structured guidance to AI assistants.
#'
#' @name hgnc_prompts
NULL


#' Generate Normalize Gene List Prompt
#'
#' Creates a prompt template that guides an AI assistant through the process
#' of normalizing a gene symbol list to approved HGNC nomenclature.
#'
#' @param gene_list Character vector or comma-separated string of gene symbols
#'   to normalize
#' @param strictness Character. Either "lenient" (default, allows aliases/prev
#'   symbols) or "strict" (approved symbols only)
#' @param return_xrefs Logical. Whether to include cross-references (Entrez,
#'   Ensembl, etc.) in the output (default: FALSE)
#'
#' @return A formatted prompt string guiding the normalization workflow
#'
#' @details
#' This prompt template helps AI assistants understand how to:
#' 1. Parse and clean the input gene list
#' 2. Use normalize_list tool for batch processing
#' 3. Interpret warnings and suggested replacements
#' 4. Optionally fetch cross-references for harmonization
#' 5. Present results in a user-friendly format
#'
#' @examples
#' \dontrun{
#' prompt_normalize_gene_list(
#'   gene_list = "BRCA1, tp53, EGFR, OLD_SYMBOL",
#'   strictness = "lenient",
#'   return_xrefs = TRUE
#' )
#' }
#'
#' @export
prompt_normalize_gene_list <- function(gene_list = "",
                                       strictness = "lenient",
                                       return_xrefs = FALSE) {
  # Convert gene_list to character if needed
  if (is.list(gene_list)) {
    gene_list <- paste(unlist(gene_list), collapse = ", ")
  }

  # Build the prompt with structured guidance
  prompt_text <- sprintf(
    "# Gene List Normalization Workflow

You are helping normalize a gene symbol list to approved HGNC nomenclature.

## Input Gene List
%s

## Workflow Parameters
- Strictness: %s
- Include cross-references: %s

## Recommended Steps

### Step 1: Parse and Clean Input
- Split the gene list by commas, newlines, or whitespace
- Trim whitespace from each symbol
- Remove duplicates (case-insensitive)
- Count: how many unique input symbols?

### Step 2: Batch Normalize
Use the **normalize_list** tool with these parameters:
- symbols: array of cleaned gene symbols
- status: [\"Approved\"] for strict mode, or NULL for lenient
- dedupe: true (to deduplicate by HGNC ID)
- return_fields: at minimum [\"symbol\", \"name\", \"hgnc_id\", \"status\"]

This tool uses local cached HGNC data for fast processing without rate limits.

### Step 3: Interpret Results
The normalize_list response contains:
- **results**: Successfully normalized genes with approved symbols
- **summary**: Counts of input, found, not found, duplicates
- **warnings**: Issues detected (withdrawn symbols, duplicates)
- **not_found**: Symbols that couldn't be resolved

Review the summary and warnings carefully.

### Step 4: Handle Not Found Symbols%s

For symbols in the **not_found** list:
- Try the **resolve_symbol** tool in %s mode for each one
- This checks aliases, previous symbols, and provides suggestions
- Report which symbols have suggested replacements vs. truly unknown

### Step 5%s: Fetch Cross-References%s
For each normalized gene, use the **xrefs** tool to get:
- Entrez Gene ID
- Ensembl Gene ID
- UniProt ID
- OMIM ID
- MANE Select transcript

This is useful for harmonizing across different database identifier systems.

### Step 6: Present Results
Format the output as a clear table with:
- Input symbol (original)
- Approved HGNC symbol (normalized)
- Gene name
- Status (Approved/Withdrawn/etc.)
- HGNC ID%s
- Any warnings or notes

Include a summary:
- Total input symbols: X
- Successfully normalized: Y
- Not found: Z
- Warnings: W (duplicates, withdrawn, etc.)

## Success Criteria
- All input symbols have been processed
- Approved symbols are used (or explained why not)
- Ambiguities and issues are clearly reported
- Results are ready for downstream use (e.g., in analysis pipelines)

## Tips
- HGNC symbols are case-sensitive (usually uppercase)
- Aliases and previous symbols are common in publications
- Withdrawn genes may have suggested replacements
- Duplicate HGNC IDs indicate the same gene under different aliases

Begin by parsing the gene list and proceeding through the workflow systematically.",
    ifelse(nchar(gene_list) > 0, gene_list, "[No gene list provided yet]"),
    strictness,
    ifelse(return_xrefs, "Yes", "No"),
    ifelse(nchar(gene_list) > 0, "", "\n[Skip this step if no symbols were not_found]"),
    strictness,
    ifelse(return_xrefs, "", " (Optional)"),
    ifelse(return_xrefs, "", "\nSince return_xrefs is FALSE, skip fetching cross-references."),
    ifelse(return_xrefs, "\n- External IDs (if requested)", "")
  )

  return(prompt_text)
}


#' Generate Nomenclature Compliance Check Prompt
#'
#' Creates a prompt template for validating a gene panel against HGNC
#' nomenclature policy and suggesting corrections.
#'
#' @param panel_text Character. Gene panel as text (symbols separated by
#'   commas, newlines, or whitespace) or empty string if file-based
#' @param file_uri Character. URI to a file containing the gene panel
#'   (optional, alternative to panel_text)
#'
#' @return A formatted prompt string guiding the compliance check workflow
#'
#' @details
#' This prompt helps AI assistants perform HGNC nomenclature compliance
#' checks by:
#' 1. Parsing the gene panel from text or file
#' 2. Using validate_panel tool to check against HGNC policy
#' 3. Categorizing issues (withdrawn, non-approved, duplicates)
#' 4. Presenting replacement suggestions with rationale
#' 5. Generating a compliance report
#'
#' @examples
#' \dontrun{
#' prompt_check_nomenclature_compliance(
#'   panel_text = "BRCA1, BRCA2, TP53, OLD_SYMBOL"
#' )
#' }
#'
#' @export
prompt_check_nomenclature_compliance <- function(panel_text = "",
                                                 file_uri = NULL) {
  has_text <- nchar(panel_text) > 0
  has_file <- !is.null(file_uri) && nchar(file_uri) > 0

  source_section <- if (has_text && has_file) {
    sprintf("## Input Panel (Text)\n%s\n\n## Alternative File Source\n%s\n\n**Note**: Both text and file provided. Prefer text input unless instructed otherwise.",
            panel_text, file_uri)
  } else if (has_text) {
    sprintf("## Input Panel (Text)\n%s", panel_text)
  } else if (has_file) {
    sprintf("## Input Panel (File)\n%s\n\n**Action Required**: Read the file content first to extract gene symbols.",
            file_uri)
  } else {
    "## Input Panel\n[No panel provided yet - request from user]"
  }

  prompt_text <- sprintf(
    "# Gene Panel Nomenclature Compliance Check

You are performing a quality assurance check on a gene panel to ensure it complies with HGNC nomenclature policy.

%s

## HGNC Compliance Policy
According to HGNC guidelines:
- Gene panels should use **approved HGNC symbols only**
- Withdrawn genes should be replaced with current approved symbols
- Aliases and previous symbols should be updated to approved symbols
- Each gene should appear only once (no duplicates by HGNC ID)

## Recommended Workflow

### Step 1: Parse Gene Panel%s
Extract gene symbols from the %s:
- Split by delimiters (commas, newlines, tabs, etc.)
- Trim whitespace
- Remove empty entries
- Keep track of the original order and format

### Step 2: Run Validation
Use the **validate_panel** tool with parameters:
- items: array of gene symbols from the panel
- policy: \"HGNC\"
- suggest_replacements: true
- include_dates: true

This tool performs comprehensive validation and provides replacement suggestions.

### Step 3: Analyze Validation Results
The validate_panel response contains:
- **valid**: Genes that pass HGNC policy (approved symbols)
- **issues**: Structured list of problems found
  - withdrawn: Genes no longer approved
  - non_approved: Using aliases/previous symbols instead of approved symbols
  - duplicates: Same gene appearing multiple times
  - not_found: Symbols not in HGNC database
- **summary**: Overall compliance statistics
- **report**: Human-readable findings
- **replacements**: Suggested fixes with rationale and dates

### Step 4: Categorize Issues by Severity
**Critical Issues** (must fix):
- Withdrawn genes without clear replacements
- Symbols not found in HGNC

**Important Issues** (should fix):
- Non-approved symbols with known approved alternatives
- Duplicates (same gene, different symbols)

**Informational**:
- Already compliant approved symbols
- Recently updated symbols (check dates)

### Step 5: Present Compliance Report
Generate a clear report with these sections:

**1. Executive Summary**
- Total genes in panel: X
- Compliant (approved): Y (Z%%)
- Issues found: W
  - Withdrawn: ...
  - Non-approved: ...
  - Duplicates: ...
  - Not found: ...

**2. Compliant Genes**
List genes that passed validation (approved symbols)

**3. Issues and Recommended Fixes**
For each problematic gene:
- Original symbol: [symbol]
- Issue: [withdrawn/non-approved/duplicate/not found]
- Recommended action: Replace with [approved_symbol]
- Rationale: [why this replacement]
- Change date: [when it changed, if applicable]

**4. Updated Panel**
Provide the corrected gene panel with all issues resolved:
- Use approved symbols only
- Remove duplicates
- Document any symbols that couldn't be resolved

**5. Action Items**
Clear checklist of what needs to be done to achieve compliance

## Success Criteria
- All genes validated against HGNC database
- Issues categorized by severity
- Replacement suggestions provided with rationale
- Compliance report is clear and actionable
- Updated panel ready for use

## Tips
- Some withdrawn genes have direct replacements (check prev_symbol mapping)
- Others may be merged, split, or discontinued (explain in rationale)
- Dates help understand when changes occurred (useful for versioning)
- Duplicate HGNC IDs mean the panel has the same gene twice (consolidate)

Begin by parsing the gene panel and running the validation tool.",
    source_section,
    ifelse(has_file, " from File", ""),
    ifelse(has_file, "file", "input text")
  )

  return(prompt_text)
}


#' Generate What Changed Since Prompt
#'
#' Creates a prompt template for generating a human-readable summary of
#' HGNC nomenclature changes since a specific date.
#'
#' @param since Character. ISO 8601 date (YYYY-MM-DD) from which to track
#'   changes. If not provided, uses 30 days ago as default.
#'
#' @return A formatted prompt string guiding the change tracking workflow
#'
#' @details
#' This prompt helps AI assistants create governance-friendly change reports by:
#' 1. Querying HGNC changes since the specified date
#' 2. Categorizing changes by type (symbol, name, status)
#' 3. Highlighting significant changes (withdrawals, renames)
#' 4. Presenting in a format suitable for compliance and watchlist tracking
#'
#' @examples
#' \dontrun{
#' prompt_what_changed_since(since = "2024-01-01")
#' }
#'
#' @export
prompt_what_changed_since <- function(since = NULL) {
  # Default to 30 days ago if not specified
  if (is.null(since) || nchar(since) == 0) {
    since_date <- Sys.Date() - 30
    since <- format(since_date, "%Y-%m-%d")
    date_note <- sprintf("%s (default: 30 days ago)", since)
  } else {
    date_note <- since
  }

  prompt_text <- sprintf(
    "# HGNC Nomenclature Changes Report

You are generating a human-readable summary of HGNC gene nomenclature changes for governance and compliance tracking.

## Time Period
Changes since: **%s**

## Workflow

### Step 1: Query All Changes
Use the **changes** tool to get all modifications:
- since: \"%s\"
- change_type: \"all\"
- fields: [\"symbol\", \"name\", \"status\", \"hgnc_id\", \"locus_type\", \"location\"]
- use_cache: true

This returns genes with any of these date fields >= since date:
- date_symbol_changed
- date_name_changed
- date_modified

### Step 2: Categorize Changes by Type
Organize changes into meaningful categories:

**Symbol Changes** (most critical for watchlists):
- Genes where the approved symbol changed
- Include: old symbol → new symbol (if available via prev_symbol)
- Impact: Code/databases using old symbol may break

**Status Changes** (affects usability):
- Genes that changed status (e.g., Approved → Withdrawn)
- Withdrawals are critical (gene may be obsolete, merged, or split)
- New approvals indicate newly characterized genes

**Name Changes** (informational):
- Changes to the full gene name/description
- Usually for clarity or updated function understanding
- Lower impact than symbol changes

**General Modifications**:
- Other updates (locus type, location, cross-references)
- Captured by date_modified but not specific change type

### Step 3: Identify High-Impact Changes
Highlight changes that require immediate attention:

**Critical**:
- Status changed to \"Withdrawn\" (gene no longer valid)
- Symbol changed (aliases should be updated)

**Important**:
- New genes approved (may be relevant for panels)
- Locus type or location changes (affects interpretation)

**Informational**:
- Name clarifications
- Cross-reference updates

### Step 4: Generate Human-Readable Report

**Executive Summary**
- Time period: [since] to [today]
- Total genes changed: X
- Breakdown:
  - Symbol changes: Y
  - Status changes: Z
  - Name changes: W
  - Other modifications: V

**Symbol Changes (Critical)**
List each symbol change as:
- HGNC:##### - [OLD_SYMBOL] → [NEW_SYMBOL] - [gene name]
- Changed on: [date]
- Action required: Update references from OLD_SYMBOL to NEW_SYMBOL

**Status Changes (Important)**
For each status change:
- HGNC:##### - [symbol] - Status: [old] → [new]
- Changed on: [date]
- Action: [explain implications, e.g., \"Remove from active panels\"]

**Name Changes (Informational)**
- HGNC:##### - [symbol] - Name updated
- Old: [old_name]
- New: [new_name]
- Changed on: [date]

**Other Modifications**
Summarize other changes without overwhelming detail.

### Step 5: Provide Actionable Recommendations

Based on the changes, suggest actions:
- \"Update gene panels to use new symbols: [list]\"
- \"Remove withdrawn genes from analyses: [list]\"
- \"Review impact on existing datasets using old symbols\"
- \"No critical changes - informational updates only\"

## Success Criteria
- All relevant changes since the date are captured
- Changes are categorized by type and impact
- Critical changes are highlighted and explained
- Report is suitable for governance review
- Actionable next steps are provided

## Tips
- Focus on symbol and status changes - these affect downstream use
- Include HGNC IDs for unambiguous tracking
- Dates help with versioning and audit trails
- Empty result is valid (\"No changes in this period\")
- Very large result sets may need pagination or filtering

Generate the report by querying changes and organizing them clearly for human consumption.",
    date_note,
    since
  )

  return(prompt_text)
}


#' Generate Build Gene Set from Group Prompt
#'
#' Creates a prompt template for discovering an HGNC gene group and building
#' a reusable gene set definition from its members.
#'
#' @param group_query Character. Search query for finding gene groups
#'   (e.g., "kinase", "zinc finger", "immunoglobulin")
#'
#' @return A formatted prompt string guiding the gene set building workflow
#'
#' @details
#' This prompt helps AI assistants:
#' 1. Search for relevant HGNC gene groups by keyword
#' 2. Select the most appropriate group
#' 3. Retrieve all member genes
#' 4. Build a structured gene set definition
#' 5. Provide metadata for reproducibility
#'
#' @examples
#' \dontrun{
#' prompt_build_gene_set_from_group(group_query = "protein kinase")
#' }
#'
#' @export
prompt_build_gene_set_from_group <- function(group_query = "") {
  prompt_text <- sprintf(
    "# Build Gene Set from HGNC Gene Group

You are helping build a reusable gene set definition by discovering and extracting members from an HGNC gene group or family.

## Search Query
%s

## Workflow

### Step 1: Search for Gene Groups
Use the **search_groups** tool to find relevant groups:
- query: \"%s\"
- limit: 20

This searches HGNC gene group names and descriptions for your keyword.

### Step 2: Review and Select Group
The search_groups response contains:
- **numFound**: Total matching groups
- **groups**: Array of group records with:
  - gene_group_id: Numeric identifier
  - gene_group: Group name
  - gene_group_description: What this group represents

Review the results and identify the most relevant group for your use case.

**Selection Criteria**:
- Group name matches your intent
- Description confirms it includes the genes you want
- If multiple matches, may need to process several groups or ask user

### Step 3: Get Group Members
Once you've selected a group, use **group_members** tool:
- group_id_or_name: [selected gene_group_id or gene_group name]
- use_cache: true

This returns all genes belonging to that group.

### Step 4: Extract Member Information
The group_members response contains:
- **numFound**: Number of genes in the group
- **docs**: Array of gene records with full HGNC data

For each member, extract:
- hgnc_id: Unique identifier
- symbol: Approved gene symbol
- name: Full gene name
- status: Usually \"Approved\"
- locus_type: Gene type (e.g., \"protein-coding\")
- location: Chromosomal location
- Cross-references (optional): entrez_id, ensembl_gene_id, etc.

### Step 5: Build Gene Set Definition
Create a structured, reusable gene set with:

**1. Metadata**
- Gene set name: [descriptive name based on group]
- Source: HGNC Gene Group
- Group ID: [gene_group_id]
- Group name: [gene_group]
- Description: [gene_group_description]
- Date created: [today's date]
- Number of genes: [count]

**2. Gene List**
Provide the gene set in multiple formats for flexibility:

**Format A: Simple symbol list** (for quick use)
```
BRCA1
BRCA2
TP53
...
```

**Format B: Tab-separated table** (for data processing)
```
hgnc_id\\tsymbol\\tname\\tstatus\\tlocation
HGNC:1100\\tBRCA1\\tBRCA1 DNA repair associated\\tApproved\\t17q21.31
HGNC:1101\\tBRCA2\\tBRCA2 DNA repair associated\\tApproved\\t13q13.1
...
```

**Format C: Structured JSON** (for programmatic use)
```json
{
  \"gene_set_name\": \"...\",
  \"source\": \"HGNC Gene Group\",
  \"group_id\": 123,
  \"created\": \"2024-01-15\",
  \"genes\": [
    {\"hgnc_id\": \"HGNC:1100\", \"symbol\": \"BRCA1\", \"name\": \"...\"},
    ...
  ]
}
```

### Step 6: Provide Usage Guidance
Explain how to use this gene set:
- \"Use symbol list for manual curation\"
- \"Import TSV table into R/Python for analysis\"
- \"Store JSON for pipeline configuration\"
- \"Validate against this list using validate_panel tool\"

**Reproducibility Note**: Include instructions for regenerating:
```
To regenerate this gene set:
1. Use search_groups with query: \"%s\"
2. Select group: [gene_group_id or name]
3. Use group_members to get current members
Note: Group membership may change over time as new genes are added.
```

## Success Criteria
- Relevant gene group found and confirmed
- All member genes extracted
- Gene set provided in multiple formats
- Metadata included for provenance
- Reproducibility instructions provided

## Tips
- Gene group descriptions help confirm you found the right group
- Groups can be large (100s of genes) or small (a few genes)
- Group membership is authoritative (curated by HGNC)
- Same gene can belong to multiple groups (e.g., \"Kinases\" and \"Cancer genes\")
- If query is too broad, you may get many groups (refine search)
- If query is too narrow, you may get zero groups (try synonyms/broader terms)

%s

Begin by searching for gene groups matching the query.",
    ifelse(nchar(group_query) > 0,
           sprintf("\"%s\"", group_query),
           "[No query provided yet - request from user]"),
    group_query,
    group_query,
    ifelse(nchar(group_query) > 0,
           "",
           "\n**Note**: No query provided. Start by asking the user what type of gene group they're interested in (e.g., \"kinases\", \"transcription factors\", \"immunoglobulins\").")
  )

  return(prompt_text)
}
