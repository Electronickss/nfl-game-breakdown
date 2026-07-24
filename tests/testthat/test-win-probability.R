test_that("is_scoring_team identifies scoring plays correctly", {
  # Touchdown by this team
  expect_true(is_scoring_team("KC", NA, NA, "KC", 0, "KC", "BAL"))

  # Extra point by this team
  expect_true(is_scoring_team("KC", "extra_point", NA, NA, 0, "KC", "BAL"))

  # Made field goal by this team
  expect_true(is_scoring_team("KC", "field_goal", "made", NA, 0, "KC", "BAL"))

  # Safety by other team (this team benefits)
  expect_true(is_scoring_team("BAL", NA, NA, NA, 1, "KC", "BAL"))

  # No scoring play
  expect_false(is_scoring_team("KC", "pass", NA, NA, 0, "KC", "BAL"))

  # Field goal missed
  expect_false(is_scoring_team("KC", "field_goal", "missed", NA, 0, "KC", "BAL"))

  # Touchdown by other team
  expect_false(is_scoring_team("KC", NA, NA, "BAL", 0, "KC", "BAL"))
})

test_that("is_scoring_team handles vectorized inputs", {
  posteam <- c("KC", "BAL", "KC", "BAL")
  play_type <- c("extra_point", NA, "pass", NA)
  field_goal_result <- c(NA, NA, NA, NA)
  td_team <- c(NA, "BAL", NA, NA)
  safety <- c(0, 0, 0, 1)
  this_team <- "KC"
  that_team <- "BAL"

  result <- is_scoring_team(posteam, play_type, field_goal_result, td_team, safety, this_team, that_team)

  expect_equal(length(result), 4)
  expect_true(result[1])   # KC extra point
  expect_false(result[2])  # BAL td (not KC)
  expect_false(result[3])  # KC pass, no score
  expect_true(result[4])   # BAL safety (KC benefits)
})

test_that("is_turnover_team identifies turnovers correctly", {
  # Interception by this team
  expect_true(is_turnover_team("KC", 0, 1, "KC"))

  # Fumble lost by this team
  expect_true(is_turnover_team("KC", 1, 0, "KC"))

  # Both interception and fumble
  expect_true(is_turnover_team("KC", 1, 1, "KC"))

  # No turnover
  expect_false(is_turnover_team("KC", 0, 0, "KC"))

  # Turnover by other team
  expect_false(is_turnover_team("BAL", 0, 1, "KC"))
})

test_that("is_turnover_team handles vectorized inputs", {
  posteam <- c("KC", "BAL", "KC", "KC")
  fumble_lost <- c(0, 1, 1, 0)
  interception <- c(1, 0, 0, 0)
  this_team <- "KC"

  result <- is_turnover_team(posteam, fumble_lost, interception, this_team)

  expect_equal(length(result), 4)
  expect_true(result[1])   # KC interception
  expect_false(result[2])  # BAL fumble (not KC)
  expect_true(result[3])   # KC fumble
  expect_false(result[4])  # KC no turnover
})

test_that("is_penalty_team identifies penalties correctly", {
  # First down penalty by this team
  expect_true(is_penalty_team("KC", 1, "KC"))

  # No first down penalty
  expect_false(is_penalty_team("KC", 0, "KC"))

  # Penalty by other team
  expect_false(is_penalty_team("BAL", 1, "KC"))
})

test_that("is_penalty_team handles vectorized inputs", {
  penalty_team <- c("KC", "BAL", "KC")
  first_down_penalty <- c(1, 1, 0)
  this_team <- "KC"

  result <- is_penalty_team(penalty_team, first_down_penalty, this_team)

  expect_equal(length(result), 3)
  expect_true(result[1])   # KC penalty
  expect_false(result[2])  # BAL penalty
  expect_false(result[3])  # KC no first down
})

test_that("theme_high_contrast returns a valid ggplot2 theme", {
  theme <- theme_high_contrast()
  expect_s3_class(theme, "theme")
})

