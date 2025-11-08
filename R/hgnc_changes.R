# HGNC Change Tracking & Validation
#
# Functions for tracking gene nomenclature changes over time and validating
# gene lists against HGNC policies

#' Track Gene Nomenclature Changes
#'
#' Query genes that have been modified since a specified date. This is useful
#' for monitoring watchlists, ensuring compliance, and staying up-to-date with
#' nomenclature changes.
#'
#' @param since Date from which to track changes. Can be a Date object,
#'   character string (ISO 8601 format: "YYYY-MM-DD"), or POSIXct object.
#' @param fields Character vector of fields to include in the results.
#'   Default: c("symbol", "name", "status").
#'   Common date fields: date_modified, date_symbol_changed, date_name_changed,
#'   date_approved_reserved
#' @param change_type Type of changes to track. One of:
#'   - "all": All changes (default)
#'   - "symbol": Only symbol changes
#'   - "name": Only name changes
#'   - "status": Only status changes
#'   - "modified": Any modification
#' @param use_cache Whether to use locally cached data (default: TRUE).
#'   If FALSE, will attempt to use REST API date filtering (may not be supported).
#'
#' @return A list containing:
#'   - `changes`: Data frame of genes modified since the specified date
#'   - `summary`: Summary statistics (total changes, by type, etc.)
#'   - `since`: The date used for filtering (for reference)
#'   - `query_time`: When the query was executed
#'
#' @details
#' This function identifies genes that have been modified since a given date by
#' examining the HGNC date fields:
#' - `date_modified`: Last modification date (any field)
#' - `date_symbol_changed`: When the symbol was last changed
#' - `date_name_changed`: When the name was last changed
#' - `date_approved_reserved`: When the gene was approved/reserved
#'
#' The function uses cached HGNC data for speed and reliability. Date fields
#' in HGNC data are in ISO 8601 format (YYYY-MM-DD).
#'
#' @examples
#' \dontrun{
#' # Find all genes modified in the last 30 days
#' recent_changes <- hgnc_changes(since = Sys.Date() - 30)
#' print(recent_changes$summary)
#'
#' # Find symbol changes since a specific date
#' symbol_changes <- hgnc_changes(
#'   since = "2024-01-01",
#'   change_type = "symbol"
#' )
#'
#' # Include more fields and date information
#' detailed_changes <- hgnc_changes(
#'   since = "2023-06-01",
#'   fields = c("symbol", "name", "status", "prev_symbol",
#'             "date_modified", "date_symbol_changed")
#' )
#'
#' # View changes
#' print(detailed_changes$changes)
#' }
#'
#' @export
hgnc_changes <- function(
  since,
  fields = c("symbol", "name", "status"),
  change_type = c("all", "symbol", "name", "status", "modified"),
  use_cache = TRUE
) {
  if (missing(since) || is.null(since)) {
    stop(
      "'since' parameter is required (Date, POSIXct, or character in YYYY-MM-DD format)",
      call. = FALSE
    )
  }

  # Parse and validate the date
  since_date <- tryCatch(
    {
      if (inherits(since, "Date")) {
        since
      } else if (inherits(since, "POSIXct") || inherits(since, "POSIXt")) {
        as.Date(since)
      } else if (is.character(since)) {
        as.Date(since)
      } else {
        stop("'since' must be a Date, POSIXct, or character string")
      }
    },
    error = function(e) {
      stop(
        sprintf(
          "Invalid date format for 'since': %s. Use YYYY-MM-DD format.",
          since
        ),
        call. = FALSE
      )
    }
  )

  change_type <- match.arg(change_type)

  # Always use cached data (REST API doesn't support date filtering well)
  if (!use_cache) {
    message(
      "Note: REST API date filtering is limited. Using cached data instead."
    )
  }

  message("Loading HGNC data to track changes since ", since_date, "...")
  hgnc_data <- load_hgnc_data()

  # Ensure date fields are available and parse them
  date_fields <- c(
    "date_modified",
    "date_symbol_changed",
    "date_name_changed",
    "date_approved_reserved"
  )
  available_date_fields <- intersect(date_fields, names(hgnc_data))

  if (length(available_date_fields) == 0) {
    warning(
      "No date fields found in HGNC data. Cannot track changes.",
      call. = FALSE
    )
    return(list(
      changes = data.frame(),
      summary = list(total = 0, since = since_date),
      since = since_date,
      query_time = Sys.time()
    ))
  }

  # Parse date fields (they should be in YYYY-MM-DD format)
  for (date_field in available_date_fields) {
    if (date_field %in% names(hgnc_data)) {
      hgnc_data[[date_field]] <- as.Date(hgnc_data[[date_field]])
    }
  }

  # Filter based on change type
  changed_genes_idx <- switch(
    change_type,
    "all" = {
      # Any date field >= since_date
      idx <- rep(FALSE, nrow(hgnc_data))
      for (df in available_date_fields) {
        if (df %in% names(hgnc_data)) {
          idx <- idx | (!is.na(hgnc_data[[df]]) & hgnc_data[[df]] >= since_date)
        }
      }
      idx
    },
    "symbol" = {
      # Symbol changed
      if ("date_symbol_changed" %in% names(hgnc_data)) {
        !is.na(hgnc_data$date_symbol_changed) &
          hgnc_data$date_symbol_changed >= since_date
      } else {
        rep(FALSE, nrow(hgnc_data))
      }
    },
    "name" = {
      # Name changed
      if ("date_name_changed" %in% names(hgnc_data)) {
        !is.na(hgnc_data$date_name_changed) &
          hgnc_data$date_name_changed >= since_date
      } else {
        rep(FALSE, nrow(hgnc_data))
      }
    },
    "status" = {
      # For status changes, we use date_modified as a proxy
      # (HGNC data doesn't have a specific date_status_changed field)
      if ("date_modified" %in% names(hgnc_data)) {
        !is.na(hgnc_data$date_modified) & hgnc_data$date_modified >= since_date
      } else {
        rep(FALSE, nrow(hgnc_data))
      }
    },
    "modified" = {
      # General modification
      if ("date_modified" %in% names(hgnc_data)) {
        !is.na(hgnc_data$date_modified) & hgnc_data$date_modified >= since_date
      } else {
        rep(FALSE, nrow(hgnc_data))
      }
    }
  )

  changed_genes <- hgnc_data[changed_genes_idx, ]

  # Select requested fields plus date fields
  all_requested_fields <- unique(c(fields, "hgnc_id", available_date_fields))
  available_fields <- intersect(all_requested_fields, names(changed_genes))

  if (length(available_fields) > 0) {
    results <- changed_genes[, available_fields, drop = FALSE]
  } else {
    results <- changed_genes
  }

  # Calculate summary statistics
  summary_info <- list(
    total = nrow(results),
    since = since_date,
    change_type = change_type,
    date_fields_checked = available_date_fields
  )

  # Add breakdown by change type if we have the date fields
  if (nrow(results) > 0) {
    if ("date_symbol_changed" %in% names(results)) {
      summary_info$symbol_changes <- sum(
        !is.na(results$date_symbol_changed) &
          results$date_symbol_changed >= since_date
      )
    }
    if ("date_name_changed" %in% names(results)) {
      summary_info$name_changes <- sum(
        !is.na(results$date_name_changed) &
          results$date_name_changed >= since_date
      )
    }
    if ("date_modified" %in% names(results)) {
      summary_info$modified <- sum(
        !is.na(results$date_modified) &
          results$date_modified >= since_date
      )
    }
    if ("status" %in% names(results)) {
      summary_info$by_status <- table(results$status)
    }
  }

  message("Found ", nrow(results), " genes with changes since ", since_date)

  list(
    changes = results,
    summary = summary_info,
    since = since_date,
    query_time = Sys.time()
  )
}

