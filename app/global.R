# global.R
# Loaded AFTER R/ folder (which we don't use), BEFORE ui.R and server.R
# Contains: packages, brand tokens, data loading, shared constants

# ── Packages ──────────────────────────────────────────────────────────────────
library(shiny)
library(shiny.semantic)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(ggiraph)
library(reactable)
library(stringr)
library(glue)

# ── Source modules ────────────────────────────────────────────────────────────
source("modules/mod_impact_overview.R")
source("modules/mod_bpn_deep_dive.R")
source("modules/mod_voices.R")
source("modules/mod_journey.R")

# ── Brand tokens ──────────────────────────────────────────────────────────────
# Source: Noise Solution Brand Guidelines
ns_colors <- list(
  black       = "#01070A",   # Primary background (50% of palette)
  acid_green  = "#BEFF00",   # Primary accent — high scores, positive (25%)
  violet      = "#8755FF",   # Secondary accent — use sparingly (12.5%)
  white       = "#FFFFFF",   # Primary text (12.5%)
  
  # Extended palette (derived, not in guidelines)
  surface     = "#0D1117",   # Slightly lifted from pure black — card backgrounds
  surface_2   = "#161B22",   # Second surface level
  text_muted  = "#8B949E",   # Muted text, labels
  green_dim   = "#7AAA00",   # Dimmed acid green for secondary indicators
  red_signal  = "#FF4D4D",   # Negative sentiment signal (not in brand — use sparingly)
  border      = "#21262D"    # Subtle borders
)

# ── Typography ────────────────────────────────────────────────────────────────
# Roc Grotesk is commercial; Barlow is the closest free match
# Loaded via www/styles.css @import from Google Fonts
ns_font <- "Barlow"

# ── Data loading ──────────────────────────────────────────────────────────────
# App only reads pre-computed .rds files — never raw Excel
sessions_clean <- readRDS("data/processed/sessions_clean.rds")
participants   <- readRDS("data/processed/participants.rds")
quotes_clean   <- readRDS("data/processed/quotes_clean.rds")

# ── App-level constants ───────────────────────────────────────────────────────
app_info <- list(
  title        = "Young People & Music",
  subtitle     = "Impact through Self-Determination",
  n_sessions   = nrow(sessions_clean),
  n_participants = n_distinct(sessions_clean$uin),
  bpn_scale    = "Scores range from 1 (not supported) to 9 (fully supported)",
  data_note    = "Each session analysed up to 5 times; scores shown are session averages.",
  disclaimer   = paste0(
    "Analysis based on ", nrow(sessions_clean), " sessions across ",
    n_distinct(sessions_clean$uin), " participants. ",
    "Patterns suggest associations; small sample size limits generalisation."
  )
)

# ── Shared ggplot2 theme ──────────────────────────────────────────────────────
theme_ns <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      # Background
      plot.background  = element_rect(fill = ns_colors$black,   color = NA),
      panel.background = element_rect(fill = ns_colors$surface, color = NA),
      panel.grid.major = element_line(color = ns_colors$border, linewidth = 0.4),
      panel.grid.minor = element_blank(),
      
      # Text
      text             = element_text(family = ns_font, color = ns_colors$white),
      plot.title       = element_text(face = "bold", size = base_size * 1.2,
                                      color = ns_colors$white),
      plot.subtitle    = element_text(size = base_size * 0.9,
                                      color = ns_colors$text_muted),
      axis.text        = element_text(color = ns_colors$text_muted,
                                      size  = base_size * 0.8),
      axis.title       = element_text(color = ns_colors$text_muted,
                                      size  = base_size * 0.85),
      legend.background = element_rect(fill = ns_colors$surface, color = NA),
      legend.text      = element_text(color = ns_colors$white),
      legend.title     = element_text(color = ns_colors$text_muted),
      
      # Strips (facets)
      strip.background = element_rect(fill = ns_colors$surface_2, color = NA),
      strip.text       = element_text(color = ns_colors$acid_green, face = "bold"),
      
      # Margins
      plot.margin      = ggplot2::margin(16, 16, 16, 16)
    )
}

# BPN domain colours — used consistently across all tabs
bpn_colors <- c(
  "Competence"  = ns_colors$acid_green,
  "Autonomy"    = ns_colors$violet,
  "Relatedness" = "#6B44CC"   # Violet-dim — locked in DESIGN_DECISIONS §5
)