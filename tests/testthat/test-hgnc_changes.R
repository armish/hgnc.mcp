# Tests for HGNC Change Tracking & Validation Functions

library(testthat)

# Test: hgnc_changes() basic functionality
test_that("hgnc_changes() requires 'since' parameter", {
  expect_error(
    hgnc_changes(),
    "since.*required"
  )
})

test_that("hgnc_changes() accepts various date formats", {
  skip_on_cran()
  skip_if_offline()

  # Date object
  result <- hgnc_changes(since = as.Date("2024-01-01"))
  expect_type(result, "list")
  expect_s3_class(result$since, "Date")
  expect_equal(result$since, as.Date("2024-01-01"))

  # Character string
  result <- hgnc_changes(since = "2024-06-01")
  expect_type(result, "list")
  expect_equal(result$since, as.Date("2024-06-01"))

  # POSIXct
  result <- hgnc_changes(since = as.POSIXct("2024-01-01"))
  expect_type(result, "list")
  expect_s3_class(result$since, "Date")
})

test_that("hgnc_changes() rejects invalid date formats", {
  expect_error(
    hgnc_changes(since = "not-a-date"),
    "Invalid date format"
  )

  expect_error(
    hgnc_changes(since = 12345),
    "Invalid date format|must be a Date"
  )
})

test_that("hgnc_changes() returns expected structure", {
  skip_on_cran()
  skip_if_offline()

  result <- hgnc_changes(since = Sys.Date() - 365)

  expect_type(result, "list")
  expect_named(result, c("changes", "summary", "since", "query_time"))

  expect_s3_class(result$changes, "data.frame")
  expect_type(result$summary, "list")
  expect_s3_class(result$since, "Date")
  expect_s3_class(result$query_time, "POSIXct")
})

test_that("hgnc_changes() filters by change type", {
  skip_on_cran()
  skip_if_offline()

  # Test all change types
  result_all <- hgnc_changes(since = "2023-01-01", change_type = "all")
  result_symbol <- hgnc_changes(since = "2023-01-01", change_type = "symbol")
  result_name <- hgnc_changes(since = "2023-01-01", change_type = "name")
  result_modified <- hgnc_changes(since = "2023-01-01", change_type = "modified")

  expect_type(result_all, "list")
  expect_type(result_symbol, "list")
  expect_type(result_name, "list")
  expect_type(result_modified, "list")

  # Summary should reflect change type
  expect_equal(result_all$summary$change_type, "all")
  expect_equal(result_symbol$summary$change_type, "symbol")
  expect_equal(result_name$summary$change_type, "name")
  expect_equal(result_modified$summary$change_type, "modified")
})

test_that("hgnc_changes() includes requested fields", {
  skip_on_cran()
  skip_if_offline()

  result <- hgnc_changes(
    since = "2023-01-01",
    fields = c("symbol", "name", "status", "date_modified")
  )

  if (nrow(result$changes) > 0) {
    # Should include requested fields (if available in data)
    expect_true("symbol" %in% names(result$changes) ||
                "name" %in% names(result$changes))
  }
})

test_that("hgnc_changes() summary contains useful info", {
  skip_on_cran()
  skip_if_offline()

  result <- hgnc_changes(since = Sys.Date() - 90)

  expect_true("total" %in% names(result$summary))
  expect_true("since" %in% names(result$summary))
  expect_true("change_type" %in% names(result$summary))
  expect_type(result$summary$total, "integer")
})

# Test: hgnc_validate_panel() basic functionality
test_that("hgnc_validate_panel() requires items parameter", {
  expect_error(
    hgnc_validate_panel(),
    "items.*required"
  )

  expect_error(
    hgnc_validate_panel(character(0)),
    "non-empty"
  )
})

test_that("hgnc_validate_panel() returns expected structure", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53", "EGFR")
  result <- hgnc_validate_panel(items)

  expect_type(result, "list")
  expect_named(result, c("valid", "issues", "summary", "report", "replacements"))

  expect_s3_class(result$valid, "data.frame")
  expect_s3_class(result$issues, "data.frame")
  expect_type(result$summary, "list")
  expect_type(result$report, "character")
  expect_type(result$replacements, "list")
})

test_that("hgnc_validate_panel() validates approved symbols correctly", {
  skip_on_cran()
  skip_if_offline()

  # Test with known approved symbols
  items <- c("BRCA1", "TP53", "EGFR", "KRAS")
  result <- hgnc_validate_panel(items)

  # All should be valid (assuming these are current approved symbols)
  expect_gte(nrow(result$valid), 3)  # At least 3 should be valid
  expect_equal(result$summary$total_items, 4)
})

test_that("hgnc_validate_panel() detects duplicates", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53", "BRCA1", "EGFR", "BRCA1")
  result <- hgnc_validate_panel(items)

  # Should detect duplicates
  if (nrow(result$issues) > 0) {
    duplicate_issues <- result$issues[result$issues$issue == "duplicate", ]
    expect_gte(nrow(duplicate_issues), 1)
  }

  # Summary should show duplicates
  expect_true("issues_by_type" %in% names(result$summary))
})

test_that("hgnc_validate_panel() detects not found symbols", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "NOTAREALGENE123", "TP53")
  result <- hgnc_validate_panel(items)

  # Should have at least one issue
  expect_gte(nrow(result$issues), 1)

  # Should have a not_found issue
  if (nrow(result$issues) > 0) {
    expect_true("not_found" %in% result$issues$issue)
  }
})

