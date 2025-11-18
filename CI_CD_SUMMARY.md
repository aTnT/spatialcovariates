# CI/CD Infrastructure Summary

## Overview

Complete continuous integration and deployment infrastructure has been
set up for the spatialcovariates package using GitHub Actions.

## Components Installed

### 1. GitHub Actions Workflows (`.github/workflows/`)

#### R-CMD-check.yaml

- **Purpose**: Comprehensive package testing across platforms
- **Runs on**: Ubuntu (release + devel), macOS, Windows
- **Checks**: Package installation, tests, documentation, CRAN
  compliance
- **Trigger**: Push to main/master/claude branches, pull requests

#### test-coverage.yaml

- **Purpose**: Code coverage tracking and reporting
- **Runs on**: Ubuntu latest
- **Reports to**: Codecov
- **Target**: 80% coverage
- **Trigger**: Push to main/master, pull requests

#### pkgdown.yaml

- **Purpose**: Auto-build and deploy documentation website
- **Deploys to**: GitHub Pages (gh-pages branch)
- **URL**: <https://atnt.github.io/spatialcovariates/>
- **Trigger**: Push to main/master, releases

#### lint.yaml

- **Purpose**: Code style and quality enforcement
- **Tool**: lintr package
- **Standards**: Tidyverse style guide
- **Trigger**: Push to main/master, pull requests

### 2. Configuration Files

#### \_pkgdown.yml

- Bootstrap 5 theme with Cosmo style
- Organized function reference
- Custom navigation structure
- Article/vignette support

#### codecov.yml

- 80% coverage target for project and patches
- 1% threshold for changes
- Ignores package docs and test files

#### .lintr

- 120 character line length
- Flexible object naming
- Excludes package documentation files

### 3. GitHub Templates

#### Issue Templates (`.github/ISSUE_TEMPLATE/`)

- **bug_report.md**: Structured bug reporting
- **feature_request.md**: Feature suggestion template

#### Pull Request Template

- **pull_request_template.md**: Comprehensive PR checklist
- Includes sections for description, testing, breaking changes

### 4. Documentation

#### .github/CONTRIBUTING.md

- Complete contributor guide
- Code style guidelines
- Development workflow
- Testing requirements
- PR process

#### .github/WORKFLOWS.md

- Detailed workflow documentation
- Troubleshooting guide
- Configuration explanations
- Best practices

## Setup Instructions

### 1. Enable GitHub Pages

1.  Go to `Settings → Pages`
2.  Source: Deploy from branch
3.  Branch: `gh-pages`
4.  Directory: `/ (root)`

### 2. Enable Codecov (Optional for Public Repos)

1.  Visit <https://codecov.io/>
2.  Sign in with GitHub
3.  Add the spatialcovariates repository
4.  For private repos: Add `CODECOV_TOKEN` to GitHub secrets

### 3. Branch Protection (Recommended)

Configure for main/master branches:

`Settings → Branches → Add rule`

Recommended settings: - \[x\] Require pull request reviews - \[x\]
Require status checks to pass: - R-CMD-check (ubuntu-latest,
R-release) - R-CMD-check (macos-latest, R-release) - R-CMD-check
(windows-latest, R-release) - test-coverage - lint - \[x\] Require
branches to be up to date - \[x\] Include administrators

## Workflow Status Badges

Add to README.md (already included):

``` markdown
[![R-CMD-check](https://github.com/aTnT/spatialcovariates/workflows/R-CMD-check/badge.svg)](https://github.com/aTnT/spatialcovariates/actions)
[![test-coverage](https://codecov.io/gh/aTnT/spatialcovariates/branch/main/graph/badge.svg)](https://codecov.io/gh/aTnT/spatialcovariates)
```

## Expected Workflow Results

When a PR is opened or commits are pushed:

1.  **R-CMD-check**: Runs on 4 platforms (~10-15 minutes)
    - Expected: 0 errors, 0 warnings, 0-1 notes
2.  **test-coverage**: Measures code coverage (~5 minutes)
    - Expected: ≥80% coverage
3.  **lint**: Checks code style (~2 minutes)
    - Expected: No linting errors
