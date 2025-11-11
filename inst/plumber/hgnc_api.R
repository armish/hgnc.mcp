# HGNC MCP Plumber API
#
# This file defines Plumber endpoints that wrap HGNC functions for use
# with plumber2mcp to expose them via the Model Context Protocol (MCP).
#
# Documentation: https://www.rplumber.io/
# plumber2mcp: https://github.com/mlverse/plumber2mcp

# Load the hgnc.mcp package
library(hgnc.mcp)

#* @apiTitle HGNC Nomenclature Service
#* @apiDescription MCP server providing HGNC gene nomenclature tools for normalization, validation, and lookup
#* @apiVersion 1.0.0

#* Get HGNC REST API Information
#*
#* Retrieves metadata about the HGNC REST API, including the last modification
#* date, searchable fields, and stored fields. Useful for cache invalidation
#* decisions and understanding API capabilities.
#*
#* @get /tools/info
#* @response 200 A list containing lastModified, searchableFields, and storedFields
#* @response 500 Internal server error
#* @tag Tools
endpoint_info <- function(res) {
  tryCatch(
    {
      result <- hgnc_rest_info()
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Search for Genes in HGNC Database
#*
#* Search across gene symbols, aliases, previous symbols, and names using
#* the HGNC REST API search endpoint.
#*
#* @post /tools/find
#* @param query:str The search query string (e.g., "BRCA1", "insulin", "kinase")
#* @param filters:[object] Optional named list of filters to apply (e.g., {"status": "Approved"})
#* @param limit:int Maximum number of results to return (default: 100)
#* @response 200 A list containing numFound, docs (matched gene records), and query
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_find <- function(req, res, query = NULL, filters = NULL, limit = 100) {
  # Validate query parameter
  if (is.null(query) || nchar(trimws(as.character(query))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'query' parameter is required and must be non-empty"
    ))
  }

  # Validate limit
  limit <- as.integer(limit)
  if (is.na(limit) || limit < 1) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'limit' must be a positive integer"
    ))
  }

  tryCatch(
    {
      result <- hgnc_find(query = query, filters = filters, limit = limit)
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Fetch Gene Records by Field Value
#*
#* Retrieve complete gene records from HGNC by searching a specific field.
#* Common fields include hgnc_id, symbol, entrez_id, ensembl_gene_id.
#*
#* @post /tools/fetch
#* @param field:str The field to search (e.g., "hgnc_id", "symbol", "entrez_id")
#* @param term:str The value to search for in the specified field
#* @response 200 A list containing numFound, docs (gene records), field, and term
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_fetch <- function(req, res, field = NULL, term = NULL) {
  # Validate parameters
  if (is.null(field) || nchar(trimws(as.character(field))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'field' parameter is required and must be non-empty"
    ))
  }

  if (is.null(term) || nchar(trimws(as.character(term))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'term' parameter is required and must be non-empty"
    ))
  }

  tryCatch(
    {
      result <- hgnc_fetch(field = field, term = term)
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Resolve Gene Symbol to Approved Symbol
#*
#* Resolve a gene symbol (which might be an alias or previous symbol) to
#* the current approved HGNC symbol.
#*
#* @post /tools/resolve_symbol
#* @param symbol:str Gene symbol to resolve (case-insensitive)
#* @param mode:str Resolution mode - "strict" (exact matches only) or "lenient" (default: "lenient")
#* @param return_record:bool Whether to return the full gene record (default: FALSE)
#* @response 200 Resolution result with approved_symbol, status, confidence, and hgnc_id
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_resolve_symbol <- function(
  req,
  res,
  symbol = NULL,
  mode = "lenient",
  return_record = FALSE
) {
  # Validate symbol parameter
  if (is.null(symbol) || nchar(trimws(as.character(symbol))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'symbol' parameter is required and must be non-empty"
    ))
  }

  # Validate mode parameter
  if (!mode %in% c("strict", "lenient")) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'mode' must be either 'strict' or 'lenient'"
    ))
  }

  # Convert return_record to logical
  return_record <- as.logical(return_record)
  if (is.na(return_record)) {
    return_record <- FALSE
  }

  tryCatch(
    {
      result <- hgnc_resolve_symbol(
        symbol = symbol,
        mode = mode,
        return_record = return_record
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Normalize Gene Symbol List
#*
#* Batch normalize a list of gene symbols using cached HGNC data. Optimized
#* for processing large lists quickly without REST API calls.
#*
#* @post /tools/normalize_list
#* @param symbols:[str] Character vector of gene symbols to normalize
#* @param return_fields:[str] Fields to include in output (default: essential fields)
#* @param status:[str] Status filter - e.g., ["Approved"] or NULL for all (default: ["Approved"])
#* @param dedupe:bool Whether to deduplicate by HGNC ID (default: TRUE)
#* @response 200 Normalization results with results, summary, warnings, and not_found
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_normalize_list <- function(
  req,
  res,
  symbols = NULL,
  return_fields = c(
    "symbol",
    "name",
    "hgnc_id",
    "status",
    "locus_type",
    "location",
    "alias_symbol",
    "prev_symbol"
  ),
  status = "Approved",
  dedupe = TRUE
) {
  # Validate symbols parameter
  if (is.null(symbols) || length(symbols) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'symbols' parameter is required and must be a non-empty array"
    ))
  }

  # Convert dedupe to logical
  dedupe <- as.logical(dedupe)
  if (is.na(dedupe)) {
    dedupe <- TRUE
  }

  tryCatch(
    {
      result <- hgnc_normalize_list(
        symbols = symbols,
        return_fields = return_fields,
        status = status,
        dedupe = dedupe,
        index = NULL # Will build fresh index each time
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Extract Cross-References from Gene Record
#*
#* Extract external database cross-references from an HGNC gene record.
#* Useful for harmonizing datasets across different identifier systems.
#*
#* @post /tools/xrefs
#* @param id_or_symbol:str Either an HGNC ID (e.g., "HGNC:5") or gene symbol (e.g., "BRCA1")
#* @response 200 Cross-reference identifiers for the gene
#* @response 400 Bad request - missing or invalid parameters
#* @response 404 Gene not found
#* @response 500 Internal server error
#* @tag Tools
endpoint_xrefs <- function(req, res, id_or_symbol = NULL) {
  # Validate parameter
  if (is.null(id_or_symbol) || nchar(trimws(as.character(id_or_symbol))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'id_or_symbol' parameter is required and must be non-empty"
    ))
  }

  tryCatch(
    {
      result <- hgnc_xrefs(id_or_symbol = id_or_symbol)

      if (is.null(result)) {
        res$status <- 404
        return(list(
          error = "Not found",
          message = sprintf(
            "Gene '%s' not found in HGNC database",
            id_or_symbol
          )
        ))
      }

      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Get Members of a Gene Group
#*
#* Retrieve all genes that belong to a specific HGNC gene group or family.
#* Gene groups represent functionally related genes such as protein families.
#*
#* @post /tools/group_members
#* @param group_id_or_name Either a numeric gene group ID or a gene group name
#* @param use_cache:bool Whether to use session-level caching (default: TRUE)
#* @response 200 List containing numFound, docs (gene records), and group_id_or_name
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_group_members <- function(
  req,
  res,
  group_id_or_name = NULL,
  use_cache = TRUE
) {
  # Validate parameter
  if (is.null(group_id_or_name)) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'group_id_or_name' parameter is required"
    ))
  }

  # Convert use_cache to logical
  use_cache <- as.logical(use_cache)
  if (is.na(use_cache)) {
    use_cache <- TRUE
  }

  tryCatch(
    {
      result <- hgnc_group_members(
        group_id_or_name = group_id_or_name,
        use_cache = use_cache
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Search for Gene Groups
#*
#* Search for HGNC gene groups by keyword. Returns matching gene groups
#* with their IDs, names, and descriptions.
#*
#* @post /tools/search_groups
#* @param query:str Search query string (e.g., "kinase", "zinc finger")
#* @param limit:int Maximum number of results to return (default: 100)
#* @response 200 List containing numFound, groups (group records), and query
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_search_groups <- function(req, res, query = NULL, limit = 100) {
  # Validate query parameter
  if (is.null(query) || nchar(trimws(as.character(query))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'query' parameter is required and must be non-empty"
    ))
  }

  # Validate limit
  limit <- as.integer(limit)
  if (is.na(limit) || limit < 1) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'limit' must be a positive integer"
    ))
  }

  tryCatch(
    {
      result <- hgnc_search_groups(query = query, limit = limit)
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Track Gene Nomenclature Changes
#*
#* Query genes that have been modified since a specified date. Useful for
#* monitoring watchlists and staying up-to-date with nomenclature changes.
#*
#* @post /tools/changes
#* @param since:str Date from which to track changes (ISO 8601 format: "YYYY-MM-DD")
#* @param fields:[str] Fields to include in results (default: ["symbol", "name", "status"])
#* @param change_type:str Type of changes - "all", "symbol", "name", "status", or "modified" (default: "all")
#* @param use_cache:bool Whether to use locally cached data (default: TRUE)
#* @response 200 Changes result with changes data frame, summary, and query metadata
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_changes <- function(
  req,
  res,
  since = NULL,
  fields = c("symbol", "name", "status"),
  change_type = "all",
  use_cache = TRUE
) {
  # Validate since parameter
  if (is.null(since)) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'since' parameter is required (use YYYY-MM-DD format)"
    ))
  }

  # Validate change_type
  valid_change_types <- c("all", "symbol", "name", "status", "modified")
  if (!change_type %in% valid_change_types) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = sprintf(
        "'change_type' must be one of: %s",
        paste(valid_change_types, collapse = ", ")
      )
    ))
  }

  # Convert use_cache to logical
  use_cache <- as.logical(use_cache)
  if (is.na(use_cache)) {
    use_cache <- TRUE
  }

  tryCatch(
    {
      result <- hgnc_changes(
        since = since,
        fields = fields,
        change_type = change_type,
        use_cache = use_cache
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Validate Gene Panel Against HGNC Policy
#*
#* Perform quality assurance on gene lists against HGNC nomenclature policy.
#* Checks for non-approved symbols, withdrawn genes, duplicates, and provides
#* replacement suggestions.
#*
#* @post /tools/validate_panel
#* @param items:[str] Gene symbols/identifiers to validate
#* @param policy:str Validation policy (default: "HGNC")
#* @param suggest_replacements:bool Whether to suggest replacements (default: TRUE)
#* @param include_dates:bool Whether to include date information (default: TRUE)
#* @response 200 Validation result with valid genes, issues, summary, report, and replacements
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Tools
endpoint_validate_panel <- function(
  req,
  res,
  items = NULL,
  policy = "HGNC",
  suggest_replacements = TRUE,
  include_dates = TRUE
) {
  # Validate items parameter
  if (is.null(items) || length(items) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'items' parameter is required and must be a non-empty array"
    ))
  }

  # Validate policy
  if (policy != "HGNC") {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "Currently only 'HGNC' policy is supported"
    ))
  }

  # Convert boolean parameters
  suggest_replacements <- as.logical(suggest_replacements)
  if (is.na(suggest_replacements)) {
    suggest_replacements <- TRUE
  }

  include_dates <- as.logical(include_dates)
  if (is.na(include_dates)) {
    include_dates <- TRUE
  }

  tryCatch(
    {
      result <- hgnc_validate_panel(
        items = items,
        policy = policy,
        suggest_replacements = suggest_replacements,
        include_dates = include_dates,
        index = NULL # Will build fresh index each time
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Get Gene Card Resource
#*
#* Retrieve a formatted gene card with essential information for LLM context.
#* This provides a resource-like view of gene data including symbol, name,
#* location, status, aliases, cross-references, and group memberships.
#*
#* @get /resources/gene_card
#* @param hgnc_id:str HGNC ID (with or without "HGNC:" prefix) or gene symbol
#* @param format:str Output format - "json" (default), "markdown", or "text"
#* @response 200 Gene card resource with uri, mimeType, and content
#* @response 400 Bad request - missing or invalid parameters
#* @response 404 Gene not found
#* @response 500 Internal server error
#* @tag Resources
endpoint_get_gene_card <- function(req, res, hgnc_id = NULL, format = "json") {
  # Validate hgnc_id parameter
  if (is.null(hgnc_id) || nchar(trimws(as.character(hgnc_id))) == 0) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'hgnc_id' parameter is required and must be non-empty"
    ))
  }

  # Validate format
  if (!format %in% c("json", "markdown", "text")) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'format' must be one of: json, markdown, text"
    ))
  }

  tryCatch(
    {
      result <- hgnc_get_gene_card(hgnc_id = hgnc_id, format = format)
      return(result)
    },
    error = function(e) {
      # Check if it's a "not found" error
      if (grepl("not found", e$message, ignore.case = TRUE)) {
        res$status <- 404
        return(list(
          error = "Not found",
          message = e$message
        ))
      } else {
        res$status <- 500
        return(list(
          error = "Internal server error",
          message = e$message
        ))
      }
    }
  )
}

