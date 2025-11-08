# HGNC Essential Lookup Tools
#
# High-level functions for gene lookup, resolution, and cross-referencing
# Built on top of the HGNC REST API client

#' Search for Genes in HGNC Database
#'
#' Search across gene symbols, aliases, previous symbols, and names using
#' the HGNC REST API `/search` endpoint.
#'
#' @param query Search query string (e.g., "BRCA1", "insulin", "kinase")
#' @param filters Optional named list of filters to apply. Supported filters
#'   include: `status` (e.g., "Approved"), `locus_type` (e.g., "gene with protein product"),
#'   `locus_group`, etc. See HGNC API documentation for complete list.
#' @param limit Maximum number of results to return (default: 100)
#'
#' @return A list containing:
#'   - `numFound`: Total number of matches
#'   - `docs`: List of matched gene records with scores
#'   - `query`: The original query for reference
#'
#' @details
#' The search function queries across multiple fields including:
#' - symbol: Official gene symbol
#' - alias_symbol: Alternative symbols
#' - prev_symbol: Previous symbols
#' - name: Gene name
#'
#' Results include a relevance score to help rank matches.
#'
#' @examples
#' \dontrun{
#' # Simple search
#' results <- hgnc_find("BRCA1")
#'
#' # Search with filters
#' results <- hgnc_find("kinase",
#'   filters = list(
#'     status = "Approved",
#'     locus_type = "gene with protein product"
#'   )
#' )
#'
#' # Check number of results
#' print(results$numFound)
#'
#' # Access top result
#' top_gene <- results$docs[[1]]
#' print(top_gene$symbol)
#' }
#'
#' @export
hgnc_find <- function(query, filters = NULL, limit = 100) {
  if (missing(query) || is.null(query) || nchar(query) == 0) {
    stop("'query' must be a non-empty string", call. = FALSE)
  }

  # Build endpoint
  endpoint <- paste0("search/", utils::URLencode(query, reserved = TRUE))

  # Add filters as query parameters if provided
  if (!is.null(filters) && length(filters) > 0) {
    filter_params <- vapply(
      names(filters),
      function(name) {
        value <- filters[[name]]
        sprintf(
          "%s:%s",
          name,
          utils::URLencode(as.character(value), reserved = TRUE)
        )
      },
      character(1)
    )

    # HGNC API uses + to combine filters
    filter_string <- paste(filter_params, collapse = "+AND+")
    endpoint <- paste0(endpoint, "+AND+", filter_string)
  }

  # Add row limit
  endpoint <- paste0(endpoint, "?rows=", limit)

  # Make request
  result <- hgnc_rest_get(endpoint)

  # Extract response
  if (!is.null(result$response)) {
    response <- list(
      numFound = result$response$numFound %||% 0,
      docs = result$response$docs %||% list(),
      query = query
    )
    return(response)
  }

  # Fallback if response structure is different
  return(result)
}

