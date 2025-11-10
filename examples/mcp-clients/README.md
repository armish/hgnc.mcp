# MCP Client Configuration Examples

This directory contains example configurations for connecting various MCP clients to the HGNC MCP server.

## Claude Desktop

Claude Desktop is an AI assistant application that supports MCP (Model Context Protocol) servers.

### Prerequisites

#### Option 1: Local R Installation

1. Install R (>= 4.0.0)
2. Install the hgnc.mcp package:
   ```r
   install.packages("remotes")
   remotes::install_github("armish/hgnc.mcp")
   ```

#### Option 2: Docker

1. Install Docker
2. Pull the HGNC MCP image:
   ```bash
   docker pull ghcr.io/armish/hgnc.mcp:latest
   ```

### Configuration

#### macOS / Linux

Claude Desktop configuration is stored at:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

#### Windows

Configuration location:
```
%APPDATA%\Claude\claude_desktop_config.json
```

### Setup Instructions

#### Local R Setup

1. Copy the contents of `claude-desktop.json` into your Claude Desktop config
2. Restart Claude Desktop
3. The HGNC MCP server should now be available

Example configuration:
```json
{
  "mcpServers": {
    "hgnc": {
      "command": "Rscript",
      "args": [
        "-e",
        "hgnc.mcp::start_hgnc_mcp_server(transport='stdio')"
      ],
      "env": {
        "HGNC_CACHE_DIR": "${HOME}/.cache/hgnc"
      }
    }
  }
}
```

#### Docker Setup

1. Copy the contents of `claude-desktop-docker.json` into your Claude Desktop config
2. Restart Claude Desktop
3. The Docker container will start automatically when needed

Example configuration:
```json
{
  "mcpServers": {
    "hgnc-docker": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-v",
        "hgnc-cache:/home/hgnc/.cache/hgnc",
        "ghcr.io/armish/hgnc.mcp:latest",
        "/usr/local/bin/hgnc-mcp-server",
        "--stdio"
      ]
    }
  }
}
```

### Transport Modes

The HGNC MCP server supports two transport modes:

**stdio (recommended for desktop clients like Claude Desktop):**
- Uses standard input/output for communication
- More efficient and reliable for local use
- No network ports required

**http (for web-based or remote clients):**
- Uses HTTP/SSE for communication
- Requires port configuration
- Includes Swagger UI for API documentation

### Custom Configuration

For stdio mode with custom cache location:

```json
{
  "mcpServers": {
    "hgnc-custom": {
      "command": "Rscript",
      "args": [
        "-e",
        "hgnc.mcp::start_hgnc_mcp_server(transport='stdio')"
      ],
      "env": {
        "HGNC_CACHE_DIR": "/custom/path/to/cache",
        "R_LIBS_USER": "/custom/r/library"
      }
    }
  }
}
```

For HTTP mode (if you need remote access):

```json
{
  "mcpServers": {
    "hgnc-http": {
      "command": "Rscript",
      "args": [
        "-e",
        "hgnc.mcp::start_hgnc_mcp_server(transport='http', port=9090, host='127.0.0.1', swagger=FALSE)"
      ]
    }
  }
}
```

Available options:
- `transport`: Transport mode - "stdio" or "http" (default: "http")
- `port`: Port number for HTTP mode (default: 8080)
- `host`: Host address for HTTP mode (default: 0.0.0.0)
- `swagger`: Enable Swagger UI for HTTP mode (default: TRUE)

### Testing the Connection

Once configured, you can test the HGNC MCP server in Claude Desktop:

1. Open Claude Desktop
2. Try asking questions like:
   - "What is the approved HGNC symbol for BRCA1?"
   - "Find information about the TP53 gene"
   - "Normalize this list of gene symbols: [BRCA1, TP53, EGFR]"
   - "What gene groups contain ABC transporters?"

### Troubleshooting

#### Server not starting

