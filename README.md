# hgnc.mcp

MCP (Model Context Protocol) Server for HGNC (HUGO Gene Nomenclature Committee) Gene Nomenclature Resources.

## Overview

This R package provides tools for accessing HGNC gene nomenclature data, including functions for searching, resolving, and validating gene symbols. MCP (Model Context Protocol) server functionality is planned for a future release.

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

## License

MIT License - see LICENSE file for details.

## Author

Bulent Arman Aksoy (arman@aksoy.org)
