options(show.error.locations = TRUE)
library(nflfastR)
library(tidyverse)
library(scales)
library(ggimage)
library(lubridate)

options(scipen = 9999)

rich_black = "#010203"
grey = "#808080"
light_blue = "#0098ff"

load_pbp_data <- function(year) {
  load_pbp(year)
}

load_rosters <- function(year) {
  nflreadr::load_rosters(year)
}

load_schedule <- function(year) {
  nflreadr::load_schedule(year)
}

get_team_stats <- function(pbp, team, week) {
  game <- pbp %>%
    filter(week == !!week, (home_team == team | away_team == team))

  is_home <- game$home_team[1] == team
  opponent <- ifelse(is_home, game$away_team[1], game$home_team[1])

  passing <- game %>%
    filter(pass == 1, posteam == team) %>%
    group_by(passer_player_name) %>%
    summarise(
      completions = sum(complete_pass, na.rm = TRUE),
      attempts = sum(pass_attempt, na.rm = TRUE),
      yards = sum(passing_yards, na.rm = TRUE),
      td = sum(pass_touchdown, na.rm = TRUE),
      interceptions = sum(interception, na.rm = TRUE),
      sacks = sum(sack, na.rm = TRUE),
      epa = sum(epa, na.rm = TRUE),
      cpoe = mean(cpoe, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(yards))

  rushing <- game %>%
    filter(rush == 1, posteam == team) %>%
    group_by(rusher_player_name) %>%
    summarise(
      carries = sum(rush_attempt, na.rm = TRUE),
      yards = sum(rushing_yards, na.rm = TRUE),
      td = sum(rush_touchdown, na.rm = TRUE),
      epa = sum(epa, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(yards))

  receiving <- game %>%
    filter(pass == 1, posteam == team) %>%
    group_by(receiver_player_name) %>%
    summarise(
      targets = sum(pass_attempt, na.rm = TRUE),
      receptions = sum(complete_pass, na.rm = TRUE),
      yards = sum(receiving_yards, na.rm = TRUE),
      td = sum(pass_touchdown, na.rm = TRUE),
      air_yards = sum(air_yards, na.rm = TRUE),
      epa = sum(epa, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(targets))

  return(list(
    passing = passing,
    rushing = rushing,
    receiving = receiving,
    opponent = opponent,
    is_home = is_home
  ))
}

plot_team_summary <- function(team_stats, team, week, year) {
  passing <- team_stats$passing
  rushing <- team_stats$rushing
  receiving <- team_stats$receiving
  opponent <- team_stats$opponent
  is_home <- team_stats$is_home

  home_away <- ifelse(is_home, "vs", "@")

  fig <- ggplot() +
    annotate("text", x = 0.5, y = 0.95, label = str_interp("${team} ${home_away} ${opponent} - Week ${week}, ${year}"),
             size = 6, fontface = "bold", hjust = 0.5) +

    annotate("text", x = 0.05, y = 0.85, label = "PASSING", size = 4, fontface = "bold", hjust = 0) +
    annotate("text", x = 0.05, y = 0.80, label = paste(collapse = "\n",
      apply(head(passing, 4), 1, function(row) {
        sprintf("%s: %d/%d, %d yds, %d TD, %d INT",
                row["passer_player_name"], as.integer(row["completions"]), as.integer(row["attempts"]),
                as.integer(row["yards"]), as.integer(row["td"]), as.integer(row["interceptions"]))
      })
    ), size = 3, hjust = 0, vjust = 1) +

    annotate("text", x = 0.05, y = 0.55, label = "RUSHING", size = 4, fontface = "bold", hjust = 0) +
    annotate("text", x = 0.05, y = 0.50, label = paste(collapse = "\n",
      apply(head(rushing, 3), 1, function(row) {
        sprintf("%s: %d carries, %d yds, %d TD",
                row["rusher_player_name"], as.integer(row["carries"]),
                as.integer(row["yards"]), as.integer(row["td"]))
      })
    ), size = 3, hjust = 0, vjust = 1) +

    annotate("text", x = 0.05, y = 0.30, label = "RECEIVING", size = 4, fontface = "bold", hjust = 0) +
    annotate("text", x = 0.05, y = 0.25, label = paste(collapse = "\n",
      apply(head(receiving, 5), 1, function(row) {
        sprintf("%s: %d tgt, %d rec, %d yds, %d TD",
                row["receiver_player_name"], as.integer(row["targets"]),
                as.integer(row["receptions"]), as.integer(row["yards"]),
                as.integer(row["td"]))
      })
    ), size = 3, hjust = 0, vjust = 1) +

    xlim(0, 1) + ylim(0, 1) +
    theme_void() +
    theme(plot.margin = margin(10, 10, 10, 10))

  return(fig)
}

plot_target_share <- function(receiving, team) {
  target_data <- receiving %>%
    filter(targets > 0) %>%
    arrange(desc(targets)) %>%
    head(8)

  plot <- ggplot(target_data, aes(x = reorder(receiver_player_name, targets), y = targets)) +
    geom_bar(stat = "identity", fill = light_blue) +
    geom_text(aes(label = targets), hjust = -0.2, size = 3) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = str_interp("${team} Target Share"),
      subtitle = "Targets by player",
      x = NULL,
      y = "Targets",
      caption = "Data from nflfastR"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      panel.grid.major.y = element_blank()
    )

  return(plot)
}

plot_air_yards <- function(receiving, team) {
  air_data <- receiving %>%
    filter(targets > 0) %>%
    arrange(desc(air_yards)) %>%
    head(8)

  plot <- ggplot(air_data, aes(x = reorder(receiver_player_name, air_yards), y = air_yards)) +
    geom_bar(stat = "identity", fill = light_blue) +
    geom_text(aes(label = air_yards), hjust = -0.2, size = 3) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = str_interp("${team} Air Yards"),
      subtitle = "Total air yards by receiver",
      x = NULL,
      y = "Air Yards",
      caption = "Data from nflfastR"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      panel.grid.major.y = element_blank()
    )

  return(plot)
}

plot_rb_workload <- function(pbp, week, year) {
  game <- pbp %>%
    filter(week == !!week, qtr <= 4) %>%
    filter(!is.na(game_seconds_remaining))

  home_team <- game$home_team[1]
  away_team <- game$away_team[1]

  wp_line <- game %>%
    distinct(game_seconds_remaining, vegas_home_wp) %>%
    arrange(desc(game_seconds_remaining))

  rb_rushes <- game %>%
    filter(rush == 1, !is.na(rusher_player_name)) %>%
    mutate(touch_type = "Rush") %>%
    select(game_seconds_remaining, vegas_home_wp, player = rusher_player_name, posteam, touch_type)

  rb_targets <- game %>%
    filter(pass == 1, !is.na(rusher_player_name), rush_attempt == 1) %>%
    mutate(touch_type = "Target (RB)") %>%
    select(game_seconds_remaining, vegas_home_wp, player = rusher_player_name, posteam, touch_type)

  rb_pass_att <- game %>%
    filter(pass == 1, !is.na(rusher_player_name), pass_attempt == 1) %>%
    mutate(touch_type = "Pass Att") %>%
    select(game_seconds_remaining, vegas_home_wp, player = rusher_player_name, posteam, touch_type)

  all_touches <- bind_rows(rb_rushes, rb_targets, rb_pass_att)

  top_rbs <- all_touches %>%
    count(posteam, player, sort = TRUE) %>%
    group_by(posteam) %>%
    slice_head(n = 4) %>%
    ungroup()

  all_touches <- all_touches %>%
    inner_join(top_rbs, by = c("posteam", "player"))

  top_rb_names <- top_rbs$player
  player_colors <- setNames(
    rep(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3"), 2)[1:length(top_rb_names)],
    top_rb_names
  )

  game_title <- str_interp("${away_team} at ${home_team} - Week ${week}, ${year}")

  plot <- ggplot(wp_line, aes(x = game_seconds_remaining, y = vegas_home_wp)) +
    geom_hline(yintercept = 0.5, color = grey, size = 0.5) +
    geom_vline(xintercept = c(15, 30, 45) * 60, color = grey, size = 0.25) +
    annotate("text", x = 58 * 60, y = 0.95, label = "Q1", color = grey, size = 2) +
    annotate("text", x = 43 * 60, y = 0.95, label = "Q2", color = grey, size = 2) +
    annotate("text", x = 28 * 60, y = 0.95, label = "Q3", color = grey, size = 2) +
    annotate("text", x = 13 * 60, y = 0.95, label = "Q4", color = grey, size = 2) +
    geom_line(size = 0.8) +
    geom_rug(
      data = all_touches %>% filter(touch_type == "Rush"),
      aes(x = game_seconds_remaining, color = player),
      sides = "b", size = 0.8
    ) +
    geom_rug(
      data = all_touches %>% filter(touch_type == "Target (RB)"),
      aes(x = game_seconds_remaining, color = player),
      sides = "t", size = 0.8
    ) +
    geom_point(
      data = all_touches %>% filter(touch_type == "Pass Att"),
      aes(x = game_seconds_remaining, y = vegas_home_wp, color = player),
      shape = 4, size = 2, stroke = 1.5
    ) +
    scale_color_manual(values = player_colors, name = "Player") +
    scale_x_reverse() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    labs(
      title = str_interp("RB Workload: ${game_title}"),
      subtitle = "Bottom = Rushes | Top = Targets | X = Pass Attempts",
      caption = "Data from nflfastR",
      x = "Game Clock",
      y = "Home Win Probability"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      axis.text.x = element_blank(),
      legend.position = "bottom"
    )

  return(plot)
}

plot_wrte_targets <- function(pbp, week, year) {
  game <- pbp %>%
    filter(week == !!week, qtr <= 4) %>%
    filter(!is.na(game_seconds_remaining))

  home_team <- game$home_team[1]
  away_team <- game$away_team[1]

  wp_line <- game %>%
    distinct(game_seconds_remaining, vegas_home_wp) %>%
    arrange(desc(game_seconds_remaining))

  wrte_targets <- game %>%
    filter(pass == 1, !is.na(receiver_player_name)) %>%
    mutate(touch_type = "Target") %>%
    select(game_seconds_remaining, vegas_home_wp, player = receiver_player_name, posteam, touch_type)

  wrte_rushes <- game %>%
    filter(rush == 1, !is.na(receiver_player_name)) %>%
    mutate(touch_type = "Rush") %>%
    select(game_seconds_remaining, vegas_home_wp, player = receiver_player_name, posteam, touch_type)

  wrte_pass_att <- game %>%
    filter(pass == 1, !is.na(receiver_player_name), pass_attempt == 1) %>%
    mutate(touch_type = "Pass Att") %>%
    select(game_seconds_remaining, vegas_home_wp, player = receiver_player_name, posteam, touch_type)

  all_touches <- bind_rows(wrte_targets, wrte_rushes, wrte_pass_att)

  top_wrte <- all_touches %>%
    filter(touch_type == "Target") %>%
    count(posteam, player, sort = TRUE) %>%
    group_by(posteam) %>%
    slice_head(n = 5) %>%
    ungroup()

  all_touches <- all_touches %>%
    inner_join(top_wrte, by = c("posteam", "player"))

  top_names <- top_wrte$player
  player_colors <- setNames(
    rep(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00"), 2)[1:length(top_names)],
    top_names
  )

  game_title <- str_interp("${away_team} at ${home_team} - Week ${week}, ${year}")

  plot <- ggplot(wp_line, aes(x = game_seconds_remaining, y = vegas_home_wp)) +
    geom_hline(yintercept = 0.5, color = grey, size = 0.5) +
    geom_vline(xintercept = c(15, 30, 45) * 60, color = grey, size = 0.25) +
    annotate("text", x = 58 * 60, y = 0.95, label = "Q1", color = grey, size = 2) +
    annotate("text", x = 43 * 60, y = 0.95, label = "Q2", color = grey, size = 2) +
    annotate("text", x = 28 * 60, y = 0.95, label = "Q3", color = grey, size = 2) +
    annotate("text", x = 13 * 60, y = 0.95, label = "Q4", color = grey, size = 2) +
    geom_line(size = 0.8) +
    geom_rug(
      data = all_touches %>% filter(touch_type == "Target"),
      aes(x = game_seconds_remaining, color = player),
      sides = "t", size = 0.8
    ) +
    geom_rug(
      data = all_touches %>% filter(touch_type == "Rush"),
      aes(x = game_seconds_remaining, color = player),
      sides = "b", size = 0.8
    ) +
    geom_point(
      data = all_touches %>% filter(touch_type == "Pass Att"),
      aes(x = game_seconds_remaining, y = vegas_home_wp, color = player),
      shape = 4, size = 2, stroke = 1.5
    ) +
    scale_color_manual(values = player_colors, name = "Player") +
    scale_x_reverse() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    labs(
      title = str_interp("WR/TE Targets: ${game_title}"),
      subtitle = "Top = Targets | Bottom = Rushes | X = Pass Attempts",
      caption = "Data from nflfastR",
      x = "Game Clock",
      y = "Home Win Probability"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      axis.text.x = element_blank(),
      legend.position = "bottom"
    )

  return(plot)
}

year <- 2023
week <- 16
team <- "BAL"

dir.create("charts", showWarnings = FALSE)

pbp <- load_pbp_data(year)

team_stats <- get_team_stats(pbp, team, week)

summary_plot <- plot_team_summary(team_stats, team, week, year)
ggsave(str_interp("charts/${team}-w${week}-summary.png"), summary_plot, width = 8, height = 6, dpi = 150)

target_plot <- plot_target_share(team_stats$receiving, team)
ggsave(str_interp("charts/${team}-w${week}-targets.png"), target_plot, width = 8, height = 6, dpi = 150)

air_plot <- plot_air_yards(team_stats$receiving, team)
ggsave(str_interp("charts/${team}-w${week}-airyards.png"), air_plot, width = 8, height = 6, dpi = 150)

rb_plot <- plot_rb_workload(pbp, week, year)
ggsave(str_interp("charts/rb-workload-w${week}.png"), rb_plot, width = 10, height = 6, dpi = 150)

wrte_plot <- plot_wrte_targets(pbp, week, year)
ggsave(str_interp("charts/wrte-targets-w${week}.png"), wrte_plot, width = 10, height = 6, dpi = 150)

cat(str_interp("Generated charts for ${team} Week ${week}, ${year}\n"))
cat(str_interp("Opponent: ${ifelse(team_stats$is_home, 'vs', '@')} ${team_stats$opponent}\n"))
