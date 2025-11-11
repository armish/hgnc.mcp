#!/bin/bash
# Docker entrypoint script for HGNC MCP Server
# This wrapper ensures that arguments passed to docker run are properly
# forwarded to the R server script or runs custom R scripts for testing

set -e

# Path to the default server script
SCRIPT_PATH="/usr/local/bin/hgnc-mcp-server"

# Rscript binary
RSCRIPT="/opt/conda/envs/hgnc-mcp/bin/Rscript"

# Check if first argument is a path to an R script (for testing/custom scripts)
# This allows running: docker run ... /path/to/test.R
if [ $# -gt 0 ] && [[ "$1" == *.R || "$1" == *.r ]]; then
    # Run the custom R script directly
    exec "$RSCRIPT" "$@"
else
    # Run the default server script with any provided arguments
    # Examples:
    #   docker run ...             → Rscript /usr/local/bin/hgnc-mcp-server
    #   docker run ... --stdio     → Rscript /usr/local/bin/hgnc-mcp-server --stdio
    exec "$RSCRIPT" "$SCRIPT_PATH" "$@"
fi
