#!/usr/bin/env Rscript
#
# Test script for HGNC MCP Resources
#
# This script tests the resource helper functions to ensure they work correctly
# before deployment to the MCP server.
#

library(hgnc.mcp)

cat("========================================\n")
cat("HGNC MCP Resources Test Script\n")
cat("========================================\n\n")

# Test 1: Gene Card Resource
cat("Test 1: Get Gene Card for BRCA1\n")
cat("--------------------------------\n")
tryCatch({
  # Test with HGNC ID
  card <- hgnc_get_gene_card("HGNC:1100", format = "json")
  cat("✓ Successfully retrieved BRCA1 gene card (JSON)\n")
  cat(sprintf("  URI: %s\n", card$uri))
  cat(sprintf("  MIME Type: %s\n", card$mimeType))
  cat(sprintf("  Symbol: %s\n", card$gene$symbol))

  # Test with symbol
  card_md <- hgnc_get_gene_card("BRCA1", format = "markdown")
  cat("✓ Successfully retrieved BRCA1 gene card (Markdown)\n")
  cat("  First 200 characters of markdown:\n")
  cat(sprintf("  %s...\n", substr(card_md$content, 1, 200)))

  cat("\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 2: Group Card Resource
cat("Test 2: Get Gene Group Card\n")
cat("----------------------------\n")
tryCatch({
  # Search for a kinase group first
  groups <- hgnc_search_groups("kinase", limit = 1)
  if (groups$numFound > 0) {
    group_id <- groups$groups[[1]]$id
    group_name <- groups$groups[[1]]$name

    cat(sprintf("Testing with group: %s (ID: %s)\n", group_name, group_id))

    # Get group card
    group_card <- hgnc_get_group_card(group_id, format = "json", include_members = FALSE)
    cat("✓ Successfully retrieved group card (JSON, no members)\n")
    cat(sprintf("  URI: %s\n", group_card$uri))
    cat(sprintf("  Group Name: %s\n", group_card$group$name))
    cat(sprintf("  Member Count: %d\n", group_card$group$member_count))

    # Get with members (limit to small group to avoid large output)
    if (group_card$group$member_count <= 20) {
      group_card_full <- hgnc_get_group_card(group_id, format = "markdown", include_members = TRUE)
      cat("✓ Successfully retrieved group card (Markdown, with members)\n")
      cat("  First 300 characters of markdown:\n")
      cat(sprintf("  %s...\n", substr(group_card_full$content, 1, 300)))
    } else {
      cat("  (Skipping full member list test - group too large)\n")
    }
  } else {
    cat("✗ No kinase groups found\n")
  }
  cat("\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 3: Snapshot Metadata Resource
cat("Test 3: Get Snapshot Metadata\n")
cat("------------------------------\n")
tryCatch({
  # Check if cache exists
  cache_info <- get_hgnc_cache_info()

  if (cache_info$exists) {
    meta <- hgnc_get_snapshot_metadata(format = "json")
    cat("✓ Successfully retrieved snapshot metadata (JSON)\n")
    cat(sprintf("  URI: %s\n", meta$uri))
    cat(sprintf("  MIME Type: %s\n", meta$mimeType))

    # Parse JSON to show stats
    content_parsed <- jsonlite::fromJSON(meta$content)
    cat(sprintf("  Total Genes: %s\n",
                format(content_parsed$statistics$total_genes, big.mark = ",")))
    cat(sprintf("  Approved: %s\n",
                format(content_parsed$statistics$approved, big.mark = ",")))
    cat(sprintf("  Download Date: %s\n", content_parsed$download_date))

    # Also test markdown format
    meta_md <- hgnc_get_snapshot_metadata(format = "markdown")
    cat("✓ Successfully retrieved snapshot metadata (Markdown)\n")
    cat("  First 400 characters of markdown:\n")
    cat(sprintf("  %s...\n", substr(meta_md$content, 1, 400)))
  } else {
    cat("✗ No cached data available. Run download_hgnc_data() first.\n")
  }
  cat("\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 4: Changes Summary Resource
cat("Test 4: Get Changes Summary\n")
cat("---------------------------\n")
tryCatch({
  # Get changes since 6 months ago
  six_months_ago <- format(Sys.Date() - 180, "%Y-%m-%d")

  cat(sprintf("Getting changes since: %s\n", six_months_ago))
  changes <- hgnc_get_changes_summary(
    since = six_months_ago,
    format = "json",
    change_type = "all",
    max_results = 10
  )

  cat("✓ Successfully retrieved changes summary (JSON)\n")
  cat(sprintf("  URI: %s\n", changes$uri))
  cat(sprintf("  MIME Type: %s\n", changes$mimeType))

  # Parse JSON to show summary
  content_parsed <- jsonlite::fromJSON(changes$content)
  cat(sprintf("  Total Changes: %d\n", content_parsed$total_changes))
  cat(sprintf("  Showing: %d\n", content_parsed$showing))

  if (content_parsed$total_changes > 0) {
    cat("  Recent changes:\n")
    for (i in 1:min(3, length(content_parsed$changes))) {
      change <- content_parsed$changes[[i]]
      cat(sprintf("    - %s (%s): %s\n",
                  change$symbol, change$hgnc_id, change$change_type))
    }

    # Test markdown format
    changes_md <- hgnc_get_changes_summary(
      since = six_months_ago,
      format = "markdown",
      change_type = "symbol",
      max_results = 5
    )
    cat("✓ Successfully retrieved changes summary (Markdown, symbol changes only)\n")
    cat("  First 300 characters of markdown:\n")
    cat(sprintf("  %s...\n", substr(changes_md$content, 1, 300)))
  } else {
    cat("  (No changes found in the specified period)\n")
  }
  cat("\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 5: Error Handling
cat("Test 5: Error Handling\n")
cat("----------------------\n")
tryCatch({
  # Test with invalid gene
  card <- hgnc_get_gene_card("NOTAREALGENE12345", format = "json")
  cat("✗ Should have thrown an error for invalid gene\n")
}, error = function(e) {
  if (grepl("not found", e$message, ignore.case = TRUE)) {
    cat("✓ Correctly throws error for invalid gene\n")
  } else {
    cat(sprintf("✗ Unexpected error: %s\n", e$message))
  }
})

tryCatch({
  # Test with invalid group
  group_card <- hgnc_get_group_card("NOTAREALGROUP12345", format = "json")
  cat("✗ Should have thrown an error for invalid group\n")
}, error = function(e) {
  if (grepl("not found", e$message, ignore.case = TRUE)) {
    cat("✓ Correctly throws error for invalid group\n")
  } else {
    cat(sprintf("✗ Unexpected error: %s\n", e$message))
  }
})

cat("\n")

# Summary
cat("========================================\n")
cat("Test Summary\n")
cat("========================================\n")
cat("All resource functions have been tested.\n")
cat("Review the output above for any errors.\n")
cat("\n")
cat("Next steps:\n")
cat("1. Fix any errors found above\n")
cat("2. Run the MCP server: start_hgnc_mcp_server()\n")
cat("3. Test endpoints via HTTP or MCP client\n")
cat("\n")
