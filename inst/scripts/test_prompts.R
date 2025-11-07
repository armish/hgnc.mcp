#!/usr/bin/env Rscript

# Test script for HGNC MCP Prompts
#
# This script tests the prompt helper functions that generate workflow
# templates for the MCP server.

library(hgnc.mcp)

cat("========================================\n")
cat("Testing HGNC MCP Prompts\n")
cat("========================================\n\n")

# Test 1: Normalize Gene List Prompt
cat("Test 1: Normalize Gene List Prompt\n")
cat("-----------------------------------\n")

prompt1 <- prompt_normalize_gene_list(
  gene_list = "BRCA1, tp53, EGFR, OLD_SYMBOL",
  strictness = "lenient",
  return_xrefs = TRUE
)

cat("Generated prompt (first 500 chars):\n")
cat(substr(prompt1, 1, 500))
cat("\n...\n\n")

# Verify key sections are present
if (grepl("Gene List Normalization Workflow", prompt1) &&
    grepl("normalize_list", prompt1) &&
    grepl("BRCA1, tp53, EGFR, OLD_SYMBOL", prompt1)) {
  cat("✓ Normalize prompt contains expected content\n\n")
} else {
  cat("✗ Normalize prompt is missing expected content\n\n")
}

# Test 2: Check Nomenclature Compliance Prompt
cat("Test 2: Check Nomenclature Compliance Prompt\n")
cat("---------------------------------------------\n")

prompt2 <- prompt_check_nomenclature_compliance(
  panel_text = "BRCA1, BRCA2, TP53, OLD_SYMBOL",
  file_uri = NULL
)

cat("Generated prompt (first 500 chars):\n")
cat(substr(prompt2, 1, 500))
cat("\n...\n\n")

# Verify key sections are present
if (grepl("Nomenclature Compliance Check", prompt2) &&
    grepl("validate_panel", prompt2) &&
    grepl("BRCA1, BRCA2, TP53, OLD_SYMBOL", prompt2)) {
  cat("✓ Compliance prompt contains expected content\n\n")
} else {
  cat("✗ Compliance prompt is missing expected content\n\n")
}

# Test 3: What Changed Since Prompt
cat("Test 3: What Changed Since Prompt\n")
cat("----------------------------------\n")

prompt3 <- prompt_what_changed_since(since = "2024-01-01")

cat("Generated prompt (first 500 chars):\n")
cat(substr(prompt3, 1, 500))
cat("\n...\n\n")

# Verify key sections are present
if (grepl("HGNC Nomenclature Changes Report", prompt3) &&
    grepl("changes", prompt3) &&
    grepl("2024-01-01", prompt3)) {
  cat("✓ Changes prompt contains expected content\n\n")
} else {
  cat("✗ Changes prompt is missing expected content\n\n")
}

# Test 4: Build Gene Set from Group Prompt
cat("Test 4: Build Gene Set from Group Prompt\n")
cat("-----------------------------------------\n")

prompt4 <- prompt_build_gene_set_from_group(group_query = "kinase")

cat("Generated prompt (first 500 chars):\n")
cat(substr(prompt4, 1, 500))
cat("\n...\n\n")

# Verify key sections are present
if (grepl("Build Gene Set from HGNC Gene Group", prompt4) &&
    grepl("search_groups", prompt4) &&
    grepl("kinase", prompt4)) {
  cat("✓ Gene set prompt contains expected content\n\n")
} else {
  cat("✗ Gene set prompt is missing expected content\n\n")
}

# Test 5: Test with default/empty arguments
cat("Test 5: Prompts with Default/Empty Arguments\n")
cat("---------------------------------------------\n")

prompt5a <- prompt_normalize_gene_list()
prompt5b <- prompt_check_nomenclature_compliance()
prompt5c <- prompt_what_changed_since()
prompt5d <- prompt_build_gene_set_from_group()

if (nchar(prompt5a) > 100 && nchar(prompt5b) > 100 &&
    nchar(prompt5c) > 100 && nchar(prompt5d) > 100) {
  cat("✓ All prompts generate valid output with default arguments\n\n")
} else {
  cat("✗ Some prompts failed with default arguments\n\n")
}

cat("========================================\n")
cat("All Prompt Tests Completed\n")
cat("========================================\n\n")

cat("Summary:\n")
cat("- All 4 prompt functions are callable\n")
cat("- Generated prompts contain expected workflow guidance\n")
cat("- Prompts handle both specified and default arguments\n")
cat("- Ready for MCP server registration\n\n")

cat("Next steps:\n")
cat("1. Start MCP server: start_hgnc_mcp_server()\n")
cat("2. Connect MCP client (e.g., Claude Desktop)\n")
cat("3. Try using prompts through the MCP interface\n")
