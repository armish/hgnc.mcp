# Default HGNC data URL
.HGNC_DATA_URL <- paste0(
  "https://storage.googleapis.com/public-download-files/",
  "hgnc/tsv/tsv/hgnc_complete_set.txt"
)

#' Get HGNC cache directory
#'
#' Returns the path to the directory where HGNC data is cached.
#' Creates the directory if it doesn't exist.
#'
#' @return Character string with the path to the cache directory
#' @export
#' @examples
#' \dontrun{
#' get_hgnc_cache_dir()
#' }
get_hgnc_cache_dir <- function() {
  cache_dir <- rappdirs::user_cache_dir("hgnc.mcp")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  cache_dir
}

#' Get path to cached HGNC data file
#'
#' @return Character string with the path to the cached data file
#' @keywords internal
get_hgnc_cache_path <- function() {
  file.path(get_hgnc_cache_dir(), "hgnc_complete_set.txt")
}

#' Get path to cache metadata file
#'
#' @return Character string with the path to the metadata file
#' @keywords internal
get_hgnc_metadata_path <- function() {
  file.path(get_hgnc_cache_dir(), "cache_metadata.rds")
}

#' Check if cached HGNC data exists and is fresh
#'
#' @param max_age_days Maximum age of cache in days before it's considered stale (default: 30)
#' @return Logical indicating whether cache exists and is fresh
#' @export
#' @examples
#' \dontrun{
#' is_hgnc_cache_fresh()
#' is_hgnc_cache_fresh(max_age_days = 7)
#' }
is_hgnc_cache_fresh <- function(max_age_days = 30) {
  cache_path <- get_hgnc_cache_path()
  metadata_path <- get_hgnc_metadata_path()

  if (!file.exists(cache_path) || !file.exists(metadata_path)) {
    return(FALSE)
  }

  metadata <- readRDS(metadata_path)
  cache_age <- as.numeric(difftime(Sys.time(), metadata$download_time, units = "days"))

  cache_age < max_age_days
}

#' Download HGNC data from the official source
#'
#' Downloads the complete HGNC dataset from the official Google Cloud Storage
#' and saves it to the cache directory along with metadata.
#'
#' @param url URL to the HGNC data file (default: official HGNC complete set)
#' @param force Force download even if cache exists (default: FALSE)
#' @return Invisible path to the cached file
#' @export
#' @examples
#' \dontrun{
#' download_hgnc_data()
#' download_hgnc_data(force = TRUE)
#' }
download_hgnc_data <- function(url = .HGNC_DATA_URL, force = FALSE) {
  cache_path <- get_hgnc_cache_path()
  metadata_path <- get_hgnc_metadata_path()

  if (!force && file.exists(cache_path)) {
    message("Cache already exists. Use force = TRUE to re-download.")
    return(invisible(cache_path))
  }

  message("Downloading HGNC data from: ", url)

  # Download the file
  response <- httr::GET(url, httr::write_disk(cache_path, overwrite = TRUE))

  if (httr::http_error(response)) {
    stop("Failed to download HGNC data. HTTP status: ", httr::status_code(response))
  }

  # Save metadata
  metadata <- list(
    download_time = Sys.time(),
    url = url,
    file_size = file.info(cache_path)$size,
    http_status = httr::status_code(response)
  )

  saveRDS(metadata, metadata_path)

  message("HGNC data successfully downloaded and cached at: ", cache_path)
  invisible(cache_path)
}

#' Load HGNC data
#'
#' Loads the HGNC complete dataset. If the data is not cached or the cache is
#' stale, it will download the latest version first.
#'
#' @param max_age_days Maximum age of cache in days (default: 30)
#' @param force Force download even if cache is fresh (default: FALSE)
#' @return A data.frame containing the HGNC complete dataset
#' @export
#' @examples
#' \dontrun{
#' hgnc <- load_hgnc_data()
#' head(hgnc)
#' }
load_hgnc_data <- function(max_age_days = 30, force = FALSE) {
  cache_path <- get_hgnc_cache_path()

  # Download if cache doesn't exist, is stale, or force is TRUE
  if (force || !is_hgnc_cache_fresh(max_age_days)) {
    download_hgnc_data(force = TRUE)
  } else if (!file.exists(cache_path)) {
    download_hgnc_data()
  }

  message("Loading HGNC data from cache...")
  data <- readr::read_tsv(cache_path, show_col_types = FALSE)
  message("Loaded ", nrow(data), " gene records with ", ncol(data), " fields")

  data
}

#' Get cache information
#'
#' Returns information about the cached HGNC data including download time,
#' file size, and age.
#'
#' @return A list with cache information or NULL if no cache exists
#' @export
#' @examples
#' \dontrun{
#' get_hgnc_cache_info()
#' }
get_hgnc_cache_info <- function() {
  cache_path <- get_hgnc_cache_path()
  metadata_path <- get_hgnc_metadata_path()

  if (!file.exists(cache_path) || !file.exists(metadata_path)) {
    message("No cache found")
    return(NULL)
  }

  metadata <- readRDS(metadata_path)
  file_info <- file.info(cache_path)

  list(
    cache_path = cache_path,
    download_time = metadata$download_time,
    age_days = as.numeric(difftime(Sys.time(), metadata$download_time, units = "days")),
    file_size_mb = round(file_info$size / 1024^2, 2),
    url = metadata$url
  )
}
