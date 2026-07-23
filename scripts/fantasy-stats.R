if (!interactive()) {
  options(show.error.locations = TRUE)
  options(nflreadr.cache = "filesystem")
  library(nflfastR)
  library(tidyverse)
  library(scales)
  library(ggimage)
  library(lubridate)
  library(future)
  library(future.apply)
  options(scipen = 9999)
}

source("scripts/fs-functions.R")

vlog <- function(...) {
  if (VERBOSE) cat(str_interp(...))
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  VERBOSE <<- "--verbose" %in% args
  args <- args[args != "--verbose"]

  year <- if (length(args) >= 1) as.integer(args[1]) else 2023
  week <- if (length(args) >= 2) as.integer(args[2]) else 16
  team <- if (length(args) >= 3 && nchar(args[3]) > 0) args[3] else ""

  vlog("Season: ${year}, Week: ${week}, Team: ${if (nchar(team) > 0) team else 'all'}\n")

  dir.create("charts", showWarnings = FALSE)

  pbp <- load_pbp_data(year)

  if (nchar(team) > 0) {
    teams <- team
  } else {
    schedule <- load_schedule(year) %>% filter(week == !!week)
    teams <- unique(c(schedule$home_team, schedule$away_team))
  }

  vlog("Generating charts for ${length(teams)} teams...\n")

  plan(multisession, workers = 2)

  process_team <- function(t) {
    vlog("Processing ${t}...\n")
    tryCatch({
      team_stats <- get_team_stats(pbp, t, week)
      summary_plot <- plot_team_summary(team_stats, t, week, year)
      ggsave(str_interp("charts/${t}-w${week}-summary.png"), summary_plot, width = 8, height = 6, dpi = 150)
      vlog("  Saved ${t}-w${week}-summary.png\n")

      if (nrow(team_stats$receiving) > 0) {
        target_plot <- plot_target_share(team_stats$receiving, t)
        ggsave(str_interp("charts/${t}-w${week}-targets.png"), target_plot, width = 8, height = 6, dpi = 150)
        vlog("  Saved ${t}-w${week}-targets.png\n")

        air_plot <- plot_air_yards(team_stats$receiving, t)
        ggsave(str_interp("charts/${t}-w${week}-airyards.png"), air_plot, width = 8, height = 6, dpi = 150)
        vlog("  Saved ${t}-w${week}-airyards.png\n")
      }
    }, error = function(e) {
      cat(str_interp("Error processing ${t}: ${e$message}\n"))
    })
  }

  future_lapply(teams, process_team, future.seed = TRUE)

  rb_plot <- plot_rb_workload(pbp, week, year)
  ggsave(str_interp("charts/rb-workload-w${week}.png"), rb_plot, width = 10, height = 6, dpi = 150)

  wrte_plot <- plot_wrte_targets(pbp, week, year)
  ggsave(str_interp("charts/wrte-targets-w${week}.png"), wrte_plot, width = 10, height = 6, dpi = 150)

  vlog("Generated charts for Week ${week}, ${year}\n")
}

if (!interactive() && !exists("TESTING")) {
  VERBOSE <<- FALSE
  main()
}
