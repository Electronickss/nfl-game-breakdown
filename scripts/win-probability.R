if (!interactive()) {
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

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
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
  dir.create("data/{latest_year}", showWarnings = FALSE)

  logos <- load_logos()
  pbp_data <- load_data_and_build(latest_year, latest_year)

  game_ids <- unique(pbp_data$game_id)
  if (!is.null(game_filter)) {
    game_ids <- game_ids[game_ids %in% game_filter]
  }

  for (single_game_id in game_ids) {
    game_title_pieces <- strsplit(single_game_id, "_")[[1]]
    game_year <- game_title_pieces[1]

    output_path <- glue("data/{game_year}/wp-{single_game_id}-v{version}.png")
    if (!force && file.exists(output_path)) {
      vlog("  Skipping {single_game_id}, already exists\n")
      next
    }

    tryCatch({
      vlog("Processing {single_game_id}...\n")
      game_data <- filter(pbp_data, game_id == single_game_id)
      vlog("  {nrow(game_data)} rows of data\n")

      plot <- plot_win_probability(game_data, logos)

      ggsave(output_path, plot = plot, width = 6, height = 4)
      vlog("  Saved {basename(output_path)}\n")
    }, error = function(e) {
      cat("  ERROR for {single_game_id}: {e$message}\n")
    })
  }
}

if (!interactive() && !exists("TESTING")) {
  VERBOSE <<- FALSE
  main()
}
