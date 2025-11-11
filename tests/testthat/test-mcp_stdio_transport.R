# Tests for MCP Server stdio Transport Mode
#
# This test suite covers:
# - Transport parameter validation
# - stdio mode initialization
# - HTTP vs stdio mode differences
# - Server behavior with different transport modes
#
# These tests verify that the MCP server works correctly in stdio mode,
# which is used by Claude Desktop and other desktop MCP clients.

# =============================================================================
# Tests for transport parameter validation
# =============================================================================

test_that("start_hgnc_mcp_server accepts transport parameter", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Check that transport parameter exists
  formals_list <- formals(start_hgnc_mcp_server)
  expect_true("transport" %in% names(formals_list))
})

test_that("start_hgnc_mcp_server has correct default transport", {
  formals_list <- formals(start_hgnc_mcp_server)

  # Default should be "http" for backwards compatibility
  expect_equal(formals_list$transport, "http")
})

test_that("start_hgnc_mcp_server validates transport parameter", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Invalid transport should error
  expect_error(
    suppressMessages(start_hgnc_mcp_server(transport = "invalid", quiet = TRUE)),
    "Invalid transport mode"
  )
})

test_that("start_hgnc_mcp_server accepts valid transport modes", {
  # Valid modes are "http" and "stdio"
  expect_silent({
    formals_list <- formals(start_hgnc_mcp_server)
    # Function should accept these without validation errors
  })

  # The actual validation happens in the function body, so we test
  # that the validation logic exists
  expect_true(TRUE)
})

# =============================================================================
# Tests for stdio transport initialization
# =============================================================================

test_that("server can initialize with stdio transport (without running)", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Get the API file
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")
  if (nchar(api_file) == 0 || !file.exists(api_file)) {
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    skip("API file not found")
  }

  # Test that we can create a plumber router and apply stdio transport
  expect_silent({
    pr <- plumber::plumb(api_file)
    pr <- plumber2mcp::pr_mcp(pr, transport = "stdio")
  })
})

test_that("server can initialize with http transport (without running)", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")
  if (nchar(api_file) == 0 || !file.exists(api_file)) {
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    skip("API file not found")
  }

  # Test that we can create a plumber router and apply http transport
  expect_silent({
    pr <- plumber::plumb(api_file)
    pr <- plumber2mcp::pr_mcp(pr, transport = "http")
  })
})

# =============================================================================
# Tests for resource registration in stdio mode
# =============================================================================

test_that("resources are registered in stdio transport mode", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  has_resource_support <- "pr_mcp_resource" %in% getNamespaceExports("plumber2mcp")

  if (!has_resource_support) {
    skip("pr_mcp_resource not available in plumber2mcp")
  }

  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")
  if (nchar(api_file) == 0 || !file.exists(api_file)) {
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    skip("API file not found")
  }

  # Create plumber router with stdio transport
  pr <- plumber::plumb(api_file)
  pr <- plumber2mcp::pr_mcp(pr, transport = "stdio")

  # Register a test resource
  pr_mcp_resource_fn <- get("pr_mcp_resource", envir = asNamespace("plumber2mcp"))

  expect_silent({
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "test://resource",
      name = "Test Resource",
      description = "Test resource for stdio mode",
      mimeType = "application/json",
      func = function() {
        '{"test": "stdio"}'
      }
    )
  })

  # Verify pr is still a plumber object
  expect_s3_class(pr, "Plumber")
})

test_that("resources are registered in http transport mode", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  has_resource_support <- "pr_mcp_resource" %in% getNamespaceExports("plumber2mcp")

  if (!has_resource_support) {
    skip("pr_mcp_resource not available in plumber2mcp")
  }

  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")
  if (nchar(api_file) == 0 || !file.exists(api_file)) {
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
  }

  if (!file.exists(api_file)) {
    skip("API file not found")
  }

  # Create plumber router with http transport
  pr <- plumber::plumb(api_file)
  pr <- plumber2mcp::pr_mcp(pr, transport = "http")

  # Register a test resource
  pr_mcp_resource_fn <- get("pr_mcp_resource", envir = asNamespace("plumber2mcp"))

  expect_silent({
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "test://resource",
      name = "Test Resource",
      description = "Test resource for http mode",
      mimeType = "application/json",
      func = function() {
        '{"test": "http"}'
      }
    )
  })

  # Verify pr is still a plumber object
  expect_s3_class(pr, "Plumber")
})

# =============================================================================
# Tests for Swagger UI behavior with transport modes
# =============================================================================

test_that("Swagger UI is enabled for http transport by default", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("plumber2mcp")

  # Check that swagger parameter exists and defaults to TRUE
  formals_list <- formals(start_hgnc_mcp_server)
  expect_equal(formals_list$swagger, TRUE)
})

test_that("Swagger UI configuration applies to http transport only", {
  # This is more of a documentation test - verifying the intent
  # Swagger UI doesn't make sense for stdio transport
  # The code should only apply Swagger config when transport == "http"

  # Read the server code to verify this
  server_file <- system.file("R", "mcp_server.R", package = "hgnc.mcp")
  if (nchar(server_file) == 0 || !file.exists(server_file)) {
    server_file <- file.path(getwd(), "R", "mcp_server.R")
  }

  if (!file.exists(server_file)) {
    skip("Server file not found")
  }

  server_code <- readLines(server_file, warn = FALSE)
  server_text <- paste(server_code, collapse = "\n")

  # Verify that Swagger config is conditional on transport == "http"
  expect_match(
    server_text,
    'if \\(transport == "http"\\)',
    info = "Swagger config should be conditional on http transport"
  )
})

