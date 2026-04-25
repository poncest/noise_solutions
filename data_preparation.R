# data_preparation.R
# Run ONCE (or when source data updates) to produce clean .rds files
# Never deployed to shinyapps.io
# Output: app/data/processed/*.rds

library(dplyr)
library(tidyr)
library(readxl)
library(janitor)
library(lubridate)
library(stringr)
library(here)

# ── 0. Paths ──────────────────────────────────────────────────────────────────
raw_dir       <- here("app", "data", "raw")
processed_dir <- here("app", "data", "processed")

# ── 1. Load raw files ─────────────────────────────────────────────────────────
quant_raw <- read_excel(
  file.path(raw_dir, "Transceve_Quant_for_DCM_v2_1.xls"),
  col_types = "text"
) |> clean_names()

qual_raw <- read_excel(
  file.path(raw_dir, "Transceve_Qual_for_DCM_v2_1.xls"),
  col_types = "text"
) |> clean_names()

demo_raw <- read_excel(
  file.path(raw_dir, "Noise_Solution_Demographics_220426.xls"),
  col_types = "text"
) |> clean_names()

# ── 2. Clean quant ────────────────────────────────────────────────────────────
quant <- quant_raw |>
  mutate(
    session_start       = dmy_hm(session_start),
    competence          = as.numeric(sense_of_competence),
    autonomy            = as.numeric(sense_of_autonomy),
    relatedness         = as.numeric(sense_of_relatedness),
    session_rating      = as.numeric(session_rating_overall)
  ) |>
  select(uin, session_id = id, session_start, session_analysis_name,
         competence, autonomy, relatedness, session_rating)

# ── 3. Average the 5 runs per session ─────────────────────────────────────────
# Each session is analysed up to 5 times — average before any analysis
sessions_clean <- quant |>
  group_by(uin, session_id, session_start) |>
  summarise(
    competence     = mean(competence,    na.rm = TRUE),
    autonomy       = mean(autonomy,      na.rm = TRUE),
    relatedness    = mean(relatedness,   na.rm = TRUE),
    session_rating = mean(session_rating, na.rm = TRUE),
    n_runs         = n(),
    .groups        = "drop"
  ) |>
  # Session order per participant (1 = first session chronologically)
  arrange(uin, session_start) |>
  group_by(uin) |>
  mutate(session_number = row_number(),
         n_sessions     = n()) |>
  ungroup() |>
  # Composite BPN score (mean of three needs)
  mutate(bpn_mean = (competence + autonomy + relatedness) / 3)

# ── 4. Clean demographics ─────────────────────────────────────────────────────
# One row per participant — demographics don't change across sessions
demo_clean <- demo_raw |>
  distinct(uin, .keep_all = TRUE) |>
  mutate(
    age    = as.numeric(participant_age),
    gender = str_to_title(participant_gender),
    sector = str_to_title(sector)
  ) |>
  select(uin, age, gender, sector)

# ── 5. Participant summary ────────────────────────────────────────────────────
participants <- sessions_clean |>
  group_by(uin) |>
  summarise(
    n_sessions       = max(session_number),
    first_session    = min(session_start),
    last_session     = max(session_start),
    avg_competence   = mean(competence,    na.rm = TRUE),
    avg_autonomy     = mean(autonomy,      na.rm = TRUE),
    avg_relatedness  = mean(relatedness,   na.rm = TRUE),
    avg_bpn          = mean(bpn_mean,      na.rm = TRUE),
    avg_rating       = mean(session_rating, na.rm = TRUE),
    .groups          = "drop"
  ) |>
  left_join(demo_clean, by = "uin")

# ── 6. Clean qualitative sentences ───────────────────────────────────────────
# Average per session: take the most common (modal) sentence per BPN/sentiment
# For qualitative data, we keep the first non-NA value per session group
# (sentences are near-identical across 5 runs for the same session)
quotes_clean <- qual_raw |>
  group_by(uin, id) |>
  summarise(
    across(
      starts_with("most_"),
      ~ first(na.omit(.x)),
      .names = "{.col}"
    ),
    .groups = "drop"
  ) |>
  rename(session_id = id) |>
  # Filter out very short sentences (< 8 words) — likely incomplete
  mutate(
    across(
      starts_with("most_"),
      ~ if_else(
          !is.na(.x) & str_count(.x, "\\S+") >= 8,
          .x,
          NA_character_
        )
    )
  )

# ── 7. Join quotes to sessions ────────────────────────────────────────────────
sessions_clean <- sessions_clean |>
  left_join(quotes_clean, by = c("uin", "session_id"))

# ── 8. Save outputs ───────────────────────────────────────────────────────────
saveRDS(sessions_clean, file.path(processed_dir, "sessions_clean.rds"))
saveRDS(participants,   file.path(processed_dir, "participants.rds"))
saveRDS(quotes_clean,   file.path(processed_dir, "quotes_clean.rds"))

cat("Data preparation complete.\n")
cat("sessions_clean:", nrow(sessions_clean), "rows\n")
cat("participants:  ", nrow(participants),   "rows\n")
cat("quotes_clean:  ", nrow(quotes_clean),   "rows\n")
