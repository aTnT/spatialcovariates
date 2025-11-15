#!/usr/bin/env Rscript
# Generate roxygen2 documentation
# This should be run before R CMD check

if (!requireNamespace("roxygen2", quietly = TRUE)) {
  install.packages("roxygen2")
}

roxygen2::roxygenize()
cat("Documentation generated successfully\n")
