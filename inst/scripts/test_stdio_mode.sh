#!/bin/bash
# Test MCP Server stdio Mode
#
# This script tests the MCP server running in stdio mode by sending
# JSON-RPC messages and checking the responses.
#
# Usage:
#   ./test_stdio_mode.sh [docker|local]
#
# Modes:
#   docker - Test using Docker container (default)
#   local  - Test using local R installation

set -e

MODE="${1:-docker}"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "MCP Server stdio Mode Test"
echo "========================================"
echo "Mode: $MODE"
echo ""

# Function to run the server
run_server() {
    if [ "$MODE" = "docker" ]; then
        docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:test
    else
        Rscript -e "hgnc.mcp::start_hgnc_mcp_server(transport='stdio', quiet=FALSE)"
    fi
}

# Function to test a message
test_message() {
    local test_name="$1"
    local message="$2"
    local check_func="$3"

    echo "Testing: $test_name"

    if [ "$VERBOSE" = "1" ]; then
        echo "Request: $message"
    fi

    # Send message and capture only the last JSON line (skip stderr)
    response=$(echo "$message" | run_server 2>/dev/null | tail -1)

    if [ "$VERBOSE" = "1" ]; then
        echo "Response: $response"
    fi

    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        echo -e "${RED}✗ FAIL${NC}: Response is not valid JSON"
        echo "Response: $response"
        return 1
    fi

    # Run custom check function if provided
    if [ -n "$check_func" ]; then
        if $check_func "$response"; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${RED}✗ FAIL${NC}: Check function failed"
            return 1
        fi
    else
        echo -e "${GREEN}✓ PASS${NC}: Valid JSON response"
        return 0
    fi
}

# Check functions
check_initialize() {
    local response="$1"
    echo "$response" | jq -e '.result.serverInfo.name' > /dev/null
}

check_tools_list() {
    local response="$1"
    local tool_count=$(echo "$response" | jq '.result.tools | length')
    [ "$tool_count" -ge 10 ]
}

check_resources_list() {
    local response="$1"
    echo "$response" | jq -e '.result.resources' > /dev/null
}

check_no_resource_tools() {
    local response="$1"
    local tool_names=$(echo "$response" | jq -r '.result.tools[].name')
    ! echo "$tool_names" | grep -q "GET__resources_"
}

# Build initialize message
INIT_MSG='{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}}}'

# Test 1: Initialize
echo ""
echo "Test 1: Initialize"
echo "-------------------"
test_message "Server initialization" "$INIT_MSG" check_initialize
INIT_RESULT=$?

# Test 2: Tools list
echo ""
echo "Test 2: List Tools"
echo "-------------------"
TOOLS_MSG=$(cat <<EOF
$INIT_MSG
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
EOF
)
test_message "List tools (should have 10+ tools)" "$TOOLS_MSG" check_tools_list
TOOLS_RESULT=$?

# Test 3: Resources list
echo ""
echo "Test 3: List Resources"
echo "-------------------"
RESOURCES_MSG=$(cat <<EOF
$INIT_MSG
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}
EOF
)
test_message "List resources" "$RESOURCES_MSG" check_resources_list
RESOURCES_RESULT=$?

# Test 4: Verify no resource/tool conflicts
echo ""
echo "Test 4: Check Tool/Resource Separation"
echo "---------------------------------------"
test_message "Resources should not appear as tools" "$TOOLS_MSG" check_no_resource_tools
NO_CONFLICT_RESULT=$?

# Test 5: Prompts list
echo ""
echo "Test 5: List Prompts"
echo "-------------------"
PROMPTS_MSG=$(cat <<EOF
$INIT_MSG
{"jsonrpc":"2.0","id":3,"method":"prompts/list","params":{}}
EOF
)
test_message "List prompts" "$PROMPTS_MSG"
PROMPTS_RESULT=$?

# Summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"

total_tests=5
passed_tests=0

if [ $INIT_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Initialize"
    ((passed_tests++))
else
    echo -e "${RED}✗${NC} Initialize"
fi

if [ $TOOLS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Tools list"
    ((passed_tests++))
else
    echo -e "${RED}✗${NC} Tools list"
fi

if [ $RESOURCES_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Resources list"
    ((passed_tests++))
else
    echo -e "${RED}✗${NC} Resources list"
fi

if [ $NO_CONFLICT_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Tool/Resource separation"
    ((passed_tests++))
else
    echo -e "${RED}✗${NC} Tool/Resource separation"
fi

if [ $PROMPTS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Prompts list"
    ((passed_tests++))
else
    echo -e "${RED}✗${NC} Prompts list"
fi

echo ""
echo "Passed: $passed_tests/$total_tests"
echo ""

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
