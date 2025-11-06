# HGNC REST API Client
#
# Base client for interacting with the HGNC REST API
# API Documentation: https://www.genenames.org/help/rest/

# Package-level environment for rate limiting and caching
.hgnc_env <- new.env(parent = emptyenv())

# Initialize rate limiter state
.hgnc_env$rate_limiter <- list(
  max_requests_per_second = 10,
  request_times = numeric(0)
)

#' Rate Limiter for HGNC API Requests
#'
#' Ensures we don't exceed HGNC's rate limit of 10 requests per second.
#' Uses a sliding window approach.
#'
#' @keywords internal
#' @noRd
rate_limit_wait <- function() {
  rl <- .hgnc_env$rate_limiter
  current_time <- Sys.time()

  # Remove requests older than 1 second
  one_second_ago <- current_time - 1
  rl$request_times <- rl$request_times[rl$request_times > as.numeric(one_second_ago)]

  # If we've hit the limit, wait until the oldest request is >1 second old
  if (length(rl$request_times) >= rl$max_requests_per_second) {
    oldest_request <- min(rl$request_times)
    wait_until <- oldest_request + 1
    wait_time <- max(0, wait_until - as.numeric(current_time))

    if (wait_time > 0) {
      Sys.sleep(wait_time)
      current_time <- Sys.time()
    }

    # Clean up again after waiting
    one_second_ago <- current_time - 1
    rl$request_times <- rl$request_times[rl$request_times > as.numeric(one_second_ago)]
  }

  # Record this request
  rl$request_times <- c(rl$request_times, as.numeric(current_time))
  .hgnc_env$rate_limiter <- rl

  invisible(NULL)
}

#' Base HTTP Client for HGNC REST API
#'
#' Makes HTTP GET requests to the HGNC REST API with rate limiting,
#' error handling, retries, and automatic JSON parsing.
#'
#' @param endpoint API endpoint path (e.g., "info", "search/BRCA1")
#' @param base_url Base URL for HGNC REST API
#' @param timeout Request timeout in seconds
#' @param max_retries Maximum number of retry attempts
#' @param parse_json Whether to parse JSON response automatically
#'
#' @return Parsed JSON response (if parse_json=TRUE) or raw httr response object
#'
#' @details
#' The function implements:
#' - Rate limiting: ≤10 requests per second (HGNC requirement)
#' - User-Agent header identifying the hgnc.mcp package
#' - Automatic retries with exponential backoff for transient failures
#' - Comprehensive error handling with informative messages
#' - JSON parsing with helpful error messages
#'
#' @examples
#' \dontrun{
#' # Get HGNC API info
#' info <- hgnc_rest_get("info")
#'
#' # Search for a gene
#' results <- hgnc_rest_get("search/BRCA1")
#' }
#'
#' @export
hgnc_rest_get <- function(endpoint,
                          base_url = "https://rest.genenames.org",
                          timeout = 30,
                          max_retries = 3,
                          parse_json = TRUE) {

  # Apply rate limiting
  rate_limit_wait()

  # Build full URL
  url <- paste0(base_url, "/", sub("^/", "", endpoint))

  # Set User-Agent header
  pkg_version <- utils::packageVersion("hgnc.mcp")
  user_agent <- sprintf("hgnc.mcp/%s (R package; https://github.com/armish/hgnc.mcp)", pkg_version)

  # Make request with retries
  tryCatch({
    response <- httr::RETRY(
      "GET",
      url,
      httr::add_headers(
        "User-Agent" = user_agent,
        "Accept" = "application/json"
      ),
      httr::timeout(timeout),
      times = max_retries,
      pause_base = 1,
      pause_cap = 60,
      quiet = FALSE
    )

    # Check for HTTP errors
    if (httr::http_error(response)) {
      status_code <- httr::status_code(response)
      error_msg <- sprintf(
        "HGNC API request failed [%s]: %s",
        status_code,
        url
      )

      # Try to extract error message from response
      tryCatch({
        content <- httr::content(response, as = "text", encoding = "UTF-8")
        parsed <- jsonlite::fromJSON(content, simplifyVector = FALSE)
        if (!is.null(parsed$message)) {
          error_msg <- sprintf("%s - %s", error_msg, parsed$message)
        }
      }, error = function(e) {
        # If we can't parse the error, just use the basic message
      })

      stop(error_msg, call. = FALSE)
    }

    # Parse JSON if requested
    if (parse_json) {
      content_text <- httr::content(response, as = "text", encoding = "UTF-8")

      if (nchar(content_text) == 0) {
        stop("HGNC API returned empty response", call. = FALSE)
      }

      tryCatch({
        parsed <- jsonlite::fromJSON(content_text, simplifyVector = FALSE)
        return(parsed)
      }, error = function(e) {
        stop(
          sprintf("Failed to parse JSON response from HGNC API: %s", e$message),
          call. = FALSE
        )
      })
    } else {
      return(response)
    }

  }, error = function(e) {
    # Re-throw with more context if it's a connection error
    if (grepl("Could not resolve host|Timeout|Connection", e$message, ignore.case = TRUE)) {
      stop(
        sprintf("Network error connecting to HGNC API: %s", e$message),
        call. = FALSE
      )
    }
    stop(e$message, call. = FALSE)
  })
}

