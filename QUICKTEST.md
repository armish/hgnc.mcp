# Quick Testing Guide for MCP Integration

This guide shows how to quickly test MCP server changes without waiting
for full Docker + Claude integration.

## Method 1: MCP Inspector (Recommended)

The [MCP Inspector](https://github.com/modelcontextprotocol/inspector)
provides a web UI for testing MCP servers interactively.

### Prerequisites

- Node.js and npx installed
- Docker installed (for running the server)

### Steps

1.  **Build and run your Docker image locally:**

    ``` bash
    # Build from source
    docker build -t hgnc-mcp:test .
    ```

2.  **Start MCP Inspector with your server:**

    ``` bash
    # For stdio transport (most common)
    npx @modelcontextprotocol/inspector docker run --rm -i \
      -v hgnc-cache:/home/hgnc/.cache/hgnc \
      hgnc-mcp:test
    ```

    Or if using the pre-built image:

    ``` bash
    npx @modelcontextprotocol/inspector docker run --rm -i \
      -v hgnc-cache:/home/hgnc/.cache/hgnc \
      ghcr.io/armish/hgnc.mcp:latest
    ```

3.  **Open the Inspector UI:**

    - The inspector will start a local web server (usually
      <http://localhost:5173>)
    - Open it in your browser
    - You’ll see:
      - **Tools tab**: List of available MCP tools
      - **Resources tab**: List of available MCP resources (should show
        4 resources now!)
      - **Prompts tab**: List of available MCP prompts
      - **Console**: Real-time JSON-RPC message viewer

4.  **Test Resources:**

    - Click on the “Resources” tab
    - You should see:
      - HGNC Dataset Snapshot (hgnc://snapshot)
      - HGNC Gene Card (hgnc://gene/{hgnc_id})
      - HGNC Gene Group Card (hgnc://group/{group_id_or_name})
      - HGNC Nomenclature Changes (hgnc://changes/{since})
    - Click “Read” on any resource to fetch its content
    - Try reading a specific gene: hgnc://gene/HGNC:5 or
      hgnc://gene/BRCA1

5.  **Test Tools:**

    - Click on the “Tools” tab
    - Try calling tools like:
      - `POST__tools_find` with query: “BRCA”
      - `POST__tools_resolve_symbol` with symbol: “TP53”
      - `POST__tools_normalize_list` with symbols: \[“BRCA1”, “TP53”,
        “EGFR”\]

### What to Look For

**Before the fix:** - Resources tab would be empty - All 14 items appear
as tools (including GET\_*resources*\*)

**After the fix:** - Resources tab shows 4 resources with hgnc:// URIs -
Tools tab shows 10 tools (POST\_*tools*\* only) - Resources can be read
with URI parameters

## Method 2: Direct stdio Testing

For even faster iteration during development:

``` bash
# Run the server directly with stdio
docker run --rm -i \
  -v hgnc-cache:/home/hgnc/.cache/hgnc \
  hgnc-mcp:test

# Send MCP messages via stdin (JSON-RPC format)
# Example: List resources
echo '{"jsonrpc":"2.0","id":1,"method":"resources/list","params":{}}' | \
  docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:test

# Example: Read a resource
echo '{"jsonrpc":"2.0","id":2,"method":"resources/read","params":{"uri":"hgnc://snapshot"}}' | \
  docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:test
```

## Method 3: Local R Testing

If you have R installed locally:

``` r
# Install the package
devtools::install(".", dependencies = TRUE)

# Load and start the server
library(hgnc.mcp)
start_hgnc_mcp_server(transport = "stdio")

# The server will start and listen on stdio
# Connect with MCP Inspector:
npx @modelcontextprotocol/inspector Rscript -e "hgnc.mcp::start_hgnc_mcp_server(transport='stdio')"
```

## Debugging Tips

1.  **Check server logs**: Look for “Registering MCP resources…” message
2.  **Verify resource count**: Should see “Successfully registered 4 MCP
    resources”
3.  **Use Inspector console**: View raw JSON-RPC messages to see what’s
    being sent/received
4.  **Check for errors**: Look for any error messages in the server
    startup logs

## Common Issues

**Resources still empty?** - Check if `pr_mcp_resource` is exported in
plumber2mcp: `getNamespaceExports("plumber2mcp")` - Verify you’re using
the latest plumber2mcp version:
`remotes::install_github('armish/plumber2mcp')`

**Can’t connect with Inspector?** - Make sure Docker is using `-i` flag
for interactive stdin - Verify the server starts successfully (check
logs)

**Resource read fails?** - Check URI format matches the template (e.g.,
hgnc://gene/BRCA1 not hgnc://gene?id=BRCA1) - Verify the hgnc_get\_\*
functions work correctly

## Automated Testing

### GitHub Actions

stdio mode is automatically tested in CI/CD via:

**`.github/workflows/test-stdio-docker.yaml`** - Tests stdio transport
with Docker - Runs on every push and PR - Tests MCP protocol messages
(initialize, tools/list, resources/list, etc.) - Verifies resources
don’t appear as tools - Confirms tool calls work - Check the Actions tab
on GitHub to see results

**`.github/workflows/R-CMD-check.yaml`** - Tests R package - Runs
testthat tests including stdio mode tests - Tests on multiple OS/R
version combinations

**`.github/workflows/test-coverage.yaml`** - Code coverage - Runs tests
with coverage analysis

### Local Test Suite

Run the test suite locally:

``` r
# Run all tests
devtools::test()

# Run specific test files
testthat::test_file("tests/testthat/test-mcp_stdio_transport.R")
testthat::test_file("tests/testthat/test-mcp_resources_integration.R")
testthat::test_file("tests/testthat/test-mcp_prompts_integration.R")
```
