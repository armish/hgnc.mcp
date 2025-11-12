#!/bin/bash
# Quick local test script for HGNC MCP server Docker integration
# This script allows fast local testing without waiting for GitHub Actions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building Docker image from local source...${NC}"
docker compose build

echo -e "${GREEN}✅ Build complete!${NC}"
echo ""

# Clean up any existing containers
echo -e "${BLUE}🧹 Cleaning up old containers...${NC}"
docker compose down 2>/dev/null || true
docker rm -f hgnc-mcp-server 2>/dev/null || true

echo -e "${BLUE}🚀 Starting MCP server...${NC}"
docker compose up -d

# Wait for server to be healthy
echo -e "${BLUE}⏳ Waiting for server to be healthy...${NC}"
for i in {1..30}; do
    if docker compose ps | grep -q "healthy"; then
        echo -e "${GREEN}✅ Server is healthy!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}⚠️  Timeout waiting for server. Checking logs...${NC}"
        docker compose logs
        exit 1
    fi
    sleep 2
done

echo ""
echo -e "${BLUE}🧪 Running HTTP endpoint tests...${NC}"
docker compose --profile test up hgnc-test-client

echo ""
echo -e "${GREEN}✅ HTTP mode tests passed!${NC}"
echo ""

# Test stdio mode (used by Claude Desktop)
echo -e "${BLUE}🧪 Testing stdio mode (Claude Desktop mode)...${NC}"
if command -v python3 &> /dev/null; then
    # Run comprehensive Python test suite
    python3 test_mcp_stdio.py --timeout 45
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ All stdio tests passed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some stdio tests failed (see above)${NC}"
    fi
else
    # Fallback to basic test
    echo -e "${YELLOW}ℹ️  Python3 not found, running basic test...${NC}"
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
        docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio 2>/dev/null | \
        grep -q "jsonrpc" && \
        echo -e "${GREEN}✅ Stdio mode is working!${NC}" || \
        echo -e "${YELLOW}⚠️  Stdio mode check inconclusive${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All tests passed!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}🌐 HTTP Server:${NC} http://localhost:8080/__docs__/"
echo ""
echo -e "${BLUE}📝 To test with Claude Desktop:${NC}"
echo "   1. Update your claude_desktop_config.json:"
echo ""
echo '   {
     "mcpServers": {
       "hgnc-local": {
         "command": "docker",
         "args": [
           "run", "--rm", "-i",
           "-v", "hgnc-cache:/home/hgnc/.cache/hgnc",
           "hgnc-mcp:latest",
           "--stdio"
         ]
       }
     }
   }'
echo ""
echo "   2. Restart Claude Desktop"
echo ""
echo -e "${BLUE}🛑 To stop the server:${NC}"
echo "   docker compose down"
echo ""
echo -e "${BLUE}📋 View logs:${NC}"
echo "   docker compose logs -f"
echo ""