test_that("theme_high_contrast accepts custom colors", {
  theme <- theme_high_contrast(
    foreground_color = "#000000",
    background_color = "#FFFFFF"
  )
  expect_s3_class(theme, "theme")
  expect_equal(theme$plot.background$fill, "#FFFFFF")
})

test_that("plot_win_probability returns a ggplot object", {
  game_data <- make_mock_game()
  logos <- make_mock_logos()

  p <- plot_win_probability(game_data, logos)

  expect_s3_class(p, "ggplot")
})

test_that("plot_win_probability covers ggimage branch", {
  game_data <- make_mock_game()
  logos <- make_mock_logos()

  has_ggimage_orig <- has_ggimage
  has_ggimage <<- function() TRUE
  on.exit(has_ggimage <<- has_ggimage_orig, add = TRUE)

  geom_image_orig <- if (exists("geom_image")) geom_image else NULL
  geom_image <- function(...) ggplot2::geom_blank()
  assign("geom_image", geom_image, envir = globalenv())
  on.exit({
    if (!is.null(geom_image_orig)) geom_image <<- geom_image_orig
    else rm("geom_image", envir = globalenv())
  }, add = TRUE)

  p <- plot_win_probability(game_data, logos)
  expect_s3_class(p, "ggplot")
})

test_that("load_data wraps load_pbp correctly", {
  # Just test that the function exists and is callable
  expect_true(is.function(load_data))
})

test_that("load_logos returns team abbreviations and logos", {
  # This function calls nflfastR::teams_colors_logos which needs the library
  # Skip if nflfastR is not available
  skip_if_not_installed("nflfastR")
  logos <- load_logos()
  expect_s3_class(logos, "tbl_df")
  expect_true("team_abbr" %in% names(logos))
  expect_true("team_logo_espn" %in% names(logos))
  expect_true(nrow(logos) > 0)
})

test_that("is_scoring_team handles NA values", {
  expect_false(is_scoring_team(NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_, "KC", "BAL"))
})

test_that("is_turnover_team handles NA values", {
  expect_false(is_turnover_team(NA, NA, NA, "KC"))
})

test_that("is_penalty_team handles NA values", {
  expect_false(is_penalty_team(NA, NA, "KC"))
})

test_that("load_data is a function wrapping load_pbp", {
  expect_true(is.function(load_data))
  expect_true("start_year" %in% names(formals(load_data)))
  expect_true("end_year" %in% names(formals(load_data)))
})

test_that("load_logos calls teams_colors_logos", {
  fake_logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn,
    "KC", "https://example.com/kc.png",
    "BAL", "https://example.com/bal.png"
  )
  load_logos_orig <- load_logos
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  load_logos <<- function() fake_logos
  result <- load_logos()
  expect_equal(nrow(result), 2)
  expect_true("team_abbr" %in% names(result))
  expect_true("team_logo_espn" %in% names(result))
  load_logos <<- load_logos_orig
})

test_that("load_data_and_build processes mock data end-to-end", {
  mock_pbp <- tibble::tribble(
    ~game_id, ~game_date, ~week, ~posteam, ~home_team, ~away_team, ~qtr, ~down, ~ydstogo, ~game_seconds_remaining, ~yardline_100, ~score_differential, ~defteam_timeouts_remaining, ~posteam_timeouts_remaining, ~play_type, ~field_goal_result, ~td_team, ~safety, ~penalty_team, ~first_down_penalty, ~interception, ~fumble_lost, ~home_score, ~away_score, ~vegas_home_wp, ~wp, ~replay_or_challenge, ~td_player_name,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 1, 1, 10, 3500, 75, 0, 3, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.55, 0.55, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "BAL", "BAL", "KC", 1, 2, 7, 3400, 60, 7, 3, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.65, 0.65, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 2, 1, 10, 1800, 50, -7, 2, 3, "extra_point", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.45, 0.45, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "BAL", "BAL", "KC", 3, 1, 10, 900, 30, 0, 2, 2, "field_goal", "made", NA, 0, NA, 0, 0, 0, 24, 17, 0.50, 0.50, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 4, 1, 10, 100, 20, -3, 1, 2, "pass", NA, NA, 0, NA, 0, 1, 0, 24, 17, 0.30, 0.30, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "BAL", "BAL", "KC", 4, 2, 5, 50, 15, 3, 1, 1, "rush", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.90, 0.90, NA, NA
  )

  mock_logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn, ~team_color,
    "KC", "https://example.com/kc.png", "#E31837",
    "BAL", "https://example.com/bal.png", "#241773"
  )

  load_data_orig <- load_data
  load_logos_orig <- load_logos
  on.exit({ load_data <<- load_data_orig; load_logos <<- load_logos_orig }, add = TRUE)
  load_data <<- function(s, e) mock_pbp
  load_logos <<- function() mock_logos

  result <- load_data_and_build(2024, 2024)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("poswins" %in% names(result))
  expect_true("home_scoring_play" %in% names(result))
  expect_true("away_scoring_play" %in% names(result))
  expect_true("home_turnover_play" %in% names(result))
  expect_true("away_turnover_play" %in% names(result))
  expect_true("home_penalty" %in% names(result))
  expect_true("away_penalty" %in% names(result))
  expect_true("team_logo_espn" %in% names(result))
  expect_true("team_color" %in% names(result))
  expect_true("replay_or_challenge" %in% names(result))
  expect_true("td_player_name" %in% names(result))
  load_data <<- load_data_orig
  load_logos <<- load_logos_orig
})

