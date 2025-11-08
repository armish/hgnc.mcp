# Changelog

## hgnc.mcp 0.1.0 (Development Version)

### Major Features

#### Data Management

- Smart caching system for HGNC complete dataset with automatic updates
- Cross-platform cache directory management (Linux, macOS, Windows)
- Configurable cache freshness (default: 30 days)
- Cache metadata tracking (download time, file size, source URL)

#### HGNC REST API Client

- Robust REST API client with rate limiting (≤10 req/sec)
- Session-level caching for repeated queries using memoise
- Comprehensive error handling and retries with exponential backoff
- Support for all major HGNC API endpoints

#### Gene Lookup and Resolution

- [`hgnc_find()`](https://armish.github.io/hgnc.mcp/reference/hgnc_find.md) -
  Search across symbols, aliases, and names
- [`hgnc_fetch()`](https://armish.github.io/hgnc.mcp/reference/hgnc_fetch.md) -
  Retrieve complete gene records
- [`hgnc_resolve_symbol()`](https://armish.github.io/hgnc.mcp/reference/hgnc_resolve_symbol.md) -
  Resolve symbols with strict/lenient modes
- [`hgnc_xrefs()`](https://armish.github.io/hgnc.mcp/reference/hgnc_xrefs.md) -
  Extract cross-references (Entrez, Ensembl, UniProt, OMIM)

#### Batch Operations

- [`hgnc_normalize_list()`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md) -
  Fast batch normalization using local cache
- [`build_symbol_index()`](https://armish.github.io/hgnc.mcp/reference/build_symbol_index.md) -
  Create efficient in-memory lookup indexes
- Support for handling ambiguous matches and withdrawn genes

#### Gene Groups and Families

- [`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md) -
  Get all genes in a specific group
- [`hgnc_search_groups()`](https://armish.github.io/hgnc.mcp/reference/hgnc_search_groups.md) -
  Discover groups by keyword search

#### Change Tracking and Validation

- [`hgnc_changes()`](https://armish.github.io/hgnc.mcp/reference/hgnc_changes.md) -
  Track nomenclature changes by date
- [`hgnc_validate_panel()`](https://armish.github.io/hgnc.mcp/reference/hgnc_validate_panel.md) -
  Validate gene panels against HGNC policy
- Comprehensive validation with replacement suggestions

#### MCP Server

- Model Context Protocol (MCP) server for AI assistant integration
- 10 MCP tools for gene nomenclature operations
- 4 MCP resources for context injection (gene cards, group cards, etc.)
- 4 MCP prompts for guided multi-step workflows
- Interactive Swagger UI for API documentation
- Standalone server script with command-line configuration

#### Docker Deployment

- Production-ready Docker image with multi-stage builds
- Docker Compose configuration with health checks
- Multi-platform builds (amd64, arm64)
- Published to GitHub Container Registry

#### Documentation

- 4 comprehensive vignettes:
  - Getting Started with hgnc.mcp
  - Normalizing Gene Lists for Clinical Panels
  - Working with HGNC Gene Groups
  - Running the MCP Server
- Complete function documentation with examples
- Real-world use cases and workflow examples

#### Testing and Quality

- Comprehensive test suite with \>80% coverage
- Unit tests for all major functions
- Integration tests for REST API and caching
- Automated testing across multiple platforms (Linux, macOS, Windows)
- Automated Docker build and test pipeline

### Initial Release

This is the first development release of hgnc.mcp. The package provides
a complete toolkit for working with HGNC gene nomenclature in R, with
particular focus on:

1.  **Speed**: Local caching for fast bulk operations
2.  **Reliability**: Robust error handling and rate limiting
3.  **Usability**: Clean API with sensible defaults
4.  **Integration**: MCP server for AI assistant workflows
5.  **Reproducibility**: Version tracking and provenance

The package is ready for use in research and production environments,
with active development continuing for additional features and
improvements.