Check Claude Desktop logs:
- macOS: `~/Library/Logs/Claude/`
- Windows: `%APPDATA%\Claude\logs\`
- Linux: `~/.config/Claude/logs/`

Common issues:

1. **R not found**: Ensure R is in your PATH
2. **Package not installed**: Run `remotes::install_github("armish/hgnc.mcp")`
3. **Docker not running**: Start Docker Desktop (for Docker-based setup)
4. **plumber2mcp not found**: Install with `remotes::install_github("armish/plumber2mcp")`

#### Verify R installation

```bash
# Check R is available
which Rscript
R --version

# Check package is installed
Rscript -e "library(hgnc.mcp); packageVersion('hgnc.mcp')"
```

#### Test server manually

For HTTP mode:
```bash
# Start server in HTTP mode
Rscript -e "hgnc.mcp::start_hgnc_mcp_server(transport='http', port=8080)"

# In another terminal, test it
curl http://localhost:8080/__docs__/
```

For stdio mode (testing with Docker):
```bash
# Test stdio mode with Docker
echo '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}' | \
  docker run --rm -i ghcr.io/armish/hgnc.mcp:latest /usr/local/bin/hgnc-mcp-server --stdio
```

## Other MCP Clients

The HGNC MCP server follows the standard MCP protocol and should work with any MCP-compatible client.

### Generic MCP Client Configuration

Most MCP clients support a similar configuration format:

```json
{
  "servers": [
    {
      "name": "hgnc",
      "url": "http://localhost:8080",
      "type": "mcp"
    }
  ]
}
```

### Python MCP Client Example

```python
from mcp_client import MCPClient

# Connect to HGNC MCP server
client = MCPClient("http://localhost:8080")

# Use tools
result = client.call_tool("find", query="BRCA1")
print(result)

# Access resources
gene_card = client.get_resource("gene/HGNC:1100")
print(gene_card)

# Use prompts
workflow = client.get_prompt("normalize-gene-list",
                             gene_list="BRCA1,TP53,EGFR")
print(workflow)
```

### HTTP API Direct Access

You can also interact with the server directly via HTTP:

```bash
# List available tools
curl -X GET http://localhost:8080/tools

# Call a tool
curl -X POST http://localhost:8080/tools/find \
  -H "Content-Type: application/json" \
  -d '{"query": "BRCA1"}'

# Access a resource
curl -X GET http://localhost:8080/resources/snapshot

# Get Swagger documentation
open http://localhost:8080/__docs__/
```

## Environment Variables

Common environment variables you can set:

| Variable | Description | Default |
|----------|-------------|---------|
| `HGNC_CACHE_DIR` | Cache directory for HGNC data | `~/.cache/hgnc` |
| `R_LIBS_USER` | R library path | System default |
| `MCP_SERVER_PORT` | Server port | 8080 |
| `MCP_SERVER_HOST` | Server host | 127.0.0.1 |

## Advanced Configuration

### Using a Remote Server

If running the server on a remote machine:

```json
{
  "mcpServers": {
    "hgnc-remote": {
      "url": "http://remote-server.example.com:8080",
      "type": "mcp"
    }
  }
}
```

### Multiple Server Instances

You can run multiple server instances (e.g., different versions or configurations):

```json
{
  "mcpServers": {
    "hgnc-local": {
      "command": "Rscript",
      "args": ["-e", "hgnc.mcp::start_hgnc_mcp_server(transport='stdio')"]
    },
    "hgnc-docker": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "ghcr.io/armish/hgnc.mcp:latest", "/usr/local/bin/hgnc-mcp-server", "--stdio"]
    }
  }
}
```

### Pre-load Cache

Download the cache before starting the server:

```bash
# Download cache
Rscript -e "hgnc.mcp::download_hgnc_data()"

# Verify cache
Rscript -e "hgnc.mcp::load_hgnc_data()"
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/armish/hgnc.mcp/issues
- Documentation: See main README.md
- MCP Protocol: https://modelcontextprotocol.io/
