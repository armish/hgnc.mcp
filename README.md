# hgnc.mcp

MCP (Model Context Protocol) Server for HGNC (HUGO Gene Nomenclature Committee) Gene Nomenclature Resources.

## Overview

This R package provides tools for accessing HGNC gene nomenclature data, including functions for searching, resolving, and validating gene symbols. It also includes an MCP (Model Context Protocol) server that exposes these tools to LLM copilots and other MCP-compatible clients.

## Installation

```r
# Install from GitHub (once available)
# remotes::install_github("yourusername/hgnc.mcp")
```

## Data Management

The package uses smart caching to manage the HGNC complete dataset:

- **First use**: Downloads data from the official HGNC source and caches it locally
- **Subsequent uses**: Loads from cache for fast access
- **Updates**: Automatically checks if cache is stale (default: 30 days) and refreshes if needed

### Data Functions

```r
# Load HGNC data (downloads and caches on first use)
hgnc <- load_hgnc_data()

# Check cache status
get_hgnc_cache_info()

# Force refresh the cache
hgnc <- load_hgnc_data(force = TRUE)

# Or explicitly download
download_hgnc_data(force = TRUE)

# Clear cache
clear_hgnc_cache()

# Check if cache is fresh (default: 30 days)
is_hgnc_cache_fresh()
is_hgnc_cache_fresh(max_age_days = 7)
```

### Cache Location

Cache is stored in a platform-appropriate location:
- **Linux**: `~/.cache/hgnc.mcp/`
- **macOS**: `~/Library/Caches/hgnc.mcp/`
- **Windows**: `%LOCALAPPDATA%/hgnc.mcp/Cache/`

## Data Source

HGNC data is sourced from:
https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt

## Features

- Smart local caching with automatic updates
- Cross-platform cache directory management
- Configurable cache freshness (default: 30 days)
- Cache metadata tracking (download time, file size, source URL)
- HGNC REST API client with rate limiting and caching
- Gene symbol search, resolution, and validation tools
- Batch operations for gene lists
- Gene group and family queries
- Change tracking for updated symbols
- **MCP server for integration with LLM copilots and AI tools**

## MCP Server

The package includes a Model Context Protocol (MCP) server that exposes HGNC tools to AI assistants, copilots, and other MCP-compatible clients. This allows LLMs to directly access HGNC nomenclature services for gene name resolution, validation, and more.

### Starting the MCP Server

#### Using R:

```r
# Load the package
library(hgnc.mcp)

# Check dependencies
check_mcp_dependencies()

# Start the server on default port 8080
start_hgnc_mcp_server()

# Or customize the configuration
start_hgnc_mcp_server(
  port = 9090,
  host = "0.0.0.0",
  swagger = TRUE
)
```

#### Using the standalone script:

```bash
# Basic usage
Rscript inst/scripts/run_server.R

# Custom port
Rscript inst/scripts/run_server.R --port 9090

# Update cache before starting
Rscript inst/scripts/run_server.R --update-cache

# Disable Swagger UI
Rscript inst/scripts/run_server.R --no-swagger

# Get help
Rscript inst/scripts/run_server.R --help
```

### MCP Client Configuration

To connect an MCP client (such as Claude Desktop) to the HGNC server, add the following to your MCP configuration file:

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "hgnc": {
      "url": "http://localhost:8080/mcp"
    }
  }
}
```

**Other MCP Clients**: Consult your client's documentation for MCP server configuration.

### Available MCP Tools

The MCP server exposes the following tools:

1. **info** - Get HGNC REST API metadata and capabilities
2. **find** - Search for genes by query across symbols, aliases, and names
3. **fetch** - Fetch complete gene records by field value (HGNC ID, symbol, etc.)
4. **resolve_symbol** - Resolve a gene symbol to the current approved HGNC symbol
5. **normalize_list** - Batch normalize a list of gene symbols (fast, uses local cache)
6. **xrefs** - Extract cross-references (Entrez, Ensembl, UniProt, OMIM, etc.)
7. **group_members** - Get all genes in a specific gene group or family
8. **search_groups** - Search for gene groups by keyword
9. **changes** - Track nomenclature changes since a specific date
10. **validate_panel** - Validate gene panels against HGNC policy with replacement suggestions

### API Documentation

When the server is running with Swagger enabled (default), you can access the interactive API documentation at:

```
http://localhost:8080/__docs__/
```

This provides detailed information about each endpoint, request/response formats, and allows you to test the API directly from your browser.

## Usage Examples

### Basic Gene Lookups

```r
library(hgnc.mcp)

# Search for genes
results <- hgnc_find("BRCA")

# Fetch a specific gene
gene <- hgnc_fetch("symbol", "BRCA1")

# Resolve a symbol (handles aliases and previous symbols)
resolution <- hgnc_resolve_symbol("BRCA1", mode = "lenient")
```

### Batch Operations

```r
# Normalize a list of gene symbols
symbols <- c("BRCA1", "tp53", "EGFR", "OLD_SYMBOL", "invalid")
result <- hgnc_normalize_list(symbols)

# View results
print(result$results)
print(result$summary)
print(result$warnings)
```

### Validation

```r
# Validate a gene panel
panel <- c("BRCA1", "BRCA2", "TP53", "ATM", "CHEK2")
validation <- hgnc_validate_panel(panel)

# Check for issues
print(validation$summary)
print(validation$report)
```

### Change Tracking

```r
# Find genes modified in the last 30 days
recent_changes <- hgnc_changes(since = Sys.Date() - 30)
print(recent_changes$summary)

# Track symbol changes since a specific date
symbol_changes <- hgnc_changes(
  since = "2024-01-01",
  change_type = "symbol"
)
```

### Gene Groups

```r
# Search for gene groups
kinases <- hgnc_search_groups("kinase")

# Get members of a specific group
members <- hgnc_group_members("Protein kinases")
```

## License

MIT License - see LICENSE file for details.

## Author

Bulent Arman Aksoy (arman@aksoy.org)
