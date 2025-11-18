# GitHub Actions Workflows

This document describes the continuous integration and deployment workflows configured for the spatialcovariates package.

## Overview

The package uses GitHub Actions for automated testing, code quality checks, and documentation deployment. All workflows are defined in `.github/workflows/`.

## Workflows

### 1. R-CMD-check.yaml

**Trigger**: Push to main/master/claude branches, pull requests
**Purpose**: Comprehensive package checking across multiple platforms
**Status Badge**: [![R-CMD-check](https://github.com/aTnT/spatialcovariates/workflows/R-CMD-check/badge.svg)](https://github.com/aTnT/spatialcovariates/actions)

#### Test Matrix

The workflow tests on:
- **Ubuntu Latest** (R release)
- **Ubuntu Latest** (R devel)
- **macOS Latest** (R release)
- **Windows Latest** (R release)

#### What it checks

- Package installation
- Documentation generation
- Unit tests execution
- R CMD check (as CRAN)
- Examples execution
- Cross-platform compatibility

#### System Dependencies

**Linux**:
- GDAL (geospatial data abstraction library)
- GEOS (geometry engine)
- PROJ (coordinate transformation)
- UDUNITS2 (unit conversion)
- SSL, CURL, XML2

**macOS**:
- GDAL, PROJ, GEOS, UDUNITS via Homebrew

**Windows**:
- Rtools (automatically configured)

#### Expected Results

- **Errors**: 0
- **Warnings**: 0
- **Notes**: 0-1 (NOTE about new submission is acceptable)

#### Failure Handling

If the check fails:
1. Review the uploaded check results artifact
2. Examine `testthat.Rout` for test failures
3. Fix issues locally and push again

### 2. test-coverage.yaml

**Trigger**: Push to main/master, pull requests
**Purpose**: Measure and report test coverage
**Status Badge**: [![test-coverage](https://codecov.io/gh/aTnT/spatialcovariates/branch/main/graph/badge.svg)](https://codecov.io/gh/aTnT/spatialcovariates)

#### What it does

- Runs test suite with coverage tracking
- Uploads results to Codecov
- Reports coverage percentage
- Flags coverage decreases

#### Configuration

Coverage settings in `codecov.yml`:
- Target: 80% overall coverage
- Project threshold: 1%
- Patch threshold: 1%
- Ignores: Package documentation, test files

#### Interpreting Results

- **Green**: Coverage meets or exceeds target
- **Yellow**: Coverage decreased but within threshold
- **Red**: Coverage below target or decreased significantly

### 3. pkgdown.yaml

**Trigger**: Push to main/master, releases, manual dispatch
**Purpose**: Build and deploy documentation website
**Website**: https://atnt.github.io/spatialcovariates/

#### What it builds

- Function reference from roxygen2 docs
- README as homepage
- NEWS as changelog
- Articles/vignettes (if any)
- Search functionality

#### Configuration

Site configuration in `_pkgdown.yml`:
- Bootstrap 5 theme
- Cosmo bootswatch style
- Organized function reference
- Custom navigation

#### Deployment

- Builds on every push to main
- Deploys to `gh-pages` branch
- Accessible at GitHub Pages URL
- No action needed after setup

#### Local Preview

Build the site locally:
```r
pkgdown::build_site()
```

Then open `docs/index.html` in a browser.

### 4. lint.yaml

**Trigger**: Push to main/master, pull requests
**Purpose**: Enforce code style and quality

#### What it checks

- Code style compliance (tidyverse style guide)
- Common programming errors
- Code smells
- Documentation issues

#### Configuration

Linting rules in `.lintr`:
- Max line length: 120 characters
- Allows flexible object naming
- Skips complexity checks
- Ignores package documentation

#### Fixing Lint Issues

Run locally before pushing:
```r
# Check for issues
lintr::lint_package()

# Auto-fix some issues
styler::style_pkg()
```

## Workflow Status

Check all workflow statuses at:
https://github.com/aTnT/spatialcovariates/actions

## Branch Protection

For production branches (main/master), configure:

1. **Required checks**:
   - R-CMD-check (all platforms)
   - test-coverage
   - lint

2. **Settings**:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date
   - No direct pushes to main

## Secrets and Tokens

### GITHUB_TOKEN

Automatically provided by GitHub Actions. Used for:
- Installing packages from GitHub
- Deploying to GitHub Pages
- Uploading artifacts

### Additional Secrets (if needed)

If you add external services:

1. **CODECOV_TOKEN**: For private repos (optional for public)
2. **PAT**: Personal Access Token for advanced GitHub API operations

Add secrets at: `Settings → Secrets and variables → Actions`

## Troubleshooting

### Workflow not running?

- Check `.github/workflows/` files are committed
- Verify branch name matches trigger pattern
- Check Actions are enabled: `Settings → Actions → General`

### System dependency failures?

**Ubuntu**: Update `apt-get install` commands in workflow
**macOS**: Update `brew install` commands
**Windows**: Usually handled by Rtools automatically

### Coverage upload fails?

- Check Codecov is enabled for your repo
- Verify `codecov.yml` is correctly configured
- For private repos, add `CODECOV_TOKEN` secret

### Documentation deployment fails?

- Ensure GitHub Pages is enabled: `Settings → Pages`
- Check source is set to `gh-pages` branch
- Verify write permissions for `GITHUB_TOKEN`

### Lint failures on legacy code?

Temporarily disable strict linting:
```r
# In .lintr, add to exclusions:
exclusions: list(
  "R/legacy_file.R"
)
```

## Best Practices

### Before Pushing

Run all checks locally:
```r
# Document
devtools::document()

# Test
devtools::test()

# Check
devtools::check()

# Lint
lintr::lint_package()

# Coverage
covr::package_coverage()
```

### For Pull Requests

1. Create feature branch from main
2. Make changes and commit
3. Push to fork
4. Open PR and wait for checks
5. Address any failures
6. Request review

### For Releases

1. Update version in DESCRIPTION
2. Update NEWS.md
3. Run full check suite
4. Merge to main
5. Create GitHub release
6. Tag with version number

## Adding New Workflows

To add a custom workflow:

1. Create `.github/workflows/workflow-name.yaml`
2. Define trigger events
3. Specify jobs and steps
4. Add required secrets (if any)
5. Test on a feature branch first
6. Document in this file

Example minimal workflow:
```yaml
name: Custom Check

on:
  push:
    branches: [main]

jobs:
  custom-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Custom script
        run: Rscript -e 'source("scripts/custom.R")'
```

## Performance Optimization

Workflows can be slow. Optimize by:

1. **Caching dependencies**:
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.local/share/renv
       key: ${{ runner.os }}-renv-${{ hashFiles('**/renv.lock') }}
   ```

2. **Running checks in parallel**:
   - Matrix builds run simultaneously
   - Separate workflows run concurrently

3. **Skipping unnecessary checks**:
   ```yaml
   on:
     push:
       paths-ignore:
         - '**.md'
         - 'docs/**'
   ```

4. **Using public RSPM** (configured in workflows):
   - Faster binary package installation
   - No compilation needed

## Monitoring

### Status Badges

Add to README.md:
```markdown
[![R-CMD-check](https://github.com/aTnT/spatialcovariates/workflows/R-CMD-check/badge.svg)](https://github.com/aTnT/spatialcovariates/actions)
[![Codecov](https://codecov.io/gh/aTnT/spatialcovariates/branch/main/graph/badge.svg)](https://codecov.io/gh/aTnT/spatialcovariates)
```

### Email Notifications

Configure at: `Settings → Notifications → Actions`

Options:
- Only failures
- All workflows
- Per-workflow basis

## Resources

- [GitHub Actions docs](https://docs.github.com/en/actions)
- [r-lib/actions](https://github.com/r-lib/actions)
- [Codecov docs](https://docs.codecov.com/)
- [pkgdown](https://pkgdown.r-lib.org/)
- [lintr](https://lintr.r-lib.org/)

## Questions?

Open an issue if:
- Workflows fail unexpectedly
- New platform support needed
- Additional checks required
- Performance issues
