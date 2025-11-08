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
#   --port PORT          Port number to run the server on (default: 8080)
#   --host HOST          Host address to bind to (default: 0.0.0.0)
#   --no-swagger         Disable Swagger UI documentation
#   --check-cache        Check and download HGNC cache if needed before starting
#   --update-cache       Force update of HGNC cache before starting
#   --quiet              Suppress startup messages
#   --help               Show this help message
#
# Examples:
#   # Start on default port 8080
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
  cat("HGNC MCP Server Launcher\n\n")
  cat("Usage:\n")
  cat("  Rscript inst/scripts/run_server.R [options]\n\n")
  cat("Options:\n")
  cat("  --port PORT          Port number (default: 8080)\n")
  cat("  --host HOST          Host address (default: 0.0.0.0)\n")
  cat("  --no-swagger         Disable Swagger UI\n")
  cat("  --check-cache        Check/download HGNC cache if needed\n")
  cat("  --update-cache       Force update HGNC cache\n")
  cat("  --quiet, -q          Suppress startup messages\n")
  cat("  --help, -h           Show this help message\n\n")
  cat("Examples:\n")
  cat("  Rscript inst/scripts/run_server.R\n")
  cat("  Rscript inst/scripts/run_server.R --port 9090 --update-cache\n")
  cat("  Rscript inst/scripts/run_server.R --no-swagger\n\n")
  quit(status = 0)
}

# Load the hgnc.mcp package
if (!quiet) {
  cat("Loading hgnc.mcp package...\n")
}

tryCatch(
  {
    library(hgnc.mcp)
  },
  error = function(e) {
    cat("Error: Could not load hgnc.mcp package.\n")
    cat("Make sure the package is installed and in your library path.\n")
    cat("\nYou can install it with:\n")
    cat("  install.packages('devtools')\n")
    cat("  devtools::install()\n")
    quit(status = 1)
  }
)

# Handle cache operations if requested
if (update_cache || check_cache) {
  if (!quiet) {
    cat("\nManaging HGNC data cache...\n")
  }

  if (update_cache) {
    if (!quiet) {
      cat("Forcing cache update...\n")
    }
    tryCatch(
      {
        hgnc.mcp::download_hgnc_data(force = TRUE, verbose = !quiet)
        if (!quiet) {
          cat("[OK] Cache updated successfully\n\n")
        }
      },
      error = function(e) {
        cat("[X] Failed to update cache:", e$message, "\n")
        cat(
          "The server will start anyway and attempt to use existing cache.\n\n"
        )
      }
    )
  } else if (check_cache) {
    if (!quiet) {
      cat("Checking cache status...\n")
    }
    tryCatch(
      {
        # Try to load data; this will download if missing
        data <- hgnc.mcp::load_hgnc_data(verbose = !quiet)
        if (!quiet) {
          cat(sprintf("[OK] Cache available with %d genes\n\n", nrow(data)))
        }
      },
      error = function(e) {
        cat("[X] Failed to load cache:", e$message, "\n")
        cat("Warning: Some tools may not work without cached data.\n\n")
      }
    )
  }
}

# Check dependencies
if (!quiet) {
  cat("Checking MCP server dependencies...\n")
  hgnc.mcp::check_mcp_dependencies()
  cat("\n")
}

# Start the server
tryCatch(
  {
    hgnc.mcp::start_hgnc_mcp_server(
      port = port,
      host = host,
      swagger = swagger,
      quiet = quiet
    )
  },
  error = function(e) {
    cat("\n[X] Failed to start MCP server:\n")
    cat("  ", e$message, "\n\n")

    # Provide helpful troubleshooting info
    cat("Troubleshooting:\n")
    cat("  1. Check if the port is already in use\n")
    cat(
      "  2. Ensure all dependencies are installed (run check_mcp_dependencies())\n"
    )
    cat("  3. Check the logs above for specific error messages\n")

    quit(status = 1)
  }
)
