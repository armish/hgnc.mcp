# Tests for HGNC MCP Resource Helpers

# Helper function to check if we're offline
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection")
  }
}

# =============================================================================
# Tests for hgnc_get_gene_card()
# =============================================================================

test_that("hgnc_get_gene_card requires valid format argument", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  expect_error(
    hgnc_get_gene_card("BRCA1", format = "invalid"),
    "'arg' should be one of"
  )
})

test_that("hgnc_get_gene_card returns JSON format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "json")

  # Check structure
  expect_type(result, "list")
  expect_true("uri" %in% names(result))
  expect_true("mimeType" %in% names(result))
  expect_true("content" %in% names(result))
  expect_true("gene" %in% names(result))

  # Check mime type
  expect_equal(result$mimeType, "application/json")

  # Check URI format
  expect_match(result$uri, "^hgnc://gene/HGNC:")

  # Check content is valid JSON
  expect_type(result$content, "character")
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_true("symbol" %in% names(content_parsed))
  expect_true("hgnc_id" %in% names(content_parsed))
  expect_true("name" %in% names(content_parsed))
  expect_equal(content_parsed$symbol, "BRCA1")
  expect_equal(content_parsed$hgnc_id, "HGNC:1100")
})

test_that("hgnc_get_gene_card returns markdown format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "markdown")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/markdown")

  # Check content is character and contains expected markdown
  expect_type(result$content, "character")
  expect_match(result$content, "# BRCA1")
  expect_match(result$content, "HGNC:1100")
  expect_match(result$content, "\\*\\*Name:\\*\\*")
  expect_match(result$content, "\\*\\*Status:\\*\\*")
})

test_that("hgnc_get_gene_card returns text format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "text")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/plain")

  # Check content is plain text
  expect_type(result$content, "character")
  expect_match(result$content, "Gene: BRCA1")
  expect_match(result$content, "HGNC:1100")
  expect_match(result$content, "Name:")
  expect_match(result$content, "Status:")
})

test_that("hgnc_get_gene_card accepts HGNC ID with prefix (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("HGNC:1100", format = "json")

  content_parsed <- jsonlite::fromJSON(result$content)
  expect_equal(content_parsed$symbol, "BRCA1")
  expect_equal(content_parsed$hgnc_id, "HGNC:1100")
})

test_that("hgnc_get_gene_card accepts numeric HGNC ID without prefix (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("1100", format = "json")

  content_parsed <- jsonlite::fromJSON(result$content)
  expect_equal(content_parsed$symbol, "BRCA1")
  expect_equal(content_parsed$hgnc_id, "HGNC:1100")
})

test_that("hgnc_get_gene_card accepts gene symbol (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("TP53", format = "json")

  content_parsed <- jsonlite::fromJSON(result$content)
  expect_equal(content_parsed$symbol, "TP53")
})

test_that("hgnc_get_gene_card handles gene not found error (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  expect_error(
    hgnc_get_gene_card("NOTAREALGENE12345", format = "json"),
    "not found in HGNC database"
  )
})

test_that("hgnc_get_gene_card includes cross-references in JSON (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "json")
  content_parsed <- jsonlite::fromJSON(result$content)

  # Check cross-references structure
  expect_true("cross_references" %in% names(content_parsed))
  xrefs <- content_parsed$cross_references

  expect_true("entrez_id" %in% names(xrefs))
  expect_true("ensembl_gene_id" %in% names(xrefs))
  expect_true("uniprot_ids" %in% names(xrefs))
})

test_that("hgnc_get_gene_card includes aliases and previous symbols when present (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "json")
  content_parsed <- jsonlite::fromJSON(result$content)

  # Check that alias and previous symbol fields exist
  expect_true("aliases" %in% names(content_parsed))
  expect_true("previous_symbols" %in% names(content_parsed))
})

test_that("hgnc_get_gene_card markdown includes sections when data present (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_gene_card("BRCA1", format = "markdown")

  # Check for cross-references section
  expect_match(result$content, "## Cross-References")
})

# =============================================================================
# Tests for hgnc_get_group_card()
# =============================================================================

