#!/usr/bin/env Rscript
# Quick script to check date-related fields in HGNC data

library(hgnc.mcp)

# Load data
hgnc_data <- load_hgnc_data()

# Get all column names
all_fields <- names(hgnc_data)

# Find date-related fields
date_fields <- grep("date", all_fields, value = TRUE, ignore.case = TRUE)

cat("Date-related fields in HGNC data:\n")
cat(paste("-", date_fields), sep = "\n")

# Show a sample record with dates
cat("\n\nSample gene with date information:\n")
sample_idx <- which(!is.na(hgnc_data$date_modified))[1]
if (!is.na(sample_idx)) {
  sample_gene <- hgnc_data[sample_idx, c("symbol", "name", date_fields)]
  print(sample_gene)
}
