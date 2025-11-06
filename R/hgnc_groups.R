# HGNC Gene Groups & Collections
#
# Functions for working with HGNC gene groups and gene families

#' Get Members of a Gene Group
#'
#' Retrieve all genes that belong to a specific HGNC gene group or family.
#' Gene groups represent functionally related genes such as protein families,
#' complexes, or genes with shared characteristics.
#'
#' @param group_id_or_name Either a numeric gene group ID or a gene group name.
#'   Gene group IDs are integers (e.g., 588 for "Zinc fingers C2H2-type").
#'   Names can be full or partial matches (e.g., "Zinc finger" or "immunoglobulin").
#' @param use_cache Whether to use session-level caching (default: TRUE).
#'   Gene groups don't change frequently, so caching is recommended.
#'
#' @return A list containing:
#'   - `numFound`: Number of genes in the group
#'   - `docs`: List of gene records for all group members
#'   - `group_id_or_name`: The query parameter for reference
#'
#' @details
#' This function queries the HGNC REST API to fetch all genes associated with
#' a specific gene group. Each gene record includes:
#' - Core identifiers: hgnc_id, symbol, name, status
#' - Location: location, chromosome
#' - Cross-references: entrez_id, ensembl_gene_id, etc.
#' - Group memberships: gene_group, gene_group_id
#'
#' Gene groups are hierarchical and genes may belong to multiple groups.
#'
#' By default, results are cached for the R session since gene group memberships
#' are relatively stable. Use `use_cache = FALSE` to force a fresh API call.
#'
#' @examples
#' \dontrun{
#' # Get members by group ID
#' zinc_fingers <- hgnc_group_members(588)
#' print(zinc_fingers$numFound)
#' print(zinc_fingers$docs[[1]]$symbol)
#'
#' # Get members by group name (searches for matching group)
#' # Note: This will search for groups matching the name first
#' kinases <- hgnc_group_members("kinase")
#'
#' # Iterate over all members
#' for (gene in zinc_fingers$docs) {
#'   cat(gene$symbol, "-", gene$name, "\n")
#' }
#'
#' # Force fresh data without cache
#' current_data <- hgnc_group_members(588, use_cache = FALSE)
#' }
#'
#' @seealso [hgnc_search_groups()] to find group IDs by keyword
#'
#' @export
hgnc_group_members_uncached <- function(group_id_or_name) {
  if (missing(group_id_or_name) || is.null(group_id_or_name)) {
    stop("'group_id_or_name' is required", call. = FALSE)
  }

  # Convert to character for URL encoding
  group_term <- as.character(group_id_or_name)

  if (nchar(trimws(group_term)) == 0) {
    stop("'group_id_or_name' must be a non-empty value", call. = FALSE)
  }

  # If the input looks like a group name (contains spaces or non-numeric),
  # we need to search for the group first
  if (grepl("[^0-9]", group_term)) {
    # This is likely a group name, search for it
    search_results <- hgnc_search_groups(group_term)

    if (search_results$numFound == 0) {
      warning(sprintf("No gene groups found matching '%s'", group_id_or_name), call. = FALSE)
      return(list(
        numFound = 0,
        docs = list(),
        group_id_or_name = group_id_or_name
      ))
    }

    # Use the first matching group's ID
    group_id <- search_results$groups[[1]]$id
    group_term <- as.character(group_id)
  }

  # Build endpoint for fetching by gene_group_id
  endpoint <- paste0("fetch/gene_group_id/", utils::URLencode(group_term, reserved = TRUE))

  # Make request
  tryCatch({
    result <- hgnc_rest_get(endpoint)

    # Extract response
    if (!is.null(result$response)) {
      response <- list(
        numFound = result$response$numFound %||% 0,
        docs = result$response$docs %||% list(),
        group_id_or_name = group_id_or_name
      )
      return(response)
    }

    # Fallback if response structure is different
    return(result)

  }, error = function(e) {
    # Handle case where group doesn't exist
    if (grepl("404|not found", e$message, ignore.case = TRUE)) {
      warning(sprintf("Gene group '%s' not found", group_id_or_name), call. = FALSE)
      return(list(
        numFound = 0,
        docs = list(),
        group_id_or_name = group_id_or_name
      ))
    }
    # Re-throw other errors
    stop(e$message, call. = FALSE)
  })
}

