#!/usr/bin/env python3
"""
Test harness for HGNC MCP Server stdio mode
Tests the JSON-RPC/MCP protocol communication used by Claude Desktop
"""

import json
import subprocess
import sys
import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass


@dataclass
class TestResult:
    """Result of a single test"""
    name: str
    passed: bool
    message: str
    duration: float
    response: Optional[Dict] = None


class MCPStdioTester:
    """Test harness for MCP stdio protocol"""

    def __init__(self, image: str = "hgnc-mcp:latest", timeout: int = 30, verbose: bool = False):
        self.image = image
        self.timeout = timeout
        self.verbose = verbose
        self.results: List[TestResult] = []

    def send_message(self, message: Dict, expect_response: bool = True) -> Optional[Dict]:
        """Send a single JSON-RPC message and get response"""
        input_json = json.dumps(message) + "\n"

        cmd = [
            "docker", "run", "--rm", "-i",
            "-v", "hgnc-cache:/home/hgnc/.cache/hgnc",
            self.image, "--stdio"
        ]

        try:
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            stdout, stderr = process.communicate(input=input_json, timeout=self.timeout)

            if self.verbose:
                print(f"  Input: {message}")
                print(f"  Stderr: {stderr[:200] if stderr else '(none)'}")
                print(f"  Stdout: {stdout[:500] if stdout else '(none)'}")

            # Find JSON-RPC response in output
            for line in stdout.split('\n'):
                line = line.strip()
                if line.startswith('{') and '"jsonrpc"' in line:
                    try:
                        return json.loads(line)
                    except json.JSONDecodeError as e:
                        if self.verbose:
                            print(f"  JSON decode error: {e}")
                        continue

            return None

        except subprocess.TimeoutExpired:
            if self.verbose:
                print(f"  Timeout after {self.timeout}s")
            return None
        except Exception as e:
            if self.verbose:
                print(f"  Error: {e}")
            return None

    def send_sequence(self, messages: List[Dict]) -> List[Optional[Dict]]:
        """Send a sequence of messages in one session"""
        input_lines = [json.dumps(msg) for msg in messages]
        input_text = "\n".join(input_lines) + "\n"

        cmd = [
            "docker", "run", "--rm", "-i",
            "-v", "hgnc-cache:/home/hgnc/.cache/hgnc",
            self.image, "--stdio"
        ]

        try:
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            stdout, stderr = process.communicate(input=input_text, timeout=self.timeout)

            if self.verbose:
                print(f"  Stderr: {stderr[:200] if stderr else '(none)'}")

            # Extract all JSON-RPC responses
            responses = []
            for line in stdout.split('\n'):
                line = line.strip()
                if line.startswith('{') and '"jsonrpc"' in line:
                    try:
                        responses.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue

            return responses

        except subprocess.TimeoutExpired:
            return []
        except Exception as e:
            if self.verbose:
                print(f"  Error: {e}")
            return []

    def test_initialize(self) -> TestResult:
        """Test MCP initialize handshake"""
        start = time.time()

        msg = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test-client", "version": "1.0.0"}
            }
        }

        response = self.send_message(msg)
        duration = time.time() - start

        if response and "result" in response:
            if "protocolVersion" in response["result"]:
                return TestResult(
                    name="MCP Initialize",
                    passed=True,
                    message=f"Protocol version: {response['result']['protocolVersion']}",
                    duration=duration,
                    response=response
                )

        return TestResult(
            name="MCP Initialize",
            passed=False,
            message="No valid initialize response",
            duration=duration,
            response=response
        )

    def test_tools_list(self) -> TestResult:
        """Test listing available tools"""
        start = time.time()

        responses = self.send_sequence([
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "test", "version": "1.0"}
                }
            },
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/list"
            }
        ])

        duration = time.time() - start

        if len(responses) >= 2 and "result" in responses[1]:
            tools = responses[1]["result"].get("tools", [])
            return TestResult(
                name="List Tools",
                passed=True,
                message=f"Found {len(tools)} tools",
                duration=duration,
                response=responses[1]
            )

        return TestResult(
            name="List Tools",
            passed=False,
            message="Failed to get tools list",
            duration=duration,
            response=responses[1] if len(responses) > 1 else None
        )

    def test_resources_list(self) -> TestResult:
        """Test listing available resources"""
        start = time.time()

        responses = self.send_sequence([
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "test", "version": "1.0"}
                }
            },
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "resources/list"
            }
        ])

        duration = time.time() - start

        if len(responses) >= 2 and "result" in responses[1]:
            resources = responses[1]["result"].get("resources", [])
            return TestResult(
                name="List Resources",
                passed=True,
                message=f"Found {len(resources)} resources",
                duration=duration,
                response=responses[1]
            )

        return TestResult(
            name="List Resources",
            passed=False,
            message="Failed to get resources list",
            duration=duration,
            response=responses[1] if len(responses) > 1 else None
        )

    def test_call_tool(self, tool_name: str, arguments: Dict) -> TestResult:
        """Test calling a specific tool"""
        start = time.time()

        responses = self.send_sequence([
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "test", "version": "1.0"}
                }
            },
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": tool_name,
                    "arguments": arguments
                }
            }
        ])

        duration = time.time() - start

        if len(responses) >= 2:
            result = responses[1]
            if "result" in result:
                return TestResult(
                    name=f"Call Tool: {tool_name}",
                    passed=True,
                    message=f"Tool executed successfully",
                    duration=duration,
                    response=result
                )
            elif "error" in result:
                return TestResult(
                    name=f"Call Tool: {tool_name}",
                    passed=False,
                    message=f"Tool error: {result['error'].get('message', 'Unknown')}",
                    duration=duration,
                    response=result
                )

        return TestResult(
            name=f"Call Tool: {tool_name}",
            passed=False,
            message="No response from tool",
            duration=duration,
            response=responses[1] if len(responses) > 1 else None
        )

    def test_invalid_method(self) -> TestResult:
        """Test error handling for invalid method"""
        start = time.time()

        msg = {
            "jsonrpc": "2.0",
            "id": 99,
            "method": "invalid/method",
            "params": {}
        }

        response = self.send_message(msg)
        duration = time.time() - start

        if response and "error" in response:
            return TestResult(
                name="Invalid Method Error Handling",
                passed=True,
                message=f"Correctly returned error: {response['error'].get('message', 'Unknown')}",
                duration=duration,
                response=response
            )

        return TestResult(
            name="Invalid Method Error Handling",
            passed=False,
            message="Did not return error for invalid method",
            duration=duration,
            response=response
        )

    def run_all_tests(self) -> Tuple[int, int]:
        """Run all tests and return (passed, total) counts"""
        print("=" * 60)
        print("  HGNC MCP Server - Stdio Mode Test Suite")
        print("=" * 60)
        print(f"\nTesting image: {self.image}")
        print(f"Timeout: {self.timeout}s per test\n")

        # Define test suite
        tests = [
            self.test_initialize,
            self.test_tools_list,
            self.test_resources_list,
            lambda: self.test_call_tool("GET__tools_info", {}),
            lambda: self.test_call_tool("POST__tools_find", {"query": "BRCA"}),
            lambda: self.test_call_tool("POST__tools_resolve_symbol", {"symbol": "TP53"}),
            lambda: self.test_call_tool("POST__tools_normalize_list", {"symbols": ["BRCA1", "TP53", "EGFR"]}),
            lambda: self.test_call_tool("POST__tools_validate_panel", {"items": ["BRCA1", "TP53", "INVALID"]}),
            self.test_invalid_method,
        ]

        # Run tests
        for i, test in enumerate(tests, 1):
            print(f"[{i}/{len(tests)}] Running: ", end="", flush=True)
            result = test()
            self.results.append(result)

            status = "✅ PASS" if result.passed else "❌ FAIL"
            print(f"{result.name}")
            print(f"      {status} - {result.message} ({result.duration:.2f}s)")

            if self.verbose and result.response:
                print(f"      Response: {json.dumps(result.response)[:200]}")
            print()

        # Summary
        passed = sum(1 for r in self.results if r.passed)
        total = len(self.results)

        print("=" * 60)
        print("  Test Results")
        print("=" * 60)
        print(f"\nTotal tests:  {total}")
        print(f"Passed:       {passed} ✅")
        print(f"Failed:       {total - passed} {'✅' if total == passed else '❌'}")
        print(f"\nTotal time:   {sum(r.duration for r in self.results):.2f}s")

        if passed == total:
            print("\n✅ All tests passed!")
            print("\nThe stdio mode is working correctly for Claude Desktop integration.")
        else:
            print("\n❌ Some tests failed!")
            print("\nFailed tests:")
            for r in self.results:
                if not r.passed:
                    print(f"  - {r.name}: {r.message}")

        return passed, total


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Test harness for HGNC MCP Server stdio mode"
    )
    parser.add_argument(
        "--image",
        default="hgnc-mcp:latest",
        help="Docker image to test (default: hgnc-mcp:latest)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Timeout in seconds per test (default: 30)"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output"
    )

    args = parser.parse_args()

    tester = MCPStdioTester(
        image=args.image,
        timeout=args.timeout,
        verbose=args.verbose
    )

    passed, total = tester.run_all_tests()

    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
