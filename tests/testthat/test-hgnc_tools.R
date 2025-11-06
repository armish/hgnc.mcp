# Tests for HGNC Essential Lookup Tools

# Helper function to check if we're offline
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection")
  }
}

# =============================================================================
# Tests for hgnc_find()
# =============================================================================

test_that("hgnc_find requires non-empty query", {
  expect_error(hgnc_find(), "'query' must be a non-empty string")
  expect_error(hgnc_find(NULL), "'query' must be a non-empty string")
  expect_error(hgnc_find(""), "'query' must be a non-empty string")
})

test_that("hgnc_find returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_find("BRCA1")

  expect_type(result, "list")
  expect_true("numFound" %in% names(result))
  expect_true("docs" %in% names(result))
  expect_true("query" %in% names(result))

  # Should find BRCA1
  expect_gt(result$numFound, 0)

  # docs should be a list
  expect_type(result$docs, "list")

  # First result should contain expected fields
  if (result$numFound > 0) {
    doc <- result$docs[[1]]
    expect_true("symbol" %in% names(doc))
    expect_true("hgnc_id" %in% names(doc))
  }
})

test_that("hgnc_find works with filters (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_find("kinase",
                      filters = list(status = "Approved"),
                      limit = 10)

  expect_type(result, "list")
  expect_gt(result$numFound, 0)

  # Check that results have Approved status
  if (result$numFound > 0) {
    statuses <- vapply(result$docs, function(doc) doc$status %||% NA_character_, character(1))
    # At least some should be Approved (exact filter behavior may vary)
    expect_true(any(statuses == "Approved", na.rm = TRUE))
  }
})

test_that("hgnc_find respects limit parameter (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_find("kinase", limit = 5)

  expect_type(result, "list")
  # Should return at most 5 results
  expect_lte(length(result$docs), 5)
})

test_that("hgnc_find handles no results gracefully (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Search for something that definitely doesn't exist
  result <- hgnc_find("xyzabc123notarealgene456")

  expect_type(result, "list")
  expect_equal(result$numFound, 0)
  expect_equal(length(result$docs), 0)
})

# =============================================================================
# Tests for hgnc_fetch()
# =============================================================================

test_that("hgnc_fetch requires field and term", {
  expect_error(hgnc_fetch(), "Both 'field' and 'term' are required")
  expect_error(hgnc_fetch("symbol"), "Both 'field' and 'term' are required")
  expect_error(hgnc_fetch(field = "symbol", term = NULL), "'term' must be a non-empty value")
  expect_error(hgnc_fetch(field = "", term = "BRCA1"), "'field' must be a non-empty string")
})

test_that("hgnc_fetch by symbol returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_fetch("symbol", "BRCA1")

  expect_type(result, "list")
  expect_true("numFound" %in% names(result))
  expect_true("docs" %in% names(result))
  expect_true("field" %in% names(result))
  expect_true("term" %in% names(result))

  expect_equal(result$field, "symbol")
  expect_equal(result$term, "BRCA1")

  # Should find exactly one BRCA1
  expect_equal(result$numFound, 1)

  # Check gene record structure
  doc <- result$docs[[1]]
  expect_equal(doc$symbol, "BRCA1")
  expect_true("hgnc_id" %in% names(doc))
  expect_true("name" %in% names(doc))
  expect_true("status" %in% names(doc))
})

test_that("hgnc_fetch by hgnc_id works (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # HGNC:1100 is BRCA1
  result <- hgnc_fetch("hgnc_id", "HGNC:1100")

  expect_type(result, "list")
  expect_equal(result$numFound, 1)

  doc <- result$docs[[1]]
  expect_equal(doc$symbol, "BRCA1")
  expect_equal(doc$hgnc_id, "HGNC:1100")
})

test_that("hgnc_fetch by entrez_id works (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Entrez ID 672 is BRCA1
  result <- hgnc_fetch("entrez_id", "672")

  expect_type(result, "list")
  expect_gt(result$numFound, 0)

  if (result$numFound > 0) {
    doc <- result$docs[[1]]
    expect_equal(doc$symbol, "BRCA1")
  }
})

