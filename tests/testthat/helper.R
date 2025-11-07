# Test Helper Functions

# Helper to skip integration tests (tests that require network/API access)
# when running coverage or in environments where we want fast unit tests only
skip_if_integration_tests <- function() {
  if (identical(Sys.getenv("SKIP_INTEGRATION_TESTS"), "true")) {
    testthat::skip("Integration tests skipped (SKIP_INTEGRATION_TESTS=true)")
  }
}
