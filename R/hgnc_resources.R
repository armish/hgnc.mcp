#' HGNC MCP Resource Helpers
#'
#' Functions to generate formatted resource content for MCP clients.
#' These provide read-only context injection for genes, groups, and metadata.
#'
#' @name hgnc_resources
NULL

#' Get Gene Card Resource
#'
#' Retrieve a formatted gene card with essential information for LLM context.
#' Returns a structured view of gene information including symbol, name,
#' location, status, aliases, cross-references, and group memberships.
#'
#' @param hgnc_id Character or numeric. HGNC ID (with or without "HGNC:" prefix)
#'   or gene symbol to look up.
#' @param format Character. Output format: "json" (structured data, default),
#'   "markdown" (human-readable), or "text" (plain text summary).
#'
#' @return A list with components:
#'   \item{uri}{Resource URI}
#'   \item{mimeType}{Content MIME type}
#'   \item{content}{Formatted gene card content}
#'   \item{gene}{Raw gene data (if format="json")}
#'
#' @examples
#' \dontrun{
#' # Get BRCA1 gene card as JSON
#' card <- hgnc_get_gene_card("HGNC:1100")
#'
#' # Get gene card as markdown for display
#' card <- hgnc_get_gene_card("BRCA1", format = "markdown")
#' }
#'
#' @export
hgnc_get_gene_card <- function(
  hgnc_id,
  format = c("json", "markdown", "text")
) {
  format <- match.arg(format)

  # Determine if input is HGNC ID or symbol
  if (grepl("^HGNC:", hgnc_id, ignore.case = TRUE)) {
    # Strip prefix and fetch by hgnc_id
    id_num <- sub("^HGNC:", "", hgnc_id, ignore.case = TRUE)
    result <- hgnc_fetch("hgnc_id", id_num)
  } else if (grepl("^\\d+$", hgnc_id)) {
    # Numeric ID without prefix
    result <- hgnc_fetch("hgnc_id", hgnc_id)
  } else {
    # Assume it's a symbol
    result <- hgnc_fetch("symbol", hgnc_id)
  }

  # Check if gene was found
  if (is.null(result) || result$numFound == 0) {
    stop(sprintf("Gene '%s' not found in HGNC database", hgnc_id))
  }

  # Extract first gene record
  gene <- result$docs[[1]]

  # Build URI
  uri <- sprintf("hgnc://gene/%s", gene$hgnc_id)

  # Format content based on requested format
  if (format == "json") {
    # Return structured JSON data
    content <- list(
      hgnc_id = gene$hgnc_id,
      symbol = gene$symbol,
      name = gene$name,
      status = gene$status %||% NA,
      locus_type = gene$locus_type %||% NA,
      location = gene$location %||% NA,
      aliases = gene$alias_symbol %||% list(),
      previous_symbols = gene$prev_symbol %||% list(),
      cross_references = list(
        entrez_id = gene$entrez_id %||% NA,
        ensembl_gene_id = gene$ensembl_gene_id %||% NA,
        uniprot_ids = gene$uniprot_ids %||% list(),
        omim_id = gene$omim_id %||% list(),
        ccds_id = gene$ccds_id %||% list(),
        mane_select = gene$mane_select %||% list(),
        agr = gene$agr %||% NA
      ),
      gene_groups = gene$gene_group %||% list(),
      gene_group_ids = gene$gene_group_id %||% list(),
      date_approved = gene$date_approved_reserved %||% NA,
      date_modified = gene$date_modified %||% NA
    )

    return(list(
      uri = uri,
      mimeType = "application/json",
      content = jsonlite::toJSON(content, auto_unbox = TRUE, pretty = TRUE),
      gene = gene
    ))
  } else if (format == "markdown") {
    # Return markdown-formatted card
    md <- c(
      sprintf("# %s (%s)", gene$symbol, gene$hgnc_id),
      "",
      sprintf("**Name:** %s", gene$name),
      sprintf("**Status:** %s", gene$status %||% "N/A"),
      sprintf("**Locus Type:** %s", gene$locus_type %||% "N/A"),
      sprintf("**Location:** %s", gene$location %||% "N/A"),
      ""
    )

    # Add aliases if present
    if (!is.null(gene$alias_symbol) && length(gene$alias_symbol) > 0) {
      md <- c(md, "## Aliases", paste("-", gene$alias_symbol), "")
    }

    # Add previous symbols if present
    if (!is.null(gene$prev_symbol) && length(gene$prev_symbol) > 0) {
      md <- c(md, "## Previous Symbols", paste("-", gene$prev_symbol), "")
    }

    # Add cross-references
    md <- c(md, "## Cross-References", "")
    if (!is.null(gene$entrez_id)) {
      md <- c(md, sprintf("- **Entrez Gene:** %s", gene$entrez_id))
    }
    if (!is.null(gene$ensembl_gene_id)) {
      md <- c(md, sprintf("- **Ensembl:** %s", gene$ensembl_gene_id))
    }
    if (!is.null(gene$uniprot_ids) && length(gene$uniprot_ids) > 0) {
      md <- c(
        md,
        sprintf("- **UniProt:** %s", paste(gene$uniprot_ids, collapse = ", "))
      )
    }
    if (!is.null(gene$omim_id) && length(gene$omim_id) > 0) {
      md <- c(
        md,
        sprintf("- **OMIM:** %s", paste(gene$omim_id, collapse = ", "))
      )
    }

    # Add gene groups
    if (!is.null(gene$gene_group) && length(gene$gene_group) > 0) {
      md <- c(md, "", "## Gene Groups", paste("-", gene$gene_group), "")
    }

    content <- paste(md, collapse = "\n")
    return(list(
      uri = uri,
      mimeType = "text/markdown",
      content = content,
      gene = gene
    ))
  } else {
    # Plain text summary
    text <- sprintf(
      "Gene: %s (%s)\nName: %s\nStatus: %s\nLocus Type: %s\nLocation: %s",
      gene$symbol,
      gene$hgnc_id,
      gene$name,
      gene$status %||% "N/A",
      gene$locus_type %||% "N/A",
      gene$location %||% "N/A"
    )

    return(list(
      uri = uri,
      mimeType = "text/plain",
      content = text,
      gene = gene
    ))
  }
}


