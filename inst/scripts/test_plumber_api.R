#!/usr/bin/env Rscript
# Test script for the HGNC Plumber API
#
# This script tests that the Plumber API can be loaded and initialized
# without errors.

library(plumber)

cat("Testing HGNC Plumber API...\n")

# Try to load the Plumber API
api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

if (nchar(api_file) == 0) {
  # Try local path if not installed
  api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
}

cat("Loading API from:", api_file, "\n")

if (!file.exists(api_file)) {
  stop("API file not found: ", api_file)
}

# Create the plumber API object
tryCatch({
  pr <- plumb(api_file)
  cat("✓ API loaded successfully\n")

  # List all endpoints
  cat("\nAvailable endpoints:\n")
  endpoints <- pr$endpoints
  for (path in names(endpoints)) {
    for (method_data in endpoints[[path]]) {
      if (!is.null(method_data$verbs)) {
        cat(sprintf("  %s %s\n", paste(method_data$verbs, collapse = ","), path))
      }
    }
  }

  cat("\n✓ All tests passed!\n")
  cat("\nTo start the server, run:\n")
  cat("  pr <- plumber::plumb('inst/plumber/hgnc_api.R')\n")
  cat("  pr$run(port = 8080)\n")

}, error = function(e) {
  cat("✗ Error loading API:\n")
  cat("  ", e$message, "\n")
  quit(status = 1)
})