#' Fetch Gene Records by Field Value
#'
#' Retrieve complete gene records from HGNC by searching a specific field.
#' This is the most direct way to get gene information when you have a
#' known identifier.
#'
#' @param field The field to search. Common fields include:
#'   - `hgnc_id`: HGNC identifier (e.g., "HGNC:5")
#'   - `symbol`: Official gene symbol (e.g., "BRCA1")
#'   - `entrez_id`: NCBI Gene ID (e.g., "672")
#'   - `ensembl_gene_id`: Ensembl gene ID (e.g., "ENSG00000012048")
#'   - `uniprot_ids`: UniProt accession
#'   - `refseq_accession`: RefSeq accession
#' @param term The value to search for in the specified field
#'
#' @return A list containing:
#'   - `numFound`: Number of matching records (usually 1 for exact matches)
#'   - `docs`: List of complete gene records with all stored fields
#'   - `field`: The field that was searched
#'   - `term`: The search term
#'
#' @details
#' This function is the primary method for retrieving complete gene information
#' when you have a specific identifier. Each gene record (doc) contains all
#' available HGNC fields including:
#' - Core identifiers: hgnc_id, symbol, name, status
#' - Location: location, chromosome
#' - Aliases: alias_symbol, prev_symbol
#' - Cross-references: entrez_id, ensembl_gene_id, uniprot_ids, omim_id, etc.
#' - Groups: gene_group, gene_group_id
#' - Dates: date_modified, date_symbol_changed, etc.
#'
#' @examples
#' \dontrun{
#' # Fetch by HGNC ID
#' gene <- hgnc_fetch("hgnc_id", "HGNC:5")
#'
#' # Fetch by symbol
#' gene <- hgnc_fetch("symbol", "BRCA1")
#'
#' # Fetch by Entrez ID
#' gene <- hgnc_fetch("entrez_id", "672")
#'
#' # Access gene data
#' if (gene$numFound > 0) {
#'   record <- gene$docs[[1]]
#'   cat("Symbol:", record$symbol, "\n")
#'   cat("Name:", record$name, "\n")
#'   cat("Location:", record$location, "\n")
#' }
#' }
#'
#' @export
hgnc_fetch <- function(field, term) {
  if (missing(field) || missing(term)) {
    stop("Both 'field' and 'term' are required", call. = FALSE)
  }

  if (is.null(field) || nchar(field) == 0) {
    stop("'field' must be a non-empty string", call. = FALSE)
  }

  if (is.null(term) || nchar(as.character(term)) == 0) {
    stop("'term' must be a non-empty value", call. = FALSE)
  }

  # Build endpoint
  term_encoded <- utils::URLencode(as.character(term), reserved = TRUE)
  endpoint <- paste0("fetch/", field, "/", term_encoded)

  # Make request
  result <- hgnc_rest_get(endpoint)

  # Extract response
  if (!is.null(result$response)) {
    response <- list(
      numFound = result$response$numFound %||% 0,
      docs = result$response$docs %||% list(),
      field = field,
      term = term
    )
    return(response)
  }

  # Fallback if response structure is different
  return(result)
}

