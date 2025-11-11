#!/bin/bash
# Docker entrypoint script for HGNC MCP Server
# This wrapper ensures that arguments passed to docker run are properly
# forwarded to the R server script

set -e

# Path to the R script
SCRIPT_PATH="/usr/local/bin/hgnc-mcp-server"

# If no arguments provided, run without args (HTTP mode)
# If arguments provided, pass them through (e.g., --stdio)
exec /opt/conda/envs/hgnc-mcp/bin/Rscript "$SCRIPT_PATH" "$@"
