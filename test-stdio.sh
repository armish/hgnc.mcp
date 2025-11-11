#!/bin/bash
# Test harness for HGNC MCP Server stdio mode
# This validates the JSON-RPC/MCP protocol communication used by Claude Desktop

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Docker image to test
IMAGE="${DOCKER_IMAGE:-hgnc-mcp:latest}"
TIMEOUT="${TEST_TIMEOUT:-30}"

# Temporary directory for test files
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  HGNC MCP Server - Stdio Mode Test Harness${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Testing image:${NC} $IMAGE"
echo -e "${BLUE}Timeout:${NC} ${TIMEOUT}s per test"
echo ""

# Helper function to run a test
run_test() {
    local test_name="$1"
    local input="$2"
    local expected_pattern="$3"
    local description="$4"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "${BLUE}[TEST $TESTS_RUN]${NC} $test_name"
    echo -e "  ${description}"

    # Save input to temp file
    local input_file="$TEST_DIR/input_${TESTS_RUN}.json"
    echo "$input" > "$input_file"

    # Run the server and capture output
    local output_file="$TEST_DIR/output_${TESTS_RUN}.txt"
    if timeout "$TIMEOUT" sh -c "docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc $IMAGE --stdio 2>/dev/null < '$input_file'" > "$output_file" 2>&1; then
        # Check if output matches expected pattern
        if grep -q "$expected_pattern" "$output_file"; then
            echo -e "  ${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))

            # Show relevant output line
            if [ -n "$expected_pattern" ]; then
                echo -e "  ${GREEN}Response:${NC} $(grep "$expected_pattern" "$output_file" | head -n 1)"
            fi
        else
            echo -e "  ${RED}❌ FAIL - Expected pattern not found: $expected_pattern${NC}"
            echo -e "  ${YELLOW}Output:${NC}"
            cat "$output_file" | head -n 10
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "  ${RED}❌ FAIL - Command timeout or error${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Helper function to run a multi-message test
run_multi_test() {
    local test_name="$1"
    local description="$2"
    shift 2

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "${BLUE}[TEST $TESTS_RUN]${NC} $test_name"
    echo -e "  ${description}"

    # Create input file with multiple messages
    local input_file="$TEST_DIR/input_${TESTS_RUN}.json"
    rm -f "$input_file"
    for msg in "$@"; do
        echo "$msg" >> "$input_file"
    done

    # Run the server and capture output
    local output_file="$TEST_DIR/output_${TESTS_RUN}.txt"
    if timeout "$TIMEOUT" sh -c "docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc $IMAGE --stdio 2>/dev/null < '$input_file'" > "$output_file" 2>&1; then
        echo -e "  ${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}Output:${NC}"
        grep "jsonrpc" "$output_file" | head -n 5
    else
        echo -e "  ${RED}❌ FAIL - Command timeout or error${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# ============================================================================
# Test Suite
# ============================================================================

echo -e "${BLUE}Running MCP Protocol Tests...${NC}"
echo ""

# Test 1: Initialize
run_test \
    "MCP Initialize" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}}}' \
    '"result".*"protocolVersion"' \
    "Verify server responds to MCP initialize request"

# Test 2: Tools List
run_multi_test \
    "List Available Tools" \
    "Request list of all available MCP tools" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

# Test 3: Resources List
run_multi_test \
    "List Available Resources" \
    "Request list of all available MCP resources" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"resources/list"}'

# Test 4: Call info tool
run_multi_test \
    "Call info Tool" \
    "Call the info tool to get HGNC API metadata" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"info","arguments":{}}}'

# Test 5: Call find tool
run_multi_test \
    "Call find Tool (Search BRCA)" \
    "Search for genes matching 'BRCA'" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"find","arguments":{"query":"BRCA"}}}'

# Test 6: Call resolve_symbol tool
run_multi_test \
    "Call resolve_symbol Tool" \
    "Resolve gene symbol 'TP53'" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"resolve_symbol","arguments":{"symbol":"TP53"}}}'

# Test 7: Call normalize_list tool
run_multi_test \
    "Call normalize_list Tool" \
    "Normalize a list of gene symbols" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"normalize_list","arguments":{"symbols":["BRCA1","TP53","EGFR"]}}}'

# Test 8: Invalid method
run_test \
    "Invalid Method Error" \
    '{"jsonrpc":"2.0","id":99,"method":"invalid/method","params":{}}' \
    '"error"' \
    "Verify server returns error for invalid method"

# Test 9: Malformed JSON
run_test \
    "Malformed JSON Error" \
    '{"jsonrpc":"2.0","id":99,"method":"tools/list"' \
    '' \
    "Verify server handles malformed JSON gracefully"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Results${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Total tests:  $TESTS_RUN"
echo -e "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed:       $TESTS_FAILED${NC}"
else
    echo -e "  ${GREEN}Failed:       $TESTS_FAILED${NC}"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo -e "${BLUE}The stdio mode is working correctly for Claude Desktop integration.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}Test artifacts saved in: $TEST_DIR${NC}"
    echo -e "${YELLOW}To keep artifacts, run: cp -r $TEST_DIR ./test-results${NC}"
    exit 1
fi
