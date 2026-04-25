# dev/eda_01_data_pipeline.R
# Exploratory: validate data_preparation.R outputs before Shiny build
# Run from project root after running data_preparation.R

library(dplyr)
library(tidyr)
library(ggplot2)
library(here)

sessions   <- readRDS(here("app", "data", "processed", "sessions_clean.rds"))
parts      <- readRDS(here("app", "data", "processed", "participants.rds"))
quotes     <- readRDS(here("app", "data", "processed", "quotes_clean.rds"))

# ── Basic checks ──────────────────────────────────────────────────────────────
cat("=== sessions_clean ===\n")
glimpse(sessions)
cat("\nMissing values:\n")
colSums(is.na(sessions)) |> print()

cat("\n=== participants ===\n")
glimpse(parts)

cat("\n=== BPN summary ===\n")
sessions |>
  summarise(
    across(c(competence, autonomy, relatedness),
           list(mean = ~mean(.x, na.rm=TRUE),
                sd   = ~sd(.x, na.rm=TRUE),
                min  = ~min(.x, na.rm=TRUE),
                max  = ~max(.x, na.rm=TRUE)))
  ) |>
  tidyr::pivot_longer(everything()) |>
  print()

cat("\n=== Sessions per participant ===\n")
sessions |>
  group_by(uin) |>
  summarise(n = n()) |>
  summarise(
    min = min(n), max = max(n), median = median(n), mean = round(mean(n), 1)
  ) |>
  print()

cat("\n=== Sector breakdown ===\n")
parts |>
  count(sector, sort = TRUE) |>
  print()

cat("\n=== Quote availability ===\n")
quote_cols <- names(quotes)[grepl("most_", names(quotes))]
for (col in quote_cols) {
  cat(col, ":", sum(!is.na(quotes[[col]])), "/", nrow(quotes), "\n")
}
