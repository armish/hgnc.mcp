# CRAN Submission Notes

## Test environments

* Local: Ubuntu 22.04, R 4.4.0
* GitHub Actions:
  - macOS-latest (release)
  - windows-latest (release)
  - ubuntu-latest (devel, release, oldrel-1)

## R CMD check results

0 errors ✓ | 0 warnings ✓ | 0 notes ✓

## Package-specific notes

### Dependencies
* The package depends on `plumber2mcp` which is currently only available from GitHub (armish/plumber2mcp)
* This is specified in the Remotes field
* For CRAN submission, we will either:
  1. Wait for `plumber2mcp` to be published on CRAN, or
  2. Move MCP server functionality to Suggests and make it optional

### External Data
* The package downloads HGNC nomenclature data from the official HGNC source
* Data is cached locally using platform-appropriate directories (via rappdirs)
* Cache size is approximately 15-20 MB when populated
* Users can control cache behavior via function parameters

### Internet Resources
* Some tests require internet access to test REST API functionality
* These tests use `skip_on_cran()` to avoid issues during CRAN checks
* Core functionality works offline using cached data

### Examples
* All examples are wrapped in `\donttest{}` where they require internet access
* Examples that use cached data run unconditionally
* No examples require more than 5 seconds to run

### Size
* Source package size: ~1.1 MB (excluding downloaded cache data)
* Well under CRAN's 5 MB recommended limit

## Downstream dependencies

This is a new package with no reverse dependencies.

## Notes for CRAN maintainers

This package provides tools for working with HGNC (HUGO Gene Nomenclature Committee)
gene nomenclature data. It is designed for researchers and bioinformaticians who
need to normalize gene symbols, validate gene panels, and track nomenclature changes.

The package also includes a Model Context Protocol (MCP) server for integration with
AI assistants, which is an emerging standard for connecting LLMs to external tools.

We have taken care to:
* Follow CRAN policies on package size and dependencies
* Properly handle internet resources with skip_on_cran()
* Use appropriate caching strategies to minimize network usage
* Provide comprehensive documentation and vignettes

Please let us know if you have any questions or concerns.
