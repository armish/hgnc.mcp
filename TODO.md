# hgnc.mcp Implementation Roadmap

## Vision

Create an MCP server that eliminates "gene name headaches" by providing reliable HGNC nomenclature services to LLM copilots, notebooks, and bioinformatics pipelines. The server will expose HGNC data through three MCP primitives:

- **Tools**: API-shaped actions (search, normalize, validate)
- **Resources**: Read-only gene/group cards for context injection
- **Prompts**: Pre-wired workflow templates

## Architecture Overview

The implementation will leverage both:

1. **Local cached data** (`hgnc_complete_set.txt`) - for fast bulk operations, offline work, and dictionary lookups
2. **HGNC REST API** - for real-time queries, updates, and precise searches

### Data Strategy Decision Matrix

| Operation | Source | Rationale |
|-----------|--------|-----------|
| Bulk normalize/validate | Local cache | Fast, no rate limits |
| Single gene lookup | REST API preferred, cache fallback | Most current data |
| Group queries | REST API | Dynamic, authoritative |
| Change tracking | REST API | Requires date filtering |
| Autocomplete | Local cache first | Speed critical |
| Cross-references | Either (prefer cache) | Static data |

---

## Status: Completed ✓

- [x] R package scaffolding (`hgnc.mcp`)
- [x] Smart data caching system with versioning
- [x] Cache management functions (`load_hgnc_data`, `download_hgnc_data`, etc.)
- [x] Unit tests for cache functions
- [x] Documentation (README, roxygen)

---

## Phase 1: HGNC REST API Client [MVP Foundation]

Build a robust R client for the HGNC REST API with rate limiting and caching.

### 1.1 Core REST Client Infrastructure ✓

**File**: `R/hgnc_rest_client.R`

- [x] `hgnc_rest_get()` - Base HTTP client with:
  - Rate limiting (≤10 req/sec) using sliding window algorithm
  - User-Agent header identifying hgnc.mcp package
  - Error handling & retries with exponential backoff (httr::RETRY)
  - JSON parsing with helpful error messages
  - Optional response caching (in-memory for session via memoise)
- [x] `hgnc_rest_info()` - GET `/info` endpoint
  - Returns: `lastModified`, searchable fields, stored fields
  - Use for cache invalidation decisions
  - Cached with memoise for fast repeated calls
- [x] Session-level cache for repeated queries
  - `clear_hgnc_cache()` to manually clear cache
  - `reset_rate_limiter()` for testing
- [x] Tests for REST client in `tests/testthat/test-hgnc_rest_client.R`
  - Rate limiting tests
  - Live API integration tests
  - Caching behavior tests
  - Error handling tests

**Dependencies added**: `httr`, `memoise`, `lubridate`, `curl` (testing)

### 1.2 Essential Lookup Tools ✓

**File**: `R/hgnc_tools.R`

Implement the minimal viable tool set:

- [x] **`hgnc_find(query, filters = NULL)`**
  - Wraps `/search` endpoint
  - Search across symbol, alias, prev_symbol, name
  - Return hits with scores and match reasons
  - Support filters: status, locus_type, etc.

- [x] **`hgnc_fetch(field, term)`**
  - Wraps `/fetch/{field}/{term}`
  - Common fields: `hgnc_id`, `symbol`, `entrez_id`, `ensembl_gene_id`
  - Return full gene "card" with all stored fields

- [x] **`hgnc_resolve_symbol(symbol, mode = "lenient")`**
  - `strict`: exact approved symbol only
  - `lenient`: search symbol|alias|prev, then fetch by hgnc_id
  - Return: approved symbol, status, confidence, candidates if ambiguous
  - Handle case normalization (HGNC uses uppercase)

- [x] **`hgnc_xrefs(id_or_symbol)`**
  - Extract cross-references from gene record
  - Return: NCBI Gene, Ensembl, UniProt, OMIM, CCDS, MANE Select
  - Useful for dataset harmonization

- [x] Tests for lookup functions
- [x] Documentation and usage examples in `EXAMPLES.md`

### 1.3 Batch Operations (Using Cached Data) ✓

**File**: `R/hgnc_batch.R`

- [x] **`hgnc_normalize_list(symbols, return_fields, status = "Approved", dedupe = TRUE, index = NULL)`**
  - Batch resolver using local cache for speed
  - Upper-case, trim, dedupe by HGNC ID
  - Flag invalid/withdrawn
  - Return clean table ready for downstream use
  - Emit warnings/reports for problematic entries
  - Support for reusing pre-built index for efficiency

