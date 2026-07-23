library(nflfastR) # NFL Fast R
library(tidyverse) # Data Cleaning, manipulation, summarization, plotting
library(ggthemes)
library(ggimage)


# Custom Theme
theme_538 <- function(base_size = 12, font = "Lato") {
  
  # Text setting
  txt <- element_text(size = base_size + 2, colour = "black", face = "plain")
  bold_txt <- element_text(
    size = base_size + 2, colour = "black",
    family = "Montserrat", face = "bold"
  )
  large_txt <- element_text(size = base_size + 4, color = "black", face = "bold")
  
  theme_minimal(base_size = base_size, base_family = font) +
    theme(
      # Legend Settings
      legend.key = element_blank(),
      legend.background = element_blank(),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.box = "vertical",
      
      # Backgrounds
      strip.background = element_blank(),
      strip.text = large_txt,
      plot.background = element_blank(),
      plot.margin = unit(c(1, 1, 1, 1), "lines"),
      
      # Axis & Titles
      text = txt,
      axis.text = txt,
      axis.ticks = element_blank(),
      axis.line = element_line(colour = "black"),
      axis.title = bold_txt,
      plot.title = large_txt,
      
      # Panel
      panel.grid = element_line(colour = NULL),
      panel.grid.major = element_line(colour = "#D2D2D2"),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      panel.border = element_rect(colour = "black", fill=NA, size=5)
    )
}

pbp <- nflreadr::load_pbp(2021) %>%
  filter(week == 16, home_team == "TEN")

pbp %>%
  dplyr::mutate(
    game_minutes_remaining = game_seconds_remaining / 60,
  ) %>%
  ggplot(aes(x=game_minutes_remaining, y=vegas_home_wp)) +
  geom_line(size=.5) +
  geom_hline(yintercept = .5, size = .25) +
  geom_point(mapping = aes(x = dplyr::filter(pbp,interception == 1), y = 0)) +
  labs(
    title = "RB Usage Chart",
    subtitle = "Plotted Against Win Percentage",
    caption = "Data: @nflfastR | Plot: @electronicks_ff"
  ) +
  theme_538() +
  scale_x_continuous(trans="reverse", breaks=c(60,45,30,15,0), name="Minutes Remaining") +
  scale_y_continuous(limit=c(0,1), breaks=c(1,.75,.5,.25,0), name="Home Team Win Probability", labels = scales::percent)