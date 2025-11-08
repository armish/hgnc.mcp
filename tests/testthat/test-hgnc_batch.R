# Tests for HGNC Batch Operations
#
# This test suite covers:
# - build_symbol_index(): Create in-memory lookup tables from cached data
# - hgnc_normalize_list(): Batch symbol normalization and validation
# - Symbol resolution via exact matches, aliases, and previous symbols
# - Duplicate detection and handling
# - Status filtering (Approved, Withdrawn)
#
# Tests use both real cached data and mock data for specific scenarios.

# =============================================================================
# Tests for build_symbol_index()
# =============================================================================

test_that("build_symbol_index creates expected structure", {
  skip_on_cran()

  # May need to download cache
  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  index <- build_symbol_index()

  expect_type(index, "list")
  expect_true("symbol_to_id" %in% names(index))
  expect_true("alias_to_id" %in% names(index))
  expect_true("prev_to_id" %in% names(index))
  expect_true("id_to_record" %in% names(index))
  expect_true("indexed_at" %in% names(index))

  # Check that index is populated
  expect_gt(length(index$symbol_to_id), 0)
  expect_gt(length(index$id_to_record), 0)

  # Check timestamp
  expect_s3_class(index$indexed_at, "POSIXct")
})

test_that("build_symbol_index handles approved symbols correctly", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  index <- build_symbol_index()

  # Common genes should be in the index
  expect_true("BRCA1" %in% names(index$symbol_to_id))
  expect_true("TP53" %in% names(index$symbol_to_id))
  expect_true("EGFR" %in% names(index$symbol_to_id))

  # Check that HGNC ID is returned
  brca1_id <- index$symbol_to_id["BRCA1"]
  expect_type(brca1_id, "character")
  expect_true(nchar(brca1_id) > 0)
})

test_that("build_symbol_index stores full records", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  index <- build_symbol_index()

  # Get BRCA1 record
  brca1_id <- index$symbol_to_id["BRCA1"]
  brca1_record <- index$id_to_record[[brca1_id]]

  expect_type(brca1_record, "list")
  expect_true("symbol" %in% names(brca1_record))
  expect_true("hgnc_id" %in% names(brca1_record))
  expect_equal(brca1_record$symbol, "BRCA1")
})

test_that("build_symbol_index can use provided data", {
  skip_on_cran()

  # Create minimal test data
  test_data <- data.frame(
    hgnc_id = c("HGNC:1", "HGNC:2"),
    symbol = c("GENE1", "GENE2"),
    alias_symbol = c("ALIAS1|ALIAS2", NA),
    prev_symbol = c(NA, "OLDGENE2"),
    name = c("Gene 1", "Gene 2"),
    status = c("Approved", "Approved"),
    stringsAsFactors = FALSE
  )

  # Build index from test data (suppress message)
  index <- suppressMessages(build_symbol_index(test_data))

  expect_type(index, "list")
  expect_equal(length(index$symbol_to_id), 2)
  expect_true("GENE1" %in% names(index$symbol_to_id))
  expect_true("GENE2" %in% names(index$symbol_to_id))

  # Check aliases
  expect_true("ALIAS1" %in% names(index$alias_to_id))
  expect_true("ALIAS2" %in% names(index$alias_to_id))
  expect_equal(index$alias_to_id[["ALIAS1"]], "HGNC:1")

  # Check previous symbols
  expect_true("OLDGENE2" %in% names(index$prev_to_id))
  expect_equal(index$prev_to_id[["OLDGENE2"]], "HGNC:2")
})

test_that("build_symbol_index normalizes to uppercase", {
  skip_on_cran()

  test_data <- data.frame(
    hgnc_id = "HGNC:1",
    symbol = "brca1",
    alias_symbol = "alias1",
    prev_symbol = "prev1",
    name = "Gene 1",
    status = "Approved",
    stringsAsFactors = FALSE
  )

  index <- suppressMessages(build_symbol_index(test_data))

  # All symbols should be uppercase
  expect_true("BRCA1" %in% names(index$symbol_to_id))
  expect_false("brca1" %in% names(index$symbol_to_id))
  expect_true("ALIAS1" %in% names(index$alias_to_id))
  expect_true("PREV1" %in% names(index$prev_to_id))
})