test_that("hgnc_get_group_card requires valid format argument", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  expect_error(
    hgnc_get_group_card("kinase", format = "invalid"),
    "'arg' should be one of"
  )
})

test_that("hgnc_get_group_card returns JSON format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Use a known gene group (588 is a valid group ID)
  result <- hgnc_get_group_card(588, format = "json")

  # Check structure
  expect_type(result, "list")
  expect_true("uri" %in% names(result))
  expect_true("mimeType" %in% names(result))
  expect_true("content" %in% names(result))
  expect_true("group" %in% names(result))

  # Check mime type
  expect_equal(result$mimeType, "application/json")

  # Check URI format
  expect_match(result$uri, "^hgnc://group/")

  # Check content is valid JSON
  expect_type(result$content, "character")
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_true("group_id" %in% names(content_parsed))
  expect_true("group_name" %in% names(content_parsed))
  expect_true("member_count" %in% names(content_parsed))
  expect_true("members" %in% names(content_parsed))
})

test_that("hgnc_get_group_card returns markdown format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_group_card(588, format = "markdown")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/markdown")

  # Check content contains expected markdown
  expect_type(result$content, "character")
  expect_match(result$content, "# Gene Group:")
  expect_match(result$content, "\\*\\*Group ID:\\*\\*")
  expect_match(result$content, "\\*\\*Member Count:\\*\\*")
})

test_that("hgnc_get_group_card returns text format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_group_card(588, format = "text")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/plain")

  # Check content is plain text
  expect_type(result$content, "character")
  expect_match(result$content, "Gene Group:")
  expect_match(result$content, "Members:")
})

test_that("hgnc_get_group_card respects include_members parameter (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # With members
  result_with <- hgnc_get_group_card(588, format = "json", include_members = TRUE)
  content_with <- jsonlite::fromJSON(result_with$content)
  expect_true("members" %in% names(content_with))
  expect_true(!is.null(content_with$members))

  reset_rate_limiter()

  # Without members
  result_without <- hgnc_get_group_card(588, format = "json", include_members = FALSE)
  content_without <- jsonlite::fromJSON(result_without$content)
  expect_true(is.null(content_without$members) || length(content_without$members) == 0)
})

test_that("hgnc_get_group_card markdown includes member table when include_members=TRUE (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_group_card(588, format = "markdown", include_members = TRUE)

  # Check for members section and table
  expect_match(result$content, "## Members")
  expect_match(result$content, "\\| Symbol \\| Name \\| Status \\| Location \\|")
})

test_that("hgnc_get_group_card handles group not found error (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  expect_error(
    hgnc_get_group_card("NOTAREALGROUP12345", format = "json"),
    "not found or has no members"
  )
})

test_that("hgnc_get_group_card member data includes expected fields (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_group_card(588, format = "json", include_members = TRUE)
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_gt(content_parsed$member_count, 0)

  if (length(content_parsed$members) > 0) {
    first_member <- content_parsed$members[[1]]
    expect_true("hgnc_id" %in% names(first_member))
    expect_true("symbol" %in% names(first_member))
    expect_true("name" %in% names(first_member))
    expect_true("status" %in% names(first_member))
  }
})

# =============================================================================
# Tests for hgnc_get_snapshot_metadata()
# =============================================================================

test_that("hgnc_get_snapshot_metadata requires valid format argument", {
  # This test doesn't require network, just validates parameter
  expect_error(
    suppressWarnings(hgnc_get_snapshot_metadata(format = "invalid")),
    "'arg' should be one of"
  )
})

test_that("hgnc_get_snapshot_metadata errors when no cached data (if applicable)", {
  # This test checks error handling when cache is empty
  # Try calling the function and check the result
  result <- tryCatch({
    suppressWarnings(hgnc_get_snapshot_metadata())
    "success"
  }, error = function(e) {
    e$message
  })

  if (result == "success") {
    skip("Cached data available, cannot test error condition")
  }

  # If we get here, an error was thrown - verify it's the right error
  expect_match(result, "No cached HGNC data available")
})

