# HGNC Batch Operations using Cached Data
#
# High-performance batch normalization and validation functions using
# locally cached HGNC data for speed and offline operation

#' Build Symbol Index from Cached Data
#'
#' Creates an in-memory lookup index from cached HGNC data for fast symbol
#' resolution. The index maps symbols, aliases, and previous symbols to HGNC IDs.
#'
#' @param hgnc_data Optional data.frame of HGNC data. If NULL, will load from cache.
#'
#' @return A list containing:
#'   - `symbol_to_id`: Named character vector mapping symbols to HGNC IDs
#'   - `alias_to_id`: Named list mapping alias symbols to HGNC IDs (may have multiple matches)
#'   - `prev_to_id`: Named list mapping previous symbols to HGNC IDs (may have multiple matches)
#'   - `id_to_record`: Named list mapping HGNC IDs to full gene records
#'   - `indexed_at`: Timestamp of index creation
#'
#' @details
#' This function creates lookup tables that enable fast O(1) symbol resolution
#' without needing to query the REST API. It handles:
#' - Multiple aliases per gene (stored as lists)
#' - Multiple previous symbols per gene (stored as lists)
#' - Potential ambiguity (same alias/prev_symbol for multiple genes)
#'
#' The index is designed for use by `hgnc_normalize_list()` and other batch
#' operations that need to process many symbols quickly.
#'
#' @examples
#' \dontrun{
#' # Build index from cache
#' index <- build_symbol_index()
#'
#' # Look up a symbol
#' hgnc_id <- index$symbol_to_id["BRCA1"]
#'
#' # Get full record
#' gene <- index$id_to_record[[hgnc_id]]
#' print(gene$name)
#'
#' # Check aliases
#' if ("BRCA1" %in% names(index$alias_to_id)) {
#'   print(index$alias_to_id[["BRCA1"]])
#' }
#' }
#'
#' @export
build_symbol_index <- function(hgnc_data = NULL) {
  # Load data if not provided
  if (is.null(hgnc_data)) {
    hgnc_data <- load_hgnc_data()
  }

  message("Building symbol index from ", nrow(hgnc_data), " records...")

  # Initialize index structures
  symbol_to_id <- character()
  alias_to_id <- list()
  prev_to_id <- list()
  id_to_record <- list()

  # Process each record
  for (i in seq_len(nrow(hgnc_data))) {
    record <- hgnc_data[i, ]

    # Get HGNC ID (handle both formats: "HGNC:####" and plain number)
    hgnc_id <- record$hgnc_id
    if (is.na(hgnc_id) || is.null(hgnc_id)) next

    # Ensure hgnc_id is character
    hgnc_id <- as.character(hgnc_id)

    # Store full record by ID
    id_to_record[[hgnc_id]] <- as.list(record)

    # Index approved symbol -> HGNC ID (should be unique)
    if (!is.na(record$symbol) && nchar(record$symbol) > 0) {
      symbol_upper <- toupper(trimws(record$symbol))
      symbol_to_id[symbol_upper] <- hgnc_id
    }

    # Index alias symbols -> HGNC ID (may have multiple per gene, and multiple genes per alias)
    if (!is.na(record$alias_symbol) && nchar(record$alias_symbol) > 0) {
      # alias_symbol may be pipe-delimited
      aliases <- strsplit(as.character(record$alias_symbol), "\\|", fixed = FALSE)[[1]]
      aliases <- toupper(trimws(aliases))

      for (alias in aliases) {
        if (nchar(alias) > 0) {
          # Append to list (handle potential conflicts)
          if (alias %in% names(alias_to_id)) {
            alias_to_id[[alias]] <- unique(c(alias_to_id[[alias]], hgnc_id))
          } else {
            alias_to_id[[alias]] <- hgnc_id
          }
        }
      }
    }

    # Index previous symbols -> HGNC ID (may have multiple per gene, and multiple genes per prev)
    if (!is.na(record$prev_symbol) && nchar(record$prev_symbol) > 0) {
      # prev_symbol may be pipe-delimited
      prevs <- strsplit(as.character(record$prev_symbol), "\\|", fixed = FALSE)[[1]]
      prevs <- toupper(trimws(prevs))

      for (prev in prevs) {
        if (nchar(prev) > 0) {
          # Append to list (handle potential conflicts)
          if (prev %in% names(prev_to_id)) {
            prev_to_id[[prev]] <- unique(c(prev_to_id[[prev]], hgnc_id))
          } else {
            prev_to_id[[prev]] <- hgnc_id
          }
        }
      }
    }
  }

  message("Index complete: ", length(symbol_to_id), " symbols, ",
          length(alias_to_id), " aliases, ",
          length(prev_to_id), " previous symbols")

  list(
    symbol_to_id = symbol_to_id,
    alias_to_id = alias_to_id,
    prev_to_id = prev_to_id,
    id_to_record = id_to_record,
    indexed_at = Sys.time()
  )
}

