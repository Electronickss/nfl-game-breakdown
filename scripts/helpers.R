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
