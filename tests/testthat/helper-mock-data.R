library(tibble)

make_mock_game <- function(
    game_id = "2024_01_KC_BAL",
    home_team = "BAL",
    away_team = "KC",
    n_plays = 100,
    week = 1
) {
  tibble(
    game_id = game_id,
    game_date = "2024-09-05",
    posteam = sample(c(home_team, away_team), n_plays, replace = TRUE),
    home_team = home_team,
    away_team = away_team,
    winner = home_team,
    qtr = rep(1:4, length.out = n_plays),
    down = sample(1:4, n_plays, replace = TRUE),
    ydstogo = sample(1:15, n_plays, replace = TRUE),
    game_seconds_remaining = seq(3600, 0, length.out = n_plays),
    yardline_100 = sample(1:100, n_plays, replace = TRUE),
    score_differential = sample(-14:14, n_plays, replace = TRUE),
    defteam_timeouts_remaining = rep(3, n_plays),
    posteam_timeouts_remaining = rep(3, n_plays),
    home_scoring_play = sample(0:1, n_plays, replace = TRUE, prob = c(0.95, 0.05)),
    away_scoring_play = sample(0:1, n_plays, replace = TRUE, prob = c(0.95, 0.05)),
    home_turnover_play = sample(0:1, n_plays, replace = TRUE, prob = c(0.97, 0.03)),
    away_turnover_play = sample(0:1, n_plays, replace = TRUE, prob = c(0.97, 0.03)),
    home_penalty = sample(0:1, n_plays, replace = TRUE, prob = c(0.9, 0.1)),
    away_penalty = sample(0:1, n_plays, replace = TRUE, prob = c(0.9, 0.1)),
    vegas_home_wp = runif(n_plays, 0.2, 0.8),
    field_goal_result = sample(c("made", "missed", NA), n_plays, replace = TRUE),
    wp = runif(n_plays, 0.2, 0.8),
    interception = sample(0:1, n_plays, replace = TRUE, prob = c(0.97, 0.03)),
    fumble_lost = sample(0:1, n_plays, replace = TRUE, prob = c(0.98, 0.02)),
    is_home_team = ifelse(posteam == home_team, 1, 0),
    home_score = rep(24, n_plays),
    away_score = rep(17, n_plays),
    team_logo_espn = rep("https://example.com/logo.png", n_plays),
    team_color = rep("#000000", n_plays),
    replay_or_challenge = sample(c("replay", "challenge", NA), n_plays, replace = TRUE, prob = c(0.05, 0.05, 0.9)),
    td_player_name = NA_character_,
    fumble = sample(0:1, n_plays, replace = TRUE, prob = c(0.98, 0.02)),
    fumbled_1_player_name = NA_character_,
    poswins = 1,
    pass = sample(0:1, n_plays, replace = TRUE),
    rush = ifelse(pass == 0, 1, 0),
    complete_pass = ifelse(pass == 1, sample(0:1, n_plays, replace = TRUE), 0),
    pass_attempt = ifelse(pass == 1, 1, 0),
    rush_attempt = ifelse(rush == 1, 1, 0),
    passer_player_name = ifelse(pass == 1, "Test QB", NA),
    rusher_player_name = ifelse(rush == 1, "Test RB", NA),
    receiver_player_name = ifelse(pass == 1, sample(c("WR1", "WR2", "TE1"), n_plays, replace = TRUE), NA),
    passing_yards = ifelse(pass == 1, sample(0:40, n_plays, replace = TRUE), 0),
    rushing_yards = ifelse(rush == 1, sample(0:20, n_plays, replace = TRUE), 0),
    pass_touchdown = ifelse(pass == 1, sample(0:1, n_plays, replace = TRUE, prob = c(0.95, 0.05)), 0),
    rush_touchdown = ifelse(rush == 1, sample(0:1, n_plays, replace = TRUE, prob = c(0.97, 0.03)), 0),
    sack = ifelse(pass == 1, sample(0:1, n_plays, replace = TRUE, prob = c(0.93, 0.07)), 0),
    epa = runif(n_plays, -2, 4),
    cpoe = ifelse(pass == 1, runif(n_plays, -10, 15), NA),
    receiving_yards = ifelse(pass == 1, sample(0:40, n_plays, replace = TRUE), 0),
    air_yards = ifelse(pass == 1, sample(-5:40, n_plays, replace = TRUE), 0),
    week = week,
    season = 2024
  )
}

make_mock_rosters <- function() {
  tribble(
    ~full_name, ~position, ~team,
    "Test RB", "RB", "BAL",
    "Test RB", "RB", "KC",
    "WR1", "WR", "BAL",
    "WR2", "WR", "BAL",
    "WR3", "WR", "KC",
    "TE1", "TE", "BAL",
    "Test QB", "QB", "BAL",
    "Test QB", "QB", "KC"
  )
}

make_mock_logos <- function() {
  tribble(
    ~team_abbr, ~team_logo_espn, ~team_color, ~team_color2,
    "KC", "https://example.com/kc.png", "#E31837", "#FFB81C",
    "BAL", "https://example.com/bal.png", "#241773", "#9E7C0C",
    "SF", "https://example.com/sf.png", "#AA0000", "#B3995D",
    "BUF", "https://example.com/buf.png", "#00338D", "#C60C30"
  )
}

make_mock_receiving <- function() {
  tribble(
    ~receiver_player_name, ~targets, ~receptions, ~yards, ~td, ~air_yards, ~epa,
    "WR1", 10, 7, 120, 2, 200, 5.0,
    "WR2", 8, 5, 80, 1, 150, 3.0,
    "TE1", 6, 4, 50, 0, 60, 1.0,
    "WR3", 3, 2, 30, 0, 40, 0.5
  )
}

make_mock_team_stats <- function() {
  list(
    passing = tribble(
      ~passer_player_name, ~completions, ~attempts, ~yards, ~td, ~interceptions, ~sacks, ~epa, ~cpoe,
      "QB1", 25, 35, 280, 3, 1, 2, 8.5, 5.2
    ),
    rushing = tribble(
      ~rusher_player_name, ~carries, ~yards, ~td, ~epa,
      "RB1", 18, 95, 1, 2.3,
      "RB2", 5, 25, 0, 0.5
    ),
    receiving = make_mock_receiving(),
    opponent = "KC",
    is_home = TRUE
  )
}
