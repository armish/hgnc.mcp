# Tests for HGNC Gene Groups & Collections

# Helper function to check if we're offline
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection")
  }
}

# =============================================================================
# Tests for hgnc_search_groups()
# =============================================================================

test_that("hgnc_search_groups requires non-empty query", {
  expect_error(hgnc_search_groups(), "'query' must be a non-empty string")
  expect_error(hgnc_search_groups(NULL), "'query' must be a non-empty string")
  expect_error(hgnc_search_groups(""), "'query' must be a non-empty string")
})

test_that("hgnc_search_groups returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_search_groups("kinase")

  expect_type(result, "list")
  expect_true("numFound" %in% names(result))
  expect_true("groups" %in% names(result))
  expect_true("query" %in% names(result))

  expect_equal(result$query, "kinase")
  expect_type(result$groups, "list")
})

test_that("hgnc_search_groups finds gene groups (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Search for a common gene group type
  result <- hgnc_search_groups("zinc finger")

  expect_type(result, "list")

  # Should find some zinc finger groups
  expect_gte(result$numFound, 0)

  # If groups found, check structure
  if (result$numFound > 0) {
    first_group <- result$groups[[1]]
    expect_true("id" %in% names(first_group))
    expect_true("name" %in% names(first_group))

    # ID should be numeric or coercible to numeric
    expect_true(!is.na(as.numeric(first_group$id)))
  }
})

test_that("hgnc_search_groups respects limit parameter (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_search_groups("kinase", limit = 5)

  expect_type(result, "list")
  # Should return at most 5 groups
  expect_lte(length(result$groups), 5)
})

test_that("hgnc_search_groups handles no results gracefully (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Search for something that definitely doesn't exist
  result <- hgnc_search_groups("xyzabc123notarealgroup456")

  expect_type(result, "list")
  expect_equal(result$numFound, 0)
  expect_equal(length(result$groups), 0)
})

test_that("hgnc_search_groups returns unique groups (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_search_groups("immunoglobulin")

  expect_type(result, "list")

  if (result$numFound > 1) {
    # Extract all group IDs
    group_ids <- vapply(result$groups, function(g) as.character(g$id), character(1))

    # Check for uniqueness
    expect_equal(length(group_ids), length(unique(group_ids)))
  }
})

# =============================================================================
# Tests for hgnc_group_members()
# =============================================================================

test_that("hgnc_group_members requires group_id_or_name", {
  expect_error(hgnc_group_members(), "'group_id_or_name' is required")
  expect_error(hgnc_group_members(NULL), "'group_id_or_name' is required")
})

test_that("hgnc_group_members returns expected structure (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Use a known gene group ID (588 is a Zinc finger group)
  result <- hgnc_group_members(588)

  expect_type(result, "list")
  expect_true("numFound" %in% names(result))
  expect_true("docs" %in% names(result))
  expect_true("group_id_or_name" %in% names(result))

  expect_equal(result$group_id_or_name, 588)
})

test_that("hgnc_group_members by ID returns gene records (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Try with a known gene group ID
  result <- hgnc_group_members(588)

  expect_type(result, "list")

  # Should find some members
  if (result$numFound > 0) {
    expect_type(result$docs, "list")
    expect_gt(length(result$docs), 0)

    # Check structure of first gene record
    first_gene <- result$docs[[1]]
    expect_true("symbol" %in% names(first_gene))
    expect_true("hgnc_id" %in% names(first_gene))
    expect_true("status" %in% names(first_gene))
  }
})

test_that("hgnc_group_members can search by name (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # This should search for groups matching "kinase" and return members
  # Note: This may not find results if the name doesn't match exactly
  result <- hgnc_group_members("Protein kinase")

  expect_type(result, "list")
  # Structure should be present even if no results
  expect_true("numFound" %in% names(result))
  expect_true("docs" %in% names(result))
})

test_that("hgnc_group_members handles not found gracefully (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Use a group ID that shouldn't exist
  expect_warning(
    result <- hgnc_group_members(999999999),
    "not found|No gene groups found"
  )

  expect_type(result, "list")
  expect_equal(result$numFound, 0)
  expect_equal(length(result$docs), 0)
})