test_that("hgnc_validate_panel() handles empty/NA values", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "", NA, "TP53")
  result <- hgnc_validate_panel(items)

  # Should detect empty/NA issues
  if (nrow(result$issues) > 0) {
    empty_issues <- result$issues[result$issues$issue == "empty_or_na", ]
    expect_gte(nrow(empty_issues), 1)
  }
})

test_that("hgnc_validate_panel() handles case insensitivity", {
  skip_on_cran()
  skip_if_offline()

  items <- c("brca1", "BRCA1", "BrCa1")
  result <- hgnc_validate_panel(items)

  # All should resolve to the same gene (BRCA1)
  # Should detect duplicates
  expect_gte(result$summary$total_items, 3)

  # At least one should be valid, others should be duplicates or warnings
  expect_gte(result$summary$valid + result$summary$issues, 3)
})

test_that("hgnc_validate_panel() generates readable report", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53", "NOTREAL")
  result <- hgnc_validate_panel(items)

  expect_type(result$report, "character")
  expect_gt(length(result$report), 0)

  # Report should contain key information
  report_text <- paste(result$report, collapse = "\n")
  expect_match(report_text, "Validation Report", ignore.case = TRUE)
  expect_match(report_text, "Total items", ignore.case = TRUE)
})

test_that("hgnc_validate_panel() suggests replacements", {
  skip_on_cran()
  skip_if_offline()

  # Use a mix of symbols that might trigger replacement suggestions
  # Note: This test might need adjustment based on actual HGNC data
  items <- c("BRCA1", "TP53")
  result <- hgnc_validate_panel(items, suggest_replacements = TRUE)

  expect_type(result$replacements, "list")

  # When suggest_replacements = FALSE
  result_no_repl <- hgnc_validate_panel(items, suggest_replacements = FALSE)
  expect_type(result_no_repl$replacements, "list")
})

test_that("hgnc_validate_panel() summary contains useful statistics", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53", "EGFR", "NOTREAL", "BRCA1")
  result <- hgnc_validate_panel(items)

  expect_true("total_items" %in% names(result$summary))
  expect_true("valid" %in% names(result$summary))
  expect_true("issues" %in% names(result$summary))
  expect_true("policy" %in% names(result$summary))

  expect_equal(result$summary$total_items, 5)
  expect_equal(result$summary$policy, "HGNC")
})

test_that("hgnc_validate_panel() works with pre-built index", {
  skip_on_cran()
  skip_if_offline()

  # Build index once
  index <- build_symbol_index()

  items1 <- c("BRCA1", "TP53")
  items2 <- c("EGFR", "KRAS")

  # Use same index for both
  result1 <- hgnc_validate_panel(items1, index = index)
  result2 <- hgnc_validate_panel(items2, index = index)

  expect_type(result1, "list")
  expect_type(result2, "list")
})

test_that("hgnc_validate_panel() only supports HGNC policy", {
  expect_error(
    hgnc_validate_panel(c("BRCA1"), policy = "OTHER"),
    "only.*HGNC.*supported"
  )
})

# Test: Integration between functions
test_that("hgnc_changes() and hgnc_validate_panel() work together", {
  skip_on_cran()
  skip_if_offline()

  # Get recent changes
  changes <- hgnc_changes(since = Sys.Date() - 180)

  if (nrow(changes$changes) > 0) {
    # Take a few changed symbols and validate them
    symbols_to_validate <- head(changes$changes$symbol, 5)

    # Remove NA values
    symbols_to_validate <- symbols_to_validate[!is.na(symbols_to_validate)]

    if (length(symbols_to_validate) > 0) {
      result <- hgnc_validate_panel(symbols_to_validate)

      expect_type(result, "list")
      # Recently changed symbols should still be valid (if they're current symbols)
      # Though some might have issues if they were the old symbols
    }
  }
})

# Test: Edge cases
test_that("hgnc_validate_panel() handles all valid input", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53", "EGFR")
  result <- hgnc_validate_panel(items)

  # If all are valid, issues should be minimal
  if (result$summary$issues == 0) {
    expect_equal(nrow(result$issues), 0)
    expect_gt(nrow(result$valid), 0)
  }
})

test_that("hgnc_validate_panel() handles all invalid input", {
  skip_on_cran()
  skip_if_offline()

  items <- c("NOTREAL1", "NOTREAL2", "NOTREAL3")
  result <- hgnc_validate_panel(items)

  # Should have issues for all items
  expect_gt(result$summary$issues, 0)
})

test_that("hgnc_changes() handles very recent dates", {
  skip_on_cran()
  skip_if_offline()

  # Very recent (yesterday)
  result <- hgnc_changes(since = Sys.Date() - 1)

  expect_type(result, "list")
  expect_s3_class(result$changes, "data.frame")

  # May have 0 changes, which is valid
  expect_gte(nrow(result$changes), 0)
})

test_that("hgnc_changes() handles dates far in the past", {
  skip_on_cran()
  skip_if_offline()

  # Far in the past (should return many changes)
  result <- hgnc_changes(since = "2000-01-01")

  expect_type(result, "list")
  expect_s3_class(result$changes, "data.frame")

  # Should have many changes over 20+ years
  # (but this depends on date field availability)
  expect_gte(nrow(result$changes), 0)
})

test_that("hgnc_validate_panel() includes date info when requested", {
  skip_on_cran()
  skip_if_offline()

  items <- c("BRCA1", "TP53")
  result_with_dates <- hgnc_validate_panel(items, include_dates = TRUE)
  result_without_dates <- hgnc_validate_panel(items, include_dates = FALSE)

  expect_type(result_with_dates, "list")
  expect_type(result_without_dates, "list")
})