4.  **pkgdown** (main branch only): Builds docs (~5 minutes)
    - Expected: Site deployed to GitHub Pages

## Local Testing Before Push

Run this checklist locally to ensure CI will pass:

``` r
# 1. Generate documentation
devtools::document()

# 2. Run tests
devtools::test()

# 3. Check package
devtools::check()

# 4. Check code style
lintr::lint_package()

# 5. Check coverage
covr::package_coverage()

# 6. Build documentation site
pkgdown::build_site()
```

Expected results: - Tests: All pass - Check: 0 errors, 0 warnings -
Lint: No errors - Coverage: ≥80%

## Files Modified

### New Files Created

    .github/
    ├── workflows/
    │   ├── R-CMD-check.yaml
    │   ├── test-coverage.yaml
    │   ├── pkgdown.yaml
    │   └── lint.yaml
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    ├── CONTRIBUTING.md
    ├── WORKFLOWS.md
    └── pull_request_template.md

    _pkgdown.yml
    codecov.yml
    .lintr
    CI_CD_SUMMARY.md (this file)

### Files Updated

    .Rbuildignore  (added CI/CD files to exclusions)

## Monitoring

### View All Workflow Runs

<https://github.com/aTnT/spatialcovariates/actions>

### View Coverage Reports

<https://codecov.io/gh/aTnT/spatialcovariates>

### View Documentation Site

<https://atnt.github.io/spatialcovariates/>

## Troubleshooting

### Workflows Not Running?

1.  Check Actions are enabled: `Settings → Actions → General`
2.  Verify workflow files are committed to `.github/workflows/`
3.  Check branch name matches trigger pattern

### Coverage Upload Fails?

1.  For public repos: No token needed
2.  For private repos: Add `CODECOV_TOKEN` to GitHub secrets
3.  Check `codecov.yml` is properly formatted

### Documentation Not Deploying?

1.  Enable GitHub Pages: `Settings → Pages`
2.  Set source to `gh-pages` branch
3.  Ensure workflow has write permissions
4.  Check workflow logs for errors

### System Dependency Failures?

Platform-specific dependencies are configured in workflows: - Ubuntu:
`apt-get install` (GDAL, GEOS, PROJ, etc.) - macOS: `brew install` -
Windows: Handled by Rtools

If failures occur, update the dependency installation commands in the
workflow files.

## Performance

Typical workflow execution times:

| Workflow      | Duration  | Platforms                    |
|---------------|-----------|------------------------------|
| R-CMD-check   | 10-15 min | 4 (Ubuntu×2, macOS, Windows) |
| test-coverage | 5 min     | 1 (Ubuntu)                   |
| lint          | 2 min     | 1 (Ubuntu)                   |
| pkgdown       | 5 min     | 1 (Ubuntu)                   |

**Total for PR**: ~15-20 minutes (parallel execution)

## Next Steps

1.  **First Push**:
    - Push to a feature branch
    - Verify all workflows pass
    - Fix any issues
2.  **Enable GitHub Pages**:
    - Go to Settings → Pages
    - Enable from gh-pages branch
3.  **Optional Enhancements**:
    - Add `CODECOV_TOKEN` for private repo
    - Configure branch protection
    - Set up email notifications
    - Add more badges to README
4.  **Maintenance**:
    - Monitor workflow runs regularly
    - Update dependencies as needed
    - Keep workflows in sync with r-lib/actions

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [r-lib/actions](https://github.com/r-lib/actions)
- [Codecov Documentation](https://docs.codecov.com/)
- [pkgdown](https://pkgdown.r-lib.org/)
- [lintr](https://lintr.r-lib.org/)

## Success Criteria

Your CI/CD is working correctly when:

✅ All workflow badges show “passing” ✅ Coverage badge shows ≥80% ✅
Documentation site is accessible ✅ PRs show status checks ✅ No errors
in workflow runs

------------------------------------------------------------------------

**Status**: CI/CD infrastructure complete and ready for use.

**Committed**: All files committed to
`claude/review-requirements-md-012N3iJvMXgxmkHUYvdHA4Tt` branch.

**Action Required**: Enable GitHub Pages after first push to trigger
documentation deployment.