test_that("hgnc_group_members caching works", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # First call with cache
  result1 <- hgnc_group_members(588, use_cache = TRUE)

  # Second call should use cache (no rate limiter needed)
  result2 <- hgnc_group_members(588, use_cache = TRUE)

  # Results should be identical
  expect_equal(result1$numFound, result2$numFound)

  # Call without cache should work too
  reset_rate_limiter()
  result3 <- hgnc_group_members(588, use_cache = FALSE)

  expect_equal(result1$numFound, result3$numFound)
})

test_that("hgnc_group_members gene records contain group information (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  result <- hgnc_group_members(588)

  if (result$numFound > 0) {
    # Check that genes have group information
    first_gene <- result$docs[[1]]

    # Genes should have gene_group and gene_group_id fields
    expect_true("gene_group" %in% names(first_gene) ||
                "gene_group_id" %in% names(first_gene))
  }
})

# =============================================================================
# Integration tests - multiple functions working together
# =============================================================================

test_that("search groups and get members work together (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # 1. Search for gene groups
  search_results <- hgnc_search_groups("zinc finger", limit = 3)

  if (search_results$numFound > 0) {
    # 2. Get members of the first group
    first_group_id <- search_results$groups[[1]]$id

    reset_rate_limiter()
    members <- hgnc_group_members(first_group_id)

    expect_type(members, "list")
    expect_true("docs" %in% names(members))

    # Should have some members
    if (members$numFound > 0) {
      # 3. Verify genes have expected structure
      first_gene <- members$docs[[1]]
      expect_true("symbol" %in% names(first_gene))
      expect_true("hgnc_id" %in% names(first_gene))
    }
  } else {
    skip("No zinc finger groups found - API may have changed")
  }
})

test_that("workflow: find group, get members, extract symbols (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # 1. Search for immunoglobulin groups
  groups <- hgnc_search_groups("immunoglobulin", limit = 1)

  if (groups$numFound > 0) {
    # 2. Get members of the first group
    group_id <- groups$groups[[1]]$id
    group_name <- groups$groups[[1]]$name

    reset_rate_limiter()
    members <- hgnc_group_members(group_id)

    # 3. Extract gene symbols
    if (members$numFound > 0) {
      symbols <- vapply(members$docs, function(doc) doc$symbol %||% NA_character_, character(1))

      expect_type(symbols, "character")
      expect_gt(length(symbols), 0)
      expect_true(all(!is.na(symbols)))
    }
  } else {
    skip("No immunoglobulin groups found - API may have changed")
  }
})

test_that("multiple group queries respect rate limiting (live API)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Make multiple group queries
  group_ids <- c(588, 594, 595)

  results <- list()
  for (id in group_ids) {
    # Should not hit rate limit due to built-in rate limiting
    results[[as.character(id)]] <- hgnc_group_members(id, use_cache = FALSE)
  }

  expect_equal(length(results), length(group_ids))

  # All should have valid structure
  for (result in results) {
    expect_type(result, "list")
    expect_true("numFound" %in% names(result))
  }
})

# =============================================================================
# Edge cases and error handling
# =============================================================================

test_that("hgnc_search_groups handles special characters", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Test with special characters (should be URL encoded)
  result <- hgnc_search_groups("G-protein")

  expect_type(result, "list")
  # Should not error, even if no results
  expect_true("numFound" %in% names(result))
})

test_that("hgnc_group_members handles numeric vs string IDs", {
  skip_on_cran()
  skip_if_offline()
  skip_if_integration_tests()

  reset_rate_limiter()

  # Test with numeric ID
  result1 <- hgnc_group_members(588)

  reset_rate_limiter()

  # Test with string ID
  result2 <- hgnc_group_members("588")

  # Both should work
  expect_type(result1, "list")
  expect_type(result2, "list")

  # Should return same results
  expect_equal(result1$numFound, result2$numFound)
})
