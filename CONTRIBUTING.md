# Contributing to hgnc.mcp

We welcome contributions to hgnc.mcp! This document provides guidelines
for contributing to the project.

## Code of Conduct

Please be respectful and considerate in all interactions. We aim to
foster an inclusive and welcoming environment for all contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:

1.  A clear, descriptive title
2.  A minimal reproducible example (reprex)
3.  Your session info
    ([`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html))
4.  Expected vs. actual behavior

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an
enhancement suggestion:

1.  Use a clear, descriptive title
2.  Provide a detailed description of the proposed functionality
3.  Explain why this enhancement would be useful
4.  If possible, provide examples of how it would work

### Pull Requests

We actively welcome pull requests! Here’s the process:

1.  **Fork the repository** and create your branch from `main`
2.  **Make your changes**:
    - Follow the existing code style
    - Add tests for new functionality
    - Update documentation as needed
    - Ensure all tests pass
3.  **Commit your changes**:
    - Use clear, descriptive commit messages
    - Reference relevant issues (e.g., “Fixes \#123”)
4.  **Push to your fork** and submit a pull request

#### Pull Request Guidelines

- **One feature per PR**: Keep pull requests focused on a single feature
  or bug fix
- **Update documentation**: Include roxygen2 documentation for new
  functions
- **Add tests**: All new code should have corresponding tests
- **Check CI**: Ensure all GitHub Actions checks pass
- **Update NEWS.md**: Add a bullet point describing your changes

### Development Setup

1.  Clone the repository:

    ``` bash
    git clone https://github.com/armish/hgnc.mcp.git
    cd hgnc.mcp
    ```

2.  Install dependencies:

    ``` r
    install.packages("remotes")
    remotes::install_deps(dependencies = TRUE)
    ```

3.  Install the package locally:

    ``` r
    devtools::load_all()  # For interactive development
    # or
    devtools::install()   # To install the package
    ```

4.  Run tests:

    ``` r
    devtools::test()
    ```

5.  Check the package:

    ``` r
    devtools::check()
    ```

### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use `styler::style_pkg()` to automatically format code
- Use `lintr::lint_package()` to check for style issues
- Keep functions focused and well-documented
- Use meaningful variable and function names

### Documentation

- All exported functions must have complete roxygen2 documentation
- Include `@examples` that demonstrate usage
- Update vignettes if adding major new functionality
- Keep README.md up to date

### Testing

- Write tests for all new functionality using testthat
- Aim for high test coverage (\>80%)
- Include both unit tests and integration tests where appropriate
- Tests should be self-contained and reproducible
- Use `skip_on_cran()` for tests that require internet access

### Docker and Deployment

If your changes affect the MCP server or Docker deployment:

- Test the Docker build locally: `docker build -t hgnc-mcp:test .`
- Verify the server starts correctly
- Update deployment documentation if needed
- Test with docker-compose if applicable

### Continuous Integration

All pull requests are automatically tested using GitHub Actions:

- **R-CMD-check**: Tests on multiple OS/R version combinations
- **test-coverage**: Measures code coverage and reports to Codecov
- **docker-build**: Builds and tests Docker image

Ensure all checks pass before requesting review.

## Development Workflow

### Adding a New Function

1.  Write the function in the appropriate `R/*.R` file
2.  Add roxygen2 documentation with:
    - `@title` and `@description`
    - `@param` for each parameter
    - `@return` describing the return value
    - `@export` if the function should be user-facing
    - `@examples` with runnable examples
3.  Update `NAMESPACE` with `devtools::document()`
4.  Add tests in `tests/testthat/test-*.R`
5.  Update relevant vignettes if needed
6.  Run `devtools::check()` to ensure everything works

### Working with the MCP Server

The MCP server is built using plumber and plumber2mcp:

- Server code: `R/mcp_server.R`
- API endpoints: `inst/plumber/hgnc_api.R` (if it exists)
- Resources: `R/hgnc_resources.R`
- Prompts: `R/hgnc_prompts.R`

When modifying the server:

1.  Test locally with
    [`start_hgnc_mcp_server()`](https://armish.github.io/hgnc.mcp/reference/start_hgnc_mcp_server.md)
2.  Check the Swagger UI at `http://localhost:8080/__docs__/`
3.  Test MCP integration with a client if possible
4.  Update server documentation

### Updating Dependencies

If you need to add a new dependency:

1.  Add it to `DESCRIPTION` under `Imports:` or `Suggests:`
2.  Use `Imports:` for required dependencies
3.  Use `Suggests:` for optional dependencies (testing, vignettes, etc.)
4.  Document why the dependency is needed
5.  Consider the CRAN policy on dependencies

## Release Process

(For maintainers)

1.  Update version in `DESCRIPTION` (follow semantic versioning)
2.  Update `NEWS.md` with changes since last release
3.  Run `devtools::check()` and ensure no errors/warnings
4.  Update `cran-comments.md` with submission notes
5.  Build and test tarball: `devtools::build()` and
    `R CMD check --as-cran`
6.  Submit to CRAN if ready
7.  Tag release on GitHub
8.  Build and push Docker image with version tag

## Questions?

If you have questions about contributing, please:

1.  Check existing issues and pull requests
2.  Review the documentation and vignettes
3.  Open a new issue with your question

Thank you for contributing to hgnc.mcp! 🎉
