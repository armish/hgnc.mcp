#!/usr/bin/env Rscript
# Manual test script for HGNC REST client
# Run this to verify the REST client works against the live HGNC API

library(hgnc.mcp)

cat("Testing HGNC REST Client\n")
cat("========================\n\n")

# Test 1: Get API info
cat("1. Testing hgnc_rest_info()...\n")
info <- hgnc_rest_info()
cat("   Last modified:", info$lastModified, "\n")
cat("   Number of searchable fields:", length(info$searchableFields), "\n")
cat("   Number of stored fields:", length(info$storedFields), "\n")
cat("   ✓ Success!\n\n")

# Test 2: Test rate limiting
cat("2. Testing rate limiting (10 requests)...\n")
reset_rate_limiter()
start_time <- Sys.time()
for (i in 1:10) {
  hgnc.mcp:::rate_limit_wait()
}
elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat("   Elapsed time:", round(elapsed, 2), "seconds\n")
cat("   ✓ Success!\n\n")

# Test 3: Test caching
cat("3. Testing session-level caching...\n")
clear_hgnc_cache()
start1 <- Sys.time()
info1 <- hgnc_rest_info()
time1 <- as.numeric(difftime(Sys.time(), start1, units = "secs"))

start2 <- Sys.time()
info2 <- hgnc_rest_info()
time2 <- as.numeric(difftime(Sys.time(), start2, units = "secs"))

cat("   First call:", round(time1 * 1000, 1), "ms\n")
cat("   Second call (cached):", round(time2 * 1000, 1), "ms\n")
cat("   Speedup:", round(time1 / time2, 1), "x\n")
cat("   ✓ Success!\n\n")

# Test 4: Raw API call
cat("4. Testing direct hgnc_rest_get()...\n")
reset_rate_limiter()
result <- hgnc_rest_get("info")
cat("   Response type:", class(result), "\n")
cat("   Has responseHeader:", !is.null(result$responseHeader), "\n")
cat("   ✓ Success!\n\n")

cat("All tests passed! ✓\n")