# =============================================================================
# Tests for hgnc_normalize_list()
# =============================================================================

test_that("hgnc_normalize_list requires non-empty input", {
  expect_error(
    hgnc_normalize_list(),
    "'symbols' must be a non-empty character vector"
  )
  expect_error(
    hgnc_normalize_list(NULL),
    "'symbols' must be a non-empty character vector"
  )
  expect_error(
    hgnc_normalize_list(character(0)),
    "'symbols' must be a non-empty character vector"
  )
})

test_that("hgnc_normalize_list returns expected structure", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "TP53")
  result <- suppressMessages(hgnc_normalize_list(symbols))

  expect_type(result, "list")
  expect_true("results" %in% names(result))
  expect_true("summary" %in% names(result))
  expect_true("warnings" %in% names(result))
  expect_true("not_found" %in% names(result))
  expect_true("withdrawn" %in% names(result))

  # Check summary
  expect_type(result$summary, "list")
  expect_true("total_input" %in% names(result$summary))
  expect_true("found" %in% names(result$summary))
  expect_true("not_found" %in% names(result$summary))
})

test_that("hgnc_normalize_list resolves exact matches", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "TP53", "EGFR")
  result <- suppressMessages(hgnc_normalize_list(symbols))

  expect_equal(result$summary$total_input, 3)
  expect_equal(result$summary$found, 3)
  expect_equal(result$summary$not_found, 0)

  # Check results data frame
  expect_s3_class(result$results, "data.frame")
  expect_equal(nrow(result$results), 3)

  # Should have match_type column
  expect_true("match_type" %in% names(result$results))
  expect_true(all(result$results$match_type == "exact"))

  # Should have query_symbol column
  expect_true("query_symbol" %in% names(result$results))
})

test_that("hgnc_normalize_list handles not found symbols", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "NOTAREALGENE", "FAKESYMBOL")
  result <- suppressMessages(hgnc_normalize_list(symbols))

  expect_equal(result$summary$total_input, 3)
  expect_equal(result$summary$found, 1)
  expect_equal(result$summary$not_found, 2)

  # Check not_found list
  expect_equal(length(result$not_found), 2)
  expect_true("NOTAREALGENE" %in% result$not_found)
  expect_true("FAKESYMBOL" %in% result$not_found)

  # Check warnings
  expect_gt(length(result$warnings), 0)
})

test_that("hgnc_normalize_list handles case insensitivity", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("brca1", "Tp53", "EGFR")
  result <- suppressMessages(hgnc_normalize_list(symbols))

  expect_equal(result$summary$found, 3)

  # All should be found despite different cases
  expect_true("BRCA1" %in% result$results$symbol)
  expect_true("TP53" %in% result$results$symbol)
  expect_true("EGFR" %in% result$results$symbol)
})

test_that("hgnc_normalize_list deduplicates by default", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "BRCA1", "TP53", "BRCA1")
  result <- suppressMessages(hgnc_normalize_list(symbols, dedupe = TRUE))

  expect_equal(result$summary$total_input, 4)
  expect_equal(result$summary$found, 2) # Only 2 unique genes
  expect_gt(result$summary$duplicates_removed, 0)

  # Check that warnings mention duplicates
  expect_gt(length(result$warnings), 0)
  expect_true(any(grepl("duplicate", result$warnings, ignore.case = TRUE)))
})

test_that("hgnc_normalize_list without deduplication", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "BRCA1", "TP53")
  result <- suppressMessages(hgnc_normalize_list(symbols, dedupe = FALSE))

  # Should return all 3 entries
  expect_equal(nrow(result$results), 3)
})

test_that("hgnc_normalize_list respects status filter", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "TP53")
  result <- suppressMessages(hgnc_normalize_list(symbols, status = "Approved"))

  # Should only return Approved genes
  expect_equal(result$summary$found, 2)
  expect_true(all(result$results$status == "Approved"))
})

test_that("hgnc_normalize_list handles empty and NA symbols", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1", "", NA, "  ", "TP53")
  result <- suppressMessages(hgnc_normalize_list(symbols))

  # Should skip empty/NA symbols
  expect_equal(result$summary$found, 2)

  # Should have warnings about skipped entries
  expect_gt(length(result$warnings), 0)
})