#* Get Group Card Resource
#*
#* Retrieve a formatted gene group card with members and metadata.
#* Provides a resource-like view of gene group information including
#* member counts and optionally full member details.
#*
#* @get /resources/group_card
#* @param group_id_or_name Numeric gene group ID or group name/slug
#* @param format:str Output format - "json" (default), "markdown", or "text"
#* @param include_members:bool Whether to include full member records (default: TRUE)
#* @response 200 Group card resource with uri, mimeType, and content
#* @response 400 Bad request - missing or invalid parameters
#* @response 404 Group not found
#* @response 500 Internal server error
#* @tag Resources
endpoint_get_group_card <- function(
  req,
  res,
  group_id_or_name = NULL,
  format = "json",
  include_members = TRUE
) {
  # Validate group_id_or_name parameter
  if (is.null(group_id_or_name)) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'group_id_or_name' parameter is required"
    ))
  }

  # Validate format
  if (!format %in% c("json", "markdown", "text")) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'format' must be one of: json, markdown, text"
    ))
  }

  # Convert include_members to logical
  include_members <- as.logical(include_members)
  if (is.na(include_members)) {
    include_members <- TRUE
  }

  tryCatch(
    {
      result <- hgnc_get_group_card(
        group_id_or_name = group_id_or_name,
        format = format,
        include_members = include_members
      )
      return(result)
    },
    error = function(e) {
      # Check if it's a "not found" error
      if (grepl("not found", e$message, ignore.case = TRUE)) {
        res$status <- 404
        return(list(
          error = "Not found",
          message = e$message
        ))
      } else {
        res$status <- 500
        return(list(
          error = "Internal server error",
          message = e$message
        ))
      }
    }
  )
}