#' Validate Gene Panel Against HGNC Policy
#'
#' Perform quality assurance on gene lists against HGNC nomenclature policy.
#' This function checks for non-approved symbols, withdrawn genes, duplicates,
#' and provides replacement suggestions with rationale.
#'
#' @param items Character vector of gene symbols/identifiers to validate
#' @param policy Validation policy to apply. Currently only "HGNC" is supported,
#'   which enforces:
#'   - Only approved symbols
#'   - No withdrawn genes
#'   - No duplicate entries
#'   - Proper nomenclature format
#' @param suggest_replacements Logical, whether to suggest replacements for
#'   problematic symbols using prev_symbol and alias_symbol mappings (default: TRUE)
#' @param include_dates Logical, whether to include date information for changes
#'   (default: TRUE)
#' @param index Optional pre-built symbol index from `build_symbol_index()`.
#'   If NULL, will build index from cached data.
#'
#' @return A list containing:
#'   - `valid`: Data frame of genes that passed all validation checks
#'   - `issues`: Data frame of genes with validation issues
#'   - `summary`: Summary of validation results
#'   - `report`: Character vector with human-readable validation report
#'   - `replacements`: Suggested replacements for problematic entries (if enabled)
#'
#' @details
#' The validation process checks for:
#'
#' **1. Non-Approved Symbols**
#' - Symbols that don't match current approved HGNC symbols
#' - May be aliases, previous symbols, or invalid entries
#'
#' **2. Withdrawn Genes**
#' - Genes with status = "Withdrawn"
#' - No longer valid identifiers
#' - Replacements suggested where possible
#'
#' **3. Duplicates**
#' - Multiple entries that map to the same HGNC ID
#' - Can occur with mixed use of symbols and aliases
#'
#' **4. Not Found**
#' - Symbols that don't exist in HGNC database
#' - May be typos, non-human genes, or outdated identifiers
#'
#' **Replacement Strategy**:
#' - For previous symbols: suggests current approved symbol with change date
#' - For aliases: suggests official symbol
#' - For withdrawn genes: attempts to find merged/replaced gene
#' - Includes rationale and dates where available
#'
#' @examples
#' \dontrun{
#' # Basic validation
#' gene_panel <- c("BRCA1", "TP53", "EGFR", "KRAS", "MYC")
#' validation <- hgnc_validate_panel(gene_panel)
#'
#' # View summary
#' print(validation$summary)
#'
#' # View readable report
#' cat(validation$report, sep = "\n")
#'
#' # Check for issues
#' if (nrow(validation$issues) > 0) {
#'   print(validation$issues)
#' }
#'
#' # Get suggested replacements
#' if (length(validation$replacements) > 0) {
#'   print(validation$replacements)
#' }
#'
#' # Validate with mixed quality input
#' messy_panel <- c(
#'   "BRCA1",         # Valid
#'   "brca1",         # Valid (case insensitive)
#'   "BRCA1",         # Duplicate
#'   "OLDNAME",       # Previous symbol
#'   "WITHDRAWN",     # Withdrawn gene
#'   "NOTREAL"        # Invalid
#' )
#' validation <- hgnc_validate_panel(messy_panel)
#' cat(validation$report, sep = "\n")
#' }
#'
#' @export
hgnc_validate_panel <- function(
  items,
  policy = "HGNC",
  suggest_replacements = TRUE,
  include_dates = TRUE,
  index = NULL
) {
  if (missing(items) || is.null(items) || length(items) == 0) {
    stop("'items' must be a non-empty character vector", call. = FALSE)
  }

  if (policy != "HGNC") {
    stop("Currently only 'HGNC' policy is supported", call. = FALSE)
  }

  # Convert to character
  items <- as.character(items)

  message("Validating ", length(items), " items against HGNC policy...")

  # Build index if not provided
  if (is.null(index)) {
    index <- build_symbol_index()
  }

  # Initialize tracking structures
  valid_genes <- list()
  issues_list <- list()
  replacements_list <- list()
  report_lines <- character()

  # Track HGNC IDs we've seen for duplicate detection
  seen_hgnc_ids <- character()

  # Process each item
  for (i in seq_along(items)) {
    item <- items[i]
    original_item <- item

    # Skip NA or empty
    if (is.na(item) || nchar(trimws(item)) == 0) {
      issues_list[[length(issues_list) + 1]] <- list(
        position = i,
        input = original_item,
        issue = "empty_or_na",
        severity = "error",
        message = "Empty or NA value"
      )
      next
    }

    # Normalize
    item_upper <- toupper(trimws(item))

    # Try to resolve the symbol
    hgnc_id <- NULL
    match_type <- NA_character_
    gene_record <- NULL

    # 1. Try exact match on approved symbol
    if (item_upper %in% names(index$symbol_to_id)) {
      hgnc_id <- index$symbol_to_id[[item_upper]]
      match_type <- "exact"
      gene_record <- index$id_to_record[[hgnc_id]]

      # 2. Try alias
    } else if (item_upper %in% names(index$alias_to_id)) {
      candidate_ids <- index$alias_to_id[[item_upper]]

      if (length(candidate_ids) == 1) {
        hgnc_id <- candidate_ids[1]
        match_type <- "alias"
        gene_record <- index$id_to_record[[hgnc_id]]

        # This is an issue: using alias instead of approved symbol
        issue_msg <- sprintf(
          "'%s' is an alias. Approved symbol: '%s'",
          original_item,
          gene_record$symbol %||% "Unknown"
        )
        issues_list[[length(issues_list) + 1]] <- list(
          position = i,
          input = original_item,
          issue = "alias_used",
          severity = "warning",
          message = issue_msg,
          approved_symbol = gene_record$symbol %||% NA_character_,
          hgnc_id = hgnc_id
        )

        if (suggest_replacements) {
          replacements_list[[length(replacements_list) + 1]] <- list(
            position = i,
            input = original_item,
            suggested = gene_record$symbol %||% NA_character_,
            rationale = "Use approved symbol instead of alias",
            match_type = "alias"
          )
        }
      } else {
        # Ambiguous
        issue_msg <- sprintf(
          "'%s' is ambiguous (matches %d genes via alias)",
          original_item,
          length(candidate_ids)
        )
        issues_list[[length(issues_list) + 1]] <- list(
          position = i,
          input = original_item,
          issue = "ambiguous",
          severity = "error",
          message = issue_msg,
          candidates = paste(candidate_ids, collapse = ", ")
        )
        next
      }

      # 3. Try previous symbol
    } else if (item_upper %in% names(index$prev_to_id)) {
      candidate_ids <- index$prev_to_id[[item_upper]]

      if (length(candidate_ids) == 1) {
        hgnc_id <- candidate_ids[1]
        match_type <- "previous"
        gene_record <- index$id_to_record[[hgnc_id]]

        # This is an issue: using outdated symbol
        date_info <- ""
        if (
          include_dates &&
            !is.null(gene_record$date_symbol_changed) &&
            !is.na(gene_record$date_symbol_changed)
        ) {
          date_info <- sprintf(
            " (changed on %s)",
            gene_record$date_symbol_changed
          )
        }

        issue_msg <- sprintf(
          "'%s' is a previous symbol. Current symbol: '%s'%s",
          original_item,
          gene_record$symbol %||% "Unknown",
          date_info
        )
        issues_list[[length(issues_list) + 1]] <- list(
          position = i,
          input = original_item,
          issue = "previous_symbol",
          severity = "warning",
          message = issue_msg,
          approved_symbol = gene_record$symbol %||% NA_character_,
          hgnc_id = hgnc_id,
          date_changed = if (include_dates) {
            gene_record$date_symbol_changed %||% NA
          } else {
            NA
          }
        )

        if (suggest_replacements) {
          replacements_list[[length(replacements_list) + 1]] <- list(
            position = i,
            input = original_item,
            suggested = gene_record$symbol %||% NA_character_,
            rationale = sprintf("Symbol was changed%s", date_info),
            match_type = "previous",
            date_changed = if (include_dates) {
              gene_record$date_symbol_changed %||% NA
            } else {
              NA
            }
          )
        }
      } else {
        # Ambiguous
        issue_msg <- sprintf(
          "'%s' is ambiguous (matches %d genes via previous symbol)",
          original_item,
          length(candidate_ids)
        )
        issues_list[[length(issues_list) + 1]] <- list(
          position = i,
          input = original_item,
          issue = "ambiguous",
          severity = "error",
          message = issue_msg,
          candidates = paste(candidate_ids, collapse = ", ")
        )
        next
      }
    } else {
      # Not found
      issue_msg <- sprintf("'%s' not found in HGNC database", original_item)
      issues_list[[length(issues_list) + 1]] <- list(
        position = i,
        input = original_item,
        issue = "not_found",
        severity = "error",
        message = issue_msg
      )
      next
    }

    # Check if we have a valid gene record
    if (is.null(gene_record)) {
      issues_list[[length(issues_list) + 1]] <- list(
        position = i,
        input = original_item,
        issue = "no_record",
        severity = "error",
        message = "Gene record not found"
      )
      next
    }

    # Check status
    gene_status <- gene_record$status %||% NA_character_

    if (!is.na(gene_status) && gene_status == "Withdrawn") {
      issue_msg <- sprintf(
        "'%s' maps to withdrawn gene '%s'",
        original_item,
        gene_record$symbol %||% "Unknown"
      )
      issues_list[[length(issues_list) + 1]] <- list(
        position = i,
        input = original_item,
        issue = "withdrawn",
        severity = "error",
        message = issue_msg,
        symbol = gene_record$symbol %||% NA_character_,
        hgnc_id = hgnc_id
      )

      # For withdrawn genes, we can't easily suggest replacements without
      # additional metadata, but we note it
      if (suggest_replacements) {
        replacements_list[[length(replacements_list) + 1]] <- list(
          position = i,
          input = original_item,
          suggested = NA_character_,
          rationale = "Gene has been withdrawn. Check HGNC for merged/replacement gene.",
          match_type = "withdrawn"
        )
      }
      next
    }

    # Check for duplicates (same HGNC ID)
    if (hgnc_id %in% seen_hgnc_ids) {
      first_position <- match(hgnc_id, seen_hgnc_ids)
      issue_msg <- sprintf(
        "'%s' is a duplicate of position %d (same HGNC ID: %s)",
        original_item,
        first_position,
        hgnc_id
      )
      issues_list[[length(issues_list) + 1]] <- list(
        position = i,
        input = original_item,
        issue = "duplicate",
        severity = "warning",
        message = issue_msg,
        hgnc_id = hgnc_id,
        duplicate_of_position = first_position
      )
      next
    }

    # Mark as seen
    seen_hgnc_ids[length(seen_hgnc_ids) + 1] <- hgnc_id

    # If we got here and match_type is exact and status is Approved, it's valid
    if (match_type == "exact" && gene_status == "Approved") {
      valid_genes[[length(valid_genes) + 1]] <- list(
        position = i,
        input = original_item,
        symbol = gene_record$symbol %||% NA_character_,
        name = gene_record$name %||% NA_character_,
        hgnc_id = hgnc_id,
        status = gene_status
      )
    }
  }

  # Convert lists to data frames
  valid_df <- if (length(valid_genes) > 0) {
    do.call(rbind.data.frame, c(valid_genes, stringsAsFactors = FALSE))
  } else {
    data.frame()
  }

  issues_df <- if (length(issues_list) > 0) {
    do.call(rbind.data.frame, c(issues_list, stringsAsFactors = FALSE))
  } else {
    data.frame()
  }

  # Generate summary
  summary_info <- list(
    total_items = length(items),
    valid = nrow(valid_df),
    issues = nrow(issues_df),
    policy = policy
  )

  # Break down issues by type
  if (nrow(issues_df) > 0) {
    summary_info$issues_by_type <- table(issues_df$issue)
    summary_info$issues_by_severity <- table(issues_df$severity)
  }

  # Generate human-readable report
  report_lines <- c(
    "=== HGNC Gene Panel Validation Report ===",
    "",
    sprintf("Total items: %d", summary_info$total_items),
    sprintf("Valid (approved symbols): %d", summary_info$valid),
    sprintf("Issues found: %d", summary_info$issues),
    ""
  )

  if (nrow(issues_df) > 0) {
    report_lines <- c(report_lines, "Issues by type:")
    for (issue_type in names(summary_info$issues_by_type)) {
      count <- summary_info$issues_by_type[[issue_type]]
      report_lines <- c(report_lines, sprintf("  - %s: %d", issue_type, count))
    }
    report_lines <- c(report_lines, "")

    report_lines <- c(report_lines, "Detailed issues:")
    for (i in seq_len(nrow(issues_df))) {
      issue <- issues_df[i, ]
      report_lines <- c(
        report_lines,
        sprintf(
          "  [%s] Position %d: %s",
          toupper(issue$severity),
          issue$position,
          issue$message
        )
      )
    }
  } else {
    report_lines <- c(
      report_lines,
      "No issues found. All symbols are valid approved HGNC symbols."
    )
  }

  if (suggest_replacements && length(replacements_list) > 0) {
    report_lines <- c(report_lines, "", "Suggested replacements:")
    for (repl in replacements_list) {
      if (!is.na(repl$suggested)) {
        report_lines <- c(
          report_lines,
          sprintf(
            "  Position %d: '%s' -> '%s' (%s)",
            repl$position,
            repl$input,
            repl$suggested,
            repl$rationale
          )
        )
      } else {
        report_lines <- c(
          report_lines,
          sprintf(
            "  Position %d: '%s' - %s",
            repl$position,
            repl$input,
            repl$rationale
          )
        )
      }
    }
  }

  message(
    "Validation complete: ",
    summary_info$valid,
    " valid, ",
    summary_info$issues,
    " issues"
  )

  list(
    valid = valid_df,
    issues = issues_df,
    summary = summary_info,
    report = report_lines,
    replacements = replacements_list
  )
}

# Internal helper: %||% operator for NULL coalescing
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