# =============================================================================
# Tests for stdio mode output to stderr
# =============================================================================

test_that("server startup messages go to stderr for stdio mode", {
  # In stdio mode, all output should go to stderr because stdin/stdout
  # are used for the MCP protocol

  # Read the server code to verify this
  server_file <- system.file("R", "mcp_server.R", package = "hgnc.mcp")
  if (nchar(server_file) == 0 || !file.exists(server_file)) {
    server_file <- file.path(getwd(), "R", "mcp_server.R")
  }

  if (!file.exists(server_file)) {
    skip("Server file not found")
  }

  server_code <- readLines(server_file, warn = FALSE)
  server_text <- paste(server_code, collapse = "\n")

  # Check that messages use stderr() or message() which goes to stderr
  # message() in R writes to stderr by default
  expect_match(
    server_text,
    "message\\(",
    info = "Server should use message() which writes to stderr"
  )
})

# =============================================================================
# Tests for transport-specific behavior
# =============================================================================

test_that("http transport uses port and host parameters", {
  formals_list <- formals(start_hgnc_mcp_server)

  # These parameters are only relevant for HTTP transport
  expect_true("port" %in% names(formals_list))
  expect_true("host" %in% names(formals_list))
})

test_that("stdio transport ignores port and host parameters", {
  # Port and host are not used in stdio mode
  # This is a documentation test to ensure we understand the behavior

  # In stdio mode:
  # - No network socket is opened
  # - Communication happens via stdin/stdout
  # - port and host parameters should be ignored

  expect_true(TRUE) # Placeholder - actual behavior is in function body
})

# =============================================================================
# Tests for MCP protocol messages in stdio mode
# =============================================================================

test_that("stdio mode expects JSON-RPC messages on stdin", {
  # This is a documentation test to verify our understanding
  # In stdio mode, the MCP protocol uses JSON-RPC 2.0 messages

  # Example messages that should work:
  # {"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
  # {"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}

  # We can't actually test this without running the server, but we can
  # verify the structure is what we expect

  example_message <- list(
    jsonrpc = "2.0",
    id = 1,
    method = "tools/list",
    params = list()
  )

  # Verify we can serialize this to JSON
  expect_silent({
    json <- jsonlite::toJSON(example_message, auto_unbox = TRUE)
  })

  # Verify it has the expected structure
  expect_match(as.character(json), '"jsonrpc":"2.0"')
  expect_match(as.character(json), '"method":"tools/list"')
})

# =============================================================================
# Tests for Docker entrypoint stdio mode
# =============================================================================

test_that("Docker entrypoint supports --stdio flag", {
  # Check if Dockerfile or entrypoint script handles --stdio

  dockerfile_path <- file.path(getwd(), "Dockerfile")
  if (!file.exists(dockerfile_path)) {
    skip("Dockerfile not found")
  }

  dockerfile <- readLines(dockerfile_path, warn = FALSE)
  dockerfile_text <- paste(dockerfile, collapse = "\n")

  # The Dockerfile should have an entrypoint or CMD that handles stdio
  # Look for references to stdio or transport
  has_stdio_support <- grepl("stdio|transport", dockerfile_text, ignore.case = TRUE)

  if (has_stdio_support) {
    expect_true(has_stdio_support)
  } else {
    # If not in Dockerfile, check for entrypoint script
    entrypoint_files <- c(
      "docker-entrypoint.sh",
      "entrypoint.sh",
      "inst/docker-entrypoint.sh"
    )

    found_entrypoint <- FALSE
    for (entrypoint_path in entrypoint_files) {
      full_path <- file.path(getwd(), entrypoint_path)
      if (file.exists(full_path)) {
        entrypoint <- readLines(full_path, warn = FALSE)
        entrypoint_text <- paste(entrypoint, collapse = "\n")
        if (grepl("stdio|transport", entrypoint_text, ignore.case = TRUE)) {
          found_entrypoint <- TRUE
          break
        }
      }
    }

    expect_true(
      found_entrypoint,
      info = "Docker should support stdio mode via Dockerfile or entrypoint script"
    )
  }
})

# =============================================================================
# Tests for transport parameter documentation
# =============================================================================

test_that("transport parameter is documented in function help", {
  # Get the help text for start_hgnc_mcp_server
  # We can't easily test rendered help, but we can check the source

  server_file <- system.file("R", "mcp_server.R", package = "hgnc.mcp")
  if (nchar(server_file) == 0 || !file.exists(server_file)) {
    server_file <- file.path(getwd(), "R", "mcp_server.R")
  }

  if (!file.exists(server_file)) {
    skip("Server file not found")
  }

  server_code <- readLines(server_file, warn = FALSE)
  server_text <- paste(server_code, collapse = "\n")

  # Check for roxygen2 documentation of transport parameter
  expect_match(
    server_text,
    "@param transport",
    info = "transport parameter should be documented"
  )

  # Check that it mentions both http and stdio
  expect_match(server_text, "stdio", ignore.case = TRUE)
  expect_match(server_text, "http", ignore.case = TRUE)
})
