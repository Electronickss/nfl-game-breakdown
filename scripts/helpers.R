rich_black <- "#010203"
grey <- "#808080"
red <- "#ff0000"
yellow <- "#FDDA0D"
light_blue <- "#0098ff"
purple <- "#800080"

vlog <- function(...) {
  if (VERBOSE) cat(paste0(...))
}

load_team_colors <- function() {
  nflfastR::teams_colors_logos |>
    dplyr::select(team_abbr, team_color)
}

read_version <- function() {
  for (path in c("VERSION", "../VERSION", "../../VERSION")) {
    if (file.exists(path)) return(trimws(readLines(path, n = 1)))
  }
  stop("Cannot find VERSION file")
}

add_version_watermark <- function(plot, version) {
  plot +
    ggplot2::annotate("text",
      x = Inf, y = -Inf,
      label = paste0("v", version),
      hjust = 1.1, vjust = -0.5,
      size = 2, color = grey, alpha = 0.5
    )
}

format_week_label <- function(week) {
  if (week == 19) "Wild Card Round"
  else if (week == 20) "Divisional Round"
  else if (week == 21) "Conference Championship"
  else if (week == 22) "Super Bowl"
  else glue("Week {week}")
}

# ---- Game Synopsis -----------------------------------------------------------

generate_synopsis <- function(data) {
  home_team <- data$home_team[1]
  away_team <- data$away_team[1]
  home_score <- tail(data$home_score, 1)
  away_score <- tail(data$away_score, 1)
  game_year <- strsplit(data$game_id[1], "_")[[1]][1]
  game_week <- as.integer(strsplit(data$game_id[1], "_")[[1]][2])
  week_label <- format_week_label(game_week)

  if (home_score > away_score) {
    winner <- home_team
  } else if (away_score > home_score) {
    winner <- away_team
  } else {
    winner <- NA_character_
  }

  if (!is.na(winner)) {
    loser <- ifelse(winner == home_team, away_team, home_team)
    opener <- glue("{winner} defeated {loser} {max(home_score, away_score)}-{min(home_score, away_score)}")
  } else {
    opener <- glue("{home_team} and {away_team} played to a {home_score}-{away_score} tie")
  }

  td_plays <- data |> filter(!is.na(td_player_name))
  turnovers <- data |> filter(interception == 1 | fumble_lost == 1)

  details <- c()
  if (nrow(td_plays) > 0) {
    top_td <- head(unique(td_plays$td_player_name[!is.na(td_plays$td_player_name)]), 3)
    if (length(top_td) > 0) {
      details <- c(details, glue("Key touchdowns from {paste(top_td, collapse = ', ')}"))
    }
  }
  if (nrow(turnovers) > 0) {
    n_turnovers <- nrow(turnovers |> distinct(posteam, game_seconds_remaining))
    details <- c(details, glue("The game featured {n_turnovers} turnover{ifelse(n_turnovers != 1, 's', '')}"))
  }

  detail_str <- if (length(details) > 0) paste(details, collapse = ". ") else "A competitive matchup from start to finish"

  glue("{opener} in {week_label}, {game_year}. {detail_str}.")
}

# ---- Color Clump Detection --------------------------------------------------

hex_to_rgb <- function(hex) {
  hex <- gsub("#", "", hex)
  data.frame(
    r = strtoi(substr(hex, 1, 2), 16L),
    g = strtoi(substr(hex, 3, 4), 16L),
    b = strtoi(substr(hex, 5, 6), 16L)
  )
}

rgb_to_lab <- function(r, g, b) {
  r_srgb <- r / 255
  g_srgb <- g / 255
  b_srgb <- b / 255

  r_lin <- ifelse(r_srgb > 0.04045, ((r_srgb + 0.055) / 1.055)^2.4, r_srgb / 12.92)
  g_lin <- ifelse(g_srgb > 0.04045, ((g_srgb + 0.055) / 1.055)^2.4, g_srgb / 12.92)
  b_lin <- ifelse(b_srgb > 0.04045, ((b_srgb + 0.055) / 1.055)^2.4, b_srgb / 12.92)

  x <- (0.4124564 * r_lin + 0.3575761 * g_lin + 0.1804375 * b_lin) / 0.95047
  y <- (0.2126729 * r_lin + 0.7151522 * g_lin + 0.0721750 * b_lin) / 1.00000
  z <- (0.0193339 * r_lin + 0.1191920 * g_lin + 0.9503041 * b_lin) / 1.08883

  f <- function(t) ifelse(t > (6/29)^3, t^(1/3), t / (3 * (6/29)^2) + 4/29)

  L <- 116 * f(y) - 16
  a <- 500 * (f(x) - f(y))
  b_val <- 200 * (f(y) - f(z))

  data.frame(L = L, a = a, b = b_val)
}

color_distance <- function(hex1, hex2) {
  rgb1 <- hex_to_rgb(hex1)
  rgb2 <- hex_to_rgb(hex2)
  lab1 <- rgb_to_lab(rgb1$r, rgb1$g, rgb1$b)
  lab2 <- rgb_to_lab(rgb2$r, rgb2$g, rgb2$b)
  sqrt((lab1$L - lab2$L)^2 + (lab1$a - lab2$a)^2 + (lab1$b - lab2$b)^2)
}

resolve_team_colors <- function(home_team, away_team, logos, threshold = 25) {
  home_color <- logos$team_color[logos$team_abbr == home_team]
  away_color <- logos$team_color[logos$team_abbr == away_team]
  away_secondary <- logos$team_color2[logos$team_abbr == away_team]
  home_secondary <- logos$team_color2[logos$team_abbr == home_team]

  home_use <- if (length(home_color) > 0) home_color else "#333333"
  away_use <- if (length(away_color) > 0) away_color else "#333333"

  if (length(home_color) > 0 && length(away_color) > 0) {
    dist <- color_distance(home_color, away_color)
    if (!is.na(dist) && dist < threshold) {
      # Try away secondary first
      combos <- list(
        list(h = home_color, a = if (!is.na(away_secondary)) away_secondary else away_color),
        list(h = if (!is.na(home_secondary)) home_secondary else home_color, a = away_color),
        list(h = if (!is.na(home_secondary)) home_secondary else home_color,
             a = if (!is.na(away_secondary)) away_secondary else away_color)
      )

      best_combo <- NULL
      best_dist <- -1
      for (combo in combos) {
        d <- color_distance(combo$h, combo$a)
        if (!is.na(d) && d > best_dist) {
          best_dist <- d
          best_combo <- combo
        }
      }

      if (!is.null(best_combo) && best_dist >= threshold) {
        home_use <- best_combo$h
        away_use <- best_combo$a
      } else if (!is.na(away_secondary)) {
        away_use <- away_secondary
      }
    }
  }

  list(home_color = home_use, away_color = away_use)
}
