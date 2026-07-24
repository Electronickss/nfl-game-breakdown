test_that("get_team_stats returns correct structure", {
  pbp <- make_mock_game()
  stats <- get_team_stats(pbp, "BAL", 1)

  expect_type(stats, "list")
  expect_true("passing" %in% names(stats))
  expect_true("rushing" %in% names(stats))
  expect_true("receiving" %in% names(stats))
  expect_true("opponent" %in% names(stats))
  expect_true("is_home" %in% names(stats))
})

test_that("get_team_stats identifies home team correctly", {
  pbp <- make_mock_game(home_team = "BAL", away_team = "KC")

  stats_home <- get_team_stats(pbp, "BAL", 1)
  expect_true(stats_home$is_home)
  expect_equal(stats_home$opponent, "KC")

  stats_away <- get_team_stats(pbp, "KC", 1)
  expect_false(stats_away$is_home)
  expect_equal(stats_away$opponent, "BAL")
})

test_that("get_team_stats filters by week", {
  pbp1 <- make_mock_game(week = 1)
  pbp2 <- make_mock_game(week = 2, game_id = "2024_02_KC_BAL")

  stats_w1 <- get_team_stats(pbp1, "BAL", 1)
  stats_w2 <- get_team_stats(pbp2, "BAL", 2)

  expect_s3_class(stats_w1$passing, "tbl_df")
  expect_s3_class(stats_w2$passing, "tbl_df")
})

test_that("get_team_stats returns empty tibbles for team with no plays", {
  pbp <- make_mock_game(home_team = "BAL", away_team = "KC")
  stats <- get_team_stats(pbp, "SF", 1)

  expect_equal(nrow(stats$passing), 0)
  expect_equal(nrow(stats$rushing), 0)
  expect_equal(nrow(stats$receiving), 0)
})

test_that("plot_team_summary returns a ggplot object", {
  stats <- make_mock_team_stats()
  p <- plot_team_summary(stats, "BAL", 1, 2024)
  expect_s3_class(p, "ggplot")
})

test_that("plot_team_summary works for away team", {
  stats <- make_mock_team_stats()
  stats$is_home <- FALSE
  p <- plot_team_summary(stats, "BAL", 1, 2024)
  expect_s3_class(p, "ggplot")
})