test_that("hgnc_normalize_list accepts custom return fields", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  symbols <- c("BRCA1")
  result <- suppressMessages(hgnc_normalize_list(
    symbols,
    return_fields = c("symbol", "name", "hgnc_id")
  ))

  # Check that only requested fields are returned (plus metadata)
  expected_fields <- c(
    "symbol",
    "name",
    "hgnc_id",
    "query_symbol",
    "match_type"
  )
  expect_true(all(expected_fields %in% names(result$results)))
})

test_that("hgnc_normalize_list works with provided index", {
  skip_on_cran()

  if (!is_hgnc_cache_fresh()) {
    skip("HGNC cache not available")
  }

  # Build index once
  index <- suppressMessages(build_symbol_index())

  # Use it multiple times
  symbols1 <- c("BRCA1", "TP53")
  symbols2 <- c("EGFR", "KRAS")

  result1 <- suppressMessages(hgnc_normalize_list(symbols1, index = index))
  result2 <- suppressMessages(hgnc_normalize_list(symbols2, index = index))

  expect_equal(result1$summary$found, 2)
  expect_equal(result2$summary$found, 2)

  # Both should reference the same index timestamp
  expect_equal(result1$index_timestamp, result2$index_timestamp)
})

test_that("hgnc_normalize_list handles test data correctly", {
  skip_on_cran()

  # Create test data
  test_data <- data.frame(
    hgnc_id = c("HGNC:1", "HGNC:2", "HGNC:3"),
    symbol = c("GENE1", "GENE2", "GENE3"),
    alias_symbol = c("ALIAS1", NA, NA),
    prev_symbol = c(NA, "OLDGENE2", NA),
    name = c("Gene 1", "Gene 2", "Gene 3"),
    status = c("Approved", "Approved", "Withdrawn"),
    locus_type = c(
      "gene with protein product",
      "gene with protein product",
      "unknown"
    ),
    location = c("1p", "2q", "3p"),
    stringsAsFactors = FALSE
  )

  index <- suppressMessages(build_symbol_index(test_data))

  # Test exact match
  result <- suppressMessages(hgnc_normalize_list(
    c("GENE1", "GENE2"),
    index = index
  ))

  expect_equal(result$summary$found, 2)
  expect_equal(result$summary$not_found, 0)

  # Test alias match
  result <- suppressMessages(hgnc_normalize_list(
    c("ALIAS1"),
    index = index
  ))

  expect_equal(result$summary$found, 1)
  expect_equal(result$results$symbol[1], "GENE1")
  expect_equal(result$results$match_type[1], "alias")

  # Test previous symbol match
  result <- suppressMessages(hgnc_normalize_list(
    c("OLDGENE2"),
    index = index
  ))

  expect_equal(result$summary$found, 1)
  expect_equal(result$results$symbol[1], "GENE2")
  expect_equal(result$results$match_type[1], "previous")
  expect_gt(length(result$warnings), 0) # Should warn about previous symbol

  # Test withdrawn gene filtering
  result <- suppressMessages(hgnc_normalize_list(
    c("GENE3"),
    status = "Approved",
    index = index
  ))

  expect_equal(result$summary$found, 0) # Should be filtered out
  expect_equal(result$summary$withdrawn, 1)
  expect_equal(nrow(result$withdrawn), 1)
})

test_that("hgnc_normalize_list handles ambiguous aliases", {
  skip_on_cran()

  # Create test data with ambiguous alias
  test_data <- data.frame(
    hgnc_id = c("HGNC:1", "HGNC:2"),
    symbol = c("GENE1", "GENE2"),
    alias_symbol = c("AMBIGUOUS", "AMBIGUOUS"),
    prev_symbol = c(NA, NA),
    name = c("Gene 1", "Gene 2"),
    status = c("Approved", "Approved"),
    stringsAsFactors = FALSE
  )

  index <- suppressMessages(build_symbol_index(test_data))

  result <- suppressMessages(hgnc_normalize_list(
    c("AMBIGUOUS"),
    index = index
  ))

  # Should not resolve ambiguous symbol
  expect_equal(result$summary$found, 0)
  expect_equal(result$summary$not_found, 1)

  # Should have warning about ambiguity
  expect_gt(length(result$warnings), 0)
  expect_true(any(grepl("ambiguous", result$warnings, ignore.case = TRUE)))
})
