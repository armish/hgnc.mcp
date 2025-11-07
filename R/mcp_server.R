#' Start HGNC MCP Server
#'
#' Initialize and start the HGNC MCP (Model Context Protocol) server using
#' the plumber2mcp integration. This exposes HGNC nomenclature tools through
#' the MCP protocol for use by LLM copilots and other MCP clients.
#'
#' @param port Integer. Port number to run the server on (default: 8080)
#' @param host Character. Host address to bind to (default: "0.0.0.0")
#' @param swagger Logical. Whether to enable Swagger UI documentation
#'   (default: TRUE)
#' @param quiet Logical. If TRUE, suppress startup messages (default: FALSE)
#' @param ... Additional arguments passed to `pr$run()`
#'
#' @return The plumber router object (invisibly), for advanced use cases
#'
#' @details
#' The function performs the following steps:
#' 1. Loads the Plumber API definition from `inst/plumber/hgnc_api.R`
#' 2. Applies MCP integration via `plumber2mcp::pr_mcp()`
#' 3. Starts the server on the specified port
#' 4. Prints connection information
#'
#' The server exposes all HGNC tools as MCP tools, making them available
#' to MCP clients like Claude Desktop, VS Code with MCP extensions, and
#' other compatible applications.
#'
#' @section Available Tools:
#' The MCP server provides the following tools:
#' - `info`: Get HGNC REST API metadata
#' - `find`: Search for genes by query
#' - `fetch`: Fetch gene records by field value
#' - `resolve_symbol`: Resolve symbols to approved HGNC symbols
#' - `normalize_list`: Batch normalize gene symbol lists
#' - `xrefs`: Extract cross-references from gene records
#' - `group_members`: Get members of a gene group
#' - `search_groups`: Search for gene groups
#' - `changes`: Track nomenclature changes since a date
#' - `validate_panel`: Validate gene panels against HGNC policy
#'
#' @section MCP Client Configuration:
#' To connect an MCP client (e.g., Claude Desktop), add the following to
#' your MCP configuration file:
#'
#' ```json
#' {
#'   "mcpServers": {
#'     "hgnc": {
#'       "url": "http://localhost:8080/mcp"
#'     }
#'   }
#' }
#' ```
#'
#' @examples
#' \dontrun{
#' # Start server on default port 8080
#' start_hgnc_mcp_server()
#'
#' # Start on custom port
#' start_hgnc_mcp_server(port = 9090)
#'
#' # Start without Swagger UI
#' start_hgnc_mcp_server(swagger = FALSE)
#'
#' # For programmatic use, capture the plumber object
#' pr <- start_hgnc_mcp_server(quiet = TRUE)
#' # ... do something with pr ...
#' pr$stop()
#' }
#'
#' @export
start_hgnc_mcp_server <- function(port = 8080,
                                   host = "0.0.0.0",
                                   swagger = TRUE,
                                   quiet = FALSE,
                                   ...) {
  # Load required packages
  if (!requireNamespace("plumber", quietly = TRUE)) {
    stop("Package 'plumber' is required but not installed. ",
         "Install it with: install.packages('plumber')")
  }

  if (!requireNamespace("plumber2mcp", quietly = TRUE)) {
    stop("Package 'plumber2mcp' is required but not installed. ",
         "Install it with: remotes::install_github('armish/plumber2mcp')")
  }

  # Locate the Plumber API file
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (!file.exists(api_file) || nchar(api_file) == 0) {
    # Try local path if package not installed
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
    if (!file.exists(api_file)) {
      stop("Could not locate HGNC Plumber API file. ",
           "Please ensure the package is properly installed.")
    }
  }

  if (!quiet) {
    message("Loading HGNC Plumber API from: ", api_file)
  }

  # Create the Plumber router
  pr <- plumber::plumb(api_file)

  # Apply MCP integration
  if (!quiet) {
    message("Applying MCP integration via plumber2mcp...")
  }
  pr <- plumber2mcp::pr_mcp(pr)

  # Configure Swagger UI
  if (swagger) {
    pr <- plumber::pr_set_docs(pr, docs = "swagger")
  } else {
    pr <- plumber::pr_set_docs(pr, docs = FALSE)
  }

  # Print startup information
  if (!quiet) {
    cat("\n")
    cat("========================================\n")
    cat("HGNC MCP Server Starting\n")
    cat("========================================\n")
    cat(sprintf("Host:    %s\n", host))
    cat(sprintf("Port:    %d\n", port))
    cat("\n")
    cat("API Endpoints:\n")
    cat(sprintf("  Base URL:    http://%s:%d\n",
                if (host == "0.0.0.0") "localhost" else host, port))
    cat(sprintf("  MCP Endpoint: http://%s:%d/mcp\n",
                if (host == "0.0.0.0") "localhost" else host, port))
    if (swagger) {
      cat(sprintf("  Swagger UI:  http://%s:%d/__docs__/\n",
                  if (host == "0.0.0.0") "localhost" else host, port))
    }
    cat("\n")
    cat("Available Tools: 10\n")
    cat("  - info, find, fetch, resolve_symbol\n")
    cat("  - normalize_list, xrefs\n")
    cat("  - group_members, search_groups\n")
    cat("  - changes, validate_panel\n")
    cat("\n")
    cat("MCP Client Configuration:\n")
    cat("  Add to your MCP config file:\n")
    cat("  {\n")
    cat('    "mcpServers": {\n')
    cat('      "hgnc": {\n')
    cat(sprintf('        "url": "http://localhost:%d/mcp"\n', port))
    cat('      }\n')
    cat('    }\n')
    cat("  }\n")
    cat("\n")
    cat("Press Ctrl+C to stop the server\n")
    cat("========================================\n")
    cat("\n")
  }

  # Start the server
  pr$run(
    host = host,
    port = port,
    ...
  )

  invisible(pr)
}


#' Check MCP Server Dependencies
#'
#' Verify that all required packages for running the MCP server are installed
#' and provide installation instructions if any are missing.
#'
#' @return Logical. TRUE if all dependencies are available, FALSE otherwise
#'
#' @examples
#' check_mcp_dependencies()
#'
#' @export
check_mcp_dependencies <- function() {
  dependencies <- list(
    plumber = list(
      package = "plumber",
      install = "install.packages('plumber')"
    ),
    plumber2mcp = list(
      package = "plumber2mcp",
      install = "remotes::install_github('armish/plumber2mcp')"
    )
  )

  all_ok <- TRUE
  missing <- character(0)

  for (dep_name in names(dependencies)) {
    dep <- dependencies[[dep_name]]
    if (!requireNamespace(dep$package, quietly = TRUE)) {
      all_ok <- FALSE
      missing <- c(missing, dep_name)
      message(sprintf("✗ Missing: %s", dep$package))
      message(sprintf("  Install with: %s", dep$install))
    } else {
      message(sprintf("✓ Found: %s", dep$package))
    }
  }

  if (all_ok) {
    message("\n✓ All MCP server dependencies are installed!")
  } else {
    message("\n✗ Some dependencies are missing. Please install them to run the MCP server.")
  }

  invisible(all_ok)
}
