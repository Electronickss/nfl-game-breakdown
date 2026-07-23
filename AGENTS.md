# Agents

Guidelines for AI agents working on this codebase.

## Overview

Automated NFL game analysis for dynasty fantasy football. Generates charts from nflfastR play-by-play data for social media and analysis content. Runs via GitHub Actions on a weekly schedule.

## Project Structure

```
nfl-game-breakdown/
├── .github/workflows/
│   ├── win-probability.yml    # Weekly WP charts (schedule + dispatch)
│   ├── fantasy-stats.yml      # Weekly fantasy charts (schedule + dispatch)
│   └── test.yml               # CI tests + coverage
├── charts/                     # Generated PNGs (gitignored)
├── data/                       # Cached PBP data (gitignored)
├── Logos/                      # Team logo PNGs
├── scripts/
│   ├── helpers.R                 # Shared constants (colors) and vlog()
│   ├── win-probability.R         # Entry point: loads libraries, calls main()
│   ├── fantasy-stats.R           # Entry point: loads libraries, calls main()
│   ├── wp-functions.R            # Pure functions for win probability charts
│   ├── fs-functions.R            # Pure functions for fantasy stats charts
│   ├── NFL-Win-Probability.R     # Legacy (unused)
│   └── InGameWinPercentage.R     # Legacy (unused)
├── tests/
│   ├── testthat.R              # Test runner
│   └── testthat/
│       ├── setup.R             # Sources helper + function files
│       ├── helper-mock-data.R  # Mock data factories
│       ├── test-win-probability.R
│       └── test-fantasy-stats.R
├── DESCRIPTION                 # Package metadata (for testthat)
├── .Rbuildignore
└── AGENTS.md                   # This file
```

## Function Separation

Functions are separated from entry-point scripts for testability:

- **`helpers.R`**: Shared color constants and `vlog()` function. Sourced by all other scripts.
- **`wp-functions.R`**: Pure functions for win probability (plot, theme, helpers). Sourced by `win-probability.R` and tests.
- **`fs-functions.R`**: Pure functions for fantasy stats (get_team_stats, plot_*). Sourced by `fantasy-stats.R` and tests.

Entry-point scripts (`win-probability.R`, `fantasy-stats.R`) handle library loading, CLI parsing, and orchestration. Guard: `if (!interactive() && !exists("TESTING"))`.

## Tests

95% coverage (aim for 100% when possible). Tests source function files directly via `setup.R`.

```bash
# Run tests
Rscript -e 'testthat::test_dir("tests/testthat", reporter = "summary")'

# Check coverage
Rscript -e '
library(testthat); library(covr)
cov <- file_coverage(
  source_files = c("scripts/wp-functions.R", "scripts/fs-functions.R"),
  test_files = c("tests/testthat/setup.R", "tests/testthat/test-win-probability.R", "tests/testthat/test-fantasy-stats.R")
)
cat(sprintf("Coverage: %.1f%%\n", percent_coverage(cov)))
'
```

Mocking network calls: use ` <<- ` to reassign wrapper functions (e.g. `load_data`, `load_logos`) with `on.exit` cleanup. nflfastR/nflreadr namespaces are locked, so can't mock at that level.

## Scripts

### win-probability.R
- Loads nflfastR PBP data for a single season (not all years)
- Generates win probability charts for every game in a season
- Uses Vegas home WP (`vegas_home_wp`)
- Rug marks: scoring (black), turnovers (red), penalties (yellow)
- Output: `data/{year}/wp-{game_id}.png`
- CLI: `Rscript scripts/win-probability.R [year] [--verbose]`

### fantasy-stats.R
- Generates per-team charts: summary, target share, air yards
- Generates per-game RB workload and WR/TE target charts (one set per game in the week)
- Processes teams in parallel using `future::future_lapply` (2 workers)
- CLI: `Rscript scripts/fantasy-stats.R [year] [week] [team] [--verbose]`
- If `team` is omitted or empty, processes all teams from the schedule
- Output: `charts/{TEAM}-w{week}-*.png`, `charts/rb-workload-w{week}-{game_id}.png`, `charts/wrte-targets-w{week}-{game_id}.png`

### Verbose Flag
Both scripts accept `--verbose` anywhere in the args. When set, prints progress messages (which game/team is being processed, files saved, etc.). Without it, scripts are silent except for errors.

## Workflows

Both chart workflows trigger on:
- **Schedule**: Monday 8am UTC during NFL season (Sept-Jan)
- **Manual dispatch**: From the Actions tab

### win-probability.yml inputs
| Input    | Required | Default | Description |
|----------|----------|---------|-------------|
| year     | No       | auto    | Season year. Empty = auto-detect from current date. |
| verbose  | No       | false   | Enable verbose logging. |

### fantasy-stats.yml inputs
| Input    | Required | Default | Description |
|----------|----------|---------|-------------|
| year     | Yes      | 2025    | Season year. |
| week     | Yes      | 1       | Week number (1-18). |
| team     | No       | all     | Team abbreviation (e.g. BAL). Empty = all teams. |
| verbose  | No       | false   | Enable verbose logging. |

### test.yml
Triggers on push to main and PRs. Runs tests and checks coverage (95% threshold).

## Dependencies

R packages: nflfastR, nflreadr, dplyr, ggplot2, glue, scales, ggimage, lubridate, future, future.apply, testthat, covr
System: libmagick++-dev (for ggimage/magick)

## Conventions

- R version: 4.3.1 (pinned in workflows)
- CRAN mirror: `https://cloud.r-project.org`
- nflreadr caching: `options(nflreadr.cache = "filesystem")` — data cached in `~/.cache/nflreadr`, persisted between CI runs via `actions/cache`
- R package caching: via `actions/cache` on `$R_LIBS_USER`
- Parallel processing: `future::future_lapply` with `plan(multisession, workers = 2)` for team charts
- Workflows use `Rscript` to run scripts directly
- All chart output is gitignored; artifacts are uploaded via `actions/upload-artifact`
- Error handling: `tryCatch` with `cat()` for errors (always visible). Progress uses `vlog()` (verbose only).
- ggplot2: uses `linewidth` for line-based geoms (`geom_line`, `geom_hline`, `geom_vline`, `geom_rug`) and theme elements (`element_line`, `element_rect`). Uses `size` for text (`geom_text`, `element_text`) and points (`geom_point`).
- String interpolation: uses `glue::glue()` (not `str_interp` or `sprintf` for user-facing strings).
- Pipes: uses native pipe `|>` (R 4.1+), not magrittr `%>%`.

## Branch Strategy

- Direct pushes to `main` are blocked (branch protection)
- All changes go through PRs
- PRs require the `test` status check to pass before merging
- No review requirements (merge when ready and CI passes)

## TODO

- Auto-detect NFL week from schedule (currently hardcoded defaults for 2025)
- Snap count analysis
- Red zone opportunity charts
- Player EPA charts
