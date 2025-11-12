# Testing Stdio Mode - HGNC MCP Server

This directory contains test harnesses for validating the stdio mode of
the HGNC MCP server. Stdio mode is used by Claude Desktop and other MCP
clients for local communication.

## Quick Start

``` bash
# Test with Python (recommended)
./test_mcp_stdio.py

# Test with Bash (simpler, less detailed)
./test-stdio.sh

# Test specific image
./test_mcp_stdio.py --image ghcr.io/armish/hgnc.mcp:latest

# Verbose output for debugging
./test_mcp_stdio.py -v
```

## Test Harnesses

### 1. Python Test Harness (`test_mcp_stdio.py`)

**Recommended** - More comprehensive and easier to extend.

``` bash
./test_mcp_stdio.py [OPTIONS]

Options:
  --image IMAGE    Docker image to test (default: hgnc-mcp:latest)
  --timeout N      Timeout in seconds per test (default: 30)
  -v, --verbose    Verbose output with full responses

Examples:
  # Test local build
  ./test_mcp_stdio.py

  # Test published image
  ./test_mcp_stdio.py --image ghcr.io/armish/hgnc.mcp:latest

  # Debug mode
  ./test_mcp_stdio.py -v --timeout 60
```

**Features:** - ✅ MCP protocol validation - ✅ JSON-RPC message
handling - ✅ Individual tool testing - ✅ Error handling verification -
✅ Detailed test reports - ✅ Exit code for CI/CD integration

### 2. Bash Test Harness (`test-stdio.sh`)

Simpler shell-based testing.

``` bash
./test-stdio.sh

Environment variables:
  DOCKER_IMAGE     Docker image to test (default: hgnc-mcp:latest)
  TEST_TIMEOUT     Timeout per test in seconds (default: 30)

Examples:
  # Test local build
  ./test-stdio.sh

  # Test with custom timeout
  TEST_TIMEOUT=60 ./test-stdio.sh
```

**Features:** - ✅ Basic MCP protocol tests - ✅ Tool invocation tests -
✅ Simple output format - ✅ No dependencies (just bash, docker, jq)

## Test Coverage

The test harnesses validate:

| Test               | Description                   | Protocol                |
|--------------------|-------------------------------|-------------------------|
| **Initialize**     | MCP handshake                 | `initialize` method     |
| **List Tools**     | Enumerate available tools     | `tools/list` method     |
| **List Resources** | Enumerate available resources | `resources/list` method |
| **Call Tools**     | Execute individual tools      | `tools/call` method     |
| **Error Handling** | Invalid method errors         | Error responses         |

### Tested Tools

1.  `GET__tools_info` - Get HGNC API metadata
2.  `POST__tools_find` - Search for genes
3.  `POST__tools_resolve_symbol` - Resolve gene symbols
4.  `POST__tools_normalize_list` - Batch normalize symbols
5.  `POST__tools_validate_panel` - Validate gene panels

## Integration with Development Workflow

### Local Development

``` bash
# 1. Make code changes
vim R/hgnc_mcp_server.R

# 2. Rebuild Docker image
docker compose build

# 3. Run stdio tests
./test_mcp_stdio.py

# 4. If tests pass, test with Claude Desktop
# (see below)
```

### CI/CD Integration

``` yaml
# Example GitHub Actions workflow
- name: Test Stdio Mode
  run: |
    docker compose build
    ./test_mcp_stdio.py --timeout 60
```

The test script exits with: - `0` if all tests pass - `1` if any test
fails

## Testing with Claude Desktop

After the stdio tests pass, you can test with Claude Desktop:

### 1. Update Claude Desktop Config

**macOS**:
`~/Library/Application Support/Claude/claude_desktop_config.json`

``` json
{
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
}
```

### 2. Restart Claude Desktop

### 3. Verify in Claude

Ask Claude: *“What MCP servers are available?”*

You should see `hgnc-local` listed with its tools.

## Manual Testing

You can manually send MCP messages to test specific scenarios:

``` bash
# Test initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio

# Test tool list
(
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
) | docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio

# Test specific tool
(
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"POST__tools_find","arguments":{"query":"BRCA"}}}'
) | docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio
```

## Troubleshooting

### Tests timeout

``` bash
# Increase timeout
./test_mcp_stdio.py --timeout 60
```

### Server not responding

``` bash
# Check if image exists
docker images | grep hgnc-mcp

# Rebuild if needed
docker compose build

# Test HTTP mode first
docker compose up -d
curl http://localhost:8080/__docs__/
```

### Cache issues

``` bash
# Clear Docker cache
docker volume rm hgnc-cache

# Re-run tests (will download HGNC data on first run)
./test_mcp_stdio.py --timeout 120
```

### Verbose debugging

``` bash
# Run with verbose output
./test_mcp_stdio.py -v

# Check Docker logs
docker run --rm -i -v hgnc-cache:/home/hgnc/.cache/hgnc hgnc-mcp:latest --stdio < test_input.json
```

## Performance Benchmarks

Typical test execution times:

| Test Type   | Duration | Notes               |
|-------------|----------|---------------------|
| Single test | 0.7-1.5s | Per test            |
| Full suite  | 8-12s    | All 9 tests         |
| First run   | 30-60s   | Downloads HGNC data |

## Extending the Tests

### Adding New Test Cases (Python)

Edit `test_mcp_stdio.py`:

``` python
def test_my_custom_tool(self) -> TestResult:
    """Test my custom tool"""
    start = time.time()

    responses = self.send_sequence([
        # Initialize
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {...}
        },
        # Call tool
        {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "POST__tools_my_tool",
                "arguments": {"arg": "value"}
            }
        }
    ])

    duration = time.time() - start

    if len(responses) >= 2 and "result" in responses[1]:
        return TestResult(
            name="My Custom Tool",
            passed=True,
            message="Tool works!",
            duration=duration,
            response=responses[1]
        )

    return TestResult(
        name="My Custom Tool",
        passed=False,
        message="Failed",
        duration=duration
    )

# Add to test suite in run_all_tests()
tests = [
    # ... existing tests ...
    self.test_my_custom_tool,
]
```

### Adding New Test Cases (Bash)

Edit `test-stdio.sh`:

``` bash
run_multi_test \
    "My Custom Tool Test" \
    "Description of what this tests" \
    '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{...}}'
```

## Related Documentation

- [Quick Test Script](https://armish.github.io/hgnc.mcp/quick-test.sh) -
  Full build and test workflow
- [Docker Compose
  Setup](https://armish.github.io/hgnc.mcp/docker-compose.yml) - Local
  server setup
- [README](https://armish.github.io/hgnc.mcp/README.md) - General
  project documentation

## Support

If you encounter issues with the test harnesses:

1.  Check this troubleshooting guide
2.  Review test output with `-v` flag
3.  Open an issue at <https://github.com/armish/hgnc.mcp/issues>
