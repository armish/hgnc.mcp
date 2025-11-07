# Tests for HGNC Data Cache Management
#
# This test suite covers:
# - Cache directory management (get_hgnc_cache_dir, get_hgnc_cache_path)
# - Cache freshness checking (is_hgnc_cache_fresh)
# - Cache metadata (get_hgnc_cache_info)
# - Cache clearing (clear_hgnc_cache)
# - Local cache for offline operations
#
# Note: download_hgnc_data() and load_hgnc_data() should be tested manually
# as they require internet connection and download large files.

test_that("get_hgnc_cache_dir creates and returns valid directory", {
  cache_dir <- get_hgnc_cache_dir()

  expect_type(cache_dir, "character")
  expect_true(dir.exists(cache_dir))
  expect_true(grepl("hgnc.mcp", cache_dir))
})

test_that("cache path functions return valid paths", {
  cache_path <- get_hgnc_cache_path()
  metadata_path <- get_hgnc_metadata_path()

  expect_type(cache_path, "character")
  expect_type(metadata_path, "character")
  expect_match(cache_path, "hgnc_complete_set\\.txt$")
  expect_match(metadata_path, "cache_metadata\\.rds$")
})

test_that("is_hgnc_cache_fresh returns FALSE when no cache exists", {
  # Clear cache first
  clear_hgnc_cache()

  expect_false(is_hgnc_cache_fresh())
})

test_that("cache info returns NULL when no cache exists", {
  # Clear cache first
  clear_hgnc_cache()

  expect_null(get_hgnc_cache_info())
})

test_that("clear_hgnc_cache works", {
  result <- clear_hgnc_cache()

  expect_true(result)
  expect_false(file.exists(get_hgnc_cache_path()))
  expect_false(file.exists(get_hgnc_metadata_path()))
})

# Note: Tests for download_hgnc_data() and load_hgnc_data() are not included
# here as they require internet connection and would download a large file.
# These should be tested manually or in integration tests.
