# Tests

testthat test suite with 95% coverage enforcement (aim for 100% when possible).

## Running

```bash
Rscript -e 'testthat::test_dir("tests/testthat", reporter = "summary")'
```

## Coverage

```bash
Rscript -e '
library(testthat); library(covr)
cov <- file_coverage(
  source_files = c("scripts/wp-functions.R", "scripts/fs-functions.R"),
  test_files = c("tests/testthat/setup.R", "tests/testthat/test-win-probability.R", "tests/testthat/test-fantasy-stats.R")
)
cat(sprintf("Coverage: %.1f%%\n", percent_coverage(cov)))
'
```

## Structure

- `testthat.R` — Test runner entry point
- `testthat/setup.R` — Sources `helpers.R` and function modules with path-agnostic logic
- `testthat/helper-mock-data.R` — Mock data factories for unit tests
- `testthat/test-win-probability.R` — Tests for WP data pipeline, helpers, theme, and chart
- `testthat/test-fantasy-stats.R` — Tests for team stats, all chart types, and logging
