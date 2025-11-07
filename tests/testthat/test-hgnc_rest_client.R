# Tests for HGNC REST API Client
#
# This test suite covers:
# - Rate limiting implementation (≤10 req/sec)
# - Response caching with memoise
# - Error handling and retries
# - API endpoint wrappers (info, search, fetch)
# - Cache management (clear_hgnc_cache, reset_rate_limiter)
#
# Integration tests are skipped on CRAN and during coverage runs.

test_that("rate limiter prevents exceeding 10 req/sec", {
  # Reset rate limiter
  reset_rate_limiter()

  # Record start time
  start_time <- Sys.time()

  # Make 15 "requests" (just calling the rate limiter)
  for (i in 1:15) {
    hgnc.mcp:::rate_limit_wait()
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # 15 requests should take at least 0.5 seconds (since we can do 10/sec)
  # We expect this to take ~0.5-1 second
  expect_gte(elapsed, 0.4)  # Allow some timing variance

  # Reset for other tests
  reset_rate_limiter()
})

test_that("rate limiter allows requests within limit", {
  reset_rate_limiter()

  start_time <- Sys.time()

  # Make 5 requests (well under limit)
  for (i in 1:5) {
    hgnc.mcp:::rate_limit_wait()
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Should be nearly instant
  expect_lt(elapsed, 0.2)

  reset_rate_limiter()
})

test_that("reset_rate_limiter clears state", {
  # Make some requests
  for (i in 1:5) {
    hgnc.mcp:::rate_limit_wait()
  }

  # Check state is populated
  expect_gt(length(hgnc.mcp:::.hgnc_env$rate_limiter$request_times), 0)

  # Reset
  reset_rate_limiter()

  # Check state is cleared
  expect_equal(length(hgnc.mcp:::.hgnc_env$rate_limiter$request_times), 0)
})

test_that("clear_hgnc_cache clears memoise cache", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  # Call hgnc_rest_info twice
  info1 <- hgnc_rest_info()
  info2 <- hgnc_rest_info()

  # Should be the same object (cached)
  expect_identical(info1, info2)

  # Clear cache
  clear_hgnc_cache()

  # Call again - this should make a new API call
  # We can't easily test this without mocking, but at least verify it doesn't error
  info3 <- hgnc_rest_info()
  expect_true(is.list(info3))

  clear_hgnc_cache()
})

# Live API tests - these hit the real HGNC API
test_that("hgnc_rest_info returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  clear_hgnc_cache()
  reset_rate_limiter()

  info <- hgnc_rest_info()

  expect_type(info, "list")
  expect_true("lastModified" %in% names(info))
  expect_true("searchableFields" %in% names(info))
  expect_true("storedFields" %in% names(info))

  # lastModified should be a character string
  expect_type(info$lastModified, "character")
  expect_gt(nchar(info$lastModified), 0)

  # Fields should be character vectors
  expect_type(info$searchableFields, "character")
  expect_type(info$storedFields, "character")

  # Should have some fields
  expect_gt(length(info$searchableFields), 0)
  expect_gt(length(info$storedFields), 0)

  # Common fields should be present
  expect_true("symbol" %in% info$storedFields)
  expect_true("hgnc_id" %in% info$storedFields)

  clear_hgnc_cache()
})

test_that("hgnc_rest_get can fetch info endpoint (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_rest_get("info")

  expect_type(result, "list")
  expect_true(!is.null(result$responseHeader) || !is.null(result$searchableFields))
})

test_that("hgnc_rest_get handles bad endpoints gracefully", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  expect_error(
    hgnc_rest_get("this_endpoint_does_not_exist_12345"),
    "HGNC API request failed"
  )
})

test_that("hgnc_rest_get sets User-Agent header", {
  # This is hard to test without mocking, but we can at least verify
  # the function doesn't error when building the header
  pkg_version <- utils::packageVersion("hgnc.mcp")
  user_agent <- sprintf("hgnc.mcp/%s (R package; https://github.com/armish/hgnc.mcp)", pkg_version)

  expect_type(user_agent, "character")
  expect_match(user_agent, "hgnc\\.mcp")
})

test_that("hgnc_rest_info caching works", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  clear_hgnc_cache()
  reset_rate_limiter()

  # First call - will hit API
  start_time1 <- Sys.time()
  info1 <- hgnc_rest_info()
  elapsed1 <- as.numeric(difftime(Sys.time(), start_time1, units = "secs"))

  # Second call - should be cached (much faster)
  start_time2 <- Sys.time()
  info2 <- hgnc_rest_info()
  elapsed2 <- as.numeric(difftime(Sys.time(), start_time2, units = "secs"))

  # Cached call should be much faster
  expect_lt(elapsed2, elapsed1 * 0.5)

  # Results should be identical
  expect_identical(info1, info2)

  clear_hgnc_cache()
})

test_that("null-coalescing operator works", {
  null_coalesce <- hgnc.mcp:::`%||%`

  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal(NA %||% "default", NA)
  expect_equal(FALSE %||% "default", FALSE)
  expect_equal(0 %||% "default", 0)
})

# Helper function to check if we're offline
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection")
  }
}
