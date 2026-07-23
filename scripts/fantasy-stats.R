if (!interactive()) {
  options(show.error.locations = TRUE)
  options(nflreadr.cache = "filesystem")
  library(nflfastR)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(glue)
  library(future)
  library(future.apply)
  options(scipen = 9999)
}

source("scripts/helpers.R")
source("scripts/fs-functions.R")

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  VERBOSE <<- "--verbose" %in% args
  args <- args[args != "--verbose"]

  year <- if (length(args) >= 1) as.integer(args[1]) else 2025
  week <- if (length(args) >= 2) as.integer(args[2]) else 1
  team <- if (length(args) >= 3 && nchar(args[3]) > 0) args[3] else ""

  vlog("Season: {year}, Week: {week}, Team: {if (nchar(team) > 0) team else 'all'}\n")

  dir.create("charts", showWarnings = FALSE)

  pbp <- load_pbp_data(year)

  if (nchar(team) > 0) {
    teams <- team
  } else {
    schedule <- load_schedule(year) |> filter(week == !!week)
    teams <- unique(c(schedule$home_team, schedule$away_team))
  }

  vlog("Generating charts for {length(teams)} teams...\n")

  plan(multisession, workers = 2)

  process_team <- function(t) {
    vlog("Processing {t}...\n")
    tryCatch({
      team_stats <- get_team_stats(pbp, t, week)
      summary_plot <- plot_team_summary(team_stats, t, week, year)
      ggsave("charts/{t}-w{week}-summary.png", summary_plot, width = 8, height = 6, dpi = 150)
      vlog("  Saved {t}-w{week}-summary.png\n")

      if (nrow(team_stats$receiving) > 0) {
        target_plot <- plot_target_share(team_stats$receiving, t)
        ggsave("charts/{t}-w{week}-targets.png", target_plot, width = 8, height = 6, dpi = 150)
        vlog("  Saved {t}-w{week}-targets.png\n")

        air_plot <- plot_air_yards(team_stats$receiving, t)
        ggsave("charts/{t}-w{week}-airyards.png", air_plot, width = 8, height = 6, dpi = 150)
        vlog("  Saved {t}-w{week}-airyards.png\n")
      }
    }, error = function(e) {
      cat("Error processing {t}: {e$message}\n")
    })
  }

  future_lapply(teams, process_team, future.seed = TRUE)

  game_ids <- unique(pbp$game_id[pbp$week == week])

  for (gid in game_ids) {
    tryCatch({
      rb_plot <- plot_rb_workload(pbp, week, year, game_id = gid)
      ggsave("charts/rb-workload-w{week}-{gid}.png", rb_plot, width = 10, height = 6, dpi = 150)
      vlog("  Saved rb-workload-w{week}-{gid}.png\n")

      wrte_plot <- plot_wrte_targets(pbp, week, year, game_id = gid)
      ggsave("charts/wrte-targets-w{week}-{gid}.png", wrte_plot, width = 10, height = 6, dpi = 150)
      vlog("  Saved wrte-targets-w{week}-{gid}.png\n")
    }, error = function(e) {
      cat("Error generating workload charts for {gid}: {e$message}\n")
    })
  }

  vlog("Generated charts for Week {week}, {year}\n")
}

if (!interactive() && !exists("TESTING")) {
  VERBOSE <<- FALSE
  main()
}