- [x] Helper: `build_symbol_index()` - Create in-memory lookup from cached data
  - Index by: symbol, alias_symbol, prev_symbol
  - Map to hgnc_id for fast resolution
  - Handles ambiguous matches

- [x] Tests for batch operations
  - Unit tests with mock data
  - Integration tests with cached data
  - Edge case handling (duplicates, ambiguous, withdrawn, empty)

### 1.4 Groups & Collections ✓

**File**: `R/hgnc_groups.R`

- [x] **`hgnc_group_members(group_id_or_name)`**
  - Use REST API `/fetch/gene_group/{id}`
  - Return members with IDs and xrefs
  - Cache results (groups don't change often)

- [x] **`hgnc_search_groups(query)`**
  - Find gene groups by keyword
  - Return group IDs, names, descriptions

- [x] Tests for group functions

### 1.5 Change Tracking & Validation ✓

**File**: `R/hgnc_changes.R`

- [x] **`hgnc_changes(since, fields = c("symbol", "name", "status"))`**
  - Query genes with date_* fields ≥ since
  - Return before/after values where available
  - Useful for watchlists and compliance
  - Supports multiple change types: all, symbol, name, status, modified

- [x] **`hgnc_validate_panel(items, policy = "HGNC")`**
  - QA gene lists against HGNC policy
  - Report: non-approved, withdrawn, duplicates
  - Suggest replacements with rationale and dates
  - Use prev_symbol/alias_symbol for mapping
  - Comprehensive validation with human-readable reports

- [x] Tests for validation functions in `tests/testthat/test-hgnc_changes.R`
- [x] Documentation and examples in `EXAMPLES.md`

---

## Phase 2: MCP Server Implementation [Core Deliverable]

Integrate with plumber2mcp to expose HGNC tools via MCP protocol.

### 2.1 Plumber API Definitions

**File**: `inst/plumber/hgnc_api.R`

Create Plumber endpoints that wrap our HGNC functions:

- [ ] Setup plumber router
- [ ] Define endpoints for each tool:
  ```r
  #* @post /tools/find
  #* @param query:str The search query
  #* @param filters:object Optional filters
  endpoint_find <- function(query, filters = NULL) {
    hgnc_find(query, filters)
  }
  ```

- [ ] Endpoints needed:
  - `/tools/info` → `hgnc_rest_info()`
  - `/tools/find` → `hgnc_find()`
  - `/tools/fetch` → `hgnc_fetch()`
  - `/tools/resolve_symbol` → `hgnc_resolve_symbol()`
  - `/tools/normalize_list` → `hgnc_normalize_list()`
  - `/tools/xrefs` → `hgnc_xrefs()`
  - `/tools/group_members` → `hgnc_group_members()`
  - `/tools/search_groups` → `hgnc_search_groups()`
  - `/tools/changes` → `hgnc_changes()`
  - `/tools/validate_panel` → `hgnc_validate_panel()`

- [ ] Error handling and validation
- [ ] OpenAPI documentation via Plumber decorators

### 2.2 MCP Integration with plumber2mcp ✓

**File**: `R/mcp_server.R`

- [x] **`start_hgnc_mcp_server(port = 8080, ...)`**
  - Initialize plumber API
  - Apply `pr_mcp()` from plumber2mcp
  - Start server
  - Print connection info

- [x] Server configuration and startup script
- [x] Documentation for running the server

**File**: `inst/scripts/run_server.R` (executable script)

- [x] Standalone server launcher
- [x] Command-line argument parsing (port, cache settings, etc.)

### 2.3 MCP Resources Implementation

Resources provide read-only context injection.

- [ ] **`resource://hgnc/gene/{hgnc_id}`**
  - Minimal gene card: symbol, name, location, status, aliases, prev_symbols, xrefs, groups, MANE
  - Format as structured JSON/markdown for LLM context

- [ ] **`resource://hgnc/group/{id_or_slug}`**
  - Group summary + members
  - Include group description and size

- [ ] **`resource://hgnc/snapshot/{version}`**
  - Metadata for cached snapshot (URL, date, columns, row count)
  - Useful for provenance

- [ ] **`resource://hgnc/changes/since/{ISO_date}`**
  - Compact change log (IDs, symbols, dates)

**Note**: Check plumber2mcp documentation for resources implementation pattern.

### 2.4 MCP Prompts (Workflow Templates)

Pre-configured multi-step workflows:

- [ ] **`normalize-gene-list`**
  - Args: list, strictness, return_xrefs
  - Orchestrates find/resolve/fetch
  - Returns tidy table + warnings

- [ ] **`check-nomenclature-compliance`**
  - Args: panel_text or fileUri
  - Lints panel against HGNC policy
  - Returns report with suggested fixes

- [ ] **`what-changed-since`**
  - Args: date
  - Human-readable summary for governance

- [ ] **`build-gene-set-from-group`**
  - Args: group_query
  - Finds group and produces reusable set definition

**Note**: Prompts are MCP templates; verify plumber2mcp support and syntax.

---

## Phase 3: Enhanced Features [Post-MVP]

### 3.1 Advanced Tools

- [ ] **`hgnc_autocomplete(prefix, limit = 20)`**
  - Fast type-ahead using local cache
  - Fallback to REST `/search/symbol/{prefix}*`
  - Optimize for UI responsiveness

- [ ] **`hgnc_download_snapshot(kind, format)`**
  - Expose bulk download functionality
  - Kinds: `hgnc_complete_set`, `withdrawn`
  - Formats: `tsv`, `json`
  - Return local cache path + version info

- [ ] **`hgnc_diff_snapshots(version_a, version_b)`**
  - Compare two cached versions
  - Report: added, removed, renamed, withdrawn
  - Useful for audit logs

### 3.2 VGNC Orthologs (Optional)

- [ ] **`vgnc_orthologs(hgnc_id, species = NULL)`**
  - Query VGNC for vertebrate orthologs
  - Map back to human HGNC IDs
  - Cross-species reference tool

### 3.3 Performance & Scalability

- [ ] Benchmark REST API rate limiting
- [ ] Optimize bulk operations with local cache
- [ ] Add persistent disk cache for REST responses (SQLite or similar)
- [ ] Implement smart cache invalidation using `/info` lastModified

### 3.4 Extended Resources

- [ ] `resource://hgnc/locus_types` - Enumeration of valid locus types
- [ ] `resource://hgnc/statistics` - Dataset stats (counts by status, locus type)
- [ ] `resource://hgnc/help/{topic}` - Contextual help for tools

---

## Phase 4: Polish & Distribution [Production-Ready]

### 4.1 Documentation

- [ ] Vignettes:
  - "Getting Started with hgnc.mcp"
  - "Normalizing Gene Lists for Clinical Panels"
  - "Running the MCP Server"
  - "Working with HGNC Gene Groups"

- [ ] Update README with:
  - MCP server setup instructions
  - Client connection examples
  - Real-world use cases
  - API reference links

- [ ] Function documentation complete with examples
- [ ] MCP tool/resource discovery documentation

### 4.2 Testing & Quality

- [ ] Unit tests for all functions (>80% coverage)
- [ ] Integration tests:
  - REST API interactions (use testthat with skip_on_cran)
  - MCP server endpoints
  - Batch operations with realistic data

- [ ] Mock HGNC responses for offline testing
- [ ] Snapshot tests for gene cards and reports
- [ ] Performance benchmarks

### 4.3 DevOps & Deployment

- [ ] Docker image for MCP server
- [ ] Docker Compose example with client
- [ ] CI/CD pipeline (GitHub Actions):
  - R CMD check
  - Unit tests
  - Integration tests
  - Docker build

- [ ] Example MCP client configurations:
  - Claude Desktop
  - Other MCP clients

### 4.4 Distribution

- [ ] Prepare for CRAN submission:
  - Check package size (cached data implications)
  - Ensure all examples are runnable
  - Address any R CMD check warnings

- [ ] GitHub repository setup:
  - README badges
  - Contributing guidelines
  - Issue templates
  - Release workflow

- [ ] pkgdown website
- [ ] Announcement blog post / tweet

---

## Implementation Notes & Best Practices

### Rate Limiting Strategy

HGNC requests ≤10 req/sec:

- Implement token bucket or leaky bucket algorithm
- Use `httr::RETRY()` with exponential backoff
- Session-level request counter
- Consider `ratelimitr` package

### ID-First Philosophy

- Internally normalize to `HGNC:####` (or just numeric ID)
- Treat symbol strings as presentation layer
- Deduplicate by HGNC ID, not by symbol string
- Store mappings: symbol → hgnc_id → canonical data

### Ambiguity Handling

When multiple matches found:

- Return all candidates with match metadata:
  - Matched via: symbol | alias_symbol | prev_symbol
  - Score (if available)
  - Status (Approved vs Withdrawn)
  - Locus type and location for disambiguation
- Let caller decide or prompt for selection

### Field Coverage

Include key stored fields in gene records:

- Identifiers: `hgnc_id`, `symbol`, `name`
- Status: `status`, `locus_type`, `location`
- Aliases: `alias_symbol`, `prev_symbol`
- Cross-refs: `entrez_id`, `ensembl_gene_id`, `uniprot_id`, `omim_id`, `ccds_id`, `mane_select`, `agr`
- Groups: `gene_group`, `gene_group_id`
- Dates: `date_symbol_changed`, `date_name_changed`, `date_modified`, `date_approved_reserved`

### Caching Strategy

1. **In-memory session cache**: Frequent identical queries (use `memoise`)
2. **Persistent disk cache**: Bulk data snapshots (already implemented)
3. **Optional SQLite cache**: REST API responses with TTL
4. **Cache invalidation**: Check `/info` lastModified vs cache timestamp

### Error Messages

User-friendly errors with actionable guidance:

- "Symbol 'XYZ' not found. Did you mean 'XYZ1'? (approved symbol)"
- "Gene 'ABC' is Withdrawn. Suggested replacement: 'DEF' (changed 2023-05-15)"
- "Ambiguous: 'KIT' matches 3 genes. Specify HGNC ID or use filters."

---

## Minimal Viable Product (Ship First)

**Goal**: Deliver a working MCP server with core normalization capabilities.

### MVP Checklist

**Phase 1 (Core Functions)**:
- [x] REST client with rate limiting
- [x] `hgnc_find()`, `hgnc_fetch()`, `hgnc_resolve_symbol()`
- [x] `hgnc_normalize_list()` (batch, using cache)
- [x] `hgnc_xrefs()`
- [x] `hgnc_group_members()`
- [x] `hgnc_changes()`
- [x] `hgnc_validate_panel()`

**Phase 2 (MCP Server)**:
- [ ] Plumber API with all MVP tools
- [ ] MCP integration via `plumber2mcp`
- [ ] Resources: `gene/*`, `group/*`
- [ ] Prompt: `normalize-gene-list`

**Phase 4 (Launch-Ready)**:
- [ ] Basic documentation (README + function docs)
- [ ] Docker image
- [ ] Example client config
- [ ] Unit tests for MVP functions

**Ship MVP when**: All above items complete, server runs, and one end-to-end workflow (normalize gene list) works from an MCP client.

---

## Future Ideas (Beyond MVP)

- [ ] Web UI dashboard for cache management and server status
- [ ] Scheduled cache refresh (cron job or background worker)
- [ ] Metrics/telemetry: query patterns, error rates, cache hit rates
- [ ] Multi-species support (MGI, RGD, etc.) via parallel servers
- [ ] Graph-based gene relationship explorer (families, pathways)
- [ ] Integration with other nomenclature resources (COSMIC, ClinVar)
- [ ] Batch job mode: process large files asynchronously

---

## Success Metrics

- **Functional**: MCP client can normalize 1000 gene symbols in <5 seconds
- **Reliability**: >99% cache hit rate for common symbols after warmup
- **Accuracy**: 100% agreement with HGNC for approved symbols
- **Usability**: New user can start server and normalize a gene list in <5 minutes
- **Adoption**: Used by ≥3 real bioinformatics workflows

---

## Dependencies Summary

**Already in DESCRIPTION**:
- plumber, plumber2mcp, jsonlite, httr, rappdirs, readr

**To add**:
- `httr2` (modern HTTP client, or stick with httr)
- `memoise` (session caching)
- `ratelimitr` or custom rate limiting
- `lubridate` (date handling for change tracking)
- `dplyr`, `purrr` (data wrangling, optional but recommended)
- `glue` (string formatting)

**Optional**:
- `DBI`, `RSQLite` (persistent REST cache)
- `furrr` (parallel processing for batch ops)
- `logger` (structured logging)

---

## Timeline Estimate

- **Phase 1**: 2-3 weeks (REST client + core tools)
- **Phase 2**: 1-2 weeks (MCP server integration)
- **MVP Launch**: ~1 month total
- **Phase 3**: 2-3 weeks (enhanced features)
- **Phase 4**: 1-2 weeks (polish, docs, distribution)

**Total to production-ready**: ~2-3 months part-time

---

## Getting Started: Next Immediate Steps

1. ✅ Review and finalize this TODO.md
2. ⬜ Set up HGNC REST API client skeleton (`R/hgnc_rest_client.R`)
3. ⬜ Implement `hgnc_rest_info()` and test against live API
4. ⬜ Add rate limiting to base client
5. ⬜ Implement `hgnc_find()` and `hgnc_fetch()` with tests
6. ⬜ Build `hgnc_resolve_symbol()` on top of find/fetch

**First concrete milestone**: Successfully resolve "BRCA1" → full gene record via REST API.

---

*Last updated: 2025-11-06*