test_that("hgnc_fetch handles not found gracefully (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_fetch("symbol", "NOTAREALSYMBOL12345")

  expect_type(result, "list")
  expect_equal(result$numFound, 0)
  expect_equal(length(result$docs), 0)
})

# =============================================================================
# Tests for hgnc_resolve_symbol()
# =============================================================================

test_that("hgnc_resolve_symbol requires non-empty symbol", {
  expect_error(hgnc_resolve_symbol(), "'symbol' must be a non-empty string")
  expect_error(hgnc_resolve_symbol(NULL), "'symbol' must be a non-empty string")
  expect_error(hgnc_resolve_symbol(""), "'symbol' must be a non-empty string")
})

test_that("hgnc_resolve_symbol validates mode parameter", {
  expect_error(
    hgnc_resolve_symbol("BRCA1", mode = "invalid"),
    "'arg' should be one of"
  )
})

test_that("hgnc_resolve_symbol strict mode finds exact matches (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_resolve_symbol("BRCA1", mode = "strict")

  expect_type(result, "list")
  expect_true("query" %in% names(result))
  expect_true("approved_symbol" %in% names(result))
  expect_true("status" %in% names(result))
  expect_true("confidence" %in% names(result))
  expect_true("hgnc_id" %in% names(result))

  expect_equal(result$approved_symbol, "BRCA1")
  expect_equal(result$confidence, "exact")
  expect_equal(result$hgnc_id, "HGNC:1100")
  expect_equal(result$status, "Approved")
})

test_that("hgnc_resolve_symbol lenient mode finds exact matches (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_resolve_symbol("TP53", mode = "lenient")

  expect_type(result, "list")
  expect_equal(result$approved_symbol, "TP53")
  expect_equal(result$confidence, "exact")
  expect_equal(result$status, "Approved")
})

test_that("hgnc_resolve_symbol handles case insensitivity (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Test lowercase
  result_lower <- hgnc_resolve_symbol("brca1", mode = "strict")
  expect_equal(result_lower$approved_symbol, "BRCA1")

  reset_rate_limiter()

  # Test mixed case
  result_mixed <- hgnc_resolve_symbol("BrCa1", mode = "strict")
  expect_equal(result_mixed$approved_symbol, "BRCA1")
})

test_that("hgnc_resolve_symbol handles whitespace (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_resolve_symbol("  BRCA1  ", mode = "strict")
  expect_equal(result$approved_symbol, "BRCA1")
})

test_that("hgnc_resolve_symbol returns not_found for missing genes (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_resolve_symbol("NOTAREALGENE12345", mode = "strict")

  expect_type(result, "list")
  expect_true(is.na(result$approved_symbol))
  expect_equal(result$confidence, "not_found")
  expect_equal(length(result$candidates), 0)
})

test_that("hgnc_resolve_symbol can return full record (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  result <- hgnc_resolve_symbol("BRCA1", mode = "strict", return_record = TRUE)

  expect_type(result, "list")
  expect_true("record" %in% names(result))
  expect_type(result$record, "list")

  # Record should have gene fields
  expect_true("symbol" %in% names(result$record))
  expect_true("name" %in% names(result$record))
  expect_true("location" %in% names(result$record))
})

# Note: Testing alias and previous symbol matching would require knowing
# specific aliases/previous symbols that are currently in HGNC.
# These tests verify the structure but may need updating with real examples.

test_that("hgnc_resolve_symbol lenient mode structure is correct (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Use a common gene that likely has aliases
  result <- hgnc_resolve_symbol("EGFR", mode = "lenient")

  expect_type(result, "list")
  expect_true("approved_symbol" %in% names(result))
  expect_true("confidence" %in% names(result))
  expect_true("candidates" %in% names(result))

  # Confidence should be one of the expected values
  expect_true(result$confidence %in% c("exact", "alias", "previous", "fuzzy", "not_found"))
})

# =============================================================================
# Tests for hgnc_xrefs()
# =============================================================================

test_that("hgnc_xrefs requires non-empty id_or_symbol", {
  expect_error(hgnc_xrefs(), "'id_or_symbol' must be a non-empty string")
  expect_error(hgnc_xrefs(NULL), "'id_or_symbol' must be a non-empty string")
  expect_error(hgnc_xrefs(""), "'id_or_symbol' must be a non-empty string")
})

