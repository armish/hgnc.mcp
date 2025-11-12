# Claude Desktop Compatibility Issue

## Status: IDENTIFIED

The MCP server connects successfully but is **disabled in Claude
Desktop** due to invalid tool schemas.

## Root Cause

`plumber2mcp` is incorrectly serializing R default parameter values that
use [`c()`](https://rdrr.io/r/base/c.html):

### What’s Happening

``` r
# R function definition
hgnc_normalize_list <- function(
  return_fields = c("symbol", "name", "hgnc_id")
)
```

Gets serialized to MCP as:

``` json
{
  "default": ["c", "symbol", "name", "hgnc_id"]
}
```

**Should be:**

``` json
{
  "default": ["symbol", "name", "hgnc_id"]
}
```

The literal string `"c"` is being included as the first array element
instead of evaluating the R expression.

## Validation Results

``` bash
$ python3 validate-mcp-schema.py
```

### Critical Issues (3)

1.  ❌ **`POST__tools_normalize_list`**: `description` is an array
    instead of string
2.  ❌ **`POST__tools_normalize_list.return_fields`**: malformed default
    `['c', 'symbol', ...]`
3.  ❌ **`POST__tools_changes.fields`**: malformed default
    `['c', 'symbol', ...]`

### Warnings (10)

Multiple tools have `"default": []` (empty array) which should be `null`
or omitted.

## Impact

- ✅ **Stdio protocol works** - Basic MCP communication is fine
- ✅ **Protocol validation passes** - Server responds correctly to MCP
  methods
- ✅ **Tools execute** - Can call tools and get results
- ❌ **Claude Desktop disables server** - Schema validation fails
- ❌ **Cannot use with Claude Desktop** - Server appears but is not
  clickable

## Evidence

From `~/Library/Logs/Claude/mcp*.log`:

    2025-11-11T23:26:47.380Z [info] [hgnc-local] Initializing server...
    2025-11-11T23:26:47.388Z [info] [hgnc-local] Server started and connected successfully
    2025-11-11T23:26:48.564Z [info] [hgnc-local] Message from server: {"jsonrpc":"2.0",...}

Server connects and responds, but Claude Desktop UI shows it as disabled
(grayed out).

## Solutions

### 1. Fix plumber2mcp (Recommended)

**File:** Likely in `plumber2mcp`’s schema generation code

**Change needed:** When extracting default parameter values from R
functions, evaluate the R expression instead of serializing it as-is:

``` r
# Current (wrong)
default <- deparse(formals(fn)[[param]])  # Returns "c(\"symbol\", \"name\")"

# Fixed (correct)
default <- eval(formals(fn)[[param]])  # Returns c("symbol", "name")
```

Then serialize the evaluated result to JSON.

### 2. Workaround in R Code

**Files to change:** - `R/hgnc_batch.R` -
[`hgnc_normalize_list()`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md) -
`R/hgnc_changes.R` or similar -
[`hgnc_changes()`](https://armish.github.io/hgnc.mcp/reference/hgnc_changes.md)

**Change:**

``` r
# Before
hgnc_normalize_list <- function(
  symbols,
  return_fields = c("symbol", "name", "hgnc_id", ...),
  ...
)

# After
hgnc_normalize_list <- function(
  symbols,
  return_fields = NULL,
  ...
) {
  if (is.null(return_fields)) {
    return_fields <- c("symbol", "name", "hgnc_id", ...)
  }
  # ... rest of function
}
```

### 3. Fix the Description Array Issue

**File:** Likely `R/mcp_server.R` or where the plumber API is defined

The `POST__tools_normalize_list` endpoint has a `description` that’s an
array. This needs investigation - check if it’s defined multiple times
or if there’s a bug in how roxygen2 comments are being converted.

## Testing

### Validate Schemas

``` bash
# Check for schema issues
./validate-mcp-schema.py

# Should show:
# ✅ All schemas are valid!
```

### Test with Claude Desktop

1.  Fix the schemas
2.  Rebuild Docker: `docker compose build`
3.  Restart Claude Desktop
4.  Server should now be enabled (not grayed out)

### Automated Tests Still Work

The stdio test harness continues to work because it doesn’t enforce
strict schema validation:

``` bash
./test_mcp_stdio.py  # ✅ 8/9 tests pass
```

## Upstream Issue

This should be reported to: - **Repository**:
<https://github.com/armish/plumber2mcp> - **Issue**: “Default parameter
values using c() are incorrectly serialized in MCP schemas”

## Workaround Until Fixed

The server works via stdio mode for testing, just not with Claude
Desktop’s UI. You can still:

1.  ✅ Test locally with `./test_mcp_stdio.py`
2.  ✅ Test with manual MCP requests
3.  ✅ Use HTTP mode for debugging
4.  ❌ Cannot use Claude Desktop UI (shows as disabled)

Once the schema is fixed, Claude Desktop will work normally.

## References

- MCP Specification: <https://spec.modelcontextprotocol.io/>
- Tool Schema Format:
  <https://spec.modelcontextprotocol.io/specification/server/tools/>
- JSON Schema: <https://json-schema.org/>

## Validation Tool

Use the included validator to check for these issues:

``` bash
./validate-mcp-schema.py [--image hgnc-mcp:latest]
```

This will identify all schema violations that prevent Claude Desktop
compatibility.
