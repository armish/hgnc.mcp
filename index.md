# hgnc.mcp

MCP (Model Context Protocol) Server for HGNC (HUGO Gene Nomenclature
Committee) Gene Nomenclature Resources.

## Overview

This R package provides tools for accessing HGNC gene nomenclature data,
including functions for searching, resolving, and validating gene
symbols. It also includes an MCP (Model Context Protocol) server that
exposes these tools to LLM copilots and other MCP-compatible clients.

## Installation

``` r
# Install from GitHub (once available)
# remotes::install_github("yourusername/hgnc.mcp")
```

## Data Management

The package uses smart caching to manage the HGNC complete dataset:

- **First use**: Downloads data from the official HGNC source and caches
  it locally
- **Subsequent uses**: Loads from cache for fast access
- **Updates**: Automatically checks if cache is stale (default: 30 days)
  and refreshes if needed

### Data Functions

``` r
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

Cache is stored in a platform-appropriate location: - **Linux**:
`~/.cache/hgnc.mcp/` - **macOS**: `~/Library/Caches/hgnc.mcp/` -
**Windows**: `%LOCALAPPDATA%/hgnc.mcp/Cache/`

## Data Source

HGNC data is sourced from:
<https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt>

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

The package includes a Model Context Protocol (MCP) server that exposes
HGNC nomenclature services to AI assistants, copilots, and other
MCP-compatible clients. The server provides three types of MCP
primitives:

- **Tools**: API endpoints for actions like search, normalize, and
  validate
- **Resources**: Read-only data for context injection (gene cards, group
  information, dataset metadata)
- **Prompts**: Workflow templates that guide AI assistants through
  multi-step nomenclature tasks

This allows LLMs to directly access HGNC services for gene name
resolution, validation, compliance checking, and more.

### Starting the MCP Server

#### Using R:

``` r
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

``` bash
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

To connect an MCP client (such as Claude Desktop) to the HGNC server,
add the following to your MCP configuration file:

**Claude Desktop**
(`~/Library/Application Support/Claude/claude_desktop_config.json` on
macOS):

``` json
{
  "mcpServers": {
    "hgnc": {
      "url": "http://localhost:8080/mcp"
    }
  }
}
```

**Other MCP Clients**: Consult your client’s documentation for MCP
server configuration.

### Available MCP Tools

The MCP server exposes the following tools:

1.  **info** - Get HGNC REST API metadata and capabilities
2.  **find** - Search for genes by query across symbols, aliases, and
    names
3.  **fetch** - Fetch complete gene records by field value (HGNC ID,
    symbol, etc.)
4.  **resolve_symbol** - Resolve a gene symbol to the current approved
    HGNC symbol
5.  **normalize_list** - Batch normalize a list of gene symbols (fast,
    uses local cache)
6.  **xrefs** - Extract cross-references (Entrez, Ensembl, UniProt,
    OMIM, etc.)
7.  **group_members** - Get all genes in a specific gene group or family
8.  **search_groups** - Search for gene groups by keyword
9.  **changes** - Track nomenclature changes since a specific date
10. **validate_panel** - Validate gene panels against HGNC policy with
    replacement suggestions

### Available MCP Resources

Resources provide read-only data for context injection:

1.  **get_gene_card** - Formatted gene information cards
    (JSON/markdown/text)
2.  **get_group_card** - Gene group information with members
3.  **get_changes_summary** - Nomenclature changes since a date
4.  **snapshot** - Dataset metadata (static resource)

### Available MCP Prompts

> **Note**: MCP Prompts are currently being integrated. Prompt
> functionality will be automatically enabled once the `plumber2mcp`
> package NAMESPACE is updated to export `pr_mcp_prompt()`. The prompt
> functions are implemented and ready to use.

Prompts are workflow templates that guide AI assistants through
multi-step HGNC tasks:

1.  **normalize-gene-list** - Guides through normalizing gene symbols to
    approved HGNC nomenclature. Helps with batch symbol resolution,
    handling aliases/previous symbols, and optionally fetching
    cross-references.

2.  **check-nomenclature-compliance** - Validates gene panels against
    HGNC nomenclature policy. Identifies non-approved symbols, withdrawn
    genes, and duplicates, then provides replacement suggestions with
    rationale.

3.  **what-changed-since** - Generates human-readable summaries of HGNC
    nomenclature changes since a specific date. Useful for governance,
    compliance tracking, and watchlist monitoring.

4.  **build-gene-set-from-group** - Discovers HGNC gene groups by
    keyword search and builds reusable gene set definitions from
    members. Provides output in multiple formats (list, table, JSON)
    with metadata for reproducibility.

### API Documentation

When the server is running with Swagger enabled (default), you can
access the interactive API documentation at:

    http://localhost:8080/__docs__/

This provides detailed information about each endpoint, request/response
formats, and allows you to test the API directly from your browser.

## Deployment

The HGNC MCP server can be deployed in several ways depending on your
needs.

### Docker Deployment

The easiest way to deploy the server is using Docker:

#### Quick Start with Docker

``` bash
# Pull the pre-built image
docker pull ghcr.io/armish/hgnc.mcp:latest