#' Normalize Gene Symbol List
#'
#' Batch normalize a list of gene symbols using cached HGNC data. This function
#' is optimized for processing large lists of symbols quickly without making
#' REST API calls.
#'
#' @param symbols Character vector of gene symbols to normalize
#' @param return_fields Character vector of fields to include in output.
#'   Default includes essential fields. Use "all" to return all available fields.
#'   Common fields: symbol, name, hgnc_id, status, locus_type, location,
#'   entrez_id, ensembl_gene_id, uniprot_ids, alias_symbol, prev_symbol
#' @param status Character vector of statuses to include (default: "Approved").
#'   Set to NULL to include all statuses.
#' @param dedupe Logical, whether to deduplicate by HGNC ID (default: TRUE)
#' @param index Optional pre-built symbol index from `build_symbol_index()`.
#'   If NULL, will build index from cached data.
#'
#' @return A list containing:
#'   - `results`: Data frame with normalized gene information
#'   - `summary`: Summary statistics (total, found, not_found, withdrawn, duplicates)
#'   - `warnings`: Character vector of warning messages for problematic entries
#'   - `not_found`: Character vector of symbols that could not be resolved
#'   - `withdrawn`: Data frame of withdrawn genes (if any)
#'   - `duplicates`: Data frame of duplicate entries (if dedupe = TRUE)
#'
#' @details
#' This function performs the following steps:
#' 1. Normalizes input symbols (uppercase, trim whitespace)
#' 2. Resolves symbols using the index (checks symbol, then alias, then prev_symbol)
#' 3. Filters by status if specified
#' 4. Deduplicates by HGNC ID if requested
#' 5. Returns comprehensive results with warnings for problematic entries
#'
#' **Resolution Strategy**:
#' - First tries exact match on approved symbol (highest confidence)
#' - Then tries alias_symbol matches (medium confidence)
#' - Finally tries prev_symbol matches (lower confidence, gene may be renamed)
#' - Reports match type and potential ambiguity
#'
#' **Performance**:
#' - Uses in-memory lookups (no API calls)
#' - Can process thousands of symbols per second
#' - Ideal for bulk validation and normalization
#'
#' @examples
#' \dontrun{
#' # Basic normalization
#' symbols <- c("BRCA1", "BRCA2", "TP53", "INVALID", "withdrawn_gene")
#' result <- hgnc_normalize_list(symbols)
#'
#' # Check results
#' print(result$summary)
#' print(result$results)
#'
#' # View warnings
#' if (length(result$warnings) > 0) {
#'   cat(result$warnings, sep = "\n")
#' }
#'
#' # Include all statuses
#' result <- hgnc_normalize_list(symbols, status = NULL)
#'
#' # Custom fields
#' result <- hgnc_normalize_list(
#'   symbols,
#'   return_fields = c("symbol", "name", "hgnc_id", "entrez_id", "location")
#' )
#'
#' # Reuse index for multiple batches (more efficient)
#' index <- build_symbol_index()
#' result1 <- hgnc_normalize_list(batch1, index = index)
#' result2 <- hgnc_normalize_list(batch2, index = index)
#' }
#'
#' @export
hgnc_normalize_list <- function(symbols,
                                 return_fields = c("symbol", "name", "hgnc_id",
                                                  "status", "locus_type",
                                                  "location", "alias_symbol",
                                                  "prev_symbol"),
                                 status = "Approved",
                                 dedupe = TRUE,
                                 index = NULL) {
  if (missing(symbols) || is.null(symbols) || length(symbols) == 0) {
    stop("'symbols' must be a non-empty character vector", call. = FALSE)
  }

  # Convert to character if needed
  symbols <- as.character(symbols)

  # Build index if not provided
  if (is.null(index)) {
    index <- build_symbol_index()
  }

  message("Normalizing ", length(symbols), " symbols...")

  # Initialize results tracking
  results_list <- list()
  warnings_list <- character()
  not_found <- character()
  withdrawn_list <- list()
  duplicate_tracking <- list()

  # Process each symbol
  for (i in seq_along(symbols)) {
    original_symbol <- symbols[i]

    # Skip NA or empty
    if (is.na(original_symbol) || nchar(trimws(original_symbol)) == 0) {
      warnings_list <- c(warnings_list,
                        sprintf("Entry %d: Empty or NA symbol skipped", i))
      next
    }

    # Normalize symbol
    symbol_upper <- toupper(trimws(original_symbol))

    hgnc_id <- NULL
    match_type <- NA_character_
    ambiguous <- FALSE
    candidates <- NULL

    # Strategy 1: Try exact match on approved symbol
    if (symbol_upper %in% names(index$symbol_to_id)) {
      hgnc_id <- index$symbol_to_id[[symbol_upper]]
      match_type <- "exact"

    # Strategy 2: Try alias_symbol
    } else if (symbol_upper %in% names(index$alias_to_id)) {
      candidate_ids <- index$alias_to_id[[symbol_upper]]

      if (length(candidate_ids) == 1) {
        hgnc_id <- candidate_ids[1]
        match_type <- "alias"
      } else {
        # Ambiguous: multiple genes share this alias
        ambiguous <- TRUE
        candidates <- candidate_ids
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' matches %d genes via alias (ambiguous): %s",
                                 i, original_symbol, length(candidate_ids),
                                 paste(candidate_ids, collapse = ", ")))
      }

    # Strategy 3: Try prev_symbol
    } else if (symbol_upper %in% names(index$prev_to_id)) {
      candidate_ids <- index$prev_to_id[[symbol_upper]]

      if (length(candidate_ids) == 1) {
        hgnc_id <- candidate_ids[1]
        match_type <- "previous"
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' is a previous symbol (gene may have been renamed)",
                                 i, original_symbol))
      } else {
        # Ambiguous: multiple genes had this as previous symbol
        ambiguous <- TRUE
        candidates <- candidate_ids
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' matches %d genes via previous symbol (ambiguous): %s",
                                 i, original_symbol, length(candidate_ids),
                                 paste(candidate_ids, collapse = ", ")))
      }
    }

    # Handle not found
    if (is.null(hgnc_id) && !ambiguous) {
      not_found <- c(not_found, original_symbol)
      warnings_list <- c(warnings_list,
                        sprintf("Entry %d: '%s' not found in HGNC database",
                               i, original_symbol))
      next
    }

    # Handle ambiguous matches (for now, skip them)
    if (ambiguous) {
      not_found <- c(not_found, original_symbol)
      next
    }

    # Get full record
    gene_record <- index$id_to_record[[hgnc_id]]
    if (is.null(gene_record)) {
      warnings_list <- c(warnings_list,
                        sprintf("Entry %d: Gene record for HGNC ID '%s' not found",
                               i, hgnc_id))
      next
    }

    # Add metadata to record
    gene_record$query_symbol <- original_symbol
    gene_record$match_type <- match_type

    # Check status filter
    gene_status <- gene_record$status %||% NA_character_
    if (!is.null(status) && !(gene_status %in% status)) {
      # Check if withdrawn
      if (gene_status == "Withdrawn") {
        withdrawn_list[[length(withdrawn_list) + 1]] <- gene_record
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' maps to withdrawn gene '%s' (HGNC:%s)",
                                 i, original_symbol, gene_record$symbol %||% "NA", hgnc_id))
      } else {
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' has status '%s' (filtered out)",
                                 i, original_symbol, gene_status))
      }
      next
    }

    # Track duplicates
    if (dedupe) {
      if (hgnc_id %in% names(duplicate_tracking)) {
        # Duplicate found
        duplicate_tracking[[hgnc_id]] <- c(duplicate_tracking[[hgnc_id]], i)
        warnings_list <- c(warnings_list,
                          sprintf("Entry %d: '%s' is a duplicate of entry %d (same HGNC ID: %s)",
                                 i, original_symbol, duplicate_tracking[[hgnc_id]][1], hgnc_id))
        next
      } else {
        duplicate_tracking[[hgnc_id]] <- i
      }
    }

    # Add to results
    results_list[[length(results_list) + 1]] <- gene_record
  }

  # Convert results to data frame
  if (length(results_list) > 0) {
    results_df <- do.call(rbind.data.frame, c(results_list, stringsAsFactors = FALSE))

    # Select requested fields
    if (length(return_fields) == 1 && return_fields == "all") {
      # Return all fields
      final_results <- results_df
    } else {
      # Return only requested fields (include metadata fields)
      available_fields <- c(return_fields, "query_symbol", "match_type")
      available_fields <- available_fields[available_fields %in% names(results_df)]
      final_results <- results_df[, available_fields, drop = FALSE]
    }
  } else {
    # No results found
    final_results <- data.frame()
  }

  # Convert withdrawn list to data frame
  if (length(withdrawn_list) > 0) {
    withdrawn_df <- do.call(rbind.data.frame, c(withdrawn_list, stringsAsFactors = FALSE))
  } else {
    withdrawn_df <- data.frame()
  }

  # Create summary
  summary_info <- list(
    total_input = length(symbols),
    found = nrow(final_results),
    not_found = length(not_found),
    withdrawn = nrow(withdrawn_df),
    duplicates_removed = sum(lengths(duplicate_tracking) > 1),
    match_types = if (nrow(final_results) > 0) table(final_results$match_type) else NULL
  )

  message("Normalization complete: ", summary_info$found, " found, ",
          summary_info$not_found, " not found, ",
          summary_info$withdrawn, " withdrawn")

  # Return comprehensive results
  list(
    results = final_results,
    summary = summary_info,
    warnings = warnings_list,
    not_found = not_found,
    withdrawn = withdrawn_df,
    index_timestamp = index$indexed_at
  )
}

# Internal helper: %||% operator for NULL coalescing
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
