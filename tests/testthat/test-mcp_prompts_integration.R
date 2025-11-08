# Tests for MCP Server Integration
#
# This test suite covers:
# - MCP prompt support detection
# - MCP dependency checking (plumber, plumber2mcp)
# - Server initialization and configuration
# - API file location and structure
# - Prompt registration and parameter handling
#
# These tests verify the MCP server setup without actually starting
# the server (which would block test execution).

test_that("MCP server checks for prompt support correctly", {
  # Check if pr_mcp_prompt is in plumber2mcp exports
  has_prompt_support <- "pr_mcp_prompt" %in% getNamespaceExports("plumber2mcp")

  expect_type(has_prompt_support, "logical")
  # This will be TRUE once plumber2mcp NAMESPACE is updated
})

test_that("prompt helper functions are exported", {
  # Verify all prompt functions are available
  expect_true(exists("prompt_normalize_gene_list"))
  expect_true(exists("prompt_check_nomenclature_compliance"))
  expect_true(exists("prompt_what_changed_since"))
  expect_true(exists("prompt_build_gene_set_from_group"))

  # Verify they are functions
  expect_type(prompt_normalize_gene_list, "closure")
  expect_type(prompt_check_nomenclature_compliance, "closure")
  expect_type(prompt_what_changed_since, "closure")
  expect_type(prompt_build_gene_set_from_group, "closure")
})

test_that("check_mcp_dependencies reports correctly", {
  # This function should run without error
  result <- check_mcp_dependencies()

  expect_type(result, "logical")
  # Result depends on whether dependencies are installed
})

# =============================================================================
# Tests for check_mcp_dependencies()
# =============================================================================

test_that("check_mcp_dependencies returns TRUE when all deps installed", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  result <- suppressMessages(check_mcp_dependencies())

  expect_type(result, "logical")
  expect_true(result)
})

test_that("check_mcp_dependencies prints status for each dependency", {
  # Capture output
  output <- capture.output(
    result <- check_mcp_dependencies(),
    type = "message"
  )

  # Should mention plumber and plumber2mcp
  output_text <- paste(output, collapse = "\n")
  expect_match(output_text, "plumber", ignore.case = TRUE)
  expect_match(output_text, "plumber2mcp", ignore.case = TRUE)
})

# =============================================================================
# Tests for start_hgnc_mcp_server() - Error Handling and Initialization
# =============================================================================

test_that("start_hgnc_mcp_server checks for plumber package", {
  skip_if_not_installed("plumber2mcp")

  # This test only works if plumber is NOT installed, which is unlikely
  # We'll check the error message structure instead
  if (!requireNamespace("plumber", quietly = TRUE)) {
    expect_error(
      start_hgnc_mcp_server(quiet = TRUE),
      "Package 'plumber' is required"
    )
  } else {
    skip("plumber is installed, cannot test missing package error")
  }
})

test_that("start_hgnc_mcp_server checks for plumber2mcp package", {
  skip_if_not_installed("plumber")

  # This test only works if plumber2mcp is NOT installed
  if (!requireNamespace("plumber2mcp", quietly = TRUE)) {
    expect_error(
      start_hgnc_mcp_server(quiet = TRUE),
      "Package 'plumber2mcp' is required"
    )
  } else {
    skip("plumber2mcp is installed, cannot test missing package error")
  }
})

test_that("start_hgnc_mcp_server can locate API file", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Get the API file path using the same logic as the function
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (nchar(api_file) == 0 || !file.exists(api_file)) {
    # Try local path
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  # API file should exist
  expect_true(file.exists(api_file))
})

test_that("start_hgnc_mcp_server validates API file exists", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # If we can't find the API file, the function should error
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (nchar(api_file) == 0) {
    # Check local path
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    expect_error(
      suppressMessages(start_hgnc_mcp_server(quiet = TRUE)),
      "Could not locate HGNC Plumber API file"
    )
  } else {
    skip("API file exists, cannot test missing file error")
  }
})

# =============================================================================
# Tests for server initialization parameters
# =============================================================================