# Run the container
docker run -d \
  --name hgnc-mcp-server \
  -p 8080:8080 \
  -v hgnc-cache:/home/hgnc/.cache/hgnc \
  ghcr.io/armish/hgnc.mcp:latest

# Access the server
open http://localhost:8080/__docs__/
```

#### Build from Source

``` bash
# Clone the repository
git clone https://github.com/armish/hgnc.mcp.git
cd hgnc.mcp

# Build the Docker image
docker build -t hgnc-mcp:latest .

# Run the container
docker run -d \
  --name hgnc-mcp-server \
  -p 8080:8080 \
  -v hgnc-cache:/home/hgnc/.cache/hgnc \
  hgnc-mcp:latest
```

#### Docker Compose

For a more complete setup with persistent storage:

``` bash
# Start the server and supporting services
docker compose up -d

# View logs
docker compose logs -f

# Test the server
docker compose --profile test up hgnc-test-client

# Stop the server
docker compose down
```

> **Note**: This uses the modern `docker compose` command (Docker
> Compose V2). If you have the legacy standalone version, use
> `docker-compose` (with a hyphen) instead.

See
[examples/docker/README.md](https://armish.github.io/hgnc.mcp/examples/docker/README.md)
for advanced Docker deployment options, including: - Production
deployment with Nginx reverse proxy - Development setup with hot
reload - Resource limits and health checks - TLS/HTTPS configuration

### Production Deployment

For production environments, we recommend:

1.  **Use Docker** - The provided Dockerfile uses multi-stage builds and
    runs as a non-root user
2.  **Set up a reverse proxy** - Use Nginx or similar for TLS, rate
    limiting, and load balancing
3.  **Persistent cache** - Mount a volume for the HGNC data cache
4.  **Health monitoring** - The container includes health checks;
    integrate with your monitoring system
5.  **Resource limits** - Set appropriate CPU and memory limits
    (recommended: 2 CPU, 4GB RAM)

Example production docker-compose configuration:

``` yaml
services:
  hgnc-mcp-server:
    image: ghcr.io/armish/hgnc.mcp:latest
    ports:
      - "127.0.0.1:8080:8080"  # Only expose to localhost
    volumes:
      - hgnc-cache:/home/hgnc/.cache/hgnc
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '0.5'
          memory: 1G
    healthcheck:
      test: ["CMD", "Rscript", "-e", "tryCatch(httr::GET('http://localhost:8080/__docs__/'), error = function(e) quit(status=1))"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Cloud Deployment

The Docker image can be deployed to any cloud platform that supports
containers:

#### AWS ECS / Fargate

``` bash
# Tag for AWS ECR
docker tag hgnc-mcp:latest <account-id>.dkr.ecr.<region>.amazonaws.com/hgnc-mcp:latest

# Push to ECR
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/hgnc-mcp:latest

# Deploy using ECS task definition
```

#### Google Cloud Run

``` bash
# Tag for Google Container Registry
docker tag hgnc-mcp:latest gcr.io/<project-id>/hgnc-mcp:latest

# Push to GCR
docker push gcr.io/<project-id>/hgnc-mcp:latest

# Deploy to Cloud Run
gcloud run deploy hgnc-mcp \
  --image gcr.io/<project-id>/hgnc-mcp:latest \
  --port 8080 \
  --memory 4Gi \
  --cpu 2
```

#### Azure Container Instances

``` bash
# Create resource group
az group create --name hgnc-mcp-rg --location eastus

# Deploy container
az container create \
  --resource-group hgnc-mcp-rg \
  --name hgnc-mcp-server \
  --image ghcr.io/armish/hgnc.mcp:latest \
  --ports 8080 \
  --cpu 2 \
  --memory 4
```

### Kubernetes

For Kubernetes deployments, see the example manifests in
`examples/kubernetes/` (coming soon).

### Local Development

For local development without Docker:

``` bash
# Clone the repository
git clone https://github.com/armish/hgnc.mcp.git
cd hgnc.mcp

# Install dependencies
R -e "install.packages('remotes'); remotes::install_deps()"

# Install the package
R CMD INSTALL .

# Start the server
Rscript inst/scripts/run_server.R --port 8080
```

### CI/CD Integration

The repository includes GitHub Actions workflows for: - **R CMD
check** - Package validation across multiple platforms - **Test
coverage** - Automated testing with coverage reports - **Docker
build** - Multi-platform Docker image builds (amd64, arm64)

See `.github/workflows/` for workflow configurations.

To use these workflows in your fork: 1. Enable GitHub Actions in your
repository settings 2. Add any required secrets (e.g., `CODECOV_TOKEN`)
3. Push to trigger the workflows

### Configuration Options

The server can be configured via command-line arguments or environment
variables:

| Option           | Environment Variable | Default          | Description                 |
|------------------|----------------------|------------------|-----------------------------|
| `--port`         | `MCP_SERVER_PORT`    | 8080             | Server port                 |
| `--host`         | `MCP_SERVER_HOST`    | 0.0.0.0          | Server host                 |
| `--no-swagger`   | \-                   | false            | Disable Swagger UI          |
| `--check-cache`  | \-                   | false            | Check cache before starting |
| `--update-cache` | \-                   | false            | Force cache update          |
| \-               | `HGNC_CACHE_DIR`     | Platform default | Cache directory             |

Example with environment variables:

``` bash
export HGNC_CACHE_DIR=/data/hgnc
export MCP_SERVER_PORT=9090
Rscript inst/scripts/run_server.R
```

### Security Considerations

When deploying the HGNC MCP server:

1.  **Network Access**: By default, the server binds to `0.0.0.0` (all
    interfaces). For production, bind to `127.0.0.1` and use a reverse
    proxy
2.  **Rate Limiting**: The server includes internal rate limiting for
    HGNC API calls, but consider adding external rate limiting via
    reverse proxy
3.  **Authentication**: The MCP server does not include authentication.
    Use a reverse proxy with authentication if needed
4.  **TLS**: Always use TLS/HTTPS in production. Configure this at the
    reverse proxy level
5.  **Resource Limits**: Set appropriate CPU and memory limits to
    prevent resource exhaustion
6.  **Updates**: Regularly update the Docker image to get security
    patches and HGNC data updates

### Monitoring

Monitor the following for production deployments:

- **Health endpoint**: `GET /__docs__/` - Returns 200 if server is
  healthy
- **Container health**: Docker/Kubernetes health checks are configured
- **Resource usage**: Monitor CPU and memory usage
- **Cache freshness**: Check
  [`get_hgnc_cache_info()`](https://armish.github.io/hgnc.mcp/reference/get_hgnc_cache_info.md)
  for cache age
- **Error rates**: Monitor server logs for errors

Example health check script:

``` bash
#!/bin/bash
# health_check.sh
if curl -f -s http://localhost:8080/__docs__/ > /dev/null; then
  echo "Server is healthy"
  exit 0
else
  echo "Server is unhealthy"
  exit 1
fi
```

### Troubleshooting

Common deployment issues:

**Port already in use:**

``` bash
# Find what's using the port
lsof -i :8080
# Use a different port
docker run -p 9090:8080 hgnc-mcp:latest
```

**Out of memory:**

``` bash
# Increase Docker memory limit
docker update --memory="4g" hgnc-mcp-server
```

**Cache not persisting:**

``` bash
# Verify volume exists
docker volume inspect hgnc-cache
# Check mount point
docker inspect hgnc-mcp-server | grep Mounts -A 10
```

For more deployment examples and troubleshooting, see: - [Docker
deployment
guide](https://armish.github.io/hgnc.mcp/examples/docker/README.md) -
[MCP client
configuration](https://armish.github.io/hgnc.mcp/examples/mcp-clients/README.md) -
[GitHub Issues](https://github.com/armish/hgnc.mcp/issues)

## Usage Examples

### Basic Gene Lookups

``` r
library(hgnc.mcp)

# Search for genes
results <- hgnc_find("BRCA")

# Fetch a specific gene
gene <- hgnc_fetch("symbol", "BRCA1")

# Resolve a symbol (handles aliases and previous symbols)
resolution <- hgnc_resolve_symbol("BRCA1", mode = "lenient")
```

### Batch Operations

``` r
# Normalize a list of gene symbols
symbols <- c("BRCA1", "tp53", "EGFR", "OLD_SYMBOL", "invalid")
result <- hgnc_normalize_list(symbols)

# View results
print(result$results)
print(result$summary)
print(result$warnings)
```

### Validation

``` r
# Validate a gene panel
panel <- c("BRCA1", "BRCA2", "TP53", "ATM", "CHEK2")
validation <- hgnc_validate_panel(panel)

# Check for issues
print(validation$summary)
print(validation$report)
```

### Change Tracking

``` r
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

``` r
# Search for gene groups
kinases <- hgnc_search_groups("kinase")

# Get members of a specific group
members <- hgnc_group_members("Protein kinases")
```

## Real-World Use Cases

### Clinical Genomics: Panel Validation

Ensure clinical gene panels use current HGNC-approved nomenclature:

``` r
# Load a clinical panel from a CSV file
clinical_panel <- read.csv("hereditary_cancer_panel.csv")$gene_symbol

# Validate against HGNC standards
validation <- hgnc_validate_panel(clinical_panel, policy = "HGNC")

# Review any issues
if (validation$summary$status != "PASS") {
  cat("Issues found:\n")
  print(validation$report)

  # Get replacement suggestions
  if (!is.null(validation$suggestions)) {
    cat("\nSuggested updates:\n")
    print(validation$suggestions[, c("input_symbol", "suggested_symbol", "reason")])
  }
}

# Generate normalized panel for clinical use
normalized <- hgnc_normalize_list(
  clinical_panel,
  return_fields = c("symbol", "name", "hgnc_id", "omim_id", "location")
)

# Export for lab reporting system
write.csv(normalized$results, "validated_panel.csv", row.names = FALSE)
```

### Research: Cross-Study Data Integration

Harmonize gene symbols across multiple datasets:

``` r
# Combine gene lists from different studies
study1_genes <- read.csv("rnaseq_study1.csv")$gene
study2_genes <- read.csv("microarray_study2.csv")$gene
study3_genes <- read.csv("proteomics_study3.csv")$gene

all_genes <- unique(c(study1_genes, study2_genes, study3_genes))

# Normalize to current HGNC symbols
normalized <- hgnc_normalize_list(
  all_genes,
  return_fields = c("symbol", "name", "hgnc_id", "entrez_id", "ensembl_gene_id"),
  dedupe = TRUE
)

# Map back to original datasets with unified nomenclature
# This eliminates false negatives from symbol inconsistencies
```

### Drug Development: Target Validation

Build and maintain target gene lists for drug development:

``` r
# Build a kinase inhibitor target panel
kinase_groups <- hgnc_search_groups("kinase")
all_kinases <- hgnc_group_members("Protein kinases")

# Filter for specific kinase families of interest
tyrosine_kinases <- hgnc_search_groups("tyrosine kinase")
target_kinases <- hgnc_group_members("Receptor tyrosine kinases")

# Get comprehensive cross-references for target validation
targets_with_xrefs <- hgnc_normalize_list(
  target_kinases$symbol,
  return_fields = c("symbol", "name", "hgnc_id", "entrez_id",
                   "ensembl_gene_id", "uniprot_id", "omim_id")
)

# Track any nomenclature changes quarterly
quarterly_changes <- hgnc_changes(since = Sys.Date() - 90, change_type = "all")
target_updates <- quarterly_changes$changes[
  quarterly_changes$changes$symbol %in% target_kinases$symbol,
]
```

### Regulatory Compliance: Audit Trail

Maintain nomenclature compliance for regulatory submissions:

``` r
# Document panel version with HGNC provenance
create_compliance_report <- function(panel_genes, panel_name) {
  # Normalize genes
  normalized <- hgnc_normalize_list(
    panel_genes,
    return_fields = c("symbol", "name", "hgnc_id", "status", "location")
  )

  # Validate
  validation <- hgnc_validate_panel(panel_genes)

  # Get cache info for provenance
  cache_info <- get_hgnc_cache_info()

  # Create report
  report <- list(
    panel_name = panel_name,
    report_date = Sys.Date(),
    hgnc_version = cache_info$download_date,
    hgnc_source = cache_info$source_url,
    total_genes = length(panel_genes),
    valid_genes = sum(normalized$results$status == "Approved"),
    validation_status = validation$summary$status,
    normalized_genes = normalized$results,
    validation_report = validation$report,
    warnings = normalized$warnings
  )

  # Save for audit trail
  saveRDS(report, paste0(panel_name, "_", Sys.Date(), "_compliance.rds"))

  return(report)
}

# Use for regulatory submission
panel <- c("BRCA1", "BRCA2", "TP53", "PTEN", "ATM")
compliance <- create_compliance_report(panel, "BRCA_Panel_v2")
```

### Literature Mining: Standardizing Gene References

Extract and normalize gene symbols from publications:

``` r
# Parse gene symbols from abstract/full text (hypothetical)
extracted_genes <- c("p53", "BRCA-1", "EGF receptor", "HER2", "ERBB2")

# Resolve to standard HGNC symbols
resolved <- lapply(extracted_genes, function(g) {
  result <- hgnc_resolve_symbol(g, mode = "lenient")
  if (!is.null(result$approved_symbol)) {
    data.frame(
      original = g,
      approved = result$approved_symbol,
      confidence = result$confidence
    )
  }
})

# Combine results
gene_mapping <- do.call(rbind, resolved)
print(gene_mapping)

# Result:
#     original approved confidence
# 1        p53     TP53      alias
# 2     BRCA-1    BRCA1   approved
# 3  ERBB2     ERBB2   approved
```

### AI-Assisted Analysis: Using MCP with Claude

With the MCP server running, Claude can help with gene nomenclature
tasks:

``` bash
# Start the MCP server
Rscript -e "library(hgnc.mcp); start_hgnc_mcp_server()"
```

Then in Claude Desktop (with MCP configured):

> **You**: “I have a list of genes from an old microarray study: BRCA1,
> p53, EGFR, HER-2, NBS1. Can you normalize these to current HGNC
> symbols and check if any have been updated?”

> **Claude**: *Uses the normalize_list and validate_panel MCP tools to
> analyze the genes and provide a detailed report with current symbols,
> any changes, and recommendations.*

## Documentation

Comprehensive documentation is available in the package vignettes:

- [Getting Started with
  hgnc.mcp](https://armish.github.io/hgnc.mcp/vignettes/getting-started.Rmd) -
  Installation, basic usage, and core functions
- [Normalizing Gene Lists for Clinical
  Panels](https://armish.github.io/hgnc.mcp/vignettes/normalizing-gene-lists.Rmd) -
  Best practices for clinical genomics workflows
- [Running the MCP
  Server](https://armish.github.io/hgnc.mcp/vignettes/running-mcp-server.Rmd) -
  MCP server setup, configuration, and deployment
- [Working with HGNC Gene
  Groups](https://armish.github.io/hgnc.mcp/vignettes/gene-groups.Rmd) -
  Building gene panels from families and functional groups

View vignettes in R:

``` r
# List all vignettes
vignette(package = "hgnc.mcp")

# View a specific vignette
vignette("getting-started", package = "hgnc.mcp")
```

## Contributing

Contributions are welcome! Please feel free to submit issues, feature
requests, or pull requests.

## License

MIT License - see LICENSE file for details.

## Author

Bulent Arman Aksoy (<arman@aksoy.org>)