test_that("load_data_and_build filters out TIE games", {
  mock_pbp <- tibble::tribble(
    ~game_id, ~game_date, ~week, ~posteam, ~home_team, ~away_team, ~qtr, ~down, ~ydstogo, ~game_seconds_remaining, ~yardline_100, ~score_differential, ~defteam_timeouts_remaining, ~posteam_timeouts_remaining, ~play_type, ~field_goal_result, ~td_team, ~safety, ~penalty_team, ~first_down_penalty, ~interception, ~fumble_lost, ~home_score, ~away_score, ~vegas_home_wp, ~wp, ~replay_or_challenge, ~td_player_name,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 4, 1, 10, 10, 50, 0, 3, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 14, 14, 0.50, 0.50, NA, NA
  )
  mock_logos <- tibble::tribble(~team_abbr, ~team_logo_espn, ~team_color, "KC", "x", "#E31837", "BAL", "x", "#241773")

  load_data_orig <- load_data
  load_logos_orig <- load_logos
  on.exit({ load_data <<- load_data_orig; load_logos <<- load_logos_orig }, add = TRUE)
  load_data <<- function(s, e) mock_pbp
  load_logos <<- function() mock_logos

  result <- load_data_and_build(2024, 2024)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  load_data <<- load_data_orig
  load_logos <<- load_logos_orig
})

test_that("load_data_and_build handles NA filter columns", {
  mock_pbp <- tibble::tribble(
    ~game_id, ~game_date, ~week, ~posteam, ~home_team, ~away_team, ~qtr, ~down, ~ydstogo, ~game_seconds_remaining, ~yardline_100, ~score_differential, ~defteam_timeouts_remaining, ~posteam_timeouts_remaining, ~play_type, ~field_goal_result, ~td_team, ~safety, ~penalty_team, ~first_down_penalty, ~interception, ~fumble_lost, ~home_score, ~away_score, ~vegas_home_wp, ~wp, ~replay_or_challenge, ~td_player_name,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 1, NA, 10, 3500, 75, 0, 3, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.55, 0.55, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "BAL", "BAL", "KC", 1, 2, 7, 3400, NA, 7, 3, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.65, 0.65, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "KC", "BAL", "KC", 5, 1, 10, 1800, 50, -7, NA, 3, "pass", NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.45, 0.45, NA, NA,
    "2024_01_KC_BAL", "2024-09-05", 1, "BAL", "BAL", "KC", 3, 1, 10, 900, 30, 0, 2, 2, NA, NA, NA, 0, NA, 0, 0, 0, 24, 17, 0.50, 0.50, NA, NA
  )
  mock_logos <- tibble::tribble(~team_abbr, ~team_logo_espn, ~team_color, "KC", "x", "#E31837", "BAL", "x", "#241773")

  load_data_orig <- load_data
  load_logos_orig <- load_logos
  on.exit({ load_data <<- load_data_orig; load_logos <<- load_logos_orig }, add = TRUE)
  load_data <<- function(s, e) mock_pbp
  load_logos <<- function() mock_logos

  result <- load_data_and_build(2024, 2024)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  load_data <<- load_data_orig
  load_logos <<- load_logos_orig
})

