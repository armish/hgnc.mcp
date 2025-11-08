#!/usr/bin/env Rscript
#
# Test script to verify the HGNC MCP server starts correctly
# This is used in CI/CD to catch startup errors
#

message("Testing HGNC MCP server startup...")

# Load the package
library(hgnc.mcp)

# Try to create the plumber router without starting the server
tryCatch(
  {
    # Locate the Plumber API file
    api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

    if (!file.exists(api_file) || nchar(api_file) == 0) {
      stop("Could not locate HGNC Plumber API file")
    }

    message("Loading Plumber API...")
    pr <- plumber::plumb(api_file)

    message("Applying MCP integration...")
    pr <- plumber2mcp::pr_mcp(pr, transport = "http")

    message("✓ Server configuration successful!")
    message("✓ MCP integration with transport='http' works correctly")

    quit(status = 0)
  },
  error = function(e) {
    message("✗ Server startup test FAILED:")
    message(paste0("  Error: ", e$message))
    quit(status = 1)
  }
)
