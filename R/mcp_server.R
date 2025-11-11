#' Start HGNC MCP Server
#'
#' Initialize and start the HGNC MCP (Model Context Protocol) server using
#' the plumber2mcp integration. This exposes HGNC nomenclature tools through
#' the MCP protocol for use by LLM copilots and other MCP clients.
#'
#' @param port Integer. Port number to run the server on (default: 8080).
#'   Only used when transport is "http".
#' @param host Character. Host address to bind to (default: "0.0.0.0").
#'   Only used when transport is "http".
#' @param transport Character. Transport mode: "http" for HTTP/SSE transport
#'   or "stdio" for standard input/output (default: "http"). Use "stdio" for
#'   desktop clients like Claude Desktop.
#' @param swagger Logical. Whether to enable Swagger UI documentation
#'   (default: TRUE). Only used when transport is "http".
#' @param quiet Logical. If TRUE, suppress startup messages (default: FALSE)
#' @param ... Additional arguments passed to `pr$run()` (for HTTP transport)
#'
#' @return The plumber router object (invisibly), for advanced use cases
#'
#' @details
#' The function performs the following steps:
#' 1. Loads the Plumber API definition from `inst/plumber/hgnc_api.R`
#' 2. Registers MCP prompts (workflow templates) for common HGNC tasks
#' 3. Applies MCP integration via `plumber2mcp::pr_mcp()`
#' 4. Starts the server on the specified port
#' 5. Prints connection information
#'
#' The server exposes HGNC functionality through three MCP primitives:
#' - **Tools**: API endpoints for actions (search, normalize, validate)
#' - **Resources**: Read-only data for context injection (gene cards, metadata)
#' - **Prompts**: Workflow templates for multi-step tasks (normalization, compliance)
#'
#' This makes them available to MCP clients like Claude Desktop, VS Code with
#' MCP extensions, and other compatible applications.
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
#' @section Available Resources:
#' The MCP server provides the following resources for context injection:
#' - `get_gene_card`: Formatted gene cards (JSON/markdown/text)
#' - `get_group_card`: Gene group information with members
#' - `get_changes_summary`: Nomenclature changes since a date
#' - `snapshot`: Static resource with dataset metadata
#'
#' Resources provide read-only data that can be injected into LLM context
#' for enhanced understanding of genes, groups, and nomenclature changes.
#'
#' @section Available Prompts:
#' The MCP server provides the following workflow template prompts:
#' - `normalize-gene-list`: Guide through normalizing gene symbols to HGNC
#' - `check-nomenclature-compliance`: Validate gene panels against HGNC policy
#' - `what-changed-since`: Generate human-readable nomenclature change reports
#' - `build-gene-set-from-group`: Build gene sets from HGNC gene groups
#'
#' Prompts provide structured guidance for multi-step workflows, helping AI
#' assistants understand how to use multiple tools together to accomplish
#' complex nomenclature tasks.
#'
#' @section MCP Client Configuration:
#' For HTTP transport, add to your MCP configuration file:
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
#' For stdio transport (recommended for desktop clients), use:
#'
#' ```json
#' {
#'   "mcpServers": {
#'     "hgnc": {
#'       "command": "Rscript",
#'       "args": ["-e", "hgnc.mcp::start_hgnc_mcp_server(transport='stdio')"]
#'     }
#'   }
#' }
#' ```
#'
#' @examples
#' \dontrun{
#' # Start server with stdio transport (for Claude Desktop)
#' start_hgnc_mcp_server(transport = "stdio")
#'
#' # Start HTTP server on default port 8080
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
start_hgnc_mcp_server <- function(
  port = 8080,
  host = "0.0.0.0",
  transport = "http",
  swagger = TRUE,
  quiet = FALSE,
  ...
) {
  # Validate transport parameter
  if (!transport %in% c("http", "stdio")) {
    stop(
      "Invalid transport mode '", transport, "'. ",
      "Must be 'http' or 'stdio'."
    )
  }
  # Load required packages
  if (!requireNamespace("plumber", quietly = TRUE)) {
    stop(
      "Package 'plumber' is required but not installed. ",
      "Install it with: install.packages('plumber')"
    )
  }

  if (!requireNamespace("plumber2mcp", quietly = TRUE)) {
    stop(
      "Package 'plumber2mcp' is required but not installed. ",
      "Install it with: remotes::install_github('armish/plumber2mcp')"
    )
  }

  # Locate the Plumber API file
  api_file <- system.file("plumber", "hgnc_api.R", package = "hgnc.mcp")

  if (!file.exists(api_file) || nchar(api_file) == 0) {
    # Try local path if package not installed
    api_file <- file.path(getwd(), "inst", "plumber", "hgnc_api.R")
    if (!file.exists(api_file)) {
      stop(
        "Could not locate HGNC Plumber API file. ",
        "Please ensure the package is properly installed."
      )
    }
  }

  if (!quiet) {
    message("Loading HGNC Plumber API from: ", api_file)
  }

  # Create the Plumber router
  pr <- plumber::plumb(api_file)

  # Register MCP Prompts (workflow templates)
  # Note: pr_mcp_prompt is available in plumber2mcp but not yet exported in NAMESPACE
  # TODO: Uncomment when plumber2mcp NAMESPACE is updated to export pr_mcp_prompt
  if (!quiet) {
    message("Checking for MCP prompts support...")
  }

  # Check if pr_mcp_prompt is available (conditionally register prompts)
  has_prompt_support <- "pr_mcp_prompt" %in% getNamespaceExports("plumber2mcp")

  if (has_prompt_support) {
    if (!quiet) {
      message("Registering MCP prompts...")
    }

    # Get the pr_mcp_prompt function dynamically to avoid R CMD check warnings
    pr_mcp_prompt_fn <- get("pr_mcp_prompt", envir = asNamespace("plumber2mcp"))

    # Prompt 1: Normalize Gene List
    pr <- pr_mcp_prompt_fn(
      pr,
      name = "normalize-gene-list",
      description = "Guide through normalizing a gene symbol list to approved HGNC nomenclature. Helps with batch symbol resolution, handling aliases/previous symbols, and optionally fetching cross-references.",
      arguments = list(
        list(
          name = "gene_list",
          description = "Comma-separated or newline-separated list of gene symbols to normalize",
          required = TRUE
        ),
        list(
          name = "strictness",
          description = "Resolution mode: 'lenient' (allows aliases/prev symbols) or 'strict' (approved only)",
          required = FALSE
        ),
        list(
          name = "return_xrefs",
          description = "Whether to include cross-references (Entrez, Ensembl, etc.) - true/false",
          required = FALSE
        )
      ),
      func = function(
        gene_list = "",
        strictness = "lenient",
        return_xrefs = FALSE
      ) {
        prompt_normalize_gene_list(gene_list, strictness, return_xrefs)
      }
    )

    # Prompt 2: Check Nomenclature Compliance
    pr <- pr_mcp_prompt_fn(
      pr,
      name = "check-nomenclature-compliance",
      description = "Validate a gene panel against HGNC nomenclature policy. Identifies non-approved symbols, withdrawn genes, duplicates, and provides replacement suggestions with rationale.",
      arguments = list(
        list(
          name = "panel_text",
          description = "Gene panel as text (symbols separated by commas, newlines, etc.)",
          required = FALSE
        ),
        list(
          name = "file_uri",
          description = "URI to a file containing the gene panel (alternative to panel_text)",
          required = FALSE
        )
      ),
      func = function(panel_text = "", file_uri = NULL) {
        prompt_check_nomenclature_compliance(panel_text, file_uri)
      }
    )

    # Prompt 3: What Changed Since
    pr <- pr_mcp_prompt_fn(
      pr,
      name = "what-changed-since",
      description = "Generate a human-readable summary of HGNC nomenclature changes since a specific date. Useful for governance, compliance tracking, and watchlist monitoring.",
      arguments = list(
        list(
          name = "since",
          description = "ISO 8601 date (YYYY-MM-DD) from which to track changes. Defaults to 30 days ago if not provided.",
          required = FALSE
        )
      ),
      func = function(since = NULL) {
        prompt_what_changed_since(since)
      }
    )

    # Prompt 4: Build Gene Set from Group
    pr <- pr_mcp_prompt_fn(
      pr,
      name = "build-gene-set-from-group",
      description = "Discover an HGNC gene group by keyword search and build a reusable gene set definition from its members. Provides output in multiple formats (list, table, JSON) with metadata for reproducibility.",
      arguments = list(
        list(
          name = "group_query",
          description = "Search query for finding gene groups (e.g., 'kinase', 'zinc finger', 'immunoglobulin')",
          required = TRUE
        )
      ),
      func = function(group_query = "") {
        prompt_build_gene_set_from_group(group_query)
      }
    )
  } else {
    if (!quiet) {
      message(
        "Note: MCP prompts not available yet (pr_mcp_prompt not exported in plumber2mcp)"
      )
      message(
        "      Prompts will be enabled automatically when plumber2mcp is updated."
      )
    }
  }

  # Register MCP Resources BEFORE applying MCP integration
  # This is important because pr_mcp() may transform the router object
  if (!quiet) {
    message("Registering MCP resources...")
  }

  # Check if pr_mcp_resource is available
  has_resource_support <- "pr_mcp_resource" %in% getNamespaceExports("plumber2mcp")

  if (has_resource_support) {
    # Get the pr_mcp_resource function dynamically
    pr_mcp_resource_fn <- get("pr_mcp_resource", envir = asNamespace("plumber2mcp"))

    # Resource 1: Snapshot metadata (static)
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "hgnc://snapshot",
      name = "HGNC Dataset Snapshot",
      description = "Metadata about the currently cached HGNC dataset including version, download date, and statistics",
      mimeType = "application/json",
      func = function() {
        result <- hgnc_get_snapshot_metadata(format = "json")
        # Return the content as JSON string
        jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE)
      }
    )

    # Resource 2: Gene card (parameterized by URI)
    # Note: MCP resources with parameters use URI templates
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "hgnc://gene/{hgnc_id}",
      name = "HGNC Gene Card",
      description = "Detailed gene information card including symbol, name, location, aliases, cross-references, and group memberships",
      mimeType = "application/json",
      func = function(hgnc_id) {
        result <- hgnc_get_gene_card(hgnc_id = hgnc_id, format = "json")
        jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE)
      }
    )

    # Resource 3: Group card (parameterized by URI)
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "hgnc://group/{group_id_or_name}",
      name = "HGNC Gene Group Card",
      description = "Gene group information with member list and metadata",
      mimeType = "application/json",
      func = function(group_id_or_name) {
        result <- hgnc_get_group_card(
          group_id_or_name = group_id_or_name,
          format = "json",
          include_members = TRUE
        )
        jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE)
      }
    )

    # Resource 4: Changes summary (parameterized by URI)
    pr <- pr_mcp_resource_fn(
      pr,
      uri = "hgnc://changes/{since}",
      name = "HGNC Nomenclature Changes",
      description = "Summary of gene nomenclature changes since a specified date",
      mimeType = "application/json",
      func = function(since) {
        result <- hgnc_get_changes_summary(
          since = since,
          format = "json",
          change_type = "all",
          max_results = 100
        )
        jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE)
      }
    )

    if (!quiet) {
      message("Successfully registered 4 MCP resources")
    }
  } else {
    if (!quiet) {
      message(
        "Note: MCP resources not available yet (pr_mcp_resource not exported in plumber2mcp)"
      )
      message(
        "      Resources will be enabled automatically when plumber2mcp is updated."
      )
    }
  }

  # Apply MCP integration AFTER registering resources
  if (!quiet) {
    message(sprintf("Applying MCP integration via plumber2mcp (transport: %s)...", transport))
  }
  pr <- plumber2mcp::pr_mcp(pr, transport = transport)

  # Configure Swagger UI (only for HTTP transport)
  if (transport == "http") {
    if (swagger) {
      pr <- plumber::pr_set_docs(pr, docs = "swagger")
    } else {
      pr <- plumber::pr_set_docs(pr, docs = FALSE)
    }
  }

  # Print startup information
  if (!quiet) {
    cat("\n", file = stderr())
    cat("========================================\n", file = stderr())
    cat("HGNC MCP Server Starting\n", file = stderr())
    cat("========================================\n", file = stderr())
    cat(sprintf("Transport: %s\n", transport), file = stderr())

    if (transport == "http") {
      cat(sprintf("Host:      %s\n", host), file = stderr())
      cat(sprintf("Port:      %d\n", port), file = stderr())
      cat("\n", file = stderr())
      cat("API Endpoints:\n", file = stderr())
      cat(sprintf(
        "  Base URL:     http://%s:%d\n",
        if (host == "0.0.0.0") "localhost" else host,
        port
      ), file = stderr())
      cat(sprintf(
        "  MCP Endpoint: http://%s:%d/mcp\n",
        if (host == "0.0.0.0") "localhost" else host,
        port
      ), file = stderr())
      if (swagger) {
        cat(sprintf(
          "  Swagger UI:   http://%s:%d/__docs__/\n",
          if (host == "0.0.0.0") "localhost" else host,
          port
        ), file = stderr())
      }
    } else {
      cat("Mode:      stdio (standard input/output)\n", file = stderr())
    }

    cat("\n", file = stderr())
    cat("Available Tools: 10\n", file = stderr())
    cat("  - info, find, fetch, resolve_symbol\n", file = stderr())
    cat("  - normalize_list, xrefs\n", file = stderr())
    cat("  - group_members, search_groups\n", file = stderr())
    cat("  - changes, validate_panel\n", file = stderr())
    cat("\n", file = stderr())
    cat("Available Resources: 4\n", file = stderr())
    cat("  - get_gene_card: Gene information cards\n", file = stderr())
    cat("  - get_group_card: Gene group information\n", file = stderr())
    cat("  - get_changes_summary: Nomenclature changes log\n", file = stderr())
    cat("  - snapshot: Dataset metadata (static)\n", file = stderr())
    cat("\n", file = stderr())
    if (has_prompt_support) {
      cat("Available Prompts: 4\n", file = stderr())
      cat("  - normalize-gene-list: Normalize gene symbols to HGNC\n", file = stderr())
      cat("  - check-nomenclature-compliance: Validate gene panels\n", file = stderr())
      cat("  - what-changed-since: Track nomenclature changes\n", file = stderr())
      cat("  - build-gene-set-from-group: Create gene sets from groups\n", file = stderr())
    } else {
      cat("Available Prompts: 0\n", file = stderr())
      cat("  (Prompts pending plumber2mcp update)\n", file = stderr())
    }
    cat("\n", file = stderr())

    if (transport == "http") {
      cat("MCP Client Configuration:\n", file = stderr())
      cat("  Add to your MCP config file:\n", file = stderr())
      cat("  {\n", file = stderr())
      cat('    "mcpServers": {\n', file = stderr())
      cat('      "hgnc": {\n', file = stderr())
      cat(sprintf('        "url": "http://localhost:%d/mcp"\n', port), file = stderr())
      cat('      }\n', file = stderr())
      cat('    }\n', file = stderr())
      cat("  }\n", file = stderr())
      cat("\n", file = stderr())
      cat("Press Ctrl+C to stop the server\n", file = stderr())
    } else {
      cat("Ready for stdio communication.\n", file = stderr())
      cat("Use this with MCP clients like Claude Desktop.\n", file = stderr())
    }

    cat("========================================\n", file = stderr())
    cat("\n", file = stderr())
  }

  # Start the server based on transport mode
  if (transport == "http") {
    # Start HTTP server
    pr$run(
      host = host,
      port = port,
      ...
    )
  } else {
    # For stdio, plumber2mcp modifies pr$run() to handle stdio transport
    # Call pr$run() which will start the stdio event loop
    if (!quiet) {
      message("Starting stdio server...")
    }
    pr$run()
  }

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
      message(sprintf("[X] Missing: %s", dep$package))
      message(sprintf("    Install with: %s", dep$install))
    } else {
      message(sprintf("[OK] Found: %s", dep$package))
    }
  }

  if (all_ok) {
    message("\n[OK] All MCP server dependencies are installed!")
  } else {
    message(
      "\n[X] Some dependencies are missing. Please install them to run the MCP server."
    )
  }

  invisible(all_ok)
}