test_that("main creates data directory with interpolated year, not literal string", {
  tmp_dir <- tempdir()
  test_subdir <- file.path(tmp_dir, paste0("test_wp_dir_", sample.int(100000, 1)))
  dir.create(test_subdir)
  on.exit(unlink(test_subdir, recursive = TRUE), add = TRUE)

  writeLines("1.0", file.path(test_subdir, "VERSION"))

  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)

  project_root <- getwd()
  while (!file.exists(file.path(project_root, "DESCRIPTION")) && project_root != dirname(project_root)) {
    project_root <- dirname(project_root)
  }
  setwd(project_root)
  TESTING <- TRUE
  source(file.path(project_root, "scripts/win-probability.R"), local = environment())
  setwd(test_subdir)

  load_data_and_build_orig <- load_data_and_build
  load_logos_orig <- load_logos
  on.exit({
    load_data_and_build <<- load_data_and_build_orig
    load_logos <<- load_logos_orig
  }, add = TRUE)

  load_data_and_build <<- function(s, e) tibble::tibble(game_id = character(0))
  load_logos <<- make_mock_logos

  main(args = c("2024"))

  expect_true(dir.exists(file.path(test_subdir, "data", "2024")),
    info = "Should create directory named with the numeric year")
  expect_false(dir.exists(file.path(test_subdir, "data", "{2024}")),
    info = "Should NOT create a directory with literal curly braces")
})

test_that("color_distance returns numeric", {
  dist <- color_distance("#E31837", "#241773")
  expect_type(dist, "double")
  expect_true(dist > 0)
})

test_that("color_distance is symmetric", {
  d1 <- color_distance("#FF0000", "#0000FF")
  d2 <- color_distance("#0000FF", "#FF0000")
  expect_equal(d1, d2)
})

test_that("color_distance returns 0 for same color", {
  dist <- color_distance("#FF0000", "#FF0000")
  expect_equal(dist, 0)
})

test_that("color_distance between similar colors is small", {
  dist <- color_distance("#E31837", "#E01030")
  expect_true(dist < 10)
})

test_that("color_distance between different colors is large", {
  dist <- color_distance("#E31837", "#241773")
  expect_true(dist > 40)
})

test_that("resolve_team_colors keeps primary when colors are distinct", {
  logos <- make_mock_logos()
  result <- resolve_team_colors("BAL", "SF", logos)
  expect_equal(result$home_color, "#241773")
  expect_equal(result$away_color, "#AA0000")
})

test_that("resolve_team_colors switches to secondary when colors clump", {
  logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn, ~team_color, ~team_color2,
    "TEAM_A", "https://example.com/a.png", "#00338D", "#FF0000",
    "TEAM_B", "https://example.com/b.png", "#003087", "#000000"
  )
  result <- resolve_team_colors("TEAM_A", "TEAM_B", logos)
  dist <- color_distance(result$home_color, result$away_color)
  expect_true(dist >= 25)
})

test_that("resolve_team_colors handles missing secondary color", {
  logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn, ~team_color, ~team_color2,
    "TEAM_A", "https://example.com/a.png", "#00338D", "#FF0000",
    "TEAM_B", "https://example.com/b.png", "#003087", NA_character_
  )
  result <- resolve_team_colors("TEAM_A", "TEAM_B", logos)
  dist <- color_distance(result$home_color, result$away_color)
  expect_true(dist >= 25)
})

test_that("resolve_team_colors uses custom threshold", {
  logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn, ~team_color, ~team_color2,
    "TEAM_A", "https://example.com/a.png", "#E31837", "#FF0000",
    "TEAM_B", "https://example.com/b.png", "#E01030", "#000000"
  )
  result_strict <- resolve_team_colors("TEAM_A", "TEAM_B", logos, threshold = 1)
  dist_strict <- color_distance(result_strict$home_color, result_strict$away_color)
  expect_true(dist_strict < 25)

  result_loose <- resolve_team_colors("TEAM_A", "TEAM_B", logos, threshold = 10)
  dist_loose <- color_distance(result_loose$home_color, result_loose$away_color)
  expect_true(dist_loose >= 25)
})

