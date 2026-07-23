# Test Files

testthat 3rd edition tests and test infrastructure.

## Files

| File | Description |
|------|-------------|
| `setup.R` | Sources `helpers.R`, `wp-functions.R`, and `fs-functions.R` with path-agnostic logic for both `test_dir` and `covr::file_coverage` |
| `helper-mock-data.R` | Factory functions: `make_mock_game()`, `make_mock_logos()`, `make_mock_receiving()`, `make_mock_team_stats()` |
| `test-win-probability.R` | Tests play classification helpers, theme, chart generation, data pipeline (including TIE games and NA handling) |
| `test-fantasy-stats.R` | Tests team stats computation, all chart types, `vlog()` behavior, and edge cases |

## Mocking Strategy

Network-dependent functions (`load_data`, `load_logos`) are mocked using ` <<- ` reassignment with `on.exit` cleanup. nflfastR/nflreadr namespaces are locked and cannot be mocked at that level.
