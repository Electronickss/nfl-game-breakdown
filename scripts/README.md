# Scripts

R source code for the project. Split into entry points and function modules for testability.

## Entry Points

| Script | Purpose | CLI |
|--------|---------|-----|
| `win-probability.R` | Load PBP data, generate WP charts for all games in a season | `Rscript scripts/win-probability.R [year] [--verbose]` |
| `fantasy-stats.R` | Load PBP data, generate per-team and per-game charts for a week | `Rscript scripts/fantasy-stats.R [year] [week] [team] [--verbose]` |

## Function Modules

| Script | Contents |
|--------|----------|
| `helpers.R` | Shared color constants and `vlog()` logging function |
| `wp-functions.R` | Win probability: data loading, play classification, theme, chart plotting |
| `fs-functions.R` | Fantasy stats: team stats computation, summary/target/air yards/RB/WRTE charts |

## Architecture

Entry points handle library loading, CLI parsing, and orchestration. Function modules contain pure, testable functions. Both entry points use the guard `if (!interactive() && !exists("TESTING"))` to prevent side effects when sourced by tests.

## Legacy

`NFL-Win-Probability.R` and `InGameWinPercentage.R` are unused legacy scripts.