#* Get Snapshot Metadata Resource
#*
#* Retrieve metadata about the currently cached HGNC dataset, including
#* version information, download date, source URL, and basic statistics.
#*
#* @get /resources/snapshot
#* @param format:str Output format - "json" (default), "markdown", or "text"
#* @response 200 Snapshot metadata resource with uri, mimeType, and content
#* @response 500 Internal server error
#* @tag Resources
endpoint_get_snapshot_metadata <- function(res, format = "json") {
  # Validate format
  if (!format %in% c("json", "markdown", "text")) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'format' must be one of: json, markdown, text"
    ))
  }

  tryCatch(
    {
      result <- hgnc_get_snapshot_metadata(format = format)
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}

#* Get Changes Summary Resource
#*
#* Retrieve a summary of nomenclature changes since a specified date.
#* Provides a compact change log with gene IDs, symbols, and modification dates.
#*
#* @get /resources/changes_summary
#* @param since:str ISO 8601 date (YYYY-MM-DD) from which to track changes
#* @param format:str Output format - "json" (default), "markdown", or "text"
#* @param change_type:str Type of changes - "all" (default), "symbol", "name", "status", or "modified"
#* @param max_results:int Maximum number of changes to return (default: 100)
#* @response 200 Changes summary resource with uri, mimeType, and content
#* @response 400 Bad request - missing or invalid parameters
#* @response 500 Internal server error
#* @tag Resources
endpoint_get_changes_summary <- function(
  req,
  res,
  since = NULL,
  format = "json",
  change_type = "all",
  max_results = 100
) {
  # Validate since parameter
  if (is.null(since)) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'since' parameter is required (use YYYY-MM-DD format)"
    ))
  }

  # Validate format
  if (!format %in% c("json", "markdown", "text")) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'format' must be one of: json, markdown, text"
    ))
  }

  # Validate change_type
  valid_change_types <- c("all", "symbol", "name", "status", "modified")
  if (!change_type %in% valid_change_types) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = sprintf(
        "'change_type' must be one of: %s",
        paste(valid_change_types, collapse = ", ")
      )
    ))
  }

  # Validate max_results
  max_results <- as.integer(max_results)
  if (is.na(max_results) || max_results < 1) {
    res$status <- 400
    return(list(
      error = "Bad request",
      message = "'max_results' must be a positive integer"
    ))
  }

  tryCatch(
    {
      result <- hgnc_get_changes_summary(
        since = since,
        format = format,
        change_type = change_type,
        max_results = max_results
      )
      return(result)
    },
    error = function(e) {
      res$status <- 500
      return(list(
        error = "Internal server error",
        message = e$message
      ))
    }
  )
}
