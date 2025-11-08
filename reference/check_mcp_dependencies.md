# Check MCP Server Dependencies

Verify that all required packages for running the MCP server are
installed and provide installation instructions if any are missing.

## Usage

``` r
check_mcp_dependencies()
```

## Value

Logical. TRUE if all dependencies are available, FALSE otherwise

## Examples

``` r
check_mcp_dependencies()
#> [OK] Found: plumber
#> [OK] Found: plumber2mcp
#> 
#> [OK] All MCP server dependencies are installed!
```