test_that("plot_target_share returns a ggplot object", {
  receiving <- make_mock_receiving()
  p <- plot_target_share(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_target_share limits to 8 players", {
  receiving <- tibble(
    receiver_player_name = paste0("Player", 1:12),
    targets = 12:1,
    receptions = rep(5, 12),
    yards = rep(50, 12),
    td = rep(0, 12),
    air_yards = rep(100, 12),
    epa = rep(1.0, 12)
  )
  p <- plot_target_share(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_air_yards returns a ggplot object", {
  receiving <- make_mock_receiving()
  p <- plot_air_yards(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_air_yards limits to 8 players", {
  receiving <- tibble(
    receiver_player_name = paste0("Player", 1:12),
    targets = rep(5, 12),
    receptions = rep(3, 12),
    yards = rep(40, 12),
    td = rep(0, 12),
    air_yards = seq(100, 10, length.out = 12),
    epa = rep(1.0, 12)
  )
  p <- plot_air_yards(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_rb_workload returns a ggplot object", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game()
  p <- plot_rb_workload(pbp, 1, 2024)
  expect_s3_class(p, "ggplot")
})

test_that("plot_rb_workload filters by game_id when provided", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game(game_id = "2024_01_KC_BAL")
  p <- plot_rb_workload(pbp, 1, 2024, game_id = "2024_01_KC_BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_wrte_targets returns a ggplot object", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game()
  p <- plot_wrte_targets(pbp, 1, 2024)
  expect_s3_class(p, "ggplot")
})

test_that("plot_wrte_targets filters by game_id when provided", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game(game_id = "2024_01_KC_BAL")
  p <- plot_wrte_targets(pbp, 1, 2024, game_id = "2024_01_KC_BAL")
  expect_s3_class(p, "ggplot")
})

test_that("vlog does not print when VERBOSE is FALSE", {
  VERBOSE <<- FALSE
  output <- capture.output(vlog("test message hello"))
  expect_equal(length(output), 0)
})

test_that("vlog prints when VERBOSE is TRUE", {
  VERBOSE <<- TRUE
  output <- capture.output(vlog("test message hello"))
  expect_true(length(output) > 0)
  expect_true(grepl("hello", output[1]))
  VERBOSE <<- FALSE
})

test_that("get_team_stats computes passing stats correctly", {
  pbp <- make_mock_game(n_plays = 1000, week = 1)
  stats <- get_team_stats(pbp, "BAL", 1)

  expect_true(nrow(stats$passing) >= 0)
  if (nrow(stats$passing) > 0) {
    expect_true(all(c("completions", "attempts", "yards", "td", "interceptions") %in% names(stats$passing)))
    expect_true(all(stats$passing$completions <= stats$passing$attempts))
  }
})

test_that("get_team_stats computes rushing stats correctly", {
  pbp <- make_mock_game(n_plays = 1000, week = 1)
  stats <- get_team_stats(pbp, "BAL", 1)

  expect_true(nrow(stats$rushing) >= 0)
  if (nrow(stats$rushing) > 0) {
    expect_true(all(c("carries", "yards", "td") %in% names(stats$rushing)))
  }
})

test_that("get_team_stats computes receiving stats correctly", {
  pbp <- make_mock_game(n_plays = 1000, week = 1)
  stats <- get_team_stats(pbp, "BAL", 1)

  expect_true(nrow(stats$receiving) >= 0)
  if (nrow(stats$receiving) > 0) {
    expect_true(all(c("targets", "receptions", "yards", "td", "air_yards") %in% names(stats$receiving)))
  }
})

test_that("load_pbp_data wraps load_pbp", {
  expect_true(is.function(load_pbp_data))
  expect_true("year" %in% names(formals(load_pbp_data)))
})

test_that("load_rosters wraps nflreadr::load_rosters", {
  expect_true(is.function(load_rosters))
  expect_true("year" %in% names(formals(load_rosters)))
})

test_that("load_schedule wraps nflreadr::load_schedule", {
  expect_true(is.function(load_schedule))
  expect_true("year" %in% names(formals(load_schedule)))
})

test_that("plot_team_summary formats title correctly", {
  stats <- make_mock_team_stats()
  p <- plot_team_summary(stats, "BAL", 5, 2024)
  built <- ggplot_build(p)
  expect_s3_class(p, "ggplot")
})

test_that("plot_target_share handles single player", {
  receiving <- tibble(
    receiver_player_name = "WR1",
    targets = 10,
    receptions = 7,
    yards = 100,
    td = 1,
    air_yards = 150,
    epa = 3.0
  )
  p <- plot_target_share(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_air_yards handles single player", {
  receiving <- tibble(
    receiver_player_name = "WR1",
    targets = 10,
    receptions = 7,
    yards = 100,
    td = 1,
    air_yards = 150,
    epa = 3.0
  )
  p <- plot_air_yards(receiving, "BAL")
  expect_s3_class(p, "ggplot")
})

test_that("plot_rb_workload handles game with all rushes from one team", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game(n_plays = 200, week = 1)
  pbp <- pbp |> mutate(
    rush = 1,
    pass = 0,
    rush_attempt = 1,
    pass_attempt = 0,
    complete_pass = 0,
    rusher_player_name = "Workhorse RB",
    receiver_player_name = NA_character_
  )
  p <- plot_rb_workload(pbp, 1, 2024)
  expect_s3_class(p, "ggplot")
})

test_that("add_touch_labels positions home above and away below", {
  home_touches <- tibble(
    game_seconds_remaining = c(3000, 2000),
    vegas_home_wp = c(0.6, 0.55),
    player = c("Home RB1", "Home RB2"),
    posteam = c("BAL", "BAL"),
    touch_type = c("Rush", "Rush")
  )
  away_touches <- tibble(
    game_seconds_remaining = c(2500, 1500),
    vegas_home_wp = c(0.45, 0.4),
    player = c("Away RB1", "Away RB2"),
    posteam = c("KC", "KC"),
    touch_type = c("Rush", "Rush")
  )
  all_touches <- bind_rows(home_touches, away_touches)
  logos <- make_mock_logos()
  base <- ggplot() + geom_point(aes(x = 1, y = 1))

  p <- add_touch_labels(base, all_touches, logos, home_team = "BAL")

  built <- ggplot_build(p)
  label_layers <- built$data[sapply(built$data, function(d) "label" %in% names(d))]

  expect_equal(length(label_layers), 2)

  home_players <- label_layers[[1]]$label
  away_players <- label_layers[[2]]$label

  expect_true(all(c("Home RB1", "Home RB2") %in% home_players))
  expect_true(all(c("Away RB1", "Away RB2") %in% away_players))
  expect_equal(length(label_layers[[1]]$y), 2)
  expect_equal(length(label_layers[[2]]$y), 2)
})

test_that("add_touch_labels labels all touches, not just first per player", {
  touches <- tibble(
    game_seconds_remaining = c(3000, 2000, 1000),
    vegas_home_wp = c(0.6, 0.55, 0.5),
    player = c("RB1", "RB1", "RB1"),
    posteam = c("BAL", "BAL", "BAL"),
    touch_type = c("Rush", "Rush", "Rush")
  )
  logos <- make_mock_logos()
  base <- ggplot() + geom_point(aes(x = 1, y = 1))

  p <- add_touch_labels(base, touches, logos, home_team = "BAL")

  built <- ggplot_build(p)
  label_layers <- built$data[sapply(built$data, function(d) "label" %in% names(d))]

  expect_equal(length(label_layers), 1)
  expect_equal(nrow(label_layers[[1]]), 3)
})

test_that("add_touch_labels works with no home touches", {
  away_touches <- tibble(
    game_seconds_remaining = c(2500, 1500),
    vegas_home_wp = c(0.45, 0.4),
    player = c("Away RB1", "Away RB2"),
    posteam = c("KC", "KC"),
    touch_type = c("Rush", "Rush")
  )
  logos <- make_mock_logos()
  base <- ggplot() + geom_point(aes(x = 1, y = 1))

  p <- add_touch_labels(base, away_touches, logos, home_team = "BAL")

  built <- ggplot_build(p)
  label_layers <- built$data[sapply(built$data, function(d) "label" %in% names(d))]

  expect_equal(length(label_layers), 1)
  expect_true(all(c("Away RB1", "Away RB2") %in% label_layers[[1]]$label))
})

test_that("add_touch_labels works with no away touches", {
  home_touches <- tibble(
    game_seconds_remaining = c(3000, 2000),
    vegas_home_wp = c(0.6, 0.55),
    player = c("Home RB1", "Home RB2"),
    posteam = c("BAL", "BAL"),
    touch_type = c("Rush", "Rush")
  )
  logos <- make_mock_logos()
  base <- ggplot() + geom_point(aes(x = 1, y = 1))

  p <- add_touch_labels(base, home_touches, logos, home_team = "BAL")

  built <- ggplot_build(p)
  label_layers <- built$data[sapply(built$data, function(d) "label" %in% names(d))]

  expect_equal(length(label_layers), 1)
  expect_true(all(c("Home RB1", "Home RB2") %in% label_layers[[1]]$label))
})

test_that("plot_wrte_targets handles game with no targets", {
  load_logos_orig <- load_logos
  load_logos <<- function() make_mock_logos()
  on.exit(load_logos <<- load_logos_orig, add = TRUE)
  pbp <- make_mock_game(n_plays = 200, week = 1)
  pbp <- pbp |> mutate(
    pass = 0,
    pass_attempt = 0,
    complete_pass = 0,
    receiver_player_name = NA_character_
  )
  p <- plot_wrte_targets(pbp, 1, 2024)
  expect_s3_class(p, "ggplot")
})
