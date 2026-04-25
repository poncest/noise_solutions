# install_packages.R
# Run ONCE to set up the project environment
# Uses pak for fast, reliable installation
# DO NOT source this inside the app — never deployed

if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

pak::pkg_install(c(
  # Core Shiny
  "shiny",
  "shiny.semantic",

  # Data wrangling
  "dplyr",
  "tidyr",
  "readxl",
  "janitor",
  "lubridate",
  "stringr",

  # Visualization
  "ggplot2",
  "scales",
  "ggiraph",

  # Tables
  "reactable",

  # Utilities
  "here",
  "glue",

  # Deployment
  "rsconnect"
))

cat("All packages installed successfully.\n")
