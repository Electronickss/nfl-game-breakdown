# NFL Game Breakdown

Automated NFL game analysis for fantasy football. Generates charts showing win probability, player stats, target shares, and air yards.

## Charts Generated

- **Win Probability** — Game flow with scoring, turnover, and penalty markers
- **Team Summary** — Passing, rushing, and receiving stats in one view
- **Target Share** — Who got the targets for each team
- **Air Yards** — Deep threats and opportunity analysis
- **RB Workload** — Rush attempts by RB for both teams (dynasty focus)
- **WR/TE Targets** — Target distribution for WRs and TEs (dynasty focus)

## Usage

### GitHub Actions

Run manually from the Actions tab with these inputs:
- `year` — NFL season year (e.g., `2024`)
- `week` — Week number (e.g., `16`)
- `team` — Optional team abbreviation for single-team charts (e.g., `BAL`)

### Local

```r
# Install dependencies
install.packages(c("nflfastR", "tidyverse", "scales", "ggimage", "lubridate"))

# Generate win probability charts
source("scripts/win-probability.R")

# Generate fantasy stats for a specific team/week
source("scripts/fantasy-stats.R")
```

## Output

Charts are saved as PNG files in the `charts/` directory, ready for:
- Social media threads
- Fantasy football analysis
- Game recap content

## Data Source

Uses [nflfastR](https://github.com/nflverse/nflfastR) play-by-play data.

## Project Structure

```
nfl-game-breakdown/
├── .github/workflows/    # GitHub Actions configuration
├── charts/               # Generated chart PNGs
├── data/                 # Cached play-by-play data
├── Logos/                # Team logo images
└── scripts/
    ├── win-probability.R      # Win probability charts
    └── fantasy-stats.R        # Fantasy-focused stats charts
```
