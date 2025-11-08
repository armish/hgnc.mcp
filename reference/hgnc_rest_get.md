# Base HTTP Client for HGNC REST API

Makes HTTP GET requests to the HGNC REST API with rate limiting, error
handling, retries, and automatic JSON parsing.

## Usage

``` r
hgnc_rest_get(
  endpoint,
  base_url = "https://rest.genenames.org",
  timeout = 30,
  max_retries = 3,
  parse_json = TRUE
)
```

## Arguments

- endpoint:

  API endpoint path (e.g., "info", "search/BRCA1")

- base_url:

  Base URL for HGNC REST API

- timeout:

  Request timeout in seconds

- max_retries:

  Maximum number of retry attempts

- parse_json:

  Whether to parse JSON response automatically

## Value

Parsed JSON response (if parse_json=TRUE) or raw httr response object

## Details

The function implements:

- Rate limiting: ≤10 requests per second (HGNC requirement)

- User-Agent header identifying the hgnc.mcp package

- Automatic retries with exponential backoff for transient failures

- Comprehensive error handling with informative messages

- JSON parsing with helpful error messages

## Examples

``` r
if (FALSE) { # \dontrun{
# Get HGNC API info
info <- hgnc_rest_get("info")

# Search for a gene
results <- hgnc_rest_get("search/BRCA1")
} # }
```
