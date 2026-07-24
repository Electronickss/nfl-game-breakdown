# ---- Data Loading -----------------------------------------------------------

load_pbp_data <- function(year) {
  nflfastR::load_pbp(year)
}

load_rosters <- function(year) {
  nflreadr::load_rosters(year)
}

load_schedule <- function(year) {
  nflreadr::load_schedule(year)
}

# ---- Team Stats -------------------------------------------------------------

get_team_stats <- function(pbp, team, week) {
  game <- pbp |>
    filter(week == !!week, (home_team == team | away_team == team))

  is_home <- game$home_team[1] == team
  opponent <- ifelse(is_home, game$away_team[1], game$home_team[1])

  passing <- game |>
    filter(pass == 1, posteam == team) |>
    group_by(passer_player_name) |>
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
    ) |>
    arrange(desc(yards))

  rushing <- game |>
    filter(rush == 1, posteam == team) |>
    group_by(rusher_player_name) |>
    summarise(
      carries = sum(rush_attempt, na.rm = TRUE),
      yards = sum(rushing_yards, na.rm = TRUE),
      td = sum(rush_touchdown, na.rm = TRUE),
      epa = sum(epa, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(yards))

  receiving <- game |>
    filter(pass == 1, posteam == team) |>
    group_by(receiver_player_name) |>
    summarise(
      targets = sum(pass_attempt, na.rm = TRUE),
      receptions = sum(complete_pass, na.rm = TRUE),
      yards = sum(receiving_yards, na.rm = TRUE),
      td = sum(pass_touchdown, na.rm = TRUE),
      air_yards = sum(air_yards, na.rm = TRUE),
      epa = sum(epa, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(targets))

  return(list(
    passing = passing,
    rushing = rushing,
    receiving = receiving,
    opponent = opponent,
    is_home = is_home
  ))
}

# ---- Summary Chart ----------------------------------------------------------

plot_team_summary <- function(team_stats, team, week, year) {
  passing <- team_stats$passing
  rushing <- team_stats$rushing
  receiving <- team_stats$receiving
  opponent <- team_stats$opponent
  is_home <- team_stats$is_home

  home_away <- ifelse(is_home, "vs", "@")
  week_label <- format_week_label(week)

  fig <- ggplot() +
    annotate("text", x = 0.5, y = 0.95,
      label = glue("{team} {home_away} {opponent} - {week_label}, {year}"),
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

# ---- Target Share Chart -----------------------------------------------------

plot_target_share <- function(receiving, team) {
  target_data <- receiving |>
    filter(targets > 0) |>
    arrange(desc(targets)) |>
    head(8)

  plot <- ggplot(target_data, aes(x = reorder(receiver_player_name, targets), y = targets)) +
    geom_bar(stat = "identity", fill = light_blue) +
    geom_text(aes(label = targets), hjust = -0.2, size = 3) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = glue("{team} Target Share"),
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

# ---- Air Yards Chart --------------------------------------------------------

plot_air_yards <- function(receiving, team) {
  air_data <- receiving |>
    filter(targets > 0) |>
    arrange(desc(air_yards)) |>
    head(8)

  plot <- ggplot(air_data, aes(x = reorder(receiver_player_name, air_yards), y = air_yards)) +
    geom_bar(stat = "identity", fill = light_blue) +
    geom_text(aes(label = air_yards), hjust = -0.2, size = 3) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = glue("{team} Air Yards"),
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

# ---- Workload Chart Helpers -------------------------------------------------

build_wp_segments <- function(game, logos) {
  team_colors <- logos |>
    distinct(team_abbr, team_color)
  team_colors <- setNames(team_colors$team_color, team_colors$team_abbr)

  wp_line <- game |>
    distinct(game_seconds_remaining, vegas_home_wp, posteam) |>
    arrange(desc(game_seconds_remaining)) |>
    mutate(
      x_end = dplyr::lead(game_seconds_remaining),
      y_end = dplyr::lead(vegas_home_wp)
    ) |>
    filter(!is.na(x_end))

  list(wp_line = wp_line, team_colors = team_colors)
}

build_touch_data <- function(game, touch_types) {
  bind_rows(touch_types) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)
}

assign_player_colors <- function(players) {
  palette <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00",
               "#A65628", "#F781BF", "#999999", "#66C2A5", "#FC8D62")
  n <- length(players)
  setNames(palette[seq_len(n) %% length(palette) + 1], players)
}

get_player_team_colors <- function(touch_data, logos) {
  team_map <- logos |>
    distinct(team_abbr, team_color)
  team_map <- setNames(team_map$team_color, team_map$team_abbr)
  touch_data$player_team_color <- team_map[touch_data$posteam]
  touch_data
}

add_touch_labels <- function(plot, touch_data, player_team_colors, position = "above") {
  labeled_touches <- touch_data |>
    group_by(player) |>
    slice_min(game_seconds_remaining, n = 1) |>
    ungroup()

  labeled_touches <- get_player_team_colors(labeled_touches, player_team_colors)

  if (nrow(labeled_touches) > 0 && requireNamespace("ggrepel", quietly = TRUE)) {
    plot +
      ggrepel::geom_text_repel(
        data = labeled_touches,
        aes(x = game_seconds_remaining, y = vegas_home_wp, label = player, color = player),
        size = 2.5, fontface = "bold", show.legend = FALSE,
        direction = "x", box.padding = 0.4, point.padding = 0.6,
        segment.color = "grey50", segment.size = 0.3,
        max.overlaps = Inf, force = 2,
        nudge_y = if (position == "above") 0.04 else -0.04
      )
  } else if (nrow(labeled_touches) > 0) {
    plot +
      geom_text(
        data = labeled_touches,
        aes(x = game_seconds_remaining, y = vegas_home_wp, label = player, color = player),
        size = 2.5, fontface = "bold", vjust = if (position == "above") -1.5 else 1.5,
        show.legend = FALSE
      )
  } else {
    plot
  }
}

# ---- RB Workload Chart ------------------------------------------------------

plot_rb_workload <- function(pbp, week, year, game_id = NULL) {
  game <- pbp |>
    filter(week == !!week, qtr <= 4) |>
    filter(!is.na(game_seconds_remaining))

  if (!is.null(game_id)) {
    game <- game |> filter(game_id == !!game_id)
  }

  home_team <- game$home_team[1]
  away_team <- game$away_team[1]
  logos <- load_logos()

  resolved <- resolve_team_colors(home_team, away_team, logos)
  wp <- build_wp_segments(game, logos)

  wp_team_colors <- c(
    setNames(resolved$home_color, home_team),
    setNames(resolved$away_color, away_team)
  )

  rb_rushes <- game |>
    filter(rush == 1, !is.na(rusher_player_name)) |>
    mutate(touch_type = "Rush", player = rusher_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  rb_targets <- game |>
    filter(pass == 1, !is.na(receiver_player_name), rush_attempt == 1) |>
    mutate(touch_type = "Target", player = receiver_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  rb_fumbles <- game |>
    filter(fumble == 1, !is.na(fumbled_1_player_name)) |>
    mutate(touch_type = "Fumble", player = fumbled_1_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  rb_scores <- game |>
    filter(!is.na(td_player_name)) |>
    mutate(touch_type = "Score", player = td_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  all_touches <- build_touch_data(game, list(rb_rushes, rb_targets, rb_fumbles, rb_scores))

  top_rbs <- all_touches |>
    count(posteam, player, sort = TRUE) |>
    group_by(posteam) |>
    slice_head(n = 4) |>
    ungroup()

  all_touches <- all_touches |>
    inner_join(top_rbs, by = c("posteam", "player"))

  player_colors <- assign_player_colors(top_rbs$player)

  touch_shapes <- c("Rush" = 16, "Target" = 17, "Fumble" = 18, "Score" = 8)
  touch_sizes <- c("Rush" = 2, "Target" = 2, "Fumble" = 2.5, "Score" = 3)

  week_label <- format_week_label(week)
  game_title <- glue("{away_team} at {home_team} - {week_label}, {year}")

  plot <- ggplot(wp$wp_line, aes(x = game_seconds_remaining, y = vegas_home_wp)) +
    geom_hline(yintercept = 0.5, color = grey, linewidth = 0.5) +
    geom_vline(xintercept = c(15, 30, 45) * 60, color = grey, linewidth = 0.25) +
    annotate("text", x = 58 * 60, y = 0.95, label = "Q1", color = grey, size = 2) +
    annotate("text", x = 43 * 60, y = 0.95, label = "Q2", color = grey, size = 2) +
    annotate("text", x = 28 * 60, y = 0.95, label = "Q3", color = grey, size = 2) +
    annotate("text", x = 13 * 60, y = 0.95, label = "Q4", color = grey, size = 2) +
    geom_segment(
      data = wp$wp_line,
      aes(x = game_seconds_remaining, xend = x_end, y = vegas_home_wp, yend = y_end, color = posteam),
      linewidth = 0.8
    ) +
    scale_color_manual(values = wp_team_colors, name = "Possession") +
    geom_point(
      data = all_touches,
      aes(x = game_seconds_remaining, y = vegas_home_wp, shape = touch_type),
      color = "grey30", size = 2, stroke = 0.5
    ) +
    scale_shape_manual(values = touch_shapes, name = "Touch Type") +
    scale_x_reverse() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    labs(
      title = glue("RB Workload: {game_title}"),
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

  plot <- add_touch_labels(plot, all_touches, logos)

  version <- tryCatch(read_version(), error = function(e) "dev")
  plot <- add_version_watermark(plot, version)

  return(plot)
}

# ---- WR/TE Targets Chart ----------------------------------------------------

plot_wrte_targets <- function(pbp, week, year, game_id = NULL) {
  game <- pbp |>
    filter(week == !!week, qtr <= 4) |>
    filter(!is.na(game_seconds_remaining))

  if (!is.null(game_id)) {
    game <- game |> filter(game_id == !!game_id)
  }

  home_team <- game$home_team[1]
  away_team <- game$away_team[1]
  logos <- load_logos()

  resolved <- resolve_team_colors(home_team, away_team, logos)
  wp <- build_wp_segments(game, logos)

  wp_team_colors <- c(
    setNames(resolved$home_color, home_team),
    setNames(resolved$away_color, away_team)
  )

  wrte_targets <- game |>
    filter(pass == 1, !is.na(receiver_player_name)) |>
    mutate(touch_type = "Target", player = receiver_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  wrte_fumbles <- game |>
    filter(fumble == 1, !is.na(fumbled_1_player_name)) |>
    mutate(touch_type = "Fumble", player = fumbled_1_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  wrte_scores <- game |>
    filter(!is.na(td_player_name)) |>
    mutate(touch_type = "Score", player = td_player_name) |>
    select(game_seconds_remaining, vegas_home_wp, player, posteam, touch_type)

  all_touches <- build_touch_data(game, list(wrte_targets, wrte_fumbles, wrte_scores))

  top_wrte <- all_touches |>
    filter(touch_type == "Target") |>
    count(posteam, player, sort = TRUE) |>
    group_by(posteam) |>
    slice_head(n = 5) |>
    ungroup()

  all_touches <- all_touches |>
    inner_join(top_wrte, by = c("posteam", "player"))

  player_colors <- assign_player_colors(top_wrte$player)

  touch_shapes <- c("Target" = 17, "Fumble" = 18, "Score" = 8)
  touch_sizes <- c("Target" = 2, "Fumble" = 2.5, "Score" = 3)

  week_label <- format_week_label(week)
  game_title <- glue("{away_team} at {home_team} - {week_label}, {year}")

  plot <- ggplot(wp$wp_line, aes(x = game_seconds_remaining, y = vegas_home_wp)) +
    geom_hline(yintercept = 0.5, color = grey, linewidth = 0.5) +
    geom_vline(xintercept = c(15, 30, 45) * 60, color = grey, linewidth = 0.25) +
    annotate("text", x = 58 * 60, y = 0.95, label = "Q1", color = grey, size = 2) +
    annotate("text", x = 43 * 60, y = 0.95, label = "Q2", color = grey, size = 2) +
    annotate("text", x = 28 * 60, y = 0.95, label = "Q3", color = grey, size = 2) +
    annotate("text", x = 13 * 60, y = 0.95, label = "Q4", color = grey, size = 2) +
    geom_segment(
      data = wp$wp_line,
      aes(x = game_seconds_remaining, xend = x_end, y = vegas_home_wp, yend = y_end, color = posteam),
      linewidth = 0.8
    ) +
    scale_color_manual(values = wp_team_colors, name = "Possession") +
    geom_point(
      data = all_touches,
      aes(x = game_seconds_remaining, y = vegas_home_wp, shape = touch_type),
      color = "grey30", size = 2, stroke = 0.5
    ) +
    scale_shape_manual(values = touch_shapes, name = "Touch Type") +
    scale_x_reverse() +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    labs(
      title = glue("WR/TE Targets: {game_title}"),
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

  plot <- add_touch_labels(plot, all_touches, logos)

  version <- tryCatch(read_version(), error = function(e) "dev")
  plot <- add_version_watermark(plot, version)

  return(plot)
}