# Create cached version using memoise
#' @rdname hgnc_group_members_uncached
#' @export
hgnc_group_members <- function(group_id_or_name, use_cache = TRUE) {
  if (use_cache) {
    # Use memoised version
    if (!exists("hgnc_group_members_memo", envir = .hgnc_env)) {
      .hgnc_env$hgnc_group_members_memo <- memoise::memoise(hgnc_group_members_uncached)
    }
    .hgnc_env$hgnc_group_members_memo(group_id_or_name)
  } else {
    # Call uncached version
    hgnc_group_members_uncached(group_id_or_name)
  }
}

#' Search for Gene Groups
#'
#' Search for HGNC gene groups by keyword. Gene groups represent functionally
#' related genes such as protein families, complexes, or genes with shared
#' characteristics.
#'
#' @param query Search query string (e.g., "kinase", "zinc finger", "immunoglobulin")
#' @param limit Maximum number of results to return (default: 100)
#'
#' @return A list containing:
#'   - `numFound`: Total number of matching groups
#'   - `groups`: List of matching gene group records, each containing:
#'     - `id`: Gene group ID (numeric)
#'     - `name`: Gene group name
#'     - `description`: Detailed description (if available)
#'   - `query`: The original query for reference
#'
#' @details
#' This function searches the HGNC database for gene groups matching your query.
#' Groups are collections of functionally related genes, such as:
#' - Protein families (e.g., "Zinc fingers", "Kinases", "Immunoglobulins")
#' - Gene complexes (e.g., "Proteasome", "Ribosomal proteins")
#' - Functional categories (e.g., "Transcription factors", "G-protein coupled receptors")
#'
#' The search is performed across group names and descriptions, returning
#' groups with relevance-based ranking.
#'
#' Once you have a group ID, use `hgnc_group_members()` to retrieve all genes
#' in that group.
#'
#' @examples
#' \dontrun{
#' # Search for kinase groups
#' kinase_groups <- hgnc_search_groups("kinase")
#' print(kinase_groups$numFound)
#'
#' # Show group names
#' for (group in kinase_groups$groups) {
#'   cat(group$id, ":", group$name, "\n")
#' }
#'
#' # Search for zinc finger groups
#' zf_groups <- hgnc_search_groups("zinc finger", limit = 10)
#'
#' # Get members of the first matching group
#' if (zf_groups$numFound > 0) {
#'   first_group_id <- zf_groups$groups[[1]]$id
#'   members <- hgnc_group_members(first_group_id)
#'   print(members$numFound)
#' }
#' }
#'
#' @seealso [hgnc_group_members()] to get genes in a specific group
#'
#' @export
hgnc_search_groups <- function(query, limit = 100) {
  if (missing(query) || is.null(query) || nchar(query) == 0) {
    stop("'query' must be a non-empty string", call. = FALSE)
  }

  # Build search endpoint
  # We search across gene_group field to find groups
  endpoint <- paste0(
    "search/gene_group:",
    utils::URLencode(query, reserved = TRUE),
    "?rows=", limit
  )

  # Make request
  result <- hgnc_rest_get(endpoint)

  # Extract unique gene groups from the results
  if (!is.null(result$response) && !is.null(result$response$docs)) {
    docs <- result$response$docs

    # Extract unique groups from the gene records
    # Each gene can belong to multiple groups
    groups_list <- list()
    seen_ids <- character()

    for (doc in docs) {
      if (!is.null(doc$gene_group_id) && !is.null(doc$gene_group)) {
        # gene_group_id and gene_group can be vectors
        group_ids <- doc$gene_group_id
        group_names <- doc$gene_group

        # Ensure they're vectors
        if (!is.list(group_ids) && !is.vector(group_ids)) {
          group_ids <- list(group_ids)
        }
        if (!is.list(group_names) && !is.vector(group_names)) {
          group_names <- list(group_names)
        }

        # Process each group
        for (i in seq_along(group_ids)) {
          group_id <- as.character(group_ids[[i]])

          if (!(group_id %in% seen_ids)) {
            seen_ids <- c(seen_ids, group_id)

            group_info <- list(
              id = group_ids[[i]],
              name = if (i <= length(group_names)) group_names[[i]] else NA_character_,
              description = NA_character_  # Not available in search results
            )

            groups_list <- c(groups_list, list(group_info))
          }
        }
      }
    }

    response <- list(
      numFound = length(groups_list),
      groups = groups_list,
      query = query
    )

    return(response)
  }

  # Fallback for empty results
  return(list(
    numFound = 0,
    groups = list(),
    query = query
  ))
}
