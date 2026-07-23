library(nflfastR)
library(tidyverse)
library(scales)
library(ggimage)
library(lubridate)

options(scipen = 9999)

rich_black = "#010203"
grey = "#808080"
red = "#ff0000"
yellow = "#FDDA0D"

load_data <- function(start_year, end_year) {
  load_pbp(start_year:end_year)
}

load_logos <- function() {
  logos <- teams_colors_logos %>%
    select(team_abbr, team_logo_espn)
  return(logos)
}

is_scoring_team <- function(posteam, play_type, field_goal_result, td_team, safety, this_team, that_team) {
  result <- (td_team == this_team) |
    (posteam == this_team & (play_type == "extra_point" | field_goal_result == "made")) |
    (posteam == that_team & safety == 1)
  ifelse(is.na(result), FALSE, result)
}

is_turnover_team <- function(posteam, fumble_lost, interception, this_team) {
  result <- (posteam == this_team) & (interception == 1 | fumble_lost == 1)
  ifelse(is.na(result), FALSE, result)
}

is_penalty_team <- function(penalty_team, first_down_penalty, this_team) {
  result <- (penalty_team == this_team) & (first_down_penalty == 1)
  ifelse(is.na(result), FALSE, result)
}

load_data_and_build <- function(start_year, end_year) {
  logos <- load_logos()
  pbp <- load_data(start_year, end_year) %>%
    left_join(logos, by = c("posteam" = "team_abbr")) %>%
    filter(
      !is.na(score_differential), !is.na(play_type), !is.na(down),
      !is.na(yardline_100), !is.na(defteam_timeouts_remaining),
      !is.na(posteam_timeouts_remaining), qtr <= 4
    ) %>%
    mutate(
      winner = if_else(home_score > away_score, home_team,
        if_else(home_score < away_score, away_team, "TIE")
      ),
      poswins = ifelse(posteam == winner, 1, 0),
      is_home_team = ifelse(posteam == home_team, 1, 0),
      home_scoring_play = is_scoring_team(posteam, play_type, field_goal_result, td_team, safety, home_team, away_team),
      away_scoring_play = is_scoring_team(posteam, play_type, field_goal_result, td_team, safety, away_team, home_team),
      home_turnover_play = is_turnover_team(posteam, fumble_lost, interception, home_team),
      away_turnover_play = is_turnover_team(posteam, fumble_lost, interception, away_team),
      home_penalty = is_penalty_team(penalty_team, first_down_penalty, home_team),
      away_penalty = is_penalty_team(penalty_team, first_down_penalty, away_team),
    ) %>%
    filter(winner != "TIE", !is.na(poswins)) %>%
    select(
      game_id, game_date, posteam, poswins, home_team, away_team, winner,
      qtr, down, ydstogo, game_seconds_remaining, yardline_100,
      score_differential, defteam_timeouts_remaining, posteam_timeouts_remaining,
      home_scoring_play, away_scoring_play, home_turnover_play, away_turnover_play,
      home_penalty, away_penalty, vegas_home_wp, field_goal_result, wp,
      interception, fumble_lost, is_home_team, home_score, away_score,
      team_logo_espn
    )
  return(pbp)
}