#' Resolve Gene Symbol to Approved Symbol
#'
#' Resolve a gene symbol (which might be an alias or previous symbol) to
#' the current approved HGNC symbol.
#'
#' @param symbol Gene symbol to resolve (case-insensitive)
#' @param mode Resolution mode:
#'   - `"strict"`: Only exact matches on approved symbols
#'   - `"lenient"`: Search across symbol, alias_symbol, and prev_symbol
#' @param return_record Whether to return the full gene record (default: FALSE)
#'
#' @return A list containing:
#'   - `query`: The original query symbol
#'   - `approved_symbol`: The current approved HGNC symbol (or NA if not found)
#'   - `status`: Gene status (e.g., "Approved", "Withdrawn")
#'   - `confidence`: Match confidence ("exact", "alias", "previous", or "not_found")
#'   - `hgnc_id`: HGNC identifier
#'   - `candidates`: If ambiguous, list of possible matches
#'   - `record`: Full gene record (if return_record = TRUE)
#'
#' @details
#' This function handles common gene symbol resolution scenarios:
#'
#' **Strict Mode**:
#' - Only finds genes where the query exactly matches the approved symbol
#' - Fastest and most conservative
#' - Use when you only want official current symbols
#'
#' **Lenient Mode** (default):
#' - Searches approved symbols, aliases, and previous symbols
#' - Handles renamed genes and common aliases
#' - Returns the current approved symbol
#' - Indicates how the match was found (exact, alias, or previous)
#'
#' The function automatically normalizes symbols to uppercase (HGNC convention).
#'
#' @examples
#' \dontrun{
#' # Resolve current symbol
#' result <- hgnc_resolve_symbol("BRCA1")
#' print(result$approved_symbol)  # "BRCA1"
#' print(result$confidence)        # "exact"
#'
#' # Resolve alias or previous symbol
#' result <- hgnc_resolve_symbol("GRCh38", mode = "lenient")
#'
#' # Get full record
#' result <- hgnc_resolve_symbol("TP53", return_record = TRUE)
#' print(result$record$location)
#'
#' # Strict mode
#' result <- hgnc_resolve_symbol("some_alias", mode = "strict")
#' # Will return not_found if it's not the approved symbol
#' }
#'
#' @export
hgnc_resolve_symbol <- function(
  symbol,
  mode = "lenient",
  return_record = FALSE
) {
  if (missing(symbol) || is.null(symbol) || nchar(symbol) == 0) {
    stop("'symbol' must be a non-empty string", call. = FALSE)
  }

  mode <- match.arg(mode, c("strict", "lenient"))

  # Normalize to uppercase (HGNC convention)
  symbol_upper <- toupper(trimws(symbol))

  if (mode == "strict") {
    # Strict mode: exact match on approved symbol only
    result <- hgnc_fetch("symbol", symbol_upper)

    if (result$numFound == 0) {
      return(list(
        query = symbol,
        approved_symbol = NA_character_,
        status = NA_character_,
        confidence = "not_found",
        hgnc_id = NA_character_,
        candidates = list()
      ))
    }

    doc <- result$docs[[1]]
    response <- list(
      query = symbol,
      approved_symbol = doc$symbol %||% NA_character_,
      status = doc$status %||% NA_character_,
      confidence = "exact",
      hgnc_id = doc$hgnc_id %||% NA_character_,
      candidates = list()
    )

    if (return_record) {
      response$record <- doc
    }

    return(response)
  } else {
    # Lenient mode: search across symbol, alias, prev_symbol
    # Use the search endpoint which searches across multiple fields
    search_result <- hgnc_find(symbol_upper)

    if (search_result$numFound == 0) {
      return(list(
        query = symbol,
        approved_symbol = NA_character_,
        status = NA_character_,
        confidence = "not_found",
        hgnc_id = NA_character_,
        candidates = list()
      ))
    }

    # Check for exact match on approved symbol first
    exact_matches <- Filter(
      function(doc) {
        isTRUE(toupper(doc$symbol %||% "") == symbol_upper)
      },
      search_result$docs
    )

    if (length(exact_matches) > 0) {
      doc <- exact_matches[[1]]
      response <- list(
        query = symbol,
        approved_symbol = doc$symbol %||% NA_character_,
        status = doc$status %||% NA_character_,
        confidence = "exact",
        hgnc_id = doc$hgnc_id %||% NA_character_,
        candidates = if (length(exact_matches) > 1) {
          exact_matches[-1]
        } else {
          list()
        }
      )

      if (return_record) {
        response$record <- doc
      }

      return(response)
    }

    # Check for alias match
    alias_matches <- Filter(
      function(doc) {
        aliases <- doc$alias_symbol %||% character(0)
        if (is.character(aliases)) {
          any(toupper(aliases) == symbol_upper)
        } else {
          FALSE
        }
      },
      search_result$docs
    )

    if (length(alias_matches) > 0) {
      doc <- alias_matches[[1]]
      response <- list(
        query = symbol,
        approved_symbol = doc$symbol %||% NA_character_,
        status = doc$status %||% NA_character_,
        confidence = "alias",
        hgnc_id = doc$hgnc_id %||% NA_character_,
        candidates = if (length(alias_matches) > 1) {
          alias_matches[-1]
        } else {
          list()
        }
      )

      if (return_record) {
        response$record <- doc
      }

      return(response)
    }

    # Check for previous symbol match
    prev_matches <- Filter(
      function(doc) {
        prev_symbols <- doc$prev_symbol %||% character(0)
        if (is.character(prev_symbols)) {
          any(toupper(prev_symbols) == symbol_upper)
        } else {
          FALSE
        }
      },
      search_result$docs
    )

    if (length(prev_matches) > 0) {
      doc <- prev_matches[[1]]
      response <- list(
        query = symbol,
        approved_symbol = doc$symbol %||% NA_character_,
        status = doc$status %||% NA_character_,
        confidence = "previous",
        hgnc_id = doc$hgnc_id %||% NA_character_,
        candidates = if (length(prev_matches) > 1) prev_matches[-1] else list()
      )

      if (return_record) {
        response$record <- doc
      }

      return(response)
    }

    # No clear match, return top result with low confidence
    doc <- search_result$docs[[1]]
    response <- list(
      query = symbol,
      approved_symbol = doc$symbol %||% NA_character_,
      status = doc$status %||% NA_character_,
      confidence = "fuzzy",
      hgnc_id = doc$hgnc_id %||% NA_character_,
      candidates = if (search_result$numFound > 1) {
        search_result$docs[-1]
      } else {
        list()
      }
    )

    if (return_record) {
      response$record <- doc
    }

    return(response)
  }
}