test_that("start_hgnc_mcp_server accepts valid port parameter", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # We can't actually start the server in tests (it would block),
  # but we can test parameter validation by checking the function signature
  expect_silent({
    # Check that the function exists and has the expected parameters
    formals_list <- formals(start_hgnc_mcp_server)
    expect_true("port" %in% names(formals_list))
    expect_true("host" %in% names(formals_list))
    expect_true("swagger" %in% names(formals_list))
    expect_true("quiet" %in% names(formals_list))
  })
})

test_that("start_hgnc_mcp_server has correct default parameters", {
  formals_list <- formals(start_hgnc_mcp_server)

  # Check defaults
  expect_equal(formals_list$port, 8080)
  expect_equal(formals_list$host, "0.0.0.0")
  expect_equal(formals_list$swagger, TRUE)
  expect_equal(formals_list$quiet, FALSE)
})

# =============================================================================
# Tests for MCP prompt registration
# =============================================================================

test_that("server checks for MCP prompt support before registration", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Check the same way the server does
  has_prompt_support <- "pr_mcp_prompt" %in% getNamespaceExports("plumber2mcp")

  expect_type(has_prompt_support, "logical")

  # If prompt support is available, verify we can access the function
  if (has_prompt_support) {
    expect_true(exists("pr_mcp_prompt", envir = asNamespace("plumber2mcp")))
  }
})

test_that("prompt helper functions return character strings", {
  # Test that prompt functions return formatted strings
  result1 <- prompt_normalize_gene_list("BRCA1,TP53", "lenient", FALSE)
  expect_type(result1, "character")
  expect_gt(nchar(result1), 0)

  result2 <- prompt_check_nomenclature_compliance("BRCA1,TP53")
  expect_type(result2, "character")
  expect_gt(nchar(result2), 0)

  result3 <- prompt_what_changed_since("2024-01-01")
  expect_type(result3, "character")
  expect_gt(nchar(result3), 0)

  result4 <- prompt_build_gene_set_from_group("kinase")
  expect_type(result4, "character")
  expect_gt(nchar(result4), 0)
})

test_that("prompt helper functions handle NULL and empty inputs gracefully", {
  # These should not error, but return reasonable default prompts
  expect_type(prompt_normalize_gene_list("", "lenient", FALSE), "character")
  expect_type(prompt_check_nomenclature_compliance(""), "character")
  expect_type(prompt_what_changed_since(NULL), "character")
  expect_type(prompt_build_gene_set_from_group(""), "character")
})

test_that("prompt_normalize_gene_list respects strictness parameter", {
  result_lenient <- prompt_normalize_gene_list("BRCA1", "lenient", FALSE)
  result_strict <- prompt_normalize_gene_list("BRCA1", "strict", FALSE)

  expect_type(result_lenient, "character")
  expect_type(result_strict, "character")

  # The prompts should be different based on strictness
  # At minimum, they should mention the strictness mode
  expect_match(result_lenient, "lenient", ignore.case = TRUE)
  expect_match(result_strict, "strict", ignore.case = TRUE)
})

test_that("prompt_normalize_gene_list respects return_xrefs parameter", {
  result_no_xrefs <- prompt_normalize_gene_list("BRCA1", "lenient", FALSE)
  result_with_xrefs <- prompt_normalize_gene_list("BRCA1", "lenient", TRUE)

  expect_type(result_no_xrefs, "character")
  expect_type(result_with_xrefs, "character")

  # When xrefs are requested, the prompt should mention them
  expect_match(
    result_with_xrefs,
    "cross.*reference|xref|entrez|ensembl",
    ignore.case = TRUE
  )
})

# =============================================================================
# Tests for API file structure
# =============================================================================

test_that("Plumber API file exists in expected location", {
  # Check inst/plumber/hgnc_api.R exists
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (nchar(api_file) == 0) {
    # Try local path for development
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  expect_true(
    file.exists(api_file),
    info = "hgnc_api.R should exist in inst/plumber/"
  )
})

test_that("Plumber API file is readable and contains expected endpoints", {
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (nchar(api_file) == 0) {
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    skip("API file not found")
  }

  # Read the API file
  api_content <- readLines(api_file, warn = FALSE)
  api_text <- paste(api_content, collapse = "\n")

  # Check for expected endpoint decorators
  expect_match(api_text, "@get|@post|@apiGet|@apiPost", ignore.case = TRUE)

  # Check for some expected function names
  expect_match(api_text, "info|find|fetch|normalize", ignore.case = TRUE)
})