theme_high_contrast <- function(base_size = 11, base_family = "", foreground_color = "white", background_color = "black") {
  half_line <- base_size/2
  theme(line = element_line(colour = foreground_color, size = 0.5, linetype = 1, lineend = "butt"),
        rect = element_rect(fill = foreground_color, colour = foreground_color, size = 0.5, linetype = 1),
        text = element_text(family = base_family, face = "plain", colour = foreground_color, size = base_size,
                            lineheight = 0.9, hjust = 0, vjust = 0.5, angle = 0, margin = margin(), debug = FALSE),
        axis.line = element_blank(),
        axis.text = element_text(size = rel(0.8), colour = foreground_color),
        axis.text.x = element_text(margin = margin(t = 0.8 * half_line/2), vjust = 1, hjust = 0.5, color = foreground_color),
        axis.text.y = element_text(margin = margin(r = 0.8 * half_line/2), hjust = 1, color = foreground_color),
        axis.ticks = element_line(colour = foreground_color),
        axis.ticks.length = unit(half_line/2, "pt"),
        axis.ticks.y = element_blank(),
        axis.title.x = element_text(margin = margin(t = 0.8 * half_line, b = 0.8 * half_line/2)),
        axis.title.y = element_text(angle = 90, margin = margin(r = 0.8 * half_line, l = 0.8 * half_line/2)),
        legend.background = element_rect(colour = background_color, fill = background_color),
        legend.spacing = unit(0.2, "cm"),
        legend.key = element_rect(fill = background_color, colour = foreground_color),
        legend.key.size = unit(1.2, "lines"),
        legend.text = element_text(size = rel(0.8)),
        legend.title = element_text(hjust = 0),
        legend.position = "right",
        legend.justification = "center",
        panel.background = element_rect(colour = background_color, fill = background_color),
        panel.border = element_blank(),
        panel.grid.major.y = element_line(colour = foreground_color, linetype = "dotted"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.spacing = unit(half_line, "pt"),
        panel.ontop = FALSE,
        strip.background = element_blank(),
        strip.text = element_text(colour = foreground_color, size = rel(0.8)),
        strip.text.x = element_text(margin = margin(t = half_line, b = half_line)),
        strip.text.y = element_text(angle = -90, margin = margin(l = half_line, r = half_line)),
        strip.switch.pad.grid = unit(0.1, "cm"),
        strip.switch.pad.wrap = unit(0.1, "cm"),
        plot.background = element_rect(colour = background_color, fill = background_color),
        plot.title = element_text(size = rel(1.2), margin = margin(b = half_line * 1.2), face = "bold"),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_text(size = rel(0.6), hjust = 1),
        plot.margin = margin(half_line, half_line, half_line, half_line * 1.5),
        complete = TRUE)
}

plot_win_probability <- function(data, logos, foreground_color = rich_black, background_color = "white") {
  single_game_id <- data[1, ]$game_id
  game_title_pieces <- strsplit(single_game_id, "_")[[1]]
  game_year <- game_title_pieces[1]
  game_week <- game_title_pieces[2]

  home_team_abbr <- data[1, ]$home_team
  away_team_abbr <- data[1, ]$away_team

  logo_placement_data <- data.frame(
    x = c(3600, 3600),
    y = c(0.875, 0.125),
    team_abbr = c(home_team_abbr, away_team_abbr),
    stringsAsFactors = FALSE
  ) %>% inner_join(logos, by = "team_abbr")

  plot <- ggplot(data, aes(x = game_seconds_remaining, y = vegas_home_wp)) +
    geom_hline(yintercept = 0.5, color = grey, size = 1) +
    geom_vline(xintercept = c(0, 15, 30, 45, 60) * 60, color = grey, size = 0.25) +
    annotate("text", x = 58 * 60, y = 0.95, label = "Q1", color = grey, size = 2) +
    annotate("text", x = 43 * 60, y = 0.95, label = "Q2", color = grey, size = 2) +
    annotate("text", x = 28 * 60, y = 0.95, label = "Q3", color = grey, size = 2) +
    annotate("text", x = 13 * 60, y = 0.95, label = "Q4", color = grey, size = 2) +
    geom_line(size = 0.8) +
    geom_rug(data = filter(data, home_scoring_play == 1), color = rich_black, sides = "t", size = 1.0) +
    geom_rug(data = filter(data, away_scoring_play == 1), color = rich_black, sides = "b", size = 1.0) +
    geom_rug(data = filter(data, home_turnover_play == 1), color = red, sides = "b", size = 1.0) +
    geom_rug(data = filter(data, away_turnover_play == 1), color = red, sides = "t", size = 1.0) +
    geom_rug(data = filter(data, home_penalty == 1), color = yellow, sides = "t", size = 0.5) +
    geom_rug(data = filter(data, away_penalty == 1), color = yellow, sides = "b", size = 0.5) +
    geom_image(data = logo_placement_data, aes(x = x, y = y, image = team_logo_espn), size = 0.08, asp = 16 / 9) +
    scale_x_reverse() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    theme_high_contrast(base_family = "Helvetica", background_color = background_color, foreground_color = foreground_color) +
    theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), legend.position = "none") +
    labs(
      title = str_interp("${game_year} Week ${game_week}: ${away_team_abbr} (${tail(data$away_score, 1)}) at ${home_team_abbr} (${tail(data$home_score, 1)})"),
      caption = "Data from nflfastR",
      x = "Quarters",
      y = "Home Win Probability"
    )

  return(plot)
}