#' Get Group Card Resource
#'
#' Retrieve a formatted gene group card with members and metadata.
#'
#' @param group_id_or_name Numeric gene group ID or group name/slug.
#' @param format Character. Output format: "json" (default), "markdown", or "text".
#' @param include_members Logical. Whether to include full member gene records
#'   (default: TRUE). If FALSE, only member count is included.
#'
#' @return A list with components:
#'   \item{uri}{Resource URI}
#'   \item{mimeType}{Content MIME type}
#'   \item{content}{Formatted group card content}
#'   \item{group}{Raw group data (if format="json")}
#'
#' @examples
#' \dontrun{
#' # Get kinase group card
#' card <- hgnc_get_group_card("kinase")
#'
#' # Get group as markdown
#' card <- hgnc_get_group_card(588, format = "markdown")
#' }
#'
#' @export
hgnc_get_group_card <- function(
  group_id_or_name,
  format = c("json", "markdown", "text"),
  include_members = TRUE
) {
  format <- match.arg(format)

  # Fetch group members
  result <- hgnc_group_members(group_id_or_name, use_cache = TRUE)

  if (is.null(result) || result$numFound == 0) {
    stop(sprintf(
      "Gene group '%s' not found or has no members",
      group_id_or_name
    ))
  }

  # Extract group info from first member
  first_member <- result$docs[[1]]
  group_name <- first_member$gene_group[[1]]
  group_id <- first_member$gene_group_id[[1]]

  # Build URI
  uri <- sprintf("hgnc://group/%s", group_id)

  # Format content
  if (format == "json") {
    content_data <- list(
      group_id = group_id,
      group_name = group_name,
      member_count = result$numFound,
      members = if (include_members) {
        lapply(result$docs, function(gene) {
          list(
            hgnc_id = gene$hgnc_id,
            symbol = gene$symbol,
            name = gene$name,
            status = gene$status %||% NA,
            location = gene$location %||% NA
          )
        })
      } else {
        NULL
      }
    )

    return(list(
      uri = uri,
      mimeType = "application/json",
      content = jsonlite::toJSON(
        content_data,
        auto_unbox = TRUE,
        pretty = TRUE
      ),
      group = list(
        id = group_id,
        name = group_name,
        member_count = result$numFound
      )
    ))
  } else if (format == "markdown") {
    md <- c(
      sprintf("# Gene Group: %s", group_name),
      "",
      sprintf("**Group ID:** %s", group_id),
      sprintf("**Member Count:** %d genes", result$numFound),
      ""
    )

    if (include_members) {
      md <- c(md, "## Members", "")

      # Add table header
      md <- c(
        md,
        "| Symbol | Name | Status | Location |",
        "|--------|------|--------|----------|"
      )

      # Add member rows
      for (gene in result$docs) {
        md <- c(
          md,
          sprintf(
            "| %s | %s | %s | %s |",
            gene$symbol,
            gene$name,
            gene$status %||% "N/A",
            gene$location %||% "N/A"
          )
        )
      }
    }

    content <- paste(md, collapse = "\n")
    return(list(
      uri = uri,
      mimeType = "text/markdown",
      content = content,
      group = list(
        id = group_id,
        name = group_name,
        member_count = result$numFound
      )
    ))
  } else {
    # Plain text
    text <- sprintf(
      "Gene Group: %s (ID: %s)\nMembers: %d genes",
      group_name,
      group_id,
      result$numFound
    )

    if (include_members) {
      text <- paste0(
        text,
        "\n\nMember Symbols:\n",
        paste(sapply(result$docs, function(g) g$symbol), collapse = ", ")
      )
    }

    return(list(
      uri = uri,
      mimeType = "text/plain",
      content = text,
      group = list(
        id = group_id,
        name = group_name,
        member_count = result$numFound
      )
    ))
  }
}


