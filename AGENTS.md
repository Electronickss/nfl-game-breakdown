# Agents

Guidelines for AI agents working on this codebase.

## Overview

Automated NFL game analysis for dynasty fantasy football. Generates charts from nflfastR play-by-play data for social media and analysis content. Runs via GitHub Actions on a weekly schedule.

## Project Structure

```
nfl-game-breakdown/
├── .github/workflows/
│   ├── win-probability.yml    # Weekly WP charts (schedule + dispatch)
│   └── fantasy-stats.yml      # Weekly fantasy charts (schedule + dispatch)
├── charts/                     # Generated PNGs (gitignored)
├── data/                       # Cached PBP data (gitignored)
├── Logos/                      # Team logo PNGs
├── scripts/
│   ├── win-probability.R       # Win prob line + scoring/turnover/penalty markers
│   ├── fantasy-stats.R         # Team summaries, target share, air yards, RB/WR workload
│   ├── NFL-Win-Probability.R   # Legacy (unused)
│   └── InGameWinPercentage.R   # Legacy (unused)
└── AGENTS.md                   # This file
```

## Scripts

### win-probability.R
- Loads nflfastR PBP data 2009-present
- Generates win probability charts for every game in a season
- Uses Vegas home WP (`vegas_home_wp`)
- Rug marks: scoring (black), turnovers (red), penalties (yellow)
- Output: `data/{year}/wp-{game_id}.png`
- CLI: `Rscript scripts/win-probability.R [year] [--verbose]`

### fantasy-stats.R
- Generates per-team charts: summary, target share, air yards, RB workload, WR/TE targets
- CLI: `Rscript scripts/fantasy-stats.R [year] [week] [team] [--verbose]`
- If `team` is omitted or empty, processes all teams from the schedule
- Output: `charts/{TEAM}-w{week}-*.png`, `charts/rb-workload-w{week}.png`, `charts/wrte-targets-w{week}.png`

### Verbose Flag
Both scripts accept `--verbose` anywhere in the args. When set, prints progress messages (which game/team is being processed, files saved, etc.). Without it, scripts are silent except for errors.

## Workflows

Both workflows trigger on:
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

## Running Locally

```bash
# Win probability charts for 2025 season
Rscript scripts/win-probability.R 2025

# Fantasy stats for a specific week
Rscript scripts/fantasy-stats.R 2025 1 BAL

# With verbose output
Rscript scripts/win-probability.R 2025 --verbose
Rscript scripts/fantasy-stats.R 2025 1 BAL --verbose
```

## Dependencies

R packages: nflfastR, nflreadr, tidyverse, scales, ggimage, lubridate
System: libmagick++-dev (for ggimage/magick)

## Conventions

- R version: 4.3.1 (pinned in workflows)
- CRAN mirror: `https://cloud.r-project.org`
- Workflows use `Rscript` with `-e` for inline R, or run scripts directly
- All chart output is gitignored; artifacts are uploaded via `actions/upload-artifact`
- Error handling: `tryCatch` with `cat()` for errors (always visible). Progress uses `vlog()` (verbose only).

## Branch Strategy

- Direct pushes to `main` are blocked (branch protection)
- All changes go through PRs
- No review requirements (merge when ready and CI passes)
- No CI tests yet (planned)

## TODO

- Add CI tests
- Auto-detect NFL week from schedule (currently hardcoded defaults for 2025)
- Snap count analysis
- Red zone opportunity charts
- Player EPA charts
