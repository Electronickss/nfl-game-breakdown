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

  if (length(args) >= 1) {
    latest_year <- as.integer(args[1])
  } else if (month(now()) < 9) {
    latest_year <- year(now()) - 1
  } else {
    latest_year <- year(now())
  }

  vlog("Season: {latest_year}\n")

  dir.create("data", showWarnings = FALSE)
  dir.create("data/{latest_year}", showWarnings = FALSE)

  logos <- load_logos()
  pbp_data <- load_data_and_build(latest_year, latest_year)

  game_ids <- unique(pbp_data$game_id)

  for (single_game_id in game_ids) {
    game_title_pieces <- strsplit(single_game_id, "_")[[1]]
    game_year <- game_title_pieces[1]

    tryCatch({
      vlog("Processing {single_game_id}...\n")
      game_data <- filter(pbp_data, game_id == single_game_id)
      vlog("  {nrow(game_data)} rows of data\n")

      plot <- plot_win_probability(game_data, logos)

      ggsave(
        "data/{game_year}/wp-{single_game_id}.png",
        plot = plot,
        width = 6,
        height = 4
      )
      vlog("  Saved wp-{single_game_id}.png\n")
    }, error = function(e) {
      cat("  ERROR for {single_game_id}: {e$message}\n")
    })
  }
}

if (!interactive() && !exists("TESTING")) {
  VERBOSE <<- FALSE
  main()
}