#' Get Snapshot Metadata Resource
#'
#' Retrieve metadata about the currently cached HGNC dataset.
#' Includes information about the snapshot version, date, source URL,
#' and basic statistics.
#'
#' @param format Character. Output format: "json" (default), "markdown", or "text".
#'
#' @return A list with components:
#'   \item{uri}{Resource URI}
#'   \item{mimeType}{Content MIME type}
#'   \item{content}{Formatted snapshot metadata}
#'
#' @examples
#' \dontrun{
#' # Get snapshot metadata
#' meta <- hgnc_get_snapshot_metadata()
#'
#' # Get as markdown
#' meta <- hgnc_get_snapshot_metadata(format = "markdown")
#' }
#'
#' @export
hgnc_get_snapshot_metadata <- function(format = c("json", "markdown", "text")) {
  format <- match.arg(format)

  # Load cached data to get metadata
  data <- load_hgnc_data()

  if (is.null(data) || nrow(data) == 0) {
    stop("No cached HGNC data available. Run download_hgnc_data() first.")
  }

  # Get cache metadata
  cache_dir <- get_hgnc_cache_dir()
  cache_file <- file.path(cache_dir, "hgnc_complete_set.txt")
  meta_file <- file.path(cache_dir, "metadata.rds")

  metadata <- if (file.exists(meta_file)) {
    readRDS(meta_file)
  } else {
    list(
      download_date = as.character(file.info(cache_file)$mtime),
      source_url = "ftp://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/tsv/hgnc_complete_set.txt"
    )
  }

  # Calculate statistics
  stats <- list(
    total_genes = nrow(data),
    approved = sum(data$status == "Approved", na.rm = TRUE),
    withdrawn = sum(data$status == "Withdrawn", na.rm = TRUE),
    locus_types = table(data$locus_type)
  )

  # Build URI
  uri <- "hgnc://snapshot/current"

  # Format content
  if (format == "json") {
    content_data <- list(
      version = "current",
      download_date = metadata$download_date,
      source_url = metadata$source_url,
      cache_location = cache_file,
      statistics = list(
        total_genes = stats$total_genes,
        approved = stats$approved,
        withdrawn = stats$withdrawn,
        locus_type_counts = as.list(stats$locus_types)
      ),
      columns = colnames(data)
    )

    return(list(
      uri = uri,
      mimeType = "application/json",
      content = jsonlite::toJSON(content_data, auto_unbox = TRUE, pretty = TRUE)
    ))
  } else if (format == "markdown") {
    md <- c(
      "# HGNC Dataset Snapshot",
      "",
      sprintf("**Version:** current"),
      sprintf("**Downloaded:** %s", metadata$download_date),
      sprintf("**Source:** %s", metadata$source_url),
      sprintf("**Cache Location:** %s", cache_file),
      "",
      "## Statistics",
      "",
      sprintf(
        "- **Total Genes:** %s",
        format(stats$total_genes, big.mark = ",")
      ),
      sprintf("- **Approved:** %s", format(stats$approved, big.mark = ",")),
      sprintf("- **Withdrawn:** %s", format(stats$withdrawn, big.mark = ",")),
      "",
      "### Locus Type Distribution",
      ""
    )

    # Add locus type counts
    for (i in seq_along(stats$locus_types)) {
      md <- c(
        md,
        sprintf(
          "- **%s:** %s",
          names(stats$locus_types)[i],
          format(stats$locus_types[i], big.mark = ",")
        )
      )
    }

    content <- paste(md, collapse = "\n")
    return(list(
      uri = uri,
      mimeType = "text/markdown",
      content = content
    ))
  } else {
    # Plain text
    text <- sprintf(
      "HGNC Snapshot: current\nDownloaded: %s\nTotal Genes: %s\nApproved: %s\nWithdrawn: %s",
      metadata$download_date,
      format(stats$total_genes, big.mark = ","),
      format(stats$approved, big.mark = ","),
      format(stats$withdrawn, big.mark = ",")
    )

    return(list(
      uri = uri,
      mimeType = "text/plain",
      content = text
    ))
  }
}


