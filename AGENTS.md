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
├── VERSION                     # Current version (major.minor)
├── charts/                     # Generated PNGs (gitignored)
├── data/                       # Cached PBP data (gitignored)
├── Logos/                      # Team logo PNGs
├── scripts/
│   ├── helpers.R                 # Shared constants (colors), vlog(), read_version(), add_version_watermark(), load_team_colors()
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

- **`helpers.R`**: Shared color constants, `vlog()`, `read_version()`, `add_version_watermark()`, `load_team_colors()`, `generate_synopsis()`, color clump detection (`hex_to_rgb()`, `rgb_to_lab()`, `color_distance()`, `resolve_team_colors()`). Sourced by all other scripts.
- **`wp-functions.R`**: Pure functions for win probability (plot, theme, helpers). Sourced by `win-probability.R` and tests.
- **`fs-functions.R`**: Pure functions for fantasy stats (get_team_stats, plot_*). Sourced by `fantasy-stats.R` and tests.

Entry-point scripts (`win-probability.R`, `fantasy-stats.R`) handle library loading, CLI parsing, and orchestration. Guard: `if (!interactive() && !exists("TESTING"))`.

## Chart Designs

### Win Probability Chart (`plot_win_probability`)
- **Line**: Possession-colored segments (each team's color when they have the ball), with color clump detection (away team switches to secondary color if too similar to home)
- **Rug marks**: scoring (black, home top/bottom), turnovers (red, inverted), penalties (yellow, inverted)
- **Logos**: Team logos at top/bottom if `ggimage` is installed
- **Watermark**: Version number in bottom-right corner
- **Axes**: Reversed x (game clock counts down), y = 0-100% home WP

### RB Workload Chart (`plot_rb_workload`)
- **Line**: Possession-colored WP segments with color clump detection
- **Touch points**: Shape by type — Rush (circle), Target (triangle), Fumble (diamond), Score (star)
- **Labels**: ggrepel labels on first touch per player, positioned away from line (falls back to geom_text if ggrepel unavailable)
- **Players**: Top 4 RBs per team by touch count, each in distinct palette color
- **Legend**: Team possession colors and touch type shapes

### WR/TE Targets Chart (`plot_wrte_targets`)
- **Line**: Possession-colored WP segments with color clump detection
- **Touch points**: Target (triangle), Fumble (diamond), Score (star)
- **Labels**: ggrepel labels on first touch per player, positioned away from line
- **Players**: Top 5 pass catchers per team by target count
- **Legend**: Team possession colors and touch type shapes

## Versioning

### VERSION File
- Located at project root, stores `major.minor` (e.g. `1.0`)
- Read by `read_version()` in `helpers.R` (tries `VERSION`, `../VERSION`, `../../VERSION`)
- Used for watermark on all charts and release tag suffixes

### Chart Release Tags
- Win probability: `{year}-wp-{game_id}-v{version}` (e.g. `2025-wp-2025_01_KC_BAL-v1.0`)
- Fantasy stats: `{year}-fantasy-w{week}-v{version}` (e.g. `2025-fantasy-w1-v1.0`)

### Major Version Bump
When a major version bump is detected (new major number in VERSION vs. latest release), all charts for the current run are regenerated even if output files already exist. Minor version changes only generate missing charts (skip existing).

### Skip Logic
Each workflow checks for existing release assets before generating:
- **Missing chart**: Generate and upload to release
- **Existing chart, same major version**: Skip
- **Existing chart, different major version**: Regenerate (overwrite release asset)
- **`--force` flag**: Regenerate all charts regardless of existing assets

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

### Bug Fix Testing Practice

When fixing a bug, always follow red-green testing to prove the fix works:

1. **Red**: Revert the fix (introduce the bug), write a test that exposes it, run the test and confirm it fails
2. **Green**: Re-apply the fix, run the test and confirm it passes

This ensures the test actually catches the bug and isn't just testing passing behavior. Never skip the red step — a test you haven't seen fail doesn't prove anything.

## Scripts

### win-probability.R
- Loads nflfastR PBP data for a single season (not all years)
- Generates win probability charts for every game in a season
- Uses Vegas home WP (`vegas_home_wp`)
- Possession-colored WP line, challenge rug marks, version watermark
- Output: `data/{year}/wp-{game_id}-v{version}.png`
- CLI: `Rscript scripts/win-probability.R [year] [--verbose] [--games GAME_IDS] [--force]`
  - `--games`: Comma-separated game IDs to process (e.g. `2025_01_KC_BAL,2025_01_BAL_KC`)
  - `--force`: Regenerate all charts even if release assets exist

### fantasy-stats.R
- Generates per-team charts: summary, target share, air yards
- Generates per-game RB workload and WR/TE target charts (one set per game in the week)
- Processes teams in parallel using `future::future_lapply` (2 workers)
- Output versioned filenames: `charts/{TEAM}-w{week}-v{version}.png`, `charts/rb-workload-w{week}-{game_id}-v{version}.png`, `charts/wrte-targets-w{week}-{game_id}-v{version}.png`
- CLI: `Rscript scripts/fantasy-stats.R [year] [week] [team] [--verbose] [--force]`
  - If `team` is omitted or empty, processes all teams from the schedule
  - `--force`: Regenerate all charts even if release assets exist

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
| force    | No       | false   | Regenerate all charts even if release assets exist. |
| verbose  | No       | false   | Enable verbose logging. |

### fantasy-stats.yml inputs
| Input    | Required | Default | Description |
|----------|----------|---------|-------------|
| year     | Yes      | 2025    | Season year. |
| week     | Yes      | 1       | Week number (1-18). |
| team     | No       | all     | Team abbreviation (e.g. BAL). Empty = all teams. |
| force    | No       | false   | Regenerate all charts even if release assets exist. |
| verbose  | No       | false   | Enable verbose logging. |

### test.yml
Triggers on push to main and PRs. Runs tests and checks coverage (95% threshold).

## Release Strategy

Chart workflows create GitHub Releases to persist generated charts:
- **Release creation**: `gh release create {tag} --latest=false --notes "{synopsis}"`
- **Release titles**: Prefixed with year (e.g. `2025 Week 1: KC at BAL (v1.0)`)
- **Release notes**: Game synopsis generated from PBP data (winner, score, key plays)
- **Asset upload**: `gh release upload {tag} {file} --clobber`
- **Skip existing**: Check `gh release view {tag} --json assets` before generating
- **Cleanup**: Delete workflow run artifacts after successful release upload
- **No git commits**: Charts never committed to the repo; only stored as release assets

## Dependencies

R packages: nflfastR, nflreadr, dplyr, ggplot2, glue, scales, ggimage, lubridate, future, future.apply, ggrepel, testthat, covr
System: libcurl4-openssl-dev, libuv1-dev, libmagick++-dev (chart workflows only), libxml2-dev, libfontconfig1-dev, libharfbuzz-dev, libfribidi-dev, libfreetype6-dev, libpng-dev, libtiff5-dev, libjpeg-dev

## Conventions

- R version: 4.3.1 (pinned in workflows)
- CRAN mirror: `https://cloud.r-project.org`
- nflreadr caching: `options(nflreadr.cache = "filesystem")` — data cached in `~/.cache/nflreadr`, persisted between CI runs via `actions/cache`
- R package caching: via `actions/cache` on `$R_LIBS_USER`
- Cache key prefixes: Each workflow uses unique prefix (`test-`, `wp-`, `fs-`) to avoid collisions
- Parallel processing: `future::future_lapply` with `plan(multisession, workers = 2)` for team charts
- Workflows use `Rscript` to run scripts directly
- Error handling: `tryCatch` with `cat()` for errors (always visible). Progress uses `vlog()` (verbose only).
- ggplot2: uses `linewidth` for line-based geoms and theme elements. Uses `size` for text and points.
- String interpolation: uses `glue::glue()` (not `str_interp` or `sprintf` for user-facing strings).
- Pipes: uses native pipe `|>` (R 4.1+), not magrittr `%>%`. Never use `{}` on RHS of `|>` (magrittr-only feature).
- Version watermark: all charts include `add_version_watermark()` call for traceability

## Branch Strategy

- Direct pushes to `main` are blocked (branch protection)
- All changes go through PRs
- PRs require the `test` status check to pass before merging (`strict: true`)
- No review requirements (merge when ready and CI passes)

## TODO

- Auto-detect NFL week from schedule (currently hardcoded defaults for 2025)
- Snap count analysis
- Red zone opportunity charts
- Player EPA charts
