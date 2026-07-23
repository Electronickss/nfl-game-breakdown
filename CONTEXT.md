# NFL Game Breakdown - Project Context

## Purpose
Automated NFL game analysis for dynasty fantasy football. Generates charts from play-by-play data for social media threads and analysis content. Runs via GitHub Actions.

## Directory Structure
```
nfl-game-breakdown/
├── .github/workflows/generate-charts.yml  # GitHub Actions (manual trigger + weekly schedule)
├── charts/                                  # Generated PNGs (gitignored)
├── data/                                    # Cached PBP data (gitignored)
├── Logos/                                   # Team logo PNGs
└── scripts/
    ├── win-probability.R                    # Win prob line + scoring/turnover/penalty markers
    ├── fantasy-stats.R                      # Team summaries, target share, air yards, RB/WR workload charts
    ├── NFL-Win-Probability.R                # Original script (legacy)
    └── InGameWinPercentage.R                # Original script (legacy)
```

## Scripts

### win-probability.R
- Loads nflfastR PBP data 2009-present
- Generates win probability charts for every game in the latest season
- Uses Vegas home WP (vegas_home_wp)
- Rug marks: scoring (black), turnovers (red), penalties (yellow)
- Output: `data/{year}/wp-{game_id}.png`

### fantasy-stats.R
Main script with these functions:
- `get_team_stats(pbp, team, week)` — passing/rushing/receiving stats
- `plot_team_summary()` — text-based team stat summary
- `plot_target_share()` — bar chart of targets
- `plot_air_yards()` — bar chart of air yards
- `plot_rb_workload(pbp, week, year)` — RB touches on win prob line (rush=bottom, targets=top, pass att=X)
- `plot_wrte_targets(pbp, week, year)` — WR/TE touches on win prob line (targets=top, rushes=bottom, pass att=X)
- Default run: 2023 week 16 BAL

### GitHub Actions
- Manual dispatch inputs: year, week, team (optional)
- Generates league-wide RB/WR-TE charts + team-specific charts
- Uploads all charts as artifacts

## Key Dependencies
- nflfastR, nflreadr, tidyverse, scales, ggimage, gghighcontrast, lubridate
- R 4.3.1

## TODO / Next Steps
- Test scripts locally end-to-end
- Add snap count analysis
- Add red zone opportunity charts
- Potentially add player EPA/charts
- Push to GitHub and verify Actions workflow runs
- Consider renaming/rebranding for dynasty focus