#' Get Changes Summary Resource
#'
#' Retrieve a summary of nomenclature changes since a specified date.
#' Provides a compact change log with gene IDs, symbols, and modification dates.
#'
#' @param since Character. ISO 8601 date (YYYY-MM-DD) from which to track changes.
#' @param format Character. Output format: "json" (default), "markdown", or "text".
#' @param change_type Character. Type of changes: "all" (default), "symbol",
#'   "name", "status", or "modified".
#' @param max_results Integer. Maximum number of changes to return (default: 100).
#'
#' @return A list with components:
#'   \item{uri}{Resource URI}
#'   \item{mimeType}{Content MIME type}
#'   \item{content}{Formatted changes summary}
#'   \item{changes}{Raw changes data}
#'
#' @examples
#' \dontrun{
#' # Get changes since 2024-01-01
#' changes <- hgnc_get_changes_summary("2024-01-01")
#'
#' # Get symbol changes only as markdown
#' changes <- hgnc_get_changes_summary("2024-01-01",
#'   format = "markdown",
#'   change_type = "symbol"
#' )
#' }
#'
#' @export
hgnc_get_changes_summary <- function(
  since,
  format = c("json", "markdown", "text"),
  change_type = "all",
  max_results = 100
) {
  format <- match.arg(format)

  # Get changes
  result <- hgnc_changes(
    since = since,
    fields = c("symbol", "name", "status", "prev_symbol", "hgnc_id"),
    change_type = change_type,
    use_cache = TRUE
  )

  # Limit results
  changes_df <- result$changes
  if (nrow(changes_df) > max_results) {
    changes_df <- changes_df[1:max_results, ]
    truncated <- TRUE
  } else {
    truncated <- FALSE
  }

  # Build URI
  uri <- sprintf("hgnc://changes/since/%s", since)

  # Format content
  if (format == "json") {
    content_data <- list(
      since = since,
      change_type = change_type,
      total_changes = result$summary$total_changes,
      showing = nrow(changes_df),
      truncated = truncated,
      changes = lapply(seq_len(nrow(changes_df)), function(i) {
        row <- changes_df[i, ]
        list(
          hgnc_id = row$hgnc_id,
          symbol = row$symbol,
          name = row$name,
          status = row$status,
          change_type = row$change_type,
          change_date = row$change_date
        )
      })
    )

    return(list(
      uri = uri,
      mimeType = "application/json",
      content = jsonlite::toJSON(
        content_data,
        auto_unbox = TRUE,
        pretty = TRUE
      ),
      changes = result
    ))
  } else if (format == "markdown") {
    md <- c(
      sprintf("# HGNC Changes Since %s", since),
      "",
      sprintf("**Change Type:** %s", change_type),
      sprintf("**Total Changes:** %d", result$summary$total_changes),
      sprintf("**Showing:** %d", nrow(changes_df)),
      ""
    )

    if (truncated) {
      md <- c(
        md,
        sprintf("*Note: Results limited to %d entries*", max_results),
        ""
      )
    }

    md <- c(
      md,
      "## Changes",
      "",
      "| HGNC ID | Symbol | Change Type | Date |",
      "|---------|--------|-------------|------|"
    )

    for (i in seq_len(nrow(changes_df))) {
      row <- changes_df[i, ]
      md <- c(
        md,
        sprintf(
          "| %s | %s | %s | %s |",
          row$hgnc_id,
          row$symbol,
          row$change_type,
          row$change_date
        )
      )
    }

    content <- paste(md, collapse = "\n")
    return(list(
      uri = uri,
      mimeType = "text/markdown",
      content = content,
      changes = result
    ))
  } else {
    # Plain text
    text <- sprintf(
      "HGNC Changes Since %s\nChange Type: %s\nTotal Changes: %d\nShowing: %d\n",
      since,
      change_type,
      result$summary$total_changes,
      nrow(changes_df)
    )

    if (truncated) {
      text <- paste0(
        text,
        sprintf("\n(Results limited to %d entries)\n", max_results)
      )
    }

    text <- paste0(text, "\nRecent Changes:\n")
    for (i in seq_len(min(10, nrow(changes_df)))) {
      row <- changes_df[i, ]
      text <- paste0(
        text,
        sprintf(
          "- %s (%s): %s on %s\n",
          row$symbol,
          row$hgnc_id,
          row$change_type,
          row$change_date
        )
      )
    }

    return(list(
      uri = uri,
      mimeType = "text/plain",
      content = text,
      changes = result
    ))
  }
}


# Null coalescing operator helper
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}