#' Extract Cross-References from Gene Record
#'
#' Extract external database cross-references from an HGNC gene record.
#' Useful for harmonizing datasets across different identifier systems.
#'
#' @param id_or_symbol Either an HGNC ID (e.g., "HGNC:5") or gene symbol (e.g., "BRCA1")
#'
#' @return A list containing cross-reference identifiers:
#'   - `hgnc_id`: HGNC identifier
#'   - `symbol`: Official gene symbol
#'   - `entrez_id`: NCBI Gene ID
#'   - `ensembl_gene_id`: Ensembl gene ID
#'   - `uniprot_ids`: UniProt accessions
#'   - `omim_id`: OMIM identifiers
#'   - `ccds_id`: CCDS identifiers
#'   - `refseq_accession`: RefSeq accessions
#'   - `mane_select`: MANE Select transcript
#'   - `agr`: Alliance of Genome Resources ID
#'   - `ucsc_id`: UCSC identifier
#'   - `vega_id`: Vega identifier
#'   - `ena`: ENA accessions
#'   - `status`: Gene status (to help identify withdrawn genes)
#'
#' @details
#' This function retrieves the gene record and extracts all common
#' cross-reference identifiers. Missing identifiers are returned as NA.
#'
#' The function automatically detects whether the input is an HGNC ID
#' (starts with "HGNC:") or a symbol, and queries accordingly.
#'
#' @examples
#' \dontrun{
#' # Get cross-references by symbol
#' xrefs <- hgnc_xrefs("BRCA1")
#' print(xrefs$entrez_id)
#' print(xrefs$ensembl_gene_id)
#'
#' # Get cross-references by HGNC ID
#' xrefs <- hgnc_xrefs("HGNC:1100")
#'
#' # Use for dataset harmonization
#' # Map your Entrez IDs to Ensembl
#' my_genes <- c("BRCA1", "TP53", "EGFR")
#' xref_table <- lapply(my_genes, hgnc_xrefs)
#' }
#'
#' @export
hgnc_xrefs <- function(id_or_symbol) {
  if (
    missing(id_or_symbol) || is.null(id_or_symbol) || nchar(id_or_symbol) == 0
  ) {
    stop("'id_or_symbol' must be a non-empty string", call. = FALSE)
  }

  # Determine if this is an HGNC ID or a symbol
  is_hgnc_id <- grepl("^HGNC:", id_or_symbol, ignore.case = TRUE)

  if (is_hgnc_id) {
    result <- hgnc_fetch("hgnc_id", id_or_symbol)
  } else {
    # Try as symbol first
    result <- hgnc_fetch("symbol", toupper(id_or_symbol))

    # If not found, try resolving as alias/prev_symbol
    if (result$numFound == 0) {
      resolved <- hgnc_resolve_symbol(
        id_or_symbol,
        mode = "lenient",
        return_record = TRUE
      )
      if (!is.na(resolved$approved_symbol) && !is.null(resolved$record)) {
        # Use the resolved record
        result <- list(
          numFound = 1,
          docs = list(resolved$record)
        )
      }
    }
  }

  if (result$numFound == 0) {
    warning(
      sprintf("Gene '%s' not found in HGNC database", id_or_symbol),
      call. = FALSE
    )
    return(NULL)
  }

  doc <- result$docs[[1]]

  # Extract common cross-references
  xrefs <- list(
    hgnc_id = doc$hgnc_id %||% NA_character_,
    symbol = doc$symbol %||% NA_character_,
    entrez_id = doc$entrez_id %||% NA_character_,
    ensembl_gene_id = doc$ensembl_gene_id %||% NA_character_,
    uniprot_ids = doc$uniprot_ids %||% NA_character_,
    omim_id = doc$omim_id %||% NA_character_,
    ccds_id = doc$ccds_id %||% NA_character_,
    refseq_accession = doc$refseq_accession %||% NA_character_,
    mane_select = doc$mane_select %||% NA_character_,
    agr = doc$agr %||% NA_character_,
    ucsc_id = doc$ucsc_id %||% NA_character_,
    vega_id = doc$vega_id %||% NA_character_,
    ena = doc$ena %||% NA_character_,
    status = doc$status %||% NA_character_
  )

  return(xrefs)
}
