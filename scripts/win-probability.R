if (!interactive() && !exists("TESTING")) {
  options(show.error.locations = TRUE)
  options(nflreadr.cache = "filesystem")
  library(nflfastR)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(ggimage)
  library(glue)
  library(lubridate)
  options(scipen = 9999)
}

source("scripts/helpers.R")
source("scripts/wp-functions.R")
source("scripts/fs-functions.R")

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  VERBOSE <<- "--verbose" %in% args
  args <- args[args != "--verbose"]

  force <- "--force" %in% args
  args <- args[args != "--force"]

  game_filter <- NULL
  if ("--games" %in% args) {
    idx <- which(args == "--games")
    game_filter <- strsplit(args[idx + 1], ",")[[1]]
    args <- args[-c(idx, idx + 1)]
  }

  week_filter <- NULL
  if ("--week" %in% args) {
    idx <- which(args == "--week")
    week_filter <- args[idx + 1]
    args <- args[-c(idx, idx + 1)]
  }

  team_filter <- NULL
  if ("--team" %in% args) {
    idx <- which(args == "--team")
    team_filter <- args[idx + 1]
    args <- args[-c(idx, idx + 1)]
  }

  if (length(args) >= 1) {
    latest_year <- as.integer(args[1])
  } else if (month(now()) < 9) {
    latest_year <- year(now()) - 1
  } else {
    latest_year <- year(now())
  }

  version <- tryCatch(read_version(), error = function(e) "dev")
  vlog("Season: {latest_year} (v{version})\n")

  dir.create("data", showWarnings = FALSE)
  dir.create(glue("data/{latest_year}"), showWarnings = FALSE)

  logos <- load_logos()
  pbp_data <- load_data_and_build(latest_year, latest_year)

  game_ids <- unique(pbp_data$game_id)
  if (!is.null(game_filter)) {
    game_ids <- game_ids[game_ids %in% game_filter]
  }
  if (!is.null(week_filter) && nchar(week_filter) > 0) {
    week_games <- pbp_data |> filter(week == as.integer(week_filter)) |> pull(game_id) |> unique()
    game_ids <- game_ids[game_ids %in% week_games]
  }
  if (!is.null(team_filter) && nchar(team_filter) > 0) {
    team_games <- pbp_data |> filter(home_team == team_filter | away_team == team_filter) |> pull(game_id) |> unique()
    game_ids <- game_ids[game_ids %in% team_games]
  }

  for (single_game_id in game_ids) {
    game_title_pieces <- strsplit(single_game_id, "_")[[1]]
    game_year <- game_title_pieces[1]
    game_week <- as.integer(game_title_pieces[2])

    output_path <- glue("data/{game_year}/wp-{single_game_id}-v{version}.png")
    rb_path <- glue("charts/rb-workload-w{game_week}-{single_game_id}-v{version}.png")
    wrte_path <- glue("charts/wrte-targets-w{game_week}-{single_game_id}-v{version}.png")

    if (!force && file.exists(output_path) && file.exists(rb_path) && file.exists(wrte_path)) {
      vlog("  Skipping {single_game_id}, charts already exist\n")
      next
    }

    tryCatch({
      vlog("Processing {single_game_id}...\n")
      game_data <- filter(pbp_data, game_id == single_game_id)
      vlog("  {nrow(game_data)} rows of data\n")

      if (force || !file.exists(output_path)) {
        plot <- plot_win_probability(game_data, logos)
        ggsave(output_path, plot = plot, width = 6, height = 4)
        vlog("  Saved {basename(output_path)}\n")
      }

      dir.create("charts", showWarnings = FALSE)
      if (force || !file.exists(rb_path)) {
        raw_pbp <- load_data(as.integer(game_year), as.integer(game_year))
        rb_plot <- plot_rb_workload(raw_pbp, game_week, as.integer(game_year), game_id = single_game_id)
        ggsave(rb_path, rb_plot, width = 10, height = 6, dpi = 150)
        vlog("  Saved {basename(rb_path)}\n")
      }

      if (force || !file.exists(wrte_path)) {
        raw_pbp <- load_data(as.integer(game_year), as.integer(game_year))
        wrte_plot <- plot_wrte_targets(raw_pbp, game_week, as.integer(game_year), game_id = single_game_id)
        ggsave(wrte_path, wrte_plot, width = 10, height = 6, dpi = 150)
        vlog("  Saved {basename(wrte_path)}\n")
      }
    }, error = function(e) {
      cat("  ERROR for {single_game_id}: {e$message}\n")
    })
  }
}

if (!interactive() && !exists("TESTING")) {
  VERBOSE <<- FALSE
  main()
}
