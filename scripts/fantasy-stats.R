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

  force <- "--force" %in% args
  args <- args[args != "--force"]

  year <- if (length(args) >= 1) as.integer(args[1]) else 2025
  week <- if (length(args) >= 2) as.integer(args[2]) else 1
  team <- if (length(args) >= 3 && nchar(args[3]) > 0) args[3] else ""

  version <- tryCatch(read_version(), error = function(e) "dev")
  vlog("Season: {year}, Week: {week}, Team: {if (nchar(team) > 0) team else 'all'} (v{version})\n")

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

      summary_path <- glue("charts/{t}-w{week}-summary-v{version}.png")
      if (force || !file.exists(summary_path)) {
        summary_plot <- plot_team_summary(team_stats, t, week, year)
        ggsave(summary_path, summary_plot, width = 8, height = 6, dpi = 150)
        vlog("  Saved {basename(summary_path)}\n")
      }

      if (nrow(team_stats$receiving) > 0) {
        target_path <- glue("charts/{t}-w{week}-targets-v{version}.png")
        if (force || !file.exists(target_path)) {
          target_plot <- plot_target_share(team_stats$receiving, t)
          ggsave(target_path, target_plot, width = 8, height = 6, dpi = 150)
          vlog("  Saved {basename(target_path)}\n")
        }

        air_path <- glue("charts/{t}-w{week}-airyards-v{version}.png")
        if (force || !file.exists(air_path)) {
          air_plot <- plot_air_yards(team_stats$receiving, t)
          ggsave(air_path, air_plot, width = 8, height = 6, dpi = 150)
          vlog("  Saved {basename(air_path)}\n")
        }
      }
    }, error = function(e) {
      cat("Error processing {t}: {e$message}\n")
    })
  }

  future_lapply(teams, process_team, future.seed = TRUE)

  game_ids <- unique(pbp$game_id[pbp$week == week])

  for (gid in game_ids) {
    tryCatch({
      rb_path <- glue("charts/rb-workload-w{week}-{gid}-v{version}.png")
      if (force || !file.exists(rb_path)) {
        rb_plot <- plot_rb_workload(pbp, week, year, game_id = gid)
        ggsave(rb_path, rb_plot, width = 10, height = 6, dpi = 150)
        vlog("  Saved {basename(rb_path)}\n")
      }

      wrte_path <- glue("charts/wrte-targets-w{week}-{gid}-v{version}.png")
      if (force || !file.exists(wrte_path)) {
        wrte_plot <- plot_wrte_targets(pbp, week, year, game_id = gid)
        ggsave(wrte_path, wrte_plot, width = 10, height = 6, dpi = 150)
        vlog("  Saved {basename(wrte_path)}\n")
      }
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
