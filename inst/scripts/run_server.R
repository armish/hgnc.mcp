#!/usr/bin/env Rscript
#
# HGNC MCP Server Launcher
#
# Standalone script to start the HGNC MCP server with command-line configuration
#
# Usage:
#   Rscript inst/scripts/run_server.R [options]
#
# Options:
#   --stdio              Use stdio transport (for Claude Desktop, etc.)
#   --port PORT          Port number to run the server on (default: 8080, HTTP only)
#   --host HOST          Host address to bind to (default: 0.0.0.0, HTTP only)
#   --no-swagger         Disable Swagger UI documentation (HTTP only)
#   --check-cache        Check and download HGNC cache if needed before starting
#   --update-cache       Force update of HGNC cache before starting
#   --quiet              Suppress startup messages
#   --help               Show this help message
#
# Examples:
#   # Start with stdio transport (for Claude Desktop)
#   Rscript inst/scripts/run_server.R --stdio
#
#   # Start HTTP server on default port 8080
#   Rscript inst/scripts/run_server.R
#
#   # Start on custom port with cache update
#   Rscript inst/scripts/run_server.R --port 9090 --update-cache
#
#   # Start without Swagger UI
#   Rscript inst/scripts/run_server.R --no-swagger
#

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default values
transport <- "http" # or "stdio"
port <- 8080
host <- "0.0.0.0"
swagger <- TRUE
check_cache <- FALSE
update_cache <- FALSE
quiet <- FALSE
show_help <- FALSE

# Parse arguments
i <- 1
while (i <= length(args)) {
  arg <- args[i]

  if (arg == "--help" || arg == "-h") {
    show_help <- TRUE
    break
  } else if (arg == "--stdio") {
    transport <- "stdio"
  } else if (arg == "--port") {
    i <- i + 1
    if (i > length(args)) {
      stop("--port requires a value")
    }
    port <- as.integer(args[i])
    if (is.na(port) || port < 1 || port > 65535) {
      stop("Invalid port number. Must be between 1 and 65535")
    }
  } else if (arg == "--host") {
    i <- i + 1
    if (i > length(args)) {
      stop("--host requires a value")
    }
    host <- args[i]
  } else if (arg == "--no-swagger") {
    swagger <- FALSE
  } else if (arg == "--check-cache") {
    check_cache <- TRUE
  } else if (arg == "--update-cache") {
    update_cache <- TRUE
  } else if (arg == "--quiet" || arg == "-q") {
    quiet <- TRUE
  } else {
    stop(sprintf("Unknown option: %s\nUse --help for usage information", arg))
  }

  i <- i + 1
}

# Show help if requested
if (show_help) {
  cat("HGNC MCP Server Launcher\n\n", file = stderr())
  cat("Usage:\n", file = stderr())
  cat("  Rscript inst/scripts/run_server.R [options]\n\n", file = stderr())
  cat("Options:\n", file = stderr())
  cat(
    "  --stdio              Use stdio transport (for Claude Desktop, etc.)\n",
    file = stderr()
  )
  cat(
    "  --port PORT          Port number (default: 8080, HTTP only)\n",
    file = stderr()
  )
  cat(
    "  --host HOST          Host address (default: 0.0.0.0, HTTP only)\n",
    file = stderr()
  )
  cat(
    "  --no-swagger         Disable Swagger UI (HTTP only)\n",
    file = stderr()
  )
  cat(
    "  --check-cache        Check/download HGNC cache if needed\n",
    file = stderr()
  )
  cat("  --update-cache       Force update HGNC cache\n", file = stderr())
  cat("  --quiet, -q          Suppress startup messages\n", file = stderr())
  cat("  --help, -h           Show this help message\n\n", file = stderr())
  cat("Examples:\n", file = stderr())
  cat("  Rscript inst/scripts/run_server.R --stdio\n", file = stderr())
  cat("  Rscript inst/scripts/run_server.R\n", file = stderr())
  cat(
    "  Rscript inst/scripts/run_server.R --port 9090 --update-cache\n",
    file = stderr()
  )
  cat("  Rscript inst/scripts/run_server.R --no-swagger\n\n", file = stderr())
  quit(status = 0)
}

# Load the hgnc.mcp package
if (!quiet) {
  cat("Loading hgnc.mcp package...\n", file = stderr())
}

tryCatch(
  {
    library(hgnc.mcp)
  },
  error = function(e) {
    cat("Error: Could not load hgnc.mcp package.\n", file = stderr())
    cat(
      "Make sure the package is installed and in your library path.\n",
      file = stderr()
    )
    cat("\nYou can install it with:\n", file = stderr())
    cat("  install.packages('devtools')\n", file = stderr())
    cat("  devtools::install()\n", file = stderr())
    quit(status = 1)
  }
)

# Handle cache operations if requested
if (update_cache || check_cache) {
  if (!quiet) {
    cat("\nManaging HGNC data cache...\n", file = stderr())
  }

  if (update_cache) {
    if (!quiet) {
      cat("Forcing cache update...\n", file = stderr())
    }
    tryCatch(
      {
        hgnc.mcp::download_hgnc_data(force = TRUE, verbose = !quiet)
        if (!quiet) {
          cat("[OK] Cache updated successfully\n\n", file = stderr())
        }
      },
      error = function(e) {
        cat("[X] Failed to update cache:", e$message, "\n", file = stderr())
        cat(
          "The server will start anyway and attempt to use existing cache.\n\n",
          file = stderr()
        )
      }
    )
  } else if (check_cache) {
    if (!quiet) {
      cat("Checking cache status...\n", file = stderr())
    }
    tryCatch(
      {
        # Try to load data; this will download if missing
        data <- hgnc.mcp::load_hgnc_data(verbose = !quiet)
        if (!quiet) {
          cat(
            sprintf("[OK] Cache available with %d genes\n\n", nrow(data)),
            file = stderr()
          )
        }
      },
      error = function(e) {
        cat("[X] Failed to load cache:", e$message, "\n", file = stderr())
        cat(
          "Warning: Some tools may not work without cached data.\n\n",
          file = stderr()
        )
      }
    )
  }
}

# Check dependencies
if (!quiet) {
  cat("Checking MCP server dependencies...\n", file = stderr())
  hgnc.mcp::check_mcp_dependencies()
  cat("\n", file = stderr())
}

# Start the server
tryCatch(
  {
    hgnc.mcp::start_hgnc_mcp_server(
      port = port,
      host = host,
      transport = transport,
      swagger = swagger,
      quiet = quiet
    )
  },
  error = function(e) {
    cat("\n[X] Failed to start MCP server:\n", file = stderr())
    cat("  ", e$message, "\n\n", file = stderr())

    # Provide helpful troubleshooting info
    cat("Troubleshooting:\n", file = stderr())
    if (transport == "http") {
      cat("  1. Check if the port is already in use\n", file = stderr())
    }
    cat(
      "  2. Ensure all dependencies are installed (run check_mcp_dependencies())\n",
      file = stderr()
    )
    cat(
      "  3. Check the logs above for specific error messages\n",
      file = stderr()
    )

    quit(status = 1)
  }
)
