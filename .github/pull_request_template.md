## Description

Please include a summary of the changes and which issue is fixed. Include relevant motivation and context.

Fixes # (issue)

## Type of change

Please delete options that are not relevant:

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Changes Made

Please describe the changes in detail:

-
-
-

## Testing

Please describe the tests you ran to verify your changes:

```r
# Test code here
library(spatialcovariates)

# Example test
bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
result <- myFunction(bbox)
```

## Checklist

Before submitting, please ensure:

- [ ] My code follows the style guidelines of this project (ran `lintr::lint_package()`)
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes (`devtools::test()`)
- [ ] R CMD check passes with 0 errors, 0 warnings (`devtools::check()`)
- [ ] I have updated NEWS.md with my changes
- [ ] Any dependent changes have been merged and published

## Additional Information

Add any other context about the pull request here:

## Screenshots (if applicable)

If your changes include visual elements or affect output, add screenshots here.

## Breaking Changes

If this PR introduces breaking changes, please describe:
- What breaks
- How users should update their code
- Migration guide (if applicable)
