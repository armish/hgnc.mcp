#!/usr/bin/env Rscript

# Generate Package Documentation
# This script generates the man/ documentation files from roxygen comments

if (!requireNamespace("roxygen2", quietly = TRUE)) {
  message("Installing roxygen2...")
  install.packages("roxygen2", repos = "https://cloud.r-project.org/")
}

message("Generating documentation...")
roxygen2::roxygenise()
message("Documentation generated successfully in man/ directory")
