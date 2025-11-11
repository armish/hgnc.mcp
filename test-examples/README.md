# MCP Stdio Test Examples

This directory contains example JSON-RPC message sequences for manual testing of the HGNC MCP server in stdio mode.

## Usage

```bash
# Basic test - list tools
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test-examples/basic-test.jsonl

# Search for BRCA genes
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test-examples/search-brca.jsonl

# Normalize gene symbols
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test-examples/normalize-genes.jsonl
```

## File Format

Each file contains one JSON-RPC message per line (JSONL format):
1. First line: `initialize` request
2. Subsequent lines: actual MCP requests

## Creating Custom Tests

Create a new `.jsonl` file with your test messages:

```jsonl
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"POST__tools_resolve_symbol","arguments":{"symbol":"TP53"}}}
```

Then run:

```bash
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < your-test.jsonl
```

## Available Tools

Use these tool names in `tools/call` requests:

- `GET__tools_info` - Get HGNC API metadata
- `POST__tools_find` - Search genes
- `POST__tools_fetch` - Fetch by field
- `POST__tools_resolve_symbol` - Resolve symbols
- `POST__tools_normalize_list` - Batch normalize
- `POST__tools_xrefs` - Get cross-references
- `POST__tools_group_members` - Get gene group members
- `POST__tools_search_groups` - Search groups
- `POST__tools_changes` - Track changes
- `POST__tools_validate_panel` - Validate panels

## Parsing Output

The output contains both stderr (server logs) and stdout (JSON-RPC responses).

To extract just JSON responses:

```bash
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test.jsonl 2>/dev/null | grep '^{'
```

To pretty-print with jq:

```bash
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test.jsonl 2>/dev/null | grep '^{' | jq .
```
