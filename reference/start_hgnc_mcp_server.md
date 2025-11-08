# Start HGNC MCP Server

Initialize and start the HGNC MCP (Model Context Protocol) server using
the plumber2mcp integration. This exposes HGNC nomenclature tools
through the MCP protocol for use by LLM copilots and other MCP clients.

## Usage

``` r
start_hgnc_mcp_server(
  port = 8080,
  host = "0.0.0.0",
  swagger = TRUE,
  quiet = FALSE,
  ...
)
```

## Arguments

- port:

  Integer. Port number to run the server on (default: 8080)

- host:

  Character. Host address to bind to (default: "0.0.0.0")

- swagger:

  Logical. Whether to enable Swagger UI documentation (default: TRUE)

- quiet:

  Logical. If TRUE, suppress startup messages (default: FALSE)

- ...:

  Additional arguments passed to `pr$run()`

## Value

The plumber router object (invisibly), for advanced use cases

## Details

The function performs the following steps:

1.  Loads the Plumber API definition from `inst/plumber/hgnc_api.R`

2.  Registers MCP prompts (workflow templates) for common HGNC tasks

3.  Applies MCP integration via
    [`plumber2mcp::pr_mcp()`](https://rdrr.io/pkg/plumber2mcp/man/pr_mcp.html)

4.  Starts the server on the specified port

5.  Prints connection information

The server exposes HGNC functionality through three MCP primitives:

- **Tools**: API endpoints for actions (search, normalize, validate)

- **Resources**: Read-only data for context injection (gene cards,
  metadata)

- **Prompts**: Workflow templates for multi-step tasks (normalization,
  compliance)

This makes them available to MCP clients like Claude Desktop, VS Code
with MCP extensions, and other compatible applications.

## Available Tools

The MCP server provides the following tools:

- `info`: Get HGNC REST API metadata

- `find`: Search for genes by query

- `fetch`: Fetch gene records by field value

- `resolve_symbol`: Resolve symbols to approved HGNC symbols

- `normalize_list`: Batch normalize gene symbol lists

- `xrefs`: Extract cross-references from gene records

- `group_members`: Get members of a gene group

- `search_groups`: Search for gene groups

- `changes`: Track nomenclature changes since a date

- `validate_panel`: Validate gene panels against HGNC policy

## Available Resources

The MCP server provides the following resources for context injection:

- `get_gene_card`: Formatted gene cards (JSON/markdown/text)

- `get_group_card`: Gene group information with members

- `get_changes_summary`: Nomenclature changes since a date

- `snapshot`: Static resource with dataset metadata

Resources provide read-only data that can be injected into LLM context
for enhanced understanding of genes, groups, and nomenclature changes.

## Available Prompts

The MCP server provides the following workflow template prompts:

- `normalize-gene-list`: Guide through normalizing gene symbols to HGNC

- `check-nomenclature-compliance`: Validate gene panels against HGNC
  policy

- `what-changed-since`: Generate human-readable nomenclature change
  reports

- `build-gene-set-from-group`: Build gene sets from HGNC gene groups

Prompts provide structured guidance for multi-step workflows, helping AI
assistants understand how to use multiple tools together to accomplish
complex nomenclature tasks.

## MCP Client Configuration

To connect an MCP client (e.g., Claude Desktop), add the following to
your MCP configuration file:

    {
      "mcpServers": {
        "hgnc": {
          "url": "http://localhost:8080/mcp"
        }
      }
    }

## Examples

``` r
if (FALSE) { # \dontrun{
# Start server on default port 8080
start_hgnc_mcp_server()

# Start on custom port
start_hgnc_mcp_server(port = 9090)

# Start without Swagger UI
start_hgnc_mcp_server(swagger = FALSE)

# For programmatic use, capture the plumber object
pr <- start_hgnc_mcp_server(quiet = TRUE)
# ... do something with pr ...
pr$stop()
} # }
```
