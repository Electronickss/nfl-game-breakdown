TESTING <- TRUE

# Load dependencies needed by function files (without nflfastR)
library(dplyr)
library(ggplot2)
library(scales)
library(glue)
if (requireNamespace("ggimage", quietly = TRUE)) library(ggimage)

# When run via test_dir, wd is tests/testthat/.
# When run via file_coverage or covr, wd is the project root.
if (file.exists("helper-mock-data.R")) {
  source("helper-mock-data.R")
} else if (file.exists("tests/testthat/helper-mock-data.R")) {
  source("tests/testthat/helper-mock-data.R")
}

if (!exists("rich_black")) {
  if (file.exists("../../scripts/helpers.R")) {
    source("../../scripts/helpers.R")
  } else if (file.exists("scripts/helpers.R")) {
    source("scripts/helpers.R")
  }
}

if (!exists("is_scoring_team")) {
  if (file.exists("../../scripts/wp-functions.R")) {
    source("../../scripts/wp-functions.R")
  } else if (file.exists("scripts/wp-functions.R")) {
    source("scripts/wp-functions.R")
  }
}

if (!exists("get_team_stats")) {
  if (file.exists("../../scripts/fs-functions.R")) {
    source("../../scripts/fs-functions.R")
  } else if (file.exists("scripts/fs-functions.R")) {
    source("scripts/fs-functions.R")
  }
}