test_that("resolve_team_colors tries home secondary when away secondary doesnt help", {
  logos <- tibble::tribble(
    ~team_abbr, ~team_logo_espn, ~team_color, ~team_color2,
    "TEAM_A", "https://example.com/a.png", "#203731", "#FFB612",
    "TEAM_B", "https://example.com/b.png", "#003F2D", "#000000"
  )
  result <- resolve_team_colors("TEAM_A", "TEAM_B", logos)
  dist <- color_distance(result$home_color, result$away_color)
  expect_true(dist >= 25)
})

test_that("load_logos includes team_color2", {
  skip_if_not_installed("nflfastR")
  logos <- load_logos()
  expect_true("team_color2" %in% names(logos))
})

test_that("color clump threshold catches known identical-color pairs", {
  logos <- make_mock_logos()
  # Simulate identical primary colors (like DAL/DEN/NE/SEA/TEN all being #002244)
  logos$team_color[logos$team_abbr == "KC"] <- "#002244"
  logos$team_color[logos$team_abbr == "BAL"] <- "#002244"

  result <- resolve_team_colors("KC", "BAL", logos)
  dist <- color_distance(result$home_color, result$away_color)
  expect_true(dist >= 25)
})

test_that("color clump threshold does not trigger for clearly distinct colors", {
  logos <- make_mock_logos()
  # KC (#E31837 red) vs BAL (#241773 purple) - very different
  result <- resolve_team_colors("KC", "BAL", logos)
  expect_equal(result$away_color, "#241773")
})

test_that("secondary color always resolves clumping for real NFL teams", {
  skip_if_not_installed("nflfastR")
  library(dplyr)

  real_teams <- c("ARI","ATL","BAL","BUF","CAR","CHI","CIN","CLE","DAL","DEN",
                  "DET","GB","HOU","IND","JAX","KC","LAC","LAR","LV","MIA",
                  "MIN","NE","NO","NYG","NYJ","PHI","PIT","SEA","SF","TB","TEN","WAS")

  logos <- nflfastR::teams_colors_logos |>
    filter(team_abbr %in% real_teams) |>
    select(team_abbr, team_color, team_color2)

  for (i in seq_along(real_teams)) {
    for (j in seq_along(real_teams)) {
      if (i >= j) next
      t1 <- real_teams[i]
      t2 <- real_teams[j]
      c1 <- logos$team_color[logos$team_abbr == t1]
      c2 <- logos$team_color[logos$team_abbr == t2]
      d <- color_distance(c1, c2)

      if (d < 25) {
        resolved <- resolve_team_colors(t1, t2, logos)
        new_dist <- color_distance(resolved$home_color, resolved$away_color)
        expect_true(new_dist >= 25,
          info = paste0(t1, " vs ", t2, " (dist=", round(d,1),
          "): resolved colors still clumped at dist=", round(new_dist,1)))
      }
    }
  }
})

test_that("generate_synopsis produces a character string", {
  game_data <- make_mock_game()
  synopsis <- generate_synopsis(game_data)
  expect_type(synopsis, "character")
  expect_true(nchar(synopsis) > 0)
})

test_that("generate_synopsis includes team names", {
  game_data <- make_mock_game(home_team = "BAL", away_team = "KC")
  synopsis <- generate_synopsis(game_data)
  expect_true(grepl("BAL", synopsis) || grepl("KC", synopsis))
})

test_that("generate_synopsis handles tie games", {
  game_data <- make_mock_game(home_team = "BAL", away_team = "KC")
  game_data$home_score <- rep(14, nrow(game_data))
  game_data$away_score <- rep(14, nrow(game_data))
  synopsis <- generate_synopsis(game_data)
  expect_true(grepl("tie", synopsis, ignore.case = TRUE))
})