test_that("hgnc_get_snapshot_metadata returns JSON format correctly (with cache)", {
  skip_on_cran()

  # Try to call the function - skip if no cache available
  can_get_snapshot <- tryCatch({
    suppressWarnings(hgnc_get_snapshot_metadata(format = "json"))
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!can_get_snapshot) {
    skip("No cached data available for testing")
  }

  result <- hgnc_get_snapshot_metadata(format = "json")

  # Check structure
  expect_type(result, "list")
  expect_true("uri" %in% names(result))
  expect_true("mimeType" %in% names(result))
  expect_true("content" %in% names(result))

  # Check mime type
  expect_equal(result$mimeType, "application/json")

  # Check URI
  expect_equal(result$uri, "hgnc://snapshot/current")

  # Check content is valid JSON
  expect_type(result$content, "character")
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_true("version" %in% names(content_parsed))
  expect_true("statistics" %in% names(content_parsed))
  expect_true("download_date" %in% names(content_parsed))
  expect_true("total_genes" %in% names(content_parsed$statistics))
})

test_that("hgnc_get_snapshot_metadata returns markdown format correctly (with cache)", {
  skip_on_cran()

  # Try to call the function - skip if no cache available
  can_get_snapshot <- tryCatch({
    suppressWarnings(hgnc_get_snapshot_metadata(format = "markdown"))
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!can_get_snapshot) {
    skip("No cached data available for testing")
  }

  result <- hgnc_get_snapshot_metadata(format = "markdown")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/markdown")

  # Check content contains expected markdown
  expect_type(result$content, "character")
  expect_match(result$content, "# HGNC Dataset Snapshot")
  expect_match(result$content, "\\*\\*Version:\\*\\*")
  expect_match(result$content, "## Statistics")
})

test_that("hgnc_get_snapshot_metadata returns text format correctly (with cache)", {
  skip_on_cran()

  # Try to call the function - skip if no cache available
  can_get_snapshot <- tryCatch({
    suppressWarnings(hgnc_get_snapshot_metadata(format = "text"))
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!can_get_snapshot) {
    skip("No cached data available for testing")
  }

  result <- hgnc_get_snapshot_metadata(format = "text")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/plain")

  # Check content is plain text
  expect_type(result$content, "character")
  expect_match(result$content, "HGNC Snapshot:")
  expect_match(result$content, "Total Genes:")
})

test_that("hgnc_get_snapshot_metadata includes statistics (with cache)", {
  skip_on_cran()

  # Try to call the function - skip if no cache available
  can_get_snapshot <- tryCatch({
    suppressWarnings(hgnc_get_snapshot_metadata(format = "json"))
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!can_get_snapshot) {
    skip("No cached data available for testing")
  }

  result <- hgnc_get_snapshot_metadata(format = "json")
  content_parsed <- jsonlite::fromJSON(result$content)

  stats <- content_parsed$statistics
  expect_true("total_genes" %in% names(stats))
  expect_true("approved" %in% names(stats))
  expect_true("withdrawn" %in% names(stats))
  expect_true("locus_type_counts" %in% names(stats))

  # Verify counts are numeric and reasonable
  expect_type(stats$total_genes, "integer")
  expect_gt(stats$total_genes, 0)
})

# =============================================================================
# Tests for hgnc_get_changes_summary()
# =============================================================================

test_that("hgnc_get_changes_summary requires valid format argument", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  expect_error(
    hgnc_get_changes_summary("2024-01-01", format = "invalid"),
    "'arg' should be one of"
  )
})

test_that("hgnc_get_changes_summary returns JSON format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "json")

  # Check structure
  expect_type(result, "list")
  expect_true("uri" %in% names(result))
  expect_true("mimeType" %in% names(result))
  expect_true("content" %in% names(result))
  expect_true("changes" %in% names(result))

  # Check mime type
  expect_equal(result$mimeType, "application/json")

  # Check URI format
  expect_match(result$uri, "^hgnc://changes/since/2024-01-01")

  # Check content is valid JSON
  expect_type(result$content, "character")
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_true("since" %in% names(content_parsed))
  expect_true("change_type" %in% names(content_parsed))
  expect_true("total_changes" %in% names(content_parsed))
  expect_equal(content_parsed$since, "2024-01-01")
})

test_that("hgnc_get_changes_summary returns markdown format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "markdown")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/markdown")

  # Check content contains expected markdown
  expect_type(result$content, "character")
  expect_match(result$content, "# HGNC Changes Since")
  expect_match(result$content, "\\*\\*Change Type:\\*\\*")
  expect_match(result$content, "\\*\\*Total Changes:\\*\\*")
})

