# Contributing to spatialcovariates

Thank you for your interest in contributing to spatialcovariates! This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## Ways to Contribute

### Reporting Bugs

Before creating a bug report:
- Check the existing issues to avoid duplicates
- Verify the bug with the latest development version

When reporting bugs, include:
- Clear description of the issue
- Minimal reproducible example
- System information (OS, R version, package version)
- Error messages and stack traces

### Suggesting Features

Feature requests are welcome! Please:
- Check existing feature requests first
- Clearly describe the use case
- Provide example usage code if possible
- Consider implementation complexity

### Contributing Code

#### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/spatialcovariates.git
   cd spatialcovariates
   ```

3. Install development dependencies:
   ```r
   install.packages(c("devtools", "testthat", "roxygen2", "lintr"))
   ```

4. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Development Workflow

1. **Make your changes**
   - Follow existing code style
   - Add roxygen2 documentation for new functions
   - Include examples in documentation

2. **Add tests**
   - Create or update test files in `tests/testthat/`
   - Aim for >80% code coverage
   - Test edge cases and error conditions

3. **Document your changes**
   - Update `NEWS.md` with your changes
   - Add roxygen2 comments for new functions
   - Update README if needed

4. **Check your code**
   ```r
   # Generate documentation
   devtools::document()

   # Run tests
   devtools::test()

   # Check package
   devtools::check()

   # Check code style
   lintr::lint_package()
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Clear description of changes"
   ```

#### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use `snake_case` for function and variable names
- Maximum line length: 120 characters
- Use roxygen2 for all exported functions
- Include `@examples` in documentation

Example function structure:
```r
#' Function title
#'
#' Detailed description of what the function does.
#'
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character, target resolution (e.g., "10km")
#'
#' @return SpatRaster object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#' result <- my_function(bbox, resolution = "10km")
#' }
my_function <- function(extent, resolution = "10km") {
  # Implementation
}
```

#### Testing Guidelines

- Write unit tests for all new functions
- Use `testthat` framework
- Test both success and failure cases
- Mock external dependencies when possible

Example test structure:
```r
test_that("function_name works correctly", {
  input <- c(1, 2, 3)
  result <- function_name(input)

  expect_equal(result, expected_output)
  expect_type(result, "numeric")
})

test_that("function_name handles errors", {
  expect_error(function_name("invalid"), "error message pattern")
})
```

#### Pull Request Process

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request**
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template

4. **PR Requirements**
   - All tests must pass
   - R CMD check must pass with 0 errors, 0 warnings
   - Code coverage should not decrease
   - Documentation must be complete
   - NEWS.md must be updated

5. **Review Process**
   - Maintainers will review your PR
   - Address any requested changes
   - Once approved, your PR will be merged

## Development Environment

### Recommended Setup

```r
# Install all dependencies
devtools::install_deps(dependencies = TRUE)

# Install development tools
install.packages(c(
  "devtools",
  "testthat",
  "roxygen2",
  "lintr",
  "covr",
  "pkgdown"
))
```

### Running Checks Locally

```r
# Full check suite
devtools::check()

# Just run tests
devtools::test()

# Check code coverage
covr::package_coverage()

# Build documentation site
pkgdown::build_site()
```

## Adding New Data Sources

When adding support for a new environmental covariate:

1. **Create a new R file** in `R/` following the naming pattern:
   - `R/datasource_name.R`

2. **Implement three-layer structure**:
   - `download_datasource_name()` - Download tiles
   - `process_datasource_name()` - Process and aggregate
   - `getDatasourceName()` - User-facing wrapper (exported)

3. **Follow existing patterns**:
   - Use consistent parameter names
   - Include progress messages
   - Implement retry logic for downloads
   - Handle errors gracefully

4. **Add to main wrapper**:
   - Integrate into `getBiasCovariates()`
   - Add optional `include_datasource` parameter

5. **Document thoroughly**:
   - Full roxygen2 documentation
   - Data source citation
   - Example usage
   - Known limitations

6. **Add tests**:
   - Tile name generation
   - Parameter validation
   - Error handling

## Questions?

- Open an issue for general questions
- Tag maintainers for urgent matters
- Check existing documentation and issues first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions help make spatialcovariates better for everyone. We appreciate your time and effort!
