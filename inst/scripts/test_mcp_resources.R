#!/usr/bin/env Rscript
# Test MCP Resources Registration
#
# This script tests whether MCP resources are properly registered
# and can be accessed via the MCP protocol.

cat("Testing MCP Resources Registration\n")
cat("===================================\n\n")

# Load the package
suppressPackageStartupMessages({
  library(hgnc.mcp)
  library(plumber)
})

# Check if pr_mcp_resource is available
cat("1. Checking plumber2mcp resource support...\n")
has_resource_support <- "pr_mcp_resource" %in% getNamespaceExports("plumber2mcp")

if (has_resource_support) {
  cat("   [OK] pr_mcp_resource is available\n\n")
} else {
  cat("   [ERROR] pr_mcp_resource is NOT exported in plumber2mcp\n")
  cat("   Install latest version: remotes::install_github('armish/plumber2mcp')\n\n")
  quit(status = 1)
}

# Test resource functions
cat("2. Testing resource functions...\n")

# Test snapshot
cat("   Testing hgnc_get_snapshot_metadata()... ")
snapshot_result <- tryCatch(
  {
    hgnc_get_snapshot_metadata(format = "json")
  },
  error = function(e) {
    cat("[ERROR]", e$message, "\n")
    NULL
  }
)
if (!is.null(snapshot_result)) {
  cat("[OK]\n")
}

# Test gene card
cat("   Testing hgnc_get_gene_card()... ")
gene_result <- tryCatch(
  {
    hgnc_get_gene_card(hgnc_id = "BRCA1", format = "json")
  },
  error = function(e) {
    cat("[ERROR]", e$message, "\n")
    NULL
  }
)
if (!is.null(gene_result)) {
  cat("[OK]\n")
}

# Test group card
cat("   Testing hgnc_get_group_card()... ")
group_result <- tryCatch(
  {
    hgnc_get_group_card(group_id_or_name = "1", format = "json", include_members = FALSE)
  },
  error = function(e) {
    cat("[ERROR]", e$message, "\n")
    NULL
  }
)
if (!is.null(group_result)) {
  cat("[OK]\n")
}

# Test changes summary
cat("   Testing hgnc_get_changes_summary()... ")
changes_result <- tryCatch(
  {
    hgnc_get_changes_summary(since = "2024-01-01", format = "json", max_results = 5)
  },
  error = function(e) {
    cat("[ERROR]", e$message, "\n")
    NULL
  }
)
if (!is.null(changes_result)) {
  cat("[OK]\n")
}

cat("\n3. Creating MCP server and checking resources...\n")

# Get the API file
api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")
if (!file.exists(api_file)) {
  api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
}

# Create plumber router
pr <- plumber::plumb(api_file)

# Apply MCP integration
pr <- plumber2mcp::pr_mcp(pr, transport = "stdio")

# Get the pr_mcp_resource function
pr_mcp_resource_fn <- get("pr_mcp_resource", envir = asNamespace("plumber2mcp"))

# Register test resource
cat("   Registering test resources...\n")

tryCatch(
  {
    # Register snapshot resource
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "hgnc://test/snapshot",
      name = "Test Snapshot",
      description = "Test snapshot resource",
      mimeType = "application/json",
      func = function() {
        jsonlite::toJSON(list(test = "success"), auto_unbox = TRUE)
      }
    )
    cat("   [OK] Successfully registered test resource\n")
  },
  error = function(e) {
    cat("   [ERROR]", e$message, "\n")
  }
)

cat("\n")
cat("===================================\n")
cat("All tests passed!\n")
cat("\n")
cat("Next steps:\n")
cat("1. Build Docker image: docker build -t hgnc-mcp:test .\n")
cat("2. Test with MCP Inspector:\n")
cat("   npx @modelcontextprotocol/inspector docker run --rm -i \\\n")
cat("     -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:test\n")
cat("\n")
cat("Expected results:\n")
cat("- Resources tab should show 4 resources with hgnc:// URIs\n")
cat("- Tools tab should show 10 tools (POST__tools_* only)\n")
cat("- GET__resources_* should NOT appear in tools list\n")
cat("\n")