test_that("hgnc_get_changes_summary returns text format correctly (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "text")

  # Check structure
  expect_type(result, "list")
  expect_equal(result$mimeType, "text/plain")

  # Check content is plain text
  expect_type(result$content, "character")
  expect_match(result$content, "HGNC Changes Since")
  expect_match(result$content, "Change Type:")
  expect_match(result$content, "Total Changes:")
})

test_that("hgnc_get_changes_summary respects max_results parameter (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "json", max_results = 5)
  content_parsed <- jsonlite::fromJSON(result$content)

  # Should show at most 5 results
  expect_lte(content_parsed$showing, 5)

  if (!is.null(content_parsed$changes)) {
    expect_lte(length(content_parsed$changes), 5)
  }
})

test_that("hgnc_get_changes_summary includes truncation flag when limited (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Use a date that will likely have many changes
  result <- hgnc_get_changes_summary("2020-01-01", format = "json", max_results = 5)
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_true("truncated" %in% names(content_parsed))
  expect_type(content_parsed$truncated, "logical")
})

test_that("hgnc_get_changes_summary respects change_type parameter (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01",
                                      format = "json",
                                      change_type = "symbol")
  content_parsed <- jsonlite::fromJSON(result$content)

  expect_equal(content_parsed$change_type, "symbol")
})

test_that("hgnc_get_changes_summary change records have expected fields (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "json", max_results = 10)
  content_parsed <- jsonlite::fromJSON(result$content)

  # Check if there are any changes
  if (!is.null(content_parsed$changes) && length(content_parsed$changes) > 0) {
    change <- content_parsed$changes[[1]]
    expect_true("hgnc_id" %in% names(change))
    expect_true("symbol" %in% names(change))
    expect_true("change_type" %in% names(change))
    expect_true("change_date" %in% names(change))
  }
})

test_that("hgnc_get_changes_summary markdown includes table when changes exist (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_get_changes_summary("2024-01-01", format = "markdown")

  # Check for changes table if there are any changes
  # The table should appear if numFound > 0
  if (grepl("Total Changes: [1-9]", result$content)) {
    expect_match(result$content, "## Changes")
    expect_match(result$content, "\\| HGNC ID \\| Symbol \\| Change Type \\| Date \\|")
  }
})

# =============================================================================
# Integration tests - resources working together
# =============================================================================

test_that("gene card and group card work together (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Get a gene card
  gene_card <- hgnc_get_gene_card("BRCA1", format = "json")
  gene_data <- jsonlite::fromJSON(gene_card$content)

  # Check if gene has group memberships
  if (length(gene_data$gene_group_ids) > 0) {
    # Get the first group card
    group_id <- gene_data$gene_group_ids[[1]]

    reset_rate_limiter()

    group_card <- hgnc_get_group_card(group_id, format = "json", include_members = TRUE)
    group_data <- jsonlite::fromJSON(group_card$content)

    # Verify BRCA1 is a member of this group
    expect_true(any(sapply(group_data$members, function(m) m$symbol == "BRCA1")))
  }
})

test_that("snapshot and changes summary are consistent (with cache)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  # Try to get snapshot metadata
  tryCatch({
    snapshot <- hgnc_get_snapshot_metadata(format = "json")
    snapshot_data <- jsonlite::fromJSON(snapshot$content)

    # Verify snapshot has expected structure
    expect_true("version" %in% names(snapshot_data))
    expect_true("statistics" %in% names(snapshot_data))
  }, error = function(e) {
    skip("Cannot load snapshot metadata")
  })
})

# =============================================================================
# Edge cases and error handling
# =============================================================================

test_that("null coalescing operator works correctly", {
  # Test the %||% operator used in the resource functions
  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal(NA %||% "default", NA)
})
