#!/usr/bin/env python3
"""
MCP Schema Validator
Validates tool schemas returned by MCP server to identify Claude Desktop compatibility issues
"""

import json
import subprocess
import sys
from typing import Dict, List, Any


def validate_tool_schema(tool: Dict[str, Any]) -> List[str]:
    """Validate a single tool schema and return list of issues"""
    issues = []
    tool_name = tool.get("name", "unknown")

    # Check description field
    if "description" in tool:
        if not isinstance(tool["description"], str):
            issues.append(f"❌ {tool_name}: 'description' must be a string, got {type(tool['description']).__name__}")

    # Check inputSchema
    if "inputSchema" in tool:
        schema = tool["inputSchema"]
        if "properties" in schema:
            for prop_name, prop_def in schema["properties"].items():
                # Check default values
                if "default" in prop_def:
                    default = prop_def["default"]
                    # Empty arrays are problematic
                    if isinstance(default, list) and len(default) == 0:
                        issues.append(f"⚠️  {tool_name}.{prop_name}: 'default' is empty array [] - should be null or omitted")
                    # Arrays with weird values like ["c", "symbol", ...]
                    elif isinstance(default, list) and len(default) > 0 and default[0] == "c":
                        issues.append(f"❌ {tool_name}.{prop_name}: 'default' contains malformed array (R c() function?): {default}")

                # Check description
                if "description" in prop_def:
                    if not isinstance(prop_def["description"], str):
                        issues.append(f"❌ {tool_name}.{prop_name}: 'description' must be a string")

    return issues


def validate_prompt_schema(prompt: Dict[str, Any]) -> List[str]:
    """Validate a single prompt schema"""
    issues = []
    prompt_name = prompt.get("name", "unknown")

    if "description" in prompt:
        if not isinstance(prompt["description"], str):
            issues.append(f"❌ Prompt {prompt_name}: 'description' must be a string")

    if "arguments" in prompt:
        if not isinstance(prompt["arguments"], list):
            issues.append(f"❌ Prompt {prompt_name}: 'arguments' must be an array")

    return issues


def validate_resource_schema(resource: Dict[str, Any]) -> List[str]:
    """Validate a single resource schema"""
    issues = []
    resource_uri = resource.get("uri", "unknown")

    required_fields = ["uri", "name", "mimeType"]
    for field in required_fields:
        if field not in resource:
            issues.append(f"❌ Resource {resource_uri}: missing required field '{field}'")
        elif not isinstance(resource[field], str):
            issues.append(f"❌ Resource {resource_uri}: '{field}' must be a string")

    return issues


def get_mcp_capabilities(image: str = "hgnc-mcp:latest") -> Dict[str, Any]:
    """Get MCP server capabilities via stdio"""
    messages = [
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "validator", "version": "1.0"}
            }
        },
        {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
        {"jsonrpc": "2.0", "id": 3, "method": "prompts/list"},
        {"jsonrpc": "2.0", "id": 4, "method": "resources/list"}
    ]

    input_text = "\n".join(json.dumps(msg) for msg in messages) + "\n"

    cmd = [
        "docker", "run", "--rm", "-i",
        "-v", "hgnc-cache:/home/hgnc/.cache/hgnc",
        image, "--stdio"
    ]

    try:
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        stdout, stderr = process.communicate(input=input_text, timeout=30)

        # Extract JSON-RPC responses
        responses = {}
        for line in stdout.split('\n'):
            line = line.strip()
            if line.startswith('{') and '"jsonrpc"' in line:
                try:
                    response = json.loads(line)
                    if "id" in response and "result" in response:
                        responses[response["id"]] = response["result"]
                except json.JSONDecodeError:
                    continue

        return {
            "tools": responses.get(2, {}).get("tools", []),
            "prompts": responses.get(3, {}).get("prompts", []),
            "resources": responses.get(4, {}).get("resources", [])
        }

    except Exception as e:
        print(f"Error communicating with MCP server: {e}", file=sys.stderr)
        return {"tools": [], "prompts": [], "resources": []}


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate MCP server schemas for Claude Desktop compatibility"
    )
    parser.add_argument(
        "--image",
        default="hgnc-mcp:latest",
        help="Docker image to validate (default: hgnc-mcp:latest)"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON"
    )

    args = parser.parse_args()

    print(f"Validating MCP schemas for: {args.image}")
    print("=" * 60)
    print()

    # Get capabilities from server
    capabilities = get_mcp_capabilities(args.image)

    all_issues = []

    # Validate tools
    print(f"📋 Validating {len(capabilities['tools'])} tools...")
    for tool in capabilities["tools"]:
        issues = validate_tool_schema(tool)
        all_issues.extend(issues)
        if issues:
            for issue in issues:
                print(f"  {issue}")

    if not any(i.startswith("❌") or i.startswith("⚠️") for i in all_issues if "tool" in i.lower()):
        print("  ✅ All tools valid")
    print()

    # Validate prompts
    print(f"💡 Validating {len(capabilities['prompts'])} prompts...")
    prompt_issues_start = len(all_issues)
    for prompt in capabilities["prompts"]:
        issues = validate_prompt_schema(prompt)
        all_issues.extend(issues)
        if issues:
            for issue in issues:
                print(f"  {issue}")

    if len(all_issues) == prompt_issues_start:
        print("  ✅ All prompts valid")
    print()

    # Validate resources
    print(f"📦 Validating {len(capabilities['resources'])} resources...")
    resource_issues_start = len(all_issues)
    for resource in capabilities["resources"]:
        issues = validate_resource_schema(resource)
        all_issues.extend(issues)
        if issues:
            for issue in issues:
                print(f"  {issue}")

    if len(all_issues) == resource_issues_start:
        print("  ✅ All resources valid")
    print()

    # Summary
    print("=" * 60)
    critical_issues = [i for i in all_issues if i.startswith("❌")]
    warnings = [i for i in all_issues if i.startswith("⚠️")]

    if critical_issues:
        print(f"❌ Found {len(critical_issues)} CRITICAL issues")
        print(f"⚠️  Found {len(warnings)} warnings")
        print()
        print("These issues will cause Claude Desktop to disable the MCP server.")
        print()
        print("Critical issues:")
        for issue in critical_issues[:5]:  # Show first 5
            print(f"  {issue}")
        if len(critical_issues) > 5:
            print(f"  ... and {len(critical_issues) - 5} more")
        sys.exit(1)
    elif warnings:
        print(f"⚠️  Found {len(warnings)} warnings")
        print()
        print("These may cause issues with some MCP clients.")
        sys.exit(0)
    else:
        print("✅ All schemas are valid!")
        print()
        print("The MCP server should work correctly with Claude Desktop.")
        sys.exit(0)


if __name__ == "__main__":
    main()