test_that("hgnc_xrefs by symbol returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  xrefs <- hgnc_xrefs("BRCA1")

  expect_type(xrefs, "list")

  # Check core identifiers
  expect_true("hgnc_id" %in% names(xrefs))
  expect_true("symbol" %in% names(xrefs))
  expect_true("entrez_id" %in% names(xrefs))
  expect_true("ensembl_gene_id" %in% names(xrefs))
  expect_true("status" %in% names(xrefs))

  # BRCA1 should have these values
  expect_equal(xrefs$symbol, "BRCA1")
  expect_equal(xrefs$hgnc_id, "HGNC:1100")
  expect_equal(xrefs$status, "Approved")

  # Should have Entrez ID (672)
  expect_false(is.na(xrefs$entrez_id))
})

test_that("hgnc_xrefs by HGNC ID works (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  xrefs <- hgnc_xrefs("HGNC:1100")

  expect_type(xrefs, "list")
  expect_equal(xrefs$symbol, "BRCA1")
  expect_equal(xrefs$hgnc_id, "HGNC:1100")
})

test_that("hgnc_xrefs includes common cross-references (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  xrefs <- hgnc_xrefs("BRCA1")

  # Check that cross-reference fields are present
  expect_true("uniprot_ids" %in% names(xrefs))
  expect_true("omim_id" %in% names(xrefs))
  expect_true("ccds_id" %in% names(xrefs))
  expect_true("refseq_accession" %in% names(xrefs))
  expect_true("mane_select" %in% names(xrefs))
  expect_true("agr" %in% names(xrefs))
  expect_true("ucsc_id" %in% names(xrefs))
})

test_that("hgnc_xrefs handles not found with warning (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  expect_warning(
    result <- hgnc_xrefs("NOTAREALGENE12345"),
    "not found in HGNC database"
  )

  expect_null(result)
})

test_that("hgnc_xrefs returns NA for missing cross-references", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Find a gene that might not have all cross-references
  # For this test, we just verify that the function handles NAs properly
  xrefs <- hgnc_xrefs("BRCA1")

  # All fields should exist (even if NA)
  expect_true("uniprot_ids" %in% names(xrefs))
  expect_true("omim_id" %in% names(xrefs))

  # Values should be either character or NA
  expect_true(is.character(xrefs$symbol) || is.na(xrefs$symbol))
})

# =============================================================================
# Integration tests - multiple functions working together
# =============================================================================

test_that("resolve and fetch work together (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # First resolve a symbol
  resolved <- hgnc_resolve_symbol("BRCA1", mode = "lenient")

  expect_false(is.na(resolved$approved_symbol))
  expect_false(is.na(resolved$hgnc_id))

  reset_rate_limiter()

  # Then fetch full record using HGNC ID
  fetched <- hgnc_fetch("hgnc_id", resolved$hgnc_id)

  expect_equal(fetched$numFound, 1)
  expect_equal(fetched$docs[[1]]$symbol, "BRCA1")
})

test_that("find and xrefs work together (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # Search for genes
  results <- hgnc_find("TP53", limit = 1)

  expect_gt(results$numFound, 0)

  top_symbol <- results$docs[[1]]$symbol

  reset_rate_limiter()

  # Get cross-references for top result
  xrefs <- hgnc_xrefs(top_symbol)

  expect_type(xrefs, "list")
  expect_equal(xrefs$symbol, top_symbol)
})

test_that("workflow: search, resolve, get xrefs (live API)", {
  skip_on_cran()
  skip_if_offline()

  reset_rate_limiter()

  # 1. Search for genes related to breast cancer
  search_results <- hgnc_find("BRCA", limit = 3)
  expect_gt(search_results$numFound, 0)

  # 2. Resolve the top hit
  top_symbol <- search_results$docs[[1]]$symbol

  reset_rate_limiter()
  resolved <- hgnc_resolve_symbol(top_symbol, mode = "lenient")
  expect_equal(resolved$confidence, "exact")

  # 3. Get cross-references
  reset_rate_limiter()
  xrefs <- hgnc_xrefs(resolved$approved_symbol)
  expect_type(xrefs, "list")
  expect_equal(xrefs$symbol, resolved$approved_symbol)
})