#' Get HGNC REST API Information
#'
#' Retrieves metadata about the HGNC REST API, including the last modification
#' date, searchable fields, and stored fields. Useful for cache invalidation
#' decisions and understanding API capabilities.
#'
#' @param use_cache Whether to use session-level caching (default: TRUE)
#'
#' @return A list containing:
#'   - lastModified: Timestamp of last database update
#'   - searchableFields: Fields that can be used in search queries
#'   - storedFields: All fields stored in gene records
#'
#' @details
#' The /info endpoint provides:
#' - `lastModified`: ISO 8601 timestamp of the last HGNC database update.
#'   Use this to determine if your local cache is stale.
#' - `searchableFields`: Fields you can filter/search on
#' - `storedFields`: All available fields in gene records
#'
#' This function is cached by default using memoise, so repeated calls
#' within the same R session will return instantly without hitting the API.
#' The cache can be cleared with `clear_hgnc_cache()`.
#'
#' @examples
#' \dontrun{
#' # Get API info
#' info <- hgnc_rest_info()
#'
#' # Check last modification date
#' last_modified <- info$lastModified
#' print(last_modified)
#'
#' # See what fields are searchable
#' print(info$searchableFields)
#'
#' # See what fields are stored
#' print(info$storedFields)
#' }
#'
#' @seealso [clear_hgnc_cache()] to clear the session cache
#'
#' @export
hgnc_rest_info_uncached <- function() {
  result <- hgnc_rest_get("info")

  # The API returns a wrapper object
  if (!is.null(result$responseHeader)) {
    # Extract useful fields
    response <- list(
      lastModified = result$responseHeader$lastModified %||% NA_character_,
      searchableFields = result$searchableFields %||% character(0),
      storedFields = result$storedFields %||% character(0)
    )
    return(response)
  }

  return(result)
}

# Create cached version using memoise
#' @rdname hgnc_rest_info_uncached
#' @export
hgnc_rest_info <- memoise::memoise(hgnc_rest_info_uncached)

#' Clear HGNC Session Cache
#'
#' Clears all session-level caches used by hgnc.mcp REST API functions.
#' This forces fresh API calls on the next request.
#'
#' @return Invisible NULL
#'
#' @details
#' This clears the memoise cache for functions like `hgnc_rest_info()`.
#' It does NOT affect:
#' - The local file cache (hgnc_complete_set.txt)
#' - The rate limiter state
#'
#' You might want to clear the cache when:
#' - You know the HGNC database has been updated
#' - You're debugging and want to ensure fresh data
#' - You're running tests
#'
#' @examples
#' \dontrun{
#' # Get info (will hit API)
#' info1 <- hgnc_rest_info()
#'
#' # Get info again (will use cache)
#' info2 <- hgnc_rest_info()
#'
#' # Clear cache
#' clear_hgnc_cache()
#'
#' # Get info again (will hit API)
#' info3 <- hgnc_rest_info()
#' }
#'
#' @export
clear_hgnc_cache <- function() {
  # Clear memoise cache for hgnc_rest_info
  memoise::forget(hgnc_rest_info)

  # Clear memoise cache for hgnc_group_members if it exists
  if (exists("hgnc_group_members_memo", envir = .hgnc_env)) {
    memoise::forget(.hgnc_env$hgnc_group_members_memo)
  }

  invisible(NULL)
}

#' Reset HGNC Rate Limiter
#'
#' Resets the rate limiter state. Primarily useful for testing.
#'
#' @return Invisible NULL
#'
#' @keywords internal
#' @export
reset_rate_limiter <- function() {
  .hgnc_env$rate_limiter$request_times <- numeric(0)
  invisible(NULL)
}

# Null-coalescing operator helper
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
