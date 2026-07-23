# Workflows

GitHub Actions workflows for automated chart generation and CI.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `win-probability.yml` | Monday 8am UTC (NFL season) + manual dispatch | Generate win probability charts for all games in a week |
| `fantasy-stats.yml` | Monday 8am UTC (NFL season) + manual dispatch | Generate per-team fantasy stat charts |
| `test.yml` | Push to main + PRs to main | Run test suite and check coverage (95% threshold) |

All chart workflows cache nflreadr data between runs via `actions/cache` on `~/.cache/nflreadr`.
